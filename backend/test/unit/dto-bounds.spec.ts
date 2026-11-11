import 'reflect-metadata';
import { plainToInstance } from 'class-transformer';
import { getMetadataStorage, validate } from 'class-validator';
import { ListQueryDto } from '../../src/common/listing/list-query';
import * as adminDtos from '../../src/modules/admin/dto/admin.dto';
import * as catalogCommonDtos from '../../src/modules/catalog/dto/catalog-common.dto';
import * as itemDtos from '../../src/modules/catalog/dto/item.dto';
import * as serviceBlockDtos from '../../src/modules/catalog/dto/service-blocks.dto';
import * as serviceDtos from '../../src/modules/catalog/dto/service.dto';
import * as uploadDtos from '../../src/modules/catalog/dto/upload.dto';
import * as guestDtos from '../../src/modules/guest/dto/guest.dto';
import * as settingsDtos from '../../src/modules/settings/settings.dto';
import * as providerDtos from '../../src/modules/transport/transport-provider.dto';
import * as villaDtos from '../../src/modules/villas/villa.dto';

type DtoClass = new () => object;

const DTO_MODULES = [
  guestDtos, adminDtos, settingsDtos, villaDtos, providerDtos, serviceDtos, serviceBlockDtos, itemDtos,
  catalogCommonDtos, uploadDtos, { ListQueryDto },
];
const DTO_CLASSES = DTO_MODULES.flatMap((m) => Object.values(m)).filter(
  (value): value is DtoClass => typeof value === 'function',
);

/** Constraint names per property, as registered by class-validator decorators. */
function constraintsByProperty(dto: DtoClass): Map<string, Set<string>> {
  const metadata = getMetadataStorage().getTargetValidationMetadatas(dto, '', true, false);
  const byProperty = new Map<string, Set<string>>();
  for (const entry of metadata) {
    const name = entry.name ?? entry.constraintCls?.name ?? entry.type;
    const set = byProperty.get(entry.propertyName) ?? new Set<string>();
    set.add(name);
    byProperty.set(entry.propertyName, set);
  }
  return byProperty;
}

function unboundedFields(dto: DtoClass): string[] {
  const missing: string[] = [];
  for (const [property, names] of constraintsByProperty(dto)) {
    const textual = names.has('isString') || names.has('isEmail');
    if (textual && !names.has('maxLength')) missing.push(`${dto.name}.${property} (maxLength)`);
    if (names.has('isArray') && !names.has('arrayMaxSize')) missing.push(`${dto.name}.${property} (arrayMaxSize)`);
    if (names.has('isObject') && !names.has('maxJsonBytes')) missing.push(`${dto.name}.${property} (maxJsonBytes)`);
  }
  return missing;
}

describe('Every guest/admin DTO field is size-bounded (ADV-07)', () => {
  it('test_dtos_everyStringArrayAndObjectField_hasAnUpperBound', () => {
    expect(DTO_CLASSES.length).toBeGreaterThan(40);
    expect(DTO_CLASSES.flatMap(unboundedFields)).toEqual([]);
  });

  it('test_createBookingDto_oversizedMetadata_isRejected', async () => {
    const dto = plainToInstance(guestDtos.CreateBookingDto, {
      serviceId: 'svc-1',
      scheduledDate: '2026-11-14',
      scheduledTimeSlot: '10:00',
      metadata: { blob: 'x'.repeat(5_000) },
    });

    const errors = await validate(dto);

    expect(errors.map((e) => e.property)).toEqual(['metadata']);
  });

  it('test_createReservationDto_villaIdWithPathCharacters_isRejected', async () => {
    const dto = plainToInstance(adminDtos.CreateReservationDto, { guestName: 'X Y', villaId: 'a/b', checkIn: '2026-12-01', checkOut: '2026-12-02' });

    const errors = await validate(dto);

    expect(errors.map((e) => e.property)).toEqual(['villaId']);
  });
});
