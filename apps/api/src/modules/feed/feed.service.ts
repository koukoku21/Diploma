import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../shared/prisma.service';
import { StoriesService } from '../stories/stories.service';
import { FeedQueryDto } from './dto/feed-query.dto';
import { StoriesFeedQueryDto } from '../stories/dto/stories-feed-query.dto';

const PAGE_SIZE = 20;

interface FeedMasterRow {
  id: string;
  user_name: string;
  avatar_url: string | null;
  bio: string | null;
  address: string;
  lat: number;
  lng: number;
  rating: number | null;
  review_count: number;
  buffer_minutes: number;
  is_active: boolean;
  is_boosted: boolean;
  distance_m: number;
  min_price: number | null;
  cover_url: string | null;
  specializations: string[];
}

@Injectable()
export class FeedService {
  constructor(
    private prisma: PrismaService,
    private stories: StoriesService,
  ) {}

  async getFeed(query: FeedQueryDto) {
    const { lat, lng, radius, serviceTemplateId, maxPrice, offset } = query;

    const templateFilter = serviceTemplateId
      ? `AND EXISTS (
           SELECT 1 FROM services s
           WHERE s."masterId" = mp.id
             AND s."isEnabled" = true
             AND s."templateId" = '${serviceTemplateId}'
         )`
      : '';

    const priceFilter = maxPrice !== undefined
      ? `AND (
           SELECT MIN("priceFrom") FROM services s
           WHERE s."masterId" = mp.id AND s."isEnabled" = true
         ) <= ${maxPrice}`
      : '';

    const rows = await this.prisma.$queryRaw<FeedMasterRow[]>`
      SELECT
        mp.id,
        u.name              AS user_name,
        u."avatarUrl"       AS avatar_url,
        mp.bio,
        mp.address,
        mp.lat,
        mp.lng,
        mp.rating,
        mp."reviewCount"    AS review_count,
        mp."bufferMinutes"  AS buffer_minutes,
        mp."isActive"       AS is_active,
        EXISTS (
          SELECT 1 FROM master_visibility mv
          WHERE mv."masterId" = mp.id
            AND mv."packageType" = 'BOOST'
            AND mv."isActive" = true
            AND mv."endsAt" > NOW()
        )                   AS is_boosted,
        ROUND(
          6371000 * 2 * ASIN(SQRT(
            POWER(SIN(RADIANS((mp.lat - ${lat}) / 2)), 2) +
            COS(RADIANS(${lat})) * COS(RADIANS(mp.lat)) *
            POWER(SIN(RADIANS((mp.lng - ${lng}) / 2)), 2)
          ))
        )::int              AS distance_m,
        (
          SELECT MIN("priceFrom") FROM services s
          WHERE s."masterId" = mp.id AND s."isEnabled" = true
        )                   AS min_price,
        (
          SELECT url FROM portfolio_photos pp
          WHERE pp."masterId" = mp.id AND pp."isCover" = true
          LIMIT 1
        )                   AS cover_url,
        ARRAY(
          SELECT DISTINCT st.category::text
          FROM services s
          JOIN service_templates st ON st.id = s."templateId"
          WHERE s."masterId" = mp.id AND s."isEnabled" = true
        )                   AS specializations
      FROM master_profiles mp
      JOIN users u ON u.id = mp."userId"
      WHERE
        mp."isVerified" = true
        AND mp."isActive" = true
        AND mp."isVisible" = true
        AND mp.status     = 'APPROVED'
        AND u."deletedAt" IS NULL
        AND mp.lat IS NOT NULL
        AND (
          6371000 * 2 * ASIN(SQRT(
            POWER(SIN(RADIANS((mp.lat - ${lat}) / 2)), 2) +
            COS(RADIANS(${lat})) * COS(RADIANS(mp.lat)) *
            POWER(SIN(RADIANS((mp.lng - ${lng}) / 2)), 2)
          ))
        ) <= ${radius}
      ORDER BY is_boosted DESC, distance_m ASC
      LIMIT ${PAGE_SIZE}
      OFFSET ${offset}
    `;

    return {
      items: rows.map((r) => ({
        id: r.id,
        name: r.user_name,
        avatarUrl: r.avatar_url,
        bio: r.bio,
        address: r.address,
        lat: r.lat,
        lng: r.lng,
        rating: r.rating,
        reviewCount: r.review_count,
        bufferMinutes: r.buffer_minutes,
        isActive: r.is_active,
        isBoosted: r.is_boosted,
        distanceM: r.distance_m,
        minPrice: r.min_price,
        coverUrl: r.cover_url,
        specializations: r.specializations,
      })),
      hasMore: rows.length === PAGE_SIZE,
      nextOffset: offset + rows.length,
    };
  }

  // Объединённый эндпоинт для главного экрана C-1
  async getHome(query: FeedQueryDto) {
    const [masters, stories] = await Promise.all([
      this.getFeed(query),
      this.stories.getFeed({
        lat: query.lat,
        lng: query.lng,
        radius: query.radius / 1000,
      } as StoriesFeedQueryDto),
    ]);

    return { stories, masters };
  }
}