import { IsString, Matches } from 'class-validator';

export class SendOtpPwaDto {
  @IsString()
  @Matches(/^\+?[0-9]{10,15}$/, { message: 'Неверный формат номера телефона' })
  phone: string;
}
