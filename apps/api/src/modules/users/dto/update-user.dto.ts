import { IsEnum, IsOptional, IsString, IsUrl, MaxLength } from 'class-validator';
import { Lang } from '@prisma/client';

export class UpdateUserDto {
  @IsOptional()
  @IsString()
  @MaxLength(60)
  name?: string;

  @IsOptional()
  @IsUrl()
  avatarUrl?: string;

  @IsOptional()
  @IsEnum(Lang)
  lang?: Lang;
}
