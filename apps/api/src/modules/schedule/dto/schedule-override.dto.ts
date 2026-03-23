import { IsBoolean, IsISO8601, IsOptional, IsString, Matches } from 'class-validator';

const TIME_REGEX = /^([01]\d|2[0-3]):[0-5]\d$/;

export class CreateOverrideDto {
  @IsISO8601({ strict: true })
  date: string; // YYYY-MM-DD

  @IsBoolean()
  isDayOff: boolean;

  @IsOptional()
  @IsString()
  @Matches(TIME_REGEX)
  startTime?: string;

  @IsOptional()
  @IsString()
  @Matches(TIME_REGEX)
  endTime?: string;
}
