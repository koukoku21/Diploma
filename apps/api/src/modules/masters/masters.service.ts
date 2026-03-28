import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../shared/prisma.service';
import { CreateMasterDto } from './dto/create-master.dto';
import { UpdateMasterDto } from './dto/update-master.dto';

@Injectable()
export class MastersService {
  constructor(private prisma: PrismaService) {}

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
          include: { client: { select: { name: true, avatarUrl: true } } },
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

    const updated = await this.prisma.masterProfile.update({
      where: { id: master.id },
      data: rest,
    });

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
