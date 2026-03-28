import { IsBoolean, IsInt, IsOptional, Max, Min } from 'class-validator';
import { Type } from 'class-transformer';

export class UpdateServiceDto {
  // templateId не меняется — нельзя сменить тип услуги, только удалить и создать новую

  @IsOptional()
  @IsInt()
  @Min(500)
  @Max(1_000_000)
  @Type(() => Number)
  priceFrom?: number;

  @IsOptional()
  @IsInt()
  @Min(15)
  @Max(480)
  @Type(() => Number)
  durationMin?: number;

  @IsOptional()
  @IsBoolean()
  isEnabled?: boolean;
}
