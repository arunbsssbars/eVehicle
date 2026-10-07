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
exports.SubscriptionsController = void 0;
const common_1 = require("@nestjs/common");
const swagger_1 = require("@nestjs/swagger");
const subscriptions_service_1 = require("./subscriptions.service");
const tenant_guard_1 = require("../common/guards/tenant.guard");
const jwt_auth_guard_1 = require("../common/guards/jwt-auth.guard");
const roles_guard_1 = require("../common/guards/roles.guard");
const tenant_id_decorator_1 = require("../common/decorators/tenant-id.decorator");
const roles_decorator_1 = require("../common/decorators/roles.decorator");
let SubscriptionsController = class SubscriptionsController {
    constructor(subscriptionsService) {
        this.subscriptionsService = subscriptionsService;
    }
    getPlans() {
        return {
            success: true,
            data: this.subscriptionsService.getAvailablePlans(),
        };
    }
    async getUsage(tenantId) {
        const usage = await this.subscriptionsService.getTenantUsage(tenantId);
        return {
            success: true,
            data: usage,
        };
    }
    async upgrade(tenantId, planCode) {
        return this.subscriptionsService.upgradePlan(tenantId, planCode);
    }
};
exports.SubscriptionsController = SubscriptionsController;
__decorate([
    (0, common_1.Get)('plans'),
    (0, swagger_1.ApiOperation)({ summary: 'List public SaaS subscription pricing plans & feature matrices' }),
    (0, swagger_1.ApiResponse)({ status: 200, description: 'List of pricing plans.' }),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", void 0)
], SubscriptionsController.prototype, "getPlans", null);
__decorate([
    (0, common_1.Get)('usage'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard, tenant_guard_1.TenantGuard),
    (0, swagger_1.ApiBearerAuth)(),
    (0, swagger_1.ApiHeader)({ name: 'x-tenant-id', required: false, description: 'Tenant Workspace ID' }),
    (0, swagger_1.ApiOperation)({ summary: 'Get current workspace resource usage vs plan quotas' }),
    __param(0, (0, tenant_id_decorator_1.TenantId)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", Promise)
], SubscriptionsController.prototype, "getUsage", null);
__decorate([
    (0, common_1.Post)('upgrade'),
    (0, common_1.HttpCode)(common_1.HttpStatus.OK),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard, tenant_guard_1.TenantGuard, roles_guard_1.RolesGuard),
    (0, roles_decorator_1.Roles)('COMPANY_ADMIN', 'SUPER_ADMIN'),
    (0, swagger_1.ApiBearerAuth)(),
    (0, swagger_1.ApiOperation)({ summary: 'Upgrade or change workspace subscription tier' }),
    __param(0, (0, tenant_id_decorator_1.TenantId)()),
    __param(1, (0, common_1.Body)('plan')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String]),
    __metadata("design:returntype", Promise)
], SubscriptionsController.prototype, "upgrade", null);
exports.SubscriptionsController = SubscriptionsController = __decorate([
    (0, swagger_1.ApiTags)('SaaS Subscriptions & Billing'),
    (0, common_1.Controller)('subscriptions'),
    __metadata("design:paramtypes", [subscriptions_service_1.SubscriptionsService])
], SubscriptionsController);
//# sourceMappingURL=subscriptions.controller.js.map