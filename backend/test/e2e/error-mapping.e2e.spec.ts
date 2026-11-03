import { Logger } from '@nestjs/common';
import request from 'supertest';
import { STAY_REPOSITORY_PORT, StayRepositoryPort } from '../../src/domain/ports/repository.ports';
import { createTestApp, GUEST_STAY_PATH as STAY, seedGuestFixtures, TestApp } from '../support/test-app';

const paidBooking = (i: number) => ({
  serviceId: 'svc-1', scheduledDate: '2026-12-03', scheduledTimeSlot: '10:00', partySize: 1, metadata: { ref: i },
});

describe('HTTP error mapping and concurrency (ADV-01, ADV-07, ADV-10)', () => {
  let logSpy: jest.SpyInstance;
  let t: TestApp;

  beforeEach(async () => {
    logSpy = jest.spyOn(Logger.prototype, 'error').mockImplementation(() => undefined);
    t = await createTestApp();
    seedGuestFixtures(t.fake);
  });

  afterEach(async () => {
    logSpy.mockRestore();
    await t.close();
  });

  it('test_20ParallelPaidBookingsOverHttp_produce20FolioLines', async () => {
    await Promise.all(Array.from({ length: 20 }, (_, i) => request(t.server()).post(`${STAY}/bookings`).send(paidBooking(i))));
    const folio = await request(t.server()).get(`${STAY}/folio`);

    const lines = folio.body.data.folioItems.filter((f: { folioItemId: string }) => f.folioItemId.startsWith('folio_bk_'));
    expect(lines).toHaveLength(20);
  });

  it('test_guestWriteAfterStayDeleted_returns404NotGeneric500', async () => {
    const repo = t.app.get<StayRepositoryPort>(STAY_REPOSITORY_PORT);
    const findOriginal = repo.findByGuestTokenUuid.bind(repo);
    jest.spyOn(repo, 'findByGuestTokenUuid').mockImplementation(async (token) => {
      const stay = await findOriginal(token);
      t.fake.store('stays').clear();
      return stay;
    });

    const res = await request(t.server()).patch(`${STAY}/transfer`).send({ flightNumber: 'AA1' });

    expect(res.status).toBe(404);
  });

  it('test_firestoreAbortedAfterRetries_returns503WithRetryAfter', async () => {
    t.fake.failWritesWith(Object.assign(new Error('10 ABORTED: Too much contention'), { code: 10 }), 'stays');

    const res = await request(t.server()).post(`${STAY}/bookings`).send(paidBooking(1));

    expect(res.status).toBe(503);
    expect(res.headers['retry-after']).toBe('1');
    expect(res.body.message).not.toContain('ABORTED');
  });

  it('test_oversizedGuestField_isRejectedWith400', async () => {
    const res = await request(t.server()).patch(`${STAY}/transfer`).send({ flightNumber: 'F'.repeat(45_000) });

    expect(res.status).toBe(400);
  });

  it('test_requestBodyAboveParserLimit_returns413NotGeneric500', async () => {
    const res = await request(t.server()).post(`${STAY}/concierge-requests`).send({ title: 'a'.repeat(200_000) });

    expect(res.status).toBe(413);
  });
});
