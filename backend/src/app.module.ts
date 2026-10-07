import { Module } from '@nestjs/common';
import { AuthModule } from './auth/auth.module';
import { TenantsModule } from './tenants/tenants.module';
import { SubscriptionsModule } from './subscriptions/subscriptions.module';
import { VehiclesModule } from './vehicles/vehicles.module';
import { JourneysModule } from './journeys/journeys.module';
import { ApprovalsModule } from './approvals/approvals.module';
import { ReportsModule } from './reports/reports.module';
import { AppController } from './app.controller';

@Module({
  imports: [
    AuthModule,
    TenantsModule,
    SubscriptionsModule,
    VehiclesModule,
    JourneysModule,
    ApprovalsModule,
    ReportsModule,
  ],
  controllers: [AppController],
})
export class AppModule {}
