import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import * as admin from 'firebase-admin';

@Injectable()
export class FcmService implements OnModuleInit {
  private readonly logger = new Logger(FcmService.name);
  private app: admin.app.App;

  constructor(private config: ConfigService) {}

  onModuleInit() {
    const projectId = this.config.get('FIREBASE_PROJECT_ID');
    if (!projectId) {
      this.logger.warn('Firebase не настроен — push уведомления отключены');
      return;
    }

    this.app = admin.initializeApp({
      credential: admin.credential.cert({
        projectId,
        clientEmail: this.config.getOrThrow('FIREBASE_CLIENT_EMAIL'),
        privateKey: this.config
          .getOrThrow('FIREBASE_PRIVATE_KEY')
          .replace(/\\n/g, '\n'),
      }),
    });
  }

  async sendToTokens(
    tokens: string[],
    title: string,
    body: string,
    data?: Record<string, string>,
  ): Promise<void> {
    if (!this.app || tokens.length === 0) return;

    try {
      const response = await admin.messaging(this.app).sendEachForMulticast({
        tokens,
        notification: { title, body },
        data,
        android: { priority: 'high' },
        apns: { payload: { aps: { sound: 'default' } } },
      });

      if (response.failureCount > 0) {
        this.logger.warn(`FCM: ${response.failureCount} токенов недоступны`);
      }
    } catch (err) {
      this.logger.error('FCM send error', err);
    }
  }
}
