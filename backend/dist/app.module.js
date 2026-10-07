"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AppModule = void 0;
const common_1 = require("@nestjs/common");
const auth_module_1 = require("./auth/auth.module");
const tenants_module_1 = require("./tenants/tenants.module");
const subscriptions_module_1 = require("./subscriptions/subscriptions.module");
const vehicles_module_1 = require("./vehicles/vehicles.module");
const journeys_module_1 = require("./journeys/journeys.module");
const approvals_module_1 = require("./approvals/approvals.module");
const reports_module_1 = require("./reports/reports.module");
const app_controller_1 = require("./app.controller");
let AppModule = class AppModule {
};
exports.AppModule = AppModule;
exports.AppModule = AppModule = __decorate([
    (0, common_1.Module)({
        imports: [
            auth_module_1.AuthModule,
            tenants_module_1.TenantsModule,
            subscriptions_module_1.SubscriptionsModule,
            vehicles_module_1.VehiclesModule,
            journeys_module_1.JourneysModule,
            approvals_module_1.ApprovalsModule,
            reports_module_1.ReportsModule,
        ],
        controllers: [app_controller_1.AppController],
    })
], AppModule);
//# sourceMappingURL=app.module.js.map