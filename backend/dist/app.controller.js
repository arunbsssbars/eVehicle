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
exports.AppController = void 0;
const common_1 = require("@nestjs/common");
const swagger_1 = require("@nestjs/swagger");
let AppController = class AppController {
    getRoot() {
        return {
            success: true,
            service: 'eVehicle LogBook API',
            version: '1.0.0',
            status: 'UP',
            docs: '/api/docs',
            endpoints: {
                vehicles: '/api/v1/vehicles',
                journeys: '/api/v1/journeys',
                approvals: '/api/v1/approvals',
                reports: '/api/v1/reports',
                auth: '/api/v1/auth',
            },
            timestamp: new Date().toISOString(),
        };
    }
    getHealth() {
        return {
            status: 'healthy',
            uptime: process.uptime(),
            timestamp: new Date().toISOString(),
        };
    }
};
exports.AppController = AppController;
__decorate([
    (0, common_1.Get)(),
    (0, swagger_1.ApiOperation)({ summary: 'API Root & Health Check' }),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", void 0)
], AppController.prototype, "getRoot", null);
__decorate([
    (0, common_1.Get)('health'),
    (0, swagger_1.ApiOperation)({ summary: 'Health Check Endpoint' }),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", void 0)
], AppController.prototype, "getHealth", null);
exports.AppController = AppController = __decorate([
    (0, swagger_1.ApiTags)('Health & Index'),
    (0, common_1.Controller)()
], AppController);
//# sourceMappingURL=app.controller.js.map