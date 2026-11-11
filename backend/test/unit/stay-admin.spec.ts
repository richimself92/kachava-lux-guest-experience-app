import { BusinessRuleError } from '../../src/domain/domain-errors';
import {
  buildStayFolio,
  toGuestProfileView,
  toGuestRow,
  toReservationRow,
  toStayDetail,
} from '../../src/domain/stays/stay-admin-views';
import { applyStayAdminPatch, transitionStay } from '../../src/domain/stays/stay-transitions';
import { populatedStayFixture, stayFixture } from '../support/stay-fixtures';
import { tripFixture } from '../support/trip-fixtures';

const AT = '2026-12-01T15:00:00.000Z';
const ACTOR = 'staff@test.local';
const LINK = 'https://guest.test/?guestId=';

describe('transitionStay', () => {
  it('test_checkIn_movesPreArrivalToInHouse_withHistory', () => {
    const stay = stayFixture();

    const next = transitionStay(stay, { action: 'CHECK_IN' }, ACTOR, AT);

    expect(next.status).toBe('ACTIVE_STAY');
    expect(next.statusHistory).toEqual([{ from: 'PRE_ARRIVAL', to: 'ACTIVE_STAY', at: AT, by: ACTOR, reason: null }]);
    expect(stay.status).toBe('PRE_ARRIVAL');
  });

  it('test_checkOut_movesInHouseToCheckedOut', () => {
    expect(transitionStay(stayFixture({ status: 'ACTIVE_STAY' }), { action: 'CHECK_OUT' }, ACTOR, AT).status).toBe('CHECKED_OUT');
  });

  it('test_cancel_needsAReason_andStoresIt', () => {
    expect(() => transitionStay(stayFixture(), { action: 'CANCEL' }, ACTOR, AT)).toThrow(/reason/);

    const next = transitionStay(stayFixture(), { action: 'CANCEL', reason: ' Guest request ' }, ACTOR, AT);

    expect(next).toMatchObject({ status: 'CANCELLED', cancellationReason: 'Guest request' });
  });

  it.each([
    ['CHECK_IN', 'ACTIVE_STAY'],
    ['CHECK_OUT', 'PRE_ARRIVAL'],
    ['CANCEL', 'ACTIVE_STAY'],
    ['CHECK_IN', 'CANCELLED'],
  ] as const)('test_%s_from_%s_isRejected', (action, status) => {
    expect(() => transitionStay(stayFixture({ status }), { action, reason: 'r' }, ACTOR, AT)).toThrow(BusinessRuleError);
  });
});

describe('applyStayAdminPatch', () => {
  it('test_setsHostNotesLanguageAndWifiOverride', () => {
    const next = applyStayAdminPatch(stayFixture(), {
      resortHostName: ' Laura ', resortHostStaffId: 'staff-3', internalNotes: 'VIP', language: 'es',
      wifi: { ssid: 'guest-net', password: 'secret' },
    }, AT);

    expect(next.hostInfo).toMatchObject({ staffId: 'staff-3', name: 'Laura', shortName: 'Laura' });
    expect(next).toMatchObject({ internalNotes: 'VIP', updatedAt: AT });
    expect(next.guestProfile.language).toBe('es');
    expect(next.villaAccess).toMatchObject({ wifiSsid: 'guest-net', wifiPasscode: 'secret' });
  });

  it('test_closedStay_isReadOnly', () => {
    expect(() => applyStayAdminPatch(stayFixture({ status: 'CANCELLED' }), { internalNotes: 'x' }, AT)).toThrow(/CANCELLED/);
  });
});

describe('admin stay views', () => {
  it('test_reservationRow_hasTheTableFields_andALinkFromTheCurrentToken', () => {
    const stay = stayFixture({ hostInfo: { ...stayFixture().hostInfo, staffId: 'staff-3', name: 'Laura' } });

    expect(toReservationRow(stay, LINK)).toEqual({
      id: 'stay-test-1', guestName: 'Test Guest', villaId: 'villa-a', villaName: 'Test Villa',
      checkIn: '2026-12-01', checkOut: '2026-12-05', status: 'PRE_ARRIVAL', resortHostName: 'Laura',
      magicLinkUrl: `${LINK}${stay.guestTokenUuid}`,
    });
  });

  it('test_unassignedHost_isNull', () => {
    expect(toReservationRow(stayFixture(), LINK).resortHostName).toBeNull();
  });

  it('test_detail_addsWifiNotesNightsAndHistory', () => {
    const detail = toStayDetail(stayFixture({ internalNotes: 'VIP' }), LINK);

    expect(detail).toMatchObject({
      id: 'stay-test-1', nights: 4, guestsCount: 2, internalNotes: 'VIP', language: null,
      wifi: { ssid: 'test-net', password: 'test-pass' }, resortHost: null, statusHistory: [], cancellationReason: null,
    });
  });

  it('test_folio_listsOrdersBookingsTripsWithSnapshots_ratingAndCharges', () => {
    const stay = populatedStayFixture();
    const trip = tripFixture({ snapshot: null });

    const folio = buildStayFolio(stay, [trip]);

    expect(folio.stay).toMatchObject({ id: stay.stayId, guestName: 'Test Guest', nights: 4, status: 'ACTIVE_STAY' });
    expect(folio.services.map((s) => [s.type, s.id])).toEqual([
      ['ORDER', 'stay-test-1_svc-stock'], ['BOOKING', 'bk-test-1'], ['TRIP', 'trip-1'],
    ]);
    expect(folio.services[0]).toMatchObject({ totalUSD: 10, lines: [{ itemId: 'item-1', quantity: 2, lineTotalUSD: 10 }] });
    expect(folio.services[1]).toMatchObject({ totalUSD: 20, snapshot: stay.experienceBookings[0].snapshot });
    expect(folio.rating).toMatchObject({ rating: 5, sentiment: 'serene' });
    expect(folio.charges).toEqual({ items: stay.folioItems, summary: stay.folioSummary, totalUSD: 0 });
  });
});

describe('guest views', () => {
  it('test_guestRow_flagsAllergiesAndCountsOpenRequests', () => {
    const stay = populatedStayFixture({
      guestProfile: { ...stayFixture().guestProfile, allergies: 'Peanuts', language: 'en' },
    });

    expect(toGuestRow(stay, 1)).toEqual({
      stayId: stay.stayId, guestName: 'Test Guest', villaId: 'villa-a', villaName: 'Test Villa',
      checkIn: '2026-12-01', checkOut: '2026-12-05', status: 'ACTIVE_STAY', language: 'en',
      hasAllergies: true, openRequests: 4,
    });
  });

  it('test_profile_hasPreferencesAllergiesOccasionHistoryAndNotes', () => {
    const stay = populatedStayFixture({ internalNotes: 'Quiet room' });

    const profile = toGuestProfileView(stay, [tripFixture()]);

    expect(profile).toMatchObject({
      stayId: stay.stayId, guestName: 'Test Guest', internalNotes: 'Quiet room',
      allergies: { hasAllergies: false, items: [], label: '' },
      occasion: { celebration: '', details: '' },
    });
    // Newest first; the trip was requested before the other three.
    expect(profile.requestHistory.map((r) => r.type)).toEqual(['BOOKING', 'REQUEST', 'ORDER', 'TRIP']);
    expect(profile.requestHistory[1]).toMatchObject({ id: 'req-test-1', title: 'Extra towels', status: 'Requested', open: true });
    expect(profile.preferences).toHaveProperty('pillow');
  });
});
