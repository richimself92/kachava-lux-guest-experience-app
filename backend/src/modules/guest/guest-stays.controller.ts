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
import { StepUpVerifiedGuard } from '../../common/guards/step-up-verified.guard';
import {
  GuestStayView,
  toGuestBookingView,
  toGuestConciergeRequestView,
  toGuestFeedbackView,
  toGuestFolioSummaryView,
  toGuestFolioView,
  toGuestLarderOrderView,
  toGuestPersonalizationView,
  toGuestStayView,
  toGuestTransferView,
} from '../../domain/guest-stay-view';
import { ConciergeRequest, FolioSummary, LarderOrderItem, StayAggregate } from '../../domain/models/domain.models';
import {
  ChangeBookingDto,
  CreateBookingDto,
  CreateConciergeMessageDto,
  CreateConciergeRequestDto,
  CreateMidStayCheckInDto,
  ExpressCheckoutDto,
  GenerateUploadUrlDto,
  UpdateJourneyDto,
  UpdateLarderOrderDto,
  UpdatePersonalizationDto,
  UpdateServiceOrderDto,
  UpdateTransferDto,
  VerifyStepUpDto,
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
  ) {}

  @Get()
  async getStayAggregate(@CurrentStay() stay: StayAggregate): Promise<GuestStayView> {
    return toGuestStayView(stay, await this.photos.resolverFor(stay.conciergeRequests));
  }

  /** Skipped ("Not now") and self-completed journey tasks; only the lists sent are replaced. */
  @Put('journey')
  updateJourney(@CurrentStay() stay: StayAggregate, @Body() dto: UpdateJourneyDto) {
    return this.guestService.updateJourney(stay, dto);
  }

  @Post('verify-step-up')
  verifyStepUp(
    @CurrentStay() stay: StayAggregate,
    @Body() dto: VerifyStepUpDto,
  ) {
    return this.guestService.verifyStepUp(stay, dto);
  }

  @Post('verify-stepup')
  verifyStepUpAlias(
    @CurrentStay() stay: StayAggregate,
    @Body() dto: VerifyStepUpDto,
  ) {
    return this.guestService.verifyStepUp(stay, dto);
  }

  @Patch('transfer')
  updateTransfer(
    @CurrentStay() stay: StayAggregate,
    @Body() dto: UpdateTransferDto,
  ) {
    return this.guestService.updateTransfer(stay, dto).then(toGuestTransferView);
  }

  @Patch('transport')
  updateTransportAlias(
    @CurrentStay() stay: StayAggregate,
    @Body() dto: UpdateTransferDto,
  ) {
    return this.guestService.updateTransfer(stay, dto).then(toGuestTransferView);
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

  /** Legacy route of the same per-service order (service id in the body). */
  @Put('larder')
  async updateLarder(
    @CurrentStay() stay: StayAggregate,
    @Body() dto: UpdateLarderOrderDto,
  ) {
    return toGuestOrdersView(await this.guestService.updateServiceOrder(stay, dto.serviceId, dto));
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

  @Get('folio')
  getFolio(@CurrentStay() stay: StayAggregate) {
    return toGuestFolioView(stay);
  }

  @Post('folio/checkout')
  @UseGuards(StepUpVerifiedGuard)
  async expressCheckout(
    @CurrentStay() stay: StayAggregate,
    @Body() dto: ExpressCheckoutDto,
  ) {
    const settled = await this.guestService.processExpressCheckout(stay, dto);
    return { ...toGuestFolioView(settled), status: settled.status };
  }

  private async requestViews(requests: ConciergeRequest[]) {
    const photoUrlOf = await this.photos.resolverFor(requests);
    return requests.map((request) => toGuestConciergeRequestView(request, photoUrlOf));
  }
}
