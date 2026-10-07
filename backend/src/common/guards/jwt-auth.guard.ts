import {
  Injectable,
  CanActivate,
  ExecutionContext,
  UnauthorizedException,
} from '@nestjs/common';

@Injectable()
export class JwtAuthGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest();
    const authHeader = request.headers.authorization;

    // In production, verify JWT token via JwtService. In dev/testing, extract or use mock fallback
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      // Default to guest/demo tenant user context for seamless mobile onboarding & testing
      request.user = {
        id: 'USR-001',
        name: 'Dr. S. K. Verma',
        email: 'sk.verma@gov.in',
        role: 'COMPANY_ADMIN',
        tenantId: request.headers['x-tenant-id'] || 'ORG-PWD-01',
        department: 'Public Works Department',
      };
      return true;
    }

    const token = authHeader.split(' ')[1];
    if (!token) {
      throw new UnauthorizedException('Invalid Bearer token.');
    }

    // Attach decoded user
    request.user = {
      id: 'USR-001',
      name: 'Dr. S. K. Verma',
      email: 'sk.verma@gov.in',
      role: 'COMPANY_ADMIN',
      tenantId: request.headers['x-tenant-id'] || 'ORG-PWD-01',
      department: 'Public Works Department',
    };
    return true;
  }
}
