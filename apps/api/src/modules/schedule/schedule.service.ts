import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../shared/prisma.service';
import { UpdateScheduleDto } from './dto/update-schedule.dto';
import { CreateOverrideDto } from './dto/schedule-override.dto';

@Injectable()
export class ScheduleService {
  constructor(private prisma: PrismaService) {}

  private async getMasterOrThrow(userId: string) {
    const master = await this.prisma.masterProfile.findUnique({
      where: { userId },
    });
    if (!master) throw new NotFoundException('Профиль мастера не найден');
    return master;
  }

  // M-8: получить недельное расписание
  async getSchedule(userId: string) {
    const master = await this.getMasterOrThrow(userId);
    return this.prisma.schedule.findMany({
      where: { masterId: master.id },
      orderBy: { dayOfWeek: 'asc' },
    });
  }

  // M-8: обновить расписание (bulk upsert)
  async updateSchedule(userId: string, dto: UpdateScheduleDto) {
    const master = await this.getMasterOrThrow(userId);

    await Promise.all(
      dto.slots.map((day) =>
        this.prisma.schedule.upsert({
          where: {
            masterId_dayOfWeek: {
              masterId: master.id,
              dayOfWeek: day.dayOfWeek,
            },
          },
          create: {
            masterId: master.id,
            dayOfWeek: day.dayOfWeek,
            isDayOff: !day.isWorking,
            startTime: day.startTime ?? '10:00',
            endTime: day.endTime ?? '19:00',
          },
          update: {
            isDayOff: !day.isWorking,
            startTime: day.startTime ?? '10:00',
            endTime: day.endTime ?? '19:00',
          },
        }),
      ),
    );

    return this.getSchedule(userId);
  }

  // M-8a: список особых дней
  async getOverrides(userId: string) {
    const master = await this.getMasterOrThrow(userId);
    return this.prisma.scheduleOverride.findMany({
      where: {
        masterId: master.id,
        date: { gte: new Date() }, // только будущие
      },
      orderBy: { date: 'asc' },
    });
  }

  // M-8a: добавить/обновить особый день
  async upsertOverride(userId: string, dto: CreateOverrideDto) {
    const master = await this.getMasterOrThrow(userId);
    const date = new Date(dto.date);

    return this.prisma.scheduleOverride.upsert({
      where: { masterId_date: { masterId: master.id, date } },
      create: {
        masterId: master.id,
        date,
        isDayOff: dto.isDayOff,
        startTime: dto.startTime,
        endTime: dto.endTime,
      },
      update: {
        isDayOff: dto.isDayOff,
        startTime: dto.startTime,
        endTime: dto.endTime,
      },
    });
  }

  // M-8a: удалить особый день
  async deleteOverride(userId: string, overrideId: string) {
    const master = await this.getMasterOrThrow(userId);
    await this.prisma.scheduleOverride.deleteMany({
      where: { id: overrideId, masterId: master.id },
    });
    return { message: 'Удалено' };
  }
}
