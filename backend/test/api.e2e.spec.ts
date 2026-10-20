import { INestApplication, ValidationPipe } from '@nestjs/common';
import { Test, TestingModule } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../src/app.module';
import { GlobalHttpExceptionFilter } from '../src/common/filters/global-http-exception.filter';
import { ResponseTransformInterceptor } from '../src/common/interceptors/response-transform.interceptor';

describe('ADR-002 Veridical Stay Aggregate, Bilateral Transfer & Configurable Catalogs E2E', () => {
  let app: INestApplication;
  let hostAdminToken = '';

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

    const loginRes = await request(app.getHttpServer())
      .post('/api/v1/admin/auth/login')
      .send({ email: 'eduardo.rivera@kachavalux.com', passcode: 'KachavaAdmin2026!' })
      .expect(201);
    hostAdminToken = loginRes.body.data.token;
  });

  afterAll(async () => {
    await app.close();
  });

  it('POST /api/v1/admin/stays creates a veridical zero-mock stay aggregate and supports bilateral transfer', async () => {
    const createRes = await request(app.getHttpServer())
      .post('/api/v1/admin/stays')
      .set('Authorization', `Bearer ${hostAdminToken}`)
      .send({
        guestName: 'Clara & Julian Thorne',
        partnerName: 'Julian',
        villaId: 'villa-106',
        villaName: 'Villa 106 — Obsidian Suite',
        checkIn: '2026-12-10',
        checkOut: '2026-12-14',
        nights: 4,
        guestsCount: 2,
        occasion: 'Anniversary Sanctuary',
      })
      .expect(201);

    const stay = createRes.body.data.stay;
    expect(stay.flightTransfer.status).toBe('Not Requested');
    expect(stay.flightTransfer.flightNumber).toBe('');
    expect(stay.personalization.pillowType).toBe('');
    expect(stay.personalization.allergies).toBe('');
    expect(stay.folioItems).toEqual([]);

    const guestTransfer = await request(app.getHttpServer())
      .patch(`/api/v1/stays/${stay.guestTokenUuid}/transfer`)
      .send({
        arrivalDate: '2026-12-10',
        arrivalAirport: 'CUN',
        airline: 'United',
        flightNumber: 'UA 812',
        terminal: 'Terminal 3',
        estimatedLanding: '1:45 PM EST',
      })
      .expect(200);
    expect(guestTransfer.body.data.status).toBe('Pending');

    const adminTransfer = await request(app.getHttpServer())
      .patch(`/api/v1/admin/stays/${stay.stayId}/transfer`)
      .set('Authorization', `Bearer ${hostAdminToken}`)
      .send({
        assignedDriver: 'Carlos M.',
        vehicleModel: 'Mercedes-Benz EQS SUV',
        meetingPoint: 'FBO Private Gate 2',
        status: 'Confirmed',
        adminDispatchNotes: 'Chilled coconut water ready.',
      })
      .expect(200);
    expect(adminTransfer.body.data.status).toBe('Confirmed');
    expect(adminTransfer.body.data.meetingPoint).toBe('FBO Private Gate 2');
  });

  it('POST & DELETE /api/v1/admin/catalog/experiences & /larder mutate live guest catalogs', async () => {
    await request(app.getHttpServer())
      .post('/api/v1/admin/catalog/experiences')
      .set('Authorization', `Bearer ${hostAdminToken}`)
      .send({
        id: 'exp-adr002-test',
        title: 'Private Mayan Stargazing',
        category: 'Wellness & Spa',
        duration: '2 Hours',
        location: 'Rooftop Observatory',
        priceText: '$220 / Guest',
        basePriceUSD: 220,
        isIncluded: false,
        description: 'Astronomer-guided telescope session.',
      })
      .expect(201);

    const expCatalog = await request(app.getHttpServer())
      .get('/api/v1/catalog/experiences')
      .expect(200);
    expect(expCatalog.body.data.some((i: { id: string }) => i.id === 'exp-adr002-test')).toBe(true);

    await request(app.getHttpServer())
      .delete('/api/v1/admin/catalog/experiences/exp-adr002-test')
      .set('Authorization', `Bearer ${hostAdminToken}`)
      .expect(200);

    await request(app.getHttpServer())
      .post('/api/v1/admin/catalog/larder')
      .set('Authorization', `Bearer ${hostAdminToken}`)
      .send({
        id: 'larder-adr002-test',
        name: 'Artisanal Mezcal Tasting Flight',
        origin: 'Oaxaca',
        description: 'Three wild agave expressions.',
        price: 140,
        category: 'cellar',
        storageType: 'DRY BAR PRESENTATION',
      })
      .expect(201);

    const larderCatalog = await request(app.getHttpServer())
      .get('/api/v1/catalog/larder')
      .expect(200);
    expect(larderCatalog.body.data.some((i: { id: string }) => i.id === 'larder-adr002-test')).toBe(
      true,
    );

    await request(app.getHttpServer())
      .delete('/api/v1/admin/catalog/larder/larder-adr002-test')
      .set('Authorization', `Bearer ${hostAdminToken}`)
      .expect(200);
  });
});
