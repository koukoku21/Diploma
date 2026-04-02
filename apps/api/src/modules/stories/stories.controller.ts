import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { StoriesService } from './stories.service';
import { CreateStoryDto } from './dto/create-story.dto';
import { RejectStoryDto } from './dto/reject-story.dto';
import { StoriesFeedQueryDto } from './dto/stories-feed-query.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { AdminGuard } from '../admin/guards/admin.guard';

@Controller('stories')
export class StoriesController {
  constructor(private readonly stories: StoriesService) {}

  // Салон создаёт заявку на сторис
  @UseGuards(JwtAuthGuard)
  @Post()
  create(@CurrentUser() user: any, @Body() dto: CreateStoryDto) {
    return this.stories.create(user.id, dto);
  }

  // Лента сторисов для клиента по геолокации
  @UseGuards(JwtAuthGuard)
  @Get('feed')
  getFeed(@Query() query: StoriesFeedQueryDto) {
    return this.stories.getFeed(query);
  }

  // Записать просмотр сториса
  @UseGuards(JwtAuthGuard)
  @Post(':id/view')
  recordView(@Param('id') id: string, @CurrentUser() user: any) {
    return this.stories.recordView(id, user.id);
  }

  // Admin: список заявок на модерацию
  @UseGuards(JwtAuthGuard, AdminGuard)
  @Get('admin/pending')
  getPending() {
    return this.stories.getPendingForAdmin();
  }

  // Admin: список активных сторисов
  @UseGuards(JwtAuthGuard, AdminGuard)
  @Get('admin/active')
  getActive() {
    return this.stories.getActiveForAdmin();
  }

  // Admin: одобрить сторис
  @UseGuards(JwtAuthGuard, AdminGuard)
  @Patch(':id/approve')
  approve(@Param('id') id: string) {
    return this.stories.approve(id);
  }

  // Admin: отклонить сторис
  @UseGuards(JwtAuthGuard, AdminGuard)
  @Patch(':id/reject')
  reject(@Param('id') id: string, @Body() dto: RejectStoryDto) {
    return this.stories.reject(id, dto);
  }

  // Admin: снять активный сторис досрочно
  @UseGuards(JwtAuthGuard, AdminGuard)
  @Patch(':id/deactivate')
  deactivate(@Param('id') id: string) {
    return this.stories.deactivate(id);
  }
}
