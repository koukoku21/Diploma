import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  UseGuards,
} from '@nestjs/common';
import { ServicesService } from './services.service';
import { CreateServiceDto } from './dto/create-service.dto';
import { UpdateServiceDto } from './dto/update-service.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';

// Публичный справочник услуг (без авторизации)
@Controller('service-templates')
export class ServiceTemplatesController {
  constructor(private services: ServicesService) {}

  @Get()
  listTemplates() {
    return this.services.listTemplates();
  }
}

@UseGuards(JwtAuthGuard)
@Controller('master/services')
export class ServicesController {
  constructor(private services: ServicesService) {}

  // M-11: список услуг мастера
  @Get()
  list(@CurrentUser() user: { id: string }) {
    return this.services.list(user.id);
  }

  // M-11: добавить услугу (templateId + price + duration)
  @Post()
  create(@CurrentUser() user: { id: string }, @Body() dto: CreateServiceDto) {
    return this.services.create(user.id, dto);
  }

  // M-11: редактировать цену/длительность/включённость
  @Patch(':id')
  update(
    @CurrentUser() user: { id: string },
    @Param('id') id: string,
    @Body() dto: UpdateServiceDto,
  ) {
    return this.services.update(user.id, id, dto);
  }

  // M-11: удалить услугу
  @Delete(':id')
  remove(@CurrentUser() user: { id: string }, @Param('id') id: string) {
    return this.services.remove(user.id, id);
  }
}
