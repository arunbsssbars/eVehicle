import {
  Injectable,
  NotFoundException,
  ConflictException,
} from '@nestjs/common';
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

@Injectable()
export class TenantsService {
  private tenants: Map<string, TenantRecord> = new Map();

  constructor() {
    // Seed standard initial enterprise tenant for existing users
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

  async registerTenant(dto: CreateTenantDto): Promise<TenantRecord> {
    for (const t of this.tenants.values()) {
      if (t.slug.toLowerCase() === dto.slug.toLowerCase()) {
        throw new ConflictException(
          `Tenant with workspace slug '${dto.slug}' already exists.`,
        );
      }
    }

    const tenantId = 'TENANT-' + Date.now();
    const joinCode = 'CORP-' + Math.floor(100 + Math.random() * 900);
    const plan = dto.initialPlan?.toUpperCase() || 'FREE';

    const maxVehicles = plan === 'ENTERPRISE' ? 100 : plan === 'PRO' ? 10 : 2;
    const maxMonthlyJourneys =
      plan === 'ENTERPRISE' ? 10000 : plan === 'PRO' ? 500 : 50;
    const maxSeats = plan === 'ENTERPRISE' ? 50 : plan === 'PRO' ? 5 : 1;

    const newTenant: TenantRecord = {
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

  async getTenantById(tenantId: string): Promise<TenantRecord> {
    const tenant = this.tenants.get(tenantId);
    if (!tenant) {
      // Default fallback tenant for demo
      return this.tenants.get('ORG-PWD-01')!;
    }
    return tenant;
  }

  async updateSettings(
    tenantId: string,
    dto: UpdateTenantSettingsDto,
  ): Promise<TenantRecord> {
    const tenant = await this.getTenantById(tenantId);
    tenant.settings = {
      ...tenant.settings,
      ...dto,
    };
    this.tenants.set(tenant.id, tenant);
    return tenant;
  }

  async createInvite(tenantId: string, email: string, role: string) {
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

  async listAllTenants(): Promise<TenantRecord[]> {
    return Array.from(this.tenants.values());
  }
}
