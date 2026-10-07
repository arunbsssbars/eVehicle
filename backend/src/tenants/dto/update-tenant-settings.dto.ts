import { IsString, IsOptional, IsIn } from 'class-validator';
import { ApiPropertyOptional } from '@nestjs/swagger';

export class UpdateTenantSettingsDto {
  @ApiPropertyOptional({ example: 'INR', enum: ['INR', 'USD', 'EUR', 'GBP'] })
  @IsString()
  @IsOptional()
  @IsIn(['INR', 'USD', 'EUR', 'GBP'])
  currencyCode?: string;

  @ApiPropertyOptional({ example: '₹' })
  @IsString()
  @IsOptional()
  currencySymbol?: string;

  @ApiPropertyOptional({ example: 'km', enum: ['km', 'mi'] })
  @IsString()
  @IsOptional()
  @IsIn(['km', 'mi'])
  distanceUnit?: string;

  @ApiPropertyOptional({ example: '#004AC6' })
  @IsString()
  @IsOptional()
  brandPrimaryColor?: string;

  @ApiPropertyOptional({ example: 'https://cdn.example.com/logo.png' })
  @IsString()
  @IsOptional()
  brandLogoUrl?: string;

  @ApiPropertyOptional({ example: 'GSTIN07AABCS1429B1Z' })
  @IsString()
  @IsOptional()
  taxId?: string;
}
