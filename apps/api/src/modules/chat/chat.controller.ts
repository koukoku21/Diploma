import { Body, Controller, Get, Param, Post, Query, UseGuards } from '@nestjs/common';
import { ChatService } from './chat.service';
import { ChatGateway } from './chat.gateway';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';
import { SendMessageDto } from './dto/send-message.dto';

@UseGuards(JwtAuthGuard)
@Controller('chat')
export class ChatController {
  constructor(
    private chat: ChatService,
    private gateway: ChatGateway,
  ) {}

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

  // Отправить сообщение через HTTP (fallback когда сокет недоступен)
  @Post('rooms/:roomId/messages')
  async sendMessage(
    @CurrentUser() user: { id: string },
    @Param('roomId') roomId: string,
    @Body('content') content: string,
  ) {
    const dto: SendMessageDto = { roomId, content };
    const message = await this.chat.saveMessage(user.id, dto);
    // Broadcast через gateway всем участникам комнаты
    this.gateway.server?.to(roomId).emit('new_message', message);
    return message;
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
