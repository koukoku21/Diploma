import { Controller, Get, Param, Query, UseGuards } from '@nestjs/common';
import { SlotsService } from './slots.service';
import { SlotsQueryDto } from './dto/slots-query.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';

@UseGuards(JwtAuthGuard)
@Controller('masters/:masterId/slots')
export class SlotsController {
  constructor(private slots: SlotsService) {}

  // C-4: Выбор даты и времени
  // GET /api/v1/masters/:masterId/slots?date=2026-03-25&serviceId=xxx
  @Get()
  getSlots(
    @Param('masterId') masterId: string,
    @Query() query: SlotsQueryDto,
  ) {
    return this.slots.getSlots(masterId, query);
  }
}
