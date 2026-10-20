import {
  BadRequestException,
  Inject,
  Injectable,
} from '@nestjs/common';
import * as crypto from 'crypto';
import { GuestTokenGuard } from '../../common/guards/guest-token.guard';
import {
  Department,
  ExperienceBooking,
  FolioItem,
  FolioSummary,
  LarderOrderItem,
  StayAggregate,
} from '../../domain/models/domain.models';
import {
  CATALOG_REPOSITORY_PORT,
  CatalogRepositoryPort,
  STAY_REPOSITORY_PORT,
  StayRepositoryPort,
} from '../../domain/ports/repository.ports';
import { CreateBookingDto, UpdateLarderOrderDto } from './dto/guest.dto';
import { GuestAlertFolioHelper } from './guest-alert-folio.helper';

@Injectable()
export class GuestBookingService {
  constructor(
    @Inject(STAY_REPOSITORY_PORT)
    private readonly stayRepo: StayRepositoryPort,
    @Inject(CATALOG_REPOSITORY_PORT)
    private readonly catalogRepo: CatalogRepositoryPort,
    private readonly alertFolioHelper: GuestAlertFolioHelper,
  ) {}

  async updateLarderOrder(
    stay: StayAggregate,
    dto: UpdateLarderOrderDto,
  ): Promise<{ orders: LarderOrderItem[]; folioSummary: FolioSummary }> {
    const orders = await this.buildLarderOrderItems(stay, dto);
    const larderTotal = orders.reduce((acc, o) => acc + o.lineTotalUSD, 0);
    const updatedFolioItems = this.upsertLarderFolioItem(
      stay.folioItems,
      larderTotal,
      orders.length,
    );
    const folioSummary = this.alertFolioHelper.recalculateFolioSummary(
      stay.folioSummary,
      updatedFolioItems,
    );
    const result = await this.stayRepo.replaceLarderOrders(
      stay.stayId,
      orders,
      updatedFolioItems,
      folioSummary,
    );
    GuestTokenGuard.invalidateCache();
    await this.alertFolioHelper.emitAlert(stay, {
      category: 'LARDER',
      severity: 'NORMAL',
      title: `${stay.villaName} Larder Stocking Order ($${larderTotal} USD)`,
      summary: `${orders.length} artisanal larder items requested for pre-arrival provisioning.`,
      sourceDocumentPath: `stays/${stay.stayId}/larder_orders`,
      assignedDepartment: 'CULINARY',
    });
    return result;
  }

  async createBooking(
    stay: StayAggregate,
    dto: CreateBookingDto,
  ): Promise<ExperienceBooking> {
    const normalizedCat = (dto.category || dto.bookingType || 'explore').toLowerCase();
    const partySize = dto.partySize ?? 2;
    if (normalizedCat.includes('yacht') && partySize > 12) {
      throw new BadRequestException(
        'Galeon 470 Sky Private Yacht Charter strictly enforces a maximum capacity of 12 guests.',
      );
    }

    const resolved = await this.resolveBookingPricing(normalizedCat, dto, partySize);
    const booking = this.constructBookingEntity(stay, dto, partySize, resolved);
    const folioItems = [...stay.folioItems];
    if (booking.priceChargedUSD > 0) {
      folioItems.push({
        folioItemId: `folio_${booking.bookingId}`,
        displayOrder: folioItems.length + 1,
        title: booking.title,
        subtitle: `${booking.scheduledDate} · ${booking.scheduledTimeSlot}`,
        category: 'EXCURSION',
        badgeLabel: null,
        isComplimentary: false,
        originalValuationUSD: booking.originalValuationUSD,
        chargedAmountUSD: booking.priceChargedUSD,
        status: 'PRE_AUTHORIZED',
        sourceRefId: booking.bookingId,
        createdAt: booking.createdAt,
      });
    }
    const folioSummary = this.alertFolioHelper.recalculateFolioSummary(
      stay.folioSummary,
      folioItems,
    );
    const saved = await this.stayRepo.createBooking(
      stay.stayId,
      booking,
      folioItems,
      folioSummary,
    );
    GuestTokenGuard.invalidateCache();
    await this.alertFolioHelper.emitAlert(stay, {
      category: 'BOOKING',
      severity: 'NORMAL',
      title: `${stay.villaName} New Booking: ${booking.title}`,
      summary: `Scheduled for ${booking.scheduledDate} (${booking.scheduledTimeSlot}) for ${partySize} guests.`,
      sourceDocumentPath: `stays/${stay.stayId}/experience_bookings/${booking.bookingId}`,
      assignedDepartment: booking.assignedDepartment,
    });
    return saved;
  }

  private upsertLarderFolioItem(
    folioItems: FolioItem[],
    larderTotal: number,
    itemCount: number,
  ): FolioItem[] {
    if (folioItems.some((fi) => fi.category === 'LARDER')) {
      return folioItems.map((fi) =>
        fi.category === 'LARDER'
          ? { ...fi, originalValuationUSD: larderTotal, chargedAmountUSD: larderTotal }
          : fi,
      );
    }
    if (larderTotal <= 0) return [...folioItems];
    return [
      ...folioItems,
      {
        folioItemId: 'folio-4',
        displayOrder: folioItems.length + 1,
        title: 'Stock My Villa Curated Larder',
        subtitle: `Pre-Arrival Provisioning (${itemCount} Artisanal Items)`,
        category: 'LARDER',
        badgeLabel: null,
        isComplimentary: false,
        originalValuationUSD: larderTotal,
        chargedAmountUSD: larderTotal,
        status: 'PRE_AUTHORIZED',
        sourceRefId: 'larder-cart',
        createdAt: new Date().toISOString(),
      },
    ];
  }

  private async buildLarderOrderItems(
    stay: StayAggregate,
    dto: UpdateLarderOrderDto,
  ): Promise<LarderOrderItem[]> {
    const catalog = await this.catalogRepo.getLarderCatalog();
    const now = new Date().toISOString();
    return dto.items
      .filter((line) => line.quantity > 0)
      .flatMap((line) => {
        const item = catalog.find((c) => c.id === line.itemId);
        if (!item) return [];
        return [
          {
            orderItemId: `larder_${stay.stayId}_${item.id}`,
            stayId: stay.stayId,
            villaId: stay.villaId,
            villaName: stay.villaName,
            guestNames: stay.guestProfile.name,
            catalogItemId: item.id,
            name: item.name,
            category: item.category,
            unitPriceUSD: item.price,
            quantity: line.quantity,
            lineTotalUSD: item.price * line.quantity,
            storageType: item.storageType,
            provisioningStatus: 'Pending',
            assignedStaffId: 'staff_eduardo',
            assignedStaffName: 'Eduardo Rivera',
            assignedDepartment: 'CULINARY' as const,
            assignedAt: now,
            updatedAt: now,
          },
        ];
      });
  }

  private constructBookingEntity(
    stay: StayAggregate,
    dto: CreateBookingDto,
    partySize: number,
    resolved: {
      bookingType: ExperienceBooking['bookingType'];
      adminCategory: string;
      title: string;
      originalValuationUSD: number;
      priceChargedUSD: number;
      department: Department;
      assignedStaffId: string;
      assignedStaffName: string;
    },
  ): ExperienceBooking {
    const now = new Date().toISOString();
    return {
      bookingId: `bk_${crypto.randomBytes(4).toString('hex')}`,
      stayId: stay.stayId,
      villaId: stay.villaId,
      villaName: stay.villaName,
      guestNames: stay.guestProfile.name,
      bookingType: resolved.bookingType,
      category: resolved.adminCategory,
      catalogRefId: dto.catalogRefId,
      title: dto.title || resolved.title,
      scheduledDate: dto.scheduledDate,
      scheduledTimeSlot: dto.scheduledTimeSlot,
      partySize,
      isIncludedWithStay: resolved.priceChargedUSD === 0,
      originalValuationUSD: resolved.originalValuationUSD,
      priceChargedUSD: resolved.priceChargedUSD,
      metadata: dto.metadata || {},
      status: 'REQUESTED',
      cancellationReason: '',
      assignedStaffId: resolved.assignedStaffId,
      assignedStaffName: resolved.assignedStaffName,
      assignedDepartment: resolved.department,
      assignedAt: now,
      notifiedAt: now,
      adminNotes: 'Automatically routed from Guest Experience Portal.',
      createdAt: now,
    };
  }

  private async resolveBookingPricing(
    normalizedCat: string,
    dto: CreateBookingDto,
    partySize: number,
  ) {
    if (normalizedCat.includes('yacht')) {
      const yacht = await this.catalogRepo.getYachtCatalog();
      const pkg = yacht.packages.find((p) => p.id === dto.catalogRefId) || yacht.packages[0];
      return {
        bookingType: 'YACHT_CHARTER' as const,
        adminCategory: 'YACHT',
        title: `Kachava Caribe · ${pkg.title}`,
        originalValuationUSD: pkg.valuationUSD,
        priceChargedUSD: pkg.upgradePriceUSD,
        department: 'MARINE' as Department,
        assignedStaffId: 'staff_velasco',
        assignedStaffName: 'Capt. Eduardo Velasco',
      };
    }
    if (normalizedCat.includes('dining')) {
      const extraGuests = Math.max(0, partySize - 2);
      return {
        bookingType: 'PRIVATE_DINING' as const,
        adminCategory: 'DINING',
        title: "Chef Mateo's Fire & Copal Table",
        originalValuationUSD: 650 + extraGuests * 180,
        priceChargedUSD: extraGuests * 180,
        department: 'CULINARY' as Department,
        assignedStaffId: 'staff_mateo',
        assignedStaffName: 'Executive Chef Mateo',
      };
    }
    if (normalizedCat.includes('included') || normalizedCat.includes('privilege')) {
      return {
        bookingType: 'INCLUDED_PRIVILEGE' as const,
        adminCategory: 'PRIVILEGE',
        title: dto.title || 'Included Sanctuary Privilege',
        originalValuationUSD: 350,
        priceChargedUSD: 0,
        department: 'WELLNESS' as Department,
        assignedStaffId: 'staff_sofia',
        assignedStaffName: 'Sofia Valdés',
      };
    }
    const exps = await this.catalogRepo.getExperiencesCatalog();
    const exp = exps.find((e) => e.id === dto.catalogRefId);
    const unitPrice = exp ? exp.basePriceUSD : 380;
    return {
      bookingType: 'EXCURSION' as const,
      adminCategory: 'EXCURSION',
      title: exp?.title || dto.title || 'Curated Sanctuary Excursion',
      originalValuationUSD: unitPrice * partySize,
      priceChargedUSD: exp?.isIncluded ? 0 : unitPrice * partySize,
      department: 'CONCIERGE' as Department,
      assignedStaffId: 'staff_eduardo',
      assignedStaffName: 'Eduardo Rivera',
    };
  }
}
