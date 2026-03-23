import {
  ConnectedSocket,
  MessageBody,
  OnGatewayConnection,
  OnGatewayDisconnect,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
  WsException,
} from '@nestjs/websockets';
import { Server, Socket } from 'socket.io';
import { UseGuards } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { ChatService } from './chat.service';
import { SendMessageDto } from './dto/send-message.dto';
import { RedisService } from '../../shared/redis.service';

const PUBSUB_CHANNEL = 'chat:messages';

@WebSocketGateway({
  cors: { origin: '*' },
  namespace: '/chat',
})
export class ChatGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer()
  server: Server;

  // userId → Set<socketId> (один юзер может открыть несколько вкладок)
  private userSockets = new Map<string, Set<string>>();

  constructor(
    private chatService: ChatService,
    private jwt: JwtService,
    private config: ConfigService,
    private redis: RedisService,
  ) {}

  // ─── Подключение ────────────────────────────────────────────────
  async handleConnection(socket: Socket) {
    try {
      const token =
        (socket.handshake.auth?.token as string) ||
        socket.handshake.headers.authorization?.replace('Bearer ', '');

      if (!token) throw new WsException('Нет токена');

      const payload = this.jwt.verify(token, {
        secret: this.config.getOrThrow('JWT_SECRET'),
      });

      socket.data.userId = payload.sub as string;

      // Регистрируем сокет
      if (!this.userSockets.has(payload.sub)) {
        this.userSockets.set(payload.sub, new Set());
      }
      this.userSockets.get(payload.sub)!.add(socket.id);
    } catch {
      socket.disconnect(true);
    }
  }

  handleDisconnect(socket: Socket) {
    const userId = socket.data.userId as string;
    if (userId) {
      const sockets = this.userSockets.get(userId);
      sockets?.delete(socket.id);
      if (sockets?.size === 0) this.userSockets.delete(userId);
    }
  }

  // ─── Вход в комнату ─────────────────────────────────────────────
  @SubscribeMessage('join_room')
  async handleJoinRoom(
    @ConnectedSocket() socket: Socket,
    @MessageBody() roomId: string,
  ) {
    const userId = socket.data.userId as string;
    if (!userId) throw new WsException('Не авторизован');

    await this.chatService.getRoom(userId, roomId); // проверка доступа
    await socket.join(roomId);
    return { event: 'joined', roomId };
  }

  // ─── Отправка сообщения ─────────────────────────────────────────
  @SubscribeMessage('send_message')
  async handleSendMessage(
    @ConnectedSocket() socket: Socket,
    @MessageBody() dto: SendMessageDto,
  ) {
    const userId = socket.data.userId as string;
    if (!userId) throw new WsException('Не авторизован');

    const message = await this.chatService.saveMessage(userId, dto);

    // Доставляем всем участникам комнаты
    this.server.to(dto.roomId).emit('new_message', message);

    // Redis Pub/Sub — для горизонтального масштабирования
    // (другие инстансы API подпишутся на этот канал)
    await this.redis.set(
      `${PUBSUB_CHANNEL}:${message.id}`,
      JSON.stringify(message),
      60,
    );

    return message;
  }

  // ─── Индикатор печати ───────────────────────────────────────────
  @SubscribeMessage('typing')
  handleTyping(
    @ConnectedSocket() socket: Socket,
    @MessageBody() roomId: string,
  ) {
    const userId = socket.data.userId as string;
    socket.to(roomId).emit('user_typing', { userId });
  }
}
