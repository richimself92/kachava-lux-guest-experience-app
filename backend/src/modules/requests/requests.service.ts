import { Inject, Injectable } from '@nestjs/common';
import { PaginatedResult, toListQuery } from '../../common/listing/list-query';
import { BusinessRuleError, EntityNotFoundError } from '../../domain/domain-errors';
import { CLOCK_PORT, ClockPort } from '../../domain/ports/clock.port';
import {
  SERVICE_REQUEST_REPOSITORY_PORT,
  ServiceRequestRepositoryPort,
  STAY_REPOSITORY_PORT,
  StayRepositoryPort,
} from '../../domain/ports/repository.ports';
import { RequestRef } from '../../domain/requests/request-transitions';
import { ServiceRequestEntry } from '../../domain/requests/service-requests';
import { RequestListQueryDto, TransitionRequestDto } from './request.dto';

/** Wire shape: the queue entry plus `id`. */
export type RequestView = ServiceRequestEntry & { id: string };

const REQUEST_LIST_SPEC = {
  sortable: ['at'],
  defaultSort: { field: 'at', direction: 'asc' as const },
};

function nextDay(isoDate: string): string {
  const [year, month, day] = isoDate.split('-').map(Number);
  return new Date(Date.UTC(year, month - 1, day + 1)).toISOString().slice(0, 10);
}

function toView(entry: ServiceRequestEntry): RequestView {
  return { id: entry.requestId, ...entry };
}

/** Section request queues: guest bookings and orders, paged in Firestore, moved by staff. */
@Injectable()
export class RequestsService {
  constructor(
    @Inject(SERVICE_REQUEST_REPOSITORY_PORT) private readonly requests: ServiceRequestRepositoryPort,
    @Inject(STAY_REPOSITORY_PORT) private readonly stays: StayRepositoryPort,
    @Inject(CLOCK_PORT) private readonly clock: ClockPort,
  ) {}

  async list(dto: RequestListQueryDto): Promise<PaginatedResult<RequestView>> {
    const query = toListQuery(dto, REQUEST_LIST_SPEC);
    if (dto.from && dto.to && dto.from > dto.to) throw new BusinessRuleError('from must not be after to');
    const page = await this.requests.page({
      section: dto.section,
      status: dto.status,
      fromAt: dto.from,
      toAtExclusive: dto.to ? nextDay(dto.to) : undefined,
      q: query.q,
      page: query.page,
      pageSize: query.pageSize,
      direction: query.sort.direction,
    });
    return new PaginatedResult(page.data.map(toView), page.meta);
  }

  async get(requestId: string): Promise<RequestView> {
    return toView(await this.require(requestId));
  }

  async transition(requestId: string, dto: TransitionRequestDto): Promise<RequestView> {
    const entry = await this.require(requestId);
    const ref: RequestRef =
      entry.kind === 'BOOKING' ? { kind: 'BOOKING', id: entry.requestId } : { kind: 'ORDER', id: entry.serviceId };
    await this.stays.transitionServiceRequest(entry.stayId, ref, {
      action: dto.action,
      reason: dto.reason,
      at: this.clock.now().toISOString(),
    });
    return this.get(requestId);
  }

  private async require(requestId: string): Promise<ServiceRequestEntry> {
    const entry = await this.requests.findById(requestId);
    if (!entry) throw new EntityNotFoundError('Request', requestId);
    return entry;
  }
}
