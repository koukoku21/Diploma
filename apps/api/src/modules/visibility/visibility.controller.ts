import { Body, Controller, Get, Post, UseGuards } from '@nestjs/common';
import { VisibilityService } from './visibility.service';
import { ActivateVisibilityDto } from './dto/activate-visibility.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';

@UseGuards(JwtAuthGuard)
@Controller('visibility')
export class VisibilityController {
  constructor(private readonly visibility: VisibilityService) {}

  @Post('activate')
  activate(@CurrentUser() user: any, @Body() dto: ActivateVisibilityDto) {
    return this.visibility.activate(user.id, dto);
  }

  @Get('status')
  getStatus(@CurrentUser() user: any) {
    return this.visibility.getStatus(user.id);
  }
}
