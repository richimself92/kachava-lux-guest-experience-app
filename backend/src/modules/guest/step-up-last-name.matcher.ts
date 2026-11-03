import { GuestProfile } from '../../domain/models/domain.models';

const MIN_LAST_NAME_LENGTH = 2;
const MAX_SURNAME_TOKENS = 2;
const COUPLE_SEPARATOR = /\s(?:&|and|y)\s/;
const SURNAME_PARTICLES = new Set([
  'de', 'del', 'la', 'las', 'los', 'da', 'das', 'do', 'dos', 'di', 'du', 'van', 'von', 'der', 'le',
]);

/** Lowercase, strip diacritics, treat hyphens as spaces and collapse whitespace. */
function normalize(value: string): string {
  return value
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .toLowerCase()
    .replace(/-/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

/** Name tokens after the given name of the last person listed ("Ana & Leo Ruiz" -> [ruiz]). */
function familyNameTokens(fullName: string): string[] {
  const people = normalize(fullName).split(COUPLE_SEPARATOR);
  const tokens = (people[people.length - 1] ?? '').split(' ').filter(Boolean);
  return tokens.length > 1 ? tokens.slice(1) : tokens;
}

/**
 * Accepted answers: the stored last name, any full surname token (compound surnames keep at most the
 * final two non-particle tokens, so a second given name is not a surname), or a trailing run of the
 * family-name tokens ("de la cruz", "garcia lopez"). Never a substring; minimum two characters.
 */
function acceptedAnswers(profile: Pick<GuestProfile, 'name' | 'lastNameNormalized'>): Set<string> {
  const family = familyNameTokens(profile.name);
  const surnameTokens = family.filter((token) => !SURNAME_PARTICLES.has(token)).slice(-MAX_SURNAME_TOKENS);
  const trailingRuns = family.map((_, index) => family.slice(index).join(' '));
  const stored = normalize(profile.lastNameNormalized);
  return new Set([stored, ...stored.split(' '), ...surnameTokens, ...trailingRuns]);
}

export function matchesGuestLastName(
  profile: Pick<GuestProfile, 'name' | 'lastNameNormalized'>,
  candidate: string | undefined,
): boolean {
  const answer = normalize(candidate ?? '');
  if (answer.length < MIN_LAST_NAME_LENGTH) return false;
  return acceptedAnswers(profile).has(answer);
}
