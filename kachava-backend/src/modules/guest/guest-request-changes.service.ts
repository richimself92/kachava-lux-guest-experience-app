import { BadRequestException, Inject, Injectable } from '@nestjs/common';
import { EntityNotFoundError } from '../../domain/domain-errors';
import { ExperienceBooking, OperationalAlert, StayAggregate } from '../../domain/models/domain.models';
import { STAY_REPOSITORY_PORT, StayRepositoryPort } from '../../domain/ports/repository.ports';
import { BookingChange, GUEST_CANCELLATION_REASON } from '../../domain/stays/guest-request-rules';
import { TaskAutomation } from '../tasks/task-automation.service';
import { ChangeBookingDto } from './dto/guest.dto';
import { GuestAlertFolioHelper } from './guest-alert-folio.helper';
import { GuestBookingService } from './guest-booking.service';

function guestActor(stay: StayAggregate): string {
  return `guest:${stay.stayId}`;
}

function definedChange(dto: ChangeBookingDto): BookingChange {
  const change: BookingChange = {};
  if (dto.scheduledDate !== undefined) change.scheduledDate = dto.scheduledDate;
  if (dto.scheduledTimeSlot !== undefined) change.scheduledTimeSlot = dto.scheduledTimeSlot;
  if (dto.partySize !== undefined) change.partySize = dto.partySize;
  return change;
}

/**
 * Guest cancel / change of their own bookings while still REQUESTED (422 afterwards, 404 for a
 * booking of another stay). Each change commits a staff alert with the stay and updates the
 * booking's automatic task (cancelled, or re-dated).
 */
@Injectable()
export class GuestRequestChangesService {
  constructor(
    @Inject(STAY_REPOSITORY_PORT) private readonly stayRepo: StayRepositoryPort,
    private readonly bookings: GuestBookingService,
    private readonly alerts: GuestAlertFolioHelper,
    private readonly taskAutomation: TaskAutomation,
  ) {}

  async cancelBooking(stay: StayAggregate, bookingId: string): Promise<ExperienceBooking> {
    const cancelled = await this.stayRepo.cancelGuestBooking(stay.stayId, bookingId, (booking) =>
      this.alert(stay, booking, `${booking.title} cancelled by guest`, GUEST_CANCELLATION_REASON),
    );
    const sourceType = cancelled.usageType === 'PREFERENCE' ? 'PREFERENCE' : 'BOOKING';
    await this.taskAutomation.cancelForSource(sourceType, bookingId, GUEST_CANCELLATION_REASON, guestActor(stay));
    return cancelled;
  }

  async changeBooking(stay: StayAggregate, bookingId: string, dto: ChangeBookingDto): Promise<ExperienceBooking> {
    const change = definedChange(dto);
    if (Object.keys(change).length === 0) {
      throw new BadRequestException('Send scheduledDate, scheduledTimeSlot or partySize to change.');
    }
    const current = stay.experienceBookings.find((b) => b.bookingId === bookingId);
    if (!current) throw new EntityNotFoundError('Booking', bookingId);
    await this.bookings.assertBookingFits(
      current.serviceId,
      change.scheduledDate ?? current.scheduledDate,
      change.partySize ?? current.partySize,
    );
    const changed = await this.stayRepo.changeGuestBooking(stay.stayId, bookingId, change, (booking) =>
      this.alert(stay, booking, `${booking.title} changed by guest`, this.whenLine(booking)),
    );
    await this.taskAutomation.rescheduleBooking(changed, guestActor(stay));
    return changed;
  }

  private whenLine(booking: ExperienceBooking): string {
    return `${booking.scheduledDate} ${booking.scheduledTimeSlot} · ${booking.partySize} guests`.replace(/\s+/g, ' ');
  }

  private alert(stay: StayAggregate, booking: ExperienceBooking, title: string, summary: string): OperationalAlert {
    return {
      ...this.alerts.buildAlert(stay, {
        category: 'BOOKING',
        severity: 'NORMAL',
        title: `${stay.villaName}: ${title}`,
        summary,
        sourceDocumentPath: `stays/${stay.stayId}`,
        assignedDepartment: booking.assignedDepartment,
      }),
      event: 'GUEST_REQUEST',
      targetRef: { type: 'BOOKING', id: booking.bookingId },
    };
  }
}
