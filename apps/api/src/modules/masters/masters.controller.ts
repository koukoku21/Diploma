import {
  Body,
  Controller,
  Get,
  Param,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { MastersService } from './masters.service';
import { CreateMasterDto } from './dto/create-master.dto';
import { UpdateMasterDto } from './dto/update-master.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';

@Controller('masters')
export class MastersController {
  constructor(private masters: MastersService) {}

  // Онбординг: "Стать мастером" из экрана C-8
  @UseGuards(JwtAuthGuard)
  @Post()
  createProfile(
    @CurrentUser() user: { id: string },
    @Body() dto: CreateMasterDto,
  ) {
    return this.masters.createProfile(user.id, dto);
  }

  // M-6: Дашборд мастера
  @UseGuards(JwtAuthGuard)
  @Get('dashboard')
  getDashboard(@CurrentUser() user: { id: string }) {
    return this.masters.getDashboard(user.id);
  }

  // Мой профиль (для экрана M-9)
  @UseGuards(JwtAuthGuard)
  @Get('me')
  getMyProfile(@CurrentUser() user: { id: string }) {
    return this.masters.getMyProfile(user.id);
  }

  // Обновление профиля (M-9)
  @UseGuards(JwtAuthGuard)
  @Patch('me')
  updateProfile(
    @CurrentUser() user: { id: string },
    @Body() dto: UpdateMasterDto,
  ) {
    return this.masters.updateProfile(user.id, dto);
  }

  // Публичный профиль (экран C-2)
  @Get(':id')
  getPublicProfile(@Param('id') id: string) {
    return this.masters.getPublicProfile(id);
  }
}
