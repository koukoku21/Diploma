import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../shared/prisma.service';
import { R2Service } from './r2.service';

const MAX_PHOTOS = 20;
const MIN_PHOTOS_FOR_APPROVAL = 3;
const ALLOWED_MIME = ['image/jpeg', 'image/png', 'image/webp'];

@Injectable()
export class PortfolioService {
  constructor(
    private prisma: PrismaService,
    private r2: R2Service,
  ) {}

  private async getMasterOrThrow(userId: string) {
    const master = await this.prisma.masterProfile.findUnique({
      where: { userId },
    });
    if (!master) throw new NotFoundException('Профиль мастера не найден');
    return master;
  }

  async getPhotos(userId: string) {
    const master = await this.getMasterOrThrow(userId);
    return this.prisma.portfolioPhoto.findMany({
      where: { masterId: master.id },
      orderBy: { sortOrder: 'asc' },
    });
  }

  async upload(userId: string, file: Express.Multer.File) {
    if (!ALLOWED_MIME.includes(file.mimetype)) {
      throw new BadRequestException('Только JPEG, PNG или WebP');
    }

    const master = await this.getMasterOrThrow(userId);

    const count = await this.prisma.portfolioPhoto.count({
      where: { masterId: master.id },
    });
    if (count >= MAX_PHOTOS) {
      throw new BadRequestException(`Максимум ${MAX_PHOTOS} фото`);
    }

    const { url, key } = await this.r2.upload(
      file,
      `portfolio/${master.id}`,
    );

    // Первое фото становится обложкой
    const isCover = count === 0;

    return this.prisma.portfolioPhoto.create({
      data: {
        masterId: master.id,
        url,
        thumbUrl: url, // TODO: thumb генерация через Cloudflare Images
        isCover,
        sortOrder: count,
      },
    });
  }

  // M-10: drag & drop сортировка
  async reorder(userId: string, orderedIds: string[]) {
    const master = await this.getMasterOrThrow(userId);

    const photos = await this.prisma.portfolioPhoto.findMany({
      where: { masterId: master.id },
    });

    const masterPhotoIds = new Set(photos.map((p) => p.id));
    if (!orderedIds.every((id) => masterPhotoIds.has(id))) {
      throw new ForbiddenException('Некоторые фото не принадлежат мастеру');
    }

    await Promise.all(
      orderedIds.map((id, index) =>
        this.prisma.portfolioPhoto.update({
          where: { id },
          data: { sortOrder: index, isCover: index === 0 },
        }),
      ),
    );

    return this.getPhotos(userId);
  }

  async delete(userId: string, photoId: string) {
    const master = await this.getMasterOrThrow(userId);

    const photo = await this.prisma.portfolioPhoto.findUnique({
      where: { id: photoId },
    });
    if (!photo) throw new NotFoundException('Фото не найдено');
    if (photo.masterId !== master.id) throw new ForbiddenException();

    // Проверяем что не удаляем последнее фото верифицированного мастера
    const count = await this.prisma.portfolioPhoto.count({
      where: { masterId: master.id },
    });
    if (master.isVerified && count <= MIN_PHOTOS_FOR_APPROVAL) {
      throw new BadRequestException(
        `Минимум ${MIN_PHOTOS_FOR_APPROVAL} фото в портфолио`,
      );
    }

    await this.r2.delete(this.r2.keyFromUrl(photo.url));
    await this.prisma.portfolioPhoto.delete({ where: { id: photoId } });

    return { message: 'Фото удалено' };
  }
}
