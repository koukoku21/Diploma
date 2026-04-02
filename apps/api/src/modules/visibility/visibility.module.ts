import { Module } from '@nestjs/common';
import { VisibilityService } from './visibility.service';
import { VisibilityController } from './visibility.controller';
import { NotificationsModule } from '../notifications/notifications.module';

@Module({
  imports: [NotificationsModule],
  controllers: [VisibilityController],
  providers: [VisibilityService],
  exports: [VisibilityService],
})
export class VisibilityModule {}
