import { createSeededStayAggregate } from '../../src/infrastructure/seed/sanctuary-seed.data';
import { buildNewStay, NewStayIdentity } from '../../src/modules/admin/new-stay.builder';

const IDENTITY: NewStayIdentity = {
  stayId: 'stay_1767225600000_villa-104',
  guestTokenUuid: '44444444-4444-4444-8444-444444444444',
  magicLinkUrl: 'https://guest.example/?guestId=44444444-4444-4444-8444-444444444444',
  now: '2026-11-02T12:00:00.000Z',
};

/** Product-wide labels and enum values that legitimately appear in any stay. */
const SHARED_VOCABULARY = new Set(['HOST ADMIN', 'PRE_AUTHORIZED', 'TRANSPORT', 'massage']);

function stringLeaves(value: unknown): string[] {
  if (typeof value === 'string') return [value];
  if (value === null || typeof value !== 'object') return [];
  return Object.values(value).flatMap(stringLeaves);
}

describe('buildNewStay (empty stay from request fields only)', () => {
  it('test_buildNewStay_minimalRequest_containsNothingFromMillerTemplate', () => {
    const stay = buildNewStay({ guestName: 'Elena Vance' }, IDENTITY);

    const templateValues = new Set(
      stringLeaves(createSeededStayAggregate()).filter((v) => v !== '' && !SHARED_VOCABULARY.has(v)),
    );
    const leaked = stringLeaves(stay).filter((v) => templateValues.has(v));

    expect(leaked).toEqual([]);
  });

  it('test_buildNewStay_minimalRequest_hasNoSynthesizedContactsDatesOrReadings', () => {
    const stay = buildNewStay({ guestName: 'Elena Vance' }, IDENTITY);

    expect(stay.checkInTimestamp).toBe('');
    expect(stay.checkOutTimestamp).toBe('');
    expect(stay.stayDatesLabel).toBe('');
    expect(stay.nights).toBe(0);
    expect(stay.villaId).toBe('');
    expect(stay.guestProfile.avatarUrl).toBe('');
    expect(stay.guestProfile.folioCard).toBe('');
    expect(stay.hostInfo).toEqual({
      staffId: '', name: 'HOST ADMIN', shortName: 'HOST ADMIN', role: 'HOST ADMIN',
      avatarUrl: '', whatsappPhone: '', isOnline: false,
    });
    expect(stay.villaAccess).toEqual({
      digitalKeyStatus: 'INACTIVE', wifiSsid: '', wifiPasscode: '', climateTempF: 0,
      plungePoolTempF: 0, humidityPercent: 0, emergencyContact: '',
    });
    expect(stay.flightTransfer.driverPhone).toBe('');
    expect(stay.flightTransfer.driverAvatarUrl).toBe('');
    expect(stay.flightTransfer.status).toBe('Not Requested');
  });

  it('test_buildNewStay_fullRequest_mapsEveryRequestField', () => {
    const stay = buildNewStay(
      {
        guestName: 'Elena & Marcus Vance', partnerName: 'Marcus', villaId: 'villa-104',
        villaName: 'Villa 104 — Copal Suite', checkIn: '2026-12-01', checkOut: '2026-12-05',
        guestsCount: 2, occasion: 'Babymoon Retreat', email: 'elena@example.com',
        phone: '+1 555 0100', wifiSsid: ' Copal_104 ', wifiPasscode: ' secret ',
      },
      IDENTITY,
    );

    expect(stay).toMatchObject({
      stayId: IDENTITY.stayId,
      guestTokenUuid: IDENTITY.guestTokenUuid, magicLinkUrl: IDENTITY.magicLinkUrl,
      status: 'PRE_ARRIVAL', villaId: 'villa-104', villaName: 'Villa 104 — Copal Suite',
      suiteName: 'Copal Suite', stayDatesLabel: '2026-12-01 – 2026-12-05', nights: 4,
      checkInTimestamp: '2026-12-01T00:00:00.000Z', checkOutTimestamp: '2026-12-05T00:00:00.000Z',
      guestsCount: 2, createdAt: IDENTITY.now, updatedAt: IDENTITY.now,
    });
    expect(stay.guestProfile).toMatchObject({
      name: 'Elena & Marcus Vance', lastNameNormalized: 'vance', partner: 'Marcus',
      celebration: 'Babymoon Retreat', email: 'elena@example.com', phone: '+1 555 0100',
    });
    expect(stay.villaAccess.wifiSsid).toBe('Copal_104');
    expect(stay.villaAccess.wifiPasscode).toBe('secret');
    expect(stay.flightTransfer.partySize).toBe(2);
    expect(stay.personalization.tripPurpose).toBe('Babymoon Retreat');
    expect([stay.larderOrders, stay.experienceBookings, stay.conciergeRequests]).toEqual([[], [], []]);
    expect(stay.folioSummary.finalSettledTotalUSD).toBe(0);
  });

  it('test_buildNewStay_monthDayDatesWithoutYear_keepNightsButNoGuessedTimestamp', () => {
    const stay = buildNewStay({ guestName: 'Sofia Solis', checkIn: 'Oct 19', checkOut: 'Oct 22' }, IDENTITY);

    expect(stay.nights).toBe(3);
    expect(stay.checkInTimestamp).toBe('');
  });
});
