import { Module } from '@nestjs/common';
import { BookingsController } from './bookings.controller';
import { BookingsService } from './bookings.service';
import { SlotsModule } from '../slots/slots.module';
import { NotificationsModule } from '../notifications/notifications.module';

@Module({
  imports: [SlotsModule, NotificationsModule],
  controllers: [BookingsController],
  providers: [BookingsService],
  exports: [BookingsService],
})
export class BookingsModule {}
