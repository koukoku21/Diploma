import { IsEnum, IsInt, IsOptional, IsString, IsUUID, Max, Min, MinLength } from 'class-validator';
import { Type } from 'class-transformer';
import { ServiceCategory } from '@prisma/client';

export class CreateServiceDto {
  @IsOptional()
  @IsUUID()
  templateId?: string;

  @IsOptional()
  @IsString()
  @MinLength(2)
  name?: string;

  @IsOptional()
  @IsEnum(ServiceCategory)
  category?: ServiceCategory;

  // Поддерживаем оба варианта имён: priceFrom и price
  @IsOptional()
  @IsInt()
  @Min(100)
  @Max(1_000_000)
  @Type(() => Number)
  priceFrom?: number;

  @IsOptional()
  @IsInt()
  @Min(100)
  @Max(1_000_000)
  @Type(() => Number)
  price?: number;

  // Поддерживаем оба варианта имён: durationMin и duration
  @IsOptional()
  @IsInt()
  @Min(15)
  @Max(480)
  @Type(() => Number)
  durationMin?: number;

  @IsOptional()
  @IsInt()
  @Min(15)
  @Max(480)
  @Type(() => Number)
  duration?: number;
}
