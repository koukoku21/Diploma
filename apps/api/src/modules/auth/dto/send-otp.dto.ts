import { IsPhoneNumber, IsString } from 'class-validator';

export class SendOtpDto {
  @IsString()
  @IsPhoneNumber('KZ')
  phone: string;
}
