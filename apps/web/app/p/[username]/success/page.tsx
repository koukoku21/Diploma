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
    <div className="min-h-screen flex flex-col items-center justify-between px-4 py-10"
      style={{ background: '#0a0a0f' }}>
      <div className="flex-1 flex flex-col items-center justify-center text-center w-full">
        {/* Иконка успеха */}
        <div className="w-20 h-20 rounded-full flex items-center justify-center mb-6"
          style={{ background: 'rgba(201,169,110,0.12)', border: '1.5px solid rgba(201,169,110,0.4)' }}>
          <svg className="w-9 h-9" fill="none" viewBox="0 0 24 24" stroke="#c9a96e" strokeWidth={2}>
            <path strokeLinecap="round" strokeLinejoin="round" d="M5 13l4 4L19 7" />
          </svg>
        </div>

        <h1 className="font-display text-2xl font-semibold text-text-primary mb-2">
          Запись подтверждена
        </h1>

        {masterName && (
          <p className="text-text-secondary mb-5 text-sm">
            Вы записаны к <span className="text-text-primary font-medium">{masterName}</span>
          </p>
        )}

        {(service || formattedDate) && (
          <div className="rounded-2xl p-5 w-full max-w-xs mb-6 text-left space-y-4 border"
            style={{ background: '#111118', borderColor: 'rgba(201,169,110,0.15)' }}>
            {service && (
              <div>
                <p className="text-xs text-text-secondary uppercase tracking-wider mb-1">Услуга</p>
                <p className="font-medium text-text-primary text-sm">{service}</p>
              </div>
            )}
            {formattedDate && (
              <div>
                <p className="text-xs text-text-secondary uppercase tracking-wider mb-1">Дата и время</p>
                <p className="font-medium text-brand text-sm">{formattedDate}</p>
              </div>
            )}
          </div>
        )}

        <p className="text-xs text-text-secondary">
          Мастер получил уведомление о вашей записи
        </p>
      </div>

      {/* Баннер «Скачай Miraku» */}
      <div className="w-full rounded-3xl p-5 border"
        style={{ background: '#111118', borderColor: 'rgba(201,169,110,0.2)' }}>
        <div className="flex items-center gap-2 mb-1">
          <span className="text-brand text-lg">✦</span>
          <p className="font-display font-semibold text-text-primary">Miraku</p>
        </div>
        <p className="text-text-secondary text-sm mb-4">
          Управляй записями и общайся с мастером в приложении
        </p>
        <div className="flex gap-2">
          <a
            href="https://apps.apple.com"
            className="flex-1 text-center text-sm font-semibold py-3 rounded-2xl transition-opacity active:opacity-80"
            style={{ background: '#c9a96e', color: '#0a0a0f' }}
          >
            App Store
          </a>
          <a
            href="https://play.google.com"
            className="flex-1 text-center text-sm font-semibold py-3 rounded-2xl border transition-opacity active:opacity-80"
            style={{ background: 'transparent', color: '#c9a96e', borderColor: 'rgba(201,169,110,0.4)' }}
          >
            Google Play
          </a>
        </div>
      </div>

      <Link
        href={`/p/${params.username}`}
        className="mt-4 text-sm text-text-secondary"
      >
        Вернуться к профилю мастера
      </Link>
    </div>
  );
}
