import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { BookingStatus, NotificationType, StoryStatus } from '@prisma/client';
import { PrismaService } from '../../shared/prisma.service';
import { NotificationsService } from '../notifications/notifications.service';

@Injectable()
export class CronService {
  private readonly logger = new Logger(CronService.name);

  constructor(
    private prisma: PrismaService,
    private notifications: NotificationsService,
  ) {}

  // ─── Напоминание о визите за 1 час ─────────────────────────────
  // Каждые 5 минут проверяем записи, которые начнутся через 50–70 мин
  @Cron('*/5 * * * *')
  async sendBookingReminders() {
    const now = new Date();
    const from = new Date(now.getTime() + 50 * 60 * 1000);
    const to   = new Date(now.getTime() + 70 * 60 * 1000);

    const bookings = await this.prisma.booking.findMany({
      where: {
        status: BookingStatus.CONFIRMED,
        reminderSentAt: null,
        startsAt: { gte: from, lte: to },
      },
      include: {
        client: { select: { id: true, name: true } },
        master: { include: { user: { select: { name: true } } } },
        service: { select: { title: true } },
      },
    });

    for (const booking of bookings) {
      try {
        const timeStr = booking.startsAt.toLocaleTimeString('ru-RU', {
          hour: '2-digit', minute: '2-digit', timeZone: 'Asia/Almaty',
        });

        // Push клиенту
        await this.notifications.send({
          userId: booking.clientId,
          type: NotificationType.BOOKING_REMINDER,
          title: 'Напоминание о визите',
          body: `Через час — ${booking.service.title} у ${booking.master.user?.name ?? 'мастера'} в ${timeStr}`,
          data: { bookingId: booking.id },
        });

        // Отмечаем что напоминание отправлено
        await this.prisma.booking.update({
          where: { id: booking.id },
          data: { reminderSentAt: new Date() },
        });
      } catch (e) {
        this.logger.warn(`Reminder failed for booking ${booking.id}: ${e}`);
      }
    }

    if (bookings.length > 0) {
      this.logger.log(`Sent reminders for ${bookings.length} bookings`);
    }
  }

  // ─── Деактивация истёкших периодов видимости ───────────────────
  // Каждый час
  @Cron(CronExpression.EVERY_HOUR)
  async deactivateExpiredVisibility() {
    const now = new Date();

    const expired = await this.prisma.masterVisibility.findMany({
      where: { endsAt: { lt: now }, isActive: true },
      include: { master: { select: { id: true, userId: true } } },
    });

    for (const v of expired) {
      try {
        await this.prisma.masterVisibility.update({
          where: { id: v.id },
          data: { isActive: false },
        });

        // Проверяем есть ли ещё активный период
        const activeCount = await this.prisma.masterVisibility.count({
          where: { masterId: v.masterId, isActive: true, endsAt: { gt: now } },
        });

        if (activeCount === 0) {
          await this.prisma.masterProfile.update({
            where: { id: v.masterId },
            data: { isVisible: false },
          });

          await this.notifications.send({
            userId: v.master.userId,
            type: NotificationType.VISIBILITY_EXPIRED,
            title: 'Видимость в ленте истекла',
            body: 'Вы скрыты из ленты клиентов. Продлите видимость в настройках.',
          });
        }
      } catch (e) {
        this.logger.warn(`Visibility deactivation failed for ${v.id}: ${e}`);
      }
    }

    if (expired.length > 0) {
      this.logger.log(`Deactivated ${expired.length} visibility periods`);
    }
  }

  // ─── Уведомление за 24 часа до истечения видимости ─────────────
  // Каждый час
  @Cron(CronExpression.EVERY_HOUR)
  async notifyExpiringVisibility() {
    const now  = new Date();
    const from = new Date(now.getTime() + 23 * 60 * 60 * 1000);
    const to   = new Date(now.getTime() + 25 * 60 * 60 * 1000);

    const expiring = await this.prisma.masterVisibility.findMany({
      where: {
        isActive: true,
        endsAt: { gte: from, lte: to },
        expiryNotifiedAt: null,
      },
      include: { master: { select: { userId: true } } },
    });

    for (const v of expiring) {
      try {
        await this.notifications.send({
          userId: v.master.userId,
          type: NotificationType.VISIBILITY_EXPIRING_SOON,
          title: 'Видимость заканчивается завтра',
          body: 'Продлите видимость в ленте, чтобы не потерять клиентов.',
        });

        await this.prisma.masterVisibility.update({
          where: { id: v.id },
          data: { expiryNotifiedAt: new Date() },
        });
      } catch (e) {
        this.logger.warn(`Expiry notification failed for ${v.id}: ${e}`);
      }
    }
  }

  // ─── Деактивация истёкших сторисов ─────────────────────────────
  // Каждый час
  @Cron(CronExpression.EVERY_HOUR)
  async expireStories() {
    const result = await this.prisma.story.updateMany({
      where: {
        status: StoryStatus.ACTIVE,
        expiresAt: { lt: new Date() },
      },
      data: { status: StoryStatus.EXPIRED },
    });

    if (result.count > 0) {
      this.logger.log(`Expired ${result.count} stories`);
    }
  }
}
