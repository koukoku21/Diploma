import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { SharedModule } from './shared/shared.module';
import { AuthModule } from './modules/auth/auth.module';
import { UsersModule } from './modules/users/users.module';
import { MastersModule } from './modules/masters/masters.module';
import { ServicesModule } from './modules/services/services.module';
import { ScheduleModule } from './modules/schedule/schedule.module';
import { PortfolioModule } from './modules/portfolio/portfolio.module';
import { FeedModule } from './modules/feed/feed.module';
import { SlotsModule } from './modules/slots/slots.module';
import { BookingsModule } from './modules/bookings/bookings.module';
import { ReviewsModule } from './modules/reviews/reviews.module';
import { FavouritesModule } from './modules/favourites/favourites.module';
import { ChatModule } from './modules/chat/chat.module';
import { NotificationsModule } from './modules/notifications/notifications.module';
import { AdminModule } from './modules/admin/admin.module';
import { GeocodeModule } from './modules/geocode/geocode.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    SharedModule,
    AuthModule,
    UsersModule,
    MastersModule,
    ServicesModule,
    ScheduleModule,
    PortfolioModule,
    FeedModule,
    SlotsModule,
    BookingsModule,
    ReviewsModule,
    FavouritesModule,
    ChatModule,
    NotificationsModule,
    AdminModule,
    GeocodeModule,
  ],
})
export class AppModule {}
