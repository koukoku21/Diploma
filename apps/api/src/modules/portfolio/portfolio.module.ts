import { Module } from '@nestjs/common';
import { PortfolioController } from './portfolio.controller';
import { PortfolioService } from './portfolio.service';
import { R2Service } from './r2.service';

@Module({
  controllers: [PortfolioController],
  providers: [PortfolioService, R2Service],
  exports: [R2Service],
})
export class PortfolioModule {}
