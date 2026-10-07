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
export declare const SAAS_PLANS: SaaSPlanDefinition[];
export declare class SubscriptionsService {
    private readonly tenantsService;
    constructor(tenantsService: TenantsService);
    getAvailablePlans(): SaaSPlanDefinition[];
    getTenantUsage(tenantId: string): Promise<{
        tenantId: string;
        tenantName: string;
        currentPlan: SaaSPlanDefinition;
        usage: {
            vehiclesUsed: number;
            vehiclesAllowed: number;
            vehiclesUsagePercent: number;
            journeysUsed: number;
            journeysAllowed: number;
            journeysUsagePercent: number;
            seatsUsed: number;
            seatsAllowed: number;
        };
        canAddVehicle: boolean;
        canStartJourney: boolean;
    }>;
    upgradePlan(tenantId: string, targetPlanCode: 'FREE' | 'PRO' | 'ENTERPRISE'): Promise<{
        success: boolean;
        message: string;
        tenant: import("../tenants/tenants.service").TenantRecord;
        activePlan: SaaSPlanDefinition;
    }>;
}
