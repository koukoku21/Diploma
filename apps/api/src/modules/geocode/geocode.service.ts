import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

export interface GeoSuggestion {
  name: string;
  fullName: string;
  lat: number;
  lng: number;
}

@Injectable()
export class GeocodeService {
  private readonly logger = new Logger(GeocodeService.name);
  private readonly apiKey: string;

  constructor(config: ConfigService) {
    this.apiKey = config.get('TWOGIS_API_KEY', '');
  }

  async suggest(q: string): Promise<GeoSuggestion[]> {
    if (!q || q.length < 3) return [];

    // Пробуем 2GIS Geocoder API (более точный для адресов)
    const results = await this.fetchFrom2gis(q);
    if (results.length > 0) return results;

    // Fallback: Nominatim (OpenStreetMap) — если 2GIS недоступен
    return this.fetchFromNominatim(q);
  }

  private async fetchFrom2gis(q: string): Promise<GeoSuggestion[]> {
    if (!this.apiKey) return [];

    // Suggest API лучше подходит для автодополнения — принимает свободный ввод
    const query = q.toLowerCase().includes('астана') ? q : `Астана, ${q}`;

    const url = new URL('https://catalog.api.2gis.com/3.0/suggests');
    url.searchParams.set('key', this.apiKey);
    url.searchParams.set('q', query);
    url.searchParams.set('fields', 'items.point');
    url.searchParams.set('locale', 'ru_RU');
    url.searchParams.set('type', 'building,street,attraction,crossroad');

    try {
      const res = await fetch(url.toString(), { signal: AbortSignal.timeout(4000) });
      if (!res.ok) {
        this.logger.warn(`2GIS suggests returned ${res.status}`);
        return [];
      }

      const data = (await res.json()) as any;
      const items: any[] = data?.result?.items ?? [];

      return items
        .filter((item) => item.point?.lat && item.point?.lon)
        .slice(0, 7)
        .map((item) => {
          const fullName: string = item.full_name ?? item.name ?? '';
          const name = item.name ?? fullName.replace(/^Астана,\s*/i, '');
          return { name, fullName, lat: item.point.lat, lng: item.point.lon };
        });
    } catch (err) {
      this.logger.warn(`2GIS unavailable, falling back to Nominatim: ${err}`);
      return [];
    }
  }

  private async fetchFromNominatim(q: string): Promise<GeoSuggestion[]> {
    const url = new URL('https://nominatim.openstreetmap.org/search');
    url.searchParams.set('q', q);
    url.searchParams.set('format', 'json');
    url.searchParams.set('limit', '7');
    url.searchParams.set('accept-language', 'ru');
    url.searchParams.set('countrycodes', 'kz');
    // Приоритет Астане (lon_min,lat_min,lon_max,lat_max)
    url.searchParams.set('viewbox', '70.8,50.8,72.2,51.5');
    url.searchParams.set('bounded', '0');

    try {
      const res = await fetch(url.toString(), {
        headers: { 'User-Agent': 'Miraku/1.0 (beauty-app)' },
        signal: AbortSignal.timeout(3000),
      });
      if (!res.ok) return [];

      const items = (await res.json()) as any[];
      return items.map((item) => {
        const parts = (item.display_name as string).split(', ');
        return {
          name:     parts.slice(0, 2).join(', '),
          fullName: item.display_name as string,
          lat:      parseFloat(item.lat),
          lng:      parseFloat(item.lon),
        };
      });
    } catch {
      return [];
    }
  }
}
