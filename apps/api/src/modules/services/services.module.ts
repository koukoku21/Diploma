import { Module } from '@nestjs/common';
import { ServicesController, ServiceTemplatesController } from './services.controller';
import { ServicesService } from './services.service';

@Module({
  controllers: [ServiceTemplatesController, ServicesController],
  providers: [ServicesService],
})
export class ServicesModule {}
