import {
  conversationMessages,
  conversationSummary,
  replyThreadId,
  toConversationRow,
} from '../../src/domain/conversations/conversation-rules';
import { ConciergeRequest, StayAggregate } from '../../src/domain/models/domain.models';
import { populatedStayFixture } from '../support/stay-fixtures';

function request(requestId: string, messages: ConciergeRequest['messages'], photo: string | null = null): ConciergeRequest {
  return { ...populatedStayFixture().conciergeRequests[0], requestId, messages, photoStoragePath: photo };
}

const guest = (text: string, sentAt: string) => ({ sender: 'GUEST' as const, senderName: 'Test Guest', text, sentAt });
const staff = (text: string, sentAt: string) => ({ sender: 'CONCIERGE' as const, senderName: 'Host', senderStaffId: 's1', text, sentAt });

function stayWith(requests: ConciergeRequest[], overrides: Partial<StayAggregate> = {}): StayAggregate {
  return populatedStayFixture({ conciergeRequests: requests, ...overrides });
}

describe('conversation rules (one conversation per stay over its Resort Host threads)', () => {
  const stay = stayWith([
    request('r1', [guest('Towels please', '2026-12-02T10:00:00.000Z'), staff('On the way', '2026-12-02T10:05:00.000Z')], 'stays/x/photo.jpg'),
    request('r2', [guest('Late checkout?', '2026-12-02T11:00:00.000Z'), guest('Hello?', '2026-12-02T12:00:00.000Z')]),
  ]);

  it('test_messages_mergeEveryThread_oldestFirst_withThePhotoOnTheOpeningMessage', () => {
    const messages = conversationMessages(stay);

    expect(messages.map((m) => [m.id, m.from])).toEqual([
      ['r1:0', 'GUEST'], ['r1:1', 'STAFF'], ['r2:0', 'GUEST'], ['r2:1', 'GUEST'],
    ]);
    expect(messages[0].photoStoragePath).toBe('stays/x/photo.jpg');
    expect(messages[1].photoStoragePath).toBeNull();
  });

  it('test_summary_countsGuestMessagesAfterTheStaffReadMark_andAwaitingReply', () => {
    expect(conversationSummary(stay)).toEqual({
      lastMessageAt: '2026-12-02T12:00:00.000Z', lastMessageText: 'Hello?', lastMessageFrom: 'GUEST',
      lastMessageHasPhoto: false, unreadCount: 3, hasUnread: true, awaitingReply: true,
    });
    const read = conversationSummary({ ...stay, conversationReadAt: '2026-12-02T11:30:00.000Z' });
    expect(read).toMatchObject({ unreadCount: 1, hasUnread: true });
  });

  it('test_noMessages_isNoConversation', () => {
    expect(conversationSummary(stayWith([]))).toBeNull();
  });

  it('test_replyThread_isTheThreadOfTheLatestGuestMessage', () => {
    expect(replyThreadId(stay)).toBe('r2');
    expect(replyThreadId(stayWith([]))).toBeNull();
  });

  it('test_row_hasTheInboxFields', () => {
    expect(toConversationRow(stay)).toEqual({
      stayId: stay.stayId, guestName: 'Test Guest', villaName: 'Test Villa',
      lastMessage: { text: 'Hello?', at: '2026-12-02T12:00:00.000Z', from: 'GUEST', hasPhoto: false },
      unreadCount: 3, awaitingReply: true,
    });
  });
});
