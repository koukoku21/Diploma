import { PrismaClient, MasterStatus, ServiceCategory } from '@prisma/client';

const prisma = new PrismaClient();

// Unsplash — beauty-related photos (stable, free, no auth needed)
const PORTFOLIO = {
  manicure: [
    'https://images.unsplash.com/photo-1604654894610-df63bc536371?w=600&h=600&fit=crop',
    'https://images.unsplash.com/photo-1604654894607-7d3e9756f3b3?w=600&h=600&fit=crop',
    'https://images.unsplash.com/photo-1604654894604-f46f18fc6fd3?w=600&h=600&fit=crop',
    'https://images.unsplash.com/photo-1604654894601-4b9dd1b6a9e1?w=600&h=600&fit=crop',
    'https://images.unsplash.com/photo-1604654894598-a5a7c8a7b6e1?w=600&h=600&fit=crop',
  ],
  hair: [
    'https://images.unsplash.com/photo-1560869713-7d0a29430803?w=600&h=600&fit=crop',
    'https://images.unsplash.com/photo-1522337360788-8b13dee7a37e?w=600&h=600&fit=crop',
    'https://images.unsplash.com/photo-1595476108010-b4d1f102b1b1?w=600&h=600&fit=crop',
    'https://images.unsplash.com/photo-1562322140-8baeececf3df?w=600&h=600&fit=crop',
    'https://images.unsplash.com/photo-1500840216050-6ffa99d75160?w=600&h=600&fit=crop',
  ],
  makeup: [
    'https://images.unsplash.com/photo-1487412947147-5cebf100ffc2?w=600&h=600&fit=crop',
    'https://images.unsplash.com/photo-1512496015851-a90fb38ba796?w=600&h=600&fit=crop',
    'https://images.unsplash.com/photo-1503236823255-94609f598e71?w=600&h=600&fit=crop',
    'https://images.unsplash.com/photo-1526045612212-70caf35c14df?w=600&h=600&fit=crop',
    'https://images.unsplash.com/photo-1583241800698-e8ab01830a22?w=600&h=600&fit=crop',
  ],
  skincare: [
    'https://images.unsplash.com/photo-1598440947619-2c35fc9aa908?w=600&h=600&fit=crop',
    'https://images.unsplash.com/photo-1570172619644-dfd03ed5d881?w=600&h=600&fit=crop',
    'https://images.unsplash.com/photo-1556228578-8c89e6adf883?w=600&h=600&fit=crop',
    'https://images.unsplash.com/photo-1620916566398-39f1143ab7be?w=600&h=600&fit=crop',
    'https://images.unsplash.com/photo-1616394584738-fc6e612e71b9?w=600&h=600&fit=crop',
  ],
};

// pravatar.cc — стабильные женские аватары по ID
const AVATARS = [
  'https://i.pravatar.cc/300?img=47',
  'https://i.pravatar.cc/300?img=49',
  'https://i.pravatar.cc/300?img=44',
  'https://i.pravatar.cc/300?img=48',
  'https://i.pravatar.cc/300?img=45',
];

const MASTERS = [
  {
    phone: '+77001110001',
    name: 'Айгерим Сейткали',
    avatarUrl: AVATARS[0],
    bio: 'Мастер маникюра с 5-летним опытом. Работаю в центре Астаны. Специализируюсь на дизайне и гель-лаке.',
    address: 'ул. Кенесары 40, Астана',
    lat: 51.1801, lng: 71.4460,
    specs: [ServiceCategory.MANICURE, ServiceCategory.PEDICURE],
    photos: PORTFOLIO.manicure,
    services: [
      { title: 'Маникюр классический',       category: ServiceCategory.MANICURE,  priceFrom: 5000,  durationMin: 60 },
      { title: 'Маникюр + гель-лак',         category: ServiceCategory.MANICURE,  priceFrom: 8000,  durationMin: 90 },
      { title: 'Педикюр классический',       category: ServiceCategory.PEDICURE,  priceFrom: 7000,  durationMin: 90 },
      { title: 'Педикюр + гель-лак',         category: ServiceCategory.PEDICURE,  priceFrom: 10000, durationMin: 120 },
    ],
  },
  {
    phone: '+77001110002',
    name: 'Дана Бекова',
    avatarUrl: AVATARS[1],
    bio: 'Колорист и стилист. Специализируюсь на окрашивании, стрижках и уходе за волосами.',
    address: 'пр. Республики 15, Астана',
    lat: 51.1694, lng: 71.4491,
    specs: [ServiceCategory.HAIRCUT, ServiceCategory.COLORING],
    photos: PORTFOLIO.hair,
    services: [
      { title: 'Женская стрижка',              category: ServiceCategory.HAIRCUT,   priceFrom: 8000,  durationMin: 60 },
      { title: 'Мужская стрижка',              category: ServiceCategory.HAIRCUT,   priceFrom: 4000,  durationMin: 30 },
      { title: 'Окрашивание (корни)',          category: ServiceCategory.COLORING,  priceFrom: 12000, durationMin: 120 },
      { title: 'Окрашивание (вся длина)',      category: ServiceCategory.COLORING,  priceFrom: 20000, durationMin: 180 },
    ],
  },
  {
    phone: '+77001110003',
    name: 'Гульнур Ахметова',
    avatarUrl: AVATARS[2],
    bio: 'Визажист с 7 годами опыта. Свадебный и вечерний макияж, коррекция и окраска бровей.',
    address: 'ул. Сейфуллина 12, Астана',
    lat: 51.1850, lng: 71.4380,
    specs: [ServiceCategory.MAKEUP, ServiceCategory.BROWS, ServiceCategory.LASHES],
    photos: PORTFOLIO.makeup,
    services: [
      { title: 'Дневной макияж',                     category: ServiceCategory.MAKEUP,  priceFrom: 10000, durationMin: 60 },
      { title: 'Вечерний макияж',                    category: ServiceCategory.MAKEUP,  priceFrom: 15000, durationMin: 90 },
      { title: 'Свадебный макияж',                   category: ServiceCategory.MAKEUP,  priceFrom: 25000, durationMin: 120 },
      { title: 'Коррекция бровей',                   category: ServiceCategory.BROWS,   priceFrom: 4000,  durationMin: 30 },
      { title: 'Наращивание ресниц (классика)',       category: ServiceCategory.LASHES,  priceFrom: 12000, durationMin: 120 },
    ],
  },
  {
    phone: '+77001110004',
    name: 'Меруерт Джаксыбекова',
    avatarUrl: AVATARS[3],
    bio: 'Косметолог-эстетист. Глубокие чистки, пилинги, уходовые процедуры для всех типов кожи.',
    address: 'ул. Достык 5, Астана',
    lat: 51.1750, lng: 71.4600,
    specs: [ServiceCategory.SKINCARE],
    photos: PORTFOLIO.skincare,
    services: [
      { title: 'Классическая чистка лица',  category: ServiceCategory.SKINCARE, priceFrom: 10000, durationMin: 60 },
      { title: 'Химический пилинг',         category: ServiceCategory.SKINCARE, priceFrom: 14000, durationMin: 60 },
      { title: 'Увлажняющий уход',          category: ServiceCategory.SKINCARE, priceFrom: 8000,  durationMin: 45 },
      { title: 'Биоревитализация',          category: ServiceCategory.SKINCARE, priceFrom: 20000, durationMin: 60 },
    ],
  },
  {
    phone: '+77001110005',
    name: 'Айнур Касымова',
    avatarUrl: AVATARS[4],
    bio: 'Универсальный мастер: маникюр и макияж для любого случая. Работаю с натуральными материалами.',
    address: 'ул. Богенбай батыра 28, Астана',
    lat: 51.1780, lng: 71.4520,
    specs: [ServiceCategory.MANICURE, ServiceCategory.MAKEUP],
    photos: [...PORTFOLIO.manicure.slice(0, 3), ...PORTFOLIO.makeup.slice(0, 2)],
    services: [
      { title: 'Маникюр без покрытия',      category: ServiceCategory.MANICURE, priceFrom: 4000,  durationMin: 45 },
      { title: 'Маникюр гель-лак',          category: ServiceCategory.MANICURE, priceFrom: 7000,  durationMin: 75 },
      { title: 'Макияж (повседневный)',      category: ServiceCategory.MAKEUP,   priceFrom: 8000,  durationMin: 60 },
      { title: 'Макияж (вечерний)',          category: ServiceCategory.MAKEUP,   priceFrom: 12000, durationMin: 90 },
    ],
  },
];

const SERVICE_TEMPLATES = [
  // MANICURE
  { name: 'Маникюр классический',   nameKz: 'Классикалық маникюр',    category: ServiceCategory.MANICURE,  sortOrder: 1 },
  { name: 'Маникюр + гель-лак',     nameKz: 'Маникюр + гель-лак',     category: ServiceCategory.MANICURE,  sortOrder: 2 },
  { name: 'Маникюр без покрытия',   nameKz: 'Жабынсыз маникюр',       category: ServiceCategory.MANICURE,  sortOrder: 3 },
  { name: 'Наращивание ногтей',     nameKz: 'Тырнақ ұзарту',          category: ServiceCategory.MANICURE,  sortOrder: 4 },
  // PEDICURE
  { name: 'Педикюр классический',   nameKz: 'Классикалық педикюр',    category: ServiceCategory.PEDICURE,  sortOrder: 1 },
  { name: 'Педикюр + гель-лак',     nameKz: 'Педикюр + гель-лак',     category: ServiceCategory.PEDICURE,  sortOrder: 2 },
  { name: 'Аппаратный педикюр',     nameKz: 'Аппараттық педикюр',     category: ServiceCategory.PEDICURE,  sortOrder: 3 },
  // HAIRCUT
  { name: 'Женская стрижка',        nameKz: 'Әйелдер шаштарауы',      category: ServiceCategory.HAIRCUT,   sortOrder: 1 },
  { name: 'Мужская стрижка',        nameKz: 'Ерлер шаштарауы',        category: ServiceCategory.HAIRCUT,   sortOrder: 2 },
  { name: 'Детская стрижка',        nameKz: 'Балалар шаштарауы',      category: ServiceCategory.HAIRCUT,   sortOrder: 3 },
  { name: 'Укладка волос',          nameKz: 'Шашты кию',              category: ServiceCategory.HAIRCUT,   sortOrder: 4 },
  // COLORING
  { name: 'Окрашивание (корни)',     nameKz: 'Тамырды бояу',           category: ServiceCategory.COLORING,  sortOrder: 1 },
  { name: 'Окрашивание (вся длина)', nameKz: 'Толық бояу',             category: ServiceCategory.COLORING,  sortOrder: 2 },
  { name: 'Мелирование',            nameKz: 'Мелировка',              category: ServiceCategory.COLORING,  sortOrder: 3 },
  { name: 'Балаяж / омбре',         nameKz: 'Балаяж / омбре',         category: ServiceCategory.COLORING,  sortOrder: 4 },
  // MAKEUP
  { name: 'Макияж дневной',         nameKz: 'Күндізгі макияж',        category: ServiceCategory.MAKEUP,    sortOrder: 1 },
  { name: 'Макияж вечерний',        nameKz: 'Кешкі макияж',           category: ServiceCategory.MAKEUP,    sortOrder: 2 },
  { name: 'Макияж свадебный',       nameKz: 'Үйлену тойы макияжы',    category: ServiceCategory.MAKEUP,    sortOrder: 3 },
  // LASHES
  { name: 'Наращивание ресниц (классика)', nameKz: 'Кірпік ұзарту (классика)', category: ServiceCategory.LASHES, sortOrder: 1 },
  { name: 'Наращивание ресниц (объём)',    nameKz: 'Кірпік ұзарту (көлем)',    category: ServiceCategory.LASHES, sortOrder: 2 },
  { name: 'Ламинирование ресниц',         nameKz: 'Кірпікті ламиниялау',      category: ServiceCategory.LASHES, sortOrder: 3 },
  // BROWS
  { name: 'Коррекция бровей',       nameKz: 'Қас түзеу',              category: ServiceCategory.BROWS,     sortOrder: 1 },
  { name: 'Окрашивание бровей',     nameKz: 'Қасты бояу',             category: ServiceCategory.BROWS,     sortOrder: 2 },
  { name: 'Оформление бровей хной', nameKz: 'Хнамен қас безендіру',   category: ServiceCategory.BROWS,     sortOrder: 3 },
  // SKINCARE
  { name: 'Чистка лица',            nameKz: 'Бет тазалау',            category: ServiceCategory.SKINCARE,  sortOrder: 1 },
  { name: 'Химический пилинг',      nameKz: 'Химиялық пилинг',        category: ServiceCategory.SKINCARE,  sortOrder: 2 },
  { name: 'Увлажняющий уход',       nameKz: 'Ылғалдандыру процедурасы', category: ServiceCategory.SKINCARE, sortOrder: 3 },
  { name: 'Биоревитализация',       nameKz: 'Биоревитализация',       category: ServiceCategory.SKINCARE,  sortOrder: 4 },
  // OTHER
  { name: 'Массаж лица',            nameKz: 'Бет массажы',            category: ServiceCategory.OTHER,     sortOrder: 1 },
  { name: 'Депиляция',              nameKz: 'Депиляция',              category: ServiceCategory.OTHER,     sortOrder: 2 },
];

async function main() {
  console.log('🌱 Seeding masters with photos...');

  // ─── Service Templates ───────────────────────────────────────────
  console.log('📋 Seeding service templates...');
  const existingCount = await prisma.serviceTemplate.count();
  if (existingCount === 0) {
    await prisma.serviceTemplate.createMany({ data: SERVICE_TEMPLATES });
    console.log(`  ✓ Created ${SERVICE_TEMPLATES.length} service templates`);
  } else {
    console.log(`  ↷ ${existingCount} templates already exist`);
  }

  for (let i = 0; i < MASTERS.length; i++) {
    const m = MASTERS[i];

    const user = await prisma.user.upsert({
      where: { phone: m.phone },
      update: { name: m.name, avatarUrl: m.avatarUrl },
      create: { phone: m.phone, name: m.name, avatarUrl: m.avatarUrl },
    });

    const existing = await prisma.masterProfile.findUnique({
      where: { userId: user.id },
    });
    if (existing) {
      console.log(`  ↷ ${m.name} — уже существует, пропускаем`);
      continue;
    }

    const master = await prisma.masterProfile.create({
      data: {
        userId:     user.id,
        bio:        m.bio,
        address:    m.address,
        lat:        m.lat,
        lng:        m.lng,
        status:     MasterStatus.APPROVED,
        isVerified: true,
        isActive:   true,
        verifiedAt: new Date(),
        specializations: {
          create: m.specs.map((category) => ({ category })),
        },
        services: {
          create: m.services,
        },
      },
    });

    // Портфолио — первое фото помечается как обложка
    await prisma.portfolioPhoto.createMany({
      data: m.photos.map((url, idx) => ({
        masterId:  master.id,
        url,
        isCover:   idx === 0,
        sortOrder: idx,
      })),
    });

    // Расписание Пн-Пт 10:00-19:00
    await prisma.schedule.createMany({
      data: [1, 2, 3, 4, 5].map((day) => ({
        masterId:  master.id,
        dayOfWeek: day,
        startTime: '10:00',
        endTime:   '19:00',
        isDayOff:  false,
      })),
    });

    console.log(`  ✓ ${m.name} — ${m.photos.length} фото`);
  }

  console.log('✅ Seed завершён');
}

main()
  .catch((e) => { console.error(e); process.exit(1); })
  .finally(() => prisma.$disconnect());
