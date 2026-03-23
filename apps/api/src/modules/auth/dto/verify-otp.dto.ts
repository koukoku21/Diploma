import { IsPhoneNumber, IsString, Length } from 'class-validator';

export class VerifyOtpDto {
  @IsString()
  @IsPhoneNumber('KZ')
  phone: string;

  @IsString()
  @Length(4, 4)
  code: string;

  // Имя — только при первой регистрации (экран A-4)
  name?: string;
}
