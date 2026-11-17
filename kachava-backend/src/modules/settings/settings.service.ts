import { Inject, Injectable } from '@nestjs/common';
import { BusinessRuleError } from '../../domain/domain-errors';
import { ResortSettings } from '../../domain/models/resort-config.models';
import {
  SETTINGS_REPOSITORY_PORT,
  SettingsRepositoryPort,
} from '../../domain/ports/repository.ports';
import { UpdateSettingsDto } from './settings.dto';

@Injectable()
export class SettingsService {
  constructor(
    @Inject(SETTINGS_REPOSITORY_PORT) private readonly settings: SettingsRepositoryPort,
  ) {}

  get(): Promise<ResortSettings> {
    return this.settings.get();
  }

  update(dto: UpdateSettingsDto, actor: string): Promise<ResortSettings> {
    if (dto.airports) assertUniqueAirports(dto.airports.map((a) => a.code));
    const patch = Object.fromEntries(
      Object.entries(dto).filter(([, value]) => value !== undefined),
    ) as Partial<ResortSettings>;
    if (dto.airports) {
      patch.airports = dto.airports.map((a) => ({ ...a, isActive: a.isActive ?? true }));
    }
    return this.settings.update((current) => ({
      ...current,
      ...patch,
      updatedAt: new Date().toISOString(),
      updatedBy: actor,
    }));
  }
}

function assertUniqueAirports(codes: string[]): void {
  const duplicates = codes.filter((code, index) => codes.indexOf(code) !== index);
  if (duplicates.length > 0) {
    throw new BusinessRuleError('Airport codes must be unique', duplicates.map((c) => `${c} is repeated`));
  }
}
