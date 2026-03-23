import { Body, Controller, Get, Param, Post, Query, UseGuards } from '@nestjs/common';
import { ReviewsService } from './reviews.service';
import { CreateReviewDto } from './dto/create-review.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';

@UseGuards(JwtAuthGuard)
@Controller('reviews')
export class ReviewsController {
  constructor(private reviews: ReviewsService) {}

  // C-7: оставить отзыв
  @Post()
  create(@CurrentUser() user: { id: string }, @Body() dto: CreateReviewDto) {
    return this.reviews.create(user.id, dto);
  }

  // C-2b: отзывы мастера
  @Get('master/:masterId')
  listForMaster(
    @Param('masterId') masterId: string,
    @Query('take') take?: number,
    @Query('skip') skip?: number,
  ) {
    return this.reviews.listForMaster(masterId, take ?? 20, skip ?? 0);
  }
}
