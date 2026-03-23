import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { BookingStatus, CancelledBy } from '@prisma/client';
import { PrismaService } from '../../shared/prisma.service';
import { SlotsService } from '../slots/slots.service';
import { CreateBookingDto } from './dto/create-booking.dto';
import { CancelBookingDto } from './dto/cancel-booking.dto';

const BOOKING_INCLUDE = {
  service: true,
  master: {
    include: {
      user: { select: { name: true, avatarUrl: true } },
      portfolioPhotos: {
        where: { isCover: true },
        take: 1,
        select: { url: true },
      },
    },
  },
  review: true,
};

@Injectable()
export class BookingsService {
  constructor(
    private prisma: PrismaService,
    private slots: SlotsService,
  ) {}

  // ─── C-5: Создать запись ────────────────────────────────────────
  async create(clientId: string, dto: CreateBookingDto) {
    const { masterId, serviceId, date, time } = dto;

    // Проверяем что слот действительно свободен
    const slotsResult = await this.slots.getSlots(masterId, { date, serviceId });

    if (slotsResult.isDayOff || !slotsResult.slots.includes(time)) {
      throw new BadRequestException('Выбранное время недоступно');
    }

    const service = await this.prisma.service.findFirst({
      where: { id: serviceId, masterId, isEnabled: true },
    });
    if (!service) throw new NotFoundException('Услуга не найдена');

    const master = await this.prisma.masterProfile.findUnique({
      where: { id: masterId },
    });
    if (!master) throw new NotFoundException('Мастер не найден');

    // Вычисляем startsAt / endsAt
    const startsAt = new Date(`${date}T${time}:00.000Z`);
    const endsAt = new Date(
      startsAt.getTime() +
        (service.durationMin + master.bufferMinutes) * 60_000,
    );

    // Финальная проверка на конкурентный запрос (race condition)
    const conflict = await this.prisma.booking.findFirst({
      where: {
        masterId,
        status: { not: 'CANCELLED' },
        AND: [{ startsAt: { lt: endsAt } }, { endsAt: { gt: startsAt } }],
      },
    });

    if (conflict) {
      throw new BadRequestException('Время уже занято, выберите другое');
    }

    const booking = await this.prisma.booking.create({
      data: {
        clientId,
        masterId,
        serviceId,
        startsAt,
        endsAt,
        priceSnapshot: service.priceFrom,
        status: BookingStatus.CONFIRMED,
      },
      include: BOOKING_INCLUDE,
    });

    // Инвалидируем кэш слотов
    await this.slots.invalidateCache(masterId, date);

    return booking;
  }

  // ─── C-6: Записи клиента ────────────────────────────────────────
  async listForClient(clientId: string, status?: BookingStatus) {
    return this.prisma.booking.findMany({
      where: {
        clientId,
        ...(status ? { status } : {}),
      },
      include: BOOKING_INCLUDE,
      orderBy: { startsAt: 'desc' },
    });
  }

  // ─── M-7: Записи мастера ────────────────────────────────────────
  async listForMaster(userId: string, status?: BookingStatus) {
    const master = await this.prisma.masterProfile.findUnique({
      where: { userId },
    });
    if (!master) throw new NotFoundException('Профиль мастера не найден');

    return this.prisma.booking.findMany({
      where: {
        masterId: master.id,
        ...(status ? { status } : {}),
      },
      include: {
        service: true,
        client: { select: { name: true, avatarUrl: true, phone: true } },
        review: true,
      },
      orderBy: { startsAt: 'asc' },
    });
  }

  // ─── C-6a / M-7: Детали записи ─────────────────────────────────
  async getOne(bookingId: string, userId: string) {
    const booking = await this.prisma.booking.findUnique({
      where: { id: bookingId },
      include: {
        ...BOOKING_INCLUDE,
        client: { select: { name: true, avatarUrl: true, phone: true } },
      },
    });

    if (!booking) throw new NotFoundException('Запись не найдена');

    // Доступ: клиент или мастер этой записи
    const master = await this.prisma.masterProfile.findUnique({
      where: { userId },
    });
    const isMaster = master?.id === booking.masterId;
    const isClient = booking.clientId === userId;

    if (!isMaster && !isClient) throw new ForbiddenException();

    return booking;
  }

  // ─── Отмена записи (клиент или мастер) ─────────────────────────
  async cancel(bookingId: string, userId: string, dto: CancelBookingDto) {
    const booking = await this.prisma.booking.findUnique({
      where: { id: bookingId },
    });
    if (!booking) throw new NotFoundException('Запись не найдена');
    if (booking.status !== BookingStatus.CONFIRMED) {
      throw new BadRequestException('Можно отменить только подтверждённую запись');
    }

    const master = await this.prisma.masterProfile.findUnique({
      where: { userId },
    });
    const isMaster = master?.id === booking.masterId;
    const isClient = booking.clientId === userId;

    if (!isMaster && !isClient) throw new ForbiddenException();

    const cancelledBy: CancelledBy = isMaster
      ? CancelledBy.MASTER
      : CancelledBy.CLIENT;

    const updated = await this.prisma.booking.update({
      where: { id: bookingId },
      data: {
        status: BookingStatus.CANCELLED,
        cancelledBy,
        cancelReason: dto.reason,
      },
    });

    // Инвалидируем кэш слотов
    const dateStr = booking.startsAt.toISOString().split('T')[0];
    await this.slots.invalidateCache(booking.masterId, dateStr);

    return updated;
  }

  // ─── M-7: Мастер завершает запись ──────────────────────────────
  async complete(bookingId: string, userId: string) {
    const booking = await this.prisma.booking.findUnique({
      where: { id: bookingId },
    });
    if (!booking) throw new NotFoundException('Запись не найдена');
    if (booking.status !== BookingStatus.CONFIRMED) {
      throw new BadRequestException('Запись не в статусе CONFIRMED');
    }

    const master = await this.prisma.masterProfile.findUnique({
      where: { userId },
    });
    if (master?.id !== booking.masterId) throw new ForbiddenException();

    return this.prisma.booking.update({
      where: { id: bookingId },
      data: {
        status: BookingStatus.COMPLETED,
        completedAt: new Date(),
      },
    });
  }
}
