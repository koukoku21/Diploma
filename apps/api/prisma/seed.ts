import {
  PrismaClient,
  MasterStatus,
  ServiceCategory,
  BookingStatus,
  BookingSource,
  CancelledBy,
} from '@prisma/client';
import * as crypto from 'crypto';

const prisma = new PrismaClient();

// ─── Photos ───────────────────────────────────────────────────────────────────

const PHOTOS = {
  manicure: [
    'https://images.unsplash.com/photo-1604654894610-df63bc536371?w=600&q=80',
    'https://images.unsplash.com/photo-1604654894607-7d3e9756f3b3?w=600&q=80',
    'https://images.unsplash.com/photo-1604654894604-f46f18fc6fd3?w=600&q=80',
    'https://images.unsplash.com/photo-1604654894601-4b9dd1b6a9e1?w=600&q=80',
    'https://images.unsplash.com/photo-1604654894598-a5a7c8a7b6e1?w=600&q=80',
  ],
  hair: [
    'https://images.unsplash.com/photo-1560869713-7d0a29430803?w=600&q=80',
    'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?w=600&q=80',
    'https://images.unsplash.com/photo-1595476108010-b4d1f102b1b1?w=600&q=80',
    'https://images.unsplash.com/photo-1562322140-8baeececf3df?w=600&q=80',
    'https://images.unsplash.com/photo-1500840216050-6ffa99d75160?w=600&q=80',
  ],
  makeup: [
    'https://images.unsplash.com/photo-1487412947147-5cebf100ffc2?w=600&q=80',
    'https://images.unsplash.com/photo-1512496015851-a90fb38ba796?w=600&q=80',
    'https://images.unsplash.com/photo-1503236823255-94609f598e71?w=600&q=80',
    'https://images.unsplash.com/photo-1526045612212-70caf35c14df?w=600&q=80',
    'https://images.unsplash.com/photo-1583241800698-e8ab01830a22?w=600&q=80',
  ],
  skincare: [
    'https://images.unsplash.com/photo-1598440947619-2c35fc9aa908?w=600&q=80',
    'https://images.unsplash.com/photo-1570172619644-dfd03ed5d881?w=600&q=80',
    'https://images.unsplash.com/photo-1556228578-8c89e6adf883?w=600&q=80',
    'https://images.unsplash.com/photo-1620916566398-39f1143ab7be?w=600&q=80',
    'https://images.unsplash.com/photo-1616394584738-fc6e612e71b9?w=600&q=80',
  ],
  lashes: [
    'https://images.unsplash.com/photo-1583241800698-e8ab01830a22?w=600&q=80',
    'https://images.unsplash.com/photo-1487412947147-5cebf100ffc2?w=600&q=80',
    'https://images.unsplash.com/photo-1526045612212-70caf35c14df?w=600&q=80',
    'https://images.unsplash.com/photo-1512496015851-a90fb38ba796?w=600&q=80',
    'https://images.unsplash.com/photo-1503236823255-94609f598e71?w=600&q=80',
  ],
};

const MASTER_AVATARS = [
  'https://i.pravatar.cc/300?img=47',
  'https://i.pravatar.cc/300?img=49',
  'https://i.pravatar.cc/300?img=44',
  'https://i.pravatar.cc/300?img=48',
  'https://i.pravatar.cc/300?img=45',
  'https://i.pravatar.cc/300?img=43',
  'https://i.pravatar.cc/300?img=46',
  'https://i.pravatar.cc/300?img=41',
  'https://i.pravatar.cc/300?img=42',
  'https://i.pravatar.cc/300?img=40',
];

const CLIENT_AVATARS = [
  'https://i.pravatar.cc/300?img=1',
  'https://i.pravatar.cc/300?img=2',
  'https://i.pravatar.cc/300?img=3',
  'https://i.pravatar.cc/300?img=5',
  'https://i.pravatar.cc/300?img=6',
  'https://i.pravatar.cc/300?img=7',
  'https://i.pravatar.cc/300?img=8',
  'https://i.pravatar.cc/300?img=9',
];

// ─── Review texts ─────────────────────────────────────────────────────────────

const REVIEW_TEXTS_5 = [
  'Просто великолепно! Очень довольна результатом, буду приходить только сюда.',
  'Мастер — профессионал с большой буквы. Всё аккуратно, быстро и красиво!',
  'Рекомендую всем! Приятная атмосфера, чистое рабочее место, идеальный результат.',
  'Записалась впервые и теперь постоянный клиент. Спасибо за работу!',
  'Держится уже 3 недели, ни сколов, ни трещин. 5 звёзд без раздумий.',
  'Лучший мастер в городе! Учтёт все пожелания, всё объяснит.',
  'Потрясающая работа, результат превзошёл ожидания. Всем советую!',
  'Очень внимательный мастер, выслушала все пожелания. Буду возвращаться.',
  'Качество на высшем уровне, цены адекватные. Очень довольна!',
  'Подруге тоже порекомендовала — теперь ходим вместе.',
];

const REVIEW_TEXTS_4 = [
  'Хорошая работа, всё аккуратно и чисто. Немного подождала, но результат стоит.',
  'Довольна в целом, мастер приятный и профессиональный.',
  'Всё сделала хорошо, пришла ещё раз. Рекомендую.',
  'Хорошая работа, цены разумные. Приду снова.',
  'Мастер внимательная, работа качественная. Небольшое опоздание, но всё ок.',
];

const REVIEW_TEXTS_3 = [
  'Работа выполнена нормально, но немного затянулась по времени.',
  'В целом неплохо, но ожидала немного другого результата.',
];

// ─── Master definitions ───────────────────────────────────────────────────────

interface ServiceDef {
  title: string;
  category: ServiceCategory;
  priceFrom: number;
  durationMin: number;
}

interface ScheduleEntry {
  dayOfWeek: number; // 0=Sun, 1=Mon … 6=Sat
  startTime: string;
  endTime: string;
  isDayOff: boolean;
}

interface MasterDef {
  phone: string;
  name: string;
  avatarUrl: string;
  bio: string;
  address: string;
  lat: number;
  lng: number;
  username: string;
  bookingSlug: string;
  specs: ServiceCategory[];
  photos: string[];
  services: ServiceDef[];
  schedule: ScheduleEntry[];
  completedCount: number; // past completed bookings to generate
}

const MASTERS: MasterDef[] = [
  {
    phone: '+77001110001',
    name: 'Айгерим Сейткали',
    avatarUrl: MASTER_AVATARS[0],
    bio: 'Мастер маникюра с 5-летним опытом. Работаю в центре Астаны. Специализируюсь на дизайне и гель-лаке.',
    address: 'ул. Кенесары 40, Астана',
    lat: 51.1801, lng: 71.4460,
    username: 'aigerim_nail',
    bookingSlug: 'a1b2c3d4',
    specs: [ServiceCategory.MANICURE, ServiceCategory.PEDICURE],
    photos: PHOTOS.manicure,
    services: [
      { title: 'Маникюр классический',  category: ServiceCategory.MANICURE,  priceFrom: 5000,  durationMin: 60  },
      { title: 'Маникюр + гель-лак',    category: ServiceCategory.MANICURE,  priceFrom: 8000,  durationMin: 90  },
      { title: 'Педикюр классический',  category: ServiceCategory.PEDICURE,  priceFrom: 7000,  durationMin: 90  },
      { title: 'Педикюр + гель-лак',    category: ServiceCategory.PEDICURE,  priceFrom: 10000, durationMin: 120 },
    ],
    schedule: [
      { dayOfWeek: 1, startTime: '10:00', endTime: '19:00', isDayOff: false },
      { dayOfWeek: 2, startTime: '10:00', endTime: '19:00', isDayOff: false },
      { dayOfWeek: 3, startTime: '10:00', endTime: '19:00', isDayOff: false },
      { dayOfWeek: 4, startTime: '10:00', endTime: '19:00', isDayOff: false },
      { dayOfWeek: 5, startTime: '10:00', endTime: '19:00', isDayOff: false },
      { dayOfWeek: 6, startTime: '10:00', endTime: '16:00', isDayOff: false },
      { dayOfWeek: 0, startTime: '00:00', endTime: '00:00', isDayOff: true  },
    ],
    completedCount: 28,
  },
  {
    phone: '+77001110002',
    name: 'Дана Бекова',
    avatarUrl: MASTER_AVATARS[1],
    bio: 'Колорист и стилист. Специализируюсь на окрашивании, стрижках и уходе за волосами. Работаю только с проверенными брендами.',
    address: 'пр. Республики 15, Астана',
    lat: 51.1694, lng: 71.4491,
    username: 'dana_hair',
    bookingSlug: 'e5f6a7b8',
    specs: [ServiceCategory.HAIRCUT, ServiceCategory.COLORING],
    photos: PHOTOS.hair,
    services: [
      { title: 'Женская стрижка',         category: ServiceCategory.HAIRCUT,  priceFrom: 8000,  durationMin: 60  },
      { title: 'Мужская стрижка',         category: ServiceCategory.HAIRCUT,  priceFrom: 4000,  durationMin: 30  },
      { title: 'Детская стрижка',         category: ServiceCategory.HAIRCUT,  priceFrom: 3500,  durationMin: 30  },
      { title: 'Окрашивание (корни)',     category: ServiceCategory.COLORING, priceFrom: 12000, durationMin: 120 },
      { title: 'Окрашивание (вся длина)', category: ServiceCategory.COLORING, priceFrom: 20000, durationMin: 180 },
      { title: 'Балаяж / омбре',         category: ServiceCategory.COLORING, priceFrom: 25000, durationMin: 210 },
    ],
    schedule: [
      { dayOfWeek: 0, startTime: '11:00', endTime: '19:00', isDayOff: false },
      { dayOfWeek: 1, startTime: '00:00', endTime: '00:00', isDayOff: true  },
      { dayOfWeek: 2, startTime: '11:00', endTime: '20:00', isDayOff: false },
      { dayOfWeek: 3, startTime: '11:00', endTime: '20:00', isDayOff: false },
      { dayOfWeek: 4, startTime: '11:00', endTime: '20:00', isDayOff: false },
      { dayOfWeek: 5, startTime: '11:00', endTime: '20:00', isDayOff: false },
      { dayOfWeek: 6, startTime: '11:00', endTime: '20:00', isDayOff: false },
    ],
    completedCount: 22,
  },
  {
    phone: '+77001110003',
    name: 'Гульнур Ахметова',
    avatarUrl: MASTER_AVATARS[2],
    bio: 'Визажист с 7 годами опыта. Свадебный и вечерний макияж, коррекция и окраска бровей. Работала с телеканалами и модными показами.',
    address: 'ул. Сейфуллина 12, Астана',
    lat: 51.1850, lng: 71.4380,
    username: 'gulnur_makeup',
    bookingSlug: 'c9d0e1f2',
    specs: [ServiceCategory.MAKEUP, ServiceCategory.BROWS, ServiceCategory.LASHES],
    photos: PHOTOS.makeup,
    services: [
      { title: 'Дневной макияж',              category: ServiceCategory.MAKEUP,  priceFrom: 10000, durationMin: 60  },
      { title: 'Вечерний макияж',             category: ServiceCategory.MAKEUP,  priceFrom: 15000, durationMin: 90  },
      { title: 'Свадебный макияж',            category: ServiceCategory.MAKEUP,  priceFrom: 25000, durationMin: 120 },
      { title: 'Коррекция бровей',            category: ServiceCategory.BROWS,   priceFrom: 4000,  durationMin: 30  },
      { title: 'Окрашивание бровей хной',     category: ServiceCategory.BROWS,   priceFrom: 6000,  durationMin: 45  },
      { title: 'Наращивание ресниц (класс.)', category: ServiceCategory.LASHES,  priceFrom: 12000, durationMin: 120 },
      { title: 'Наращивание ресниц (объём)',  category: ServiceCategory.LASHES,  priceFrom: 16000, durationMin: 150 },
    ],
    schedule: [
      { dayOfWeek: 1, startTime: '10:00', endTime: '18:00', isDayOff: false },
      { dayOfWeek: 2, startTime: '10:00', endTime: '18:00', isDayOff: false },
      { dayOfWeek: 3, startTime: '10:00', endTime: '18:00', isDayOff: false },
      { dayOfWeek: 4, startTime: '10:00', endTime: '18:00', isDayOff: false },
      { dayOfWeek: 5, startTime: '10:00', endTime: '18:00', isDayOff: false },
      { dayOfWeek: 6, startTime: '00:00', endTime: '00:00', isDayOff: true  },
      { dayOfWeek: 0, startTime: '00:00', endTime: '00:00', isDayOff: true  },
    ],
    completedCount: 30,
  },
  {
    phone: '+77001110004',
    name: 'Меруерт Джаксыбекова',
    avatarUrl: MASTER_AVATARS[3],
    bio: 'Косметолог-эстетист. Глубокие чистки, пилинги, уходовые процедуры для всех типов кожи. Диплом Москва 2019.',
    address: 'ул. Достык 5, Астана',
    lat: 51.1750, lng: 71.4600,
    username: 'meruert_skin',
    bookingSlug: 'g3h4i5j6',
    specs: [ServiceCategory.SKINCARE],
    photos: PHOTOS.skincare,
    services: [
      { title: 'Классическая чистка лица', category: ServiceCategory.SKINCARE, priceFrom: 10000, durationMin: 60 },
      { title: 'Химический пилинг',        category: ServiceCategory.SKINCARE, priceFrom: 14000, durationMin: 60 },
      { title: 'Увлажняющий уход',         category: ServiceCategory.SKINCARE, priceFrom: 8000,  durationMin: 45 },
      { title: 'Биоревитализация',         category: ServiceCategory.SKINCARE, priceFrom: 20000, durationMin: 60 },
      { title: 'Лимфодренажный массаж',    category: ServiceCategory.SKINCARE, priceFrom: 9000,  durationMin: 60 },
    ],
    schedule: [
      { dayOfWeek: 1, startTime: '09:00', endTime: '18:00', isDayOff: false },
      { dayOfWeek: 2, startTime: '09:00', endTime: '18:00', isDayOff: false },
      { dayOfWeek: 3, startTime: '09:00', endTime: '18:00', isDayOff: false },
      { dayOfWeek: 4, startTime: '09:00', endTime: '18:00', isDayOff: false },
      { dayOfWeek: 5, startTime: '09:00', endTime: '18:00', isDayOff: false },
      { dayOfWeek: 6, startTime: '09:00', endTime: '14:00', isDayOff: false },
      { dayOfWeek: 0, startTime: '00:00', endTime: '00:00', isDayOff: true  },
    ],
    completedCount: 20,
  },
  {
    phone: '+77001110005',
    name: 'Айнур Касымова',
    avatarUrl: MASTER_AVATARS[4],
    bio: 'Универсальный мастер: маникюр и макияж для любого случая. Работаю с натуральными материалами без аллергенов.',
    address: 'ул. Богенбай батыра 28, Астана',
    lat: 51.1780, lng: 71.4520,
    username: 'ainur_beauty',
    bookingSlug: 'k7l8m9n0',
    specs: [ServiceCategory.MANICURE, ServiceCategory.MAKEUP],
    photos: [...PHOTOS.manicure.slice(0, 3), ...PHOTOS.makeup.slice(0, 2)],
    services: [
      { title: 'Маникюр без покрытия', category: ServiceCategory.MANICURE, priceFrom: 4000,  durationMin: 45 },
      { title: 'Маникюр гель-лак',    category: ServiceCategory.MANICURE, priceFrom: 7000,  durationMin: 75 },
      { title: 'Макияж дневной',      category: ServiceCategory.MAKEUP,   priceFrom: 8000,  durationMin: 60 },
      { title: 'Макияж вечерний',     category: ServiceCategory.MAKEUP,   priceFrom: 12000, durationMin: 90 },
    ],
    schedule: [
      { dayOfWeek: 1, startTime: '12:00', endTime: '20:00', isDayOff: false },
      { dayOfWeek: 2, startTime: '12:00', endTime: '20:00', isDayOff: false },
      { dayOfWeek: 3, startTime: '12:00', endTime: '20:00', isDayOff: false },
      { dayOfWeek: 4, startTime: '12:00', endTime: '20:00', isDayOff: false },
      { dayOfWeek: 5, startTime: '12:00', endTime: '20:00', isDayOff: false },
      { dayOfWeek: 6, startTime: '00:00', endTime: '00:00', isDayOff: true  },
      { dayOfWeek: 0, startTime: '00:00', endTime: '00:00', isDayOff: true  },
    ],
    completedCount: 17,
  },
  {
    phone: '+77001110006',
    name: 'Зарина Нурланова',
    avatarUrl: MASTER_AVATARS[5],
    bio: 'Мастер по ресницам и бровям с 4-летним стажем. Создаю идеальный взгляд. Использую только гипоаллергенные материалы.',
    address: 'ул. Туркестан 10, Астана',
    lat: 51.1920, lng: 71.4550,
    username: 'zarina_lash',
    bookingSlug: 'p1q2r3s4',
    specs: [ServiceCategory.LASHES, ServiceCategory.BROWS],
    photos: PHOTOS.lashes,
    services: [
      { title: 'Наращивание ресниц классика',   category: ServiceCategory.LASHES, priceFrom: 11000, durationMin: 120 },
      { title: 'Наращивание ресниц 2D/3D',      category: ServiceCategory.LASHES, priceFrom: 14000, durationMin: 150 },
      { title: 'Ламинирование ресниц',          category: ServiceCategory.LASHES, priceFrom: 8000,  durationMin: 60  },
      { title: 'Коррекция ресниц',              category: ServiceCategory.LASHES, priceFrom: 5000,  durationMin: 60  },
      { title: 'Коррекция бровей',              category: ServiceCategory.BROWS,  priceFrom: 3500,  durationMin: 30  },
      { title: 'Окрашивание бровей',            category: ServiceCategory.BROWS,  priceFrom: 4500,  durationMin: 30  },
    ],
    schedule: [
      { dayOfWeek: 0, startTime: '10:00', endTime: '18:00', isDayOff: false },
      { dayOfWeek: 1, startTime: '00:00', endTime: '00:00', isDayOff: true  },
      { dayOfWeek: 2, startTime: '00:00', endTime: '00:00', isDayOff: true  },
      { dayOfWeek: 3, startTime: '10:00', endTime: '19:00', isDayOff: false },
      { dayOfWeek: 4, startTime: '10:00', endTime: '19:00', isDayOff: false },
      { dayOfWeek: 5, startTime: '10:00', endTime: '19:00', isDayOff: false },
      { dayOfWeek: 6, startTime: '10:00', endTime: '19:00', isDayOff: false },
    ],
    completedCount: 24,
  },
  {
    phone: '+77001110007',
    name: 'Самал Абенова',
    avatarUrl: MASTER_AVATARS[6],
    bio: 'Парикмахер-стилист. 8 лет опыта, 300+ довольных клиентов. Стрижки на любую длину, укладка, лечение волос.',
    address: 'пр. Кабанбай батыра 3, Астана',
    lat: 51.1650, lng: 71.4650,
    username: 'samal_hair',
    bookingSlug: 't5u6v7w8',
    specs: [ServiceCategory.HAIRCUT, ServiceCategory.COLORING],
    photos: [...PHOTOS.hair.slice(0, 3), ...PHOTOS.hair.slice(2, 5)],
    services: [
      { title: 'Женская стрижка',      category: ServiceCategory.HAIRCUT,  priceFrom: 7000,  durationMin: 60  },
      { title: 'Мужская стрижка',      category: ServiceCategory.HAIRCUT,  priceFrom: 3500,  durationMin: 30  },
      { title: 'Укладка волос',        category: ServiceCategory.HAIRCUT,  priceFrom: 5000,  durationMin: 45  },
      { title: 'Лечение волос (маска)',category: ServiceCategory.HAIRCUT,  priceFrom: 6000,  durationMin: 45  },
      { title: 'Мелирование',         category: ServiceCategory.COLORING, priceFrom: 15000, durationMin: 120 },
    ],
    schedule: [
      { dayOfWeek: 1, startTime: '09:00', endTime: '17:00', isDayOff: false },
      { dayOfWeek: 2, startTime: '09:00', endTime: '17:00', isDayOff: false },
      { dayOfWeek: 3, startTime: '09:00', endTime: '17:00', isDayOff: false },
      { dayOfWeek: 4, startTime: '09:00', endTime: '17:00', isDayOff: false },
      { dayOfWeek: 5, startTime: '09:00', endTime: '17:00', isDayOff: false },
      { dayOfWeek: 6, startTime: '09:00', endTime: '15:00', isDayOff: false },
      { dayOfWeek: 0, startTime: '00:00', endTime: '00:00', isDayOff: true  },
    ],
    completedCount: 35,
  },
  {
    phone: '+77001110008',
    name: 'Карина Иванова',
    avatarUrl: MASTER_AVATARS[7],
    bio: 'Мастер ногтевого сервиса. Маникюр, педикюр, наращивание ногтей. Стерильность — главный приоритет.',
    address: 'ул. Иманова 19, Астана',
    lat: 51.1820, lng: 71.4420,
    username: 'karina_nails',
    bookingSlug: 'x9y0z1a2',
    specs: [ServiceCategory.MANICURE, ServiceCategory.PEDICURE],
    photos: [...PHOTOS.manicure.slice(1, 4), ...PHOTOS.skincare.slice(0, 2)],
    services: [
      { title: 'Маникюр классический',    category: ServiceCategory.MANICURE,  priceFrom: 4500,  durationMin: 60  },
      { title: 'Маникюр + шеллак',        category: ServiceCategory.MANICURE,  priceFrom: 7500,  durationMin: 80  },
      { title: 'Наращивание гелем',       category: ServiceCategory.MANICURE,  priceFrom: 13000, durationMin: 120 },
      { title: 'Педикюр классический',    category: ServiceCategory.PEDICURE,  priceFrom: 6500,  durationMin: 80  },
      { title: 'Педикюр + шеллак',        category: ServiceCategory.PEDICURE,  priceFrom: 9000,  durationMin: 100 },
    ],
    schedule: [
      { dayOfWeek: 1, startTime: '10:00', endTime: '19:00', isDayOff: false },
      { dayOfWeek: 2, startTime: '10:00', endTime: '19:00', isDayOff: false },
      { dayOfWeek: 3, startTime: '10:00', endTime: '19:00', isDayOff: false },
      { dayOfWeek: 4, startTime: '10:00', endTime: '19:00', isDayOff: false },
      { dayOfWeek: 5, startTime: '10:00', endTime: '19:00', isDayOff: false },
      { dayOfWeek: 6, startTime: '10:00', endTime: '15:00', isDayOff: false },
      { dayOfWeek: 0, startTime: '00:00', endTime: '00:00', isDayOff: true  },
    ],
    completedCount: 19,
  },
  {
    phone: '+77001110009',
    name: 'Жанар Умбеталиева',
    avatarUrl: MASTER_AVATARS[8],
    bio: 'Косметолог, работаю на дому. Мягкие методики, без боли. Прийди с усталым лицом — уйди с сияющим.',
    address: 'ул. Абая 22, Астана',
    lat: 51.1730, lng: 71.4580,
    username: 'zhanar_care',
    bookingSlug: 'b3c4d5e6',
    specs: [ServiceCategory.SKINCARE, ServiceCategory.OTHER],
    photos: [...PHOTOS.skincare.slice(0, 3), ...PHOTOS.makeup.slice(3, 5)],
    services: [
      { title: 'Чистка лица ультразвуком', category: ServiceCategory.SKINCARE, priceFrom: 11000, durationMin: 60 },
      { title: 'Омолаживающий уход',       category: ServiceCategory.SKINCARE, priceFrom: 12000, durationMin: 75 },
      { title: 'Массаж лица',             category: ServiceCategory.OTHER,    priceFrom: 6000,  durationMin: 45 },
      { title: 'Депиляция (верхняя губа)', category: ServiceCategory.OTHER,    priceFrom: 2000,  durationMin: 15 },
      { title: 'Депиляция (ноги)',        category: ServiceCategory.OTHER,    priceFrom: 7000,  durationMin: 45 },
    ],
    schedule: [
      { dayOfWeek: 0, startTime: '00:00', endTime: '00:00', isDayOff: true  },
      { dayOfWeek: 1, startTime: '00:00', endTime: '00:00', isDayOff: true  },
      { dayOfWeek: 2, startTime: '10:00', endTime: '18:00', isDayOff: false },
      { dayOfWeek: 3, startTime: '10:00', endTime: '18:00', isDayOff: false },
      { dayOfWeek: 4, startTime: '10:00', endTime: '18:00', isDayOff: false },
      { dayOfWeek: 5, startTime: '10:00', endTime: '18:00', isDayOff: false },
      { dayOfWeek: 6, startTime: '10:00', endTime: '15:00', isDayOff: false },
    ],
    completedCount: 14,
  },
  {
    phone: '+77001110010',
    name: 'Арайлым Сабитова',
    avatarUrl: MASTER_AVATARS[9],
    bio: 'Визажист и мастер по ресницам. Работаю в студии на Левом берегу. Принимаю с 11 до 21, включая выходные.',
    address: 'пр. Туран 55, Астана',
    lat: 51.1860, lng: 71.4700,
    username: 'araylym_glam',
    bookingSlug: 'f7g8h9i0',
    specs: [ServiceCategory.MAKEUP, ServiceCategory.LASHES],
    photos: [...PHOTOS.makeup.slice(0, 3), ...PHOTOS.lashes.slice(2, 5)],
    services: [
      { title: 'Макияж на каждый день',    category: ServiceCategory.MAKEUP,  priceFrom: 9000,  durationMin: 60  },
      { title: 'Вечерний макияж',          category: ServiceCategory.MAKEUP,  priceFrom: 14000, durationMin: 90  },
      { title: 'Свадебный образ (полный)', category: ServiceCategory.MAKEUP,  priceFrom: 30000, durationMin: 150 },
      { title: 'Наращивание ресниц',       category: ServiceCategory.LASHES,  priceFrom: 12000, durationMin: 120 },
      { title: 'Ламинирование ресниц',     category: ServiceCategory.LASHES,  priceFrom: 7500,  durationMin: 60  },
    ],
    schedule: [
      { dayOfWeek: 0, startTime: '11:00', endTime: '21:00', isDayOff: false },
      { dayOfWeek: 1, startTime: '11:00', endTime: '21:00', isDayOff: false },
      { dayOfWeek: 2, startTime: '11:00', endTime: '21:00', isDayOff: false },
      { dayOfWeek: 3, startTime: '11:00', endTime: '21:00', isDayOff: false },
      { dayOfWeek: 4, startTime: '11:00', endTime: '21:00', isDayOff: false },
      { dayOfWeek: 5, startTime: '11:00', endTime: '21:00', isDayOff: false },
      { dayOfWeek: 6, startTime: '11:00', endTime: '21:00', isDayOff: false },
    ],
    completedCount: 26,
  },
];

// ─── Clients ──────────────────────────────────────────────────────────────────

const CLIENTS = [
  { phone: '+77009990001', name: 'Алия Жумабекова',    avatarUrl: CLIENT_AVATARS[0] },
  { phone: '+77009990002', name: 'Мадина Сериккали',   avatarUrl: CLIENT_AVATARS[1] },
  { phone: '+77009990003', name: 'Диана Ли',           avatarUrl: CLIENT_AVATARS[2] },
  { phone: '+77009990004', name: 'Сауле Нурмагамбет',  avatarUrl: CLIENT_AVATARS[3] },
  { phone: '+77009990005', name: 'Камилла Ахмед',      avatarUrl: CLIENT_AVATARS[4] },
  { phone: '+77009990006', name: 'Виктория Павлова',   avatarUrl: CLIENT_AVATARS[5] },
  { phone: '+77009990007', name: 'Аяулым Ергалиева',   avatarUrl: CLIENT_AVATARS[6] },
  { phone: '+77009990008', name: 'Наргиза Усманова',   avatarUrl: CLIENT_AVATARS[7] },
];

// ─── Service templates ────────────────────────────────────────────────────────

const SERVICE_TEMPLATES = [
  { name: 'Маникюр классический',          nameKz: 'Классикалық маникюр',         category: ServiceCategory.MANICURE,  sortOrder: 1 },
  { name: 'Маникюр + гель-лак',            nameKz: 'Маникюр + гель-лак',          category: ServiceCategory.MANICURE,  sortOrder: 2 },
  { name: 'Маникюр без покрытия',          nameKz: 'Жабынсыз маникюр',            category: ServiceCategory.MANICURE,  sortOrder: 3 },
  { name: 'Наращивание ногтей',            nameKz: 'Тырнақ ұзарту',               category: ServiceCategory.MANICURE,  sortOrder: 4 },
  { name: 'Педикюр классический',          nameKz: 'Классикалық педикюр',         category: ServiceCategory.PEDICURE,  sortOrder: 1 },
  { name: 'Педикюр + гель-лак',            nameKz: 'Педикюр + гель-лак',          category: ServiceCategory.PEDICURE,  sortOrder: 2 },
  { name: 'Аппаратный педикюр',            nameKz: 'Аппараттық педикюр',          category: ServiceCategory.PEDICURE,  sortOrder: 3 },
  { name: 'Женская стрижка',               nameKz: 'Әйелдер шаштарауы',           category: ServiceCategory.HAIRCUT,   sortOrder: 1 },
  { name: 'Мужская стрижка',               nameKz: 'Ерлер шаштарауы',             category: ServiceCategory.HAIRCUT,   sortOrder: 2 },
  { name: 'Детская стрижка',               nameKz: 'Балалар шаштарауы',           category: ServiceCategory.HAIRCUT,   sortOrder: 3 },
  { name: 'Укладка волос',                 nameKz: 'Шашты кию',                   category: ServiceCategory.HAIRCUT,   sortOrder: 4 },
  { name: 'Окрашивание (корни)',            nameKz: 'Тамырды бояу',                category: ServiceCategory.COLORING,  sortOrder: 1 },
  { name: 'Окрашивание (вся длина)',        nameKz: 'Толық бояу',                  category: ServiceCategory.COLORING,  sortOrder: 2 },
  { name: 'Мелирование',                   nameKz: 'Мелировка',                   category: ServiceCategory.COLORING,  sortOrder: 3 },
  { name: 'Балаяж / омбре',                nameKz: 'Балаяж / омбре',              category: ServiceCategory.COLORING,  sortOrder: 4 },
  { name: 'Макияж дневной',                nameKz: 'Күндізгі макияж',             category: ServiceCategory.MAKEUP,    sortOrder: 1 },
  { name: 'Макияж вечерний',               nameKz: 'Кешкі макияж',                category: ServiceCategory.MAKEUP,    sortOrder: 2 },
  { name: 'Макияж свадебный',              nameKz: 'Үйлену тойы макияжы',         category: ServiceCategory.MAKEUP,    sortOrder: 3 },
  { name: 'Наращивание ресниц (классика)', nameKz: 'Кірпік ұзарту (классика)',    category: ServiceCategory.LASHES,    sortOrder: 1 },
  { name: 'Наращивание ресниц (объём)',    nameKz: 'Кірпік ұзарту (көлем)',       category: ServiceCategory.LASHES,    sortOrder: 2 },
  { name: 'Ламинирование ресниц',          nameKz: 'Кірпікті ламиниялау',         category: ServiceCategory.LASHES,    sortOrder: 3 },
  { name: 'Коррекция бровей',              nameKz: 'Қас түзеу',                   category: ServiceCategory.BROWS,     sortOrder: 1 },
  { name: 'Окрашивание бровей',            nameKz: 'Қасты бояу',                  category: ServiceCategory.BROWS,     sortOrder: 2 },
  { name: 'Оформление бровей хной',        nameKz: 'Хнамен қас безендіру',        category: ServiceCategory.BROWS,     sortOrder: 3 },
  { name: 'Чистка лица',                   nameKz: 'Бет тазалау',                 category: ServiceCategory.SKINCARE,  sortOrder: 1 },
  { name: 'Химический пилинг',             nameKz: 'Химиялық пилинг',             category: ServiceCategory.SKINCARE,  sortOrder: 2 },
  { name: 'Увлажняющий уход',              nameKz: 'Ылғалдандыру процедурасы',    category: ServiceCategory.SKINCARE,  sortOrder: 3 },
  { name: 'Биоревитализация',              nameKz: 'Биоревитализация',            category: ServiceCategory.SKINCARE,  sortOrder: 4 },
  { name: 'Массаж лица',                   nameKz: 'Бет массажы',                 category: ServiceCategory.OTHER,     sortOrder: 1 },
  { name: 'Депиляция',                     nameKz: 'Депиляция',                   category: ServiceCategory.OTHER,     sortOrder: 2 },
];

// ─── Helpers ──────────────────────────────────────────────────────────────────

function rInt(min: number, max: number): number {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

function pick<T>(arr: T[]): T {
  return arr[rInt(0, arr.length - 1)];
}

function daysAgo(n: number, hour: number): Date {
  const d = new Date();
  d.setDate(d.getDate() - n);
  d.setHours(hour, 0, 0, 0);
  d.setMilliseconds(0);
  return d;
}

function daysFromNow(n: number, hour: number): Date {
  const d = new Date();
  d.setDate(d.getDate() + n);
  d.setHours(hour, 0, 0, 0);
  d.setMilliseconds(0);
  return d;
}

function weightedRating(): number {
  const r = Math.random();
  if (r < 0.68) return 5;
  if (r < 0.93) return 4;
  return 3;
}

function reviewText(rating: number): string | null {
  if (Math.random() < 0.25) return null; // 25% без текста
  if (rating === 5) return pick(REVIEW_TEXTS_5);
  if (rating === 4) return pick(REVIEW_TEXTS_4);
  return pick(REVIEW_TEXTS_3);
}

// ─── Seed bookings + reviews ──────────────────────────────────────────────────

async function seedBookingsForMaster(
  masterId: string,
  services: Array<{ id: string; priceFrom: number; durationMin: number }>,
  clients: Array<{ id: string; name: string }>,
  completedCount: number,
) {
  // ── Completed (past) ────────────────────────────────────────────────────────
  const completedBookings: Array<{ id: string; startsAt: Date; clientId: string }> = [];

  for (let i = 0; i < completedCount; i++) {
    const svc = pick(services);
    const dayN = rInt(2, 90);
    const hour = rInt(9, 17);
    const startsAt = daysAgo(dayN, hour);
    const endsAt = new Date(startsAt.getTime() + svc.durationMin * 60000);
    const client = pick(clients);

    const b = await prisma.booking.create({
      data: {
        clientId:      client.id,
        masterId,
        serviceId:     svc.id,
        startsAt,
        endsAt,
        status:        BookingStatus.COMPLETED,
        source:        Math.random() < 0.2 ? BookingSource.PWA_LINK : BookingSource.APP,
        priceSnapshot: svc.priceFrom,
        completedAt:   endsAt,
      },
    });
    completedBookings.push({ id: b.id, startsAt, clientId: client.id });
  }

  // ── Cancelled (past) ────────────────────────────────────────────────────────
  const cancelCount = rInt(2, 4);
  for (let i = 0; i < cancelCount; i++) {
    const svc = pick(services);
    const dayN = rInt(2, 60);
    const hour = rInt(9, 17);
    const startsAt = daysAgo(dayN, hour);
    const endsAt = new Date(startsAt.getTime() + svc.durationMin * 60000);
    const client = pick(clients);

    await prisma.booking.create({
      data: {
        clientId:      client.id,
        masterId,
        serviceId:     svc.id,
        startsAt,
        endsAt,
        status:        BookingStatus.CANCELLED,
        source:        BookingSource.APP,
        priceSnapshot: svc.priceFrom,
        cancelledBy:   CancelledBy.CLIENT,
        cancelReason:  'Изменились планы',
      },
    });
  }

  // ── Upcoming (future) ────────────────────────────────────────────────────────
  const upcomingCount = rInt(3, 5);
  for (let i = 0; i < upcomingCount; i++) {
    const svc = pick(services);
    const dayN = rInt(1, 12);
    const hour = rInt(10, 18);
    const startsAt = daysFromNow(dayN + i, hour); // +i to avoid time overlap
    const endsAt = new Date(startsAt.getTime() + svc.durationMin * 60000);
    const client = pick(clients);

    await prisma.booking.create({
      data: {
        clientId:      client.id,
        masterId,
        serviceId:     svc.id,
        startsAt,
        endsAt,
        status:        BookingStatus.CONFIRMED,
        source:        Math.random() < 0.3 ? BookingSource.PWA_LINK : BookingSource.APP,
        priceSnapshot: svc.priceFrom,
      },
    });
  }

  return completedBookings;
}

async function seedReviewsForMaster(
  masterId: string,
  completedBookings: Array<{ id: string; startsAt: Date; clientId: string }>,
) {
  let totalRating = 0;
  let count = 0;

  for (const b of completedBookings) {
    if (Math.random() < 0.22) continue; // ~78% оставляют отзыв

    const rating = weightedRating();
    const text = reviewText(rating);

    await prisma.review.create({
      data: {
        bookingId: b.id,
        clientId:  b.clientId,
        masterId,
        rating,
        text,
        createdAt: new Date(b.startsAt.getTime() + rInt(30, 120) * 60000),
      },
    });

    totalRating += rating;
    count++;
  }

  if (count > 0) {
    const avg = Math.round((totalRating / count) * 10) / 10;
    await prisma.masterProfile.update({
      where: { id: masterId },
      data: { rating: avg, reviewCount: count },
    });
  }
}

// ─── Main ─────────────────────────────────────────────────────────────────────

async function main() {
  console.log('🌱 Miraku seed — старт');

  // ── Service templates ──────────────────────────────────────────────────────
  const existingTpls = await prisma.serviceTemplate.count();
  if (existingTpls === 0) {
    await prisma.serviceTemplate.createMany({ data: SERVICE_TEMPLATES });
    console.log(`  ✓ ${SERVICE_TEMPLATES.length} шаблонов услуг`);
  } else {
    console.log(`  ↷ шаблоны уже есть (${existingTpls})`);
  }

  // ── Client users ───────────────────────────────────────────────────────────
  const clientIds: Array<{ id: string; name: string }> = [];
  for (const c of CLIENTS) {
    const user = await prisma.user.upsert({
      where:  { phone: c.phone },
      update: { name: c.name, avatarUrl: c.avatarUrl },
      create: { phone: c.phone, name: c.name, avatarUrl: c.avatarUrl },
    });
    clientIds.push({ id: user.id, name: user.name });
  }
  console.log(`  ✓ ${clientIds.length} клиентов`);

  // ── Masters ────────────────────────────────────────────────────────────────
  for (const m of MASTERS) {
    const user = await prisma.user.upsert({
      where:  { phone: m.phone },
      update: { name: m.name, avatarUrl: m.avatarUrl },
      create: { phone: m.phone, name: m.name, avatarUrl: m.avatarUrl },
    });

    // Проверяем, есть ли уже профиль
    const existing = await prisma.masterProfile.findUnique({ where: { userId: user.id } });
    if (existing) {
      // Если нет записей — добавляем
      const bookingCount = await prisma.booking.count({ where: { masterId: existing.id } });
      if (bookingCount === 0) {
        console.log(`  + записи для ${m.name}...`);
        const services = await prisma.service.findMany({ where: { masterId: existing.id } });
        const completed = await seedBookingsForMaster(existing.id, services, clientIds, m.completedCount);
        await seedReviewsForMaster(existing.id, completed);
      } else {
        console.log(`  ↷ ${m.name} — уже есть данные`);
      }
      continue;
    }

    const master = await prisma.masterProfile.create({
      data: {
        userId:             user.id,
        bio:                m.bio,
        address:            m.address,
        lat:                m.lat,
        lng:                m.lng,
        username:           m.username,
        bookingSlug:        m.bookingSlug,
        isBookingLinkActive:true,
        status:             MasterStatus.APPROVED,
        isVerified:         true,
        isVisible:          true,
        isActive:           true,
        verifiedAt:         new Date(),
        specializations: {
          create: m.specs.map(category => ({ category })),
        },
        services: {
          create: m.services,
        },
      },
    });

    // PostGIS location (опционально — если расширение установлено)
    try {
      await prisma.$executeRaw`
        UPDATE master_profiles
        SET location = ST_SetSRID(ST_MakePoint(${m.lng}, ${m.lat}), 4326)::geography
        WHERE id = ${master.id}
      `;
    } catch {
      // PostGIS недоступен — lat/lng уже сохранены в основных полях
    }

    // Portfolio photos
    await prisma.portfolioPhoto.createMany({
      data: m.photos.map((url, idx) => ({
        masterId:  master.id,
        url,
        isCover:   idx === 0,
        sortOrder: idx,
      })),
    });

    // Schedule
    await prisma.schedule.createMany({
      data: m.schedule.map(s => ({
        masterId:  master.id,
        dayOfWeek: s.dayOfWeek,
        startTime: s.startTime,
        endTime:   s.endTime,
        isDayOff:  s.isDayOff,
      })),
    });

    // Visibility (active for 3 months)
    const now = new Date();
    const endsAt = new Date(now);
    endsAt.setDate(endsAt.getDate() + 90);
    await prisma.masterVisibility.create({
      data: {
        masterId:    master.id,
        packageType: 'MONTH',
        paidAmount:  2990,
        startsAt:    now,
        endsAt,
        isActive:    true,
      },
    });

    // Bookings + reviews
    const services = await prisma.service.findMany({ where: { masterId: master.id } });
    const completed = await seedBookingsForMaster(master.id, services, clientIds, m.completedCount);
    await seedReviewsForMaster(master.id, completed);

    const bookingTotal = await prisma.booking.count({ where: { masterId: master.id } });
    const rev = await prisma.masterProfile.findUnique({ where: { id: master.id }, select: { rating: true, reviewCount: true } });
    console.log(`  ✓ ${m.name} — ${m.photos.length} фото, ${bookingTotal} записей, рейтинг ${rev?.rating ?? '—'} (${rev?.reviewCount} отзывов)`);
  }

  const totalMasters = await prisma.masterProfile.count({ where: { status: MasterStatus.APPROVED } });
  const totalBookings = await prisma.booking.count();
  const totalReviews = await prisma.review.count();
  console.log(`\n✅ Готово: ${totalMasters} мастеров, ${totalBookings} записей, ${totalReviews} отзывов`);
}

main()
  .catch(e => { console.error(e); process.exit(1); })
  .finally(() => prisma.$disconnect());
