import { Inject, Injectable } from '@nestjs/common';
import * as crypto from 'crypto';
import { PaginatedResult, sliceToPage, toListQuery } from '../../common/listing/list-query';
import {
  ConversationMessage,
  conversationMessages,
  ConversationRow,
  replyThreadId,
  toConversationRow,
} from '../../domain/conversations/conversation-rules';
import { EntityNotFoundError } from '../../domain/domain-errors';
import { ConciergeMessage, ConciergeRequest, StaffMember, StayAggregate } from '../../domain/models/domain.models';
import { CLOCK_PORT, ClockPort } from '../../domain/ports/clock.port';
import {
  STAY_REPOSITORY_PORT,
  StayRepositoryPort,
  STORAGE_SIGNER_PORT,
  StorageSignerPort,
} from '../../domain/ports/repository.ports';
import { ConversationListQueryDto, ConversationMessagesQueryDto } from './conversation.dto';

export type ConversationMessageView = Omit<ConversationMessage, 'photoStoragePath'> & { photoUrl: string | null };

export const CONVERSATION_LIST_SPEC = {
  sortable: ['lastMessageAt'],
  defaultSort: { field: 'lastMessageAt', direction: 'desc' as const },
};
const MESSAGE_LIST_SPEC = { sortable: ['at'], defaultSort: { field: 'at', direction: 'asc' as const } };

/**
 * Messages inbox over the stays' Resort Host threads. Staff replies are appended to the thread
 * the guest last wrote in, so guests read them through `GET /stays/:guestUuid/concierge-requests`.
 */
@Injectable()
export class ConversationsService {
  constructor(
    @Inject(STAY_REPOSITORY_PORT) private readonly stays: StayRepositoryPort,
    @Inject(STORAGE_SIGNER_PORT) private readonly signer: StorageSignerPort,
    @Inject(CLOCK_PORT) private readonly clock: ClockPort,
  ) {}

  async list(dto: ConversationListQueryDto): Promise<PaginatedResult<ConversationRow>> {
    const query = toListQuery(dto, CONVERSATION_LIST_SPEC);
    const page = await this.stays.pageConversations({
      unread: dto.unread,
      awaitingReply: dto.awaitingReply,
      q: query.q,
      page: query.page,
      pageSize: query.pageSize,
      direction: query.sort.direction,
    });
    const rows = page.data.map(toConversationRow).filter((row): row is ConversationRow => row !== null);
    return new PaginatedResult(rows, page.meta);
  }

  /** Page 1 holds the newest messages; inside a page messages run oldest → newest. */
  async messages(stayId: string, dto: ConversationMessagesQueryDto): Promise<PaginatedResult<ConversationMessageView>> {
    const query = toListQuery(dto, MESSAGE_LIST_SPEC);
    const newestFirst = conversationMessages(await this.require(stayId)).reverse();
    const page = sliceToPage(newestFirst, query);
    const views = await Promise.all([...page.data].reverse().map((message) => this.view(message)));
    return new PaginatedResult(views, page.meta);
  }

  async reply(stayId: string, text: string, staff: StaffMember): Promise<ConversationMessageView> {
    const stay = await this.require(stayId);
    const at = this.clock.now().toISOString();
    const message: ConciergeMessage = {
      sender: 'CONCIERGE', senderStaffId: staff.staffId, senderName: staff.shortName || staff.fullName, text: text.trim(), sentAt: at,
    };
    const threadId = replyThreadId(stay);
    if (threadId) await this.stays.appendConciergeMessage(stayId, threadId, message);
    else await this.stays.createConciergeRequest(stayId, staffThread(stay, message));
    const updated = await this.stays.updateStay(stayId, (current) => ({ ...current, conversationReadAt: at }));
    return this.view(conversationMessages(updated).at(-1) as ConversationMessage);
  }

  async markRead(stayId: string): Promise<ConversationRow | null> {
    await this.require(stayId);
    const at = this.clock.now().toISOString();
    return toConversationRow(await this.stays.updateStay(stayId, (current) => ({ ...current, conversationReadAt: at })));
  }

  async unreadCount(): Promise<{ unreadConversations: number; unreadMessages: number }> {
    const rows = (await this.stays.listUnreadConversations()).map(toConversationRow);
    return {
      unreadConversations: rows.filter((row) => row && row.unreadCount > 0).length,
      unreadMessages: rows.reduce((sum, row) => sum + (row?.unreadCount ?? 0), 0),
    };
  }

  private async view(message: ConversationMessage): Promise<ConversationMessageView> {
    const { photoStoragePath, ...rest } = message;
    const photoUrl = photoStoragePath ? (await this.signer.generateSignedGetUrl(photoStoragePath)).downloadUrl ?? null : null;
    return { ...rest, photoUrl };
  }

  private async require(stayId: string): Promise<StayAggregate> {
    const stay = await this.stays.findByStayId(stayId);
    if (!stay) throw new EntityNotFoundError('Stay', stayId);
    return stay;
  }
}

/** Thread for a conversation the staff opens before the guest wrote (closed: it is not a request). */
function staffThread(stay: StayAggregate, message: ConciergeMessage): ConciergeRequest {
  return {
    requestId: `req_${crypto.randomUUID()}`,
    stayId: stay.stayId, villaId: stay.villaId, villaName: stay.villaName, guestNames: stay.guestProfile.name,
    type: 'ask', category: 'Messages', priority: 'NORMAL', title: 'Resort Host', timeLabel: '', location: '',
    status: 'Completed', currentStep: 4, assignedStaffId: message.senderStaffId ?? null, assignedTo: message.senderName,
    assignedDepartment: 'CONCIERGE', assignedAt: message.sentAt, notifiedAt: message.sentAt, details: '', notes: '',
    photoStoragePath: null, isCompleted: true, messages: [message], createdAt: message.sentAt, updatedAt: message.sentAt,
  };
}
