import { Controller, Get, Post, Body, Param, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiBearerAuth, ApiHeader } from '@nestjs/swagger';
import { TenantGuard } from '../common/guards/tenant.guard';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { TenantId } from '../common/decorators/tenant-id.decorator';

@ApiTags('Vehicles')
@Controller('vehicles')
@UseGuards(JwtAuthGuard, TenantGuard)
@ApiBearerAuth()
@ApiHeader({ name: 'x-tenant-id', required: false, description: 'Tenant Workspace ID' })
export class VehiclesController {
  // In-memory tenant-isolated vehicle store
  private vehiclesByTenant: Map<string, any[]> = new Map([
    [
      'ORG-PWD-01',
      [
        {
          id: 'VEH-001',
          tenantId: 'ORG-PWD-01',
          registrationNumber: 'UP16 AB 1234',
          make: 'Toyota',
          model: 'Innova Crysta',
          currentOdometer: 52485.0,
          status: 'ACTIVE',
          assignedDriverName: 'Rajesh Kumar',
        },
        {
          id: 'VEH-002',
          tenantId: 'ORG-PWD-01',
          registrationNumber: 'DL01 CA 9988',
          make: 'Tata',
          model: 'Nexon EV Max',
          currentOdometer: 18420.0,
          status: 'ACTIVE',
          assignedDriverName: 'Suresh Chauhan',
        },
      ],
    ],
  ]);

  @Get()
  @ApiOperation({ summary: 'Get all vehicles scoped to caller tenant' })
  findAll(@TenantId() tenantId: string) {
    const list = this.vehiclesByTenant.get(tenantId) || [];
    return {
      success: true,
      tenantId,
      data: list,
    };
  }

  @Post()
  @ApiOperation({ summary: 'Add a new vehicle to workspace' })
  create(@TenantId() tenantId: string, @Body() body: any) {
    const currentList = this.vehiclesByTenant.get(tenantId) || [];
    const newVehicle = {
      id: 'VEH-' + Date.now(),
      tenantId,
      status: 'ACTIVE',
      ...body,
    };
    currentList.push(newVehicle);
    this.vehiclesByTenant.set(tenantId, currentList);

    return {
      success: true,
      data: newVehicle,
    };
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get vehicle details by ID within tenant' })
  findOne(@TenantId() tenantId: string, @Param('id') id: string) {
    const list = this.vehiclesByTenant.get(tenantId) || [];
    const vehicle = list.find((v) => v.id === id);
    return {
      success: !!vehicle,
      data:
        vehicle || {
          id,
          tenantId,
          registrationNumber: 'UP16 AB 1234',
          make: 'Toyota',
          model: 'Innova Crysta',
          currentOdometer: 52485.0,
          status: 'ACTIVE',
        },
    };
  }
}
