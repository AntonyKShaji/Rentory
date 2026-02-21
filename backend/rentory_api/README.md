# Rentory API (MVP)

This is a runnable backend MVP for Rentory using FastAPI + PostgreSQL via SQLAlchemy.

## Project structure (industrial-style layering)

- `app/controllers/` → route handlers (controller layer).
- `app/services/` → business logic and orchestration (service layer).
- `app/models.py` → SQLAlchemy entities (entity/model layer).
- `app/schemas.py` → request/response DTOs.
- `app/core/messages.py` → centralized API message constants.
- `app/core/config.py` → environment-aware settings.

## Environment configuration

Use one of these environment templates:

- Development: `.env.development`
- Production: `.env.production`

Example:

```bash
cp .env.development .env
set -a && source .env && set +a
```

## Run locally

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
cp .env.development .env
set -a && source .env && set +a
uvicorn app.main:app --reload --port 8000
```

## Endpoints included

- `POST /auth/login`
- `GET /owners/{owner_id}/properties`
- `POST /owners/{owner_id}/properties`
- `GET /properties/{property_id}`
- `POST /properties/{property_id}/tenants/join-requests`
- `POST /payments`
- `POST /notifications/broadcast`
- `POST /maintenance-tickets`
- `GET /health`

## Current data storage

- Uses `DATABASE_URL` from environment settings.
- Tables are auto-created on startup for MVP bootstrap.
- For production, use Alembic migrations and managed Postgres backups.
