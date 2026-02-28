import os

from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker
from sqlalchemy.pool import NullPool

from app.core.config import settings

DATABASE_URL = os.getenv("DATABASE_URL") or settings.database_url


def _normalize_database_url(url: str) -> str:
    """Prefer psycopg v3 when a generic postgres URL is provided."""

    if url.startswith(("postgres://", "postgresql://")) and "+" not in url.split("://", 1)[0]:
        return url.replace("postgres://", "postgresql+psycopg://", 1).replace(
            "postgresql://", "postgresql+psycopg://", 1
        )
    return url


DATABASE_URL = _normalize_database_url(DATABASE_URL)

engine = create_engine(
    DATABASE_URL,
    poolclass=NullPool,  # VERY IMPORTANT for serverless
)

SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine,
)
Base = declarative_base()


def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
