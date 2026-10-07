import { TenantsService } from './tenants.service';
import { CreateTenantDto } from './dto/create-tenant.dto';
import { UpdateTenantSettingsDto } from './dto/update-tenant-settings.dto';
export declare class TenantsController {
    private readonly tenantsService;
    constructor(tenantsService: TenantsService);
    registerTenant(dto: CreateTenantDto): Promise<{
        success: boolean;
        message: string;
        data: import("./tenants.service").TenantRecord;
    }>;
    getCurrentTenant(tenantId: string): Promise<{
        success: boolean;
        data: import("./tenants.service").TenantRecord;
    }>;
    updateSettings(tenantId: string, dto: UpdateTenantSettingsDto): Promise<{
        success: boolean;
        message: string;
        data: import("./tenants.service").TenantRecord;
    }>;
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
    listAllTenants(): Promise<{
        success: boolean;
        data: import("./tenants.service").TenantRecord[];
    }>;
}
