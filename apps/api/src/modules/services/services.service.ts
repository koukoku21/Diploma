import {
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
    });
    if (!service) throw new NotFoundException('Услуга не найдена');
    if (service.masterId !== masterId) throw new ForbiddenException();
    return service;
  }

  async list(userId: string) {
    const master = await this.getMasterOrThrow(userId);
    return this.prisma.service.findMany({
      where: { masterId: master.id },
      orderBy: { createdAt: 'asc' },
    });
  }

  async create(userId: string, dto: CreateServiceDto) {
    const master = await this.getMasterOrThrow(userId);
    return this.prisma.service.create({
      data: { ...dto, masterId: master.id },
    });
  }

  async update(userId: string, serviceId: string, dto: UpdateServiceDto) {
    const master = await this.getMasterOrThrow(userId);
    await this.getServiceOrThrow(serviceId, master.id);
    return this.prisma.service.update({
      where: { id: serviceId },
      data: dto,
    });
  }

  async remove(userId: string, serviceId: string) {
    const master = await this.getMasterOrThrow(userId);
    await this.getServiceOrThrow(serviceId, master.id);
    await this.prisma.service.delete({ where: { id: serviceId } });
    return { message: 'Услуга удалена' };
  }
}
