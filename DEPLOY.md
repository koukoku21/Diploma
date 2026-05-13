# Miraku — Инструкция по деплою (всё на Railway)

Все сервисы деплоятся на Railway. Домен не нужен — Railway даёт бесплатные URL.

---

## Содержание

1. [Что уже сделано](#1-что-уже-сделано)
2. [Шаг 1 — API сервис на Railway](#шаг-1--api-сервис-на-railway)
3. [Шаг 2 — PWA сервис на Railway](#шаг-2--pwa-сервис-на-railway)
4. [Шаг 3 — Mobizon (SMS OTP)](#шаг-3--mobizon-sms-otp)
5. [Шаг 4 — Firebase (пуши)](#шаг-4--firebase-пуши)
6. [Шаг 5 — Telegram бот](#шаг-5--telegram-бот)
7. [Шаг 6 — Flutter APK](#шаг-6--flutter-apk)
8. [Шаг 7 — Финальные действия](#шаг-7--финальные-действия)
9. [Переменные окружения](#переменные-окружения)
10. [Когда появится домен miraku.kz](#когда-появится-домен-mirakukz)

---

## 1. Что уже сделано

| Сервис | Статус |
|--------|--------|
| Railway PostgreSQL | ✅ Online |
| Railway Redis | ✅ Online |
| Cloudflare R2 (файлы) | ✅ настроен |
| Prisma миграция | ✅ применена |
| API сервис | деплоишь сейчас → Шаг 1 |
| PWA сервис | деплоишь сейчас → Шаг 2 |
| Mobizon SMS | нужно зарегистрироваться → Шаг 3 |
| Firebase пуши | нужно создать проект → Шаг 4 |
| Telegram бот | нужно создать → Шаг 5 |

---

## Шаг 1 — API сервис на Railway

### 1.1 Добавить сервис

1. Открой [railway.app](https://railway.app) → твой проект `nurturing-light`
2. Нажми **+ Add → GitHub Repo → Diploma** (репо `koukoku21/Diploma`)
3. Railway спросит Root Directory → введи `apps/api`
4. Нажми **Add Service** — сервис создастся, но пока не деплоится

### 1.2 Добавить переменные окружения

Кликни на API сервис → вкладка **Variables** → добавь каждую переменную:

```
NODE_ENV=production
PORT=3000
DATABASE_URL=postgresql://postgres:JXvGcquRMesRwjTzVhGKzwMEhqXBbTNY@viaduct.proxy.rlwy.net:25005/railway
REDIS_URL=redis://default:jTZaisknKvRhFkKYertdzDfPOOYwaFtn@centerbeam.proxy.rlwy.net:43127
JWT_SECRET=miraku_super_secret_jwt_key_change_me_32chars
JWT_EXPIRES_IN=15m
JWT_REFRESH_EXPIRES_IN=30d
ADMIN_SECRET=miraku_admin_2026
R2_ACCOUNT_ID=0e2d34d81007b14fc269f14d137cc5a1
R2_ACCESS_KEY_ID=cc8e63a5c1311c1cbb34030d0c5d6a08
R2_SECRET_ACCESS_KEY=692e2ba09015223db05de1a310d6531535b6035baeaf46714c40104272900ac7
R2_BUCKET_NAME=miraku-media
R2_PUBLIC_URL=https://pub-a201b8700685403186b8ce029f984994.r2.dev
MOBIZON_API_KEY=
MOBIZON_SENDER=Miraku
FIREBASE_PROJECT_ID=
FIREBASE_CLIENT_EMAIL=
FIREBASE_PRIVATE_KEY=
TELEGRAM_BOT_TOKEN=
TELEGRAM_ADMIN_CHAT_ID=
```

> `MOBIZON`, `FIREBASE`, `TELEGRAM` пока оставь пустыми — API запустится без них.
> `JWT_SECRET` — замени на любую случайную строку от 32 символов.
> `ADMIN_SECRET` — придумай пароль для входа в /admin.

### 1.3 Задеплоить

Вкладка **Deployments** → нажми **Deploy**. Билд займёт ~3-5 минут.

### 1.4 Получить URL

Вкладка **Settings → Networking → Public Domain** → нажми **Generate Domain**.

Получишь URL вида: `https://diploma-production-xxxx.up.railway.app`

**Запомни его** — подставишь в шаге 2.

### 1.5 Проверить

Открой в браузере:
```
https://<твой-api-url>/api/v1/feed
```
Должен вернуть `[]`. Если так — API работает.

---

## Шаг 2 — PWA сервис на Railway

### 2.1 Добавить второй сервис

1. В том же проекте `nurturing-light` → **+ Add → GitHub Repo → Diploma**
2. Root Directory → `apps/web`
3. Нажми **Add Service**

### 2.2 Добавить переменные

Кликни на PWA сервис → вкладка **Variables**:

```
NEXT_PUBLIC_API_URL=https://<твой-api-url-из-шага-1>/api/v1
```

Например:
```
NEXT_PUBLIC_API_URL=https://diploma-production-xxxx.up.railway.app/api/v1
```

### 2.3 Задеплоить

Вкладка **Deployments → Deploy**. Займёт ~2-3 минуты.

### 2.4 Получить URL

**Settings → Networking → Generate Domain**.

Получишь URL вида: `https://diploma-web-production-xxxx.up.railway.app`

### 2.5 Проверить

Открой:
```
https://<твой-pwa-url>/p/test
```
Должна загрузиться страница (даже если мастер не найден — это нормально).

---

## Шаг 3 — Mobizon (SMS OTP)

Без этого SMS с кодом подтверждения не будут отправляться.

1. Зайди на [mobizon.kz](https://mobizon.kz) → **Регистрация**
2. Пополни баланс (минимум **2 000 ₸** для теста)
3. В личном кабинете: **API → Получить ключ** → скопируй ключ
4. В Railway → API сервис → **Variables** → обнови:
   ```
   MOBIZON_API_KEY=<твой ключ>
   ```
5. Railway автоматически передеплоит сервис

> **Имя отправителя:** регистрация `Miraku` как имени занимает 1-3 дня.
> Пока не зарегистрировано — SMS придут с числового номера, это нормально для теста.

---

## Шаг 4 — Firebase (пуши)

Без этого push-уведомления не будут работать. Всё остальное работает.

### 4.1 Создать проект

1. Открой [console.firebase.google.com](https://console.firebase.google.com)
2. **Add project** → название: `miraku-app` → создай

### 4.2 Серверные ключи для API

1. Шестерёнка → **Project settings → Service accounts**
2. **Generate new private key** → скачает JSON файл
3. Открой JSON и найди три поля:

```
project_id       → FIREBASE_PROJECT_ID
client_email     → FIREBASE_CLIENT_EMAIL
private_key      → FIREBASE_PRIVATE_KEY (вся строка со -----BEGIN... до END-----\n)
```

4. В Railway → API сервис → Variables → добавь эти три переменные

### 4.3 Конфиг для Android приложения

1. Firebase Console → **Add app → Android**
2. Package name: `kz.miraku.miraku`
3. Скачай `google-services.json`
4. Положи файл: `apps/mobile/android/app/google-services.json`
5. Закоммить и запушить:
   ```bash
   git add apps/mobile/android/app/google-services.json
   git commit -m "add google-services.json"
   git push origin main
   ```

### 4.4 Конфиг для iOS приложения

1. Firebase Console → **Add app → iOS**
2. Bundle ID: `kz.miraku.app`
3. Скачай `GoogleService-Info.plist`
4. В Xcode: правой кнопкой на папку `Runner` → **Add Files** → выбери файл

---

## Шаг 5 — Telegram бот

Нужен для уведомлений о новых заявках мастеров и сторисах прямо в Telegram.

### 5.1 Создать бота

1. Открой Telegram → найди `@BotFather`
2. Напиши `/newbot`
3. Название: `Miraku Admin`
4. Username: любой, оканчивающийся на `bot` (например `miraku_notify_bot`)
5. BotFather пришлёт токен вида `7123456789:AABBccdd...`

### 5.2 Получить свой Chat ID

1. Напиши боту `/start`
2. Открой в браузере (замени TOKEN на свой):
   ```
   https://api.telegram.org/bot<TOKEN>/getUpdates
   ```
3. Найди `"chat": {"id": 123456789}` — это твой Chat ID

### 5.3 Добавить в Railway

В Railway → API сервис → Variables:
```
TELEGRAM_BOT_TOKEN=<токен от BotFather>
TELEGRAM_ADMIN_CHAT_ID=<твой chat id>
```

### 5.4 Зарегистрировать webhook (после деплоя API)

Выполни в терминале (замени значения на свои):
```bash
curl -X POST https://<твой-api-url>/api/v1/admin/telegram/setup-webhook \
  -H "Content-Type: application/json" \
  -H "X-Admin-Secret: miraku_admin_2026" \
  -d '{"url": "https://<твой-api-url>/api/v1/admin/telegram/webhook"}'
```

---

## Шаг 6 — Flutter APK

### 6.1 Быстрый debug APK (для своего телефона)

```bash
cd apps/mobile
flutter pub get

flutter build apk --debug \
  --dart-define=API_URL=https://<твой-api-url>/api/v1

# APK готов:
# apps/mobile/build/app/outputs/flutter-apk/app-debug.apk
```

Скинь файл на Android-телефон и открой, или:
```bash
adb install build/app/outputs/flutter-apk/app-debug.apk
```

### 6.2 Release APK для тестеров

```bash
flutter build apk --release \
  --dart-define=API_URL=https://<твой-api-url>/api/v1

# APK: build/app/outputs/flutter-apk/app-release.apk
# Отправь через Telegram или Google Drive
```

> **Что работает без Firebase:** авторизация, лента, запись, чат, профиль.
> **Что не работает без Firebase:** push-уведомления.
> **Что не работает без Mobizon:** отправка SMS с кодом.

---

## Шаг 7 — Финальные действия

### 7.1 Проверить Admin Panel

Открой в браузере:
```
https://<твой-api-url>/api/v1/admin
```
Введи `ADMIN_SECRET` (из переменных Railway). Должны работать все вкладки.

### 7.2 Smoke-тест

1. Установи APK на телефон
2. Зарегистрируйся по номеру телефона → должна прийти SMS
3. В Admin Panel → вкладка **На проверке** → одобри тестового мастера
4. Зайди как клиент → найди мастера в ленте → запишись
5. Telegram должен прислать уведомление (если настроен)

---

## Переменные окружения

### Railway — API сервис

```env
NODE_ENV=production
PORT=3000
DATABASE_URL=postgresql://postgres:JXvGcquRMesRwjTzVhGKzwMEhqXBbTNY@viaduct.proxy.rlwy.net:25005/railway
REDIS_URL=redis://default:jTZaisknKvRhFkKYertdzDfPOOYwaFtn@centerbeam.proxy.rlwy.net:43127
JWT_SECRET=miraku_super_secret_jwt_key_change_me_32chars
JWT_EXPIRES_IN=15m
JWT_REFRESH_EXPIRES_IN=30d
ADMIN_SECRET=miraku_admin_2026
R2_ACCOUNT_ID=0e2d34d81007b14fc269f14d137cc5a1
R2_ACCESS_KEY_ID=cc8e63a5c1311c1cbb34030d0c5d6a08
R2_SECRET_ACCESS_KEY=692e2ba09015223db05de1a310d6531535b6035baeaf46714c40104272900ac7
R2_BUCKET_NAME=miraku-media
R2_PUBLIC_URL=https://pub-a201b8700685403186b8ce029f984994.r2.dev
MOBIZON_API_KEY=
MOBIZON_SENDER=Miraku
FIREBASE_PROJECT_ID=
FIREBASE_CLIENT_EMAIL=
FIREBASE_PRIVATE_KEY=
TELEGRAM_BOT_TOKEN=
TELEGRAM_ADMIN_CHAT_ID=
```

### Railway — PWA сервис

```env
NEXT_PUBLIC_API_URL=https://<твой-api-url>/api/v1
```

---

## Частые ошибки

| Ошибка | Решение |
|--------|---------|
| `Cannot find module '/app/dist/src/main'` | Билд не запустился — проверь вкладку Deployments → Logs на этапе Build |
| SMS не приходит | Добавь `MOBIZON_API_KEY` в переменные Railway |
| Push не приходят | Добавь Firebase переменные в Railway |
| Admin Panel не открывается | Проверь `ADMIN_SECRET` — вводи точно как в переменных |
| PWA показывает ошибку API | Проверь `NEXT_PUBLIC_API_URL` — должен быть без слэша в конце `/api/v1` |
| `Cannot find module '@prisma/client'` | Зайди в Railway → API сервис → Deployments → Redeploy |

---

## Когда появится домен miraku.kz

Когда будешь готов к реальному запуску — купи домен и настрой DNS:

| DNS запись | Тип | Значение |
|-----------|-----|---------|
| `@` (miraku.kz) | CNAME | Railway PWA URL |
| `api` (api.miraku.kz) | CNAME | Railway API URL |

Затем в Railway каждому сервису добавь кастомный домен:
- API сервис → Settings → Networking → Custom Domain → `api.miraku.kz`
- PWA сервис → Settings → Networking → Custom Domain → `miraku.kz`

И обнови переменную в PWA сервисе:
```
NEXT_PUBLIC_API_URL=https://api.miraku.kz/api/v1
```
