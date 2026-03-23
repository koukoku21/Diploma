import { IsISO8601, IsUUID } from 'class-validator';

export class SlotsQueryDto {
  @IsISO8601({ strict: true })
  date: string; // YYYY-MM-DD

  @IsUUID()
  serviceId: string;
}
