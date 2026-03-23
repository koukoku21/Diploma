import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Post,
  Put,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { PortfolioService } from './portfolio.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';

@UseGuards(JwtAuthGuard)
@Controller('master/portfolio')
export class PortfolioController {
  constructor(private portfolio: PortfolioService) {}

  // M-10: список фото
  @Get()
  getPhotos(@CurrentUser() user: { id: string }) {
    return this.portfolio.getPhotos(user.id);
  }

  // M-3 / M-10: загрузить фото
  @Post('upload')
  @UseInterceptors(
    FileInterceptor('file', {
      limits: { fileSize: 10 * 1024 * 1024 }, // 10 MB
    }),
  )
  upload(
    @CurrentUser() user: { id: string },
    @UploadedFile() file: Express.Multer.File,
  ) {
    return this.portfolio.upload(user.id, file);
  }

  // M-10: drag & drop порядок
  @Put('reorder')
  reorder(
    @CurrentUser() user: { id: string },
    @Body('ids') ids: string[],
  ) {
    return this.portfolio.reorder(user.id, ids);
  }

  // M-10: удалить фото
  @Delete(':id')
  delete(
    @CurrentUser() user: { id: string },
    @Param('id') id: string,
  ) {
    return this.portfolio.delete(user.id, id);
  }
}
