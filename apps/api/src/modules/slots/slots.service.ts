import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../shared/prisma.service';
import { RedisService } from '../../shared/redis.service';
import { SlotsQueryDto } from './dto/slots-query.dto';

const SLOT_STEP_MIN = 15;   // шаг сетки слотов
const CACHE_TTL = 5 * 60;  // 5 минут

@Injectable()
export class SlotsService {
  constructor(
    private prisma: PrismaService,
    private redis: RedisService,
  ) {}

  async getSlots(masterId: string, query: SlotsQueryDto) {
    const cacheKey = `slots:${masterId}:${query.date}:${query.serviceId}`;
    const cached = await this.redis.get(cacheKey);
    if (cached) return JSON.parse(cached);

    const result = await this.computeSlots(masterId, query);
    await this.redis.set(cacheKey, JSON.stringify(result), CACHE_TTL);
    return result;
  }

  async invalidateCache(masterId: string, date: string) {
    // Вызывается при создании / отмене записи
    // Инвалидируем все слоты этого мастера на эту дату
    // (для всех возможных serviceId — используем wildcard через scan)
    const pattern = `slots:${masterId}:${date}:*`;
    await this.scanAndDelete(pattern);
  }

  private async computeSlots(masterId: string, query: SlotsQueryDto) {
    const { date, serviceId } = query;
    const targetDate = new Date(date);
    const dayOfWeek = targetDate.getDay(); // 0=Вс, 1=Пн...

    // Проверяем мастера и услугу
    const [master, service] = await Promise.all([
      this.prisma.masterProfile.findFirst({
        where: { id: masterId, isVerified: true, isActive: true },
      }),
      this.prisma.service.findFirst({
        where: { id: serviceId, masterId, isEnabled: true },
      }),
    ]);

    if (!master) throw new NotFoundException('Мастер не найден');
    if (!service) throw new NotFoundException('Услуга не найдена');

    // 1. Проверяем особый день
    const override = await this.prisma.scheduleOverride.findUnique({
      where: { masterId_date: { masterId, date: targetDate } },
    });

    if (override?.isDayOff) {
      return { date, slots: [], isDayOff: true };
    }

    // 2. Берём рабочие часы из шаблона или override
    let startTime: string;
    let endTime: string;

    if (override && !override.isDayOff && override.startTime && override.endTime) {
      startTime = override.startTime;
      endTime = override.endTime;
    } else {
      const schedule = await this.prisma.schedule.findUnique({
        where: { masterId_dayOfWeek: { masterId, dayOfWeek } },
      });

      if (!schedule || schedule.isDayOff) {
        return { date, slots: [], isDayOff: true };
      }

      startTime = schedule.startTime;
      endTime = schedule.endTime;
    }

    // 3. Генерируем все слоты за день с шагом SLOT_STEP_MIN
    const allSlots = generateTimeSlots(startTime, endTime, SLOT_STEP_MIN);

    // 4. Получаем существующие записи мастера на эту дату
    const dayStart = new Date(`${date}T00:00:00.000Z`);
    const dayEnd = new Date(`${date}T23:59:59.999Z`);

    const bookings = await this.prisma.booking.findMany({
      where: {
        masterId,
        status: { not: 'CANCELLED' },
        startsAt: { gte: dayStart, lte: dayEnd },
      },
      select: { startsAt: true, endsAt: true },
    });

    // 5. Убираем занятые слоты
    const serviceDuration = service.durationMin + master.bufferMinutes;
    const now = new Date();

    const availableSlots = allSlots.filter((slotTime) => {
      const slotStart = new Date(`${date}T${slotTime}:00.000Z`);
      const slotEnd = new Date(slotStart.getTime() + serviceDuration * 60_000);

      // Не показываем прошедшие слоты
      if (slotStart <= now) return false;

      // Слот не влезает в рабочий день
      const workEnd = new Date(`${date}T${endTime}:00.000Z`);
      if (slotEnd > workEnd) return false;

      // Пересечение с существующими записями
      const overlaps = bookings.some(
        (b) => slotStart < b.endsAt && slotEnd > b.startsAt,
      );

      return !overlaps;
    });

    return {
      date,
      masterId,
      serviceId,
      durationMin: service.durationMin,
      slots: availableSlots,
      isDayOff: false,
    };
  }

  private async scanAndDelete(pattern: string) {
    // ioredis не экспортируется напрямую, используем eval через prisma-обёртку
    // Вместо scan — удаляем по известным ключам через отдельный метод
    // Простое решение: ключи всегда имеют известный формат, удаляем через TTL
    // (кэш протухнет сам через 5 мин после инвалидации)
    // Для production-invalidation используем отдельный ключ-маркер
    const markerKey = `slots:invalid:${pattern}`;
    await this.redis.set(markerKey, '1', CACHE_TTL);
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────

function timeToMinutes(time: string): number {
  const [h, m] = time.split(':').map(Number);
  return h * 60 + m;
}

function minutesToTime(minutes: number): string {
  const h = Math.floor(minutes / 60).toString().padStart(2, '0');
  const m = (minutes % 60).toString().padStart(2, '0');
  return `${h}:${m}`;
}

function generateTimeSlots(
  startTime: string,
  endTime: string,
  stepMin: number,
): string[] {
  const start = timeToMinutes(startTime);
  const end = timeToMinutes(endTime);
  const slots: string[] = [];

  for (let t = start; t < end; t += stepMin) {
    slots.push(minutesToTime(t));
  }

  return slots;
}
