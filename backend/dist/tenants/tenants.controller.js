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
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.TenantsController = void 0;
const common_1 = require("@nestjs/common");
const swagger_1 = require("@nestjs/swagger");
const tenants_service_1 = require("./tenants.service");
const create_tenant_dto_1 = require("./dto/create-tenant.dto");
const update_tenant_settings_dto_1 = require("./dto/update-tenant-settings.dto");
const tenant_guard_1 = require("../common/guards/tenant.guard");
const jwt_auth_guard_1 = require("../common/guards/jwt-auth.guard");
const roles_guard_1 = require("../common/guards/roles.guard");
const tenant_id_decorator_1 = require("../common/decorators/tenant-id.decorator");
const roles_decorator_1 = require("../common/decorators/roles.decorator");
let TenantsController = class TenantsController {
    constructor(tenantsService) {
        this.tenantsService = tenantsService;
    }
    async registerTenant(dto) {
        const tenant = await this.tenantsService.registerTenant(dto);
        return {
            success: true,
            message: 'Workspace successfully registered.',
            data: tenant,
        };
    }
    async getCurrentTenant(tenantId) {
        const tenant = await this.tenantsService.getTenantById(tenantId);
        return {
            success: true,
            data: tenant,
        };
    }
    async updateSettings(tenantId, dto) {
        const updated = await this.tenantsService.updateSettings(tenantId, dto);
        return {
            success: true,
            message: 'Workspace settings updated successfully.',
            data: updated,
        };
    }
    async createInvite(tenantId, email, role) {
        return this.tenantsService.createInvite(tenantId, email, role || 'DRIVER');
    }
    async listAllTenants() {
        const list = await this.tenantsService.listAllTenants();
        return {
            success: true,
            data: list,
        };
    }
};
exports.TenantsController = TenantsController;
__decorate([
    (0, common_1.Post)('register'),
    (0, common_1.HttpCode)(common_1.HttpStatus.CREATED),
    (0, swagger_1.ApiOperation)({ summary: 'Self-Service SaaS Workspace Registration' }),
    (0, swagger_1.ApiResponse)({ status: 201, description: 'New multi-tenant workspace provisioned.' }),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [create_tenant_dto_1.CreateTenantDto]),
    __metadata("design:returntype", Promise)
], TenantsController.prototype, "registerTenant", null);
__decorate([
    (0, common_1.Get)('current'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard, tenant_guard_1.TenantGuard),
    (0, swagger_1.ApiBearerAuth)(),
    (0, swagger_1.ApiHeader)({ name: 'x-tenant-id', required: false, description: 'Tenant Workspace ID' }),
    (0, swagger_1.ApiOperation)({ summary: 'Get current workspace profile & quotas' }),
    __param(0, (0, tenant_id_decorator_1.TenantId)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], TenantsController.prototype, "getCurrentTenant", null);
__decorate([
    (0, common_1.Patch)('settings'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard, tenant_guard_1.TenantGuard, roles_guard_1.RolesGuard),
    (0, roles_decorator_1.Roles)('COMPANY_ADMIN', 'SUPER_ADMIN'),
    (0, swagger_1.ApiBearerAuth)(),
    (0, swagger_1.ApiHeader)({ name: 'x-tenant-id', required: false }),
    (0, swagger_1.ApiOperation)({ summary: 'Update workspace white-label branding & regional settings' }),
    __param(0, (0, tenant_id_decorator_1.TenantId)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, update_tenant_settings_dto_1.UpdateTenantSettingsDto]),
    __metadata("design:returntype", Promise)
], TenantsController.prototype, "updateSettings", null);
__decorate([
    (0, common_1.Post)('invites'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard, tenant_guard_1.TenantGuard, roles_guard_1.RolesGuard),
    (0, roles_decorator_1.Roles)('COMPANY_ADMIN', 'SUPER_ADMIN'),
    (0, swagger_1.ApiBearerAuth)(),
    (0, swagger_1.ApiOperation)({ summary: 'Generate member invite for workspace' }),
    __param(0, (0, tenant_id_decorator_1.TenantId)()),
    __param(1, (0, common_1.Body)('email')),
    __param(2, (0, common_1.Body)('role')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, String]),
    __metadata("design:returntype", Promise)
], TenantsController.prototype, "createInvite", null);
__decorate([
    (0, common_1.Get)('all'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard, roles_guard_1.RolesGuard),
    (0, roles_decorator_1.Roles)('SUPER_ADMIN'),
    (0, swagger_1.ApiBearerAuth)(),
    (0, swagger_1.ApiOperation)({ summary: 'List all multi-tenant workspaces (Super Admin only)' }),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", Promise)
], TenantsController.prototype, "listAllTenants", null);
exports.TenantsController = TenantsController = __decorate([
    (0, swagger_1.ApiTags)('SaaS Tenants & Workspaces'),
    (0, common_1.Controller)('tenants'),
    __metadata("design:paramtypes", [tenants_service_1.TenantsService])
], TenantsController);
//# sourceMappingURL=tenants.controller.js.map