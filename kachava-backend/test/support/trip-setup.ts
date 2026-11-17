import request from 'supertest';
import { ClockPort } from '../../src/domain/ports/clock.port';
import { CreatedStay, createVillaAndStay, TestApp } from './test-app';

const ADMIN = '/api/v1/admin';

/** "Now" for trip e2e tests: 2026-11-20 07:00 at the resort (America/Cancun, UTC-5). */
export const TRIP_NOW = new Date('2026-11-20T12:00:00.000Z');

export class FixedClock implements ClockPort {
  constructor(public current: Date = TRIP_NOW) {}

  now(): Date {
    return new Date(this.current);
  }
}

/** CUN active (3 h departure buffer), TQO configured but inactive, 12 h alert lead time. */
export const TRANSPORT_SETTINGS = {
  timeZone: 'America/Cancun',
  airports: [
    { code: 'CUN', name: 'Test Airport CUN', departureBufferHours: 3 },
    { code: 'TQO', name: 'Test Airport TQO', departureBufferHours: 2, isActive: false },
  ],
  transportAlertLeadHours: 12,
};

export interface TripWorld {
  stay: CreatedStay;
  guestPath: string;
  serviceId: string;
  vanId: string;
  providerId: string;
  providerEmail: string;
}

export async function patchSettings(t: TestApp, body: Record<string, unknown>): Promise<void> {
  const res = await request(t.server()).patch(`${ADMIN}/settings`).set(await t.adminHeaders()).send(body);
  if (res.status !== 200) throw new Error(`settings: ${res.status} ${JSON.stringify(res.body)}`);
}

/** An ACTIVE transport service (FIXED $80 per trip, 24 h minimum lead time) unless overridden. */
export async function createTransportService(t: TestApp, overrides: Record<string, unknown> = {}): Promise<string> {
  const res = await request(t.server()).post(`${ADMIN}/services`).set(await t.adminHeaders()).send({
    kind: 'TRANSPORT', section: 'TRANSPORTATION', usageType: 'TRIP',
    name: { en: 'Airport transfer', es: 'Traslado aeropuerto' },
    shortDescription: { en: 'Short', es: 'Corta' },
    cover: { storagePath: 'catalog/services/cover.jpg' },
    status: 'ACTIVE',
    pricing: { mode: 'FIXED', amount: 80, chargeToFolio: true },
    availability: { minLeadHours: 24 },
    transport: { airportCodes: ['CUN', 'TQO'], priceBasis: 'PER_VEHICLE' },
    operation: { internalInstructions: 'staff-only instruction' },
    ...overrides,
  });
  if (res.status !== 201) throw new Error(`service: ${res.status} ${JSON.stringify(res.body)}`);
  return res.body.data.id;
}

export async function createVehicle(t: TestApp, serviceId: string, capacity = { passengers: 4, luggage: 4 }): Promise<string> {
  const res = await request(t.server()).post(`${ADMIN}/services/${serviceId}/items`).set(await t.adminHeaders())
    .send({ name: { en: 'Van', es: 'Camioneta' }, priceUSD: 95, status: 'ACTIVE', capacity });
  if (res.status !== 201) throw new Error(`item: ${res.status} ${JSON.stringify(res.body)}`);
  return res.body.data.id;
}

export async function createProvider(t: TestApp, body: Record<string, unknown>): Promise<string> {
  const res = await request(t.server()).post(`${ADMIN}/transport-providers`).set(await t.adminHeaders()).send(body);
  if (res.status !== 201) throw new Error(`provider: ${res.status} ${JSON.stringify(res.body)}`);
  return res.body.data.id;
}

/** Settings, one stay (guest "Ana Test"), a transport service with a 4-seat van and a provider. */
export async function setUpTripWorld(t: TestApp): Promise<TripWorld> {
  await patchSettings(t, TRANSPORT_SETTINGS);
  const stay = await createVillaAndStay(t, { villaName: 'Villa 3', guestName: 'Ana Test' });
  const serviceId = await createTransportService(t);
  const vanId = await createVehicle(t, serviceId);
  const providerEmail = 'dispatch@provider.test';
  const providerId = await createProvider(t, { name: 'Test Transfers', phone: '+52 100', email: providerEmail });
  return { stay, guestPath: `/api/v1/stays/${stay.guestTokenUuid}/trips`, serviceId, vanId, providerId, providerEmail };
}

/** Arrival on 2026-12-01 14:30 resort time (19:30 UTC) at CUN. */
export function arrivalBody(serviceId: string, overrides: Record<string, unknown> = {}): Record<string, unknown> {
  return {
    serviceId,
    type: 'ARRIVAL',
    airportCode: 'CUN',
    flight: { airline: 'Test Air', number: 'TA 123', scheduledAt: '2026-12-01T14:30' },
    passengers: 2,
    luggage: 2,
    ...overrides,
  };
}
