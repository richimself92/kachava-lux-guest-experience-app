import {
  MAX_BOOKINGS_PER_STAY,
  MAX_CONCIERGE_REQUESTS_PER_STAY,
  MAX_MESSAGES_PER_REQUEST,
  MAX_MIDSTAY_FEEDBACK_PER_STAY,
  MAX_STAY_DOCUMENT_BYTES,
} from '../../src/domain/stay-limits';
import { StayDocumentTooLargeError, StayLimitExceededError } from '../../src/domain/stay-errors';
import { StayAggregate } from '../../src/domain/models/domain.models';
import { FirestoreStayRepository } from '../../src/infrastructure/repositories/firestore-stay.repository';
import { createSeededStayAggregate } from '../../src/infrastructure/seed/sanctuary-seed.data';
import { FakeFirestore } from '../support/fake-firestore';

const LONG_MESSAGE = 'x'.repeat(2000);

async function seeded(): Promise<{ repo: FirestoreStayRepository; stay: StayAggregate }> {
  const repo = new FirestoreStayRepository(new FakeFirestore().asFirestore());
  const stay = createSeededStayAggregate();
  await repo.createStay(stay);
  return { repo, stay };
}

function message(text: string) {
  return { sender: 'GUEST' as const, senderName: 'Guest', text, sentAt: '2026-11-13T10:00:00.000Z' };
}

/** Adds items until `cap` is reached, then returns the promise of one more (the overflow). */
async function fillStay<T>(cap: number, existing: number, add: (i: number) => Promise<T>) {
  for (let i = existing; i < cap; i += 1) await add(i);
  return add(cap);
}

describe('Per-stay list caps and document budget (ADV-12)', () => {
  it('test_caps_keepEveryListAndTheDocumentBelowOneMiB', () => {
    expect(MAX_STAY_DOCUMENT_BYTES).toBeLessThan(1_048_576);
    expect(MAX_MESSAGES_PER_REQUEST).toBeLessThanOrEqual(100);
  });

  it('test_appendConciergeMessage_beyondCap_rejectsWithLimitError', async () => {
    const { repo, stay } = await seeded();
    const request = stay.conciergeRequests[0];

    const overflow = fillStay(MAX_MESSAGES_PER_REQUEST, request.messages.length, () =>
      repo.appendConciergeMessage(stay.stayId, request.requestId, message('hi')),
    );

    await expect(overflow).rejects.toBeInstanceOf(StayLimitExceededError);
  });

  it('test_createBooking_beyondCap_rejectsWithLimitError', async () => {
    const { repo, stay } = await seeded();
    const template = stay.experienceBookings[0];

    const overflow = fillStay(MAX_BOOKINGS_PER_STAY, stay.experienceBookings.length, (i) =>
      repo.createBooking(stay.stayId, { ...template, bookingId: `bk_cap_${i}`, priceChargedUSD: 0 }),
    );

    await expect(overflow).rejects.toBeInstanceOf(StayLimitExceededError);
  });

  it('test_createConciergeRequestAndFeedback_beyondCap_rejectWithLimitError', async () => {
    const { repo, stay } = await seeded();

    const requests = fillStay(MAX_CONCIERGE_REQUESTS_PER_STAY, stay.conciergeRequests.length, (i) =>
      repo.createConciergeRequest(stay.stayId, { ...stay.conciergeRequests[0], requestId: `req_cap_${i}` }),
    );
    const feedback = fillStay(MAX_MIDSTAY_FEEDBACK_PER_STAY, stay.midstayFeedback.length, (i) =>
      repo.createMidStayFeedback(stay.stayId, { ...stay.midstayFeedback[0], feedbackId: `fb_cap_${i}` }),
    );

    await expect(requests).rejects.toBeInstanceOf(StayLimitExceededError);
    await expect(feedback).rejects.toBeInstanceOf(StayLimitExceededError);
  });

  it('test_growthBeyondBudget_rejectsBeforeFirestoreLimitAndStayStaysWritable', async () => {
    const { repo, stay } = await seeded();
    const template = { ...stay.conciergeRequests[0], messages: [] };
    let failure: unknown = null;

    for (let r = 0; r < MAX_CONCIERGE_REQUESTS_PER_STAY && !failure; r += 1) {
      const requestId = `req_big_${r}`;
      await repo.createConciergeRequest(stay.stayId, { ...template, requestId }).catch((e) => (failure = e));
      for (let m = 0; m < 20 && !failure; m += 1) {
        await repo.appendConciergeMessage(stay.stayId, requestId, message(LONG_MESSAGE)).catch((e) => (failure = e));
      }
    }

    expect(failure).toBeInstanceOf(StayDocumentTooLargeError);
    await expect(repo.updateStayStatus(stay.stayId, 'ACTIVE_STAY')).resolves.toBeDefined();
  });
});
