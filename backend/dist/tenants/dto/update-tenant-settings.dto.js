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
exports.UpdateTenantSettingsDto = void 0;
const class_validator_1 = require("class-validator");
const swagger_1 = require("@nestjs/swagger");
class UpdateTenantSettingsDto {
}
exports.UpdateTenantSettingsDto = UpdateTenantSettingsDto;
__decorate([
    (0, swagger_1.ApiPropertyOptional)({ example: 'INR', enum: ['INR', 'USD', 'EUR', 'GBP'] }),
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsIn)(['INR', 'USD', 'EUR', 'GBP']),
    __metadata("design:type", String)
], UpdateTenantSettingsDto.prototype, "currencyCode", void 0);
__decorate([
    (0, swagger_1.ApiPropertyOptional)({ example: '₹' }),
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsOptional)(),
    __metadata("design:type", String)
], UpdateTenantSettingsDto.prototype, "currencySymbol", void 0);
__decorate([
    (0, swagger_1.ApiPropertyOptional)({ example: 'km', enum: ['km', 'mi'] }),
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsOptional)(),
    (0, class_validator_1.IsIn)(['km', 'mi']),
    __metadata("design:type", String)
], UpdateTenantSettingsDto.prototype, "distanceUnit", void 0);
__decorate([
    (0, swagger_1.ApiPropertyOptional)({ example: '#004AC6' }),
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsOptional)(),
    __metadata("design:type", String)
], UpdateTenantSettingsDto.prototype, "brandPrimaryColor", void 0);
__decorate([
    (0, swagger_1.ApiPropertyOptional)({ example: 'https://cdn.example.com/logo.png' }),
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsOptional)(),
    __metadata("design:type", String)
], UpdateTenantSettingsDto.prototype, "brandLogoUrl", void 0);
__decorate([
    (0, swagger_1.ApiPropertyOptional)({ example: 'GSTIN07AABCS1429B1Z' }),
    (0, class_validator_1.IsString)(),
    (0, class_validator_1.IsOptional)(),
    __metadata("design:type", String)
], UpdateTenantSettingsDto.prototype, "taxId", void 0);
//# sourceMappingURL=update-tenant-settings.dto.js.map