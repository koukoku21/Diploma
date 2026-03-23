# Miraku — Design System

## Философия
Дух лендинга переносится в приложение без изменений:
тёмная тема, золотой акцент, элегантность.
Адаптируем только то что требует мобильный контекст.

---

## Цвета

### Фоны
```
Background Primary:    #0a0a0f  — основной фон всех экранов
Background Secondary:  #111118  — карточки, боттом-шиты, Tab Bar
Background Tertiary:   #16161f  — инпуты, чипы, вложенные блоки
```

### Акценты
```
Gold:        #c9a96e  — CTA кнопки, активные табы, рейтинг, цены
Gold Light:  #e8c99a  — pressed состояние кнопок, выбранные слоты
Rose:        #d4748a  — кнопка избранного ♡, акценты онбординга
```

### Текст
```
Text Primary:    #f0ede8  — основной текст, заголовки
Text Secondary:  #9b9690  — подписи, метаданные, плейсхолдеры
Text Tertiary:   #5a5750  — неактивные табы, хинты
```

### Семантика
```
Success:   #1d9e75   — запись подтверждена, верифицирован ✓
Error:     #d4748a   — ошибки, отменённые записи
Border:    rgba(255,255,255,0.07)  — разделители, границы карточек
Border 2:  rgba(255,255,255,0.12) — акцентные границы (активные эл-ты)
```

### В Flutter (ThemeData)
```dart
const Color kGold       = Color(0xFFC9A96E);
const Color kGoldLight  = Color(0xFFE8C99A);
const Color kRose       = Color(0xFFD4748A);
const Color kBgPrimary  = Color(0xFF0A0A0F);
const Color kBgSecondary = Color(0xFF111118);
const Color kBgTertiary = Color(0xFF16161F);
const Color kTextPrimary   = Color(0xFFF0EDE8);
const Color kTextSecondary = Color(0xFF9B9690);
const Color kTextTertiary  = Color(0xFF5A5750);
const Color kSuccess    = Color(0xFF1D9E75);
const Color kBorder     = Color(0x12FFFFFF);  // rgba(255,255,255,0.07)
const Color kBorder2    = Color(0x1FFFFFFF);  // rgba(255,255,255,0.12)
```

---

## Шрифты

### Подключение в pubspec.yaml
```yaml
fonts:
  - family: Mulish
    fonts:
      - asset: assets/fonts/Mulish-Light.ttf
        weight: 300
      - asset: assets/fonts/Mulish-Regular.ttf
        weight: 400
      - asset: assets/fonts/Mulish-Medium.ttf
        weight: 500
      - asset: assets/fonts/Mulish-SemiBold.ttf
        weight: 600
  - family: PlayfairDisplay
    fonts:
      - asset: assets/fonts/PlayfairDisplay-Regular.ttf
        weight: 400
      - asset: assets/fonts/PlayfairDisplay-Bold.ttf
        weight: 700
      - asset: assets/fonts/PlayfairDisplay-Italic.ttf
        style: italic
```

### Шкала размеров
```
Display  — 28px / 700 / PlayfairDisplay — онбординг, Hero экраны
H1       — 22px / 700 / PlayfairDisplay — имена мастеров на свайп-карточке
Title    — 20px / 600 / Mulish           — заголовки навбара, экранов
Subtitle — 17px / 500 / Mulish           — подзаголовки, важный текст
Body     — 16px / 400 / Mulish           — основной контент, описания
Label    — 14px / 500 / Mulish           — кнопки, лейблы форм, услуги
Caption  — 12px / 400 / Mulish           — метаданные, Tab Bar лейблы
Overline — 10px / 700 / Mulish UPPERCASE — категории, лейблы секций
```

### В Flutter (TextStyle)
```dart
// Использование:
// Text('Айгерим С.', style: AppTextStyles.h1)

class AppTextStyles {
  static const display = TextStyle(
    fontFamily: 'PlayfairDisplay',
    fontSize: 28, fontWeight: FontWeight.w700,
    color: kTextPrimary, height: 1.15,
  );
  static const h1 = TextStyle(
    fontFamily: 'PlayfairDisplay',
    fontSize: 22, fontWeight: FontWeight.w700,
    color: kTextPrimary,
  );
  static const title = TextStyle(
    fontFamily: 'Mulish',
    fontSize: 20, fontWeight: FontWeight.w600,
    color: kTextPrimary,
  );
  static const subtitle = TextStyle(
    fontFamily: 'Mulish',
    fontSize: 17, fontWeight: FontWeight.w500,
    color: kTextPrimary,
  );
  static const body = TextStyle(
    fontFamily: 'Mulish',
    fontSize: 16, fontWeight: FontWeight.w400,
    color: kTextPrimary, height: 1.5,
  );
  static const label = TextStyle(
    fontFamily: 'Mulish',
    fontSize: 14, fontWeight: FontWeight.w500,
    color: kTextPrimary,
  );
  static const caption = TextStyle(
    fontFamily: 'Mulish',
    fontSize: 12, fontWeight: FontWeight.w400,
    color: kTextSecondary,
  );
  static const overline = TextStyle(
    fontFamily: 'Mulish',
    fontSize: 10, fontWeight: FontWeight.w700,
    color: kGold,
    letterSpacing: 1.2,
  );
}
```

---

## Радиусы и отступы

### Border Radius
```
xs:  8px   — мелкие чипы, бейджи
sm:  12px  — инпуты, мелкие карточки, кнопки действий
md:  16px  — карточки мастеров, боттом-шиты
lg:  20px  — Tab Bar, крупные карточки
xl:  24px  — модальные окна
pill: 100px — CTA кнопки (Записаться, Войти)
```

### Отступы (spacing)
```
4px  — xs  — между иконкой и текстом внутри кнопки
8px  — sm  — между элементами в строке
12px — md  — padding внутри карточки
16px — lg  — горизонтальные отступы экрана (SafeArea)
20px — xl  — между секциями
24px — 2xl — крупные отступы
```

### В Flutter
```dart
class AppSpacing {
  static const double xs  = 4;
  static const double sm  = 8;
  static const double md  = 12;
  static const double lg  = 16;
  static const double xl  = 20;
  static const double xxl = 24;
  static const double screenH = 16; // горизонтальный padding экрана
}

class AppRadius {
  static const double xs   = 8;
  static const double sm   = 12;
  static const double md   = 16;
  static const double lg   = 20;
  static const double xl   = 24;
  static const double pill = 100;
}
```

---

## Компоненты

### Кнопки

#### Primary (CTA) — «Записаться», «Войти»
```dart
// Золотая, pill форма, тёмный текст
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: kGold,
    foregroundColor: kBgPrimary,
    minimumSize: const Size.fromHeight(52),
    shape: const StadiumBorder(),
    textStyle: AppTextStyles.label.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: 0.3,
    ),
  ),
)
```

#### Secondary (Outline) — второстепенные действия
```dart
OutlinedButton(
  style: OutlinedButton.styleFrom(
    foregroundColor: kGold,
    side: const BorderSide(color: kGold),
    minimumSize: const Size.fromHeight(52),
    shape: const StadiumBorder(),
  ),
)
```

#### Ghost — вспомогательные действия
```dart
// Полупрозрачный золотой фон
backgroundColor: kGold.withOpacity(0.1)
foregroundColor: kGold
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pill))
```

#### Danger — отмена, удаление
```dart
backgroundColor: kRose.withOpacity(0.12)
foregroundColor: kRose
```

### Минимальный размер зоны тапа — 44×44px (требование Apple)
```dart
// Все интерактивные элементы:
constraints: const BoxConstraints(minWidth: 44, minHeight: 44)
```

---

### Карточка мастера (свайп-лента C-1)

```
Структура:
  ┌─────────────────────────┐
  │  Фото работы (фон)      │
  │  Chip: ✓ Верифицирован  │
  │                         │
  │  ████ градиент снизу    │
  │  Айгерим С.  (Playfair) │
  │  МАНИКЮР · ПЕДИКЮР      │
  │  ★4.9  от 5000₸  1.2км │
  ├─────────────────────────┤
  │  [✕ Пропустить] [♡] [📅 Записаться] │
  └─────────────────────────┘

Размеры:
  - Высота фото: 70% высоты карточки
  - Градиент overlay: LinearGradient(transparent → #0a0a0f), высота 120px
  - Кнопка «Записаться»: flex 1.6 от остальных
  - Вся карточка: BorderRadius 20px, border 1px rgba(255,255,255,0.12)
```

---

### Инпуты

```dart
InputDecoration(
  filled: true,
  fillColor: kBgTertiary,
  border: OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadius.sm),
    borderSide: BorderSide(color: kBorder),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: BorderRadius.circular(AppRadius.sm),
    borderSide: BorderSide(color: kGold),
  ),
  labelStyle: AppTextStyles.caption.copyWith(
    color: kTextSecondary,
    letterSpacing: 0.5,
  ),
  contentPadding: EdgeInsets.symmetric(
    horizontal: AppSpacing.lg,
    vertical: AppSpacing.md,
  ),
)
```

---

### Tab Bar

```dart
// Плавающий Tab Bar с фоном #111118, BorderRadius 20px
// Активный таб: фон rgba(201,169,110,0.12), цвет текста #c9a96e
// Неактивный: цвет #5a5750

BottomNavigationBarThemeData(
  backgroundColor: kBgSecondary,
  selectedItemColor: kGold,
  unselectedItemColor: kTextTertiary,
  selectedLabelStyle: AppTextStyles.caption.copyWith(
    fontWeight: FontWeight.w700,
    fontSize: 10,
  ),
  unselectedLabelStyle: AppTextStyles.caption.copyWith(fontSize: 10),
  elevation: 0,
)
```

---

### Боттом-шит

```dart
showModalBottomSheet(
  backgroundColor: kBgSecondary,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(
      top: Radius.circular(AppRadius.lg),
    ),
  ),
  // Handle (ручка сверху):
  // Container 36×4px, BorderRadius 2px, цвет rgba(255,255,255,0.2)
)
```

---

### Статусы записи

```
CONFIRMED  — фон rgba(29,158,117,0.12),  текст #1d9e75,  точка ●
PENDING    — фон rgba(201,169,110,0.12), текст #c9a96e,  точка ●
CANCELLED  — фон rgba(212,116,138,0.12), текст #d4748a,  точка ●
```

---

### Чипы / теги специализаций

```
Активный:    фон #c9a96e, текст #0a0a0f, pill форма
Неактивный:  фон rgba(255,255,255,0.05), текст #9b9690, border rgba(255,255,255,0.1)
Rose:        фон rgba(212,116,138,0.12), текст #d4748a (для «Новое», «Онлайн»)
```

---

## Иконки

Использовать: **Phosphor Icons** для Flutter
```yaml
# pubspec.yaml
phosphor_flutter: ^2.0.1
```

Почему Phosphor а не Material Icons:
- 6 весов (Thin, Light, Regular, Bold, Fill, Duotone)
- Элегантнее и тоньше — соответствует стилю
- Regular + Bold = все нужные состояния
- 1000+ иконок включая все нужные для бьюти

```dart
// Примеры использования:
PhosphorIcon(PhosphorIcons.mapPin())         // Локация
PhosphorIcon(PhosphorIcons.heart())          // Избранное пустое
PhosphorIcon(PhosphorIcons.heartFill())      // Избранное заполненное
PhosphorIcon(PhosphorIcons.calendarBlank())  // Записи
PhosphorIcon(PhosphorIcons.chatCircle())     // Чат
PhosphorIcon(PhosphorIcons.star())           // Рейтинг
PhosphorIcon(PhosphorIcons.checkCircle())    // Выполнено
```

---

## Анимации

### Принципы
```
Длительность:
  Микро (нажатие кнопки):  150ms
  Переход между экранами:  300ms
  Боттом-шит появление:    250ms
  Свайп карточки:          200ms

Кривые (Curves):
  Появление: Curves.easeOut
  Исчезновение: Curves.easeIn
  Пружинящие (кнопки): Curves.elasticOut
```

### Свайп карточек (C-1)
```
Механика как в Tinder:
  - Перетаскивание с rotation (макс ±15 градусов)
  - Влево > 120px: анимация улёта влево (пропустить)
  - Вправо > 120px: переход на профиль мастера
  - Кнопка ✕: анимация улёта влево
  - Кнопка ♡: pulse анимация сердца + тост
  - Кнопка 📅: slide up боттом-шит с выбором услуги

Flutter пакет: flutter_card_swiper или custom GestureDetector
```

### Hero анимации (переходы)
```dart
// Фото мастера анимируется при переходе C-1 → C-2
Hero(
  tag: 'master_photo_${master.id}',
  child: MasterPhotoWidget(),
)
```

---

## Что НЕ переносим из лендинга

```
✗ Кастомный курсор (золотое кольцо) — на мобайле нет курсора
✗ Зернистый оверлей на всём экране — снижает FPS
✗ CSS анимации reveal при скролле — в Flutter свои механизмы
✗ Большие секционные заголовки — экран мобайла маленький
```

---

## Требования платформ (важно для модерации)

```
Минимальный шрифт:     11px (iOS) / 11sp (Android) — у нас мин. 12px ✓
Минимальная зона тапа: 44×44pt (iOS) / 48×48dp (Android) ✓
Контрастность текста:  4.5:1 минимум — #f0ede8 на #0a0a0f = 17:1 ✓
Safe Area:             Flutter SafeArea widget — автоматически ✓
Системный back:        GoRouter + CupertinoPageRoute ✓

App Icon:
  iOS:     1024×1024px PNG, без прозрачности, без скруглений
  Android: 1024×1024px PNG + Adaptive Icon (foreground + background)

Скриншоты для стора:
  iPhone: 6.7" (1290×2796px) — минимум 3, рекомендуется 5
  Android: минимум 2 скриншота
  Язык: русский (основной) + казахский
```

---

## Структура папок дизайна в Flutter проекте

```
lib/
  core/
    theme/
      app_colors.dart      — все цвета (константы)
      app_text_styles.dart — типографика
      app_spacing.dart     — отступы и радиусы
      app_theme.dart       — ThemeData для MaterialApp
    widgets/
      buttons/
        primary_button.dart
        outline_button.dart
        ghost_button.dart
      cards/
        master_card.dart    — свайп-карточка
        booking_card.dart   — карточка записи
        service_card.dart   — карточка услуги
      inputs/
        app_text_field.dart
        phone_input.dart
        otp_input.dart
      chips/
        spec_chip.dart      — специализация
        status_chip.dart    — статус записи
      misc/
        app_bottom_sheet.dart
        app_tab_bar.dart
        loading_widget.dart
        empty_state.dart    — пустые состояния

assets/
  fonts/
    Mulish-*.ttf
    PlayfairDisplay-*.ttf
  images/
    onboarding_1.png
    empty_feed.png
    empty_bookings.png
    verified_badge.svg
```

---

## Figma структура (для дизайнера или Google Stitch)

```
Miraku Design/
  ├── 00 Foundations
  │   ├── Colors
  │   ├── Typography
  │   ├── Spacing & Grid
  │   └── Icons (Phosphor)
  ├── 01 Components
  │   ├── Buttons
  │   ├── Inputs
  │   ├── Cards
  │   ├── Chips & Tags
  │   ├── Tab Bar
  │   ├── Bottom Sheets
  │   └── Status Badges
  ├── 02 Screens — Auth
  ├── 03 Screens — Client
  ├── 04 Screens — Master Onboarding
  ├── 05 Screens — Master Dashboard
  └── 06 Prototype flows
```

---

## Google Stitch промпты для экранов

Используй эти промпты в stitch.withgoogle.com для быстрой генерации вариантов:

**C-1 Свайп-лента:**
```
Dark luxury beauty app, Tinder-style swipe cards.
Full screen portrait photo background with dark gradient overlay.
Gold accent color #c9a96e. Master name in serif font (Playfair Display) 22px.
Specialization in gold uppercase overline. Rating, price, distance metadata.
Three bottom action buttons: skip (grey), favourite heart (rose #d4748a), book (gold, wider).
Verified badge chip top left. Mobile iOS 16, dark #0a0a0f background.
```

**M-6 Дашборд мастера:**
```
Dark beauty master dashboard mobile app.
Top: large toggle "Accepting bookings" gold active state.
Today stats: appointment count card + earnings card, gold accents.
Next appointment card with client name, service, time.
"Mark complete" gold button. Timeline of today's bookings.
Tab bar: Dashboard, Bookings, Schedule, Profile. Dark #111118 cards on #0a0a0f bg.
```

**C-4 Выбор времени:**
```
Dark mobile booking flow step 2 of 3.
Horizontal date scroller 14 days, selected date gold highlighted.
Time slots grid 3 columns: available white/transparent, 
booked grey disabled, selected gold background.
Service summary chip at top. Confirm button gold pill at bottom.
iOS dark theme, #0a0a0f background.
```
