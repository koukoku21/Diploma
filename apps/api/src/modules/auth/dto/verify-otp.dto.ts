import { IsOptional, IsString, Length, Matches } from 'class-validator';

export class VerifyOtpDto {
  @IsString()
  @Matches(/^\+7\d{10}$/, { message: 'Введите корректный номер телефона (+7XXXXXXXXXX)' })
  phone: string;

  @IsString()
  @Length(4, 4)
  code: string;

  @IsOptional()
  @IsString()
  name?: string;
}
