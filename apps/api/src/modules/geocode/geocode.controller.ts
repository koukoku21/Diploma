import { Controller, Get, Query } from '@nestjs/common';
import { GeocodeService } from './geocode.service';

@Controller('geocode')
export class GeocodeController {
  constructor(private geocode: GeocodeService) {}

  // GET /geocode/suggest?q=Кенесары
  @Get('suggest')
  suggest(@Query('q') q: string) {
    return this.geocode.suggest(q ?? '');
  }
}
