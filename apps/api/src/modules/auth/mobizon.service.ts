import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import axios from 'axios';

@Injectable()
export class MobizonService {
  private readonly logger = new Logger(MobizonService.name);
  private readonly apiKey: string;
  private readonly sender: string;
  private readonly baseUrl = 'https://api.mobizon.kz/service';

  constructor(config: ConfigService) {
    this.apiKey = config.getOrThrow<string>('MOBIZON_API_KEY');
    this.sender = config.get<string>('MOBIZON_SENDER', 'Miraku');
  }

  async sendOtp(phone: string, code: string): Promise<void> {
    const text = `Miraku: ваш код подтверждения ${code}. Никому не сообщайте.`;

    // В dev режиме — не отправляем реальный SMS
    if (process.env.NODE_ENV !== 'production') {
      this.logger.debug(`[DEV] OTP для ${phone}: ${code}`);
      return;
    }

    try {
      const response = await axios.post(
        `${this.baseUrl}/message/sendsmsmessage`,
        null,
        {
          params: {
            recipient: phone.replace('+', ''),
            text,
            from: this.sender,
            apiKey: this.apiKey,
            output: 'json',
            api: 1,
          },
        },
      );

      if (response.data?.code !== 0) {
        this.logger.error('Mobizon error', response.data);
        throw new Error(`Mobizon API error: ${response.data?.message}`);
      }
    } catch (err) {
      this.logger.error('Failed to send SMS', err);
      throw err;
    }
  }
}
