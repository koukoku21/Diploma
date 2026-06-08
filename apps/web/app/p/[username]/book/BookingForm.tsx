'use client';

import { useRouter } from 'next/navigation';
import { useEffect, useState } from 'react';
import type { Service, SlotsResult } from '@/lib/api';

type Step = 'service' | 'datetime' | 'contact' | 'otp';

const TODAY = new Date().toISOString().split('T')[0];

const CARD_STYLE = {
  background: '#111118',
  borderColor: 'rgba(201,169,110,0.15)',
};

const INPUT_STYLE = {
  background: '#16161f',
  borderColor: 'rgba(201,169,110,0.2)',
  color: '#f0ede8',
};

export default function BookingForm({
  username,
  services,
}: {
  username: string;
  services: Service[];
}) {
  const router = useRouter();

  const [step, setStep] = useState<Step>('service');
  const [selectedService, setSelectedService] = useState<Service | null>(null);
  const [selectedDate, setSelectedDate] = useState(TODAY);
  const [slotsResult, setSlotsResult] = useState<SlotsResult | null>(null);
  const [slotsLoading, setSlotsLoading] = useState(false);
  const [selectedTime, setSelectedTime] = useState('');

  const [name, setName] = useState('');
  const [phone, setPhone] = useState('');
  const [otpCode, setOtpCode] = useState('');
  const [otpSent, setOtpSent] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    if (!selectedService || !selectedDate) return;
    getSlotsForDate(selectedDate);
  }, [selectedService, selectedDate]);

  async function getSlotsForDate(date: string) {
    if (!selectedService) return;
    setSlotsLoading(true);
    setSelectedTime('');
    try {
      const res = await fetch(`/api/p/${username}/slots?serviceId=${selectedService.id}&date=${date}`);
      const data = await res.json();
      if (!res.ok) throw new Error(data?.message ?? `HTTP ${res.status}`);
      setSlotsResult(data);
    } catch {
      setSlotsResult(null);
    } finally {
      setSlotsLoading(false);
    }
  }

  async function handleSendOtp() {
    if (!phone.match(/^\+?[0-9]{10,15}$/)) {
      setError('Введите корректный номер телефона');
      return;
    }
    setLoading(true);
    setError('');
    try {
      const res = await fetch(`/api/p/${username}/send-otp`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ phone }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data?.message ?? `HTTP ${res.status}`);
      setOtpSent(true);
      setStep('otp');
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Ошибка отправки кода');
    } finally {
      setLoading(false);
    }
  }

  async function handleBook() {
    if (!selectedService || !selectedDate || !selectedTime) return;
    setLoading(true);
    setError('');
    try {
      const res = await fetch(`/api/p/${username}/book`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ name, phone, otpCode, serviceId: selectedService.id, date: selectedDate, time: selectedTime }),
      });
      const result = await res.json();
      if (!res.ok) throw new Error(result?.message ?? `HTTP ${res.status}`);
      router.push(
        `/p/${username}/success?masterName=${encodeURIComponent(result.masterName)}&service=${encodeURIComponent(result.service)}&startsAt=${encodeURIComponent(result.startsAt)}`,
      );
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Ошибка создания записи');
    } finally {
      setLoading(false);
    }
  }

  const stepLabels: Record<Step, string> = {
    service: 'Услуга',
    datetime: 'Дата и время',
    contact: 'Контакты',
    otp: 'Подтверждение',
  };
  const stepOrder: Step[] = ['service', 'datetime', 'contact', 'otp'];
  const currentStepIndex = stepOrder.indexOf(step);

  return (
    <div className="px-4 pt-4 pb-10 min-h-screen" style={{ background: '#0a0a0f' }}>
      <div className="flex items-center gap-3 mb-5">
        {step === 'service' ? (
          <a href={`/p/${username}`} className="text-text-secondary text-sm">← Назад</a>
        ) : (
          <button
            onClick={() => { const prev = stepOrder[currentStepIndex - 1]; if (prev) setStep(prev); }}
            className="text-text-secondary text-sm"
          >
            ← Назад
          </button>
        )}
        <span className="font-display text-base font-semibold text-text-primary">
          {stepLabels[step]}
        </span>
      </div>

      <div className="flex gap-1.5 mb-6">
        {stepOrder.map((s, i) => (
          <div
            key={s}
            className="h-0.5 flex-1 rounded-full transition-all"
            style={{ background: i <= currentStepIndex ? '#c9a96e' : 'rgba(201,169,110,0.2)' }}
          />
        ))}
      </div>

      {step === 'service' && (
        services.length === 0 ? (
          <p className="text-text-secondary text-sm text-center mt-10">Услуги не найдены</p>
        ) : (
          <div className="space-y-2">
            {services.map((s) => (
              <button
                key={s.id}
                onClick={() => { setSelectedService(s); setStep('datetime'); }}
                className="w-full text-left flex justify-between items-center p-4 rounded-2xl border transition-all active:scale-[0.98]"
                style={CARD_STYLE}
              >
                <div>
                  <p className="font-medium text-text-primary text-sm">{s.title}</p>
                  <p className="text-xs text-text-secondary mt-0.5">{s.durationMin} мин</p>
                </div>
                <span className="font-semibold text-brand text-sm ml-3 shrink-0">
                  от {s.priceFrom.toLocaleString('ru')} ₸
                </span>
              </button>
            ))}
          </div>
        )
      )}

      {step === 'datetime' && selectedService && (
        <>
          <div className="rounded-2xl p-4 mb-5 border" style={CARD_STYLE}>
            <p className="font-semibold text-text-primary text-sm">{selectedService.title}</p>
            <p className="text-xs text-text-secondary mt-0.5">
              {selectedService.durationMin} мин · от {selectedService.priceFrom.toLocaleString('ru')} ₸
            </p>
          </div>

          <label className="block text-xs font-medium text-text-secondary mb-2 uppercase tracking-wider">Дата</label>
          <input
            type="date"
            min={TODAY}
            value={selectedDate}
            onChange={(e) => setSelectedDate(e.target.value)}
            className="w-full rounded-2xl px-4 py-3 mb-5 border text-sm focus:outline-none"
            style={INPUT_STYLE}
          />

          {slotsLoading && (
            <div className="grid grid-cols-4 gap-2">
              {[1,2,3,4,5,6,7,8].map((i) => (
                <div key={i} className="h-10 rounded-xl animate-pulse" style={{ background: '#111118' }} />
              ))}
            </div>
          )}

          {slotsResult && !slotsLoading && (
            slotsResult.isDayOff ? (
              <div className="rounded-2xl p-4 text-center border" style={{ background: '#16161f', borderColor: 'rgba(255,80,80,0.2)' }}>
                <p className="text-sm" style={{ color: '#ff6b6b' }}>Выходной день — выберите другую дату</p>
              </div>
            ) : slotsResult.slots.length === 0 ? (
              <div className="rounded-2xl p-4 text-center border" style={CARD_STYLE}>
                <p className="text-sm text-text-secondary">Нет свободного времени на эту дату</p>
              </div>
            ) : (
              <>
                <label className="block text-xs font-medium text-text-secondary mb-2 uppercase tracking-wider">Время</label>
                <div className="grid grid-cols-4 gap-2">
                  {slotsResult.slots.map((t) => (
                    <button
                      key={t}
                      onClick={() => setSelectedTime(t)}
                      className="py-2.5 rounded-xl text-sm font-medium transition-all active:scale-95"
                      style={
                        selectedTime === t
                          ? { background: '#c9a96e', color: '#0a0a0f' }
                          : { background: '#111118', color: '#9b9690', border: '1px solid rgba(201,169,110,0.15)' }
                      }
                    >
                      {t}
                    </button>
                  ))}
                </div>
              </>
            )
          )}

          {selectedTime && (
            <button
              onClick={() => setStep('contact')}
              className="mt-6 w-full font-semibold py-4 transition-opacity active:opacity-80"
              style={{ background: '#c9a96e', color: '#0a0a0f', borderRadius: '100px' }}
            >
              Продолжить
            </button>
          )}
        </>
      )}

      {(step === 'contact' || step === 'otp') && (
        <>
          <div className="rounded-2xl p-4 mb-5 border" style={CARD_STYLE}>
            <p className="text-text-secondary text-xs mb-1">{selectedService?.title}</p>
            <p className="text-text-primary text-sm font-medium">
              {selectedDate} · {selectedTime}
            </p>
          </div>

          <div className="space-y-4">
            <div>
              <label className="block text-xs font-medium text-text-secondary mb-2 uppercase tracking-wider">Имя</label>
              <input
                type="text"
                value={name}
                onChange={(e) => setName(e.target.value)}
                placeholder="Ваше имя"
                disabled={otpSent}
                className="w-full rounded-2xl px-4 py-3 border text-sm focus:outline-none disabled:opacity-50"
                style={INPUT_STYLE}
              />
            </div>
            <div>
              <label className="block text-xs font-medium text-text-secondary mb-2 uppercase tracking-wider">Телефон</label>
              <input
                type="tel"
                value={phone}
                onChange={(e) => setPhone(e.target.value)}
                placeholder="+7 (777) 123-45-67"
                disabled={otpSent}
                className="w-full rounded-2xl px-4 py-3 border text-sm focus:outline-none disabled:opacity-50"
                style={INPUT_STYLE}
              />
            </div>

            {step === 'otp' && (
              <div>
                <label className="block text-xs font-medium text-text-secondary mb-2 uppercase tracking-wider">
                  Код из SMS
                </label>
                <input
                  type="text"
                  inputMode="numeric"
                  maxLength={4}
                  value={otpCode}
                  onChange={(e) => setOtpCode(e.target.value)}
                  placeholder="• • • •"
                  className="w-full rounded-2xl px-4 py-4 border text-center text-2xl tracking-[0.5em] focus:outline-none"
                  style={{ ...INPUT_STYLE, fontFamily: 'Mulish, sans-serif' }}
                />
                <p className="text-xs text-text-secondary mt-2 text-center">
                  Код отправлен на {phone}
                </p>
              </div>
            )}
          </div>

          {error && (
            <div className="mt-4 rounded-xl p-3 text-sm text-center"
              style={{ background: 'rgba(255,80,80,0.1)', color: '#ff6b6b', border: '1px solid rgba(255,80,80,0.2)' }}>
              {error}
            </div>
          )}

          <div className="mt-6 space-y-3">
            {step === 'contact' && (
              <button
                onClick={handleSendOtp}
                disabled={loading || !name.trim() || !phone.trim()}
                className="w-full font-semibold py-4 transition-opacity active:opacity-80 disabled:opacity-40"
                style={{ background: '#c9a96e', color: '#0a0a0f', borderRadius: '100px' }}
              >
                {loading ? 'Отправляем...' : 'Получить код'}
              </button>
            )}
            {step === 'otp' && (
              <>
                <button
                  onClick={handleBook}
                  disabled={loading || otpCode.length < 4}
                  className="w-full font-semibold py-4 transition-opacity active:opacity-80 disabled:opacity-40"
                  style={{ background: '#c9a96e', color: '#0a0a0f', borderRadius: '100px' }}
                >
                  {loading ? 'Записываем...' : 'Подтвердить запись'}
                </button>
                <button
                  onClick={() => { setOtpSent(false); setStep('contact'); setOtpCode(''); }}
                  className="w-full text-text-secondary text-sm py-2"
                >
                  Изменить номер
                </button>
              </>
            )}
          </div>
        </>
      )}
    </div>
  );
}
