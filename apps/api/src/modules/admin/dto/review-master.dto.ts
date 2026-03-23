import { IsEnum, IsOptional, IsString, MaxLength } from 'class-validator';
import { MasterStatus } from '@prisma/client';

export class ReviewMasterDto {
  @IsEnum([MasterStatus.APPROVED, MasterStatus.REJECTED, MasterStatus.SUSPENDED])
  status: MasterStatus;

  @IsOptional()
  @IsString()
  @MaxLength(500)
  comment?: string; // причина отклонения
}
