"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.CurrentUser = void 0;
const common_1 = require("@nestjs/common");
exports.CurrentUser = (0, common_1.createParamDecorator)((data, ctx) => {
    const request = ctx.switchToHttp().getRequest();
    return (request.user || {
        id: 'USR-001',
        name: 'Dr. S. K. Verma',
        email: 'sk.verma@gov.in',
        role: 'COMPANY_ADMIN',
        tenantId: request.tenantId || 'ORG-PWD-01',
        department: 'Public Works Department',
    });
});
//# sourceMappingURL=current-user.decorator.js.map