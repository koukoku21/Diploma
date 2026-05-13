import { Body, Controller, Get, Param, Post, Query, Redirect } from '@nestjs/common';
import { BookingPageService } from './booking-page.service';
import { SendOtpPwaDto } from './dto/send-otp-pwa.dto';
import { BookSlotPwaDto } from './dto/book-slot-pwa.dto';

@Controller('p')
export class BookingPageController {
  constructor(private readonly service: BookingPageService) {}

  // GET /p/b/:slug — резолв короткой ссылки → редирект на /@username
  @Get('b/:slug')
  @Redirect()
  async resolveSlug(@Param('slug') slug: string) {
    const { username } = await this.service.resolveSlug(slug);
    return { url: `/p/${username}`, statusCode: 302 };
  }

  // GET /p/:username — публичный профиль мастера
  @Get(':username')
  getProfile(@Param('username') username: string) {
    return this.service.getProfile(username);
  }

  // GET /p/:username/slots?serviceId=&date=
  @Get(':username/slots')
  getSlots(
    @Param('username') username: string,
    @Query('serviceId') serviceId: string,
    @Query('date') date: string,
  ) {
    return this.service.getSlots(username, serviceId, date);
  }

  // POST /p/:username/send-otp — отправить OTP (до бронирования)
  @Post(':username/send-otp')
  sendOtp(@Param('username') username: string, @Body() dto: SendOtpPwaDto) {
    return this.service.sendOtp(username, dto);
  }

  // POST /p/:username/book — создать запись (с верификацией OTP)
  @Post(':username/book')
  book(@Param('username') username: string, @Body() dto: BookSlotPwaDto) {
    return this.service.bookSlot(username, dto);
  }
}
