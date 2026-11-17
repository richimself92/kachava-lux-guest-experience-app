import { Trip } from '../../src/domain/trips/trip.models';

const AT = '2026-11-20T10:00:00.000Z';

/** Neutral test-only trip (an arrival requested by the guest); exists only under test/. */
export function tripFixture(overrides: Partial<Trip> = {}): Trip {
  return {
    tripId: 'trip-1',
    stayId: 'stay-test-1',
    villaId: 'villa-a',
    villaName: 'Test Villa',
    guestName: 'Test Guest',
    serviceId: 'svc-transfer',
    itemId: null,
    snapshot: null,
    type: 'ARRIVAL',
    airportCode: 'AAA',
    flight: { airline: 'Test Air', number: 'TA 100', scheduledAt: '2026-12-01T19:30:00.000Z' },
    pickupAt: '2026-12-01T19:30:00.000Z',
    origin: null,
    destination: null,
    roundTrip: false,
    waitMinutes: null,
    passengers: 2,
    luggage: 2,
    guestNotes: '',
    notes: '',
    providerId: null,
    driver: null,
    vehicle: null,
    status: 'REQUESTED',
    cancellationReason: null,
    createdBy: 'GUEST',
    statusHistory: [{ from: null, to: 'REQUESTED', at: AT, by: 'guest:stay-test-1', reason: null }],
    createdAt: AT,
    createdByActor: 'guest:stay-test-1',
    updatedAt: AT,
    updatedBy: 'guest:stay-test-1',
    ...overrides,
  };
}
