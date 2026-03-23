import { ServiceCategory } from '@prisma/client';
import { IsEnum, IsInt, IsString, Max, MaxLength, Min } from 'class-validator';

export class CreateServiceDto {
  @IsString()
  @MaxLength(100)
  title: string;

  @IsEnum(ServiceCategory)
  category: ServiceCategory;

  @IsInt()
  @Min(500)
  @Max(1_000_000)
  priceFrom: number; // в тенге

  @IsInt()
  @Min(15)
  @Max(480)
  durationMin: number; // в минутах
}
