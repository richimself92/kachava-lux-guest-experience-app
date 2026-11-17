import { buildNewStay, NewStayIdentity, nightsBetween } from '../../src/modules/admin/new-stay.builder';
import { villaFixture } from '../support/stay-fixtures';

const IDENTITY: NewStayIdentity = {
  stayId: 'stay_test_1',
  guestTokenUuid: '44444444-4444-4444-8444-444444444444',
  magicLinkUrl: 'https://guest.example/?guestId=44444444-4444-4444-8444-444444444444',
  now: '2026-11-02T12:00:00.000Z',
};

describe('buildNewStay (empty stay from the request and its villa only)', () => {
  it('test_buildNewStay_minimalRequest_hasNoSynthesizedContactsOrReadings', () => {
    const stay = buildNewStay(
      { guestName: 'Test Guest', villaId: 'villa-a', checkIn: '2026-12-01', checkOut: '2026-12-03' },
      villaFixture(),
      IDENTITY,
    );

    expect(stay.guestProfile.avatarUrl).toBe('');
    expect(stay.guestProfile.folioCard).toBe('');
    expect(stay.hostInfo).toEqual({
      staffId: '', name: 'HOST ADMIN', shortName: 'HOST ADMIN', role: 'HOST ADMIN',
      avatarUrl: '', whatsappPhone: '', isOnline: false,
    });
    expect(stay.villaAccess).toEqual({
      digitalKeyStatus: 'INACTIVE', wifiSsid: 'test-net', wifiPasscode: 'test-pass', climateTempF: 0,
      plungePoolTempF: 0, humidityPercent: 0, emergencyContact: '',
    });
    expect(stay.flightTransfer.driverPhone).toBe('');
    expect(stay.flightTransfer.status).toBe('Not Requested');
    expect([stay.larderOrders, stay.experienceBookings, stay.conciergeRequests, stay.folioItems]).toEqual([[], [], [], []]);
  });

  it('test_buildNewStay_fullRequest_mapsRequestAndVillaFields', () => {
    const stay = buildNewStay(
      {
        guestName: 'Ana & Leo Test', partnerName: 'Leo', villaId: 'villa-a', checkIn: '2026-12-01',
        checkOut: '2026-12-05', guestsCount: 2, occasion: 'Anniversary', email: 'ana@example.com',
        phone: '+1 555 0100', wifiSsid: ' Override ', wifiPasscode: ' secret ',
      },
      villaFixture(),
      IDENTITY,
    );

    expect(stay).toMatchObject({
      stayId: IDENTITY.stayId, guestTokenUuid: IDENTITY.guestTokenUuid, magicLinkUrl: IDENTITY.magicLinkUrl,
      status: 'PRE_ARRIVAL', villaId: 'villa-a', villaName: 'Test Villa', suiteName: 'Test category',
      stayDatesLabel: '2026-12-01 – 2026-12-05', nights: 4, checkInDate: '2026-12-01', checkOutDate: '2026-12-05',
      checkInTimestamp: '2026-12-01T00:00:00.000Z', checkOutTimestamp: '2026-12-05T00:00:00.000Z',
      guestsCount: 2, createdAt: IDENTITY.now, updatedAt: IDENTITY.now,
    });
    expect(stay.guestProfile).toMatchObject({
      name: 'Ana & Leo Test', lastNameNormalized: 'test', partner: 'Leo',
      celebration: 'Anniversary', email: 'ana@example.com', phone: '+1 555 0100',
    });
    expect(stay.villaAccess.wifiSsid).toBe('Override');
    expect(stay.villaAccess.wifiPasscode).toBe('secret');
    expect(stay.flightTransfer.partySize).toBe(2);
    expect(stay.personalization.tripPurpose).toBe('Anniversary');
  });

  it('test_nightsBetween_isoDates', () => {
    expect(nightsBetween('2026-12-30', '2027-01-02')).toBe(3);
    expect(nightsBetween('2026-12-01', '2026-12-01')).toBe(0);
  });
});
