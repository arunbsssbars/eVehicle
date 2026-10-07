import { Controller, Get, Query } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';

@ApiTags('Reports')
@Controller('reports')
export class ReportsController {
  @Get('monthly')
  @ApiOperation({ summary: 'Get monthly logbook aggregate' })
  getMonthlyReport(
    @Query('month') month: string,
    @Query('vehicleId') vehicleId: string,
  ) {
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

  @Get('daily')
  @ApiOperation({ summary: 'Get daily dispatch register' })
  getDailyReport(@Query('date') date: string) {
    return {
      success: true,
      data: {
        date: date || new Date().toISOString().split('T')[0],
        totalTrips: 4,
        totalDistanceKm: 185.0,
      },
    };
  }
}
