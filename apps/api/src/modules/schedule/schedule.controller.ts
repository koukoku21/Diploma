import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  Put,
  UseGuards,
} from '@nestjs/common';
import { ScheduleService } from './schedule.service';
import { UpdateScheduleDto } from './dto/update-schedule.dto';
import { CreateOverrideDto } from './dto/schedule-override.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';

@UseGuards(JwtAuthGuard)
@Controller('master/schedule')
export class ScheduleController {
  constructor(private schedule: ScheduleService) {}

  // M-8: недельное расписание
  @Get()
  getSchedule(@CurrentUser() user: { id: string }) {
    return this.schedule.getSchedule(user.id);
  }

  @Put()
  updateSchedule(
    @CurrentUser() user: { id: string },
    @Body() dto: UpdateScheduleDto,
  ) {
    return this.schedule.updateSchedule(user.id, dto);
  }

  // M-8a: особые дни
  @Get('overrides')
  getOverrides(@CurrentUser() user: { id: string }) {
    return this.schedule.getOverrides(user.id);
  }

  @Post('overrides')
  upsertOverride(
    @CurrentUser() user: { id: string },
    @Body() dto: CreateOverrideDto,
  ) {
    return this.schedule.upsertOverride(user.id, dto);
  }

  @Delete('overrides/:id')
  deleteOverride(
    @CurrentUser() user: { id: string },
    @Param('id') id: string,
  ) {
    return this.schedule.deleteOverride(user.id, id);
  }
}
