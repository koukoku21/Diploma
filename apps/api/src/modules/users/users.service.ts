import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../shared/prisma.service';
import { R2Service } from '../portfolio/r2.service';
import { UpdateUserDto } from './dto/update-user.dto';

@Injectable()
export class UsersService {
  constructor(
    private prisma: PrismaService,
    private r2: R2Service,
  ) {}

  async getProfile(userId: string) {
    const user = await this.prisma.user.findFirst({
      where: { id: userId, deletedAt: null },
      select: {
        id: true,
        phone: true,
        name: true,
        avatarUrl: true,
        lang: true,
        createdAt: true,
        masterProfile: {
          select: {
            id: true,
            status: true,
            isActive: true,
            isVerified: true,
          },
        },
      },
    });

    if (!user) throw new NotFoundException('Пользователь не найден');
    return user;
  }

  async updateProfile(userId: string, dto: UpdateUserDto) {
    return this.prisma.user.update({
      where: { id: userId },
      data: dto,
      select: {
        id: true,
        phone: true,
        name: true,
        avatarUrl: true,
        lang: true,
      },
    });
  }

  async uploadAvatar(userId: string, file: Express.Multer.File) {
    const { url } = await this.r2.upload(file, 'avatars');
    return this.prisma.user.update({
      where: { id: userId },
      data: { avatarUrl: url },
      select: { id: true, avatarUrl: true },
    });
  }

  async deleteAccount(userId: string) {
    // Soft delete
    await this.prisma.user.update({
      where: { id: userId },
      data: { deletedAt: new Date() },
    });
    return { message: 'Аккаунт удалён' };
  }
}
