import {
  toGuestBookingView,
  toGuestConciergeRequestView,
  toGuestFolioView,
  toGuestStayView,
} from '../../src/domain/guest-stay-view';
import { StayAggregate } from '../../src/domain/models/domain.models';
import { createSeededStayAggregate } from '../../src/infrastructure/seed/sanctuary-seed.data';
import { collectKeys, forbiddenKeysIn } from '../support/guest-view-assertions';

function seededStay(): StayAggregate {
  const stay = createSeededStayAggregate();
  stay.flightTransfer.adminDispatchNotes = 'VIP: meet at gate B';
  stay.flightTransfer.meetingPoint = 'FBO Private Terminal Gate B';
  stay.personalization.housekeepingCadence = 'Morning (09:00 - 11:00)';
  stay.folioSummary.approvedByStaffId = 'staff_eduardo';
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
      villaName: 'Villa 102',
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
    expect(view.experienceBookings[0]).toHaveProperty('catalogRefId');
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
