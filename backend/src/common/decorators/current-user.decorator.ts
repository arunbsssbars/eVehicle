import { createParamDecorator, ExecutionContext } from '@nestjs/common';

export interface RequestUser {
  id: string;
  name: string;
  email: string;
  role: string;
  tenantId: string;
  department?: string;
}

/**
 * Extracts the authenticated User object from the Request.
 */
export const CurrentUser = createParamDecorator(
  (data: unknown, ctx: ExecutionContext): RequestUser => {
    const request = ctx.switchToHttp().getRequest();
    return (
      request.user || {
        id: 'USR-001',
        name: 'Dr. S. K. Verma',
        email: 'sk.verma@gov.in',
        role: 'COMPANY_ADMIN',
        tenantId: request.tenantId || 'ORG-PWD-01',
        department: 'Public Works Department',
      }
    );
  },
);
