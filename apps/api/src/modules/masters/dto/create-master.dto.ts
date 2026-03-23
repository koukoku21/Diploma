import {
  IsArray,
  IsEnum,
  IsLatitude,
  IsLongitude,
  IsOptional,
  IsString,
  MaxLength,
} from 'class-validator';
import { ServiceCategory } from '@prisma/client';

export class CreateMasterDto {
  @IsString()
  address: string;

  @IsLatitude()
  lat: number;

  @IsLongitude()
  lng: number;

  @IsOptional()
  @IsString()
  @MaxLength(300)
  bio?: string;

  @IsArray()
  @IsEnum(ServiceCategory, { each: true })
  specializations: ServiceCategory[];
}
