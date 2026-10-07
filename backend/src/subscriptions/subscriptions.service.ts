import { Injectable, BadRequestException } from '@nestjs/common';
import { TenantsService } from '../tenants/tenants.service';

export interface SaaSPlanDefinition {
  id: string;
  code: 'FREE' | 'PRO' | 'ENTERPRISE';
  name: string;
  monthlyPriceUsd: number;
  monthlyPriceInr: number;
  maxVehicles: number;
  maxMonthlyJourneys: number;
  maxSeats: number;
  features: string[];
}

export const SAAS_PLANS: SaaSPlanDefinition[] = [
  {
    id: 'plan_free',
    code: 'FREE',
    name: 'Free Starter',
    monthlyPriceUsd: 0,
    monthlyPriceInr: 0,
    maxVehicles: 2,
    maxMonthlyJourneys: 50,
    maxSeats: 1,
    features: [
      'Basic Vehicle & Journey Logging',
      'Standard CSV Export',
      'Community Support',
    ],
  },
  {
    id: 'plan_pro',
    code: 'PRO',
    name: 'Pro Fleet',
    monthlyPriceUsd: 2.99,
    monthlyPriceInr: 249,
    maxVehicles: 10,
    maxMonthlyJourneys: 500,
    maxSeats: 5,
    features: [
      'Up to 10 Fleet Vehicles',
      '500 Monthly Verified Journeys',
      'Advanced PDF & Excel Audit Export',
      'Automated Fraud & Tamper Detection',
      'Priority Email & In-App Support',
    ],
  },
  {
    id: 'plan_enterprise',
    code: 'ENTERPRISE',
    name: 'Enterprise Commercial',
    monthlyPriceUsd: 29.99,
    monthlyPriceInr: 2499,
    maxVehicles: 100,
    maxMonthlyJourneys: 10000,
    maxSeats: 50,
    features: [
      'Unlimited Fleet Scale (100+ Vehicles)',
      '10,000+ Monthly High-Throughput Trips',
      'Full 140-Sentinel Real-Time Telematics & Diagnostics',
      'Custom Multi-Level Approval Hierarchies',
      'Tenant White-Labeling & Custom Subdomains',
      'REST API Keys & Webhook Integrations',
      '24/7 Dedicated SLA & Cloud Backups',
    ],
  },
];

@Injectable()
export class SubscriptionsService {
  constructor(private readonly tenantsService: TenantsService) {}

  getAvailablePlans(): SaaSPlanDefinition[] {
    return SAAS_PLANS;
  }

  async getTenantUsage(tenantId: string) {
    const tenant = await this.tenantsService.getTenantById(tenantId);
    const plan =
      SAAS_PLANS.find((p) => p.code === tenant.plan) || SAAS_PLANS[0];

    // Mock live usage stats scoped to tenant
    const activeVehicles = 1;
    const monthlyJourneys = 4;
    const activeSeats = 1;

    return {
      tenantId: tenant.id,
      tenantName: tenant.name,
      currentPlan: plan,
      usage: {
        vehiclesUsed: activeVehicles,
        vehiclesAllowed: plan.maxVehicles,
        vehiclesUsagePercent: Math.min(100, Math.round((activeVehicles / plan.maxVehicles) * 100)),
        journeysUsed: monthlyJourneys,
        journeysAllowed: plan.maxMonthlyJourneys,
        journeysUsagePercent: Math.min(100, Math.round((monthlyJourneys / plan.maxMonthlyJourneys) * 100)),
        seatsUsed: activeSeats,
        seatsAllowed: plan.maxSeats,
      },
      canAddVehicle: activeVehicles < plan.maxVehicles,
      canStartJourney: monthlyJourneys < plan.maxMonthlyJourneys,
    };
  }

  async upgradePlan(tenantId: string, targetPlanCode: 'FREE' | 'PRO' | 'ENTERPRISE') {
    const plan = SAAS_PLANS.find((p) => p.code === targetPlanCode);
    if (!plan) {
      throw new BadRequestException(`Invalid subscription plan code: ${targetPlanCode}`);
    }

    const tenant = await this.tenantsService.getTenantById(tenantId);
    tenant.plan = plan.code;
    tenant.quotas = {
      maxVehicles: plan.maxVehicles,
      maxMonthlyJourneys: plan.maxMonthlyJourneys,
      maxSeats: plan.maxSeats,
    };

    return {
      success: true,
      message: `Tenant ${tenant.name} upgraded to ${plan.name}`,
      tenant,
      activePlan: plan,
    };
  }
}
