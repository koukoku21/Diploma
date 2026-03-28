# Miraku — Архитектура системы

Простое объяснение того, как всё работает вместе.

---

## Большая картина

```
┌─────────────────────────────────┐
│        Flutter App              │  ← телефон пользователя
│  (клиент + мастер в одном)      │
└────────────────┬────────────────┘
                 │ HTTPS (REST API + WebSocket)
                 │
┌────────────────▼────────────────┐
│         NestJS API              │  ← сервер (Railway)
│         порт 3000               │
└──────┬──────────────┬───────────┘
       │              │
┌──────▼──────┐  ┌────▼─────────┐
│ PostgreSQL  │  │    Redis     │  ← тоже на Railway
│  (данные)   │  │ (кэш + чат)  │
└─────────────┘  └─────────────┘
```

**Правило одно:** Flutter никогда не ходит в БД напрямую. Только через API.

---

## Как Flutter общается с API

### Базовый URL

```dart
// apps/mobile/lib/core/network/dio_client.dart
const baseUrl = 'http://192.168.1.x:3000/api/v1';  // локально
// на проде: https://api.miraku.kz/api/v1
```

Каждый HTTP запрос — это:
```
GET  /feed          → получить список мастеров
POST /bookings      → создать запись
GET  /bookings/mine → мои записи
```

### Заголовки каждого запроса

```
Authorization: Bearer eyJhbGc...   ← JWT токен (кто я)
Content-Type: application/json
```

---

## Авторизация — как это работает

### Шаг 1: Вход по SMS

```
Телефон → API → Mobizon SMS → Пользователь вводит код → API проверяет
```

```
POST /auth/send-otp
{ "phone": "+77001234567" }

→ Mobizon отправляет SMS с кодом "1234"
→ Код хранится в Redis 5 минут (не в БД!)
```

```
POST /auth/verify-otp
{ "phone": "+77001234567", "code": "1234" }

→ API проверяет код в Redis
→ Возвращает два токена:
{
  "accessToken":  "eyJhbGc...",   ← живёт 15 минут
  "refreshToken": "eyJhbGc..."    ← живёт 30 дней
}
```

### Шаг 2: Два типа токенов

#### Access Token (короткоживущий)
- JWT токен, подписанный `JWT_SECRET`
- Живёт **15 минут**
- Передаётся в каждом запросе в заголовке `Authorization: Bearer`
- Содержит внутри: `{ userId, iat, exp }`
- API расшифровывает его и знает, кто делает запрос

```
Что внутри JWT (Base64 decode):
{
  "userId": "550e8400-e29b-41d4-a716-446655440000",
  "iat": 1711612800,   ← когда создан (unix timestamp)
  "exp": 1711613700    ← когда истекает (iat + 15 мин)
}
```

#### Refresh Token (долгоживущий)
- Тоже JWT, но живёт **30 дней**
- Хранится в БД в таблице `refresh_tokens`
- Используется ТОЛЬКО для получения нового access токена
- Больше ни для чего не используется

### Шаг 3: Обновление токенов

Когда access токен истекает (15 мин), Flutter автоматически:

```
POST /auth/refresh
{ "refreshToken": "eyJhbGc..." }

→ API проверяет refresh токен в БД
→ Выдаёт новую пару токенов
→ Старый refresh токен удаляется из БД
→ Записывается новый
```

Это происходит **автоматически** в Dio interceptor — пользователь ничего не замечает.

### Схема потока токенов

```
Пользователь вводит SMS код
         │
         ▼
    API выдаёт:
    ┌─────────────────┐    ┌──────────────────┐
    │  accessToken    │    │  refreshToken     │
    │  (15 минут)     │    │  (30 дней)        │
    └────────┬────────┘    └────────┬──────────┘
             │                      │
             ▼                      ▼
    В каждом запросе         В БД (refresh_tokens)
    Authorization: Bearer    Только для обновления
             │
             │ через 15 мин истекает
             ▼
    Dio автоматически вызывает /auth/refresh
    Получает новый accessToken
    Запрос повторяется
```

---

## Как защищены эндпоинты

### Публичные (без токена)
```
POST /auth/send-otp    ← отправить SMS
POST /auth/verify-otp  ← проверить код
GET  /service-templates ← список услуг (для каталога)
```

### Защищённые (нужен accessToken)
```
GET  /feed             ← лента мастеров
GET  /bookings/mine    ← мои записи
POST /bookings         ← создать запись
...и всё остальное
```

На сервере стоит `JwtAuthGuard`:
```typescript
@UseGuards(JwtAuthGuard)  // ← проверяет токен
@Get('bookings/mine')
getMyBookings(@CurrentUser() user: User) {
  // user.id уже доступен, потому что токен расшифрован
}
```

### Только для мастеров
```
POST /master/services   ← добавить услугу
PUT  /master/schedule   ← обновить расписание
```

Дополнительно проверяется, что у пользователя есть `masterProfile`.

### Только для администраторов
```
GET  /admin/masters      ← заявки мастеров
POST /admin/masters/:id/review ← одобрить/отклонить
GET  /admin/service-templates  ← справочник услуг
```

Используется `AdminGuard` — проверяет заголовок `X-Admin-Secret`:
```
X-Admin-Secret: секретный_ключ_из_env
```
Нет JWT — просто секретный ключ, который знает только admin-панель.

---

## Хранилище данных — что где лежит

### PostgreSQL (постоянные данные)
```
users              ← пользователи
master_profiles    ← профили мастеров
services           ← услуги мастеров
service_templates  ← справочник услуг (заполнен через seed)
schedules          ← расписание
bookings           ← записи
reviews            ← отзывы
chat_rooms         ← комнаты чата
chat_messages      ← сообщения
favourites         ← избранные мастера
notifications      ← история уведомлений
refresh_tokens     ← refresh токены
push_tokens        ← FCM токены для пушей
```

### Redis (временные данные)
```
otp:{phone}        ← SMS код, TTL 5 минут
slots:{masterId}:{date} ← кэш слотов, TTL 5 минут
pub/sub channels   ← для WebSocket чата
```

### Cloudflare R2 (файлы)
```
portfolio/{masterId}/{uuid}.jpg   ← фото портфолио
avatars/{userId}/{uuid}.jpg       ← аватары
```

Файлы отдаются через CDN: `https://media.miraku.kz/portfolio/...`

---

## WebSocket — чат в реальном времени

Чат работает не через обычные HTTP запросы, а через постоянное соединение.

```
Flutter                          API (Socket.io)
   │                                   │
   │── connect ─────────────────────>  │  устанавливает соединение
   │   { token: "eyJhbGc..." }         │  проверяет JWT
   │                                   │
   │── join_room ──────────────────>   │
   │   { roomId: "uuid" }              │
   │                                   │
   │── send_message ───────────────>   │
   │   { roomId, content: "Привет" }   │  сохраняет в PostgreSQL
   │                                   │  публикует в Redis Pub/Sub
   │                                   │
   │  <── new_message ─────────────────│  доставляет всем в комнате
   │   { id, content, senderId, ... }  │
```

**Redis Pub/Sub** нужен для масштабирования: если API запущен на нескольких серверах, Redis связывает их между собой.

---

## Push-уведомления

```
Событие в API (например, новая запись)
         │
         ▼
NotificationsService.notify(userId, type, data)
         │
         ├── 1. Сохраняет в таблицу notifications (история)
         │
         └── 2. Ищет push_tokens пользователя
                    │
                    ▼
              Firebase FCM
                    │
                    ▼
              Телефон пользователя
              (уведомление появляется)
```

Push-токен Flutter отправляет на сервер при входе:
```
POST /notifications/push-token
{ "token": "FCM_TOKEN", "platform": "IOS" }
```

---

## Геофильтрация ленты

Как мастера появляются в ленте клиента:

```
Flutter отправляет:
GET /feed?lat=51.18&lng=71.44&radius=5000

API делает SQL запрос (PostGIS):
SELECT * FROM master_profiles
WHERE ST_DWithin(
  location,                              ← координаты мастера
  ST_Point(71.44, 51.18)::geography,     ← координаты клиента
  5000                                   ← радиус в метрах
)
AND is_active = true
AND is_verified = true
ORDER BY расстояние
LIMIT 20
```

**Важно:** координаты мастера — это адрес РАБОЧЕГО места, который он указал при регистрации. Не GPS в реальном времени.

---

## Расчёт свободных слотов

Самая сложная логика в системе:

```
GET /schedule/slots?masterId=X&serviceId=Y&date=2026-03-28

1. Берём расписание мастера на этот день (Schedule)
2. Проверяем ScheduleOverride (особый день?)
3. Берём все существующие записи на этот день (Booking)
4. Генерируем слоты с шагом 30 минут
5. Убираем занятые (запись + буфер 15 мин)
6. Кэшируем результат в Redis (TTL 5 мин)

Ответ:
["10:00", "10:30", "11:30", "12:00", ...]
```

---

## Структура запроса — пример полного цикла

**Клиент создаёт запись:**

```
Flutter                          API                        PostgreSQL
  │                               │                              │
  │── POST /bookings ──────────>  │                              │
  │   Authorization: Bearer ...   │── проверяет JWT              │
  │   {                           │── проверяет слот свободен    │
  │     masterId,                 │── инвалидирует кэш Redis     │
  │     serviceId,                │── INSERT bookings ─────────> │
  │     startsAt                  │                              │
  │   }                           │── уведомляет мастера (FCM)   │
  │                               │                              │
  │  <── 201 Created ─────────── │                              │
  │   {                           │                              │
  │     id: "uuid",               │                              │
  │     status: "CONFIRMED",      │                              │
  │     priceSnapshot: 5000       │                              │
  │   }                           │                              │
```

---

## Окружение — какие переменные нужны

```env
# .env в apps/api/

DATABASE_URL=postgresql://user:pass@host/miraku
REDIS_URL=redis://host:6379

JWT_SECRET=длинная_случайная_строка
JWT_EXPIRES_IN=15m
JWT_REFRESH_EXPIRES_IN=30d

MOBIZON_API_KEY=...        ← SMS провайдер (KZ)
MOBIZON_SENDER=Miraku

FIREBASE_PROJECT_ID=...    ← Push уведомления
FIREBASE_CLIENT_EMAIL=...
FIREBASE_PRIVATE_KEY=...

R2_ACCOUNT_ID=...          ← Хранилище файлов
R2_ACCESS_KEY_ID=...
R2_SECRET_ACCESS_KEY=...
R2_BUCKET_NAME=miraku-media
R2_PUBLIC_URL=https://media.miraku.kz

TWOGIS_API_KEY=...         ← Геокодинг адресов

ADMIN_SECRET=секретный_ключ_для_admin_панели

PORT=3000
NODE_ENV=production
```

---

## Итог одной строкой

> Flutter отправляет JWT в каждом запросе → API проверяет кто ты → достаёт/меняет данные в PostgreSQL → отвечает JSON → Flutter показывает UI.
