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
exports.TenantsService = void 0;
const common_1 = require("@nestjs/common");
let TenantsService = class TenantsService {
    constructor() {
        this.tenants = new Map();
        this.tenants.set('ORG-PWD-01', {
            id: 'ORG-PWD-01',
            name: 'Public Works Department (Noida Division)',
            slug: 'pwd-noida',
            code: 'PWD-842',
            adminId: 'USR-001',
            adminName: 'Dr. S. K. Verma',
            adminEmail: 'sk.verma@gov.in',
            contactMobile: '+91 98765 43210',
            plan: 'ENTERPRISE',
            status: 'ACTIVE',
            settings: {
                currencyCode: 'INR',
                currencySymbol: '₹',
                distanceUnit: 'km',
                brandPrimaryColor: '#004AC6',
                brandLogoUrl: 'https://cdn.example.com/pwd-logo.png',
                taxId: 'UP-GOV-PWD-01',
            },
            quotas: {
                maxVehicles: 100,
                maxMonthlyJourneys: 10000,
                maxSeats: 50,
            },
            createdAt: '2026-01-01T00:00:00.000Z',
        });
    }
    async registerTenant(dto) {
        for (const t of this.tenants.values()) {
            if (t.slug.toLowerCase() === dto.slug.toLowerCase()) {
                throw new common_1.ConflictException(`Tenant with workspace slug '${dto.slug}' already exists.`);
            }
        }
        const tenantId = 'TENANT-' + Date.now();
        const joinCode = 'CORP-' + Math.floor(100 + Math.random() * 900);
        const plan = dto.initialPlan?.toUpperCase() || 'FREE';
        const maxVehicles = plan === 'ENTERPRISE' ? 100 : plan === 'PRO' ? 10 : 2;
        const maxMonthlyJourneys = plan === 'ENTERPRISE' ? 10000 : plan === 'PRO' ? 500 : 50;
        const maxSeats = plan === 'ENTERPRISE' ? 50 : plan === 'PRO' ? 5 : 1;
        const newTenant = {
            id: tenantId,
            name: dto.name,
            slug: dto.slug.toLowerCase(),
            code: joinCode,
            adminId: 'USR-' + Date.now(),
            adminName: dto.adminName,
            adminEmail: dto.adminEmail,
            contactMobile: dto.contactMobile || '',
            plan,
            status: 'ACTIVE',
            settings: {
                currencyCode: 'INR',
                currencySymbol: '₹',
                distanceUnit: 'km',
                brandPrimaryColor: '#004AC6',
            },
            quotas: {
                maxVehicles,
                maxMonthlyJourneys,
                maxSeats,
            },
            createdAt: new Date().toISOString(),
        };
        this.tenants.set(tenantId, newTenant);
        return newTenant;
    }
    async getTenantById(tenantId) {
        const tenant = this.tenants.get(tenantId);
        if (!tenant) {
            return this.tenants.get('ORG-PWD-01');
        }
        return tenant;
    }
    async updateSettings(tenantId, dto) {
        const tenant = await this.getTenantById(tenantId);
        tenant.settings = {
            ...tenant.settings,
            ...dto,
        };
        this.tenants.set(tenant.id, tenant);
        return tenant;
    }
    async createInvite(tenantId, email, role) {
        const tenant = await this.getTenantById(tenantId);
        const inviteToken = 'INV-' + Math.random().toString(36).substring(2, 9).toUpperCase();
        return {
            success: true,
            data: {
                inviteToken,
                tenantId: tenant.id,
                tenantName: tenant.name,
                email,
                role,
                joinCode: tenant.code,
                expiresAt: new Date(Date.now() + 7 * 86400 * 1000).toISOString(),
            },
        };
    }
    async listAllTenants() {
        return Array.from(this.tenants.values());
    }
};
exports.TenantsService = TenantsService;
exports.TenantsService = TenantsService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [])
], TenantsService);
//# sourceMappingURL=tenants.service.js.map