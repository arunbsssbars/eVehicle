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
exports.ApprovalsController = void 0;
const common_1 = require("@nestjs/common");
const swagger_1 = require("@nestjs/swagger");
let ApprovalsController = class ApprovalsController {
    findPending() {
        return {
            success: true,
            data: [],
        };
    }
    approve(id) {
        return {
            success: true,
            data: {
                id,
                status: 'APPROVED',
                approvedAt: new Date().toISOString(),
            },
        };
    }
    reject(id, reason) {
        return {
            success: true,
            data: {
                id,
                status: 'REJECTED',
                reason,
                rejectedAt: new Date().toISOString(),
            },
        };
    }
    lock(id) {
        return {
            success: true,
            data: {
                id,
                status: 'LOCKED',
                lockedAt: new Date().toISOString(),
            },
        };
    }
};
exports.ApprovalsController = ApprovalsController;
__decorate([
    (0, common_1.Get)('pending'),
    (0, swagger_1.ApiOperation)({ summary: 'Get all pending approval requests' }),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", []),
    __metadata("design:returntype", void 0)
], ApprovalsController.prototype, "findPending", null);
__decorate([
    (0, common_1.Post)(':id/approve'),
    (0, swagger_1.ApiOperation)({ summary: 'Approve an official journey' }),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], ApprovalsController.prototype, "approve", null);
__decorate([
    (0, common_1.Post)(':id/reject'),
    (0, swagger_1.ApiOperation)({ summary: 'Reject an official journey with remarks' }),
    __param(0, (0, common_1.Param)('id')),
    __param(1, (0, common_1.Body)('reason')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String]),
    __metadata("design:returntype", void 0)
], ApprovalsController.prototype, "reject", null);
__decorate([
    (0, common_1.Post)(':id/lock'),
    (0, swagger_1.ApiOperation)({ summary: 'Lock and archive approved record' }),
    __param(0, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], ApprovalsController.prototype, "lock", null);
exports.ApprovalsController = ApprovalsController = __decorate([
    (0, swagger_1.ApiTags)('Approvals'),
    (0, common_1.Controller)('approvals')
], ApprovalsController);
//# sourceMappingURL=approvals.controller.js.map