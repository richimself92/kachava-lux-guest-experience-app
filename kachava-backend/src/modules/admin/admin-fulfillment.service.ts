import { Inject, Injectable } from '@nestjs/common';
import { ListQueryDto, paginateInMemory, PaginatedResult, toListQuery } from '../../common/listing/list-query';
import { MidStayFeedback } from '../../domain/models/domain.models';
import { STAY_REPOSITORY_PORT, StayRepositoryPort } from '../../domain/ports/repository.ports';

const FEEDBACK_LIST_SPEC = {
  sortable: ['createdAt', 'rating'],
  defaultSort: { field: 'createdAt', direction: 'desc' as const },
};

@Injectable()
export class AdminFulfillmentService {
  constructor(
    @Inject(STAY_REPOSITORY_PORT)
    private readonly stayRepo: StayRepositoryPort,
  ) {}

  async listMidStayFeedback(dto: ListQueryDto): Promise<PaginatedResult<MidStayFeedback>> {
    const query = toListQuery(dto, FEEDBACK_LIST_SPEC);
    const feedback = await this.stayRepo.listMidStayFeedbackAcrossStays();
    return paginateInMemory(feedback, query, {
      searchText: (f) => `${f.note} ${f.guestNames} ${f.villaName}`,
      sortValue: (f, field) => (field === 'rating' ? f.rating ?? null : f.createdAt),
    });
  }
}
