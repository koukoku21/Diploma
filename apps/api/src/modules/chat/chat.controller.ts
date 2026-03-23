import { Controller, Get, Param, Query, UseGuards } from '@nestjs/common';
import { ChatService } from './chat.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';

@UseGuards(JwtAuthGuard)
@Controller('chat')
export class ChatController {
  constructor(private chat: ChatService) {}

  // C-10 / M-13: список чатов
  @Get('rooms')
  getRooms(@CurrentUser() user: { id: string }) {
    return this.chat.getRooms(user.id);
  }

  // Найти комнату по masterId (для перехода из профиля мастера)
  @Get('rooms/by-master/:masterId')
  getRoomByMaster(
    @CurrentUser() user: { id: string },
    @Param('masterId') masterId: string,
  ) {
    return this.chat.getRoomByMaster(user.id, masterId);
  }

  // C-11: история сообщений
  @Get('rooms/:roomId/messages')
  getMessages(
    @CurrentUser() user: { id: string },
    @Param('roomId') roomId: string,
    @Query('take') take?: number,
    @Query('before') before?: string,
  ) {
    return this.chat.getMessages(user.id, roomId, take ?? 50, before);
  }
}
