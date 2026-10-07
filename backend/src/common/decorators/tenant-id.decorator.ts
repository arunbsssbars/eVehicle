import { createParamDecorator, ExecutionContext } from '@nestjs/common';

/**
 * Extracts the tenantId from the validated request object (set by TenantGuard or JwtAuthGuard).
 */
export const TenantId = createParamDecorator(
  (data: unknown, ctx: ExecutionContext): string => {
    const request = ctx.switchToHttp().getRequest();
    return request.tenantId || request.headers['x-tenant-id'] || 'ORG-PWD-01';
  },
);
