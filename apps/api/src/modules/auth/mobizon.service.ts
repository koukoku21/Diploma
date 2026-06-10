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

      if (response.status === 200) {
        this.logger.log(`WhatsApp OTP sent to ${phone}`);
      } else {
        this.logger.warn(`Green API ${response.status}: ${JSON.stringify(response.data)}`);
        this.logger.warn(`[OTP FALLBACK] ${phone}: ${code}`);
      }
    } catch (err: any) {
      const status = err?.response?.status;
      const data = err?.response?.data;
      this.logger.warn(`Green API error ${status}: ${JSON.stringify(data)}`);
      this.logger.warn(`[OTP FALLBACK] ${phone}: ${code}`);
    }
  }
}
