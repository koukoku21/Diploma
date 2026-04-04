import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../../shared/prisma.service';
import { StoryPackage, StoryStatus } from '@prisma/client';
import { CreateStoryDto } from './dto/create-story.dto';
import { RejectStoryDto } from './dto/reject-story.dto';
import { StoriesFeedQueryDto } from './dto/stories-feed-query.dto';
import { TelegramService } from '../telegram/telegram.service';

const PACKAGE_DURATION_DAYS: Record<StoryPackage, number> = {
  DAY: 1,
  WEEK: 7,
  MONTH: 30,
};

const PACKAGE_RADIUS_KM: Record<StoryPackage, number> = {
  DAY: 5,
  WEEK: 5,
  MONTH: 10,
};

@Injectable()
export class StoriesService {
  constructor(
    private prisma: PrismaService,
    private telegram: TelegramService,
  ) {}

  async create(userId: string, dto: CreateStoryDto) {
    const salon = await this.prisma.salonProfile.findUnique({
      where: { ownerId: userId },
    });
    if (!salon) throw new ForbiddenException('Salon profile not found');

    const story = await this.prisma.story.create({
      data: {
        salonId: salon.id,
        mediaUrl: dto.mediaUrl,
        caption: dto.caption,
        category: dto.category,
        packageType: dto.packageType,
        paidAmount: dto.paidAmount,
        radiusKm: PACKAGE_RADIUS_KM[dto.packageType],
        status: StoryStatus.PENDING,
      },
    });

    // Уведомление в Telegram (fire-and-forget)
    this.telegram.notifyNewStory({
      id: story.id,
      salonName: salon.name,
      packageType: story.packageType,
      paidAmount: story.paidAmount ? Number(story.paidAmount) : null,
      caption: story.caption,
      mediaUrl: story.mediaUrl,
    }).catch(() => {});

    return story;
  }

  async getFeed(query: StoriesFeedQueryDto) {
    const radiusMeters = (query.radius ?? 10) * 1000;
    const now = new Date();

    // Достаём ACTIVE сторисы через JOIN с salon_profiles
    // Prisma хранит поля как camelCase — используем кавычки в SQL
    const stories = await this.prisma.$queryRaw<any[]>`
      SELECT
        s.id,
        s."mediaUrl",
        s.caption,
        s.category,
        s."isPaid",
        s."expiresAt",
        s."viewCount",
        sp.name        AS "salonName",
        sp."logoUrl"   AS "salonLogoUrl"
      FROM stories s
      JOIN salon_profiles sp ON sp.id = s."salonId"
      WHERE s.status = 'ACTIVE'
        AND s."expiresAt" > ${now}
        AND (
          ${query.category ?? null} IS NULL
          OR s.category = ${query.category ?? null}::"ServiceCategory"
        )
      ORDER BY s."isPaid" DESC, s."expiresAt" ASC
      LIMIT 20
    `;

    return stories;
  }

  async recordView(storyId: string, userId: string) {
    const story = await this.prisma.story.findUnique({ where: { id: storyId } });
    if (!story || story.status !== StoryStatus.ACTIVE) throw new NotFoundException();

    await this.prisma.$transaction([
      this.prisma.storyView.upsert({
        where: { storyId_userId: { storyId, userId } },
        create: { storyId, userId },
        update: { viewedAt: new Date() },
      }),
      this.prisma.story.update({
        where: { id: storyId },
        data: { viewCount: { increment: 1 } },
      }),
    ]);
  }

  async approve(storyId: string) {
    const story = await this.prisma.story.findUnique({ where: { id: storyId } });
    if (!story) throw new NotFoundException();

    const days = PACKAGE_DURATION_DAYS[story.packageType as StoryPackage];
    const now = new Date();
    const expiresAt = new Date(now.getTime() + days * 24 * 60 * 60 * 1000);

    return this.prisma.story.update({
      where: { id: storyId },
      data: {
        status: StoryStatus.ACTIVE,
        startsAt: now,
        expiresAt,
      },
    });
  }

  async reject(storyId: string, dto: RejectStoryDto) {
    const story = await this.prisma.story.findUnique({ where: { id: storyId } });
    if (!story) throw new NotFoundException();

    return this.prisma.story.update({
      where: { id: storyId },
      data: {
        status: StoryStatus.REJECTED,
        rejectReason: dto.reason,
      },
    });
  }

  async getPendingForAdmin() {
    return this.prisma.story.findMany({
      where: { status: StoryStatus.PENDING },
      include: {
        salon: { select: { name: true, logoUrl: true } },
      },
      orderBy: { createdAt: 'asc' },
    });
  }

  async getActiveForAdmin() {
    return this.prisma.story.findMany({
      where: { status: StoryStatus.ACTIVE },
      include: {
        salon: { select: { name: true, logoUrl: true } },
      },
      orderBy: { expiresAt: 'asc' },
    });
  }

  async deactivate(storyId: string) {
    return this.prisma.story.update({
      where: { id: storyId },
      data: { status: StoryStatus.EXPIRED },
    });
  }

  // Вызывается cron job'ом каждый час
  async expireStories() {
    const result = await this.prisma.story.updateMany({
      where: {
        status: StoryStatus.ACTIVE,
        expiresAt: { lt: new Date() },
      },
      data: { status: StoryStatus.EXPIRED },
    });
    return result.count;
  }
}
