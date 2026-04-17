import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { MasterStatus, ServiceCategory } from '@prisma/client';
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

  // Список всех пользователей
  async getUsers(search?: string) {
    return this.prisma.user.findMany({
      where: {
        deletedAt: null,
        ...(search ? {
          OR: [
            { name: { contains: search, mode: 'insensitive' } },
            { phone: { contains: search } },
          ],
        } : {}),
      },
      include: {
        masterProfile: { select: { id: true, status: true, isActive: true } },
      },
      orderBy: { createdAt: 'desc' },
      take: 200,
    });
  }

  // Удалить аккаунт (soft delete)
  async deleteUser(userId: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException('Пользователь не найден');
    await this.prisma.user.update({
      where: { id: userId },
      data: { deletedAt: new Date() },
    });
    return { userId, deleted: true };
  }

  // Обновить данные пользователя (имя)
  async updateUser(userId: string, name: string) {
    return this.prisma.user.update({
      where: { id: userId },
      data: { name },
      select: { id: true, name: true, phone: true },
    });
  }

  // Убрать доступ к мастеру (деактивировать профиль)
  async revokeMaster(masterId: string) {
    const master = await this.prisma.masterProfile.findUnique({
      where: { id: masterId },
    });
    if (!master) throw new NotFoundException('Профиль мастера не найден');
    await this.prisma.masterProfile.update({
      where: { id: masterId },
      data: { status: MasterStatus.REJECTED, isActive: false, isVerified: false },
    });
    return { masterId, revoked: true };
  }

  // ─── Справочник услуг ─────────────────────────────────────────────

  async listServiceTemplates() {
    return this.prisma.serviceTemplate.findMany({
      orderBy: [{ category: 'asc' }, { sortOrder: 'asc' }],
      include: { _count: { select: { services: true } } },
    });
  }

  async createServiceTemplate(dto: { name: string; nameKz?: string; category: ServiceCategory }) {
    const maxOrder = await this.prisma.serviceTemplate.aggregate({
      _max: { sortOrder: true },
    });
    return this.prisma.serviceTemplate.create({
      data: {
        name: dto.name,
        nameKz: dto.nameKz ?? null,
        category: dto.category,
        sortOrder: (maxOrder._max.sortOrder ?? 0) + 1,
      },
    });
  }

  async updateServiceTemplate(id: string, dto: { name?: string; nameKz?: string; isActive?: boolean }) {
    const tpl = await this.prisma.serviceTemplate.findUnique({ where: { id } });
    if (!tpl) throw new NotFoundException('Шаблон не найден');
    return this.prisma.serviceTemplate.update({ where: { id }, data: dto });
  }

  async deleteServiceTemplate(id: string) {
    const tpl = await this.prisma.serviceTemplate.findUnique({
      where: { id },
      include: { _count: { select: { services: true } } },
    });
    if (!tpl) throw new NotFoundException('Шаблон не найден');
    if (tpl._count.services > 0) {
      throw new BadRequestException(
        `Нельзя удалить: шаблон используется ${tpl._count.services} мастерами`,
      );
    }
    await this.prisma.serviceTemplate.delete({ where: { id } });
    return { deleted: true };
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
