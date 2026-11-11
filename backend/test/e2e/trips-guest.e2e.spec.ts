import request from 'supertest';
import { storedAlerts } from '../support/stored-alerts';
import { FakeFirestore } from '../support/fake-firestore';
import { createTestApp, TestApp } from '../support/test-app';
import {
  arrivalBody,
  createTransportService,
  createVehicle,
  FixedClock,
  patchSettings,
  setUpTripWorld,
  TripWorld,
} from '../support/trip-setup';
import { createVillaAndStay } from '../support/test-app';

const ADMIN = '/api/v1/admin';

describe('Guest trips (POST/GET /stays/:guestUuid/trips)', () => {
  let t: TestApp;
  let w: TripWorld;

  beforeEach(async () => {
    t = await createTestApp(new FakeFirestore(), { clock: new FixedClock() });
    w = await setUpTripWorld(t);
  });

  afterEach(() => t.close());

  const post = (body: Record<string, unknown>) => request(t.server()).post(w.guestPath).send(body);

  describe('creation', () => {
    it('test_guestArrival_withVan_isRequestedAtLandingWithSnapshot', async () => {
      const res = await post(arrivalBody(w.serviceId, { itemId: w.vanId, guestNotes: 'child seat' }));

      expect(res.status).toBe(201);
      expect(res.body.data).toMatchObject({
        type: 'ARRIVAL', status: 'REQUESTED', createdBy: 'GUEST', airportCode: 'CUN', itemId: w.vanId,
        flight: { airline: 'Test Air', number: 'TA 123', scheduledAt: '2026-12-01T19:30:00.000Z' },
        pickupAt: '2026-12-01T19:30:00.000Z', passengers: 2, luggage: 2, guestNotes: 'child seat',
        snapshot: {
          serviceId: w.serviceId, serviceName: { en: 'Airport transfer', es: 'Traslado aeropuerto' },
          pricingMode: 'FIXED', totalUSD: 95, vehicleCapacity: { passengers: 4, luggage: 4 },
          lines: [expect.objectContaining({ itemId: w.vanId, name: { en: 'Van', es: 'Camioneta' }, unitPriceUSD: 95 })],
        },
      });
      expect(res.body.data.id).toEqual(expect.any(String));
    });

    it('test_guestDeparture_pickupIsFlightMinusAirportBuffer', async () => {
      const res = await post(arrivalBody(w.serviceId, {
        type: 'DEPARTURE', flight: { airline: 'Test Air', number: 'TA 9', scheduledAt: '2026-12-04T12:00:00-05:00' },
      }));

      expect(res.status).toBe(201);
      expect(res.body.data.pickupAt).toBe('2026-12-04T14:00:00.000Z');
    });

    it('test_guestLocalTrip_usesItsOwnPickupInResortTime', async () => {
      const res = await post({
        serviceId: w.serviceId, type: 'LOCAL', pickupAt: '2026-12-02T19:00', origin: 'Villa', destination: 'Town',
        roundTrip: true, waitMinutes: 60, passengers: 2,
      });

      expect(res.status).toBe(201);
      expect(res.body.data).toMatchObject({ pickupAt: '2026-12-03T00:00:00.000Z', roundTrip: true, waitMinutes: 60, luggage: 0 });
    });

    it('test_guestCannotSetStaffOnlyFields', async () => {
      const res = await post(arrivalBody(w.serviceId, {
        notes: 'sneaky', providerId: w.providerId, status: 'CONFIRMED', createdBy: 'STAFF', stayId: 'other-stay',
      }));

      const stored = await request(t.server()).get(`${ADMIN}/trips/${res.body.data.id}`).set(await t.adminHeaders());

      expect(res.status).toBe(201);
      expect(stored.body.data).toMatchObject({
        notes: '', providerId: null, status: 'REQUESTED', createdBy: 'GUEST', stayId: w.stay.stayId,
      });
    });

    it('test_guestCreation_raisesHighTransferAlertTargetingTheTrip', async () => {
      const created = await post(arrivalBody(w.serviceId));

      const alerts = storedAlerts(t.fake, 'TRANSFER');

      expect(alerts).toHaveLength(1);
      expect(alerts[0]).toMatchObject({
        category: 'TRANSFER', severity: 'HIGH', stayId: w.stay.stayId, assignedDepartment: 'TRANSPORT',
        targetRef: { type: 'TRIP', id: created.body.data.id }, sourceDocumentPath: `trips/${created.body.data.id}`,
      });
    });
  });

  describe('validation', () => {
    it('test_tooLittleLeadTime_is422', async () => {
      const res = await post(arrivalBody(w.serviceId, {
        flight: { airline: 'Test Air', number: 'TA 1', scheduledAt: '2026-11-21T06:00' },
      }));

      expect(res.status).toBe(422);
      expect(res.body.message).toContain('at least 24 hours');
    });

    it('test_overVehicleCapacity_is422', async () => {
      const res = await post(arrivalBody(w.serviceId, { itemId: w.vanId, passengers: 5, luggage: 6 }));

      expect(res.status).toBe(422);
      expect(res.body.message).toContain('passengers exceed the vehicle capacity of 4');
      expect(res.body.message).toContain('luggage exceeds the vehicle capacity of 4');
    });

    it('test_inactiveAirport_is422WithoutSettingsCode', async () => {
      const res = await post(arrivalBody(w.serviceId, { airportCode: 'TQO' }));

      expect(res.status).toBe(422);
      expect(res.body.code).toBeUndefined();
      expect(res.body.message).toContain('TQO is not active');
    });

    it('test_unconfiguredAirport_is422SettingsRequired', async () => {
      const res = await post(arrivalBody(w.serviceId, { airportCode: 'MEX' }));

      expect(res.status).toBe(422);
      expect(res.body).toMatchObject({ code: 'SETTINGS_REQUIRED', details: ['airports.MEX'] });
    });

    it('test_guestPickupForAirportTrip_isRejected', async () => {
      const res = await post(arrivalBody(w.serviceId, { pickupAt: '2026-12-01T10:00' }));

      expect(res.status).toBe(422);
      expect(res.body.message).toContain('pickupAt');
    });

    it('test_airportTripWithoutFlight_is422', async () => {
      const res = await post(arrivalBody(w.serviceId, { flight: undefined }));

      expect(res.status).toBe(422);
      expect(res.body.message).toContain('flight is required for ARRIVAL trips');
    });

    it('test_disabledOrNonTransportOrUnknownService_isRejected', async () => {
      const disabled = await createTransportService(t, { status: 'DISABLED' });
      const experience = await createTransportService(t, {
        kind: 'EXPERIENCE', section: 'EXPERIENCES', usageType: 'BOOKING', transport: undefined,
      });

      const statuses = [
        (await post(arrivalBody(disabled))).status,
        (await post(arrivalBody(experience))).status,
        (await post(arrivalBody('no-such-service'))).status,
      ];

      expect(statuses).toEqual([422, 422, 404]);
    });

    it('test_vehicleOfAnotherService_is404', async () => {
      const other = await createTransportService(t);
      const foreignVan = await createVehicle(t, other);

      expect((await post(arrivalBody(w.serviceId, { itemId: foreignVan }))).status).toBe(404);
    });

    it.each([
      { type: 'BOAT' },
      { passengers: 0 },
      { flight: { airline: 'A', number: '1', scheduledAt: '01/12/2026 14:30' } },
      { airportCode: 'cun' },
    ])('test_malformedBody_%j_is400', async (override) => {
      expect((await post(arrivalBody(w.serviceId, override))).status).toBe(400);
    });
  });

  describe('guest-safe listing', () => {
    it('test_list_hidesInternalNotesProviderAndHistory_butShowsDriver', async () => {
      const created = await post(arrivalBody(w.serviceId));
      const id = created.body.data.id;
      const admin = await t.adminHeaders();
      await request(t.server()).patch(`${ADMIN}/trips/${id}`).set(admin).send({ notes: 'INTERNAL-ONLY note' });
      await request(t.server()).post(`${ADMIN}/trips/${id}/transition`).set(admin)
        .send({ to: 'SENT_TO_PROVIDER', providerId: w.providerId });
      await request(t.server()).post(`${ADMIN}/trips/${id}/transition`).set(admin)
        .send({ to: 'CONFIRMED', driver: { name: 'Test Driver', phone: '+52 200' }, vehicle: { description: 'White van', plate: 'TST-1' } });

      const res = await request(t.server()).get(w.guestPath);

      expect(res.status).toBe(200);
      expect(res.body.data).toHaveLength(1);
      expect(res.body.data[0]).toMatchObject({
        id, status: 'CONFIRMED', driver: { name: 'Test Driver', phone: '+52 200' }, vehicle: { description: 'White van', plate: 'TST-1' },
      });
      for (const hidden of ['notes', 'providerId', 'statusHistory', 'createdByActor', 'updatedBy']) {
        expect(res.body.data[0]).not.toHaveProperty(hidden);
      }
      const raw = JSON.stringify(res.body);
      expect(raw).not.toContain('INTERNAL-ONLY');
      expect(raw).not.toContain(w.providerEmail);
      expect(raw).not.toContain('staff-only instruction');
    });

    it('test_list_onlyReturnsTheGuestsOwnTrips_byPickup', async () => {
      const other = await createVillaAndStay(t, { villaName: 'Villa 4', guestName: 'Other Guest' });
      await request(t.server()).post(`/api/v1/stays/${other.guestTokenUuid}/trips`).send(arrivalBody(w.serviceId));
      await post(arrivalBody(w.serviceId, { type: 'DEPARTURE', flight: { airline: 'A', number: 'TA 2', scheduledAt: '2026-12-04T12:00' } }));
      await post(arrivalBody(w.serviceId));

      const res = await request(t.server()).get(w.guestPath);

      expect(res.body.data.map((trip: { type: string }) => trip.type)).toEqual(['ARRIVAL', 'DEPARTURE']);
    });

    it('test_unknownGuestToken_is401', async () => {
      const res = await request(t.server()).get('/api/v1/stays/22222222-2222-4222-8222-222222222222/trips');

      expect(res.status).toBe(401);
    });
  });
});

describe('Guest trips when Settings are incomplete', () => {
  let t: TestApp;

  beforeEach(async () => {
    t = await createTestApp(new FakeFirestore(), { clock: new FixedClock() });
  });

  afterEach(() => t.close());

  it('test_noAirportsConfigured_is422SettingsRequired', async () => {
    const stay = await createVillaAndStay(t, { villaName: 'Villa 3', guestName: 'Ana Test' });
    const serviceId = await createTransportService(t, { transport: { airportCodes: [] } });

    const res = await request(t.server()).post(`/api/v1/stays/${stay.guestTokenUuid}/trips`).send(arrivalBody(serviceId));

    expect(res.status).toBe(422);
    expect(res.body).toMatchObject({ code: 'SETTINGS_REQUIRED', details: ['airports.CUN'] });
  });

  it('test_localWallTimeWithoutTimeZone_is422SettingsRequired', async () => {
    await patchSettings(t, { airports: [{ code: 'CUN', name: 'Test Airport CUN', departureBufferHours: 3 }] });
    const stay = await createVillaAndStay(t, { villaName: 'Villa 3', guestName: 'Ana Test' });
    // Reservations need the zone; clear it afterwards to exercise the trip rule.
    await patchSettings(t, { timeZone: null });
    const serviceId = await createTransportService(t, { transport: { airportCodes: ['CUN'] } });

    const res = await request(t.server()).post(`/api/v1/stays/${stay.guestTokenUuid}/trips`).send(arrivalBody(serviceId));

    expect(res.status).toBe(422);
    expect(res.body).toMatchObject({ code: 'SETTINGS_REQUIRED', details: ['timeZone'] });
  });
});
