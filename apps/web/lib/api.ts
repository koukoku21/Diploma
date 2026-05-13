const API = process.env.NEXT_PUBLIC_API_URL ?? 'http://localhost:3000';

async function request<T>(path: string, init?: RequestInit): Promise<T> {
  const res = await fetch(`${API}${path}`, {
    headers: { 'Content-Type': 'application/json' },
    ...init,
  });
  if (!res.ok) {
    const body = await res.json().catch(() => ({}));
    throw new Error(body?.message ?? `HTTP ${res.status}`);
  }
  return res.json() as Promise<T>;
}

export interface Service {
  id: string;
  title: string;
  priceFrom: number;
  durationMin: number;
  category: string;
}

export interface MasterProfile {
  id: string;
  username: string;
  isBookingLinkActive: boolean;
  bookingDisabled?: boolean;
  rating: number | null;
  reviewCount: number;
  address: string;
  user: { name: string; avatarUrl: string | null };
  specializations: { category: string }[];
  portfolioPhotos: { url: string; isCover: boolean }[];
  services: Service[];
  reviews: {
    id: string;
    rating: number;
    text: string | null;
    client: { name: string; avatarUrl: string | null };
  }[];
}

export interface SlotsResult {
  date: string;
  slots: string[];
  isDayOff: boolean;
  durationMin: number;
}

export function getMasterProfile(username: string): Promise<MasterProfile> {
  return request<MasterProfile>(`/p/${username}`, { cache: 'no-store' });
}

export function getMasterSlots(username: string, serviceId: string, date: string): Promise<SlotsResult> {
  return request<SlotsResult>(`/p/${username}/slots?serviceId=${serviceId}&date=${date}`);
}

export function sendOtpPwa(username: string, phone: string): Promise<{ message: string }> {
  return request(`/p/${username}/send-otp`, {
    method: 'POST',
    body: JSON.stringify({ phone }),
  });
}

export function createBooking(
  username: string,
  data: { name: string; phone: string; otpCode: string; serviceId: string; date: string; time: string },
): Promise<{ bookingId: string; masterName: string; service: string; startsAt: string }> {
  return request(`/p/${username}/book`, {
    method: 'POST',
    body: JSON.stringify(data),
  });
}

export function resolveSlug(slug: string): Promise<{ username: string }> {
  return request<{ username: string }>(`/p/b/${slug}`);
}
