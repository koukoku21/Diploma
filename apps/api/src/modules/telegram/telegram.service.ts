import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

@Injectable()
export class TelegramService {
  private readonly logger = new Logger(TelegramService.name);
  private readonly botToken: string;
  private readonly chatId: string;
  private readonly apiBase: string;

  constructor(private config: ConfigService) {
    this.botToken = this.config.get<string>('TELEGRAM_BOT_TOKEN', '');
    this.chatId   = this.config.get<string>('TELEGRAM_ADMIN_CHAT_ID', '');
    this.apiBase  = `https://api.telegram.org/bot${this.botToken}`;
  }

  private async call(method: string, body: object): Promise<any> {
    if (!this.botToken || !this.chatId) {
      this.logger.warn('Telegram not configured, skipping notification');
      return;
    }
    try {
      const res = await fetch(`${this.apiBase}/${method}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body),
      });
      return res.json();
    } catch (e) {
      this.logger.warn(`Telegram call "${method}" failed: ${e}`);
    }
  }

  async notifyNewStory(story: {
    id: string;
    salonName: string;
    packageType: string;
    paidAmount: number | null;
    caption?: string | null;
    mediaUrl: string;
  }) {
    const packageLabel: Record<string, string> = {
      DAY:   'День (2 990 ₸)',
      WEEK:  'Неделя (9 990 ₸)',
      MONTH: 'Месяц (24 990 ₸)',
    };
    const label = packageLabel[story.packageType] ?? story.packageType;
    const paid  = story.paidAmount ? `${story.paidAmount} ₸` : 'не указано';

    const text =
      `🎬 *Новый сторис на модерацию*\n\n` +
      `Салон: *${this._escape(story.salonName)}*\n` +
      `Пакет: ${label}\n` +
      `Оплачено: ${paid}\n` +
      (story.caption ? `Подпись: ${this._escape(story.caption)}\n` : '') +
      `\n[Открыть медиа](${story.mediaUrl})`;

    return this.call('sendMessage', {
      chat_id: this.chatId,
      text,
      parse_mode: 'Markdown',
      reply_markup: {
        inline_keyboard: [[
          { text: '✅ Опубликовать', callback_data: `approve_story:${story.id}` },
          { text: '❌ Отклонить',    callback_data: `reject_story:${story.id}`  },
        ]],
      },
    });
  }

  async notifyNewMaster(master: {
    id: string;
    userName: string;
    phone: string;
    address: string;
    specializations: string[];
  }) {
    const specs = master.specializations.join(', ') || '—';

    const text =
      `👤 *Новая заявка мастера на верификацию*\n\n` +
      `Имя: *${this._escape(master.userName)}*\n` +
      `Телефон: ${master.phone}\n` +
      `Адрес: ${this._escape(master.address)}\n` +
      `Специализации: ${specs}`;

    return this.call('sendMessage', {
      chat_id: this.chatId,
      text,
      parse_mode: 'Markdown',
      reply_markup: {
        inline_keyboard: [[
          { text: '✅ Одобрить',  callback_data: `approve_master:${master.id}` },
          { text: '❌ Отклонить', callback_data: `reject_master:${master.id}`  },
        ]],
      },
    });
  }

  async answerCallbackQuery(callbackQueryId: string, text: string) {
    return this.call('answerCallbackQuery', {
      callback_query_id: callbackQueryId,
      text,
    });
  }

  async editMessageText(chatId: string | number, messageId: number, text: string) {
    return this.call('editMessageText', {
      chat_id: chatId,
      message_id: messageId,
      text,
      parse_mode: 'Markdown',
    });
  }

  async setWebhook(webhookUrl: string) {
    return this.call('setWebhook', { url: webhookUrl });
  }

  private _escape(s: string) {
    return s.replace(/[_*[\]()~`>#+=|{}.!-]/g, '\\$&');
  }
}
