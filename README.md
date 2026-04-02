# Miraku — Бьюти-приложение для Астаны

"Tinder для бьюти-услуг" — свайп-лента мастеров → запись за 3 клика.

## Структура монорепо

```
apps/
  api/      — NestJS backend
  mobile/   — Flutter приложение
```

## Быстрый старт

### Backend (API)

```bash
cd apps/api

# Зависимости
npm install

# Переменные окружения
cp ../../.env.example .env
# Заполнить DATABASE_URL, REDIS_URL, MOBIZON_API_KEY и др.

# БД: создать и применить схему
npx prisma migrate dev

# PostGIS колонка (один раз)
psql $DATABASE_URL -f prisma/sql/add_postgis_location.sql

# Dev сервер
npm run start:dev
```

### Flutter (Mobile)

```bash
cd apps/mobile

# Зависимости
flutter pub get

# Firebase (один раз, требует flutterfire CLI)
# flutterfire configure

# Android эмулятор / iOS симулятор
flutter run

# Production build (API_URL — адрес Railway)
flutter build apk --release --dart-define=API_URL=https://api.miraku.kz/api/v1
```

## Переменные окружения

Смотри `.env.example` в корне.
Обязательные для запуска в dev:

```
DATABASE_URL=postgresql://...
REDIS_URL=redis://...
JWT_SECRET=любая-строка
```

Опциональные в dev (без них SMS не отправляется, логируется в консоль):
```
MOBIZON_API_KEY=
FIREBASE_PROJECT_ID=
R2_ACCOUNT_ID=
```

## CI/CD

- `main` ветка → автодеплой на Railway (API) через GitHub Actions
- Pull request → lint + build проверка
- Android APK артефакт сохраняется 14 дней

### Secrets в GitHub

| Secret | Где взять |
|--------|-----------|
| `RAILWAY_TOKEN` | railway.app → Account → Tokens |
| `DATABASE_URL` | Railway → PostgreSQL plugin |
| `API_URL` | URL деплоя на Railway |

## Firebase (Push-уведомления)

```bash
npm install -g firebase-tools
dart pub global activate flutterfire_cli
cd apps/mobile
flutterfire configure --project=miraku-app
```

Генерирует `lib/firebase_options.dart`. После этого пуши заработают.

## Стек

| Слой | Технология |
|------|-----------|
| Mobile | Flutter 3 + Riverpod 2 + GoRouter |
| API | NestJS + Prisma + PostgreSQL + PostGIS |
| Cache | Redis (OTP, слоты, WebSocket Pub/Sub) |
| Auth | JWT (15м) + Refresh (30д) + SMS OTP |
| Files | Cloudflare R2 |
| Push | Firebase FCM |
| Chat | Socket.io + Redis Pub/Sub |
| Deploy | Railway (API) + GitHub Actions |
