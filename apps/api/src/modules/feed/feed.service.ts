import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../shared/prisma.service';
import { FeedQueryDto } from './dto/feed-query.dto';

const PAGE_SIZE = 20;

interface FeedMasterRow {
  id: string;
  user_name: string;
  avatar_url: string | null;
  bio: string | null;
  address: string;
  rating: number | null;
  review_count: number;
  buffer_minutes: number;
  is_active: boolean;
  distance_m: number;
  min_price: number | null;
  cover_url: string | null;
  specializations: string[];
}

@Injectable()
export class FeedService {
  constructor(private prisma: PrismaService) {}

  async getFeed(query: FeedQueryDto) {
    const { lat, lng, radius, category, maxPrice, offset } = query;

    // Фильтр по категории — подзапрос к master_specs
    const categoryFilter = category
      ? `AND EXISTS (
           SELECT 1 FROM master_specs ms
           WHERE ms.master_id = mp.id AND ms.category = '${category}'
         )`
      : '';

    // Фильтр по цене — минимальная цена услуги мастера
    const priceFilter = maxPrice !== undefined
      ? `AND (
           SELECT MIN(price_from) FROM services s
           WHERE s.master_id = mp.id AND s.is_enabled = true
         ) <= ${maxPrice}`
      : '';

    const rows = await this.prisma.$queryRaw<FeedMasterRow[]>`
      SELECT
        mp.id,
        u.name          AS user_name,
        u.avatar_url,
        mp.bio,
        mp.address,
        mp.rating,
        mp.review_count,
        mp.buffer_minutes,
        mp.is_active,
        ROUND(
          ST_Distance(mp.location, ST_SetSRID(ST_MakePoint(${lng}, ${lat}), 4326)::geography)
        )::int          AS distance_m,
        (
          SELECT MIN(price_from) FROM services s
          WHERE s.master_id = mp.id AND s.is_enabled = true
        )               AS min_price,
        (
          SELECT url FROM portfolio_photos pp
          WHERE pp.master_id = mp.id AND pp.is_cover = true
          LIMIT 1
        )               AS cover_url,
        ARRAY(
          SELECT category::text FROM master_specs ms
          WHERE ms.master_id = mp.id
        )               AS specializations
      FROM master_profiles mp
      JOIN users u ON u.id = mp.user_id
      WHERE
        mp.is_verified = true
        AND mp.is_active = true
        AND mp.status   = 'APPROVED'
        AND u.deleted_at IS NULL
        AND mp.location IS NOT NULL
        AND ST_DWithin(
          mp.location,
          ST_SetSRID(ST_MakePoint(${lng}, ${lat}), 4326)::geography,
          ${radius}
        )
      ORDER BY distance_m ASC
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
        rating: r.rating,
        reviewCount: r.review_count,
        bufferMinutes: r.buffer_minutes,
        isActive: r.is_active,
        distanceM: r.distance_m,
        minPrice: r.min_price,
        coverUrl: r.cover_url,
        specializations: r.specializations,
      })),
      hasMore: rows.length === PAGE_SIZE,
      nextOffset: offset + rows.length,
    };
  }
}
