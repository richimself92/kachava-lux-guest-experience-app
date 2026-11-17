import { Inject, Injectable } from '@nestjs/common';
import { magicLinkBase } from '../../common/config/guest-portal';
import { ListQuery, PaginatedResult, toListQuery } from '../../common/listing/list-query';
import { definedFields } from '../../common/validation/patch';
import { BusinessRuleError, EntityNotFoundError } from '../../domain/domain-errors';
import { StayAggregate } from '../../domain/models/domain.models';
import { CLOCK_PORT, ClockPort } from '../../domain/ports/clock.port';
import {
  STAY_REPOSITORY_PORT,
  StayDateField,
  StayRepositoryPort,
  TRIP_REPOSITORY_PORT,
  TripRepositoryPort,
} from '../../domain/ports/repository.ports';
import {
  buildStayFolio,
  GuestProfileView,
  GuestRow,
  ReservationRow,
  StayDetail,
  StayFolio,
  toGuestProfileView,
  toGuestRow,
  toReservationRow,
  toStayDetail,
} from '../../domain/stays/stay-admin-views';
import { applyStayAdminPatch, StayAdminPatch, transitionStay } from '../../domain/stays/stay-transitions';
import { isFinalTripStatus } from '../../domain/trips/trip.models';
import { StayListQueryDto } from '../admin/dto/admin.dto';
import { UpdateReservationDto } from './reservation.dto';

/** `checkIn` / `checkOut` order (and range) the list; `checkInDate` is kept as an alias. */
export const RESERVATION_LIST_SPEC = {
  sortable: ['checkIn', 'checkOut', 'checkInDate'],
  defaultSort: { field: 'checkIn', direction: 'asc' as const },
};
const DATE_FIELDS: Record<string, StayDateField> = {
  checkIn: 'checkInDate',
  checkInDate: 'checkInDate',
  checkOut: 'checkOutDate',
};

/**
 * Reservations and Guests (plan v2): Firestore-paged stays (filters, guest-name keyword search,
 * date order and `count()`), detail, staff edits/status moves, folio and the guest profile.
 */
@Injectable()
export class ReservationsService {
  constructor(
    @Inject(STAY_REPOSITORY_PORT) private readonly stays: StayRepositoryPort,
    @Inject(TRIP_REPOSITORY_PORT) private readonly trips: TripRepositoryPort,
    @Inject(CLOCK_PORT) private readonly clock: ClockPort,
  ) {}

  async list(dto: StayListQueryDto): Promise<PaginatedResult<ReservationRow>> {
    const page = await this.page(dto, toListQuery(dto, RESERVATION_LIST_SPEC));
    const base = magicLinkBase();
    return new PaginatedResult(page.data.map((stay) => toReservationRow(stay, base)), page.meta);
  }

  async get(stayId: string): Promise<StayDetail> {
    return toStayDetail(await this.require(stayId), magicLinkBase());
  }

  /** Field edits apply first, then the optional status move; both commit in one transaction. */
  async update(stayId: string, dto: UpdateReservationDto, actor: string): Promise<StayDetail> {
    const { action, reason, ...fields } = definedFields(dto);
    const patch = fields as StayAdminPatch;
    const hasFields = Object.keys(patch).length > 0;
    if (!hasFields && !action) throw new BusinessRuleError('Nothing to update');
    const at = this.clock.now().toISOString();
    const updated = await this.stays.updateStay(stayId, (current) => {
      const edited = hasFields ? applyStayAdminPatch(current, patch, at) : current;
      return action ? transitionStay(edited, { action, reason }, actor, at) : edited;
    });
    return toStayDetail(updated, magicLinkBase());
  }

  async folio(stayId: string): Promise<StayFolio> {
    const stay = await this.require(stayId);
    return buildStayFolio(stay, await this.trips.listForStay(stayId));
  }

  /** One row per stay; open trips are read for the page's stays only. */
  async listGuests(dto: StayListQueryDto): Promise<PaginatedResult<GuestRow>> {
    const page = await this.page(dto, toListQuery(dto, RESERVATION_LIST_SPEC));
    const trips = await this.trips.listForStays(page.data.map((stay) => stay.stayId));
    const openTrips = new Map<string, number>();
    for (const trip of trips) {
      if (!isFinalTripStatus(trip.status)) openTrips.set(trip.stayId, (openTrips.get(trip.stayId) ?? 0) + 1);
    }
    return new PaginatedResult(page.data.map((stay) => toGuestRow(stay, openTrips.get(stay.stayId) ?? 0)), page.meta);
  }

  async guestProfile(stayId: string): Promise<GuestProfileView> {
    const stay = await this.require(stayId);
    return toGuestProfileView(stay, await this.trips.listForStay(stayId));
  }

  private page(dto: StayListQueryDto, query: ListQuery): Promise<PaginatedResult<StayAggregate>> {
    if (dto.from && dto.to && dto.from > dto.to) throw new BusinessRuleError('from must not be after to');
    return this.stays.pageStays({
      dateField: DATE_FIELDS[query.sort.field],
      status: dto.status,
      villaId: dto.villaId,
      from: dto.from,
      to: dto.to,
      q: query.q,
      page: query.page,
      pageSize: query.pageSize,
      direction: query.sort.direction,
    });
  }

  private async require(stayId: string): Promise<StayAggregate> {
    const stay = await this.stays.findByStayId(stayId);
    if (!stay) throw new EntityNotFoundError('Stay', stayId);
    return stay;
  }
}
