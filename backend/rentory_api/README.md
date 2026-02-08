# Rentory API (MVP)

This is a runnable backend MVP for Rentory using FastAPI.

## Run locally

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
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

> Note: Storage is currently in-memory for MVP/dev usage.
