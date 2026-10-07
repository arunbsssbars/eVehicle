import { Controller, Get, Post, Param, Body } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';

@ApiTags('Approvals')
@Controller('approvals')
export class ApprovalsController {
  @Get('pending')
  @ApiOperation({ summary: 'Get all pending approval requests' })
  findPending() {
    return {
      success: true,
      data: [],
    };
  }

  @Post(':id/approve')
  @ApiOperation({ summary: 'Approve an official journey' })
  approve(@Param('id') id: string) {
    return {
      success: true,
      data: {
        id,
        status: 'APPROVED',
        approvedAt: new Date().toISOString(),
      },
    };
  }

  @Post(':id/reject')
  @ApiOperation({ summary: 'Reject an official journey with remarks' })
  reject(@Param('id') id: string, @Body('reason') reason: string) {
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

  @Post(':id/lock')
  @ApiOperation({ summary: 'Lock and archive approved record' })
  lock(@Param('id') id: string) {
    return {
      success: true,
      data: {
        id,
        status: 'LOCKED',
        lockedAt: new Date().toISOString(),
      },
    };
  }
}
