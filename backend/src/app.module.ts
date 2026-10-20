import { Module } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import { AdminAuthGuard } from './common/guards/admin-auth.guard';
import { GuestTokenGuard } from './common/guards/guest-token.guard';
import { RolesGuard } from './common/guards/roles.guard';
import { StepUpVerifiedGuard } from './common/guards/step-up-verified.guard';
import { SecurityTokenService } from './common/services/security-token.service';
import { FirebaseInfrastructureModule } from './infrastructure/firebase/firebase-admin.module';
import { AdminFulfillmentService } from './modules/admin/admin-fulfillment.service';
import { AdminController } from './modules/admin/admin.controller';
import { AdminService } from './modules/admin/admin.service';
import { CatalogController } from './modules/guest/catalog.controller';
import { GuestAlertFolioHelper } from './modules/guest/guest-alert-folio.helper';
import { GuestBookingService } from './modules/guest/guest-booking.service';
import { GuestConciergeService } from './modules/guest/guest-concierge.service';
import { GuestStaysController } from './modules/guest/guest-stays.controller';
import { GuestService } from './modules/guest/guest.service';

@Module({
  imports: [
    ThrottlerModule.forRoot([
      {
        ttl: 60000,
        limit: 120,
      },
    ]),
    FirebaseInfrastructureModule,
  ],
  controllers: [GuestStaysController, CatalogController, AdminController],
  providers: [
    SecurityTokenService,
    GuestAlertFolioHelper,
    GuestBookingService,
    GuestConciergeService,
    GuestService,
    AdminFulfillmentService,
    AdminService,
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
