import {
  Body,
  Controller,
  Get,
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
import { StayAggregate } from '../../domain/models/domain.models';
import {
  CreateBookingDto,
  CreateConciergeMessageDto,
  CreateConciergeRequestDto,
  CreateMidStayCheckInDto,
  ExpressCheckoutDto,
  GenerateUploadUrlDto,
  UpdateLarderOrderDto,
  UpdatePersonalizationDto,
  UpdateTransferDto,
  VerifyStepUpDto,
} from './dto/guest.dto';
import { GuestService } from './guest.service';

/**
 * Guest capability routes. Every response is built from the ADR-007 allow-list projections in
 * `domain/guest-stay-view.ts`; the stored aggregate itself is never returned to a guest.
 */
@Controller('stays/:guestUuid')
@UseGuards(GuestTokenGuard)
export class GuestStaysController {
  constructor(private readonly guestService: GuestService) {}

  @Get()
  getStayAggregate(@CurrentStay() stay: StayAggregate): GuestStayView {
    return toGuestStayView(stay);
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

  @Put('larder')
  async updateLarder(
    @CurrentStay() stay: StayAggregate,
    @Body() dto: UpdateLarderOrderDto,
  ) {
    const result = await this.guestService.updateLarderOrder(stay, dto);
    return {
      orders: result.orders.map(toGuestLarderOrderView),
      folioSummary: toGuestFolioSummaryView(result.folioSummary),
    };
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

  @Get('concierge-requests')
  listConciergeRequests(@CurrentStay() stay: StayAggregate) {
    return stay.conciergeRequests.map(toGuestConciergeRequestView);
  }

  @Post('concierge-requests')
  createConciergeRequest(
    @CurrentStay() stay: StayAggregate,
    @Body() dto: CreateConciergeRequestDto,
  ) {
    return this.guestService
      .createConciergeRequest(stay, dto)
      .then(toGuestConciergeRequestView);
  }

  @Post('concierge-requests/upload-url')
  generateUploadUrl(
    @CurrentStay() stay: StayAggregate,
    @Body() dto: GenerateUploadUrlDto,
  ) {
    return this.guestService.generateUploadUrl(stay, dto);
  }

  @Post('concierge-requests/:requestId/messages')
  appendConciergeMessage(
    @CurrentStay() stay: StayAggregate,
    @Param('requestId') requestId: string,
    @Body() dto: CreateConciergeMessageDto,
  ) {
    return this.guestService
      .appendConciergeMessage(stay, requestId, dto)
      .then(toGuestConciergeRequestView);
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
}
