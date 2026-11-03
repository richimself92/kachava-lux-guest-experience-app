import { Module } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import { AdminAuthGuard } from './common/guards/admin-auth.guard';
import { GuestTokenGuard } from './common/guards/guest-token.guard';
import { RolesGuard } from './common/guards/roles.guard';
import { StepUpVerifiedGuard } from './common/guards/step-up-verified.guard';
import { buildThrottlerOptions } from './common/throttling/throttle-tracker';
import { FirebaseIdTokenVerifier } from './common/services/firebase-id-token.verifier';
import { SecurityTokenService } from './common/services/security-token.service';
import { StepUpAttemptLimiter } from './common/services/step-up-attempt-limiter';
import { CLOCK_PORT } from './domain/ports/clock.port';
import { FirebaseInfrastructureModule } from './infrastructure/firebase/firebase-admin.module';
import { SystemClock } from './infrastructure/time/system-clock';
import { AdminFulfillmentService } from './modules/admin/admin-fulfillment.service';
import { AdminSyncService } from './modules/admin/admin-sync.service';
import { AdminController } from './modules/admin/admin.controller';
import { AdminService } from './modules/admin/admin.service';
import { CatalogAdminService } from './modules/catalog/catalog-admin.service';
import { CatalogUploadsService } from './modules/catalog/catalog-uploads.service';
import {
  AdminServicesController,
  AdminUploadsController,
  GuestCatalogController,
} from './modules/catalog/catalog.controllers';
import { GuestCatalogService } from './modules/catalog/guest-catalog.service';
import { GuestAlertFolioHelper } from './modules/guest/guest-alert-folio.helper';
import { GuestBookingService } from './modules/guest/guest-booking.service';
import { GuestConciergeService } from './modules/guest/guest-concierge.service';
import { GuestPhotoLinks } from './modules/guest/guest-photo-links.service';
import { GuestRequestChangesService } from './modules/guest/guest-request-changes.service';
import { GuestStaysController } from './modules/guest/guest-stays.controller';
import { GuestService } from './modules/guest/guest.service';
import { SettingsController } from './modules/settings/settings.controller';
import { SettingsService } from './modules/settings/settings.service';
import { TransportProvidersController } from './modules/transport/transport-providers.controller';
import { TransportProvidersService } from './modules/transport/transport-providers.service';
import { GuestTripsService } from './modules/trips/guest-trips.service';
import { TripFactory } from './modules/trips/trip-factory.service';
import { GuestTripsController, TripsAdminController } from './modules/trips/trips.controllers';
import { TripsAdminService } from './modules/trips/trips-admin.service';
import { VillasController } from './modules/villas/villas.controller';
import { ConversationsController } from './modules/conversations/conversations.controller';
import { ConversationsService } from './modules/conversations/conversations.service';
import { DashboardController } from './modules/dashboard/dashboard.controller';
import { DashboardService } from './modules/dashboard/dashboard.service';
import { NotificationsController } from './modules/notifications/notifications.controller';
import { NotificationsService } from './modules/notifications/notifications.service';
import { GuestsController, ReservationsController } from './modules/reservations/reservations.controllers';
import { ReservationsService } from './modules/reservations/reservations.service';
import { TaskAutomation } from './modules/tasks/task-automation.service';
import { TasksController } from './modules/tasks/tasks.controller';
import { TasksService } from './modules/tasks/tasks.service';
import { VillasService } from './modules/villas/villas.service';

@Module({
  imports: [
    ThrottlerModule.forRoot(buildThrottlerOptions()),
    FirebaseInfrastructureModule,
  ],
  controllers: [
    GuestStaysController,
    GuestCatalogController,
    AdminController,
    SettingsController,
    VillasController,
    TransportProvidersController,
    AdminServicesController,
    AdminUploadsController,
    TripsAdminController,
    GuestTripsController,
    DashboardController,
    ReservationsController,
    GuestsController,
    TasksController,
    NotificationsController,
    ConversationsController,
  ],
  providers: [
    SecurityTokenService,
    StepUpAttemptLimiter,
    FirebaseIdTokenVerifier,
    GuestAlertFolioHelper,
    GuestBookingService,
    GuestConciergeService,
    GuestPhotoLinks,
    GuestRequestChangesService,
    GuestService,
    AdminFulfillmentService,
    AdminService,
    AdminSyncService,
    SettingsService,
    VillasService,
    TransportProvidersService,
    CatalogAdminService,
    CatalogUploadsService,
    GuestCatalogService,
    TripFactory,
    TripsAdminService,
    GuestTripsService,
    DashboardService,
    ReservationsService,
    TasksService,
    TaskAutomation,
    NotificationsService,
    ConversationsService,
    { provide: CLOCK_PORT, useClass: SystemClock },
    GuestTokenGuard,
    StepUpVerifiedGuard,
    AdminAuthGuard,
    RolesGuard,
    {
      provide: APP_GUARD,
      useClass: ThrottlerGuard,
    },
  ],
})
export class AppModule {}
