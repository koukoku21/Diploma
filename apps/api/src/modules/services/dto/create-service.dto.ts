import { IsInt, IsUUID, Max, Min } from 'class-validator';
import { Type } from 'class-transformer';

export class CreateServiceDto {
  @IsUUID()
  templateId: string; // Ссылка на ServiceTemplate — название и категория берутся оттуда

  @IsInt()
  @Min(500)
  @Max(1_000_000)
  @Type(() => Number)
  priceFrom: number; // в тенге

  @IsInt()
  @Min(15)
  @Max(480)
  @Type(() => Number)
  durationMin: number; // в минутах
}
