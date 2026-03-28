import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../shared/prisma.service';
import { CreateServiceDto } from './dto/create-service.dto';
import { UpdateServiceDto } from './dto/update-service.dto';

@Injectable()
export class ServicesService {
  constructor(private prisma: PrismaService) {}

  private async getMasterOrThrow(userId: string) {
    const master = await this.prisma.masterProfile.findUnique({
      where: { userId },
    });
    if (!master) throw new NotFoundException('Профиль мастера не найден');
    return master;
  }

  private async getServiceOrThrow(serviceId: string, masterId: string) {
    const service = await this.prisma.service.findUnique({
      where: { id: serviceId },
      include: { template: true },
    });
    if (!service) throw new NotFoundException('Услуга не найдена');
    if (service.masterId !== masterId) throw new ForbiddenException();
    return service;
  }

  // GET /service-templates — публичный справочник услуг
  async listTemplates() {
    return this.prisma.serviceTemplate.findMany({
      where: { isActive: true },
      orderBy: { sortOrder: 'asc' },
      select: { id: true, name: true, nameKz: true, category: true, sortOrder: true },
    });
  }

  async list(userId: string) {
    const master = await this.getMasterOrThrow(userId);
    return this.prisma.service.findMany({
      where: { masterId: master.id },
      include: { template: { select: { name: true, nameKz: true, category: true } } },
      orderBy: { createdAt: 'asc' },
    });
  }

  async create(userId: string, dto: CreateServiceDto) {
    const master = await this.getMasterOrThrow(userId);

    const template = await this.prisma.serviceTemplate.findUnique({
      where: { id: dto.templateId },
    });
    if (!template || !template.isActive) {
      throw new NotFoundException('Шаблон услуги не найден');
    }

    // Проверяем уникальность: один мастер — одна услуга из шаблона
    const existing = await this.prisma.service.findFirst({
      where: { masterId: master.id, templateId: dto.templateId },
    });
    if (existing) {
      throw new BadRequestException('Эта услуга уже добавлена');
    }

    return this.prisma.service.create({
      data: {
        masterId: master.id,
        templateId: dto.templateId,
        title: template.name,       // снапшот названия
        category: template.category, // снапшот категории
        priceFrom: dto.priceFrom,
        durationMin: dto.durationMin,
      },
      include: { template: { select: { name: true, nameKz: true, category: true } } },
    });
  }

  async update(userId: string, serviceId: string, dto: UpdateServiceDto) {
    const master = await this.getMasterOrThrow(userId);
    await this.getServiceOrThrow(serviceId, master.id);
    return this.prisma.service.update({
      where: { id: serviceId },
      data: dto,
      include: { template: { select: { name: true, nameKz: true, category: true } } },
    });
  }

  async remove(userId: string, serviceId: string) {
    const master = await this.getMasterOrThrow(userId);
    await this.getServiceOrThrow(serviceId, master.id);
    await this.prisma.service.delete({ where: { id: serviceId } });
    return { message: 'Услуга удалена' };
  }
}
