'use client';

import { useParams, useRouter } from 'next/navigation';
import { useEffect, useState } from 'react';
import { getMasterProfile, getMasterSlots, sendOtpPwa, createBooking } from '@/lib/api';
import type { Service, SlotsResult } from '@/lib/api';

type Step = 'service' | 'datetime' | 'contact' | 'otp';

const TODAY = new Date().toISOString().split('T')[0];

export default function BookPage() {
  const { username } = useParams<{ username: string }>();
  const router = useRouter();

  const [services, setServices] = useState<Service[]>([]);
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
    getMasterProfile(username).then((m) => setServices(m.services)).catch(() => {});
  }, [username]);

  useEffect(() => {
    if (!selectedService || !selectedDate) return;
    setSlotsLoading(true);
    getSlotsForDate(selectedDate);
  }, [selectedService, selectedDate]);

  async function getSlotsForDate(date: string) {
    if (!selectedService) return;
    setSlotsLoading(true);
    setSelectedTime('');
    try {
      const result = await getMasterSlots(username, selectedService.id, date);
      setSlotsResult(result);
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
      await sendOtpPwa(username, phone);
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
      const result = await createBooking(username, {
        name,
        phone,
        otpCode,
        serviceId: selectedService.id,
        date: selectedDate,
        time: selectedTime,
      });
      router.push(
        `/p/${username}/success?masterName=${encodeURIComponent(result.masterName)}&service=${encodeURIComponent(result.service)}&startsAt=${encodeURIComponent(result.startsAt)}`,
      );
    } catch (e: unknown) {
      setError(e instanceof Error ? e.message : 'Ошибка создания записи');
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="px-4 py-6 pb-10">
      {/* Шаг 1: выбор услуги */}
      {step === 'service' && (
        <>
          <h1 className="text-xl font-bold mb-4">Выберите услугу</h1>
          <div className="space-y-2">
            {services.map((s) => (
              <button
                key={s.id}
                onClick={() => { setSelectedService(s); setStep('datetime'); }}
                className="w-full text-left flex justify-between items-center p-4 bg-white rounded-2xl border border-gray-200 hover:border-brand transition-colors"
              >
                <div>
                  <p className="font-medium text-gray-800">{s.title}</p>
                  <p className="text-xs text-gray-400">{s.durationMin} мин</p>
                </div>
                <span className="font-semibold text-gray-900 text-sm">от {s.priceFrom.toLocaleString('ru')} ₸</span>
              </button>
            ))}
          </div>
        </>
      )}

      {/* Шаг 2: дата и время */}
      {step === 'datetime' && selectedService && (
        <>
          <button onClick={() => setStep('service')} className="text-brand text-sm mb-4">← Назад</button>
          <h1 className="text-xl font-bold mb-1">{selectedService.title}</h1>
          <p className="text-sm text-gray-400 mb-4">{selectedService.durationMin} мин · от {selectedService.priceFrom.toLocaleString('ru')} ₸</p>

          <label className="block text-sm font-medium text-gray-700 mb-1">Дата</label>
          <input
            type="date"
            min={TODAY}
            value={selectedDate}
            onChange={(e) => setSelectedDate(e.target.value)}
            className="w-full border border-gray-200 rounded-xl px-4 py-3 mb-4 text-gray-800 focus:outline-none focus:border-brand"
          />

          {slotsLoading && <p className="text-sm text-gray-400">Загружаем слоты...</p>}

          {slotsResult && !slotsLoading && (
            slotsResult.isDayOff ? (
              <p className="text-sm text-red-500">Выходной день — выберите другую дату</p>
            ) : slotsResult.slots.length === 0 ? (
              <p className="text-sm text-gray-500">Нет свободного времени на эту дату</p>
            ) : (
              <>
                <p className="text-sm font-medium text-gray-700 mb-2">Время</p>
                <div className="grid grid-cols-4 gap-2">
                  {slotsResult.slots.map((t) => (
                    <button
                      key={t}
                      onClick={() => setSelectedTime(t)}
                      className={`py-2 rounded-xl text-sm font-medium transition-colors ${
                        selectedTime === t
                          ? 'bg-brand text-white'
                          : 'bg-gray-100 text-gray-700 hover:bg-pink-50'
                      }`}
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
              className="mt-6 w-full bg-brand text-white font-semibold py-3.5 rounded-2xl"
            >
              Продолжить
            </button>
          )}
        </>
      )}

      {/* Шаг 3: контактные данные */}
      {(step === 'contact' || step === 'otp') && (
        <>
          <button onClick={() => setStep('datetime')} className="text-brand text-sm mb-4">← Назад</button>
          <h1 className="text-xl font-bold mb-1">Ваши данные</h1>
          <p className="text-sm text-gray-400 mb-4">
            {selectedService?.title} · {selectedDate} в {selectedTime}
          </p>

          <div className="space-y-3">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Имя</label>
              <input
                type="text"
                value={name}
                onChange={(e) => setName(e.target.value)}
                placeholder="Ваше имя"
                disabled={otpSent}
                className="w-full border border-gray-200 rounded-xl px-4 py-3 focus:outline-none focus:border-brand disabled:bg-gray-50"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-1">Телефон</label>
              <input
                type="tel"
                value={phone}
                onChange={(e) => setPhone(e.target.value)}
                placeholder="+7 (777) 123-45-67"
                disabled={otpSent}
                className="w-full border border-gray-200 rounded-xl px-4 py-3 focus:outline-none focus:border-brand disabled:bg-gray-50"
              />
            </div>

            {step === 'otp' && (
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-1">Код из SMS</label>
                <input
                  type="text"
                  inputMode="numeric"
                  maxLength={4}
                  value={otpCode}
                  onChange={(e) => setOtpCode(e.target.value)}
                  placeholder="• • • •"
                  className="w-full border border-gray-200 rounded-xl px-4 py-3 text-center text-2xl tracking-widest focus:outline-none focus:border-brand"
                />
              </div>
            )}
          </div>

          {error && <p className="mt-3 text-sm text-red-500">{error}</p>}

          <div className="mt-6 space-y-3">
            {step === 'contact' && (
              <button
                onClick={handleSendOtp}
                disabled={loading || !name.trim() || !phone.trim()}
                className="w-full bg-brand text-white font-semibold py-3.5 rounded-2xl disabled:opacity-50"
              >
                {loading ? 'Отправляем...' : 'Получить код'}
              </button>
            )}
            {step === 'otp' && (
              <>
                <button
                  onClick={handleBook}
                  disabled={loading || otpCode.length < 4}
                  className="w-full bg-brand text-white font-semibold py-3.5 rounded-2xl disabled:opacity-50"
                >
                  {loading ? 'Записываем...' : 'Подтвердить запись'}
                </button>
                <button
                  onClick={() => { setOtpSent(false); setStep('contact'); setOtpCode(''); }}
                  className="w-full text-brand text-sm py-2"
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
