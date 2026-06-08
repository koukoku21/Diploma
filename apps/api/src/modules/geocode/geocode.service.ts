import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

export interface GeoSuggestion {
  name: string;
  fullName: string;
  lat: number;
  lng: number;
}

const ADMIN_RE = /астана|нур.?султан|целиноград|акмолин|казахстан|область|район|округ|город|district|region/i;

@Injectable()
export class GeocodeService {
  private readonly logger = new Logger(GeocodeService.name);
  private readonly apiKey: string;

  constructor(config: ConfigService) {
    this.apiKey = config.get('TWOGIS_API_KEY', '');
  }

  async suggest(q: string): Promise<GeoSuggestion[]> {
    if (!q || q.length < 3) return [];

    const results = await this.fetchFrom2gis(q);
    if (results.length > 0) return results;

    return this.fetchFromNominatim(q);
  }

  private cleanName(fullName: string): string {
    const parts = fullName.split(', ');
    const meaningful = parts.filter(p => p.trim() && !ADMIN_RE.test(p));
    // Берём максимум улица + номер дома (2 части)
    return meaningful.slice(0, 2).join(', ') || parts[0] || fullName;
  }

  private async fetchFrom2gis(q: string): Promise<GeoSuggestion[]> {
    if (!this.apiKey) return [];

    const query = q.toLowerCase().includes('астана') ? q : `Астана, ${q}`;
    const hasHouseNumber = /\d/.test(q);

    // Если в запросе есть цифры (номер дома) — используем Geocoder, он точнее
    if (hasHouseNumber) {
      return this.fetchFrom2gisGeocode(query);
    }

    return this.fetchFrom2gisSuggest(query);
  }

  private async fetchFrom2gisSuggest(query: string): Promise<GeoSuggestion[]> {
    const url = new URL('https://catalog.api.2gis.com/3.0/suggests');
    url.searchParams.set('key', this.apiKey);
    url.searchParams.set('q', query);
    url.searchParams.set('fields', 'items.point');
    url.searchParams.set('locale', 'ru_RU');
    url.searchParams.set('type', 'street,building');

    try {
      const res = await fetch(url.toString(), { signal: AbortSignal.timeout(4000) });
      if (!res.ok) return [];

      const data = (await res.json()) as any;
      const items: any[] = data?.result?.items ?? [];

      return items
        .filter((item) => item.point?.lat && item.point?.lon)
        .slice(0, 6)
        .map((item) => {
          const raw: string = item.full_name ?? item.name ?? '';
          const name = this.cleanName(raw);
          return { name, fullName: name, lat: item.point.lat, lng: item.point.lon };
        })
        .filter(s => s.name.length > 0);
    } catch (err) {
      this.logger.warn(`2GIS suggest failed: ${err}`);
      return [];
    }
  }

  private async fetchFrom2gisGeocode(query: string): Promise<GeoSuggestion[]> {
    const url = new URL('https://geocode.api.2gis.com/1.0');
    url.searchParams.set('key', this.apiKey);
    url.searchParams.set('q', query);
    url.searchParams.set('fields', 'items.point,items.address');
    url.searchParams.set('locale', 'ru_RU');

    try {
      const res = await fetch(url.toString(), { signal: AbortSignal.timeout(4000) });
      if (!res.ok) return [];

      const data = (await res.json()) as any;
      const items: any[] = data?.result?.items ?? [];

      return items
        .filter((item) => item.point?.lat && item.point?.lon)
        .slice(0, 6)
        .map((item) => {
          // address_name содержит "улица, номер" без административных частей
          const addressName: string = item.address_name ?? item.full_name ?? item.name ?? '';
          const name = this.cleanName(addressName);
          return { name, fullName: name, lat: item.point.lat, lng: item.point.lon };
        })
        .filter(s => s.name.length > 0);
    } catch (err) {
      this.logger.warn(`2GIS geocode failed: ${err}`);
      return [];
    }
  }

  private async fetchFromNominatim(q: string): Promise<GeoSuggestion[]> {
    const url = new URL('https://nominatim.openstreetmap.org/search');
    url.searchParams.set('q', `Астана, ${q}`);
    url.searchParams.set('format', 'json');
    url.searchParams.set('limit', '6');
    url.searchParams.set('accept-language', 'ru');
    url.searchParams.set('countrycodes', 'kz');
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
        const name = this.cleanName(item.display_name as string);
        return { name, fullName: name, lat: parseFloat(item.lat), lng: parseFloat(item.lon) };
      });
    } catch {
      return [];
    }
  }
}
