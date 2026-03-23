import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

// Простая защита admin-панели: X-Admin-Secret хедер
// В production заменить на полноценный admin JWT с ролью
@Injectable()
export class AdminGuard implements CanActivate {
  private readonly secret: string;

  constructor(config: ConfigService) {
    this.secret = config.getOrThrow('ADMIN_SECRET');
  }

  canActivate(ctx: ExecutionContext): boolean {
    const req = ctx.switchToHttp().getRequest();
    const header = req.headers['x-admin-secret'];

    if (header !== this.secret) {
      throw new ForbiddenException('Нет доступа');
    }

    return true;
  }
}
