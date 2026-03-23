/// Строки интерфейса. Язык определяется из настроек устройства.
/// Переключается вручную в профиле (настройки).
///
/// Расширение: добавить flutter_localizations + arb-файлы
/// когда появится бюджет на перевод KZ.
/// Пока — простая map-based реализация без кодогенерации.
class AppStrings {
  AppStrings._();

  static String lang = 'ru'; // 'ru' | 'kz' | 'en'

  static String get(String key) =>
      (_strings[key] ?? {})[lang] ?? _strings[key]?['ru'] ?? key;

  static const _strings = <String, Map<String, String>>{
    // ─── Auth ──────────────────────────────────────────────────────
    'login':              {'ru': 'Войти',         'kz': 'Кіру',          'en': 'Sign in'},
    'phone_hint':         {'ru': '700 000 00 00', 'kz': '700 000 00 00', 'en': '700 000 00 00'},
    'get_code':           {'ru': 'Получить код',  'kz': 'Код алу',       'en': 'Get code'},
    'enter_code':         {'ru': 'Введите код',   'kz': 'Кодты енгізіңіз', 'en': 'Enter code'},
    'resend':             {'ru': 'Отправить снова', 'kz': 'Қайта жіберу', 'en': 'Resend'},
    'your_name':          {'ru': 'Ваше имя',      'kz': 'Атыңыз',        'en': 'Your name'},
    'allow_location':     {'ru': 'Разрешить геолокацию', 'kz': 'Геолокацияға рұқсат беру', 'en': 'Allow location'},

    // ─── Feed ──────────────────────────────────────────────────────
    'no_masters':         {'ru': 'Мастеров не найдено', 'kz': 'Шебер табылмады', 'en': 'No masters found'},
    'increase_radius':    {'ru': 'Попробуйте увеличить радиус', 'kz': 'Іздеу радиусын ұлғайтып көріңіз', 'en': 'Try increasing the radius'},
    'book':               {'ru': 'Записаться',    'kz': 'Жазылу',        'en': 'Book'},
    'skip':               {'ru': 'Пропустить',    'kz': 'Өткізіп жіберу', 'en': 'Skip'},

    // ─── Tabs ──────────────────────────────────────────────────────
    'tab_feed':           {'ru': 'Лента',         'kz': 'Таспа',         'en': 'Feed'},
    'tab_favourites':     {'ru': 'Избранное',     'kz': 'Таңдаулы',      'en': 'Favourites'},
    'tab_chats':          {'ru': 'Чаты',          'kz': 'Чаттар',        'en': 'Chats'},
    'tab_bookings':       {'ru': 'Записи',        'kz': 'Жазбалар',      'en': 'Bookings'},
    'tab_profile':        {'ru': 'Профиль',       'kz': 'Профиль',       'en': 'Profile'},

    // ─── Profile ───────────────────────────────────────────────────
    'become_master':      {'ru': 'Стать мастером', 'kz': 'Шебер болу',   'en': 'Become a master'},
    'logout':             {'ru': 'Выйти',          'kz': 'Шығу',         'en': 'Log out'},
    'master_mode':        {'ru': 'Режим мастера',  'kz': 'Шебер режимі', 'en': 'Master mode'},
    'client_mode':        {'ru': 'Режим клиента',  'kz': 'Клиент режимі', 'en': 'Client mode'},

    // ─── Booking ───────────────────────────────────────────────────
    'select_service':     {'ru': 'Выберите услугу', 'kz': 'Қызметті таңдаңыз', 'en': 'Select service'},
    'select_time':        {'ru': 'Выберите время',  'kz': 'Уақытты таңдаңыз',  'en': 'Select time'},
    'confirm_booking':    {'ru': 'Подтвердить запись', 'kz': 'Жазылуды растау', 'en': 'Confirm booking'},
    'booking_success':    {'ru': 'Запись оформлена!', 'kz': 'Жазылу рәсімделді!', 'en': 'Booking confirmed!'},
    'cancel':             {'ru': 'Отменить',        'kz': 'Бас тарту',    'en': 'Cancel'},
    'payment_note':       {'ru': 'Оплата мастеру напрямую', 'kz': 'Төлем тікелей шеберге', 'en': 'Pay master directly'},

    // ─── Chat ──────────────────────────────────────────────────────
    'no_chats':           {'ru': 'Нет чатов',      'kz': 'Чаттар жоқ',   'en': 'No chats'},
    'start_chat':         {'ru': 'Начните переписку', 'kz': 'Хат алмасуды бастаңыз', 'en': 'Start a conversation'},
    'message_hint':       {'ru': 'Сообщение...',   'kz': 'Хабарлама...',  'en': 'Message...'},

    // ─── Master dashboard ──────────────────────────────────────────
    'accepting':          {'ru': 'Принимаю записи', 'kz': 'Жазылуды қабылдаймын', 'en': 'Accepting bookings'},
    'not_accepting':      {'ru': 'Не принимаю',    'kz': 'Қабылдамаймын', 'en': 'Not accepting'},
    'today_income':       {'ru': 'Сегодня',        'kz': 'Бүгін',         'en': 'Today'},
    'month_income':       {'ru': 'Этот месяц',     'kz': 'Осы ай',        'en': 'This month'},
    'next_booking':       {'ru': 'Следующая запись', 'kz': 'Келесі жазылу', 'en': 'Next booking'},

    // ─── Common ────────────────────────────────────────────────────
    'save':               {'ru': 'Сохранить',      'kz': 'Сақтау',        'en': 'Save'},
    'next':               {'ru': 'Далее',           'kz': 'Әрі қарай',    'en': 'Next'},
    'error':              {'ru': 'Ошибка',          'kz': 'Қате',          'en': 'Error'},
    'loading':            {'ru': 'Загрузка...',     'kz': 'Жүктелуде...',  'en': 'Loading...'},
    'no_items':           {'ru': 'Нет данных',      'kz': 'Деректер жоқ',  'en': 'No data'},
    'apply':              {'ru': 'Применить',       'kz': 'Қолдану',       'en': 'Apply'},
    'filters':            {'ru': 'Фильтры',         'kz': 'Сүзгілер',      'en': 'Filters'},
    'search_radius':      {'ru': 'Радиус поиска',   'kz': 'Іздеу радиусы', 'en': 'Search radius'},
  };
}
