# Rentory MVP Technical Architecture

## Mobile app
- **Framework:** Flutter (single codebase for Android + iOS).
- **State management:** Provider/Riverpod (recommended for next step).
- **Navigation:** role-based routing (Owner stack vs Tenant stack).

## Backend (recommended)
- **API:** REST with JWT auth.
- **Runtime:** Node.js (NestJS/Express) or Django/FastAPI.
- **Database:** PostgreSQL.
- **Queue/notifications:** Firebase Cloud Messaging + background scheduler.

## Core modules
1. Auth & Profiles
2. Properties & Units
3. Tenant Association (QR + approval)
4. Billing & Payments
5. Notifications
6. Maintenance Tickets
7. Reports & Export

## Security and compliance
- Role-based authorization for owner/tenant/supervisor.
- Audit logs for payment and profile changes.
- Sensitive data encryption at rest and transit.

## Store release path
1. Complete MVP UX + QA on Android and iOS simulators/devices.
2. Configure Android signing + iOS provisioning.
3. Publish beta using Google Internal Testing + TestFlight.
4. Resolve beta feedback and release public v1.
