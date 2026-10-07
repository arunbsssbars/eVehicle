import {
  Controller,
  Get,
  Post,
  Patch,
  Body,
  UseGuards,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth, ApiHeader } from '@nestjs/swagger';
import { TenantsService } from './tenants.service';
import { CreateTenantDto } from './dto/create-tenant.dto';
import { UpdateTenantSettingsDto } from './dto/update-tenant-settings.dto';
import { TenantGuard } from '../common/guards/tenant.guard';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { TenantId } from '../common/decorators/tenant-id.decorator';
import { Roles } from '../common/decorators/roles.decorator';

@ApiTags('SaaS Tenants & Workspaces')
@Controller('tenants')
export class TenantsController {
  constructor(private readonly tenantsService: TenantsService) {}

  @Post('register')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Self-Service SaaS Workspace Registration' })
  @ApiResponse({ status: 201, description: 'New multi-tenant workspace provisioned.' })
  async registerTenant(@Body() dto: CreateTenantDto) {
    const tenant = await this.tenantsService.registerTenant(dto);
    return {
      success: true,
      message: 'Workspace successfully registered.',
      data: tenant,
    };
  }

  @Get('current')
  @UseGuards(JwtAuthGuard, TenantGuard)
  @ApiBearerAuth()
  @ApiHeader({ name: 'x-tenant-id', required: false, description: 'Tenant Workspace ID' })
  @ApiOperation({ summary: 'Get current workspace profile & quotas' })
  async getCurrentTenant(@TenantId() tenantId: string) {
    const tenant = await this.tenantsService.getTenantById(tenantId);
    return {
      success: true,
      data: tenant,
    };
  }

  @Patch('settings')
  @UseGuards(JwtAuthGuard, TenantGuard, RolesGuard)
  @Roles('COMPANY_ADMIN', 'SUPER_ADMIN')
  @ApiBearerAuth()
  @ApiHeader({ name: 'x-tenant-id', required: false })
  @ApiOperation({ summary: 'Update workspace white-label branding & regional settings' })
  async updateSettings(
    @TenantId() tenantId: string,
    @Body() dto: UpdateTenantSettingsDto,
  ) {
    const updated = await this.tenantsService.updateSettings(tenantId, dto);
    return {
      success: true,
      message: 'Workspace settings updated successfully.',
      data: updated,
    };
  }

  @Post('invites')
  @UseGuards(JwtAuthGuard, TenantGuard, RolesGuard)
  @Roles('COMPANY_ADMIN', 'SUPER_ADMIN')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Generate member invite for workspace' })
  async createInvite(
    @TenantId() tenantId: string,
    @Body('email') email: string,
    @Body('role') role: string,
  ) {
    return this.tenantsService.createInvite(tenantId, email, role || 'DRIVER');
  }

  @Get('all')
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles('SUPER_ADMIN')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'List all multi-tenant workspaces (Super Admin only)' })
  async listAllTenants() {
    const list = await this.tenantsService.listAllTenants();
    return {
      success: true,
      data: list,
    };
  }
}
