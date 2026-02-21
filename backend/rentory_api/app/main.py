from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
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
    Base.metadata.create_all(bind=engine)
    _widen_legacy_image_columns()


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


app.include_router(auth_router)
app.include_router(owner_router)
app.include_router(property_router)
app.include_router(tenant_router)
app.include_router(operations_router)
