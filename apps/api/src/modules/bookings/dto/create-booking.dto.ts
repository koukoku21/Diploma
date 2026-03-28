import { IsISO8601, IsString, IsUUID, Matches } from 'class-validator';

export class CreateBookingDto {
  @IsUUID()
  masterId: string;

  @IsUUID()
  serviceId: string;

  @IsISO8601({ strict: false, strictSeparator: true })
  date: string; // YYYY-MM-DD

  @IsString()
  @Matches(/^([01]\d|2[0-3]):[0-5]\d$/, { message: 'Формат времени: HH:MM' })
  time: string; // HH:MM
}
