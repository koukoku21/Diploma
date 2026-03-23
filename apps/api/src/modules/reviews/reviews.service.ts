import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../shared/prisma.service';
import { CreateReviewDto } from './dto/create-review.dto';

@Injectable()
export class ReviewsService {
  constructor(private prisma: PrismaService) {}

  // C-7: оставить отзыв (только после COMPLETED)
  async create(clientId: string, dto: CreateReviewDto) {
    const booking = await this.prisma.booking.findUnique({
      where: { id: dto.bookingId },
    });

    if (!booking) throw new NotFoundException('Запись не найдена');
    if (booking.clientId !== clientId) throw new ForbiddenException();
    if (booking.status !== 'COMPLETED') {
      throw new BadRequestException('Отзыв можно оставить только после завершённой записи');
    }

    const existing = await this.prisma.review.findUnique({
      where: { bookingId: dto.bookingId },
    });
    if (existing) {
      throw new BadRequestException('Отзыв уже оставлен');
    }

    const review = await this.prisma.review.create({
      data: {
        bookingId: dto.bookingId,
        clientId,
        masterId: booking.masterId,
        rating: dto.rating,
        text: dto.text,
      },
    });

    // Пересчёт денормализованного рейтинга мастера
    await this.recalcRating(booking.masterId);

    return review;
  }

  // C-2b: все отзывы мастера
  async listForMaster(masterId: string, take = 20, skip = 0) {
    const [reviews, total] = await Promise.all([
      this.prisma.review.findMany({
        where: { masterId },
        include: { client: { select: { name: true, avatarUrl: true } } },
        orderBy: { createdAt: 'desc' },
        take,
        skip,
      }),
      this.prisma.review.count({ where: { masterId } }),
    ]);

    return { reviews, total, hasMore: skip + take < total };
  }

  private async recalcRating(masterId: string) {
    const agg = await this.prisma.review.aggregate({
      where: { masterId },
      _avg: { rating: true },
      _count: { rating: true },
    });

    await this.prisma.masterProfile.update({
      where: { id: masterId },
      data: {
        rating: agg._avg.rating ?? null,
        reviewCount: agg._count.rating,
      },
    });
  }
}
