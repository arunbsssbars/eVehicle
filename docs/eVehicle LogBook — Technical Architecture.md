# eVehicle LogBook — Technical Architecture

## 1. Architecture Overview

```text
                    ┌─────────────────────┐
                    │   Flutter Mobile    │
                    │    Android / iOS    │
                    └──────────┬──────────┘
                               │
                         HTTPS / JSON
                               │
                               ▼
                    ┌─────────────────────┐
                    │     API Gateway     │
                    └──────────┬──────────┘
                               │
                               ▼
                    ┌─────────────────────┐
                    │      NestJS         │
                    │      Backend        │
                    └──────────┬──────────┘
                               │
             ┌─────────────────┼────────────────┐
             │                 │                │
             ▼                 ▼                ▼
        PostgreSQL           Redis          Object Storage
             │                 │                │
             └─────────────────┼────────────────┘
                               │
                               ▼
                     Background Workers
```

---

# 2. Monorepo

Recommended structure:

```text
vehicle-logbook/
│
├── apps/
│   ├── mobile/
│   ├── admin-web/
│   └── api/
│
├── packages/
│   ├── shared-types/
│   ├── api-client/
│   ├── design-system/
│   └── config/
│
├── infrastructure/
│   ├── docker/
│   ├── database/
│   └── deployment/
│
├── docs/
│
├── scripts/
│
├── .github/
│
├── docker-compose.yml
├── README.md
└── package.json
```

---

# 3. Flutter Structure

```text
apps/mobile/lib/

├── app/
│   ├── app.dart
│   ├── router.dart
│   ├── theme/
│   └── config/
│
├── core/
│   ├── constants/
│   ├── errors/
│   ├── network/
│   ├── storage/
│   ├── permissions/
│   ├── location/
│   ├── utils/
│   └── widgets/
│
├── features/
│   ├── auth/
│   ├── dashboard/
│   ├── journeys/
│   ├── vehicles/
│   ├── reports/
│   ├── notifications/
│   ├── profile/
│   └── settings/
│
└── main.dart
```

Use feature-based architecture rather than placing every screen in one global screens folder.

Flutter's current architecture guidance explicitly emphasizes intentional architecture for maintainability and scalability.

---

# 4. Feature Structure

Example:

```text
features/journeys/

├── data/
│   ├── datasources/
│   ├── models/
│   └── repositories/
│
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
│
└── presentation/
    ├── providers/
    ├── screens/
    └── widgets/
```

---

# 5. State Management

Use Riverpod.

State categories:

### Authentication State

- unauthenticated
- authenticating
- authenticated
- session expired

### Journey State

- idle
- creating
- active
- completing
- submitted
- syncing
- synced
- failed

### Sync State

- online
- offline
- pending
- syncing
- conflict
- failed

Flutter's documentation distinguishes application state from ephemeral UI state; this project should keep persistent business state separate from temporary UI state.

---

# 6. Local Database

Use SQLite through a strongly typed Flutter database layer.

Local tables:

```text
local_users
local_vehicles
local_journeys
local_journey_locations
local_sync_queue
local_documents
local_settings
```

Every offline entity should have:

```text
local_id
server_id
sync_status
created_at
updated_at
```

---

# 7. Synchronization

Sync engine:

```text
Connectivity Change
       ↓
Check Pending Queue
       ↓
Upload Pending Records
       ↓
Receive Server IDs
       ↓
Update Local Records
       ↓
Download Server Changes
       ↓
Resolve Conflicts
       ↓
Mark Synced
```

All mutations should be idempotent.

Use an idempotency key such as:

```text
client_operation_id
```

---

# 8. Backend Structure

```text
apps/api/src/

├── main.ts
├── app.module.ts
│
├── common/
│   ├── guards/
│   ├── interceptors/
│   ├── filters/
│   ├── decorators/
│   ├── pipes/
│   └── utils/
│
├── config/
│
├── auth/
├── users/
├── organizations/
├── departments/
├── offices/
├── vehicles/
├── drivers/
├── journeys/
├── approvals/
├── fuel/
├── maintenance/
├── documents/
├── notifications/
├── reports/
├── audit/
└── health/
```

NestJS is specifically designed around modular controllers/providers and supports guards, interceptors, validation, authorization and other enterprise concerns.

---

# 9. Backend Modules

## AuthModule

Responsibilities:

- Login
- Signup
- OTP
- Password reset
- JWT
- Refresh tokens
- Session management

## UsersModule

- User CRUD
- Roles
- Permissions
- Profile

## VehiclesModule

- Vehicle CRUD
- Assignment
- Odometer
- Status

## JourneysModule

- Create journey
- Start journey
- Complete journey
- Update journey
- Submit journey
- Journey history

## ApprovalModule

- Pending approvals
- Approve
- Reject
- Lock

## ReportsModule

- Daily
- Monthly
- Vehicle
- Driver
- Department

## AuditModule

- Record all sensitive actions

---

# 10. Database

PostgreSQL entities:

```text
organizations
departments
offices
users
roles
permissions
user_roles
vehicles
drivers
vehicle_assignments
journeys
journey_locations
journey_approvals
fuel_entries
maintenance_records
vehicle_documents
notifications
audit_logs
refresh_tokens
```

---

# 11. Journey Database Model

```text
Journey

id
organization_id
department_id
office_id
vehicle_id
driver_id
created_by
journey_date
start_time
end_time
start_location
destination
opening_odometer
closing_odometer
distance
gps_distance
start_latitude
start_longitude
end_latitude
end_longitude
purpose
remarks
status
client_operation_id
created_at
updated_at
```

---

# 12. API Design

Base:

```text
/api/v1
```

Authentication:

```text
POST /auth/register
POST /auth/login
POST /auth/refresh
POST /auth/logout
POST /auth/forgot-password
POST /auth/reset-password
POST /auth/verify-otp
```

Users:

```text
GET    /users/me
PATCH  /users/me
```

Vehicles:

```text
GET    /vehicles
POST   /vehicles
GET    /vehicles/:id
PATCH  /vehicles/:id
DELETE /vehicles/:id
```

Journeys:

```text
GET    /journeys
POST   /journeys
GET    /journeys/:id
PATCH  /journeys/:id
POST   /journeys/:id/start
POST   /journeys/:id/complete
POST   /journeys/:id/submit
POST   /journeys/:id/cancel
```

Approvals:

```text
GET  /approvals/pending
POST /approvals/:id/approve
POST /approvals/:id/reject
POST /approvals/:id/lock
```

Reports:

```text
GET /reports/daily
GET /reports/monthly
GET /reports/vehicle
GET /reports/driver
GET /reports/department
```

---

# 13. API Response Standard

Success:

```json
{
  "success": true,
  "data": {},
  "meta": {}
}
```

Error:

```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Closing odometer cannot be lower than opening odometer."
  }
}
```

---

# 14. Security

Implement:

- JWT
- Refresh-token rotation
- Password hashing
- RBAC
- DTO validation
- Rate limiting
- HTTPS
- Secure headers
- CORS
- Request logging
- Audit logs
- Database backups
- Secrets through environment variables
- No secrets committed to Git

NestJS documents JWT-based authentication and role-based authorization as standard patterns.

---

# 15. API Documentation

Use OpenAPI/Swagger.

Every endpoint should document:

- Request
- Response
- Authentication
- Permissions
- Error codes
- Examples

---

# 16. Role-Based Access

Example:

```text
SUPER_ADMIN
    ↓
DEPARTMENT_ADMIN
    ↓
APPROVING_OFFICER
    ↓
USER
    ↓
DRIVER
```

Permissions should be granular.

Example:

```text
journey:create
journey:update
journey:submit
journey:approve
journey:reject
journey:lock
vehicle:create
vehicle:update
report:view
report:export
audit:view
```

---

# 17. Deployment

Development:

```text
Docker Compose
├── PostgreSQL
├── Redis
└── API
```

Production:

```text
Mobile
  ↓
Load Balancer
  ↓
API Servers
  ↓
PostgreSQL
  ↓
Redis
  ↓
Object Storage
```

Use CI/CD for:

- lint
- tests
- build
- migration
- deployment

---

# 18. Testing

## Flutter

- Unit tests
- Widget tests
- Integration tests

## Backend

- Unit tests
- Controller tests
- Service tests
- Integration tests
- E2E tests

Critical scenarios:

1. Login
2. Start journey
3. Complete journey
4. Odometer validation
5. Offline journey
6. Sync
7. Duplicate prevention
8. Approval
9. Rejection
10. Locking
11. Report generation
12. Authorization

---

# 19. Development Rule

Do not build the application as one giant implementation.

Implement vertically:

```text
Authentication
    ↓
Dashboard
    ↓
Vehicle
    ↓
Journey
    ↓
Offline Sync
    ↓
Approval
    ↓
Reports
    ↓
Admin
```

Each feature should be fully functional before moving to the next major feature.