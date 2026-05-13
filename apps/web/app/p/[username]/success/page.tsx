import Link from 'next/link';

export default function SuccessPage({
  params,
  searchParams,
}: {
  params: { username: string };
  searchParams: { masterName?: string; service?: string; startsAt?: string };
}) {
  const { masterName, service, startsAt } = searchParams;

  const formattedDate = startsAt
    ? new Intl.DateTimeFormat('ru-KZ', {
        day: 'numeric',
        month: 'long',
        hour: '2-digit',
        minute: '2-digit',
        timeZone: 'Asia/Almaty',
      }).format(new Date(startsAt))
    : '';

  return (
    <div className="min-h-screen flex flex-col items-center justify-between px-4 py-10">
      <div className="flex-1 flex flex-col items-center justify-center text-center">
        {/* Иконка успеха */}
        <div className="w-20 h-20 rounded-full bg-green-100 flex items-center justify-center mb-6">
          <svg className="w-10 h-10 text-green-500" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
            <path strokeLinecap="round" strokeLinejoin="round" d="M5 13l4 4L19 7" />
          </svg>
        </div>

        <h1 className="text-2xl font-bold text-gray-900 mb-2">Запись подтверждена!</h1>

        {masterName && (
          <p className="text-gray-500 mb-4">
            Вы записаны к <span className="font-medium text-gray-700">{masterName}</span>
          </p>
        )}

        {(service || formattedDate) && (
          <div className="bg-gray-50 rounded-2xl p-5 w-full max-w-xs mb-6 text-left space-y-3">
            {service && (
              <div>
                <p className="text-xs text-gray-400 uppercase tracking-wide">Услуга</p>
                <p className="font-medium text-gray-800">{service}</p>
              </div>
            )}
            {formattedDate && (
              <div>
                <p className="text-xs text-gray-400 uppercase tracking-wide">Дата и время</p>
                <p className="font-medium text-gray-800">{formattedDate}</p>
              </div>
            )}
          </div>
        )}

        <p className="text-sm text-gray-400">
          Мастер получил уведомление о вашей записи
        </p>
      </div>

      {/* Баннер «Скачай Miraku» */}
      <div className="w-full bg-gradient-to-br from-pink-500 to-pink-400 rounded-3xl p-5 text-white">
        <p className="font-bold text-lg mb-1">Скачай приложение Miraku</p>
        <p className="text-pink-100 text-sm mb-4">
          Управляй записями, общайся с мастером и находи новых
        </p>
        <div className="flex gap-2">
          <a
            href="https://apps.apple.com"
            className="flex-1 bg-white text-pink-500 text-center text-sm font-semibold py-2.5 rounded-xl"
          >
            App Store
          </a>
          <a
            href="https://play.google.com"
            className="flex-1 bg-white text-pink-500 text-center text-sm font-semibold py-2.5 rounded-xl"
          >
            Google Play
          </a>
        </div>
      </div>

      {/* Кнопка назад к профилю */}
      <Link
        href={`/p/${params.username}`}
        className="mt-4 text-brand text-sm"
      >
        Вернуться к профилю мастера
      </Link>
    </div>
  );
}
