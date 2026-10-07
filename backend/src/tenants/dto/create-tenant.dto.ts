import { IsString, IsNotEmpty, IsEmail, IsOptional, Matches } from 'class-validator';
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';

export class CreateTenantDto {
  @ApiProperty({ example: 'Logistics Fleet Pro' })
  @IsString()
  @IsNotEmpty()
  name: string;

  @ApiProperty({ example: 'logistics-pro' })
  @IsString()
  @IsNotEmpty()
  @Matches(/^[a-z0-9-]+$/, {
    message: 'Slug must contain only lowercase alphanumeric characters and hyphens',
  })
  slug: string;

  @ApiProperty({ example: 'admin@logisticspro.com' })
  @IsEmail()
  adminEmail: string;

  @ApiProperty({ example: 'Rajesh Sharma' })
  @IsString()
  @IsNotEmpty()
  adminName: string;

  @ApiPropertyOptional({ example: '+91 98765 43210' })
  @IsString()
  @IsOptional()
  contactMobile?: string;

  @ApiPropertyOptional({ example: 'PRO', enum: ['FREE', 'PRO', 'ENTERPRISE'] })
  @IsString()
  @IsOptional()
  initialPlan?: string;
}
