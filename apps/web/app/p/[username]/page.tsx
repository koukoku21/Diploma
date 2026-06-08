import type { Metadata } from 'next';
import Image from 'next/image';
import Link from 'next/link';
import { notFound } from 'next/navigation';
import { getMasterProfile } from '@/lib/api';

const CATEGORY_LABELS: Record<string, string> = {
  MANICURE: 'Маникюр', PEDICURE: 'Педикюр', HAIRCUT: 'Стрижка',
  COLORING: 'Окрашивание', MAKEUP: 'Макияж', LASHES: 'Ресницы',
  BROWS: 'Брови', SKINCARE: 'Уход за кожей', OTHER: 'Другое',
};

export async function generateMetadata({
  params,
}: {
  params: { username: string };
}): Promise<Metadata> {
  try {
    const master = await getMasterProfile(params.username);
    const specs = master.specializations.map((s) => CATEGORY_LABELS[s.category]).join(', ');
    return {
      title: `${master.user.name} — ${specs} | Miraku`,
      description: `Записаться к мастеру ${master.user.name} в Астане. ${specs}. Быстрая запись без приложения.`,
      openGraph: {
        title: master.user.name,
        description: specs,
        images: master.portfolioPhotos.find((p) => p.isCover)?.url
          ? [{ url: master.portfolioPhotos.find((p) => p.isCover)!.url }]
          : [],
      },
    };
  } catch {
    return { title: 'Мастер | Miraku' };
  }
}

export default async function MasterProfilePage({
  params,
}: {
  params: { username: string };
}) {
  let master;
  try {
    master = await getMasterProfile(params.username);
  } catch {
    notFound();
  }

  const coverPhoto = master.portfolioPhotos.find((p) => p.isCover);
  const specs = master.specializations.map((s) => CATEGORY_LABELS[s.category]).join(' · ');

  return (
    <div className="pb-28">
      {/* Обложка */}
      <div className="relative h-64 bg-bg-tertiary">
        {coverPhoto ? (
          <Image src={coverPhoto.url} alt={master.user.name} fill className="object-cover" />
        ) : (
          <div className="w-full h-full bg-gradient-to-br from-bg-secondary to-bg-tertiary" />
        )}
        {/* Затемнение снизу */}
        <div className="absolute inset-0 bg-gradient-to-t from-bg-primary via-transparent to-transparent" />
      </div>

      {/* Основная инфо */}
      <div className="px-4 -mt-10 relative z-10">
        <div className="flex items-end gap-4 mb-4">
          {master.user.avatarUrl ? (
            <Image
              src={master.user.avatarUrl}
              alt={master.user.name}
              width={80}
              height={80}
              className="rounded-full object-cover shrink-0 border-2 border-brand shadow-lg"
              style={{ borderColor: '#c9a96e' }}
            />
          ) : (
            <div className="w-20 h-20 rounded-full bg-bg-tertiary flex items-center justify-center shrink-0 border-2 text-3xl"
              style={{ borderColor: '#c9a96e33' }}>
              ✦
            </div>
          )}
          <div className="pb-1">
            <h1 className="font-display text-xl font-semibold text-text-primary">{master.user.name}</h1>
            <p className="text-sm text-text-secondary mt-0.5">{specs}</p>
          </div>
        </div>

        {/* Рейтинг и адрес */}
        {(master.rating || master.address) && (
          <div className="flex flex-wrap gap-3 mb-5">
            {master.rating && (
              <div className="flex items-center gap-1.5 bg-bg-secondary rounded-full px-3 py-1.5 border"
                style={{ borderColor: '#c9a96e22' }}>
                <span className="text-brand text-sm">★</span>
                <span className="text-text-primary text-sm font-medium">{master.rating.toFixed(1)}</span>
                <span className="text-text-secondary text-xs">({master.reviewCount})</span>
              </div>
            )}
            {master.address && (
              <div className="flex items-center gap-1.5 bg-bg-secondary rounded-full px-3 py-1.5 border"
                style={{ borderColor: '#c9a96e22' }}>
                <span className="text-brand text-xs">◎</span>
                <span className="text-text-secondary text-xs">{master.address}</span>
              </div>
            )}
          </div>
        )}

        {/* Разделитель */}
        <div className="h-px bg-bg-tertiary mb-5" style={{ background: 'rgba(201,169,110,0.1)' }} />

        {/* Услуги */}
        <h2 className="font-display text-base font-semibold text-text-primary mb-3">Услуги</h2>
        {master.services.length === 0 ? (
          <p className="text-text-secondary text-sm">Услуги не добавлены</p>
        ) : (
          <div className="space-y-2">
            {master.services.map((s) => (
              <div key={s.id}
                className="flex justify-between items-center py-3.5 px-4 rounded-2xl border"
                style={{ background: '#111118', borderColor: 'rgba(201,169,110,0.12)' }}>
                <div>
                  <p className="font-medium text-text-primary text-sm">{s.title}</p>
                  <p className="text-xs text-text-secondary mt-0.5">{s.durationMin} мин</p>
                </div>
                <span className="font-semibold text-brand text-sm">от {s.priceFrom.toLocaleString('ru')} ₸</span>
              </div>
            ))}
          </div>
        )}

        {/* Отзывы */}
        {master.reviews.length > 0 && (
          <>
            <div className="h-px my-5" style={{ background: 'rgba(201,169,110,0.1)' }} />
            <h2 className="font-display text-base font-semibold text-text-primary mb-3">Отзывы</h2>
            <div className="space-y-3">
              {master.reviews.map((r) => (
                <div key={r.id}
                  className="rounded-2xl p-4 border"
                  style={{ background: '#111118', borderColor: 'rgba(201,169,110,0.12)' }}>
                  <div className="flex items-center gap-2 mb-1.5">
                    <span className="text-sm font-medium text-text-primary">{r.client.name}</span>
                    <span className="text-brand text-xs">{'★'.repeat(r.rating)}</span>
                  </div>
                  {r.text && <p className="text-sm text-text-secondary leading-relaxed">{r.text}</p>}
                </div>
              ))}
            </div>
          </>
        )}
      </div>

      {/* Кнопка «Записаться» — фиксированная внизу */}
      <div className="fixed bottom-0 left-0 right-0 max-w-md mx-auto px-4 pb-6 pt-3"
        style={{ background: 'linear-gradient(to top, #0a0a0f 60%, transparent)' }}>
        {master.bookingDisabled ? (
          <p className="text-center text-sm text-text-secondary py-3">
            Мастер временно не принимает записи по ссылке
          </p>
        ) : (
          <Link
            href={`/p/${params.username}/book`}
            className="block w-full text-center font-semibold py-4 rounded-pill transition-opacity active:opacity-80"
            style={{ background: '#c9a96e', color: '#0a0a0f', borderRadius: '100px' }}
          >
            Записаться
          </Link>
        )}
      </div>
    </div>
  );
}
