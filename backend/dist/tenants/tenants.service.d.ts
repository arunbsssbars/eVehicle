import { CreateTenantDto } from './dto/create-tenant.dto';
import { UpdateTenantSettingsDto } from './dto/update-tenant-settings.dto';
export interface TenantRecord {
    id: string;
    name: string;
    slug: string;
    code: string;
    adminId: string;
    adminName: string;
    adminEmail: string;
    contactMobile: string;
    plan: string;
    status: 'ACTIVE' | 'TRIALING' | 'SUSPENDED';
    settings: {
        currencyCode: string;
        currencySymbol: string;
        distanceUnit: string;
        brandPrimaryColor: string;
        brandLogoUrl?: string;
        taxId?: string;
    };
    quotas: {
        maxVehicles: number;
        maxMonthlyJourneys: number;
        maxSeats: number;
    };
    createdAt: string;
}
export declare class TenantsService {
    private tenants;
    constructor();
    registerTenant(dto: CreateTenantDto): Promise<TenantRecord>;
    getTenantById(tenantId: string): Promise<TenantRecord>;
    updateSettings(tenantId: string, dto: UpdateTenantSettingsDto): Promise<TenantRecord>;
    createInvite(tenantId: string, email: string, role: string): Promise<{
        success: boolean;
        data: {
            inviteToken: string;
            tenantId: string;
            tenantName: string;
            email: string;
            role: string;
            joinCode: string;
            expiresAt: string;
        };
    }>;
    listAllTenants(): Promise<TenantRecord[]>;
}
