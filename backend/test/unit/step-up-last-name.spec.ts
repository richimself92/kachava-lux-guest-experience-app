import { matchesGuestLastName } from '../../src/modules/guest/step-up-last-name.matcher';

const profile = (name: string, lastNameNormalized: string) => ({ name, lastNameNormalized });

describe('matchesGuestLastName', () => {
  const miller = profile('Alex & Sarah Miller', 'miller');
  const garciaLopez = profile('María José García López', 'lópez');

  it.each(['Miller', '  MILLER ', 'miller'])('test_matches_fullLastName_%p_accepted', (input) => {
    expect(matchesGuestLastName(miller, input)).toBe(true);
  });

  it.each(['a', 'm', 'mil', 'ille', 'Sarah', 'Alex', '&', '', '  '])(
    'test_matches_substringOrGivenName_%p_rejected',
    (input) => {
      expect(matchesGuestLastName(miller, input)).toBe(false);
    },
  );

  it.each(['garcia', 'García', 'LOPEZ', 'lópez', 'Garcia Lopez', 'garcía-lópez'])(
    'test_matches_compoundSurnameToken_%p_acceptedDiacriticsInsensitive',
    (input) => {
      expect(matchesGuestLastName(garciaLopez, input)).toBe(true);
    },
  );

  it.each(['maria', 'jose', 'gar', 'lo'])('test_matches_compoundGivenOrPartial_%p_rejected', (input) => {
    expect(matchesGuestLastName(garciaLopez, input)).toBe(false);
  });

  it.each([
    ['cruz', true],
    ['De la Cruz', true],
    ['de', false],
    ['la', false],
    ['ana', false],
  ])('test_matches_surnameWithParticles_%p_returns%s', (input, expected) => {
    expect(matchesGuestLastName(profile('Ana de la Cruz', 'cruz'), input)).toBe(expected);
  });

  it('test_matches_undefinedInput_rejected', () => {
    expect(matchesGuestLastName(miller, undefined)).toBe(false);
  });

  it('test_matches_singleCharacterSurname_rejectedBelowMinimumLength', () => {
    expect(matchesGuestLastName(profile('Ana O', 'o'), 'o')).toBe(false);
  });
});
