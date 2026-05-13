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
    <div className="pb-24">
      {/* Обложка */}
      <div className="relative h-64 bg-gray-200">
        {coverPhoto ? (
          <Image src={coverPhoto.url} alt={master.user.name} fill className="object-cover" />
        ) : (
          <div className="w-full h-full bg-gradient-to-br from-pink-100 to-pink-200" />
        )}
      </div>

      {/* Основная инфо */}
      <div className="px-4 pt-4">
        <div className="flex items-start gap-3">
          {master.user.avatarUrl ? (
            <Image
              src={master.user.avatarUrl}
              alt={master.user.name}
              width={64}
              height={64}
              className="rounded-full object-cover shrink-0 border-2 border-white shadow"
            />
          ) : (
            <div className="w-16 h-16 rounded-full bg-pink-100 flex items-center justify-center shrink-0 text-2xl">
              💅
            </div>
          )}
          <div>
            <h1 className="text-xl font-bold text-gray-900">{master.user.name}</h1>
            <p className="text-sm text-gray-500">{specs}</p>
            {master.rating && (
              <p className="text-sm text-yellow-500 mt-0.5">
                ★ {master.rating.toFixed(1)}
                <span className="text-gray-400 ml-1">({master.reviewCount})</span>
              </p>
            )}
            <p className="text-xs text-gray-400 mt-0.5">{master.address}</p>
          </div>
        </div>

        {/* Услуги */}
        <h2 className="mt-6 mb-3 font-semibold text-gray-800">Услуги</h2>
        {master.services.length === 0 ? (
          <p className="text-gray-400 text-sm">Услуги не добавлены</p>
        ) : (
          <div className="space-y-2">
            {master.services.map((s) => (
              <div key={s.id} className="flex justify-between items-center py-3 border-b border-gray-100">
                <div>
                  <p className="font-medium text-gray-800">{s.title}</p>
                  <p className="text-xs text-gray-400">{s.durationMin} мин</p>
                </div>
                <span className="font-semibold text-gray-900">от {s.priceFrom.toLocaleString('ru')} ₸</span>
              </div>
            ))}
          </div>
        )}

        {/* Отзывы */}
        {master.reviews.length > 0 && (
          <>
            <h2 className="mt-6 mb-3 font-semibold text-gray-800">Отзывы</h2>
            <div className="space-y-3">
              {master.reviews.map((r) => (
                <div key={r.id} className="bg-gray-50 rounded-xl p-3">
                  <div className="flex items-center gap-2 mb-1">
                    <span className="text-sm font-medium text-gray-700">{r.client.name}</span>
                    <span className="text-yellow-500 text-xs">{'★'.repeat(r.rating)}</span>
                  </div>
                  {r.text && <p className="text-sm text-gray-600">{r.text}</p>}
                </div>
              ))}
            </div>
          </>
        )}
      </div>

      {/* Кнопка «Записаться» — фиксированная внизу */}
      {master.bookingDisabled ? (
        <div className="fixed bottom-0 left-0 right-0 max-w-md mx-auto px-4 pb-6 pt-3 bg-white border-t border-gray-100">
          <p className="text-center text-sm text-gray-500">Мастер временно не принимает записи по ссылке</p>
        </div>
      ) : (
        <div className="fixed bottom-0 left-0 right-0 max-w-md mx-auto px-4 pb-6 pt-3 bg-white border-t border-gray-100">
          <Link
            href={`/p/${params.username}/book`}
            className="block w-full text-center bg-brand hover:bg-brand-dark text-white font-semibold py-3.5 rounded-2xl transition-colors"
          >
            Записаться
          </Link>
        </div>
      )}
    </div>
  );
}
