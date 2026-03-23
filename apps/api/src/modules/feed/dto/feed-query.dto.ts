import { Type } from 'class-transformer';
import {
  IsEnum,
  IsInt,
  IsLatitude,
  IsLongitude,
  IsNumber,
  IsOptional,
  Max,
  Min,
} from 'class-validator';
import { ServiceCategory } from '@prisma/client';

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

  @IsOptional()
  @IsEnum(ServiceCategory)
  category?: ServiceCategory;

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
