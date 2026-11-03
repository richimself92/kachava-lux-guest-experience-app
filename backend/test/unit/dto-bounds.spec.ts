import 'reflect-metadata';
import { plainToInstance } from 'class-transformer';
import { getMetadataStorage, validate } from 'class-validator';
import * as adminDtos from '../../src/modules/admin/dto/admin.dto';
import * as guestDtos from '../../src/modules/guest/dto/guest.dto';

type DtoClass = new () => object;

const DTO_CLASSES = [...Object.values(guestDtos), ...Object.values(adminDtos)].filter(
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
    expect(DTO_CLASSES.length).toBeGreaterThan(15);
    expect(DTO_CLASSES.flatMap(unboundedFields)).toEqual([]);
  });

  it('test_createBookingDto_oversizedMetadata_isRejected', async () => {
    const dto = plainToInstance(guestDtos.CreateBookingDto, {
      catalogRefId: 'exp-1',
      scheduledDate: '2026-11-14',
      scheduledTimeSlot: '10:00',
      metadata: { blob: 'x'.repeat(5_000) },
    });

    const errors = await validate(dto);

    expect(errors.map((e) => e.property)).toEqual(['metadata']);
  });

  it('test_createReservationDto_villaIdWithPathCharacters_isRejected', async () => {
    const dto = plainToInstance(adminDtos.CreateReservationDto, { guestName: 'X Y', villaId: 'a/b' });

    const errors = await validate(dto);

    expect(errors.map((e) => e.property)).toEqual(['villaId']);
  });
});
