import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  Query,
  UseGuards,
} from '@nestjs/common';
import { BookingStatus } from '@prisma/client';
import { BookingsService } from './bookings.service';
import { CreateBookingDto } from './dto/create-booking.dto';
import { CancelBookingDto } from './dto/cancel-booking.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';

@UseGuards(JwtAuthGuard)
@Controller('bookings')
export class BookingsController {
  constructor(private bookings: BookingsService) {}

  // C-5: Создать запись
  @Post()
  create(
    @CurrentUser() user: { id: string },
    @Body() dto: CreateBookingDto,
  ) {
    return this.bookings.create(user.id, dto);
  }

  // C-6: Мои записи (как клиент)
  @Get('my')
  listForClient(
    @CurrentUser() user: { id: string },
    @Query('status') status?: BookingStatus,
  ) {
    return this.bookings.listForClient(user.id, status);
  }

  // M-7: Мои записи (как мастер)
  @Get('master')
  listForMaster(
    @CurrentUser() user: { id: string },
    @Query('status') status?: BookingStatus,
  ) {
    return this.bookings.listForMaster(user.id, status);
  }

  // C-6a / M-7: Детали записи
  @Get(':id')
  getOne(
    @CurrentUser() user: { id: string },
    @Param('id') id: string,
  ) {
    return this.bookings.getOne(id, user.id);
  }

  // Отмена (клиент или мастер)
  @Patch(':id/cancel')
  cancel(
    @CurrentUser() user: { id: string },
    @Param('id') id: string,
    @Body() dto: CancelBookingDto,
  ) {
    return this.bookings.cancel(id, user.id, dto);
  }

  // M-7: Мастер завершает запись → открывает отзыв
  @Patch(':id/complete')
  complete(
    @CurrentUser() user: { id: string },
    @Param('id') id: string,
  ) {
    return this.bookings.complete(id, user.id);
  }
}
