import os

from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base, sessionmaker
from sqlalchemy.pool import NullPool

from app.core.config import settings

DATABASE_URL = os.getenv("DATABASE_URL") or settings.database_url

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
