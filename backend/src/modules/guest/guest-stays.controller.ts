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

@Controller('stays/:guestUuid')
@UseGuards(GuestTokenGuard)
export class GuestStaysController {
  constructor(private readonly guestService: GuestService) {}

  @Get()
  getStayAggregate(@CurrentStay() stay: StayAggregate): StayAggregate {
    return stay;
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
    return this.guestService.updateTransfer(stay, dto);
  }

  @Patch('transport')
  updateTransportAlias(
    @CurrentStay() stay: StayAggregate,
    @Body() dto: UpdateTransferDto,
  ) {
    return this.guestService.updateTransfer(stay, dto);
  }

  @Patch('personalization')
  updatePersonalization(
    @CurrentStay() stay: StayAggregate,
    @Body() dto: UpdatePersonalizationDto,
  ) {
    return this.guestService.updatePersonalization(stay, dto);
  }

  @Put('larder')
  updateLarder(
    @CurrentStay() stay: StayAggregate,
    @Body() dto: UpdateLarderOrderDto,
  ) {
    return this.guestService.updateLarderOrder(stay, dto);
  }

  @Get('bookings')
  listBookings(@CurrentStay() stay: StayAggregate) {
    return stay.experienceBookings;
  }

  @Post('bookings')
  createBooking(
    @CurrentStay() stay: StayAggregate,
    @Body() dto: CreateBookingDto,
  ) {
    return this.guestService.createBooking(stay, dto);
  }

  @Get('concierge-requests')
  listConciergeRequests(@CurrentStay() stay: StayAggregate) {
    return stay.conciergeRequests;
  }

  @Post('concierge-requests')
  createConciergeRequest(
    @CurrentStay() stay: StayAggregate,
    @Body() dto: CreateConciergeRequestDto,
  ) {
    return this.guestService.createConciergeRequest(stay, dto);
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
    return this.guestService.appendConciergeMessage(stay, requestId, dto);
  }

  @Post('midstay-checkin')
  submitMidStayCheckIn(
    @CurrentStay() stay: StayAggregate,
    @Body() dto: CreateMidStayCheckInDto,
  ) {
    return this.guestService.submitMidStayCheckIn(stay, dto);
  }

  @Get('folio')
  getFolio(@CurrentStay() stay: StayAggregate) {
    return {
      folioSummary: stay.folioSummary,
      folioItems: stay.folioItems,
    };
  }

  @Post('folio/checkout')
  @UseGuards(StepUpVerifiedGuard)
  expressCheckout(
    @CurrentStay() stay: StayAggregate,
    @Body() dto: ExpressCheckoutDto,
  ) {
    return this.guestService.processExpressCheckout(stay, dto);
  }
}
