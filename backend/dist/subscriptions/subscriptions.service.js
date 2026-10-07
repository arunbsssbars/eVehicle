"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.SubscriptionsService = exports.SAAS_PLANS = void 0;
const common_1 = require("@nestjs/common");
const tenants_service_1 = require("../tenants/tenants.service");
exports.SAAS_PLANS = [
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
let SubscriptionsService = class SubscriptionsService {
    constructor(tenantsService) {
        this.tenantsService = tenantsService;
    }
    getAvailablePlans() {
        return exports.SAAS_PLANS;
    }
    async getTenantUsage(tenantId) {
        const tenant = await this.tenantsService.getTenantById(tenantId);
        const plan = exports.SAAS_PLANS.find((p) => p.code === tenant.plan) || exports.SAAS_PLANS[0];
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
    async upgradePlan(tenantId, targetPlanCode) {
        const plan = exports.SAAS_PLANS.find((p) => p.code === targetPlanCode);
        if (!plan) {
            throw new common_1.BadRequestException(`Invalid subscription plan code: ${targetPlanCode}`);
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
};
exports.SubscriptionsService = SubscriptionsService;
exports.SubscriptionsService = SubscriptionsService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [tenants_service_1.TenantsService])
], SubscriptionsService);
//# sourceMappingURL=subscriptions.service.js.map