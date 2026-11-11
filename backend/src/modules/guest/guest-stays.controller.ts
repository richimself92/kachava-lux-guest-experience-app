import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Patch,
  Post,
  Put,
  UseGuards,
} from '@nestjs/common';
import { CurrentStay } from '../../common/decorators/auth.decorators';
import { GuestTokenGuard } from '../../common/guards/guest-token.guard';
import {
  GuestStayView,
  toGuestBookingView,
  toGuestConciergeRequestView,
  toGuestFeedbackView,
  toGuestFolioSummaryView,
  toGuestLarderOrderView,
  toGuestPersonalizationView,
  toGuestStayView,
} from '../../domain/guest-stay-view';
import { ConciergeRequest, FolioSummary, LarderOrderItem, StayAggregate } from '../../domain/models/domain.models';
import { GuestRealtimeChannels, guestRealtimeChannels } from '../../domain/realtime/realtime-signal';
import { RealtimeChannels } from '../realtime/realtime-channels.service';
import {
  ChangeBookingDto,
  CreateBookingDto,
  CreateConciergeMessageDto,
  CreateConciergeRequestDto,
  CreateMidStayCheckInDto,
  GenerateUploadUrlDto,
  UpdateJourneyDto,
  UpdatePersonalizationDto,
  UpdateServiceOrderDto,
} from './dto/guest.dto';
import { GuestPhotoLinks } from './guest-photo-links.service';
import { GuestRequestChangesService } from './guest-request-changes.service';
import { GuestService } from './guest.service';

function toGuestOrdersView(result: { orders: LarderOrderItem[]; folioSummary: FolioSummary }) {
  return {
    orders: result.orders.map(toGuestLarderOrderView),
    folioSummary: toGuestFolioSummaryView(result.folioSummary),
  };
}

/**
 * Guest capability routes. Every response is built from the ADR-007 allow-list projections in
 * `domain/guest-stay-view.ts`; the stored aggregate itself is never returned to a guest.
 */
@Controller('stays/:guestUuid')
@UseGuards(GuestTokenGuard)
export class GuestStaysController {
  constructor(
    private readonly guestService: GuestService,
    private readonly changes: GuestRequestChangesService,
    private readonly photos: GuestPhotoLinks,
    private readonly realtime: RealtimeChannels,
  ) {}

  /** The guest-safe view plus the ADR-012 signal channels this guest may listen to. */
  @Get()
  async getStayAggregate(
    @CurrentStay() stay: StayAggregate,
  ): Promise<GuestStayView & { realtime: GuestRealtimeChannels }> {
    const view = toGuestStayView(stay, await this.photos.resolverFor(stay.conciergeRequests));
    return { ...view, realtime: guestRealtimeChannels(await this.realtime.ensureStayChannel(stay)) };
  }

  /** Skipped ("Not now") and self-completed journey tasks; only the lists sent are replaced. */
  @Put('journey')
  updateJourney(@CurrentStay() stay: StayAggregate, @Body() dto: UpdateJourneyDto) {
    return this.guestService.updateJourney(stay, dto);
  }

  @Patch('personalization')
  updatePersonalization(
    @CurrentStay() stay: StayAggregate,
    @Body() dto: UpdatePersonalizationDto,
  ) {
    return this.guestService.updatePersonalization(stay, dto).then(toGuestPersonalizationView);
  }

  /** The guest's order for ONE ORDER service; orders of other services are kept. */
  @Put('orders/:serviceId')
  async updateServiceOrder(
    @CurrentStay() stay: StayAggregate,
    @Param('serviceId') serviceId: string,
    @Body() dto: UpdateServiceOrderDto,
  ) {
    return toGuestOrdersView(await this.guestService.updateServiceOrder(stay, serviceId, dto));
  }

  @Get('bookings')
  listBookings(@CurrentStay() stay: StayAggregate) {
    return stay.experienceBookings.map(toGuestBookingView);
  }

  @Post('bookings')
  createBooking(
    @CurrentStay() stay: StayAggregate,
    @Body() dto: CreateBookingDto,
  ) {
    return this.guestService.createBooking(stay, dto).then(toGuestBookingView);
  }

  /** Cancel while REQUESTED (422 afterwards). */
  @Post('bookings/:bookingId/cancel')
  @HttpCode(HttpStatus.OK)
  cancelBooking(@CurrentStay() stay: StayAggregate, @Param('bookingId') bookingId: string) {
    return this.changes.cancelBooking(stay, bookingId).then(toGuestBookingView);
  }

  /** New date, time or party size while REQUESTED (422 afterwards). */
  @Patch('bookings/:bookingId')
  changeBooking(
    @CurrentStay() stay: StayAggregate,
    @Param('bookingId') bookingId: string,
    @Body() dto: ChangeBookingDto,
  ) {
    return this.changes.changeBooking(stay, bookingId, dto).then(toGuestBookingView);
  }

  @Get('concierge-requests')
  listConciergeRequests(@CurrentStay() stay: StayAggregate) {
    return this.requestViews(stay.conciergeRequests);
  }

  @Post('concierge-requests')
  async createConciergeRequest(
    @CurrentStay() stay: StayAggregate,
    @Body() dto: CreateConciergeRequestDto,
  ) {
    const created = await this.guestService.createConciergeRequest(stay, dto);
    return (await this.requestViews([created]))[0];
  }

  @Post('concierge-requests/upload-url')
  generateUploadUrl(
    @CurrentStay() stay: StayAggregate,
    @Body() dto: GenerateUploadUrlDto,
  ) {
    return this.guestService.generateUploadUrl(stay, dto);
  }

  /** Text and/or a photo (`photoStoragePath` from upload-url) appended to the thread. */
  @Post('concierge-requests/:requestId/messages')
  async appendConciergeMessage(
    @CurrentStay() stay: StayAggregate,
    @Param('requestId') requestId: string,
    @Body() dto: CreateConciergeMessageDto,
  ) {
    const updated = await this.guestService.appendConciergeMessage(stay, requestId, dto);
    return (await this.requestViews([updated]))[0];
  }

  @Post('midstay-checkin')
  submitMidStayCheckIn(
    @CurrentStay() stay: StayAggregate,
    @Body() dto: CreateMidStayCheckInDto,
  ) {
    return this.guestService.submitMidStayCheckIn(stay, dto).then(toGuestFeedbackView);
  }

  private async requestViews(requests: ConciergeRequest[]) {
    const photoUrlOf = await this.photos.resolverFor(requests);
    return requests.map((request) => toGuestConciergeRequestView(request, photoUrlOf));
  }
}
