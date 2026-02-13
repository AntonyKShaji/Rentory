# Rentory

Rentory is a cross-platform rental management application for **property owners** and **tenants** with QR-based onboarding and property-level collaboration.

## Implemented feature set

### Owner side
- Owner signup/login.
- Add unlimited properties with details (`name`, `place`, `capacity`, `rent`, `description`) and a single image URL.
- Empty-state dashboard with CTA to create first property.
- Property cards showing image, name, occupancy, and rent.
- Dashboard analytics:
  - total properties grouped by location,
  - total tenants across all properties.
- Property detail screen APIs provide:
  - property metadata and image,
  - tenant list,
  - current bill amount,
  - water bill status (owner can switch paid/unpaid),
  - unique QR code value and renderable QR image URL.
- Group chat is now modeled with property-specific chat groups and membership validation (owner + tenants, text/image URL sharing).
- Tenant detail API by selecting a tenant.

### Tenant side
- Tenant onboarding using property QR code.
- Registration captures profile + documents + credentials.
- Tenant login flow.
- Tenant dashboard API with assigned property, owner phone, and rent.
- Access to property group chat.
- QR enrollment is capacity-aware (respects max tenants configured by owner).

## Repository structure

- `mobile/rentory_app/` — Flutter mobile application.
- `backend/rentory_api/` — FastAPI backend and tests.
- `docs/` — architecture, schema, API, and backlog artifacts.

## Run the backend API

```bash
cd backend/rentory_api
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
```

## Run backend tests

```bash
cd backend/rentory_api
pytest
```

## Run the Flutter app

```bash
cd mobile/rentory_app
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

For iOS simulator/local desktop target, use `http://127.0.0.1:8000`.
