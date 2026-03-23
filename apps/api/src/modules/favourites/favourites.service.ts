import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../shared/prisma.service';

@Injectable()
export class FavouritesService {
  constructor(private prisma: PrismaService) {}

  // C-9: список избранных мастеров
  async list(userId: string) {
    return this.prisma.favourite.findMany({
      where: { userId },
      include: {
        master: {
          include: {
            user: { select: { name: true, avatarUrl: true } },
            specializations: true,
            portfolioPhotos: {
              where: { isCover: true },
              take: 1,
            },
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  // C-1 ♡: добавить мастера в избранное → создаёт ChatRoom
  async add(userId: string, masterId: string) {
    const master = await this.prisma.masterProfile.findFirst({
      where: { id: masterId, isVerified: true },
    });
    if (!master) throw new NotFoundException('Мастер не найден');

    const existing = await this.prisma.favourite.findUnique({
      where: { userId_masterId: { userId, masterId } },
    });
    if (existing) throw new BadRequestException('Уже в избранном');

    // Транзакция: создаём Favourite + ChatRoom атомарно
    const [favourite] = await this.prisma.$transaction([
      this.prisma.favourite.create({
        data: { userId, masterId },
      }),
      // ChatRoom — @@unique([clientId, masterId]) не даст дубликат
      this.prisma.chatRoom.upsert({
        where: { clientId_masterId: { clientId: userId, masterId } },
        create: {
          clientId: userId,
          masterId,
          users: {
            create: [{ userId }, { userId: master.userId }],
          },
        },
        update: {},
      }),
    ]);

    return favourite;
  }

  // C-9: убрать из избранного
  async remove(userId: string, masterId: string) {
    const fav = await this.prisma.favourite.findUnique({
      where: { userId_masterId: { userId, masterId } },
    });
    if (!fav) throw new NotFoundException('Не найдено в избранном');

    await this.prisma.favourite.delete({
      where: { userId_masterId: { userId, masterId } },
    });

    return { message: 'Удалено из избранного' };
  }

  async isFavourite(userId: string, masterId: string): Promise<boolean> {
    const fav = await this.prisma.favourite.findUnique({
      where: { userId_masterId: { userId, masterId } },
    });
    return !!fav;
  }
}
