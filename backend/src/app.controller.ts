import { Controller, Get } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';

@ApiTags('Health & Index')
@Controller()
export class AppController {
  @Get()
  @ApiOperation({ summary: 'API Root & Health Check' })
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

  @Get('health')
  @ApiOperation({ summary: 'Health Check Endpoint' })
  getHealth() {
    return {
      status: 'healthy',
      uptime: process.uptime(),
      timestamp: new Date().toISOString(),
    };
  }
}
