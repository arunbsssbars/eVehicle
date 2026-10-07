# eVehicle LogBook — Stitch UI/UX Prompt

## Master Prompt

Design a premium, modern and highly usable mobile application named:

# eVehicle LogBook

Tagline:

**Digital Vehicle Journey & Log Book Management System**

The application is intended primarily for government departments, PSUs, engineering organizations and official vehicle fleets.

The UI must feel:

- Professional
- Trustworthy
- Modern
- Clean
- Minimal
- Fast
- Enterprise-grade
- Easy for non-technical government staff
- Suitable for daily operational use

Do not make the UI look like a taxi/ride-sharing application.

Do not use excessive gradients, unnecessary illustrations or gaming-style UI.

Use a restrained professional visual system with:

- Light background
- White cards
- Strong typography
- Clear hierarchy
- Rounded corners
- Subtle shadows
- Professional blue/indigo primary color
- Green for successful/approved states
- Orange for warnings
- Red for errors
- Neutral gray secondary colors

Support:

- Android
- iOS

Design mobile-first screens for approximately 390 x 844 px.

---

# 1. Splash Screen

Display:

eVehicle LogBook

Icon:

Vehicle + digital document concept

Subtitle:

Digital Vehicle Journey & Log Book

Minimal animation.

---

# 2. Onboarding

Three screens.

## Screen 1

Title:

**Your Vehicle Log Book, Digital**

Description:

Maintain official vehicle journeys quickly and securely from your mobile.

## Screen 2

Title:

**Record Every Journey**

Description:

Capture start location, destination, odometer, purpose and journey details.

## Screen 3

Title:

**Reports Made Simple**

Description:

Generate monthly log books, reports and official records instantly.

CTA:

Get Started

---

# 3. Login

Header:

Welcome Back

Fields:

Mobile Number / Email

Password

Actions:

Login

Forgot Password?

Login with OTP

Footer:

Don't have an account?

Create Account

---

# 4. Signup

Fields:

Full Name

Mobile Number

Email

Employee ID

Department

Office

Password

Confirm Password

CTA:

Create Account

---

# 5. OTP Verification

Title:

Verify your mobile number

Display:

OTP input boxes

Countdown

Resend OTP

CTA:

Verify

---

# 6. Dashboard

Header:

Good Morning, [Name]

Show:

Office name

Current vehicle card

Vehicle number

Vehicle model

Current odometer

Today's distance

Today's journey count

Primary CTA:

+ Start Journey

Cards:

Today's Distance

Monthly Distance

Pending Approvals

Active Journey

Section:

Today's Journeys

Each journey row:

Time

From → To

Distance

Status

Bottom navigation:

Home

Journeys

Vehicles

Reports

Profile

---

# 7. Start Journey

Header:

Start Journey

Progress indicator:

1. Journey
2. Destination
3. Review

Fields:

Vehicle

Driver

Opening Odometer

Starting Location

Purpose

Accompanying Officers

Remarks

Location card:

Current GPS location

"Use Current Location"

Primary CTA:

Start Journey

Important:

Opening odometer must be visually prominent.

---

# 8. Active Journey

Show a large active journey card.

Status:

JOURNEY ACTIVE

Elapsed time

Start location

Current location

Opening KM

Live/current KM if available

Map preview

Actions:

Add Stop

Add Note

End Journey

The End Journey button should be visually prominent.

---

# 9. End Journey

Title:

Complete Journey

Fields:

Destination

Closing Odometer

Remarks

Automatically show:

Opening KM

Closing KM

Total Distance

Example:

Opening:

52,340 KM

Closing:

52,485 KM

Distance:

145 KM

Show GPS distance separately:

GPS Distance: 142 KM

CTA:

Review Journey

---

# 10. Journey Review

Show a clean summary card.

Date

Vehicle

Driver

From

To

Purpose

Opening KM

Closing KM

Distance

GPS information

Remarks

Actions:

Save Draft

Submit Journey

---

# 11. Journey Success

Large success icon.

Title:

Journey Submitted

Message:

Your journey has been successfully recorded.

Show:

Journey ID

Distance

Date

CTA:

View Journey

Secondary:

Back to Dashboard

---

# 12. Journey History

Header:

Journey History

Search bar.

Filters:

Date

Vehicle

Driver

Status

Destination

Journey cards:

Date

From → To

Distance

Vehicle

Status

Tap to open details.

---

# 13. Journey Details

Display complete official record.

Sections:

Journey Information

Vehicle Information

Odometer

Location

Purpose

Approval

Audit

Buttons depending on status:

Edit

Submit

Cancel

View Map

Download PDF

---

# 14. Calendar View

Monthly calendar.

Days with journeys should show small indicators.

Selecting a date shows:

Total journeys

Total distance

Journey list

---

# 15. Vehicles

Header:

My Vehicles

Vehicle cards:

Registration Number

Vehicle model

Vehicle status

Current KM

Assigned driver

Tap:

Vehicle Details

---

# 16. Vehicle Details

Header:

UP16 AB 1234

Sections:

Vehicle Information

Current Odometer

Driver

Office

Documents

Insurance

PUC

Fitness

Service

Journey Statistics

Fuel Statistics

Actions:

View Journeys

Add Fuel

Maintenance

---

# 17. Reports

Dashboard-style screen.

Cards:

Daily Log

Monthly Log Book

Vehicle Report

Driver Report

Distance Report

Fuel Report

Maintenance Report

Allow:

Date range

Vehicle

Driver

Department

Export:

PDF

Excel

---

# 18. Monthly Log Book

Show a mobile preview of an official government-style table.

Header:

VEHICLE LOG BOOK

Month:

August 2026

Vehicle:

UP16 AB 1234

Rows:

Date

Driver

From

To

Purpose

Opening KM

Closing KM

Distance

Footer:

Total Distance

Approval status

Buttons:

Download PDF

Export Excel

---

# 19. Notifications

Notification categories:

Journey

Approval

Vehicle

Maintenance

Documents

System

Use clear icons and unread indicators.

---

# 20. Profile

Display:

Profile photo

Name

Employee ID

Designation

Department

Office

Mobile

Email

Actions:

Edit Profile

Change Password

Security

Devices

Logout

---

# 21. Settings

Sections:

Account

Notifications

Location

Offline Sync

Security

Language

About

Privacy

Terms

---

# 22. Admin Dashboard

Desktop/tablet-oriented responsive design.

KPIs:

Total Vehicles

Active Vehicles

Today's Journeys

Today's Distance

Pending Approvals

Service Due

Documents Expiring

Charts:

Monthly Distance

Vehicle Utilization

Journeys by Department

Top Vehicles by Distance

---

# 23. Admin Vehicle Management

Table:

Vehicle No

Model

Driver

Office

Current KM

Status

Actions

Actions:

Add Vehicle

Edit

Assign Driver

View History

Deactivate

---

# 24. Admin Journey Approval

Screen:

Pending Approvals

Each card/table row:

Journey ID

Date

Vehicle

Driver

From

To

Distance

Submitted By

Status

Actions:

View

Approve

Reject

---

# 25. Approval Detail

Display complete journey.

Show warning indicators for:

- Odometer anomaly
- GPS discrepancy
- Backdated entry
- Duplicate journey
- Overlapping journey

Actions:

Approve Journey

Reject Journey

Request Correction

---

# 26. Audit Log

Table/list:

Timestamp

User

Action

Entity

Old Value

New Value

IP

Device

Details

Provide filters.

---

# 27. Empty States

Create useful empty states.

Example:

No journeys yet.

"Your completed journeys will appear here."

CTA:

Start Journey

Do not use generic sad illustrations.

---

# 28. Error States

Use clear messages.

Example:

**Unable to sync**

Your journey is safely stored on this device and will sync automatically when internet connectivity is restored.

CTA:

Retry Sync

---

# 29. Offline Indicator

When offline, show a subtle banner:

**Offline Mode**

Your changes are being saved locally.

When synchronized:

**All changes synced**

---

# 30. Design System

Typography:

Use a modern sans-serif font.

Hierarchy:

Display

Headline

Title

Body

Caption

Use generous spacing.

Buttons:

Minimum comfortable touch target.

Cards:

12–16 px radius.

Inputs:

Clear labels above fields.

Do not rely only on placeholder text.

---

# 31. Accessibility

Support:

- Large text
- Good contrast
- Clear focus states
- Screen readers
- Large touch targets
- Error messages associated with fields
- Avoid color-only status indication

---

# 32. UI Navigation

Mobile:

```text
Home
Journeys
Vehicles
Reports
Profile
```

Floating/primary action:

**Start Journey**

Admin:

```text
Dashboard
Vehicles
Drivers
Journeys
Approvals
Reports
Users
Settings
Audit Logs
```

---

# 33. UX Principle

The most frequently performed action should require minimum effort.

Target flow:

```text
Open App
 ↓
Dashboard
 ↓
Start Journey
 ↓
Confirm Vehicle
 ↓
Enter Opening KM
 ↓
Confirm Location
 ↓
Start
```

For ending:

```text
Active Journey
 ↓
End Journey
 ↓
Enter Closing KM
 ↓
Confirm Destination
 ↓
Review
 ↓
Submit
```

The user should be able to complete a normal journey entry in less than one minute.

---

# 34. Final Stitch Instruction

Generate all screens as a coherent design system.

Do not design screens independently.

Maintain:

- Same spacing
- Same typography
- Same component system
- Same navigation
- Same colors
- Same card styles
- Same buttons
- Same input fields
- Same status indicators

The final result should look like a production-ready enterprise mobile application suitable for deployment in a government organization.