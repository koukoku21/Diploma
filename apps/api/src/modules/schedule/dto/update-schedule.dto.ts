import { Type } from 'class-transformer';
import {
  IsArray,
  IsBoolean,
  IsInt,
  IsOptional,
  IsString,
  Matches,
  Max,
  Min,
  ValidateNested,
} from 'class-validator';

const TIME_REGEX = /^([01]\d|2[0-3]):[0-5]\d$/; // HH:MM

export class ScheduleDayDto {
  @IsInt()
  @Min(0)
  @Max(6)
  dayOfWeek: number;

  @IsBoolean()
  isDayOff: boolean;

  @IsOptional()
  @IsString()
  @Matches(TIME_REGEX, { message: 'Формат времени: HH:MM' })
  startTime?: string;

  @IsOptional()
  @IsString()
  @Matches(TIME_REGEX, { message: 'Формат времени: HH:MM' })
  endTime?: string;
}

export class UpdateScheduleDto {
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => ScheduleDayDto)
  days: ScheduleDayDto[];
}
