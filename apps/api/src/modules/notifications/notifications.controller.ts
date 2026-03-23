import { Body, Controller, Delete, Get, Post, Query, UseGuards } from '@nestjs/common';
import { NotificationsService } from './notifications.service';
import { RegisterTokenDto } from './dto/register-token.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';

@UseGuards(JwtAuthGuard)
@Controller('notifications')
export class NotificationsController {
  constructor(private notifications: NotificationsService) {}

  @Get()
  getHistory(@CurrentUser() user: { id: string }) {
    return this.notifications.getHistory(user.id);
  }

  @Get('unread-count')
  getUnreadCount(@CurrentUser() user: { id: string }) {
    return this.notifications.getUnreadCount(user.id);
  }

  @Post('token')
  registerToken(
    @CurrentUser() user: { id: string },
    @Body() dto: RegisterTokenDto,
  ) {
    return this.notifications.registerToken(user.id, dto.token, dto.platform);
  }

  @Delete('token')
  removeToken(@Query('token') token: string) {
    return this.notifications.removeToken(token);
  }
}
