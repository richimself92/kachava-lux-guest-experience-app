import {
  toGuestBookingView,
  toGuestConciergeRequestView,
  toGuestFolioView,
  toGuestLarderOrderView,
  toGuestStayView,
} from '../../src/domain/guest-stay-view';
import { StayAggregate } from '../../src/domain/models/domain.models';
import { collectKeys, forbiddenKeysIn } from '../support/guest-view-assertions';
import { populatedStayFixture } from '../support/stay-fixtures';

function seededStay(): StayAggregate {
  const stay = populatedStayFixture();
  stay.flightTransfer.adminDispatchNotes = 'VIP: meet at gate B';
  stay.flightTransfer.meetingPoint = 'FBO Private Terminal Gate B';
  stay.personalization.housekeepingCadence = 'Morning (09:00 - 11:00)';
  stay.folioSummary.approvedByStaffId = 'staff-internal';
  return stay;
}

describe('toGuestStayView (ADR-007 allow-list)', () => {
  it('test_toGuestStayView_seededStay_containsNoStaffOrInternalKeys', () => {
    const view = toGuestStayView(seededStay());

    expect(forbiddenKeysIn(view)).toEqual([]);
    expect(view).not.toHaveProperty('createdAt');
    expect(view).not.toHaveProperty('updatedAt');
    expect(view).not.toHaveProperty('stayId');
  });

  it('test_toGuestStayView_unknownNewStayField_isHiddenByDefault', () => {
    const stay = { ...seededStay(), housekeepingStatus: 'MAINTENANCE' } as StayAggregate;

    expect(collectKeys(toGuestStayView(stay)).has('housekeepingStatus')).toBe(false);
  });

  it('test_toGuestStayView_keepsEveryFieldTheGuestPortalRenders', () => {
    const view = toGuestStayView(seededStay());

    expect(view).toMatchObject({
      status: 'ACTIVE_STAY',
      villaName: 'Test Villa',
      suiteName: expect.any(String),
      stayDatesLabel: expect.any(String),
      nights: expect.any(Number),
      guestsCount: expect.any(Number),
      selectedSignaturePrivilege: expect.any(String),
      guestProfile: { name: expect.any(String), partner: expect.any(String) },
      hostInfo: { name: 'HOST ADMIN', role: 'HOST ADMIN' },
      villaAccess: { wifiSsid: expect.any(String), wifiPasscode: expect.any(String) },
    });
    expect(view.flightTransfer).toHaveProperty('flightNumber');
    expect(view.flightTransfer).toHaveProperty('meetingPoint');
    expect(view.personalization).toHaveProperty('housekeepingCadence');
    expect(view.larderOrders[0]).toHaveProperty('catalogItemId');
    expect(view.larderOrders[0]).toHaveProperty('provisioningStatus');
    expect(view.larderOrders[0]).toMatchObject({
      pricingUnit: 'ITEM', ozPerPortion: null, unitPriceUSD: 5, lineTotalUSD: 10, substitutionsAllowed: null, termsAcceptedAt: null,
    });
    expect(view.experienceBookings[0]).toHaveProperty('serviceId');
    expect(view.experienceBookings[0].snapshot.totalUSD).toBe(20);
    expect(view.experienceBookings[0]).toHaveProperty('scheduledTimeSlot');
    expect(view.conciergeRequests[0].messages[0]).toHaveProperty('text');
    expect(view.folioItems[0]).toHaveProperty('chargedAmountUSD');
    expect(view.folioSummary).toHaveProperty('finalSettledTotalUSD');
  });

  it('test_entityViews_bookingConciergeFolio_dropInternalFields', () => {
    const stay = seededStay();
    const views = [
      toGuestBookingView(stay.experienceBookings[0]),
      toGuestConciergeRequestView(stay.conciergeRequests[0]),
      toGuestFolioView(stay),
    ];

    expect(forbiddenKeysIn(views)).toEqual([]);
  });
});

describe('guest larder order lines: substitution answer and terms acceptance', () => {
  it('test_everyLineOfTheOrder_carriesTheAnswers', () => {
    const answers = { substitutionsAllowed: true, termsAcceptedAt: '2026-11-19T10:00:00.000Z' };
    const [first] = populatedStayFixture().larderOrders;
    const lines = [{ ...first, ...answers }, { ...first, orderItemId: 'larder-test-2', ...answers }];

    expect(lines.map(toGuestLarderOrderView)).toEqual([expect.objectContaining(answers), expect.objectContaining(answers)]);
  });
});
