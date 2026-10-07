import { SubscriptionsService } from './subscriptions.service';
export declare class SubscriptionsController {
    private readonly subscriptionsService;
    constructor(subscriptionsService: SubscriptionsService);
    getPlans(): {
        success: boolean;
        data: import("./subscriptions.service").SaaSPlanDefinition[];
    };
    getUsage(tenantId: string): Promise<{
        success: boolean;
        data: {
            tenantId: string;
            tenantName: string;
            currentPlan: import("./subscriptions.service").SaaSPlanDefinition;
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
        };
    }>;
    upgrade(tenantId: string, planCode: 'FREE' | 'PRO' | 'ENTERPRISE'): Promise<{
        success: boolean;
        message: string;
        tenant: import("../tenants/tenants.service").TenantRecord;
        activePlan: import("./subscriptions.service").SaaSPlanDefinition;
    }>;
}
