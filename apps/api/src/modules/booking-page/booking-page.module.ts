import { Module } from '@nestjs/common';
import { BookingPageController } from './booking-page.controller';
import { BookingPageService } from './booking-page.service';
import { MobizonService } from '../auth/mobizon.service';
import { SlotsModule } from '../slots/slots.module';

@Module({
  imports: [SlotsModule],
  controllers: [BookingPageController],
  providers: [BookingPageService, MobizonService],
})
export class BookingPageModule {}
