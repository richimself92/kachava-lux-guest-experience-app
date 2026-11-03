import { Transform } from 'class-transformer';

/** Query strings arrive as text: maps "true"/"false" to booleans and leaves anything else for validation. */
export function QueryBoolean(): PropertyDecorator {
  return Transform(({ value }) => {
    if (value === 'true') return true;
    if (value === 'false') return false;
    return value;
  });
}
