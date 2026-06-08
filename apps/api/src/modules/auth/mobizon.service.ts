import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import axios from 'axios';

@Injectable()
export class MobizonService {
  private readonly logger = new Logger(MobizonService.name);
  private readonly instanceId: string;
  private readonly token: string;

  constructor(config: ConfigService) {
    this.instanceId = config.getOrThrow<string>('GREENAPI_INSTANCE_ID');
    this.token = config.getOrThrow<string>('GREENAPI_TOKEN');
  }

  async sendOtp(phone: string, code: string): Promise<void> {
    const message = `Miraku: ваш код подтверждения *${code}*. Никому не сообщайте.`;

    if (process.env.NODE_ENV !== 'production') {
      this.logger.debug(`[DEV] OTP для ${phone}: ${code}`);
      return;
    }

    // chatId format: 77001234567@c.us (без +)
    const chatId = `${phone.replace('+', '')}@c.us`;

    try {
      const response = await axios.post(
        `https://api.green-api.com/waInstance${this.instanceId}/sendMessage/${this.token}`,
        { chatId, message },
      );

      this.logger.debug(`WhatsApp OTP sent to ${phone}, id=${response.data?.idMessage}`);
    } catch (err) {
      this.logger.error('Failed to send WhatsApp OTP', err);
      this.logger.warn(`[OTP FALLBACK] ${phone}: ${code}`);
    }
  }
}
