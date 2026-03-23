import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../shared/prisma.service';
import { SendMessageDto } from './dto/send-message.dto';

@Injectable()
export class ChatService {
  constructor(private prisma: PrismaService) {}

  // C-10 / M-13: список чатов пользователя
  async getRooms(userId: string) {
    const roomUsers = await this.prisma.chatRoomUser.findMany({
      where: { userId },
      include: {
        room: {
          include: {
            master: {
              include: {
                user: { select: { name: true, avatarUrl: true } },
                portfolioPhotos: { where: { isCover: true }, take: 1 },
              },
            },
            messages: {
              orderBy: { createdAt: 'desc' },
              take: 1,
            },
          },
        },
      },
      orderBy: { room: { updatedAt: 'desc' } },
    });

    return roomUsers.map((ru) => ({
      roomId: ru.room.id,
      master: ru.room.master,
      lastMessage: ru.room.messages[0] ?? null,
      lastReadAt: ru.lastReadAt,
    }));
  }

  // C-11: история сообщений
  async getMessages(userId: string, roomId: string, take = 50, before?: string) {
    await this.assertRoomAccess(userId, roomId);

    const messages = await this.prisma.chatMessage.findMany({
      where: {
        roomId,
        ...(before ? { createdAt: { lt: new Date(before) } } : {}),
      },
      include: {
        sender: { select: { id: true, name: true, avatarUrl: true } },
      },
      orderBy: { createdAt: 'desc' },
      take,
    });

    // Помечаем сообщения собеседника как прочитанные
    await this.prisma.chatMessage.updateMany({
      where: { roomId, senderId: { not: userId }, isRead: false },
      data: { isRead: true },
    });

    await this.prisma.chatRoomUser.updateMany({
      where: { roomId, userId },
      data: { lastReadAt: new Date() },
    });

    return messages.reverse();
  }

  // Сохранить сообщение в БД (вызывается из Gateway)
  async saveMessage(senderId: string, dto: SendMessageDto) {
    await this.assertRoomAccess(senderId, dto.roomId);

    const message = await this.prisma.chatMessage.create({
      data: {
        roomId: dto.roomId,
        senderId,
        content: dto.content,
        type: dto.type ?? 'TEXT',
      },
      include: {
        sender: { select: { id: true, name: true, avatarUrl: true } },
      },
    });

    // Обновляем updatedAt комнаты (для сортировки в списке чатов)
    await this.prisma.chatRoom.update({
      where: { id: dto.roomId },
      data: { updatedAt: new Date() },
    });

    return message;
  }

  private async assertRoomAccess(userId: string, roomId: string) {
    const member = await this.prisma.chatRoomUser.findUnique({
      where: { roomId_userId: { roomId, userId } },
    });
    if (!member) throw new ForbiddenException('Нет доступа к этому чату');
    return member;
  }

  async getRoom(userId: string, roomId: string) {
    await this.assertRoomAccess(userId, roomId);
    return this.prisma.chatRoom.findUnique({
      where: { id: roomId },
      include: {
        master: {
          include: { user: { select: { name: true, avatarUrl: true } } },
        },
      },
    });
  }

  async getRoomByMaster(userId: string, masterId: string) {
    const room = await this.prisma.chatRoom.findUnique({
      where: { clientId_masterId: { clientId: userId, masterId } },
    });
    if (!room) throw new NotFoundException('Чат не найден — добавьте мастера в избранное');
    return room;
  }
}
