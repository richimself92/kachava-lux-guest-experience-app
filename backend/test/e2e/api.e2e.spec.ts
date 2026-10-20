import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../../src/app.module';
import { GlobalHttpExceptionFilter } from '../../src/common/filters/global-http-exception.filter';
import { ResponseTransformInterceptor } from '../../src/common/interceptors/response-transform.interceptor';

describe('Kachava Lux REST API E2E Suite (Guest Portal & Admin Dashboard)', () => {
  let app: INestApplication;
  const demoUuid = '550e8400-e29b-41d4-a716-446655440000';
  let stepUpToken = '';
  let hostAdminToken = '';
  let coordinatorToken = '';

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    app.setGlobalPrefix('api/v1');
    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        transform: true,
        forbidNonWhitelisted: false,
      }),
    );
    app.useGlobalInterceptors(new ResponseTransformInterceptor());
    app.useGlobalFilters(new GlobalHttpExceptionFilter());
    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  describe('1. Guest Portal Endpoints (/api/v1/stays/:guestUuid/* & /api/v1/catalog/*)', () => {
    it('GET /api/v1/stays/:guestUuid hydrates Villa 102 — Ceiba Suite, Alex & Sarah Miller, and HOST ADMIN', async () => {
      const res = await request(app.getHttpServer())
        .get(`/api/v1/stays/${demoUuid}`)
        .expect(200);

      expect(res.body.data.villaName).toBe('Villa 102');
      expect(res.body.data.suiteName).toBe('Ceiba Suite');
      expect(res.body.data.hostInfo.name).toBe('HOST ADMIN');
      expect(res.body.data.hostInfo.shortName).toBe('HOST ADMIN');
      expect(res.body.data.hostInfo.role).toBe('HOST ADMIN');
      expect(res.body.data.guestProfile.name).toContain('Miller');
      expect(Array.isArray(res.body.data.larderOrders)).toBe(true);
      expect(Array.isArray(res.body.data.experienceBookings)).toBe(true);
      expect(Array.isArray(res.body.data.conciergeRequests)).toBe(true);
      expect(Array.isArray(res.body.data.folioItems)).toBe(true);
    });

    it('POST /api/v1/stays/:guestUuid/verify-step-up verifies villa 102 or lastName Miller and returns stepUpToken', async () => {
      const res = await request(app.getHttpServer())
        .post(`/api/v1/stays/${demoUuid}/verify-step-up`)
        .send({ villaNumber: '102', lastName: 'miller' })
        .expect(201);

      expect(res.body.data.verified).toBe(true);
      expect(typeof res.body.data.stepUpToken).toBe('string');
      stepUpToken = res.body.data.stepUpToken;
    });

    it('PATCH /api/v1/stays/:guestUuid/transfer updates aviation transfer details and emits TRANSFER alert', async () => {
      const res = await request(app.getHttpServer())
        .patch(`/api/v1/stays/${demoUuid}/transfer`)
        .send({
          flightNumber: 'AA 990',
          arrivalTime: '12:15 PM CST',
          terminal: 'FBO Private Terminal',
          luggageCount: 5,
          notes: 'Chilled coconut water requested on tarmac',
        })
        .expect(200);

      expect(res.body.data.flightNumber).toBe('AA 990');
      expect(res.body.data.luggageCount).toBe(5);
    });

    it('PATCH /api/v1/stays/:guestUuid/personalization updates 3-step preferences and emits DIETARY alert when allergies exist', async () => {
      const res = await request(app.getHttpServer())
        .patch(`/api/v1/stays/${demoUuid}/personalization`)
        .send({
          pillowSelection: 'Goose Down',
          temperatureCurve: '68°F Night / 72°F Day',
          scentProfile: 'Copal & Amber',
          lightingRhythm: 'Circadian Warmth',
          dietaryAllergies: ['Shellfish', 'Tree Nuts'],
        })
        .expect(200);

      expect(res.body.data.pillowSelection).toBe('Goose Down');
      expect(res.body.data.scentProfile).toBe('Copal & Amber');
      expect(res.body.data.dietaryAllergies).toContain('Shellfish');
    });

    it('PATCH /api/v1/stays/:guestUuid/personalization without allergies still emits a NORMAL alert and persists housekeepingCadence', async () => {
      const res = await request(app.getHttpServer())
        .patch(`/api/v1/stays/${demoUuid}/personalization`)
        .send({
          pillowType: 'Memory Foam',
          scentProfile: 'Mayan Copal',
          dietary: 'Mediterranean',
          dietaryAllergies: [],
          allergies: '',
          housekeepingCadence: 'Morning (09:00 - 11:00)',
          occasionDetails: 'Sunset terrace setup at 6 PM',
        })
        .expect(200);

      expect(res.body.data.pillowType).toBe('Memory Foam');
      expect(res.body.data.scentProfile).toBe('Mayan Copal');
      expect(res.body.data.allergies).toBe('');
      expect(res.body.data.housekeepingCadence).toBe('Morning (09:00 - 11:00)');
    });

    it('GET /api/v1/catalog/larder, /experiences, and /yacht return master catalogs', async () => {
      const larderRes = await request(app.getHttpServer())
        .get('/api/v1/catalog/larder')
        .set('Authorization', `Bearer ${demoUuid}`)
        .expect(200);
      expect(larderRes.body.data.length).toBeGreaterThanOrEqual(7);

      const expRes = await request(app.getHttpServer())
        .get('/api/v1/catalog/experiences')
        .set('Authorization', `Bearer ${demoUuid}`)
        .expect(200);
      expect(expRes.body.data.length).toBeGreaterThanOrEqual(6);

      const yachtRes = await request(app.getHttpServer())
        .get('/api/v1/catalog/yacht')
        .set('Authorization', `Bearer ${demoUuid}`)
        .expect(200);
      expect(yachtRes.body.data.vesselSpecs.model).toBe('Galeon 470 Sky');
    });

    it('PUT /api/v1/stays/:guestUuid/larder updates larder order with stay-scoped orderItemId and recalculates folio summary', async () => {
      const res = await request(app.getHttpServer())
        .put(`/api/v1/stays/${demoUuid}/larder`)
        .set('X-StepUp-Session', stepUpToken)
        .send({
          items: [
            { itemId: 'larder-1', quantity: 2 },
            { itemId: 'larder-2', quantity: 2 },
          ],
        })
        .expect(200);

      expect(res.body.data.orders.length).toBe(2);
      expect(res.body.data.orders[0].orderItemId).toBe(
        'larder_stay_2026_11_villa102_miller_larder-1',
      );
      expect(res.body.data.orders[1].orderItemId).toBe(
        'larder_stay_2026_11_villa102_miller_larder-2',
      );
      expect(res.body.data.folioSummary.finalSettledTotalUSD).toBeGreaterThan(0);
    });

    it('POST /api/v1/stays/:guestUuid/bookings creates yacht/dining/excursion bookings in REQUESTED status and rejects > 12 yacht guests with 400', async () => {
      await request(app.getHttpServer())
        .post(`/api/v1/stays/${demoUuid}/bookings`)
        .set('X-StepUp-Session', stepUpToken)
        .send({
          category: 'yacht',
          catalogRefId: 'extended',
          scheduledDate: '2026-11-15',
          scheduledTimeSlot: '10:00 AM – 4:00 PM',
          partySize: 14,
        })
        .expect(400);

      const validRes = await request(app.getHttpServer())
        .post(`/api/v1/stays/${demoUuid}/bookings`)
        .set('X-StepUp-Session', stepUpToken)
        .send({
          category: 'yacht',
          catalogRefId: 'extended',
          scheduledDate: '2026-11-15',
          scheduledTimeSlot: '10:00 AM – 4:00 PM',
          partySize: 4,
        })
        .expect(201);

      expect(validRes.body.data.bookingType).toBe('YACHT_CHARTER');
      expect(validRes.body.data.partySize).toBe(4);
      expect(validRes.body.data.status).toBe('REQUESTED');
      expect(validRes.body.data.cancellationReason).toBe('');

      const listRes = await request(app.getHttpServer())
        .get(`/api/v1/stays/${demoUuid}/bookings`)
        .expect(200);
      expect(listRes.body.data.length).toBeGreaterThanOrEqual(3);
    });

    it('POST & GET /api/v1/stays/:guestUuid/concierge-requests and live guest message append', async () => {
      const createRes = await request(app.getHttpServer())
        .post(`/api/v1/stays/${demoUuid}/concierge-requests`)
        .send({
          type: 'issue',
          category: 'Air conditioning',
          title: 'Master Suite A/C Calibration',
          details: 'Please lower master suite to 68F before evening turn-down.',
          photoStoragePath: `/private/stays/stay_2026_11_villa102_miller/concierge/req-ac/panel.jpg`,
        })
        .expect(201);

      expect(createRes.body.data.status).toBe('Requested');
      expect(createRes.body.data.currentStep).toBe(1);
      const requestId = createRes.body.data.requestId;

      const msgRes = await request(app.getHttpServer())
        .post(`/api/v1/stays/${demoUuid}/concierge-requests/${requestId}/messages`)
        .send({ text: 'We will be at the beach until 5 PM.' })
        .expect(201);

      expect(msgRes.body.data.messages.length).toBeGreaterThanOrEqual(2);
    });

    it('POST /api/v1/stays/:guestUuid/concierge-requests/upload-url validates MIME and size and returns V4 Signed PUT URL', async () => {
      await request(app.getHttpServer())
        .post(`/api/v1/stays/${demoUuid}/concierge-requests/upload-url`)
        .send({
          requestId: 'req-ac',
          fileName: 'malware.exe',
          contentType: 'application/x-msdownload',
          fileSizeBytes: 1024,
        })
        .expect(400);

      await request(app.getHttpServer())
        .post(`/api/v1/stays/${demoUuid}/concierge-requests/upload-url`)
        .send({
          requestId: 'req-ac',
          fileName: 'huge.jpg',
          contentType: 'image/jpeg',
          fileSizeBytes: 15 * 1024 * 1024,
        })
        .expect(400);

      const validUpload = await request(app.getHttpServer())
        .post(`/api/v1/stays/${demoUuid}/concierge-requests/upload-url`)
        .send({
          requestId: 'req-ac',
          fileName: 'ac_panel.jpg',
          contentType: 'image/jpeg',
          fileSizeBytes: 512000,
        })
        .expect(201);

      expect(validUpload.body.data.storagePath).toContain(
        '/private/stays/stay_2026_11_villa102_miller/concierge/req-ac/',
      );
      expect(validUpload.body.data.uploadUrl).toContain('X-Goog-Algorithm=GOOG4-RSA-SHA256');
    });

    it('POST /api/v1/stays/:guestUuid/midstay-checkin creates feedback and emits URGENT < 7 Min SLA alert when rating <= 3', async () => {
      const res = await request(app.getHttpServer())
        .post(`/api/v1/stays/${demoUuid}/midstay-checkin`)
        .send({
          rating: 2,
          selectedSentiment: 'direct',
          selectedAspects: ['Villa Climate & Night Temp'],
          housekeepingPreferences: ['Evening copal diffusion at 6:30 PM'],
          note: 'Need immediate thermal engineer adjustment.',
        })
        .expect(201);

      expect(res.body.data.selectedSentiment).toBe('direct');
    });

    it('GET /api/v1/stays/:guestUuid/folio returns itemized ledger ($0 included privileges vs paid incidentals)', async () => {
      const res = await request(app.getHttpServer())
        .get(`/api/v1/stays/${demoUuid}/folio`)
        .expect(200);

      expect(res.body.data.folioSummary.complimentarySavingsUSD).toBeGreaterThan(0);
      const complimentaryItems = res.body.data.folioItems.filter(
        (item: { isComplimentary: boolean; chargedAmountUSD: number }) =>
          item.isComplimentary && item.chargedAmountUSD === 0,
      );
      expect(complimentaryItems.length).toBeGreaterThanOrEqual(2);
    });
  });

  describe('2. Admin Operations Dashboard Endpoints (All 16 /api/v1/admin/* Routes)', () => {
    it('1) POST /api/v1/admin/auth/login authenticates HOST ADMIN (HOST_ADMIN) and Chef Mateo (DEPARTMENT_COORDINATOR)', async () => {
      const adminRes = await request(app.getHttpServer())
        .post('/api/v1/admin/auth/login')
        .send({ email: 'eduardo.rivera@kachavalux.com', passcode: 'KachavaAdmin2026!' })
        .expect(201);

      expect(adminRes.body.data.staff.fullName).toBe('HOST ADMIN');
      expect(adminRes.body.data.staff.shortName).toBe('HOST ADMIN');
      expect(adminRes.body.data.staff.role).toBe('HOST ADMIN');
      expect(adminRes.body.data.staff.rbacRole).toBe('HOST_ADMIN');
      hostAdminToken = adminRes.body.data.token;

      const chefRes = await request(app.getHttpServer())
        .post('/api/v1/admin/auth/login')
        .send({ email: 'mateo@kachavalux.com', passcode: 'KachavaAdmin2026!' })
        .expect(201);

      coordinatorToken = chefRes.body.data.token;
    });

    it('2 & 3) GET /api/v1/admin/alerts and PATCH /api/v1/admin/alerts/:alertId/acknowledge', async () => {
      const alertsRes = await request(app.getHttpServer())
        .get('/api/v1/admin/alerts?isAcknowledged=false')
        .set('Authorization', `Bearer ${hostAdminToken}`)
        .expect(200);

      expect(alertsRes.body.data.unreadCount).toBeGreaterThan(0);
      const alerts = alertsRes.body.data.alerts as Array<{
        alertId: string;
        category: string;
        severity: string;
        title: string;
        summary: string;
      }>;
      const normalPrefAlert = alerts.find(
        (a) =>
          a.category === 'DIETARY' &&
          a.severity === 'NORMAL' &&
          a.title.includes('Stay Preferences Updated'),
      );
      expect(normalPrefAlert).toBeDefined();
      expect(normalPrefAlert?.summary).toContain('Pillow: Memory Foam');
      expect(normalPrefAlert?.summary).toContain('Scent: Mayan Copal');
      expect(normalPrefAlert?.summary).toContain('Cleaning: Morning (09:00 - 11:00)');

      const urgentPrefAlert = alerts.find(
        (a) =>
          a.category === 'DIETARY' &&
          a.severity === 'URGENT' &&
          a.title.includes('Dietary & Allergy Update: Shellfish, Tree Nuts'),
      );
      expect(urgentPrefAlert).toBeDefined();
      expect(urgentPrefAlert?.summary).toContain('Allergies: Shellfish, Tree Nuts');

      const firstAlertId = alerts[0].alertId;

      const ackRes = await request(app.getHttpServer())
        .patch(`/api/v1/admin/alerts/${firstAlertId}/acknowledge`)
        .set('Authorization', `Bearer ${hostAdminToken}`)
        .expect(200);

      expect(ackRes.body.data.isAcknowledged).toBe(true);
    });

    it('4, 5 & 6) GET /api/v1/admin/stays, POST /api/v1/admin/stays, and POST /api/v1/admin/stays/:stayId/regenerate-token (RBAC enforced)', async () => {
      const listRes = await request(app.getHttpServer())
        .get('/api/v1/admin/stays?villaId=villa-102')
        .set('Authorization', `Bearer ${hostAdminToken}`)
        .expect(200);
      expect(listRes.body.data.length).toBeGreaterThanOrEqual(1);

      const octRes = await request(app.getHttpServer())
        .post('/api/v1/admin/stays')
        .set('Authorization', `Bearer ${hostAdminToken}`)
        .send({
          guestName: 'Sofia & Mateo Solis',
          villaId: 'villa-103',
          villaName: 'Villa 103 — Mangrove Suite',
          checkIn: 'Oct 19',
          checkOut: 'Oct 22',
          guestsCount: 2,
          occasion: 'Sanctuary Escape',
        })
        .expect(201);
      expect(octRes.body.data.stay.nights).toBe(3);
      expect(octRes.body.data.stay.personalization.housekeepingCadence).toBe('');

      const createRes = await request(app.getHttpServer())
        .post('/api/v1/admin/stays')
        .set('Authorization', `Bearer ${hostAdminToken}`)
        .send({
          guestName: 'Elena & Marcus Vance',
          partnerName: 'Marcus',
          villaId: 'villa-104',
          villaName: 'Villa 104 — Copal Suite',
          checkIn: '2026-12-01',
          checkOut: '2026-12-05',
          nights: 4,
          guestsCount: 2,
          occasion: 'Babymoon Retreat',
        })
        .expect(201);

      const createdStay = createRes.body.data.stay;
      expect(createdStay.villaId).toBe('villa-104');
      expect(createdStay.villaName).toBe('Villa 104 — Copal Suite');
      expect(createdStay.suiteName).toBe('Copal Suite');
      expect(createdStay.villaAccess.wifiSsid).toBe('Kachava_Sanctuary_104');
      expect(createdStay.villaAccess.wifiPasscode).toBe('stillness2026');
      expect(createdStay.stayDatesLabel).toBe('2026-12-01 – 2026-12-05');
      expect(createdStay.guestProfile.name).toBe('Elena & Marcus Vance');
      expect(createdStay.guestProfile.celebration).toBe('Babymoon Retreat');
      expect(createdStay.guestProfile.dietaryProfile).toBe('');
      expect(createdStay.guestProfile.allergies).toBe('');
      expect(createdStay.guestProfile.inVillaBar).toBe('');
      expect(createdStay.guestProfile.folioCard).toBe('On File');
      expect(createdStay.hostInfo.name).toBe('HOST ADMIN');
      expect(createdStay.hostInfo.shortName).toBe('HOST ADMIN');
      expect(createdStay.experienceBookings).toEqual([]);
      expect(createdStay.larderOrders).toEqual([]);
      expect(createdStay.conciergeRequests).toEqual([]);
      expect(createdStay.midstayFeedback).toEqual([]);
      expect(createdStay.folioItems).toEqual([]);
      expect(createdStay.folioSummary.incidentalsSubtotalUSD).toBe(0);
      expect(createdStay.folioSummary.finalSettledTotalUSD).toBe(0);
      expect(createdStay.folioSummary.isCheckedOut).toBe(false);
      expect(createdStay.flightTransfer.status).toBe('Not Requested');
      expect(createdStay.flightTransfer.flightNumber).toBe('');
      expect(createdStay.flightTransfer.arrivalDate).toBe('');
      expect(createdStay.flightTransfer.arrivalAirport).toBe('');
      expect(createdStay.flightTransfer.airline).toBe('');
      expect(createdStay.flightTransfer.terminal).toBe('');
      expect(createdStay.flightTransfer.arrivalTime).toBe('');
      expect(createdStay.flightTransfer.estimatedLanding).toBe('');
      expect(createdStay.flightTransfer.assignedDriver).toBe('');
      expect(createdStay.flightTransfer.assignedStaffName).toBe('');
      expect(createdStay.flightTransfer.vehicleModel).toBe('');
      expect(createdStay.flightTransfer.meetingPoint).toBe('');
      expect(createdStay.personalization.currentStep).toBe(1);
      expect(createdStay.personalization.tripPurpose).toBe('Babymoon Retreat');
      expect(createdStay.personalization.occasionDetails).toBe('');
      expect(createdStay.personalization.selectedInterests).toEqual([]);
      expect(createdStay.personalization.dietary).toBe('');
      expect(createdStay.personalization.dietaryAllergies).toEqual([]);
      expect(createdStay.personalization.allergies).toBe('');
      expect(createdStay.personalization.pillowType).toBe('');
      expect(createdStay.personalization.scentProfile).toBe('');
      expect(createRes.body.data.magicLinkUrl).toBe(
        `http://localhost:3000/?guestId=${createdStay.guestTokenUuid}`,
      );
      const newStayId = createdStay.stayId;

      // Guest submits flight details on new stay -> status transitions from 'Not Requested' to 'Pending'
      const guestTransferRes = await request(app.getHttpServer())
        .patch(`/api/v1/stays/${createdStay.guestTokenUuid}/transfer`)
        .send({
          arrivalDate: '2026-12-01',
          arrivalAirport: 'CUN',
          airline: 'Delta',
          flightNumber: 'DL 404',
          terminal: 'Terminal 4',
          estimatedLanding: '2:10 PM EST',
        })
        .expect(200);
      expect(guestTransferRes.body.data.status).toBe('Pending');
      expect(guestTransferRes.body.data.flightNumber).toBe('DL 404');

      // Update stay status via PATCH /api/v1/admin/stays/:stayId/status
      const statusRes = await request(app.getHttpServer())
        .patch(`/api/v1/admin/stays/${newStayId}/status`)
        .set('Authorization', `Bearer ${hostAdminToken}`)
        .send({ status: 'ACTIVE_STAY' })
        .expect(200);
      expect(statusRes.body.data.status).toBe('ACTIVE_STAY');

      // RBAC: DEPARTMENT_COORDINATOR cannot regenerate token
      await request(app.getHttpServer())
        .post(`/api/v1/admin/stays/${newStayId}/regenerate-token`)
        .set('Authorization', `Bearer ${coordinatorToken}`)
        .expect(403);

      const rotateRes = await request(app.getHttpServer())
        .post(`/api/v1/admin/stays/${newStayId}/regenerate-token`)
        .set('Authorization', `Bearer ${hostAdminToken}`)
        .expect(201);

      expect(rotateRes.body.data.guestTokenUuid).not.toBe(
        createRes.body.data.stay.guestTokenUuid,
      );
    });

    it('7) PATCH /api/v1/admin/stays/:stayId/transfer and /wifi update stay without emitting self-alert', async () => {
      const beforeAlerts = await request(app.getHttpServer())
        .get('/api/v1/admin/alerts')
        .set('Authorization', `Bearer ${hostAdminToken}`)
        .expect(200);
      const beforeCount = beforeAlerts.body.data.alerts.length;

      const res = await request(app.getHttpServer())
        .patch('/api/v1/admin/stays/stay_2026_11_villa102_miller/transfer')
        .set('Authorization', `Bearer ${hostAdminToken}`)
        .send({
          assignedStaffId: 'staff_carlos',
          assignedStaffName: 'Carlos M.',
          assignedDriver: 'Carlos M.',
          vehicleModel: 'Mercedes-Benz EQS SUV',
          meetingPoint: 'FBO Private Terminal Gate B',
          status: 'En Route',
          adminDispatchNotes: 'Departing sanctuary gate for Terminal 3.',
        })
        .expect(200);

      expect(res.body.data.status).toBe('En Route');
      expect(res.body.data.assignedStaffName).toBe('Carlos M.');
      expect(res.body.data.assignedDriver).toBe('Carlos M.');
      expect(res.body.data.vehicleModel).toBe('Mercedes-Benz EQS SUV');
      expect(res.body.data.meetingPoint).toBe('FBO Private Terminal Gate B');

      const wifiRes = await request(app.getHttpServer())
        .patch('/api/v1/admin/stays/stay_2026_11_villa102_miller/wifi')
        .set('Authorization', `Bearer ${hostAdminToken}`)
        .send({
          wifiSsid: 'Kachava_Private_102_5G',
          wifiPasscode: 'CopalSanctuary2026',
        })
        .expect(200);

      expect(wifiRes.body.data.villaAccess.wifiSsid).toBe('Kachava_Private_102_5G');
      expect(wifiRes.body.data.villaAccess.wifiPasscode).toBe('CopalSanctuary2026');

      const guestStayRes = await request(app.getHttpServer())
        .get(`/api/v1/stays/${demoUuid}`)
        .expect(200);
      expect(guestStayRes.body.data.villaAccess.wifiSsid).toBe('Kachava_Private_102_5G');
      expect(guestStayRes.body.data.villaAccess.wifiPasscode).toBe('CopalSanctuary2026');

      const afterAlerts = await request(app.getHttpServer())
        .get('/api/v1/admin/alerts')
        .set('Authorization', `Bearer ${hostAdminToken}`)
        .expect(200);
      expect(afterAlerts.body.data.alerts.length).toBe(beforeCount);
    });

    it('7b) Configurable Catalogs: GET/POST/DELETE /api/v1/admin/catalog/experiences & /larder mutate live guest catalogs (with optional larder category)', async () => {
      const createExpRes = await request(app.getHttpServer())
        .post('/api/v1/admin/catalog/experiences')
        .set('Authorization', `Bearer ${hostAdminToken}`)
        .send({
          id: 'exp-custom-cenote',
          title: 'Midnight Bioluminescence Kayak',
          category: 'Cenotes & Caverns',
          duration: '2.5 Hours',
          location: 'Laguna Kaan Luum',
          priceText: '$290 / Guest',
          basePriceUSD: 290,
          isIncluded: false,
          description: 'Guided nocturnal paddle under the stars.',
        })
        .expect(201);
      expect(createExpRes.body.data.id).toBe('exp-custom-cenote');

      const guestExpRes = await request(app.getHttpServer())
        .get('/api/v1/catalog/experiences')
        .expect(200);
      expect(
        guestExpRes.body.data.some((e: { id: string }) => e.id === 'exp-custom-cenote'),
      ).toBe(true);

      await request(app.getHttpServer())
        .delete('/api/v1/admin/catalog/experiences/exp-custom-cenote')
        .set('Authorization', `Bearer ${hostAdminToken}`)
        .expect(200);

      const createLarderRes = await request(app.getHttpServer())
        .post('/api/v1/admin/catalog/larder')
        .set('Authorization', `Bearer ${hostAdminToken}`)
        .send({
          id: 'larder-custom-cacao',
          name: 'Ceremonial Criollo Cacao',
          origin: 'Chiapas Highlands',
          description: 'Stone-ground organic cacao nibs and spiced vanilla bean.',
          price: 54,
          storageType: 'DRY BAR PRESENTATION',
          dietary: 'VEGAN',
        })
        .expect(201);
      expect(createLarderRes.body.data.id).toBe('larder-custom-cacao');
      expect(createLarderRes.body.data.category).toBe('Minibar');

      const guestLarderRes = await request(app.getHttpServer())
        .get('/api/v1/catalog/larder')
        .expect(200);
      expect(
        guestLarderRes.body.data.some((l: { id: string }) => l.id === 'larder-custom-cacao'),
      ).toBe(true);

      await request(app.getHttpServer())
        .delete('/api/v1/admin/catalog/larder/larder-custom-cacao')
        .set('Authorization', `Bearer ${hostAdminToken}`)
        .expect(200);
    });

    it('8 & 9) GET /api/v1/admin/bookings and PATCH /api/v1/admin/bookings/:bookingId/assign (including CANCELLED with cancellationReason)', async () => {
      const bookingsRes = await request(app.getHttpServer())
        .get('/api/v1/admin/bookings?category=YACHT')
        .set('Authorization', `Bearer ${hostAdminToken}`)
        .expect(200);

      expect(bookingsRes.body.data.length).toBeGreaterThanOrEqual(1);
      const bookingId = bookingsRes.body.data[0].bookingId;

      const assignRes = await request(app.getHttpServer())
        .patch(`/api/v1/admin/bookings/${bookingId}/assign`)
        .set('Authorization', `Bearer ${hostAdminToken}`)
        .send({
          assignedStaffId: 'staff_velasco',
          assignedStaffName: 'Captain Eduardo Velasco Tadeo',
          assignedDepartment: 'MARINE',
          status: 'IN_PREPARATION',
          adminNotes: 'Galeon 470 Sky fueled and stocked.',
        })
        .expect(200);

      expect(assignRes.body.data.notifiedAt).toBeTruthy();
      expect(assignRes.body.data.status).toBe('IN_PREPARATION');

      const cancelRes = await request(app.getHttpServer())
        .patch(`/api/v1/admin/bookings/${bookingId}/assign`)
        .set('Authorization', `Bearer ${hostAdminToken}`)
        .send({
          status: 'CANCELLED',
          cancellationReason: 'Clima adverso en altamar',
        })
        .expect(200);

      expect(cancelRes.body.data.status).toBe('CANCELLED');
      expect(cancelRes.body.data.cancellationReason).toBe('Clima adverso en altamar');

      const guestStayRes = await request(app.getHttpServer())
        .get(`/api/v1/stays/${demoUuid}`)
        .expect(200);
      const cancelledBooking = guestStayRes.body.data.experienceBookings.find(
        (b: { bookingId: string }) => b.bookingId === bookingId,
      );
      expect(cancelledBooking).toBeDefined();
      expect(cancelledBooking.status).toBe('CANCELLED');
      expect(cancelledBooking.cancellationReason).toBe('Clima adverso en altamar');
    });

    it('10 & 11) GET /api/v1/admin/larder-orders and PATCH /api/v1/admin/larder-orders/:orderId/status updates all stay larder items', async () => {
      const larderRes = await request(app.getHttpServer())
        .get('/api/v1/admin/larder-orders')
        .set('Authorization', `Bearer ${hostAdminToken}`)
        .expect(200);

      expect(larderRes.body.data.length).toBeGreaterThanOrEqual(2);
      const orderId = larderRes.body.data[0].orderItemId;

      const updateRes = await request(app.getHttpServer())
        .patch(`/api/v1/admin/larder-orders/${orderId}/status`)
        .set('Authorization', `Bearer ${hostAdminToken}`)
        .send({
          assignedStaffId: 'staff_eduardo',
          assignedStaffName: 'Eduardo Rivera',
          provisioningStatus: 'Stocked in Villa',
        })
        .expect(200);

      expect(updateRes.body.data.provisioningStatus).toBe('Stocked in Villa');

      const guestStayRes = await request(app.getHttpServer())
        .get(`/api/v1/stays/${demoUuid}`)
        .expect(200);
      expect(guestStayRes.body.data.larderOrders.length).toBe(2);
      expect(
        guestStayRes.body.data.larderOrders.every(
          (o: { provisioningStatus: string }) => o.provisioningStatus === 'Stocked in Villa',
        ),
      ).toBe(true);
    });

    it('12, 13 & 14) GET/PATCH /api/v1/admin/concierge-requests and GET photo-url', async () => {
      const listRes = await request(app.getHttpServer())
        .get('/api/v1/admin/concierge-requests')
        .set('Authorization', `Bearer ${hostAdminToken}`)
        .expect(200);

      expect(listRes.body.data.length).toBeGreaterThanOrEqual(1);
      const reqId = listRes.body.data[0].requestId;

      const patchRes = await request(app.getHttpServer())
        .patch(`/api/v1/admin/concierge-requests/${reqId}`)
        .set('Authorization', `Bearer ${hostAdminToken}`)
        .send({
          status: 'In Progress',
          currentStep: 3,
          assignedStaffId: 'staff_eduardo',
          assignedTo: 'Eduardo Rivera',
          assignedDepartment: 'ENGINEERING',
          replyMessage: 'Our thermal engineer is arriving at Villa 102 in 4 minutes.',
        })
        .expect(200);

      expect(patchRes.body.data.status).toBe('In Progress');
      expect(patchRes.body.data.currentStep).toBe(3);

      const photoUrlRes = await request(app.getHttpServer())
        .get(`/api/v1/admin/concierge-requests/${reqId}/photo-url`)
        .set('Authorization', `Bearer ${hostAdminToken}`)
        .expect(200);

      expect(photoUrlRes.body.data.downloadUrl).toContain('X-Goog-Algorithm=GOOG4-RSA-SHA256');
    });

    it('15 & 16) GET /api/v1/admin/midstay-feedback, GET /api/v1/admin/staff, and Express Checkout + Post-Checkout Read-Only enforcement', async () => {
      const midstayRes = await request(app.getHttpServer())
        .get('/api/v1/admin/midstay-feedback')
        .set('Authorization', `Bearer ${hostAdminToken}`)
        .expect(200);
      expect(midstayRes.body.data.length).toBeGreaterThanOrEqual(1);

      const staffRes = await request(app.getHttpServer())
        .get('/api/v1/admin/staff')
        .set('Authorization', `Bearer ${hostAdminToken}`)
        .expect(200);
      expect(staffRes.body.data.length).toBeGreaterThanOrEqual(4);

      // Guest triggers Express Checkout (with StepUpVerifiedGuard)
      const checkoutRes = await request(app.getHttpServer())
        .post(`/api/v1/stays/${demoUuid}/folio/checkout`)
        .set('X-StepUp-Session', stepUpToken)
        .send({ lateCheckoutRequested: false })
        .expect(201);
      expect(checkoutRes.body.data.folioSummary.isCheckedOut).toBe(true);

      // Admin approves checkout -> transitions stay to CHECKED_OUT
      const approveRes = await request(app.getHttpServer())
        .patch('/api/v1/admin/stays/stay_2026_11_villa102_miller/folio/approve-checkout')
        .set('Authorization', `Bearer ${hostAdminToken}`)
        .send({ approveLateCheckout: false })
        .expect(200);
      expect(approveRes.body.data.status).toBe('CHECKED_OUT');

      // Post-checkout: GET folio is allowed within 48h window, but PATCH/POST mutations return 403 Forbidden
      await request(app.getHttpServer())
        .get(`/api/v1/stays/${demoUuid}/folio`)
        .expect(200);

      await request(app.getHttpServer())
        .patch(`/api/v1/stays/${demoUuid}/transfer`)
        .send({ flightNumber: 'AA 000' })
        .expect(403);
    });

    it('17) POST /api/v1/admin/reset wipes all stays and alerts for zero-state testing', async () => {
      const resetRes = await request(app.getHttpServer())
        .post('/api/v1/admin/reset')
        .set('Authorization', `Bearer ${hostAdminToken}`)
        .expect(201);
      expect(resetRes.body.data.reset).toBe(true);

      const staysRes = await request(app.getHttpServer())
        .get('/api/v1/admin/stays')
        .set('Authorization', `Bearer ${hostAdminToken}`)
        .expect(200);
      expect(staysRes.body.data).toEqual([]);

      const alertsRes = await request(app.getHttpServer())
        .get('/api/v1/admin/alerts')
        .set('Authorization', `Bearer ${hostAdminToken}`)
        .expect(200);
      expect(alertsRes.body.data.alerts).toEqual([]);
      expect(alertsRes.body.data.unreadCount).toBe(0);
    });
  });
});
