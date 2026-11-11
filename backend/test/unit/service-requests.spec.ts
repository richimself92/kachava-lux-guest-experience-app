import { BusinessRuleError, EntityNotFoundError } from '../../src/domain/domain-errors';
import { orderFolioItemId } from '../../src/domain/folio-ledger';
import { LarderOrderItem, StayAggregate } from '../../src/domain/models/domain.models';
import { applyRequestTransition, RequestAction } from '../../src/domain/requests/request-transitions';
import {
  bookingRequestStatus,
  orderRequestStatus,
  projectServiceRequests,
} from '../../src/domain/requests/service-requests';
import { resortWallTime } from '../../src/domain/time/zoned-time';
import { phraseKeywords } from '../../src/infrastructure/repositories/firestore-service-request.repository';
import { populatedStayFixture } from '../support/stay-fixtures';

const AT = '2026-12-02T15:00:00.000Z';
const ZONE = 'America/Cancun';

function barStay(): StayAggregate {
  const stay = populatedStayFixture();
  const line = (itemId: string, quantity: number): LarderOrderItem => ({
    ...structuredClone(stay.larderOrders[0]),
    orderItemId: `larder_${stay.stayId}_${itemId}`,
    serviceId: 'svc-bar',
    section: 'DINING',
    serviceName: { en: 'Lux bar', es: 'Bar Lux' },
    catalogItemId: itemId,
    quantity,
    lineTotalUSD: quantity * 5,
    createdAt: '2026-12-02T02:30:00.000Z',
    updatedAt: '2026-12-02T02:30:00.000Z',
  });
  stay.larderOrders = [line('mojito', 2), line('water', 3)];
  stay.folioItems.push({
    folioItemId: orderFolioItemId('svc-bar'), displayOrder: 2, title: 'Lux bar', subtitle: '2 items',
    category: 'LARDER', badgeLabel: null, isComplimentary: false, originalValuationUSD: 25,
    chargedAmountUSD: 25, status: 'PRE_AUTHORIZED', sourceRefId: 'svc-bar', createdAt: AT,
  });
  return stay;
}

describe('request queue projection', () => {
  it('test_booking_becomesAReceivedEntryAtItsResortSlotWithItsParty', () => {
    const [entry] = projectServiceRequests(populatedStayFixture(), null);

    expect(entry).toMatchObject({
      requestId: 'bk-test-1', kind: 'BOOKING', section: 'EXPERIENCES', guestName: 'Test Guest',
      villaName: 'Test Villa', serviceName: { en: 'Test service', es: 'Servicio de prueba' },
      at: '2026-12-03T10:00', quantity: 2, status: 'RECEIVED', open: true, totalUSD: 20, cancellationReason: null,
    });
  });

  it('test_orderLinesOfOneService_becomeOneEntryAtTheResortTimeTheOrderWasPlaced', () => {
    const entries = projectServiceRequests(barStay(), ZONE);

    const order = entries.find((e) => e.kind === 'ORDER');
    expect(entries).toHaveLength(2);
    expect(order).toMatchObject({
      requestId: 'stay-test-1_svc-bar', serviceId: 'svc-bar', section: 'DINING',
      serviceName: { en: 'Lux bar', es: 'Bar Lux' }, at: '2026-12-01T21:30', quantity: 5, totalUSD: 25,
      status: 'RECEIVED',
    });
    expect(order?.lines).toEqual([
      { name: { en: 'Test item', es: 'Artículo de prueba' }, quantity: 2 },
      { name: { en: 'Test item', es: 'Artículo de prueba' }, quantity: 3 },
    ]);
  });

  it('test_olderOrderLineWithoutSection_hasNoSection', () => {
    const order = projectServiceRequests(populatedStayFixture(), ZONE).find((e) => e.kind === 'ORDER');

    expect(order?.section).toBeNull();
  });

  it.each([
    ['REQUESTED', 'RECEIVED'], ['MODIFICATION_REQUESTED', 'RECEIVED'], ['CONFIRMED', 'CONFIRMED'],
    ['IN_PREPARATION', 'PREPARING'], ['COMPLETED', 'DONE'], ['CANCELLED', 'CANCELLED'],
  ] as const)('test_bookingStatus_%s_readsAs_%s', (raw, expected) => {
    expect(bookingRequestStatus(raw)).toBe(expected);
  });

  it.each([
    ['Pending', 'RECEIVED'], ['Confirmed', 'CONFIRMED'], ['Preparing', 'PREPARING'],
    ['In progress', 'PREPARING'], ['Delivered', 'DONE'], ['Completed', 'DONE'], ['Cancelled', 'CANCELLED'],
  ])('test_orderStatus_%s_readsAs_%s', (raw, expected) => {
    expect(orderRequestStatus(raw)).toBe(expected);
  });

  it('test_resortWallTime_readsTheInstantOnTheResortClock', () => {
    expect(resortWallTime(new Date('2026-12-02T02:30:00.000Z'), ZONE)).toBe('2026-12-01T21:30');
  });

  it('test_searchKeywords_holdWordAndPhrasePrefixesWithoutAccents', () => {
    expect(phraseKeywords('Ána Ruiz')).toEqual(expect.arrayContaining(['a', 'an', 'ana', 'ana r', 'ru', 'ruiz']));
  });
});

describe('request queue transitions', () => {
  const move = (action: RequestAction, reason?: string) => ({ action, reason, at: AT });

  it.each([
    ['CONFIRM', 'CONFIRMED'], ['START', 'IN_PREPARATION'],
  ] as const)('test_%s_onAReceivedBooking_setsItsStatus', (action, expected) => {
    const stay = populatedStayFixture();

    applyRequestTransition(stay, { kind: 'BOOKING', id: 'bk-test-1' }, move(action));

    expect(stay.experienceBookings[0]).toMatchObject({ status: expected, updatedAt: AT });
  });

  it('test_complete_afterConfirm_isDone', () => {
    const stay = populatedStayFixture();
    applyRequestTransition(stay, { kind: 'BOOKING', id: 'bk-test-1' }, move('CONFIRM'));

    applyRequestTransition(stay, { kind: 'BOOKING', id: 'bk-test-1' }, move('COMPLETE'));

    expect(stay.experienceBookings[0].status).toBe('COMPLETED');
  });

  it('test_cancel_withReason_cancelsTheBookingAndDropsItsFolioCharge', () => {
    const stay = populatedStayFixture();

    applyRequestTransition(stay, { kind: 'BOOKING', id: 'bk-test-1' }, move('CANCEL', ' Weather '));

    expect(stay.experienceBookings[0]).toMatchObject({ status: 'CANCELLED', cancellationReason: 'Weather' });
    expect(stay.folioItems.some((item) => item.sourceRefId === 'bk-test-1')).toBe(false);
  });

  it('test_cancel_withoutReason_isABusinessRuleError', () => {
    const stay = populatedStayFixture();

    expect(() => applyRequestTransition(stay, { kind: 'BOOKING', id: 'bk-test-1' }, move('CANCEL', ' ')))
      .toThrow(BusinessRuleError);
    expect(stay.experienceBookings[0].status).toBe('REQUESTED');
  });

  it.each(['CONFIRM', 'START', 'COMPLETE', 'CANCEL'] as const)('test_%s_onADoneBooking_isRefused', (action) => {
    const stay = populatedStayFixture();
    stay.experienceBookings[0].status = 'COMPLETED';

    expect(() => applyRequestTransition(stay, { kind: 'BOOKING', id: 'bk-test-1' }, move(action, 'x')))
      .toThrow(BusinessRuleError);
  });

  it('test_complete_onAReceivedBooking_isRefused', () => {
    expect(() => applyRequestTransition(populatedStayFixture(), { kind: 'BOOKING', id: 'bk-test-1' }, move('COMPLETE')))
      .toThrow(BusinessRuleError);
  });

  it('test_unknownRequest_isNotFound', () => {
    expect(() => applyRequestTransition(populatedStayFixture(), { kind: 'ORDER', id: 'svc-none' }, move('CONFIRM')))
      .toThrow(EntityNotFoundError);
  });

  it('test_orderMoves_setEveryLineOfThatServiceToTheGuestWord', () => {
    const stay = barStay();

    applyRequestTransition(stay, { kind: 'ORDER', id: 'svc-bar' }, move('START'));

    expect(stay.larderOrders.map((l) => l.provisioningStatus)).toEqual(['Preparing', 'Preparing']);
    expect(projectServiceRequests(stay, ZONE).find((e) => e.kind === 'ORDER')?.status).toBe('PREPARING');
  });

  it('test_orderCancel_keepsTheReasonAndDropsTheOrderCharge', () => {
    const stay = barStay();

    applyRequestTransition(stay, { kind: 'ORDER', id: 'svc-bar' }, move('CANCEL', 'Out of stock'));

    const order = projectServiceRequests(stay, ZONE).find((e) => e.kind === 'ORDER');
    expect(order).toMatchObject({ status: 'CANCELLED', open: false, cancellationReason: 'Out of stock' });
    expect(stay.folioItems.some((item) => item.folioItemId === orderFolioItemId('svc-bar'))).toBe(false);
  });
});
