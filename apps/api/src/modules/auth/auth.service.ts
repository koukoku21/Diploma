import {
  BadRequestException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService } from '@nestjs/jwt';
import { PrismaService } from '../../shared/prisma.service';
import { RedisService } from '../../shared/redis.service';
import { MobizonService } from './mobizon.service';
import { SendOtpDto } from './dto/send-otp.dto';
import { VerifyOtpDto } from './dto/verify-otp.dto';
import { RefreshTokenDto } from './dto/refresh-token.dto';
import { JwtPayload } from './strategies/jwt.strategy';
import * as crypto from 'crypto';

const OTP_TTL_SECONDS = 5 * 60;        // 5 минут
const OTP_RATE_LIMIT_TTL = 60;         // повтор не раньше чем через 60 сек
const REFRESH_TOKEN_EXPIRES_DAYS = 30;

@Injectable()
export class AuthService {
  constructor(
    private prisma: PrismaService,
    private redis: RedisService,
    private jwt: JwtService,
    private config: ConfigService,
    private mobizon: MobizonService,
  ) {}

  // ─── POST /auth/send-otp ────────────────────────────────────────
  async sendOtp(dto: SendOtpDto): Promise<{ message: string }> {
    const rateLimitKey = `otp:rate:${dto.phone}`;
    const rateHit = await this.redis.get(rateLimitKey);
    if (rateHit) {
      throw new BadRequestException('Подождите минуту перед повторной отправкой');
    }

    const code = this.generateOtp();
    const otpKey = `otp:${dto.phone}`;

    await this.redis.set(otpKey, code, OTP_TTL_SECONDS);
    await this.redis.set(rateLimitKey, '1', OTP_RATE_LIMIT_TTL);

    await this.mobizon.sendOtp(dto.phone, code);

    return { message: 'Код отправлен' };
  }

  // ─── POST /auth/verify-otp ──────────────────────────────────────
  async verifyOtp(dto: VerifyOtpDto) {
    const otpKey = `otp:${dto.phone}`;
    const stored = await this.redis.get(otpKey);

    if (!stored || stored !== dto.code) {
      throw new BadRequestException('Неверный или устаревший код');
    }

    await this.redis.del(otpKey);

    // Ищем активного пользователя (для определения isNewUser)
    const existing = await this.prisma.user.findFirst({
      where: { phone: dto.phone, deletedAt: null },
    });

    const isNewUser = !existing;

    // upsert: создаём нового ИЛИ восстанавливаем soft-deleted аккаунт.
    // Атомарная операция — исключает race condition при двойном запросе.
    const user = await this.prisma.user.upsert({
      where: { phone: dto.phone },
      create: { phone: dto.phone, name: dto.name ?? '' },
      update: { deletedAt: null },
    });

    const tokens = await this.generateTokens(user.id, user.phone);

    return {
      ...tokens,
      isNewUser,
      user: {
        id: user.id,
        phone: user.phone,
        name: user.name,
        avatarUrl: user.avatarUrl,
        lang: user.lang,
      },
    };
  }

  // ─── POST /auth/refresh ─────────────────────────────────────────
  async refresh(dto: RefreshTokenDto) {
    const tokenRecord = await this.prisma.refreshToken.findUnique({
      where: { token: dto.refreshToken },
      include: { user: true },
    });

    if (!tokenRecord || tokenRecord.expiresAt < new Date()) {
      throw new UnauthorizedException('Refresh token недействителен');
    }

    if (tokenRecord.user.deletedAt) {
      throw new UnauthorizedException('Пользователь удалён');
    }

    // Ротация: удаляем старый, выдаём новый
    await this.prisma.refreshToken.delete({ where: { id: tokenRecord.id } });

    return this.generateTokens(tokenRecord.userId, tokenRecord.user.phone);
  }

  // ─── Helpers ────────────────────────────────────────────────────
  private generateOtp(): string {
    return String(crypto.randomInt(1000, 9999));
  }

  private async generateTokens(userId: string, phone: string) {
    const payload: JwtPayload = { sub: userId, phone };

    const accessToken = this.jwt.sign(payload, {
      expiresIn: this.config.get('JWT_EXPIRES_IN', '15m'),
    });

    const rawRefresh = crypto.randomBytes(40).toString('hex');
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + REFRESH_TOKEN_EXPIRES_DAYS);

    await this.prisma.refreshToken.create({
      data: { userId, token: rawRefresh, expiresAt },
    });

    return { accessToken, refreshToken: rawRefresh };
  }
}
