import { IsString, Matches } from 'class-validator';

export class SendOtpDto {
  @IsString()
  @Matches(/^\+7\d{10}$/, { message: 'Введите корректный номер телефона (+7XXXXXXXXXX)' })
  phone: string;
}
