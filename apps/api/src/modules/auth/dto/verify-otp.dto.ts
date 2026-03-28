import { IsOptional, IsPhoneNumber, IsString, Length } from 'class-validator';

export class VerifyOtpDto {
  @IsString()
  @IsPhoneNumber('KZ')
  phone: string;

  @IsString()
  @Length(4, 4)
  code: string;

  @IsOptional()
  @IsString()
  name?: string;
}
