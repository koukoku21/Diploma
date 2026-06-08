import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { BookingSource, BookingStatus } from '@prisma/client';
import * as crypto from 'crypto';
import { PrismaService } from '../../shared/prisma.service';
import { RedisService } from '../../shared/redis.service';
import { MobizonService } from '../auth/mobizon.service';
import { SlotsService } from '../slots/slots.service';
import { NotificationsService } from '../notifications/notifications.service';
import { SendOtpPwaDto } from './dto/send-otp-pwa.dto';
import { BookSlotPwaDto } from './dto/book-slot-pwa.dto';

const OTP_TTL_SECONDS = 5 * 60;
const OTP_RATE_LIMIT_TTL = 60;

@Injectable()
export class BookingPageService {
  constructor(
    private prisma: PrismaService,
    private redis: RedisService,
    private mobizon: MobizonService,
    private slots: SlotsService,
    private notifications: NotificationsService,
  ) {}

  // GET /p/b/:slug → resolve bookingSlug → username
  async resolveSlug(slug: string): Promise<{ username: string }> {
    const master = await this.prisma.masterProfile.findUnique({
      where: { bookingSlug: slug },
      select: { username: true, isBookingLinkActive: true },
    });

    if (!master || !master.username) {
      throw new NotFoundException('Ссылка не найдена');
    }
    if (!master.isBookingLinkActive) {
      throw new BadRequestException('Мастер временно не принимает записи по ссылке');
    }

    return { username: master.username };
  }

  // GET /p/:username → публичный профиль мастера
  async getProfile(username: string) {
    const master = await this.prisma.masterProfile.findUnique({
      where: { username },
      include: {
        user: { select: { name: true, avatarUrl: true } },
        specializations: true,
        portfolioPhotos: { orderBy: { sortOrder: 'asc' } },
        services: {
          where: { isEnabled: true },
          orderBy: { priceFrom: 'asc' },
        },
        reviews: {
          orderBy: { createdAt: 'desc' },
          take: 5,
          include: { client: { select: { name: true, avatarUrl: true } } },
        },
      },
    });

    if (!master) throw new NotFoundException('Мастер не найден');
    if (!master.isBookingLinkActive) {
      return { ...master, bookingDisabled: true };
    }

    return master;
  }

  // GET /p/:username/slots?serviceId=&date=
  async getSlots(username: string, serviceId: string, date: string) {
    const master = await this.prisma.masterProfile.findUnique({
      where: { username },
      select: { id: true, isBookingLinkActive: true, isVerified: true, isActive: true },
    });

    if (!master) throw new NotFoundException('Мастер не найден');
    if (!master.isBookingLinkActive) {
      throw new BadRequestException('Мастер временно не принимает записи по ссылке');
    }

    return this.slots.getSlots(master.id, { serviceId, date });
  }

  // POST /p/:username/send-otp
  async sendOtp(username: string, dto: SendOtpPwaDto): Promise<{ message: string }> {
    const master = await this.prisma.masterProfile.findUnique({
      where: { username },
      select: { isBookingLinkActive: true },
    });
    if (!master) throw new NotFoundException('Мастер не найден');
    if (!master.isBookingLinkActive) {
      throw new BadRequestException('Мастер временно не принимает записи по ссылке');
    }

    const phone = dto.phone.startsWith('+') ? dto.phone : `+${dto.phone}`;
    const rateLimitKey = `otp:rate:${phone}`;
    if (await this.redis.get(rateLimitKey)) {
      throw new BadRequestException('Подождите минуту перед повторной отправкой');
    }

    const code = String(crypto.randomInt(1000, 9999));
    await this.redis.set(`otp:${phone}`, code, OTP_TTL_SECONDS);
    await this.redis.set(rateLimitKey, '1', OTP_RATE_LIMIT_TTL);

    await this.mobizon.sendOtp(phone, code);

    return { message: 'Код отправлен' };
  }

  // POST /p/:username/book
  async bookSlot(username: string, dto: BookSlotPwaDto) {
    const { name, otpCode, serviceId, date, time } = dto;
    const phone = dto.phone.startsWith('+') ? dto.phone : `+${dto.phone}`;

    // Верификация OTP
    const otpKey = `otp:${phone}`;
    const stored = await this.redis.get(otpKey);
    if (!stored || stored !== otpCode) {
      throw new BadRequestException('Неверный или устаревший код');
    }
    await this.redis.del(otpKey);

    // Находим мастера
    const master = await this.prisma.masterProfile.findUnique({
      where: { username },
      select: { id: true, isBookingLinkActive: true, bufferMinutes: true },
    });
    if (!master) throw new NotFoundException('Мастер не найден');
    if (!master.isBookingLinkActive) {
      throw new BadRequestException('Мастер временно не принимает записи по ссылке');
    }

    // Проверяем что слот свободен
    const slotsResult = await this.slots.getSlots(master.id, { date, serviceId });
    if (slotsResult.isDayOff || !slotsResult.slots.includes(time)) {
      throw new BadRequestException('Выбранное время недоступно');
    }

    // Получаем услугу
    const service = await this.prisma.service.findFirst({
      where: { id: serviceId, masterId: master.id, isEnabled: true },
    });
    if (!service) throw new NotFoundException('Услуга не найдена');

    // Upsert пользователя: если уже есть по телефону — привязываем, иначе isGuest
    const user = await this.prisma.user.upsert({
      where: { phone },
      create: { phone, name, isGuest: true },
      update: { deletedAt: null },
    });

    // Вычисляем startsAt / endsAt (UTC+5)
    const startsAt = new Date(`${date}T${time}:00.000+05:00`);
    const endsAt = new Date(
      startsAt.getTime() + (service.durationMin + master.bufferMinutes) * 60_000,
    );

    // Финальная проверка race condition
    const conflict = await this.prisma.booking.findFirst({
      where: {
        masterId: master.id,
        status: { not: 'CANCELLED' },
        AND: [{ startsAt: { lt: endsAt } }, { endsAt: { gt: startsAt } }],
      },
    });
    if (conflict) {
      throw new BadRequestException('Время уже занято, выберите другое');
    }

    const booking = await this.prisma.booking.create({
      data: {
        clientId: user.id,
        masterId: master.id,
        serviceId,
        startsAt,
        endsAt,
        priceSnapshot: service.priceFrom,
        status: BookingStatus.CONFIRMED,
        source: BookingSource.PWA_LINK,
      },
      include: {
        service: { select: { title: true, durationMin: true } },
        master: { include: { user: { select: { name: true } } } },
      },
    });

    await this.slots.invalidateCache(master.id, date);

    await this.notifications.notifyNewBooking(
      master.id,
      booking.id,
      user.name || dto.name,
      booking.service.title,
    );

    return {
      bookingId: booking.id,
      masterName: booking.master.user?.name,
      service: booking.service.title,
      startsAt: booking.startsAt,
    };
  }
}
