# Rentory API (MVP)

This is a runnable backend MVP for Rentory using FastAPI + PostgreSQL via SQLAlchemy.

## Run locally

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
export DATABASE_URL=postgresql+psycopg://postgres:postgres@localhost:5432/rentory
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

- Uses PostgreSQL connection via `DATABASE_URL`.
- Tables are auto-created on startup for MVP bootstrap.
- For production, use Alembic migrations and managed Postgres backups.
