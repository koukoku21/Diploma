import { Injectable, NotFoundException } from '@nestjs/common';
import { MasterStatus } from '@prisma/client';
import { PrismaService } from '../../shared/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';
import { ReviewMasterDto } from './dto/review-master.dto';

@Injectable()
export class AdminService {
  constructor(
    private prisma: PrismaService,
    private notifications: NotificationsService,
  ) {}

  // Список заявок мастеров на верификацию
  async getPendingMasters(status: MasterStatus = MasterStatus.PENDING) {
    return this.prisma.masterProfile.findMany({
      where: { status },
      include: {
        user: { select: { id: true, name: true, phone: true, avatarUrl: true } },
        specializations: true,
        portfolioPhotos: { orderBy: { sortOrder: 'asc' } },
        services: { where: { isEnabled: true } },
      },
      orderBy: { createdAt: 'asc' },
    });
  }

  // Детали заявки
  async getMasterDetail(masterId: string) {
    const master = await this.prisma.masterProfile.findUnique({
      where: { id: masterId },
      include: {
        user: { select: { id: true, name: true, phone: true, createdAt: true } },
        specializations: true,
        portfolioPhotos: { orderBy: { sortOrder: 'asc' } },
        services: true,
        schedules: { orderBy: { dayOfWeek: 'asc' } },
        _count: { select: { bookings: true, reviews: true } },
      },
    });

    if (!master) throw new NotFoundException('Мастер не найден');
    return master;
  }

  // APPROVED / REJECTED / SUSPENDED
  async reviewMaster(masterId: string, dto: ReviewMasterDto) {
    const master = await this.prisma.masterProfile.findUnique({
      where: { id: masterId },
      include: { user: true },
    });

    if (!master) throw new NotFoundException('Мастер не найден');

    const isApproved = dto.status === MasterStatus.APPROVED;

    await this.prisma.masterProfile.update({
      where: { id: masterId },
      data: {
        status: dto.status,
        isVerified: isApproved,
        verifiedAt: isApproved ? new Date() : null,
      },
    });

    // Push уведомление мастеру
    if (isApproved) {
      await this.notifications.notifyProfileApproved(master.userId);
    } else if (dto.status === MasterStatus.REJECTED) {
      await this.notifications.notifyProfileRejected(master.userId);
    }

    return { masterId, status: dto.status };
  }

  // Статистика для дашборда
  async getStats() {
    const [totalMasters, pendingMasters, totalUsers, totalBookings] =
      await Promise.all([
        this.prisma.masterProfile.count({ where: { status: MasterStatus.APPROVED } }),
        this.prisma.masterProfile.count({ where: { status: MasterStatus.PENDING } }),
        this.prisma.user.count({ where: { deletedAt: null } }),
        this.prisma.booking.count(),
      ]);

    return { totalMasters, pendingMasters, totalUsers, totalBookings };
  }
}
