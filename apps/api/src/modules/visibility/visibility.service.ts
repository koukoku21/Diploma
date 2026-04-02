import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../shared/prisma.service';
import { RedisService } from '../../shared/redis.service';
import { NotificationsService } from '../notifications/notifications.service';
import { NotificationType, VisibilityPackage } from '@prisma/client';
import { ActivateVisibilityDto } from './dto/activate-visibility.dto';

const PACKAGE_DURATION_DAYS: Record<VisibilityPackage, number> = {
  WEEK: 7,
  MONTH: 30,
  BOOST: 1,
};

// Redis ключ для буста мастера: boost:{masterId} → '1', TTL = 24h
const boostKey = (masterId: string) => `boost:${masterId}`;
const BOOST_TTL_SECONDS = 24 * 60 * 60;

@Injectable()
export class VisibilityService {
  constructor(
    private prisma: PrismaService,
    private redis: RedisService,
    private notifications: NotificationsService,
  ) {}

  async activate(userId: string, dto: ActivateVisibilityDto) {
    const master = await this.prisma.masterProfile.findUnique({
      where: { userId },
    });
    if (!master) throw new NotFoundException('Master profile not found');

    const days = PACKAGE_DURATION_DAYS[dto.packageType];
    const now = new Date();
    const endsAt = new Date(now.getTime() + days * 24 * 60 * 60 * 1000);

    const [visibility] = await this.prisma.$transaction([
      this.prisma.masterVisibility.create({
        data: {
          masterId: master.id,
          packageType: dto.packageType,
          paidAmount: dto.paidAmount,
          startsAt: now,
          endsAt,
        },
      }),
      this.prisma.masterProfile.update({
        where: { id: master.id },
        data: { isVisible: true },
      }),
    ]);

    if (dto.packageType === VisibilityPackage.BOOST) {
      await this.redis.set(boostKey(master.id), '1', BOOST_TTL_SECONDS);
    }

    return { visibility, endsAt };
  }

  async getStatus(userId: string) {
    const master = await this.prisma.masterProfile.findUnique({
      where: { userId },
      select: { id: true, isVisible: true, createdAt: true },
    });
    if (!master) throw new NotFoundException('Master profile not found');

    const threeMonthsAfterJoin = new Date(master.createdAt);
    threeMonthsAfterJoin.setMonth(threeMonthsAfterJoin.getMonth() + 3);
    const isFreeTrialActive = new Date() < threeMonthsAfterJoin;

    const activeVisibility = await this.prisma.masterVisibility.findFirst({
      where: {
        masterId: master.id,
        isActive: true,
        endsAt: { gt: new Date() },
      },
      orderBy: { endsAt: 'desc' },
    });

    const isBoosted = !!(await this.redis.get(boostKey(master.id)));

    return {
      isVisible: master.isVisible,
      isFreeTrialActive,
      freeTrialEndsAt: isFreeTrialActive ? threeMonthsAfterJoin : null,
      activePackage: activeVisibility ?? null,
      isBoosted,
    };
  }

  async isMasterBoosted(masterId: string): Promise<boolean> {
    return !!(await this.redis.get(boostKey(masterId)));
  }

  // Вызывается cron job'ом каждый час
  async deactivateExpired() {
    const now = new Date();

    const expired = await this.prisma.masterVisibility.findMany({
      where: { isActive: true, endsAt: { lt: now } },
      select: { id: true, masterId: true },
    });

    if (expired.length === 0) return { deactivated: 0 };

    const masterIds = [...new Set(expired.map((v) => v.masterId))];

    await this.prisma.masterVisibility.updateMany({
      where: { id: { in: expired.map((v) => v.id) } },
      data: { isActive: false },
    });

    for (const masterId of masterIds) {
      const hasActive = await this.prisma.masterVisibility.findFirst({
        where: { masterId, isActive: true, endsAt: { gt: now } },
      });

      const master = await this.prisma.masterProfile.findUnique({
        where: { id: masterId },
        select: { createdAt: true, userId: true },
      });
      if (!master) continue;

      const freeTrialEnd = new Date(master.createdAt);
      freeTrialEnd.setMonth(freeTrialEnd.getMonth() + 3);
      const isFreeTrial = now < freeTrialEnd;

      if (!hasActive && !isFreeTrial) {
        await this.prisma.masterProfile.update({
          where: { id: masterId },
          data: { isVisible: false },
        });
        await this.notifications.send({
          userId: master.userId,
          type: NotificationType.VISIBILITY_EXPIRED,
          title: 'Вы скрыты из ленты',
          body: 'Период видимости истёк. Продлите, чтобы клиенты снова вас видели.',
        });
      }
    }

    return { deactivated: masterIds.length };
  }

  // Вызывается cron job'ом раз в день
  async notifyExpiringSoon() {
    const in24h = new Date(Date.now() + 24 * 60 * 60 * 1000);

    const expiringSoon = await this.prisma.masterVisibility.findMany({
      where: {
        isActive: true,
        endsAt: { gt: new Date(), lt: in24h },
      },
      include: {
        master: { select: { userId: true } },
      },
    });

    for (const v of expiringSoon) {
      await this.notifications.send({
        userId: v.master.userId,
        type: NotificationType.VISIBILITY_EXPIRING_SOON,
        title: 'Видимость заканчивается завтра',
        body: 'Продлите пакет, чтобы не пропасть из ленты.',
      });
    }

    return { notified: expiringSoon.length };
  }
}
