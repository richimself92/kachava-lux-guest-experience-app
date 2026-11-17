import { ConciergeMessage, ConciergeRequest, StayAggregate } from '../models/domain.models';

/**
 * Messages inbox (ADR-011): one conversation per stay, merged from the messages of the stay's
 * Resort Host threads (`conciergeRequests[].messages`). Nothing is duplicated: the summary is
 * derived from those messages and the staff read mark `conversationReadAt`.
 */
export type MessageAuthor = 'GUEST' | 'STAFF';

export interface ConversationMessage {
  /** `<requestId>:<index in the thread>`. */
  id: string;
  requestId: string;
  from: MessageAuthor;
  senderName: string;
  text: string;
  at: string;
  /** The message photo (the thread photo is carried by the opening message). */
  photoStoragePath: string | null;
}

export interface ConversationSummary {
  lastMessageAt: string;
  lastMessageText: string;
  lastMessageFrom: MessageAuthor;
  lastMessageHasPhoto: boolean;
  /** Guest messages after the staff read mark. */
  unreadCount: number;
  hasUnread: boolean;
  /** The last message is the guest's. */
  awaitingReply: boolean;
}

export interface ConversationRow {
  stayId: string;
  guestName: string;
  villaName: string;
  lastMessage: { text: string; at: string; from: MessageAuthor; hasPhoto: boolean };
  unreadCount: number;
  awaitingReply: boolean;
}

/** The photo of message `index`: its own, else (opening message) the photo the thread was opened with. */
export function messagePhotoPath(request: ConciergeRequest, index: number): string | null {
  const own = request.messages?.[index]?.photoStoragePath;
  if (own) return own;
  return index === 0 ? request.photoStoragePath ?? null : null;
}

function authorOf(message: ConciergeMessage): MessageAuthor {
  return message.sender === 'GUEST' ? 'GUEST' : 'STAFF';
}

/** Every message of the stay, oldest first (ties keep thread order). */
export function conversationMessages(stay: StayAggregate): ConversationMessage[] {
  const messages = (stay.conciergeRequests ?? []).flatMap((request) =>
    (request.messages ?? []).map((message, index) => ({
      id: `${request.requestId}:${index}`,
      requestId: request.requestId,
      from: authorOf(message),
      senderName: message.senderName,
      text: message.text,
      at: message.sentAt,
      photoStoragePath: messagePhotoPath(request, index),
    })),
  );
  return messages
    .map((message, order) => ({ message, order }))
    .sort((a, b) => a.message.at.localeCompare(b.message.at) || a.order - b.order)
    .map(({ message }) => message);
}

export function conversationSummary(stay: StayAggregate): ConversationSummary | null {
  const messages = conversationMessages(stay);
  const last = messages.at(-1);
  if (!last) return null;
  const readAt = stay.conversationReadAt ?? '';
  const unreadCount = messages.filter((m) => m.from === 'GUEST' && m.at > readAt).length;
  return {
    lastMessageAt: last.at,
    lastMessageText: last.text,
    lastMessageFrom: last.from,
    lastMessageHasPhoto: last.photoStoragePath !== null,
    unreadCount,
    hasUnread: unreadCount > 0,
    awaitingReply: last.from === 'GUEST',
  };
}

/** Staff replies land in the thread the guest last wrote in (null when the guest never wrote). */
export function replyThreadId(stay: StayAggregate): string | null {
  const lastGuest = conversationMessages(stay).filter((m) => m.from === 'GUEST').at(-1);
  return lastGuest?.requestId ?? null;
}

export function toConversationRow(stay: StayAggregate): ConversationRow | null {
  const summary = conversationSummary(stay);
  if (!summary) return null;
  return {
    stayId: stay.stayId,
    guestName: stay.guestProfile?.name ?? '',
    villaName: stay.villaName,
    lastMessage: {
      text: summary.lastMessageText,
      at: summary.lastMessageAt,
      from: summary.lastMessageFrom,
      hasPhoto: summary.lastMessageHasPhoto,
    },
    unreadCount: summary.unreadCount,
    awaitingReply: summary.awaitingReply,
  };
}
