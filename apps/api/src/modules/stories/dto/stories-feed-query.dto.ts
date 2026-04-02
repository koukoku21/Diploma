import { IsEnum, IsNumber, IsOptional, Max, Min } from 'class-validator';
import { Type } from 'class-transformer';
import { ServiceCategory } from '@prisma/client';

export class StoriesFeedQueryDto {
  @Type(() => Number)
  @IsNumber()
  lat: number;

  @Type(() => Number)
  @IsNumber()
  lng: number;

  @Type(() => Number)
  @IsNumber()
  @Min(1)
  @Max(50)
  @IsOptional()
  radius?: number = 10;

  @IsOptional()
  @IsEnum(ServiceCategory)
  category?: ServiceCategory;
}
