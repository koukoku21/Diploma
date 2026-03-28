import { Injectable, OnModuleDestroy, OnModuleInit, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Redis from 'ioredis';

@Injectable()
export class RedisService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(RedisService.name);
  private client: Redis;
  private connected = false;
  // Fallback для локальной разработки когда Redis недоступен
  private readonly memStore = new Map<string, { value: string; expiresAt: number }>();

  constructor(private config: ConfigService) {}

  onModuleInit() {
    this.client = new Redis(this.config.getOrThrow<string>('REDIS_URL'), {
      lazyConnect: true,
      maxRetriesPerRequest: 1,
    });

    this.client.on('ready', () => {
      this.connected = true;
      this.logger.log('Redis connected');
    });

    this.client.on('error', () => {
      if (this.connected) this.logger.warn('Redis недоступен — используется in-memory fallback');
      this.connected = false;
    });

    this.client.connect().catch(() => {
      this.logger.warn('Redis недоступен — используется in-memory fallback');
    });
  }

  async onModuleDestroy() {
    await this.client.quit().catch(() => {});
  }

  async set(key: string, value: string, ttlSeconds: number): Promise<void> {
    if (this.connected) {
      await this.client.set(key, value, 'EX', ttlSeconds);
    } else {
      this.memStore.set(key, { value, expiresAt: Date.now() + ttlSeconds * 1000 });
    }
  }

  async get(key: string): Promise<string | null> {
    if (this.connected) {
      return this.client.get(key);
    }
    const entry = this.memStore.get(key);
    if (!entry) return null;
    if (Date.now() > entry.expiresAt) {
      this.memStore.delete(key);
      return null;
    }
    return entry.value;
  }

  async del(key: string): Promise<void> {
    if (this.connected) {
      await this.client.del(key);
    } else {
      this.memStore.delete(key);
    }
  }

  async delPattern(pattern: string): Promise<void> {
    if (this.connected) {
      // Используем SCAN для безопасного удаления по паттерну
      let cursor = '0';
      do {
        const [nextCursor, keys] = await this.client.scan(cursor, 'MATCH', pattern, 'COUNT', 100);
        cursor = nextCursor;
        if (keys.length > 0) {
          await this.client.del(...keys);
        }
      } while (cursor !== '0');
    } else {
      // In-memory fallback — фильтруем по паттерну (заменяем * на regexp)
      const regex = new RegExp('^' + pattern.replace(/\*/g, '.*') + '$');
      for (const key of this.memStore.keys()) {
        if (regex.test(key)) this.memStore.delete(key);
      }
    }
  }
}
