import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { MasterStatus, ServiceCategory, StoryPackage, StoryStatus } from '@prisma/client';
import * as crypto from 'crypto';
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
      where: {
        status,
        services: { some: { isEnabled: true } },   // только с хотя бы одной услугой
        address: { not: 'Астана' },                 // адрес должен быть заполнен
      },
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

    // Генерируем bookingSlug при первом одобрении (если ещё нет)
    const bookingSlug =
      isApproved && !master.bookingSlug
        ? crypto.randomBytes(4).toString('hex')
        : undefined;

    await this.prisma.masterProfile.update({
      where: { id: masterId },
      data: {
        status: dto.status,
        isVerified: isApproved,
        isVisible: isApproved ? true : undefined,
        verifiedAt: isApproved ? new Date() : null,
        rejectionReason: dto.rejectionReason ?? null,
        ...(bookingSlug ? { bookingSlug } : {}),
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

  // Удалить аккаунт навсегда (hard delete) — без возможности восстановления
  async hardDeleteUser(userId: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException('Пользователь не найден');

    await this.prisma.$transaction(async (tx) => {
      // Удаляем записи без cascade на User
      await tx.chatMessage.deleteMany({ where: { senderId: userId } });
      await tx.booking.deleteMany({ where: { clientId: userId } });
      await tx.review.deleteMany({ where: { clientId: userId } });
      await tx.salonProfile.deleteMany({ where: { ownerId: userId } });
      // Остальное (MasterProfile→cascade, RefreshToken, PushToken,
      // Notification, ChatRoomUser, Favourite, StoryView) удаляется автоматически
      await tx.user.delete({ where: { id: userId } });
    });

    return { userId, hardDeleted: true };
  }

  // Заблокировать пользователя
  async banUser(userId: string, reason?: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException('Пользователь не найден');
    await this.prisma.user.update({
      where: { id: userId },
      data: { isBanned: true, banReason: reason ?? null, bannedAt: new Date() },
    });
    return { userId, banned: true };
  }

  // Разблокировать пользователя
  async unbanUser(userId: string) {
    await this.prisma.user.update({
      where: { id: userId },
      data: { isBanned: false, banReason: null, bannedAt: null },
    });
    return { userId, banned: false };
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
    const now = new Date();
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);

    const [totalMasters, pendingMasters, totalUsers, totalBookings, pendingStories,
           monthRevenue, completedBookings] =
      await Promise.all([
        this.prisma.masterProfile.count({ where: { status: MasterStatus.APPROVED } }),
        this.prisma.masterProfile.count({ where: { status: MasterStatus.PENDING } }),
        this.prisma.user.count({ where: { deletedAt: null } }),
        this.prisma.booking.count(),
        this.prisma.story.count({ where: { status: StoryStatus.PENDING } }),
        this.prisma.booking.aggregate({
          where: { status: 'COMPLETED', completedAt: { gte: startOfMonth } },
          _sum: { priceSnapshot: true },
        }),
        this.prisma.booking.count({ where: { status: 'COMPLETED' } }),
      ]);

    // Последние 7 дней: новые пользователи и записи
    const dailyStats: { date: string; newUsers: number; bookings: number }[] = [];
    for (let i = 6; i >= 0; i--) {
      const d = new Date(now);
      d.setDate(now.getDate() - i);
      d.setHours(0, 0, 0, 0);
      const dEnd = new Date(d);
      dEnd.setHours(23, 59, 59, 999);

      const [newUsers, dayBookings] = await Promise.all([
        this.prisma.user.count({
          where: { createdAt: { gte: d, lte: dEnd }, deletedAt: null },
        }),
        this.prisma.booking.count({
          where: { createdAt: { gte: d, lte: dEnd } },
        }),
      ]);

      dailyStats.push({ date: d.toISOString().split('T')[0], newUsers, bookings: dayBookings });
    }

    return {
      totalMasters, pendingMasters, totalUsers, totalBookings,
      completedBookings, pendingStories,
      monthRevenue: monthRevenue._sum.priceSnapshot ?? 0,
      dailyStats,
    };
  }

  // ─── Сторисы ───────────────────────────────────────────────────────

  async getPendingStories() {
    return this.prisma.story.findMany({
      where: { status: StoryStatus.PENDING },
      include: { salon: { select: { name: true, logoUrl: true } } },
      orderBy: { createdAt: 'asc' },
    });
  }

  async getActiveStories() {
    return this.prisma.story.findMany({
      where: { status: StoryStatus.ACTIVE },
      include: { salon: { select: { name: true, logoUrl: true } } },
      orderBy: { expiresAt: 'asc' },
    });
  }

  async approveStory(storyId: string) {
    const story = await this.prisma.story.findUnique({ where: { id: storyId } });
    if (!story) throw new NotFoundException('Сторис не найден');

    const durationDays = { DAY: 1, WEEK: 7, MONTH: 30 }[story.packageType] ?? 7;
    const now = new Date();
    const expiresAt = new Date(now.getTime() + durationDays * 24 * 60 * 60 * 1000);

    return this.prisma.story.update({
      where: { id: storyId },
      data: { status: StoryStatus.ACTIVE, startsAt: now, expiresAt },
    });
  }

  async rejectStory(storyId: string, reason: string) {
    const story = await this.prisma.story.findUnique({ where: { id: storyId } });
    if (!story) throw new NotFoundException('Сторис не найден');

    return this.prisma.story.update({
      where: { id: storyId },
      data: { status: StoryStatus.REJECTED, rejectReason: reason },
    });
  }

  async deactivateStory(storyId: string) {
    const story = await this.prisma.story.findUnique({ where: { id: storyId } });
    if (!story) throw new NotFoundException('Сторис не найден');

    return this.prisma.story.update({
      where: { id: storyId },
      data: { status: StoryStatus.EXPIRED },
    });
  }

  async listSalons() {
    return this.prisma.salonProfile.findMany({
      select: { id: true, name: true },
      orderBy: { name: 'asc' },
    });
  }

  async createStory(dto: {
    salonId?: string;
    mediaUrl: string;
    caption?: string;
    category?: ServiceCategory;
    packageType: StoryPackage;
  }) {
    let salonId = dto.salonId;

    if (!salonId) {
      let salon = await this.prisma.salonProfile.findFirst();
      if (!salon) {
        const demoUser = await this.prisma.user.upsert({
          where: { phone: '+77000000000' },
          create: { phone: '+77000000000', name: 'Demo Salon' },
          update: {},
        });
        salon = await this.prisma.salonProfile.upsert({
          where: { ownerId: demoUser.id },
          create: { ownerId: demoUser.id, name: 'Demo Salon', address: 'Астана' },
          update: {},
        });
      }
      salonId = salon.id;
    }

    const paidAmounts: Record<StoryPackage, number> = { DAY: 2990, WEEK: 9990, MONTH: 24990 };

    return this.prisma.story.create({
      data: {
        salonId,
        mediaUrl: dto.mediaUrl,
        caption: dto.caption ?? null,
        category: dto.category ?? null,
        packageType: dto.packageType,
        paidAmount: paidAmounts[dto.packageType],
        isPaid: true,
        status: StoryStatus.PENDING,
      },
      include: { salon: { select: { name: true } } },
    });
  }
}
