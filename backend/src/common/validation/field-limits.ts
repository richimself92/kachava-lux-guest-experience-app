import { registerDecorator, ValidationOptions } from 'class-validator';

/**
 * Upper bounds for every client-supplied field (ADV-07). Together with the per-stay list caps in
 * `domain/stay-limits.ts` they keep one stay document far below Firestore's 1 MiB limit.
 */
export const SHORT_TEXT_MAX = 200;
export const LONG_TEXT_MAX = 2000;
export const URL_MAX = 2048;
export const EMAIL_MAX = 254;
export const STRING_LIST_MAX = 30;
export const LARDER_LINES_MAX = 100;
export const METADATA_MAX_BYTES = 2048;
/** Calendar date without time, e.g. 2026-11-02 (compared lexicographically in Firestore). */
export const ISO_DATE_PATTERN = /^\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12]\d|3[01])$/;
/** 24-hour clock time, e.g. 07:30. */
export const TIME_OF_DAY_PATTERN = /^([01]\d|2[0-3]):[0-5]\d$/;
/** Language code such as `en`, `es` or `es-MX`. */
export const LANGUAGE_PATTERN = /^[a-z]{2}(-[A-Z]{2})?$/;
/** Villa ids become part of stay ids and storage paths: letters, digits, `_` and `-` only. */
export const VILLA_ID_PATTERN = /^[A-Za-z0-9_-]{1,40}$/;

/** Rejects objects whose JSON encoding exceeds `maxBytes`. */
export function MaxJsonBytes(maxBytes: number, options?: ValidationOptions): PropertyDecorator {
  return (target, propertyName) =>
    registerDecorator({
      name: 'maxJsonBytes',
      target: target.constructor,
      propertyName: String(propertyName),
      constraints: [maxBytes],
      options: { message: `$property must be at most ${maxBytes} bytes of JSON`, ...options },
      validator: {
        validate: (value: unknown) =>
          value === undefined || Buffer.byteLength(JSON.stringify(value) ?? '') <= maxBytes,
      },
    });
}
