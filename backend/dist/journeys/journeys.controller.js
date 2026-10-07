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
exports.JourneysController = void 0;
const common_1 = require("@nestjs/common");
const swagger_1 = require("@nestjs/swagger");
const tenant_guard_1 = require("../common/guards/tenant.guard");
const jwt_auth_guard_1 = require("../common/guards/jwt-auth.guard");
const tenant_id_decorator_1 = require("../common/decorators/tenant-id.decorator");
let JourneysController = class JourneysController {
    constructor() {
        this.journeysByTenant = new Map([
            [
                'ORG-PWD-01',
                [
                    {
                        id: 'JRN-2026-0824-01',
                        tenantId: 'ORG-PWD-01',
                        vehicleRegistration: 'UP16 AB 1234',
                        startLocation: 'PWD Division Office, Sector 27',
                        destination: 'Expressway Construction Site Sector 150',
                        openingOdometer: 52340.0,
                        closingOdometer: 52415.0,
                        officialDistance: 75.0,
                        status: 'APPROVED',
                    },
                ],
            ],
        ]);
    }
    findAll(tenantId) {
        const journeys = this.journeysByTenant.get(tenantId) || [];
        return {
            success: true,
            tenantId,
            data: journeys,
        };
    }
    startJourney(tenantId, body) {
        const list = this.journeysByTenant.get(tenantId) || [];
        const newJourney = {
            id: 'JRN-' + Date.now(),
            tenantId,
            status: 'ACTIVE',
            ...body,
        };
        list.unshift(newJourney);
        this.journeysByTenant.set(tenantId, list);
        return {
            success: true,
            data: newJourney,
        };
    }
    completeJourney(tenantId, id, body) {
        const list = this.journeysByTenant.get(tenantId) || [];
        const journey = list.find((j) => j.id === id);
        const opening = body.openingOdometer || (journey ? journey.openingOdometer : 50000);
        const closing = body.closingOdometer || 50100;
        if (closing < opening) {
            return {
                success: false,
                error: {
                    code: 'INVALID_ODOMETER',
                    message: 'Closing odometer cannot be less than opening odometer.',
                },
            };
        }
        const officialDistance = closing - opening;
        if (journey) {
            journey.closingOdometer = closing;
            journey.officialDistance = officialDistance;
            journey.status = 'PENDING_APPROVAL';
        }
        return {
            success: true,
            data: {
                id,
                tenantId,
                officialDistance,
                status: 'PENDING_APPROVAL',
            },
        };
    }
};
exports.JourneysController = JourneysController;
__decorate([
    (0, common_1.Get)(),
    (0, swagger_1.ApiOperation)({ summary: 'List all journey records scoped to tenant' }),
    __param(0, (0, tenant_id_decorator_1.TenantId)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], JourneysController.prototype, "findAll", null);
__decorate([
    (0, common_1.Post)('start'),
    (0, swagger_1.ApiOperation)({ summary: 'Start new official journey for tenant' }),
    __param(0, (0, tenant_id_decorator_1.TenantId)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", void 0)
], JourneysController.prototype, "startJourney", null);
__decorate([
    (0, common_1.Post)(':id/complete'),
    (0, swagger_1.ApiOperation)({ summary: 'Complete active journey with closing odometer' }),
    __param(0, (0, tenant_id_decorator_1.TenantId)()),
    __param(1, (0, common_1.Param)('id')),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, Object]),
    __metadata("design:returntype", void 0)
], JourneysController.prototype, "completeJourney", null);
exports.JourneysController = JourneysController = __decorate([
    (0, swagger_1.ApiTags)('Journeys'),
    (0, common_1.Controller)('journeys'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard, tenant_guard_1.TenantGuard),
    (0, swagger_1.ApiBearerAuth)(),
    (0, swagger_1.ApiHeader)({ name: 'x-tenant-id', required: false, description: 'Tenant Workspace ID' })
], JourneysController);
//# sourceMappingURL=journeys.controller.js.map