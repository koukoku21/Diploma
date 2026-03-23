import { Body, Controller, Get, Param, Patch, Query, UseGuards } from '@nestjs/common';
import { MasterStatus } from '@prisma/client';
import { AdminService } from './admin.service';
import { AdminGuard } from './guards/admin.guard';
import { ReviewMasterDto } from './dto/review-master.dto';

@UseGuards(AdminGuard)
@Controller('admin')
export class AdminController {
  constructor(private admin: AdminService) {}

  @Get('stats')
  getStats() {
    return this.admin.getStats();
  }

  // Список заявок (по умолчанию PENDING)
  @Get('masters')
  getPendingMasters(@Query('status') status?: MasterStatus) {
    return this.admin.getPendingMasters(status ?? MasterStatus.PENDING);
  }

  // Детали заявки мастера
  @Get('masters/:id')
  getMasterDetail(@Param('id') id: string) {
    return this.admin.getMasterDetail(id);
  }

  // APPROVE / REJECT / SUSPEND
  @Patch('masters/:id/review')
  reviewMaster(@Param('id') id: string, @Body() dto: ReviewMasterDto) {
    return this.admin.reviewMaster(id, dto);
  }
}
