# eVehicle LogBook

> **Digital Vehicle Journey & Official Log Book Management System**  
> Designed for Government Departments, PSUs, Engineering Fleets, and Field Operations.

---

## 📌 Project Overview

**eVehicle LogBook** is an enterprise-grade digital journey management and official vehicle logbook system built according to Government compliance standards, the **Stitch UI Design System**, and strict **AQIL / ACHS** standards.

### Core Value & Principles:
- **Official Log-Book Distance**: `Official Distance = Closing Odometer - Opening Odometer`
- **GPS Supporting Distance**: Recorded via high-accuracy telemetry for cross-verification without replacing official odometer log.
- **Offline-First Resilience**: Mobile app records journeys locally via SQLite / persistent cache with idempotent sync engine (`client_operation_id`).
- **Fraud & Anomaly Guards**: Active odometer rollback blocking, duplicate journey prevention, and GPS discrepancy flagging.
- **Government Compliance**: Government standard Monthly Log Book register format with driver and controlling officer signature certification blocks, plus PDF & Excel exports.

---

## 📁 Standard Directory Structure

```text
├── android/               # Native Android project configuration
├── ios/                   # Native iOS project configuration
├── web/                   # Web build configuration
├── windows/               # Windows desktop configuration
├── macos/                 # macOS desktop configuration
├── linux/                 # Linux desktop configuration
├── lib/                   # Flutter application source code (Clean Architecture)
├── test/                  # Stack-native test suite (Unit, Widget, and Service tests)
├── docs/                  # PRD, Technical Architecture, and UI/UX design specifications
├── backend/               # NestJS enterprise backend API (TypeScript)
├── pubspec.yaml           # Flutter dependencies and project metadata
├── analysis_options.yaml  # Flutter/Dart static analysis & linter rules
└── README.md              # Project documentation
```

---

## 📱 Mobile Application Features

| Module | Features |
| :--- | :--- |
| **Authentication** | Official Gov Splash & Onboarding (3 slides), Password & OTP Login tabs, Role Switcher (User, Driver, Approver, Admin), Signup, OTP Countdown, Password Reset |
| **Dashboard** | Officer greeting & department badge, Live vehicle card with digital drum odometer, 2x2 KPI grid, Active trip alert banner, Today's journeys list |
| **Journey Management** | Start Journey (Odometer validation, GPS auto-lock, Purpose & Officers), Active Journey (Live elapsed timer, in-transit notes & stops), Complete Journey (Odometer math, validation, GPS comparison), Review & Success screens |
| **Log Book & Calendar** | Multi-filter history search (Date, Vehicle, Status), Detailed official record view with approval timeline & PDF slip export, Interactive Monthly Calendar with trip indicators |
| **Vehicle Registry** | Fleet list with document status badges (RC, Insurance, PUC, Fitness) with expiry countdowns, Maintenance logs & scheduling, Fuel fill logging with KM/L calculations |
| **Approvals Queue** | Pending journey verification, single & bulk approvals, rejection with mandatory remarks, monthly record locking |
| **Monthly Log Book** | Official government-formatted table, month & vehicle filters, total distance calculation, PDF download & print, CSV export |
| **Fleet Intelligence** | Admin utilization bar charts, telemetry audit, anomaly detection overview |

---

## 🛠️ Technology Stack

- **Mobile / Web Frontend**: Flutter 3.24.5 / Dart 3.5
- **Design System**: Stitch Modern UI System (`#004AC6` Primary, Inter Typography, Material 3)
- **State Management**: Riverpod (`flutter_riverpod`)
- **Navigation**: Declarative Routing (`go_router`)
- **Reports & Printing**: `pdf` & `printing`
- **Charts**: `fl_chart`
- **Backend API**: NestJS / TypeScript with OpenAPI / Swagger Documentation
- **Database**: Local SQLite & Persistent Storage / Remote PostgreSQL

---

## 🚀 Getting Started

### 1. Flutter Application (Workspace Root)
```bash
flutter pub get
flutter run
```

### 2. Run Tests
```bash
flutter test
```

### 3. Static Analysis
```bash
flutter analyze
```

### 4. Backend API
From workspace root:
```bash
npm run dev        # Starts backend API dev server
```
Or directly inside backend directory:
```bash
cd backend
npm install
npm run start:dev
```
- Swagger API Docs: `http://localhost:3000/api/docs`
- Base API Endpoint: `http://localhost:3000/api/v1`
