# Rentory MVP

Rentory is a cross-platform rental management application for **property owners** and **tenants**.
This repository contains an MVP foundation designed for release on both **Android (Play Store)** and **iOS (App Store)** using Flutter.

## MVP goals

- Separate experiences for owner and tenant users.
- Owner dashboard with property overview, bill status, notifications, and quick communication actions.
- Tenant dashboard with rent payment visibility, issue requests, and owner communication.
- Core data model and API contract for future backend implementation.

## Repository structure

- `mobile/rentory_app/` — Flutter MVP app (UI + navigation + sample data).
- `docs/mvp-product-requirements.md` — Product scope and feature definition.
- `docs/mvp-technical-architecture.md` — Suggested architecture and release approach.
- `docs/api/openapi.yaml` — Initial API contract for backend services.
- `docs/database-schema.sql` — Initial relational schema.
- `backend/rentory_api/` — Runnable FastAPI backend MVP.

## Run the Flutter app

1. Install Flutter (stable channel).
2. From `mobile/rentory_app`, run:

```bash
flutter pub get
flutter run
```

## What this MVP includes today

- Role switcher (Owner / Tenant) at login stage.
- Owner home with:
  - Search, notifications, profile actions.
  - Property grouping by location.
  - Property cards with occupancy and bill status indicators.
  - Property details with tenant contacts and pending bills.
- Tenant home with:
  - Assigned property summary.
  - Payment status blocks (Rent/Electricity/Water).
  - Service request composer.
  - QR onboarding placeholder flow.

## Next steps after MVP

- Integrate real authentication + authorization.
- Connect payment gateway and receipt generation.
- Add push notifications and chat.
- Add subscriptions and feature-tier enforcement.


## Run the backend API

1. From `backend/rentory_api`:

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
```


## Frontend ↔ Backend connection status

- The Owner dashboard now fetches properties from backend endpoint `GET /owners/owner-1/properties`.
- The `Add Property` action calls `POST /owners/owner-1/properties`.
- API base URL is configurable via dart define:

```bash
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

For Android emulator, use:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

## Database recommendation

- **Best choice:** PostgreSQL (matches structured entities like users/properties/bills/payments/leases).
- **Current backend state:** PostgreSQL connection implemented with SQLAlchemy (`DATABASE_URL`).
- **Next step:** add Alembic migrations, indexing, and production-grade backup/restore.


## Backend PostgreSQL config

```bash
export DATABASE_URL=postgresql+psycopg://postgres:postgres@localhost:5432/rentory
```
