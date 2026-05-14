import { NestFactory } from '@nestjs/core';
import { ValidationPipe, RequestMethod } from '@nestjs/common';
import { NestExpressApplication } from '@nestjs/platform-express';
import { AppModule } from './app.module';
import * as path from 'path';

async function bootstrap() {
  const app = await NestFactory.create<NestExpressApplication>(AppModule);

  // Локальные загруженные файлы (fallback когда R2 не настроен)
  app.useStaticAssets(path.join(process.cwd(), 'uploads'), { prefix: '/uploads' });

  app.setGlobalPrefix('api/v1', {
    exclude: [{ path: 'admin', method: RequestMethod.GET }],
  });

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );

  app.enableCors({
    origin: '*',
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Admin-Secret'],
  });

  const port = process.env.PORT ?? 3000;
  await app.listen(port);
  console.log(`Miraku API running on port ${port}`);
}
bootstrap();
