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
exports.ReportsController = void 0;
const common_1 = require("@nestjs/common");
const swagger_1 = require("@nestjs/swagger");
let ReportsController = class ReportsController {
    getMonthlyReport(month, vehicleId) {
        return {
            success: true,
            data: {
                month: month || '2026-08',
                vehicleId,
                totalJourneys: 14,
                totalDistanceKm: 1450.5,
                totalFuelLiters: 95.0,
                fuelCost: 8513.9,
            },
        };
    }
    getDailyReport(date) {
        return {
            success: true,
            data: {
                date: date || new Date().toISOString().split('T')[0],
                totalTrips: 4,
                totalDistanceKm: 185.0,
            },
        };
    }
};
exports.ReportsController = ReportsController;
__decorate([
    (0, common_1.Get)('monthly'),
    (0, swagger_1.ApiOperation)({ summary: 'Get monthly logbook aggregate' }),
    __param(0, (0, common_1.Query)('month')),
    __param(1, (0, common_1.Query)('vehicleId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String]),
    __metadata("design:returntype", void 0)
], ReportsController.prototype, "getMonthlyReport", null);
__decorate([
    (0, common_1.Get)('daily'),
    (0, swagger_1.ApiOperation)({ summary: 'Get daily dispatch register' }),
    __param(0, (0, common_1.Query)('date')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], ReportsController.prototype, "getDailyReport", null);
exports.ReportsController = ReportsController = __decorate([
    (0, swagger_1.ApiTags)('Reports'),
    (0, common_1.Controller)('reports')
], ReportsController);
//# sourceMappingURL=reports.controller.js.map