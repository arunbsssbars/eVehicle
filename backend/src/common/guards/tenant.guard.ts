import {
  Injectable,
  CanActivate,
  ExecutionContext,
  BadRequestException,
} from '@nestjs/common';

@Injectable()
export class TenantGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest();
    const tenantIdHeader = request.headers['x-tenant-id'] as string;
    const userTenantId = request.user?.tenantId;

    const resolvedTenantId = tenantIdHeader || userTenantId || 'ORG-PWD-01';

    if (!resolvedTenantId) {
      throw new BadRequestException(
        'Missing required tenant context (x-tenant-id header or authenticated tenant token claim).',
      );
    }

    // Attach resolved tenant ID to request object for downstream services and controllers
    request.tenantId = resolvedTenantId;
    return true;
  }
}
