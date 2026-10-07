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
exports.VehiclesController = void 0;
const common_1 = require("@nestjs/common");
const swagger_1 = require("@nestjs/swagger");
const tenant_guard_1 = require("../common/guards/tenant.guard");
const jwt_auth_guard_1 = require("../common/guards/jwt-auth.guard");
const tenant_id_decorator_1 = require("../common/decorators/tenant-id.decorator");
let VehiclesController = class VehiclesController {
    constructor() {
        this.vehiclesByTenant = new Map([
            [
                'ORG-PWD-01',
                [
                    {
                        id: 'VEH-001',
                        tenantId: 'ORG-PWD-01',
                        registrationNumber: 'UP16 AB 1234',
                        make: 'Toyota',
                        model: 'Innova Crysta',
                        currentOdometer: 52485.0,
                        status: 'ACTIVE',
                        assignedDriverName: 'Rajesh Kumar',
                    },
                    {
                        id: 'VEH-002',
                        tenantId: 'ORG-PWD-01',
                        registrationNumber: 'DL01 CA 9988',
                        make: 'Tata',
                        model: 'Nexon EV Max',
                        currentOdometer: 18420.0,
                        status: 'ACTIVE',
                        assignedDriverName: 'Suresh Chauhan',
                    },
                ],
            ],
        ]);
    }
    findAll(tenantId) {
        const list = this.vehiclesByTenant.get(tenantId) || [];
        return {
            success: true,
            tenantId,
            data: list,
        };
    }
    create(tenantId, body) {
        const currentList = this.vehiclesByTenant.get(tenantId) || [];
        const newVehicle = {
            id: 'VEH-' + Date.now(),
            tenantId,
            status: 'ACTIVE',
            ...body,
        };
        currentList.push(newVehicle);
        this.vehiclesByTenant.set(tenantId, currentList);
        return {
            success: true,
            data: newVehicle,
        };
    }
    findOne(tenantId, id) {
        const list = this.vehiclesByTenant.get(tenantId) || [];
        const vehicle = list.find((v) => v.id === id);
        return {
            success: !!vehicle,
            data: vehicle || {
                id,
                tenantId,
                registrationNumber: 'UP16 AB 1234',
                make: 'Toyota',
                model: 'Innova Crysta',
                currentOdometer: 52485.0,
                status: 'ACTIVE',
            },
        };
    }
};
exports.VehiclesController = VehiclesController;
__decorate([
    (0, common_1.Get)(),
    (0, swagger_1.ApiOperation)({ summary: 'Get all vehicles scoped to caller tenant' }),
    __param(0, (0, tenant_id_decorator_1.TenantId)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], VehiclesController.prototype, "findAll", null);
__decorate([
    (0, common_1.Post)(),
    (0, swagger_1.ApiOperation)({ summary: 'Add a new vehicle to workspace' }),
    __param(0, (0, tenant_id_decorator_1.TenantId)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, Object]),
    __metadata("design:returntype", void 0)
], VehiclesController.prototype, "create", null);
__decorate([
    (0, common_1.Get)(':id'),
    (0, swagger_1.ApiOperation)({ summary: 'Get vehicle details by ID within tenant' }),
    __param(0, (0, tenant_id_decorator_1.TenantId)()),
    __param(1, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String]),
    __metadata("design:returntype", void 0)
], VehiclesController.prototype, "findOne", null);
exports.VehiclesController = VehiclesController = __decorate([
    (0, swagger_1.ApiTags)('Vehicles'),
    (0, common_1.Controller)('vehicles'),
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard, tenant_guard_1.TenantGuard),
    (0, swagger_1.ApiBearerAuth)(),
    (0, swagger_1.ApiHeader)({ name: 'x-tenant-id', required: false, description: 'Tenant Workspace ID' })
], VehiclesController);
//# sourceMappingURL=vehicles.controller.js.map