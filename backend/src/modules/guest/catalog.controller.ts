import { Controller, Get, Inject } from '@nestjs/common';
import {
  CATALOG_REPOSITORY_PORT,
  CatalogRepositoryPort,
} from '../../domain/ports/repository.ports';

@Controller('catalog')
export class CatalogController {
  constructor(
    @Inject(CATALOG_REPOSITORY_PORT)
    private readonly catalogRepo: CatalogRepositoryPort,
  ) {}

  @Get('larder')
  getLarderCatalog() {
    return this.catalogRepo.getLarderCatalog();
  }

  @Get('experiences')
  getExperiencesCatalog() {
    return this.catalogRepo.getExperiencesCatalog();
  }

  @Get('yacht')
  getYachtCatalog() {
    return this.catalogRepo.getYachtCatalog();
  }
}
