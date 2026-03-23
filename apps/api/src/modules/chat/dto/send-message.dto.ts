import { IsEnum, IsOptional, IsString, IsUUID, MaxLength } from 'class-validator';
import { MessageType } from '@prisma/client';

export class SendMessageDto {
  @IsUUID()
  roomId: string;

  @IsString()
  @MaxLength(2000)
  content: string;

  @IsOptional()
  @IsEnum(MessageType)
  type?: MessageType = MessageType.TEXT;
}
