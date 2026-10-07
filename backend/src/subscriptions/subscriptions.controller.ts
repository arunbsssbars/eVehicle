import {
  Controller,
  Get,
  Post,
  Body,
  UseGuards,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBearerAuth, ApiHeader } from '@nestjs/swagger';
import { SubscriptionsService } from './subscriptions.service';
import { TenantGuard } from '../common/guards/tenant.guard';
import { JwtAuthGuard } from '../common/guards/jwt-auth.guard';
import { RolesGuard } from '../common/guards/roles.guard';
import { TenantId } from '../common/decorators/tenant-id.decorator';
import { Roles } from '../common/decorators/roles.decorator';

@ApiTags('SaaS Subscriptions & Billing')
@Controller('subscriptions')
export class SubscriptionsController {
  constructor(private readonly subscriptionsService: SubscriptionsService) {}

  @Get('plans')
  @ApiOperation({ summary: 'List public SaaS subscription pricing plans & feature matrices' })
  @ApiResponse({ status: 200, description: 'List of pricing plans.' })
  getPlans() {
    return {
      success: true,
      data: this.subscriptionsService.getAvailablePlans(),
    };
  }

  @Get('usage')
  @UseGuards(JwtAuthGuard, TenantGuard)
  @ApiBearerAuth()
  @ApiHeader({ name: 'x-tenant-id', required: false, description: 'Tenant Workspace ID' })
  @ApiOperation({ summary: 'Get current workspace resource usage vs plan quotas' })
  async getUsage(@TenantId() tenantId: string) {
    const usage = await this.subscriptionsService.getTenantUsage(tenantId);
    return {
      success: true,
      data: usage,
    };
  }

  @Post('upgrade')
  @HttpCode(HttpStatus.OK)
  @UseGuards(JwtAuthGuard, TenantGuard, RolesGuard)
  @Roles('COMPANY_ADMIN', 'SUPER_ADMIN')
  @ApiBearerAuth()
  @ApiOperation({ summary: 'Upgrade or change workspace subscription tier' })
  async upgrade(
    @TenantId() tenantId: string,
    @Body('plan') planCode: 'FREE' | 'PRO' | 'ENTERPRISE',
  ) {
    return this.subscriptionsService.upgradePlan(tenantId, planCode);
  }
}
