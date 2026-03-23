import { Controller, Delete, Get, Param, Post, UseGuards } from '@nestjs/common';
import { FavouritesService } from './favourites.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser } from '../auth/decorators/current-user.decorator';

@UseGuards(JwtAuthGuard)
@Controller('favourites')
export class FavouritesController {
  constructor(private favourites: FavouritesService) {}

  @Get()
  list(@CurrentUser() user: { id: string }) {
    return this.favourites.list(user.id);
  }

  @Post(':masterId')
  add(@CurrentUser() user: { id: string }, @Param('masterId') masterId: string) {
    return this.favourites.add(user.id, masterId);
  }

  @Delete(':masterId')
  remove(@CurrentUser() user: { id: string }, @Param('masterId') masterId: string) {
    return this.favourites.remove(user.id, masterId);
  }
}
