import { IsEnum, IsInt, Min } from 'class-validator';
import { VisibilityPackage } from '@prisma/client';

export class ActivateVisibilityDto {
  @IsEnum(VisibilityPackage)
  packageType: VisibilityPackage;

  @IsInt()
  @Min(0)
  paidAmount: number;
}
