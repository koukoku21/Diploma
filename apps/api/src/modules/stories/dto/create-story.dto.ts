import { IsEnum, IsInt, IsOptional, IsString, IsUrl, Max, Min } from 'class-validator';
import { ServiceCategory, StoryPackage } from '@prisma/client';

export class CreateStoryDto {
  @IsUrl()
  mediaUrl: string;

  @IsOptional()
  @IsString()
  caption?: string;

  @IsOptional()
  @IsEnum(ServiceCategory)
  category?: ServiceCategory;

  @IsEnum(StoryPackage)
  packageType: StoryPackage;

  @IsInt()
  @Min(0)
  paidAmount: number;
}
