import { Logger } from '@nestjs/common';
import { NestExpressApplication } from '@nestjs/platform-express';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { AppModule } from '../../src/app.module';
import { STAY_REPOSITORY_PORT, StayRepositoryPort } from '../../src/domain/ports/repository.ports';
import { FirestoreStayRepository } from '../../src/infrastructure/repositories/firestore-stay.repository';
import {
  createSeededStayAggregate,
  DEFAULT_DEMO_GUEST_UUID,
} from '../../src/infrastructure/seed/sanctuary-seed.data';
import { configureApp } from '../../src/main';
import { FakeFirestore } from '../support/fake-firestore';

const STAY = `/api/v1/stays/${DEFAULT_DEMO_GUEST_UUID}`;
const paidBooking = (i: number) => ({
  category: 'explore', catalogRefId: `par_${i}`, scheduledDate: '2026-11-14', scheduledTimeSlot: '10:00', partySize: 1,
});

async function createApp(stayRepo?: StayRepositoryPort): Promise<NestExpressApplication> {
  let builder = Test.createTestingModule({ imports: [AppModule] });
  if (stayRepo) builder = builder.overrideProvider(STAY_REPOSITORY_PORT).useValue(stayRepo);
  const app = (await builder.compile()).createNestApplication<NestExpressApplication>();
  configureApp(app);
  await app.init();
  return app;
}

describe('HTTP error mapping and concurrency (ADV-01, ADV-07, ADV-10)', () => {
  let logSpy: jest.SpyInstance;

  beforeEach(() => {
    logSpy = jest.spyOn(Logger.prototype, 'error').mockImplementation(() => undefined);
  });

  afterEach(() => logSpy.mockRestore());

  it('test_20ParallelPaidBookingsOverHttp_produce20FolioLines', async () => {
    const app = await createApp();
    const server = app.getHttpServer();

    await Promise.all(Array.from({ length: 20 }, (_, i) => request(server).post(`${STAY}/bookings`).send(paidBooking(i))));
    const folio = await request(server).get(`${STAY}/folio`);
    await app.close();

    const lines = folio.body.data.folioItems.filter((f: { folioItemId: string }) => f.folioItemId.startsWith('folio_bk_'));
    expect(lines).toHaveLength(20);
  });

  it('test_guestWriteAfterStayDeleted_returns404NotGeneric500', async () => {
    const app = await createApp();
    const repo = app.get<StayRepositoryPort>(STAY_REPOSITORY_PORT);
    const findOriginal = repo.findByGuestTokenUuid.bind(repo);
    jest.spyOn(repo, 'findByGuestTokenUuid').mockImplementation(async (token) => {
      const stay = await findOriginal(token);
      await repo.resetAllStays();
      return stay;
    });

    const res = await request(app.getHttpServer()).patch(`${STAY}/transfer`).send({ flightNumber: 'AA1' });
    await app.close();

    expect(res.status).toBe(404);
  });

  it('test_firestoreAbortedAfterRetries_returns503WithRetryAfter', async () => {
    const fake = new FakeFirestore();
    const repo = new FirestoreStayRepository(fake.asFirestore());
    await repo.createStay(createSeededStayAggregate());
    const app = await createApp(repo);
    fake.failWritesWith(Object.assign(new Error('10 ABORTED: Too much contention'), { code: 10 }), 'stays');

    const res = await request(app.getHttpServer()).post(`${STAY}/bookings`).send(paidBooking(1));
    await app.close();

    expect(res.status).toBe(503);
    expect(res.headers['retry-after']).toBe('1');
    expect(res.body.message).not.toContain('ABORTED');
  });

  it('test_oversizedGuestField_isRejectedWith400', async () => {
    const app = await createApp();

    const res = await request(app.getHttpServer()).patch(`${STAY}/transfer`).send({ flightNumber: 'F'.repeat(45_000) });
    await app.close();

    expect(res.status).toBe(400);
  });

  it('test_requestBodyAboveParserLimit_returns413NotGeneric500', async () => {
    const app = await createApp();

    const res = await request(app.getHttpServer()).post(`${STAY}/concierge-requests`).send({ title: 'a'.repeat(200_000) });
    await app.close();

    expect(res.status).toBe(413);
  });
});
