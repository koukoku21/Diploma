import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import axios from 'axios';

@Injectable()
export class MobizonService {
  private readonly logger = new Logger(MobizonService.name);
  private readonly login: string;
  private readonly password: string;
  private readonly sender: string;

  constructor(config: ConfigService) {
    this.login = config.getOrThrow<string>('SMSC_LOGIN');
    this.password = config.getOrThrow<string>('SMSC_PASSWORD');
    this.sender = config.get<string>('SMSC_SENDER', 'Miraku');
  }

  async sendOtp(phone: string, code: string): Promise<void> {
    const text = `Miraku: ваш код подтверждения ${code}. Никому не сообщайте.`;

    if (process.env.NODE_ENV !== 'production') {
      this.logger.debug(`[DEV] OTP для ${phone}: ${code}`);
      return;
    }

    try {
      const response = await axios.get('https://smsc.kz/sys/send.php', {
        params: {
          login: this.login,
          psw: this.password,
          phones: phone.replace('+', ''),
          mes: text,
          sender: this.sender,
          fmt: 3,
        },
      });

      if (response.data?.error_code) {
        this.logger.error('SMSC error', response.data);
        this.logger.warn(`[OTP FALLBACK] ${phone}: ${code}`);
        return;
      }

      this.logger.debug(`SMS sent to ${phone}, id=${response.data?.id}`);
    } catch (err) {
      this.logger.error('Failed to send SMS', err);
      this.logger.warn(`[OTP FALLBACK] ${phone}: ${code}`);
    }
  }
}
