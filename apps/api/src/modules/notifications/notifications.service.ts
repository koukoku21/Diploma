import { Injectable } from '@nestjs/common';
import { NotificationType } from '@prisma/client';
import { PrismaService } from '../../shared/prisma.service';
import { FcmService } from './fcm.service';

interface SendPayload {
  userId: string;
  type: NotificationType;
  title: string;
  body: string;
  data?: Record<string, string>;
}

@Injectable()
export class NotificationsService {
  constructor(
    private prisma: PrismaService,
    private fcm: FcmService,
  ) {}

  // Основной метод — сохранить в БД + отправить push
  async send(payload: SendPayload): Promise<void> {
    const { userId, type, title, body, data } = payload;

    // Сохраняем в историю
    await this.prisma.notification.create({
      data: { userId, type, title, body, data },
    });

    // Берём FCM токены пользователя
    const tokens = await this.prisma.pushToken.findMany({
      where: { userId },
      select: { token: true },
    });

    if (tokens.length > 0) {
      await this.fcm.sendToTokens(
        tokens.map((t) => t.token),
        title,
        body,
        { ...data, type },
      );
    }
  }

  // Регистрация FCM токена
  async registerToken(userId: string, token: string, platform: 'IOS' | 'ANDROID') {
    await this.prisma.pushToken.upsert({
      where: { token },
      create: { userId, token, platform },
      update: { userId },
    });
  }

  // Удаление токена (при выходе из аккаунта)
  async removeToken(token: string) {
    await this.prisma.pushToken.deleteMany({ where: { token } });
  }

  // История уведомлений
  async getHistory(userId: string) {
    const notifications = await this.prisma.notification.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
      take: 50,
    });

    await this.prisma.notification.updateMany({
      where: { userId, isRead: false },
      data: { isRead: true },
    });

    return notifications;
  }

  // Счётчик непрочитанных (для бейджа)
  async getUnreadCount(userId: string): Promise<number> {
    return this.prisma.notification.count({
      where: { userId, isRead: false },
    });
  }

  // ─── Хелперы для конкретных событий ────────────────────────────

  async notifyNewBooking(masterId: string, bookingId: string, clientName: string, serviceName: string) {
    const master = await this.prisma.masterProfile.findUnique({
      where: { id: masterId },
      select: { userId: true },
    });
    if (!master) return;

    await this.send({
      userId: master.userId,
      type: NotificationType.NEW_BOOKING,
      title: 'Новая запись',
      body: `${clientName} записался на ${serviceName}`,
      data: { bookingId },
    });
  }

  async notifyBookingCancelledByClient(masterId: string, bookingId: string, clientName: string) {
    const master = await this.prisma.masterProfile.findUnique({
      where: { id: masterId },
      select: { userId: true },
    });
    if (!master) return;

    await this.send({
      userId: master.userId,
      type: NotificationType.BOOKING_CANCELLED_BY_CLIENT,
      title: 'Запись отменена',
      body: `${clientName} отменил запись`,
      data: { bookingId },
    });
  }

  async notifyBookingCancelledByMaster(clientId: string, bookingId: string, masterName: string) {
    await this.send({
      userId: clientId,
      type: NotificationType.BOOKING_CANCELLED_BY_MASTER,
      title: 'Запись отменена мастером',
      body: `${masterName} отменил вашу запись`,
      data: { bookingId },
    });
  }

  async notifyReviewRequest(clientId: string, bookingId: string, masterName: string) {
    await this.send({
      userId: clientId,
      type: NotificationType.REVIEW_REQUEST,
      title: 'Оцените визит',
      body: `Как прошёл визит к ${masterName}? Оставьте отзыв`,
      data: { bookingId },
    });
  }

  async notifyProfileApproved(userId: string) {
    await this.send({
      userId,
      type: NotificationType.PROFILE_APPROVED,
      title: 'Профиль одобрен ✓',
      body: 'Ваш профиль мастера прошёл верификацию и теперь виден клиентам',
    });
  }

  async notifyProfileRejected(userId: string) {
    await this.send({
      userId,
      type: NotificationType.PROFILE_REJECTED,
      title: 'Профиль отклонён',
      body: 'Проверьте данные профиля и отправьте заявку повторно',
    });
  }
}
