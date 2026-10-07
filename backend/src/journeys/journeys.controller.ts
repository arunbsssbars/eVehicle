import { Controller, Get, Post, Body, Param, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiHeader } from '@nestjs/swagger';
import { TenantGuard } from '../common/guards/tenant.guard';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { TenantId } from '../common/decorators/tenant-id.decorator';

@ApiTags('Journeys')
@Controller('journeys')
@UseGuards(JwtAuthGuard, TenantGuard)
@ApiBearerAuth()
@ApiHeader({ name: 'x-tenant-id', required: false, description: 'Tenant Workspace ID' })
export class JourneysController {
  private journeysByTenant: Map<string, any[]> = new Map([
    [
      'ORG-PWD-01',
      [
        {
          id: 'JRN-2026-0824-01',
          tenantId: 'ORG-PWD-01',
          vehicleRegistration: 'UP16 AB 1234',
          startLocation: 'PWD Division Office, Sector 27',
          destination: 'Expressway Construction Site Sector 150',
          openingOdometer: 52340.0,
          closingOdometer: 52415.0,
          officialDistance: 75.0,
          status: 'APPROVED',
        },
      ],
    ],
  ]);

  @Get()
  @ApiOperation({ summary: 'List all journey records scoped to tenant' })
  findAll(@TenantId() tenantId: string) {
    const journeys = this.journeysByTenant.get(tenantId) || [];
    return {
      success: true,
      tenantId,
      data: journeys,
    };
  }

  @Post('start')
  @ApiOperation({ summary: 'Start new official journey for tenant' })
  startJourney(@TenantId() tenantId: string, @Body() body: any) {
    const list = this.journeysByTenant.get(tenantId) || [];
    const newJourney = {
      id: 'JRN-' + Date.now(),
      tenantId,
      status: 'ACTIVE',
      ...body,
    };
    list.unshift(newJourney);
    this.journeysByTenant.set(tenantId, list);

    return {
      success: true,
      data: newJourney,
    };
  }

  @Post(':id/complete')
  @ApiOperation({ summary: 'Complete active journey with closing odometer' })
  completeJourney(
    @TenantId() tenantId: string,
    @Param('id') id: string,
    @Body() body: any,
  ) {
    const list = this.journeysByTenant.get(tenantId) || [];
    const journey = list.find((j) => j.id === id);

    const opening = body.openingOdometer || (journey ? journey.openingOdometer : 50000);
    const closing = body.closingOdometer || 50100;
    if (closing < opening) {
      return {
        success: false,
        error: {
          code: 'INVALID_ODOMETER',
          message: 'Closing odometer cannot be less than opening odometer.',
        },
      };
    }

    const officialDistance = closing - opening;
    if (journey) {
      journey.closingOdometer = closing;
      journey.officialDistance = officialDistance;
      journey.status = 'PENDING_APPROVAL';
    }

    return {
      success: true,
      data: {
        id,
        tenantId,
        officialDistance,
        status: 'PENDING_APPROVAL',
      },
    };
  }
}
