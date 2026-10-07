# eVehicle LogBook — Product Requirements Document

## 1. Product Overview

**Product Name:** eVehicle LogBook

**Tagline:** Digital Vehicle Journey & Log Book Management System

eVehicle LogBook is a cross-platform mobile application for maintaining official vehicle journey and log-book records digitally.

The application is primarily designed for:

- Government departments
- Government offices
- PSUs
- Electricity utilities
- Field engineering organizations
- Municipal organizations
- Universities
- Hospitals
- Private fleet operators

The system will replace or supplement traditional paper vehicle log books while maintaining strong auditability, approval workflows, odometer records, reporting and administrative controls.

---

# 2. Primary Objective

The application shall allow authorized users to digitally record every vehicle journey.

For every journey the system should maintain:

- Vehicle
- Driver
- User/Officer
- Date
- Start time
- End time
- Starting location
- Destination
- Purpose
- Opening odometer
- Closing odometer
- Automatically calculated distance
- GPS coordinates where permission is available
- GPS distance as supporting information
- Remarks
- Approval status
- Audit history

---

# 3. Core Principle

The application shall distinguish between:

### Official Distance

Calculated from:

`Closing Odometer - Opening Odometer`

This is the primary log-book distance.

### GPS Distance

Calculated from recorded GPS locations/routes.

GPS distance shall be treated as supporting/verification information and shall not replace the official odometer distance.

---

# 4. User Roles

## 4.1 Super Administrator

Permissions:

- Manage organizations
- Manage departments
- Manage offices
- Manage vehicles
- Manage users
- Manage drivers
- Configure system
- View all reports
- View audit logs
- Manage roles
- Lock monthly records

## 4.2 Department Administrator

Permissions:

- Manage department vehicles
- Manage drivers
- Manage users
- View department journeys
- Approve journeys
- Generate reports

## 4.3 Approving Officer

Permissions:

- View submitted journeys
- Verify journeys
- Approve journeys
- Reject journeys
- Add remarks
- Lock approved records where authorized

## 4.4 Driver

Permissions:

- View assigned vehicle
- Start journey
- End journey
- Enter odometer readings
- Enter destination
- Enter purpose
- View own journeys

## 4.5 General User/Officer

Permissions:

- Select authorized vehicle
- Create journey
- Submit journey
- View own journeys
- Download permitted reports

---

# 5. Authentication

The application shall support:

- Mobile number login
- Email login
- Password login
- OTP verification
- Forgot password
- Reset password
- Refresh token
- Secure logout
- Session/device management

Future support:

- Government employee ID
- Organization SSO
- Enterprise identity provider

Passwords must never be stored in plain text.

Authentication should use secure token-based authentication.

---

# 6. Main Application Modules

## Authentication

- Splash
- Onboarding
- Login
- Sign Up
- OTP Verification
- Forgot Password
- Reset Password

## Dashboard

- Current vehicle
- Today's journeys
- Today's distance
- Monthly distance
- Pending approvals
- Active journey
- Notifications

## Journey Management

- Start Journey
- Active Journey
- End Journey
- Journey Details
- Journey History
- Calendar
- Search/filter
- Edit journey
- Submit journey
- Cancel journey

## Vehicle Management

- Vehicle list
- Vehicle details
- Assigned driver
- Odometer
- Documents
- Service information

## Reports

- Daily report
- Weekly report
- Monthly log book
- Vehicle-wise report
- Driver-wise report
- Department-wise report
- Distance report
- Utilization report

## Administration

- Users
- Drivers
- Vehicles
- Departments
- Offices
- Approvals
- Audit logs
- Settings

---

# 7. Journey Workflow

The standard workflow:

```text
Create Journey
      ↓
Enter Start Information
      ↓
Record Opening Odometer
      ↓
Start Journey
      ↓
Active Journey
      ↓
Reach Destination
      ↓
Enter Closing Odometer
      ↓
Calculate Distance
      ↓
Review
      ↓
Submit
      ↓
Pending Approval
      ↓
Approved
      ↓
Locked
```

Rejected journey:

```text
Rejected
   ↓
Correction
   ↓
Resubmit
   ↓
Approval
```

---

# 8. Start Journey

Required fields:

- Vehicle
- Driver
- Date
- Start time
- Starting location
- Purpose
- Opening odometer

Optional:

- GPS location
- Accompanying officers
- Remarks

The system should automatically capture:

- Device ID
- User ID
- Server timestamp
- GPS coordinates if permitted

---

# 9. End Journey

Required:

- End time
- Destination
- Closing odometer

Automatically calculated:

```text
Distance = Closing Odometer - Opening Odometer
```

Validation:

```text
Closing Odometer >= Opening Odometer
```

If not:

Show:

> Closing odometer cannot be less than opening odometer.

---

# 10. GPS

GPS shall be permission based.

The application may capture:

- Start latitude
- Start longitude
- End latitude
- End longitude
- Route coordinates when enabled
- GPS distance
- GPS accuracy

The user must be informed why location permission is required.

Location tracking must not continue unnecessarily after the journey ends.

---

# 11. Offline First

The mobile application must work without internet.

Offline flow:

```text
User
 ↓
Flutter App
 ↓
Local Database
 ↓
Journey Saved
 ↓
Network Available
 ↓
Sync Engine
 ↓
Backend API
 ↓
PostgreSQL
```

Every locally created record should receive a local UUID.

Synchronization must be idempotent so that the same journey cannot accidentally be uploaded twice.

---

# 12. Conflict Handling

If an offline record conflicts with a server record:

The application must not silently overwrite data.

Possible states:

- Sync Pending
- Syncing
- Synced
- Conflict
- Failed

Conflict resolution should retain the original audit history.

---

# 13. Odometer Validation

The system should remember the vehicle's latest accepted odometer reading.

Example:

Previous:

`52,340 KM`

New opening:

`52,100 KM`

System warning:

> Opening odometer is lower than the previous recorded reading.

Depending on role configuration:

- Prevent submission
- Allow with reason
- Require administrator approval

---

# 14. Fraud/Anomaly Detection

The system should flag:

### Odometer rollback

New reading lower than previous reading.

### Duplicate journey

Same vehicle, date, origin, destination and overlapping time.

### Overlapping journeys

Two active journeys for the same vehicle.

### Excessive discrepancy

Large difference between GPS and odometer distance.

### Backdated entry

Journey created significantly after the journey date.

### Future entry

Journey date/time in the future.

### Unusually long journey

Distance exceeds configured threshold.

These should generate warnings or audit events.

---

# 15. Journey Status

```text
DRAFT
ACTIVE
COMPLETED
SUBMITTED
PENDING_APPROVAL
APPROVED
REJECTED
CANCELLED
LOCKED
SYNC_PENDING
SYNC_FAILED
```

---

# 16. Monthly Log Book

The application shall generate a government-style monthly log book.

Fields:

- Organization
- Department
- Office
- Vehicle number
- Vehicle model
- Driver
- Month
- Journey rows
- Opening KM
- Closing KM
- Distance
- Purpose
- Remarks
- Approval status

Footer:

- Total journeys
- Total distance
- Certification
- Driver signature
- Controlling officer signature

---

# 17. PDF Export

Generate professional PDF reports.

Types:

- Journey receipt
- Daily log
- Monthly log book
- Vehicle history
- Driver report
- Department report

PDF should include:

- Organization logo
- Report title
- Vehicle information
- Date range
- Journey table
- Totals
- Approval information
- Generated timestamp
- Report ID

---

# 18. Excel Export

Excel export should contain:

- Serial number
- Date
- Vehicle
- Driver
- Start time
- End time
- Start location
- Destination
- Purpose
- Opening KM
- Closing KM
- Distance
- GPS distance
- Status
- Approved by
- Remarks

---

# 19. Vehicle Module

Vehicle fields:

- Vehicle ID
- Registration number
- Make
- Model
- Vehicle type
- Fuel type
- Manufacturing year
- Purchase date
- Current odometer
- Assigned office
- Assigned driver
- Status

Vehicle statuses:

- ACTIVE
- INACTIVE
- UNDER_REPAIR
- SOLD
- RETIRED

---

# 20. Vehicle Documents

Support:

- RC
- Insurance
- PUC
- Fitness certificate
- Permit
- Other documents

Each document should contain:

- Document type
- Document number
- Issue date
- Expiry date
- Attachment
- Verification status

Notifications should be generated before expiry.

---

# 21. Fuel Module

Fuel records:

- Vehicle
- Date
- Fuel station
- Fuel type
- Quantity
- Rate
- Amount
- Odometer
- Receipt
- Remarks

Analytics:

- Fuel consumption
- Average KM/L
- Fuel cost/km
- Monthly fuel expenditure
- Vehicle-wise fuel usage

---

# 22. Maintenance Module

Maintenance records:

- Vehicle
- Service date
- Odometer
- Service type
- Work performed
- Parts replaced
- Cost
- Vendor
- Invoice
- Next service KM
- Next service date

---

# 23. Notifications

Notifications include:

- Journey pending
- Approval pending
- Journey rejected
- Vehicle service due
- Insurance expiry
- PUC expiry
- Fitness expiry
- Sync failure
- Odometer anomaly

---

# 24. Audit Trail

Every important change must be recorded.

Audit fields:

- Audit ID
- User ID
- Action
- Entity
- Entity ID
- Previous value
- New value
- IP address
- Device ID
- Timestamp
- Reason

Example:

```text
Action:
UPDATE_JOURNEY

Field:
Opening Odometer

Old:
52340

New:
52345

Reason:
Incorrect entry
```

Approved/locked records should not be silently modified.

---

# 25. Search and Filters

Users should be able to filter by:

- Date
- Vehicle
- Driver
- Department
- Office
- Status
- Destination
- Purpose

Search should support:

- Vehicle number
- Journey ID
- Driver name
- Destination

---

# 26. Dashboard KPIs

Dashboard cards:

### Today's Journeys

12

### Today's Distance

386 KM

### Monthly Distance

4,850 KM

### Active Vehicles

24

### Pending Approvals

8

### Vehicles Due for Service

3

### Expiring Documents

5

---

# 27. Security

Required:

- HTTPS
- JWT authentication
- Refresh tokens
- Password hashing
- Role-based authorization
- Input validation
- Rate limiting
- Secure storage
- API authorization
- Audit logging
- CORS configuration
- Security headers
- Database backups
- Encryption at rest where appropriate

NestJS provides built-in architectural mechanisms for guards, authentication, authorization, validation and security features suitable for this design.

---

# 28. Non-Functional Requirements

## Performance

Normal API responses:

Target < 500 ms excluding large reports.

## Availability

Target:

99.5%+

## Scalability

The architecture should support:

- 10,000+ users
- 5,000+ vehicles
- Millions of journey records

## Reliability

Offline data must not be lost because of temporary network failure.

---

# 29. Recommended Technology

## Mobile

Flutter

Dart

Riverpod

GoRouter

Dio

Drift/SQLite

Secure Storage

## Backend

NestJS

TypeScript

REST API

JWT

Swagger/OpenAPI

Prisma ORM

## Database

PostgreSQL

## Cache/Jobs

Redis

BullMQ

## Storage

S3-compatible object storage

## Maps

Google Maps or Mapbox

## Push notifications

Firebase Cloud Messaging

## Monitoring

Sentry

Structured application logging

---

# 30. Future Features

Possible future modules:

- GPS route tracking
- Driver attendance
- Vehicle reservation
- Vehicle booking
- Pool vehicle management
- Trip approval before journey
- eSign
- Digital certificate
- Fuel card integration
- FASTag integration
- Expense management
- Accident reporting
- Tyre management
- Battery management
- Fleet analytics
- Web administration portal
- Organization-wide analytics
- SSO

---

# 31. Product Goal

The final product should feel like a professional enterprise application, not a simple CRUD logbook.

The application should prioritize:

1. Simplicity
2. Reliability
3. Offline operation
4. Auditability
5. Security
6. Government-style reporting
7. Modern UI
8. Scalability
9. Low training requirement
10. Excellent mobile experience