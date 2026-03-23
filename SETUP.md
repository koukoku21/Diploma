# Запуск Miraku локально

## Что нужно установить

| Инструмент | Версия | Установка |
|-----------|--------|-----------|
| Flutter | 3.x | https://docs.flutter.dev/get-started/install/macos |
| Node.js | 20 LTS | `brew install node@20` |
| PostgreSQL | 15+ | `brew install postgresql@16` |
| Redis | 7+ | `brew install redis` |
| Xcode | 15+ | App Store (для iOS симулятора) |
| Android Studio | + эмулятор | https://developer.android.com/studio |

---

## 1. Клонировать репо и поставить зависимости

```bash
git clone https://github.com/твой-юзер/Miraku2.git
cd Miraku2

# API
cd apps/api && npm install && cd ../..

# Flutter
cd apps/mobile && flutter pub get && cd ../..
```

---

## 2. Запустить PostgreSQL и Redis

```bash
brew services start postgresql@16
brew services start redis
```

Создать базу данных:
```bash
createdb miraku
```

---

## 3. Настроить .env для API

```bash
cd apps/api
cp ../../.env.example .env
```

Открыть `apps/api/.env` и заполнить:

```env
# Обязательно
DATABASE_URL=postgresql://localhost/miraku
REDIS_URL=redis://localhost:6379
JWT_SECRET=любая-длинная-строка-например-miraku-local-secret-123
NODE_ENV=development

# Оставить пустыми в dev (SMS будет логироваться в консоль, не отправляться)
MOBIZON_API_KEY=
MOBIZON_SENDER=Miraku

# Оставить пустыми (файлы не будут загружаться в облако)
R2_ACCOUNT_ID=
R2_ACCESS_KEY_ID=
R2_SECRET_ACCESS_KEY=
R2_BUCKET_NAME=
R2_PUBLIC_URL=

# Оставить пустыми (push-уведомления не будут работать)
FIREBASE_PROJECT_ID=
FIREBASE_CLIENT_EMAIL=
FIREBASE_PRIVATE_KEY=

# Admin-панель (можно любое)
ADMIN_SECRET=local-admin-secret

JWT_EXPIRES_IN=15m
JWT_REFRESH_EXPIRES_IN=30d
PORT=3000
```

---

## 4. Применить миграции БД

```bash
cd apps/api

# Создать таблицы
npx prisma migrate dev --name init

# Добавить PostGIS колонку (один раз)
psql miraku -f prisma/sql/add_postgis_location.sql
```

> Если psql говорит "extension postgis does not exist":
> ```bash
> brew install postgis
> psql miraku -c "CREATE EXTENSION IF NOT EXISTS postgis;"
> psql miraku -f prisma/sql/add_postgis_location.sql
> ```

---

## 5. Запустить API

```bash
cd apps/api
npm run start:dev
```

Должно появиться:
```
[NestJS] Application is running on: http://localhost:3000
```

Проверить что работает:
```bash
curl http://localhost:3000/api/v1/feed?lat=51.18&lng=71.44&radius=5000
# Вернёт [] (пустой массив — мастеров ещё нет)
```

---

## 6. Настроить Flutter под iOS симулятор

Открыть `apps/mobile/lib/core/network/dio_client.dart` и изменить `defaultValue`:

```dart
// Для iOS симулятора:
defaultValue: 'http://localhost:3000/api/v1',

// Для Android эмулятора (уже стоит по умолчанию):
defaultValue: 'http://10.0.2.2:3000/api/v1',
```

---

## 7. Запустить Flutter

```bash
cd apps/mobile
flutter run
```

Выбрать эмулятор/симулятор из списка.

---

## Как протестировать авторизацию

В `development` режиме SMS не отправляется — OTP-код появится в консоли API:

```
[MobizonService] DEV: sending OTP 4821 to +77001234567
```

Вводишь этот код в приложении на экране A-3.

---

## Что НЕ будет работать локально без дополнительной настройки

| Фича | Причина | Что нужно |
|------|---------|-----------|
| Загрузка фото в портфолио | Нет R2 | Завести Cloudflare R2 и заполнить R2_* в .env |
| Push-уведомления | Нет Firebase | `flutterfire configure` (см. ниже) |
| SMS OTP | Намеренно отключено в dev | OTP виден в консоли API |

---

## Firebase (опционально, для пушей)

```bash
# Установить инструменты
npm install -g firebase-tools
dart pub global activate flutterfire_cli

# Войти
firebase login

# Настроить (из папки mobile)
cd apps/mobile
flutterfire configure --project=твой-firebase-project-id
```

Генерирует `lib/firebase_options.dart`. После этого пуши заработают.

---

## Cloudflare R2 (опционально, для фото)

1. Зайти на https://dash.cloudflare.com → R2
2. Создать bucket `miraku-media`
3. Создать API token с правами на bucket
4. Заполнить в `.env`:
```env
R2_ACCOUNT_ID=...
R2_ACCESS_KEY_ID=...
R2_SECRET_ACCESS_KEY=...
R2_BUCKET_NAME=miraku-media
R2_PUBLIC_URL=https://pub-xxxx.r2.dev
```

---

## Частые проблемы

**`prisma migrate dev` падает с ошибкой подключения**
```bash
# Проверить что postgres запущен
brew services list | grep postgresql
# Проверить что база существует
psql -l | grep miraku
```

**Flutter не видит API (timeout)**
- Android эмулятор → убедись что в `dio_client.dart` стоит `10.0.2.2`
- iOS симулятор → убедись что стоит `localhost`
- Реальный телефон → нужен ngrok или локальный IP (`192.168.x.x`)

**`extension postgis does not exist`**
```bash
brew install postgis
psql miraku -c "CREATE EXTENSION postgis;"
```

**`flutter run` — нет устройств**
```bash
# Список доступных симуляторов
flutter devices
# Открыть iOS симулятор
open -a Simulator
```
