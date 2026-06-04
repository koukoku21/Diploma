import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../shared/prisma.service';
import { CreateMasterDto } from './dto/create-master.dto';
import { UpdateMasterDto } from './dto/update-master.dto';
import { TelegramService } from '../telegram/telegram.service';

@Injectable()
export class MastersService {
  constructor(
    private prisma: PrismaService,
    private telegram: TelegramService,
  ) {}

  // ─── Онбординг мастера (из C-8 "Стать мастером") ───────────────
  async createProfile(userId: string, dto: CreateMasterDto) {
    const existing = await this.prisma.masterProfile.findUnique({
      where: { userId },
    });
    if (existing) {
      throw new BadRequestException('Профиль мастера уже существует');
    }

    const master = await this.prisma.masterProfile.create({
      data: {
        userId,
        address: dto.address,
        lat: dto.lat,
        lng: dto.lng,
        bio: dto.bio,
        specializations: {
          create: dto.specializations.map((category) => ({ category })),
        },
      },
      include: { specializations: true },
    });

    // Дефолтное расписание: Пн-Пт 10:00-19:00 (dayOfWeek: 1-5)
    await this.prisma.schedule.createMany({
      data: [1, 2, 3, 4, 5].map((day) => ({
        masterId: master.id,
        dayOfWeek: day,
        startTime: '10:00',
        endTime: '19:00',
        isDayOff: false,
      })),
    });

    // Уведомление в Telegram (fire-and-forget)
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (user) {
      this.telegram.notifyNewMaster({
        id: master.id,
        userName: user.name ?? '—',
        phone: user.phone,
        address: master.address,
        specializations: master.specializations.map((s) => s.category),
      }).catch(() => {});
    }

    return master;
  }

  // ─── Мой профиль мастера ────────────────────────────────────────
  async getMyProfile(userId: string) {
    const master = await this.prisma.masterProfile.findUnique({
      where: { userId },
      include: {
        user: { select: { name: true, avatarUrl: true } },
        specializations: true,
        portfolioPhotos: { orderBy: { sortOrder: 'asc' } },
        services: { where: { isEnabled: true } },
        schedules: { orderBy: { dayOfWeek: 'asc' } },
      },
    });

    if (!master) throw new NotFoundException('Профиль мастера не найден');
    return master;
  }

  // ─── Повторная отправка заявки после отклонения ─────────────────
  async resubmit(userId: string) {
    const master = await this.prisma.masterProfile.findUnique({
      where: { userId },
      include: {
        user: { select: { name: true, phone: true } },
        specializations: true,
      },
    });
    if (!master) throw new NotFoundException('Профиль мастера не найден');
    if (master.status !== 'REJECTED') {
      throw new BadRequestException('Повторная отправка доступна только после отклонения');
    }

    await this.prisma.masterProfile.update({
      where: { id: master.id },
      data: { status: 'PENDING', rejectionReason: null },
    });

    await this.telegram.notifyNewMaster({
      id: master.id,
      userName: master.user.name,
      phone: master.user.phone,
      address: master.address,
      specializations: master.specializations.map((s) => s.category),
    }).catch(() => {});

    return { status: 'PENDING' };
  }

  // ─── Публичный профиль мастера (для клиентов) ───────────────────
  async getPublicProfile(masterId: string) {
    const master = await this.prisma.masterProfile.findFirst({
      where: { id: masterId, isVerified: true },
      include: {
        user: { select: { name: true, avatarUrl: true } },
        specializations: true,
        portfolioPhotos: { orderBy: { sortOrder: 'asc' } },
        services: { where: { isEnabled: true }, orderBy: { priceFrom: 'asc' } },
        reviews: {
          orderBy: { createdAt: 'desc' },
          take: 5,
          include: {
            client: { select: { name: true, avatarUrl: true } },
            reply: true,
          },
        },
      },
    });

    if (!master) throw new NotFoundException('Мастер не найден');
    return master;
  }

  // ─── Обновление профиля мастера ─────────────────────────────────
  async updateProfile(userId: string, dto: UpdateMasterDto) {
    const master = await this.prisma.masterProfile.findUnique({
      where: { userId },
    });
    if (!master) throw new NotFoundException('Профиль мастера не найден');

    const { specializations, ...rest } = dto;

    let updated;
    try {
      updated = await this.prisma.masterProfile.update({
        where: { id: master.id },
        data: rest,
      });
    } catch (e) {
      if (e instanceof Prisma.PrismaClientKnownRequestError && e.code === 'P2002') {
        throw new BadRequestException('Этот @username уже занят');
      }
      throw e;
    }

    // Заменяем специализации если переданы
    if (specializations) {
      await this.prisma.masterSpec.deleteMany({ where: { masterId: master.id } });
      await this.prisma.masterSpec.createMany({
        data: specializations.map((category) => ({
          masterId: master.id,
          category,
        })),
      });
    }

    return updated;
  }

  // ─── Статистика мастера ─────────────────────────────────────────
  async getStats(userId: string) {
    const master = await this.prisma.masterProfile.findUnique({
      where: { userId },
      select: { id: true, rating: true, reviewCount: true },
    });
    if (!master) throw new NotFoundException('Профиль мастера не найден');

    const now = new Date();
    const startOfWeek = new Date(now);
    startOfWeek.setDate(now.getDate() - now.getDay() + 1);
    startOfWeek.setHours(0, 0, 0, 0);
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);

    // Последние 7 дней для графика
    const days: { date: string; revenue: number; bookings: number }[] = [];
    for (let i = 6; i >= 0; i--) {
      const d = new Date(now);
      d.setDate(now.getDate() - i);
      d.setHours(0, 0, 0, 0);
      const dEnd = new Date(d);
      dEnd.setHours(23, 59, 59, 999);

      const agg = await this.prisma.booking.aggregate({
        where: {
          masterId: master.id,
          status: 'COMPLETED',
          completedAt: { gte: d, lte: dEnd },
        },
        _sum: { priceSnapshot: true },
        _count: true,
      });

      days.push({
        date: d.toISOString().split('T')[0],
        revenue: agg._sum.priceSnapshot ?? 0,
        bookings: agg._count,
      });
    }

    const [weekAgg, monthAgg, allAgg, cancelledCount] = await Promise.all([
      this.prisma.booking.aggregate({
        where: { masterId: master.id, status: 'COMPLETED', completedAt: { gte: startOfWeek } },
        _sum: { priceSnapshot: true },
        _count: true,
      }),
      this.prisma.booking.aggregate({
        where: { masterId: master.id, status: 'COMPLETED', completedAt: { gte: startOfMonth } },
        _sum: { priceSnapshot: true },
        _count: true,
      }),
      this.prisma.booking.aggregate({
        where: { masterId: master.id, status: 'COMPLETED' },
        _sum: { priceSnapshot: true },
        _count: true,
      }),
      this.prisma.booking.count({
        where: { masterId: master.id, status: 'CANCELLED' },
      }),
    ]);

    return {
      rating: master.rating,
      reviewCount: master.reviewCount,
      week: {
        revenue: weekAgg._sum.priceSnapshot ?? 0,
        bookings: weekAgg._count,
      },
      month: {
        revenue: monthAgg._sum.priceSnapshot ?? 0,
        bookings: monthAgg._count,
      },
      allTime: {
        revenue: allAgg._sum.priceSnapshot ?? 0,
        bookings: allAgg._count,
        cancelled: cancelledCount,
      },
      dailyChart: days,
    };
  }

  // ─── Дашборд мастера (M-6) ──────────────────────────────────────
  async getDashboard(userId: string) {
    const master = await this.prisma.masterProfile.findUnique({
      where: { userId },
      select: { id: true, isActive: true },
    });
    if (!master) throw new NotFoundException('Профиль мастера не найден');

    const now = new Date();
    const startOfDay = new Date(now);
    startOfDay.setHours(0, 0, 0, 0);
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);

    const [todayIncome, monthIncome, nextBooking, pendingCount] =
      await Promise.all([
        // Доход за сегодня (завершённые)
        this.prisma.booking.aggregate({
          where: {
            masterId: master.id,
            status: 'COMPLETED',
            completedAt: { gte: startOfDay },
          },
          _sum: { priceSnapshot: true },
        }),
        // Доход за месяц
        this.prisma.booking.aggregate({
          where: {
            masterId: master.id,
            status: 'COMPLETED',
            completedAt: { gte: startOfMonth },
          },
          _sum: { priceSnapshot: true },
        }),
        // Следующая запись
        this.prisma.booking.findFirst({
          where: {
            masterId: master.id,
            status: 'CONFIRMED',
            startsAt: { gte: now },
          },
          orderBy: { startsAt: 'asc' },
          include: {
            client: { select: { name: true } },
            service: { select: { title: true } },
          },
        }),
        // Количество новых записей
        this.prisma.booking.count({
          where: { masterId: master.id, status: 'CONFIRMED' },
        }),
      ]);

    return {
      isActive: master.isActive,
      todayIncome: todayIncome._sum.priceSnapshot ?? 0,
      monthIncome: monthIncome._sum.priceSnapshot ?? 0,
      nextBooking,
      pendingCount,
    };
  }
}
