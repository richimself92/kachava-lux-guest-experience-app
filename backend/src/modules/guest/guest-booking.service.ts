import { Inject, Injectable } from '@nestjs/common';
import * as crypto from 'crypto';
import {
  buildServiceSnapshot,
  resolveOrderLines,
  ResolvedLine,
} from '../../domain/catalog/catalog-rules';
import { CatalogItem, CatalogService, ServiceSnapshot } from '../../domain/catalog/catalog.models';
import { BusinessRuleError, EntityNotFoundError } from '../../domain/domain-errors';
import {
  ExperienceBooking,
  FolioSummary,
  LarderOrderItem,
  StayAggregate,
} from '../../domain/models/domain.models';
import {
  SERVICE_ITEM_REPOSITORY_PORT,
  SERVICE_REPOSITORY_PORT,
  ServiceItemRepositoryPort,
  ServiceRepositoryPort,
  STAY_REPOSITORY_PORT,
  StayRepositoryPort,
} from '../../domain/ports/repository.ports';
import { CreateBookingDto, UpdateLarderOrderDto } from './dto/guest.dto';
import { GuestAlertFolioHelper } from './guest-alert-folio.helper';

interface OrderableService {
  service: CatalogService;
  items: CatalogItem[];
}

/**
 * Guest orders and bookings. Every name and price comes from the admin-managed catalog and is
 * copied into the stay as a snapshot; unknown services are 404, unavailable ones 422.
 */
@Injectable()
export class GuestBookingService {
  constructor(
    @Inject(STAY_REPOSITORY_PORT)
    private readonly stayRepo: StayRepositoryPort,
    @Inject(SERVICE_REPOSITORY_PORT)
    private readonly services: ServiceRepositoryPort,
    @Inject(SERVICE_ITEM_REPOSITORY_PORT)
    private readonly items: ServiceItemRepositoryPort,
    private readonly alerts: GuestAlertFolioHelper,
  ) {}

  async updateLarderOrder(
    stay: StayAggregate,
    dto: UpdateLarderOrderDto,
  ): Promise<{ orders: LarderOrderItem[]; folioSummary: FolioSummary }> {
    const { service, items } = await this.loadService(dto.serviceId);
    if (service.usageType !== 'ORDER') {
      throw new BusinessRuleError(`Service ${service.serviceId} does not take orders`);
    }
    const requested = dto.items.filter((line) => line.quantity > 0);
    const lines = resolveOrderLines(service, items, requested);
    const snapshot = buildServiceSnapshot(service, lines, 1, new Date().toISOString());
    const orders = this.toLarderLines(stay, service, lines, snapshot);
    const charge = { title: service.name.en, chargeToFolio: service.pricing.chargeToFolio };
    return this.stayRepo.replaceLarderOrders(stay.stayId, orders, charge, () =>
      this.alerts.buildAlert(stay, {
        category: 'LARDER',
        severity: 'NORMAL',
        title: `${stay.villaName}: ${service.name.en}`,
        summary: `${orders.length} items requested.`,
        sourceDocumentPath: `stays/${stay.stayId}`,
        assignedDepartment: service.operation.responsibleDepartment,
      }),
    );
  }

  async createBooking(stay: StayAggregate, dto: CreateBookingDto): Promise<ExperienceBooking> {
    const { service, items } = await this.loadService(dto.serviceId);
    if (service.usageType === 'ORDER') {
      throw new BusinessRuleError(`Service ${service.serviceId} takes orders, not bookings`);
    }
    const partySize = dto.partySize ?? Math.max(stay.guestsCount, 1);
    this.assertBookable(service, dto.scheduledDate, partySize);
    const lines: ResolvedLine[] = dto.itemId
      ? resolveOrderLines(service, items, [{ itemId: dto.itemId, quantity: 1 }])
      : (resolveOrderLines(service, items, []), [{ item: null, quantity: 1 }]);
    const now = new Date().toISOString();
    const snapshot = buildServiceSnapshot(service, lines, partySize, now);
    const booking = this.toBooking(stay, service, dto, partySize, snapshot, now);
    return this.stayRepo.createBooking(stay.stayId, booking, () =>
      this.alerts.buildAlert(stay, {
        category: 'BOOKING',
        severity: 'NORMAL',
        title: `${stay.villaName}: ${booking.title}`,
        summary: `${booking.scheduledDate} ${booking.scheduledTimeSlot} · ${partySize} guests`.trim(),
        sourceDocumentPath: `stays/${stay.stayId}`,
        assignedDepartment: booking.assignedDepartment,
      }),
    );
  }

  private async loadService(serviceId: string): Promise<OrderableService> {
    const service = await this.services.findById(serviceId);
    if (!service) throw new EntityNotFoundError('Service', serviceId);
    const items = await this.items.list({ serviceId });
    return { service, items };
  }

  private assertBookable(service: CatalogService, date: string, partySize: number): void {
    const { minGuests, maxGuests, blockedDates } = service.availability;
    if (minGuests !== null && partySize < minGuests) {
      throw new BusinessRuleError(`At least ${minGuests} guests are required`);
    }
    if (maxGuests !== null && partySize > maxGuests) {
      throw new BusinessRuleError(`At most ${maxGuests} guests are allowed`);
    }
    if (blockedDates.includes(date)) throw new BusinessRuleError(`${date} is not available`);
  }

  private toLarderLines(
    stay: StayAggregate,
    service: CatalogService,
    lines: ResolvedLine[],
    snapshot: ServiceSnapshot,
  ): LarderOrderItem[] {
    const now = snapshot.capturedAt;
    return lines.map(({ item }, index) => {
      const line = snapshot.lines[index];
      return {
        orderItemId: `larder_${stay.stayId}_${line.itemId}`,
        stayId: stay.stayId,
        villaId: stay.villaId,
        villaName: stay.villaName,
        guestNames: stay.guestProfile.name,
        serviceId: service.serviceId,
        catalogItemId: line.itemId ?? '',
        name: line.name.en,
        itemName: line.name,
        category: item?.category ?? '',
        unitPriceUSD: line.unitPriceUSD ?? 0,
        quantity: line.quantity,
        lineTotalUSD: line.lineTotalUSD ?? 0,
        storageType: item?.storage ?? '',
        provisioningStatus: 'Pending',
        assignedStaffId: service.operation.responsibleStaffId,
        assignedStaffName: null,
        assignedDepartment: service.operation.responsibleDepartment,
        assignedAt: null,
        updatedAt: now,
      };
    });
  }

  private toBooking(
    stay: StayAggregate,
    service: CatalogService,
    dto: CreateBookingDto,
    partySize: number,
    snapshot: ServiceSnapshot,
    now: string,
  ): ExperienceBooking {
    const total = snapshot.totalUSD ?? 0;
    return {
      bookingId: `bk_${crypto.randomUUID()}`,
      stayId: stay.stayId,
      villaId: stay.villaId,
      villaName: stay.villaName,
      guestNames: stay.guestProfile.name,
      serviceId: service.serviceId,
      itemId: snapshot.lines[0]?.itemId ?? null,
      section: service.section,
      usageType: service.usageType,
      category: service.category,
      snapshot,
      title: snapshot.lines[0]?.itemId ? `${service.name.en} · ${snapshot.lines[0].name.en}` : service.name.en,
      scheduledDate: dto.scheduledDate,
      scheduledTimeSlot: dto.scheduledTimeSlot ?? '',
      partySize,
      isIncludedWithStay: service.pricing.mode === 'INCLUDED',
      originalValuationUSD: total,
      priceChargedUSD: total,
      metadata: dto.metadata ?? {},
      status: 'REQUESTED',
      cancellationReason: '',
      assignedStaffId: service.operation.responsibleStaffId,
      assignedStaffName: null,
      assignedDepartment: service.operation.responsibleDepartment,
      assignedAt: null,
      notifiedAt: null,
      adminNotes: '',
      createdAt: now,
    };
  }
}
