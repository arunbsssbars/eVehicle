import { Controller, Post, Body, HttpCode, HttpStatus } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';

@ApiTags('Authentication')
@Controller('auth')
export class AuthController {
  @Post('login')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Login with Email/Mobile and Password' })
  @ApiResponse({ status: 200, description: 'JWT authentication tokens returned.' })
  login(@Body() body: any) {
    return {
      success: true,
      data: {
        accessToken: 'mock_jwt_access_token_v1',
        refreshToken: 'mock_jwt_refresh_token_v1',
        user: {
          id: 'USR-001',
          name: 'Dr. S. K. Verma',
          email: body.email || 'sk.verma@gov.in',
          role: 'USER',
          department: 'Public Works Department',
          office: 'District Division 1, Noida',
        },
      },
    };
  }

  @Post('register')
  @ApiOperation({ summary: 'Register a new official user' })
  register(@Body() body: any) {
    return {
      success: true,
      data: {
        message: 'Account created successfully. Pending officer verification.',
        userId: 'USR-' + Date.now(),
      },
    };
  }

  @Post('verify-otp')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Verify 6-digit OTP' })
  verifyOtp(@Body() body: any) {
    return {
      success: true,
      data: {
        accessToken: 'mock_jwt_access_token_v1',
        verified: true,
      },
    };
  }
}
