import os
from dataclasses import dataclass


@dataclass(frozen=True)
class Settings:
    app_name: str = os.getenv("APP_NAME", "Rentory API")
    app_version: str = os.getenv("APP_VERSION", "1.1.0")
    app_env: str = os.getenv("APP_ENV", "development")
    database_url: str = os.getenv(
        "DATABASE_URL",
        "postgresql+psycopg://postgres:postgres@localhost:5432/rentory",
    )
    cors_origins: list[str] = None
    jwt_secret_key: str = os.getenv("JWT_SECRET_KEY", "change-me-in-production")
    access_token_expiry_minutes: int = int(os.getenv("ACCESS_TOKEN_EXPIRY_MINUTES", "30"))

    def __post_init__(self) -> None:
        origins = os.getenv("CORS_ORIGINS", "*")
        object.__setattr__(self, "cors_origins", [origin.strip() for origin in origins.split(",") if origin.strip()])


settings = Settings()
