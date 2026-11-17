import { BusinessRuleError, EntityNotFoundError } from '../../src/domain/domain-errors';
import { LarderOrderItem, StayAggregate } from '../../src/domain/models/domain.models';
import {
  cancelGuestBooking,
  changeGuestBooking,
  isStayPhotoPath,
  replaceServiceOrder,
  resizeSnapshotParty,
  setJourneyMarks,
} from '../../src/domain/stays/guest-request-rules';
import { populatedStayFixture } from '../support/stay-fixtures';

const AT = '2026-12-02T12:00:00.000Z';

function orderLine(stay: StayAggregate, serviceId: string, itemId: string, total: number): LarderOrderItem {
  return {
    ...structuredClone(stay.larderOrders[0]),
    orderItemId: `larder_${stay.stayId}_${itemId}`,
    serviceId,
    catalogItemId: itemId,
    lineTotalUSD: total,
    createdAt: '2026-12-01T09:00:00.000Z',
    updatedAt: '2026-12-01T09:00:00.000Z',
  };
}

describe('guest booking cancel/change (only while REQUESTED)', () => {
  it('test_cancel_requestedBooking_isCancelledAndItsFolioLineRemoved', () => {
    const stay = populatedStayFixture();

    const cancelled = cancelGuestBooking(stay, 'bk-test-1', AT);

    expect(cancelled).toMatchObject({ status: 'CANCELLED', cancellationReason: 'Cancelled by guest', updatedAt: AT });
    expect(stay.experienceBookings[0].status).toBe('CANCELLED');
    expect(stay.folioItems.some((item) => item.sourceRefId === 'bk-test-1')).toBe(false);
    expect(stay.folioSummary.incidentalsSubtotalUSD).toBe(0);
  });

  it.each(['CONFIRMED', 'IN_PREPARATION', 'COMPLETED', 'CANCELLED'] as const)(
    'test_cancel_%sBooking_isABusinessRuleError',
    (status) => {
      const stay = populatedStayFixture();
      stay.experienceBookings[0].status = status;

      expect(() => cancelGuestBooking(stay, 'bk-test-1', AT)).toThrow(BusinessRuleError);
    },
  );

  it('test_cancel_unknownBooking_isNotFound', () => {
    expect(() => cancelGuestBooking(populatedStayFixture(), 'bk-missing', AT)).toThrow(EntityNotFoundError);
  });

  it('test_change_dateTimeAndParty_repricesFromTheSnapshotAndTheFolioLine', () => {
    const stay = populatedStayFixture();

    const changed = changeGuestBooking(
      stay, 'bk-test-1', { scheduledDate: '2026-12-04', scheduledTimeSlot: '16:00', partySize: 3 }, AT,
    );

    expect(changed).toMatchObject({
      scheduledDate: '2026-12-04', scheduledTimeSlot: '16:00', partySize: 3, status: 'REQUESTED',
      priceChargedUSD: 30, originalValuationUSD: 30, updatedAt: AT,
    });
    expect(changed.snapshot.totalUSD).toBe(30);
    expect(changed.snapshot.lines[0].unitPriceUSD).toBe(10);
    const line = stay.folioItems.find((item) => item.sourceRefId === 'bk-test-1');
    expect(line).toMatchObject({ chargedAmountUSD: 30, subtitle: '2026-12-04 · 16:00' });
    expect(stay.folioSummary.incidentalsSubtotalUSD).toBe(30);
  });

  it('test_change_confirmedBooking_isABusinessRuleError', () => {
    const stay = populatedStayFixture();
    stay.experienceBookings[0].status = 'CONFIRMED';

    expect(() => changeGuestBooking(stay, 'bk-test-1', { partySize: 1 }, AT)).toThrow(BusinessRuleError);
  });

  it('test_change_preferenceChoice_isABusinessRuleError', () => {
    const stay = populatedStayFixture();
    stay.experienceBookings[0].usageType = 'PREFERENCE';

    expect(() => changeGuestBooking(stay, 'bk-test-1', { partySize: 1 }, AT)).toThrow(BusinessRuleError);
  });
});

describe('resizeSnapshotParty', () => {
  it('test_perPerson_scalesLineTotals_otherModesAreUnchanged', () => {
    const stay = populatedStayFixture();
    const perPerson = stay.experienceBookings[0].snapshot;
    const fixed = { ...structuredClone(perPerson), pricingMode: 'FIXED' as const };

    expect(resizeSnapshotParty(perPerson, 4).totalUSD).toBe(40);
    expect(resizeSnapshotParty(fixed, 4)).toEqual(fixed);
  });
});

describe('replaceServiceOrder (one ORDER service never erases another)', () => {
  it('test_replace_keepsOtherServicesLines_andChargesPerService', () => {
    const stay = populatedStayFixture({ folioItems: [] });
    stay.larderOrders = [orderLine(stay, 'svc-a', 'item-a', 10), orderLine(stay, 'svc-b', 'item-b', 6)];
    const fresh = [{ ...orderLine(stay, 'svc-a', 'item-c', 4), createdAt: undefined }];

    const result = replaceServiceOrder(stay, 'svc-a', fresh, { title: 'Bar', chargeToFolio: true }, AT);

    expect(result.orders.map((o) => o.catalogItemId).sort()).toEqual(['item-b', 'item-c']);
    const replaced = result.orders.find((o) => o.catalogItemId === 'item-c');
    expect(replaced).toMatchObject({ createdAt: '2026-12-01T09:00:00.000Z', updatedAt: AT });
    expect(stay.folioItems).toEqual([
      expect.objectContaining({ folioItemId: 'folio_order_svc-a', category: 'LARDER', title: 'Bar', chargedAmountUSD: 4 }),
    ]);
    expect(result.folioSummary.incidentalsSubtotalUSD).toBe(4);
  });

  it('test_replace_firstOrderOfAService_isCreatedNow', () => {
    const stay = populatedStayFixture({ larderOrders: [], folioItems: [] });

    const result = replaceServiceOrder(
      stay, 'svc-a', [{ ...orderLine(stay, 'svc-a', 'item-a', 5), createdAt: undefined }],
      { title: 'Bar', chargeToFolio: true }, AT,
    );

    expect(result.orders[0]).toMatchObject({ createdAt: AT, updatedAt: AT });
  });

  it('test_replace_withNoLines_removesOnlyThatServicesFolioLine', () => {
    const stay = populatedStayFixture({ folioItems: [] });
    stay.larderOrders = [orderLine(stay, 'svc-a', 'item-a', 10), orderLine(stay, 'svc-b', 'item-b', 6)];
    replaceServiceOrder(stay, 'svc-b', [orderLine(stay, 'svc-b', 'item-b', 6)], { title: 'Wine', chargeToFolio: true }, AT);

    replaceServiceOrder(stay, 'svc-a', [], { title: 'Bar', chargeToFolio: true }, AT);

    expect(stay.larderOrders.map((o) => o.serviceId)).toEqual(['svc-b']);
    expect(stay.folioItems.map((i) => i.folioItemId)).toEqual(['folio_order_svc-b']);
    expect(stay.folioSummary.incidentalsSubtotalUSD).toBe(6);
  });

  it('test_replace_notChargedToFolio_addsNoFolioLine', () => {
    const stay = populatedStayFixture({ larderOrders: [], folioItems: [] });

    replaceServiceOrder(stay, 'svc-a', [orderLine(stay, 'svc-a', 'item-a', 5)], { title: 'Bar', chargeToFolio: false }, AT);

    expect(stay.folioItems).toEqual([]);
  });

  it('test_replace_legacySingleLarderLine_keepsChargingTheOtherServicesLines', () => {
    const stay = populatedStayFixture();
    const legacyLine = (serviceId: string, itemId: string, total: number) =>
      ({ ...orderLine(stay, serviceId, itemId, total), createdAt: undefined });
    stay.larderOrders = [legacyLine('svc-a', 'item-a', 10), legacyLine('svc-b', 'item-b', 6)];
    stay.folioItems = [{
      folioItemId: 'folio-4', displayOrder: 1, title: 'Old cart', subtitle: '2 items', category: 'LARDER',
      badgeLabel: null, isComplimentary: false, originalValuationUSD: 16, chargedAmountUSD: 16,
      status: 'PRE_AUTHORIZED', sourceRefId: 'larder-cart', createdAt: AT,
    }];

    replaceServiceOrder(stay, 'svc-a', [legacyLine('svc-a', 'item-a', 12)], { title: 'Bar', chargeToFolio: true }, AT);

    const legacy = stay.folioItems.find((i) => i.folioItemId === 'folio-4');
    expect(legacy).toMatchObject({ chargedAmountUSD: 6, originalValuationUSD: 6 });
    expect(stay.folioSummary.incidentalsSubtotalUSD).toBe(18);
  });
});

describe('setJourneyMarks', () => {
  it('test_marks_replaceOnlyTheGivenLists_withoutDuplicates', () => {
    const stay = populatedStayFixture({ skippedTaskIds: ['1:core:flight'], completedTaskIds: ['core:departure'] });

    const marks = setJourneyMarks(stay, { skippedTaskIds: ['2:section:DINING', '2:section:DINING'] }, AT);

    expect(marks).toEqual({ skippedTaskIds: ['2:section:DINING'], completedTaskIds: ['core:departure'] });
    expect(stay.skippedTaskIds).toEqual(['2:section:DINING']);
    expect(stay.updatedAt).toBe(AT);
  });

  it('test_marks_absentOnAnOlderStay_areEmptyLists', () => {
    expect(setJourneyMarks(populatedStayFixture(), {}, AT)).toEqual({ skippedTaskIds: [], completedTaskIds: [] });
  });
});

describe('isStayPhotoPath', () => {
  it.each([
    ['/private/stays/stay-test-1/concierge/req_1/a.jpg', true],
    ['private/stays/stay-test-1/concierge/req_1/a.jpg', true],
    ['/private/stays/other-stay/concierge/req_1/a.jpg', false],
    ['/private/stays/stay-test-1/concierge/../../other/a.jpg', false],
    ['/catalog/services/a.jpg', false],
    ['/private/stays/stay-test-1/concierge/', false],
  ])('test_%s_is%s', (path, expected) => {
    expect(isStayPhotoPath('stay-test-1', path)).toBe(expected);
  });
});
