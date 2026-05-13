import { IsString, IsNotEmpty, Matches, Length } from 'class-validator';

export class BookSlotPwaDto {
  @IsString()
  @IsNotEmpty()
  name: string;

  @IsString()
  @Matches(/^\+?[0-9]{10,15}$/, { message: 'Неверный формат номера телефона' })
  phone: string;

  @IsString()
  @Length(4, 4)
  otpCode: string;

  @IsString()
  serviceId: string;

  @IsString()
  @Matches(/^\d{4}-\d{2}-\d{2}$/, { message: 'Формат даты: YYYY-MM-DD' })
  date: string;

  @IsString()
  @Matches(/^\d{2}:\d{2}$/, { message: 'Формат времени: HH:MM' })
  time: string;
}
