import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  S3Client,
  PutObjectCommand,
  DeleteObjectCommand,
} from '@aws-sdk/client-s3';
import * as crypto from 'crypto';
import * as path from 'path';
import * as fs from 'fs';

@Injectable()
export class R2Service {
  private readonly logger = new Logger(R2Service.name);
  private s3: S3Client | null = null;
  private bucket: string;
  private publicUrl: string;
  private localPublicUrl: string;
  // Локальное хранилище для разработки (когда R2 не настроен)
  private readonly localDir = path.join(process.cwd(), 'uploads');

  constructor(private config: ConfigService) {
    const accountId    = this.config.get('R2_ACCOUNT_ID');
    const accessKeyId  = this.config.get('R2_ACCESS_KEY_ID');
    const secretKey    = this.config.get('R2_SECRET_ACCESS_KEY');
    this.bucket        = this.config.get('R2_BUCKET_NAME') ?? 'miraku-media';
    this.publicUrl     = this.config.get('R2_PUBLIC_URL') ?? 'http://localhost:3000/uploads';
    const port         = this.config.get('PORT') ?? '3000';
    this.localPublicUrl = `http://localhost:${port}/uploads`;

    if (accountId && accessKeyId && secretKey) {
      this.s3 = new S3Client({
        region: 'auto',
        endpoint: `https://${accountId}.r2.cloudflarestorage.com`,
        credentials: { accessKeyId, secretAccessKey: secretKey },
      });
      this.logger.log('R2 storage connected');
    } else {
      this.logger.warn('R2 не настроен — используется локальное хранилище ./uploads');
      fs.mkdirSync(this.localDir, { recursive: true });
    }
  }

  async upload(
    file: Express.Multer.File,
    folder: string,
  ): Promise<{ url: string; key: string }> {
    const ext = path.extname(file.originalname).toLowerCase() || '.jpg';
    const key = `${folder}/${crypto.randomUUID()}${ext}`;

    if (this.s3) {
      await this.s3.send(new PutObjectCommand({
        Bucket: this.bucket,
        Key: key,
        Body: file.buffer,
        ContentType: file.mimetype,
        CacheControl: 'public, max-age=31536000',
      }));
    } else {
      // Локальный fallback
      const dest = path.join(this.localDir, key);
      fs.mkdirSync(path.dirname(dest), { recursive: true });
      fs.writeFileSync(dest, file.buffer);
    }

    const baseUrl = this.s3 ? this.publicUrl : this.localPublicUrl;
    return { url: `${baseUrl}/${key}`, key };
  }

  async delete(key: string): Promise<void> {
    if (this.s3) {
      await this.s3.send(new DeleteObjectCommand({ Bucket: this.bucket, Key: key }));
    } else {
      const filePath = path.join(this.localDir, key);
      if (fs.existsSync(filePath)) fs.unlinkSync(filePath);
    }
  }

  keyFromUrl(url: string): string {
    return url.replace(`${this.publicUrl}/`, '').replace(`${this.localPublicUrl}/`, '');
  }
}
