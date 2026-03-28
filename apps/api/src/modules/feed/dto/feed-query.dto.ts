import { Type } from 'class-transformer';
import {
  IsInt,
  IsLatitude,
  IsLongitude,
  IsNumber,
  IsOptional,
  IsUUID,
  Max,
  Min,
} from 'class-validator';

export class FeedQueryDto {
  @IsLatitude()
  @Type(() => Number)
  lat: number;

  @IsLongitude()
  @Type(() => Number)
  lng: number;

  // Радиус в метрах (500м — 25км), дефолт 5км
  @IsOptional()
  @IsNumber()
  @Min(500)
  @Max(25_000)
  @Type(() => Number)
  radius: number = 5_000;

  // Фильтр по шаблону услуги (заменяет старый category)
  @IsOptional()
  @IsUUID()
  serviceTemplateId?: string;

  // Максимальная цена в тенге
  @IsOptional()
  @IsInt()
  @Min(0)
  @Type(() => Number)
  maxPrice?: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  @Type(() => Number)
  offset: number = 0;
}
