import { Controller, Get, Query, UseGuards } from '@nestjs/common';
import { FeedService } from './feed.service';
import { FeedQueryDto } from './dto/feed-query.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@UseGuards(JwtAuthGuard)
@Controller('feed')
export class FeedController {
  constructor(private feed: FeedService) {}

  // C-1: Лента мастеров
  @Get()
  getFeed(@Query() query: FeedQueryDto) {
    return this.feed.getFeed(query);
  }
}
