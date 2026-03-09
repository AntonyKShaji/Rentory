from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy import text as sql_text

from app.controllers.auth_controller import router as auth_router
from app.controllers.operations_controller import router as operations_router
from app.controllers.owner_controller import router as owner_router
from app.controllers.property_controller import router as property_router
from app.controllers.tenant_controller import router as tenant_router
from app.core.config import settings
from app.database import Base, engine

app = FastAPI(title=settings.app_name, version=settings.app_version)
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
def startup() -> None:
    try:
        Base.metadata.create_all(bind=engine)
        _widen_legacy_image_columns()
    except SQLAlchemyError as exc:
        # Keep the API bootable even when database connectivity is temporarily unavailable
        # (for example, a missing DATABASE_URL in serverless preview deployments).
        print(f"Startup database initialization skipped: {exc}")


@app.get("/health")
def health() -> dict:
    return {
        "status": "ok",
        "service": "rentory-api",
        "db": "connected",
        "environment": settings.app_env,
    }


def _widen_legacy_image_columns() -> None:
    with engine.begin() as connection:
        if connection.dialect.name != "postgresql":
            return
        connection.execute(sql_text("ALTER TABLE IF EXISTS properties ALTER COLUMN image_url TYPE TEXT"))
        connection.execute(sql_text("ALTER TABLE IF EXISTS chat_messages ALTER COLUMN image_url TYPE TEXT"))
        connection.execute(sql_text("ALTER TABLE IF EXISTS properties ADD COLUMN IF NOT EXISTS is_active BOOLEAN NOT NULL DEFAULT TRUE"))
        connection.execute(sql_text("ALTER TABLE IF EXISTS properties ADD COLUMN IF NOT EXISTS area_sqft INTEGER"))
        connection.execute(sql_text("ALTER TABLE IF EXISTS properties ADD COLUMN IF NOT EXISTS parking_details VARCHAR(120)"))
        connection.execute(sql_text("ALTER TABLE IF EXISTS properties ADD COLUMN IF NOT EXISTS preferred_residents VARCHAR(120)"))
        connection.execute(sql_text("ALTER TABLE IF EXISTS properties ADD COLUMN IF NOT EXISTS advance_amount DOUBLE PRECISION NOT NULL DEFAULT 0"))
        connection.execute(sql_text("ALTER TABLE IF EXISTS properties ADD COLUMN IF NOT EXISTS full_address VARCHAR(240)"))
        connection.execute(sql_text("ALTER TABLE IF EXISTS properties ADD COLUMN IF NOT EXISTS caretaker_enabled BOOLEAN NOT NULL DEFAULT FALSE"))
        connection.execute(sql_text("ALTER TABLE IF EXISTS properties ADD COLUMN IF NOT EXISTS caretaker_name VARCHAR(120)"))
        connection.execute(sql_text("ALTER TABLE IF EXISTS properties ADD COLUMN IF NOT EXISTS caretaker_contact VARCHAR(30)"))
        connection.execute(sql_text("ALTER TABLE IF EXISTS properties ADD COLUMN IF NOT EXISTS property_reference VARCHAR(64)"))


app.include_router(auth_router)
app.include_router(owner_router)
app.include_router(property_router)
app.include_router(tenant_router)
app.include_router(operations_router)
