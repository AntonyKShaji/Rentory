import base64
import hashlib
import hmac
import json
import os
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone

from fastapi import Depends, HTTPException
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from app.core import messages
from app.core.config import settings


@dataclass(frozen=True)
class AuthUser:
    user_id: str
    role: str


class SecurityService:
    _algorithm = "HS256"
    _password_scheme = "pbkdf2_sha256"
    _password_iterations = 390000

    @staticmethod
    def _b64url_encode(data: bytes) -> str:
        return base64.urlsafe_b64encode(data).rstrip(b"=").decode("utf-8")

    @staticmethod
    def _b64url_decode(data: str) -> bytes:
        padding = "=" * (-len(data) % 4)
        return base64.urlsafe_b64decode(f"{data}{padding}".encode("utf-8"))

    @classmethod
    def hash_password(cls, password: str) -> str:
        salt = os.urandom(16)
        digest = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt, cls._password_iterations)
        salt_b64 = cls._b64url_encode(salt)
        digest_b64 = cls._b64url_encode(digest)
        return f"{cls._password_scheme}${cls._password_iterations}${salt_b64}${digest_b64}"

    @classmethod
    def verify_password(cls, password: str, hashed_password: str | None) -> bool:
        if not hashed_password:
            return False
        if hashed_password.startswith("plain::"):
            return hmac.compare_digest(hashed_password, f"plain::{password}")

        parts = hashed_password.split("$")
        if len(parts) != 4:
            return False
        scheme, iterations_raw, salt_b64, digest_b64 = parts
        if scheme != cls._password_scheme:
            return False

        iterations = int(iterations_raw)
        salt = cls._b64url_decode(salt_b64)
        expected = cls._b64url_decode(digest_b64)
        actual = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt, iterations)
        return hmac.compare_digest(actual, expected)

    @classmethod
    def create_access_token(cls, user_id: str, role: str) -> str:
        now = int(datetime.now(tz=timezone.utc).timestamp())
        payload = {
            "sub": user_id,
            "role": role,
            "type": "access",
            "iat": now,
            "nbf": now,
            "exp": now + settings.access_token_expiry_minutes * 60,
        }
        header = {"alg": cls._algorithm, "typ": "JWT"}

        header_segment = cls._b64url_encode(json.dumps(header, separators=(",", ":")).encode("utf-8"))
        payload_segment = cls._b64url_encode(json.dumps(payload, separators=(",", ":")).encode("utf-8"))
        signing_input = f"{header_segment}.{payload_segment}".encode("utf-8")
        signature = hmac.new(settings.jwt_secret_key.encode("utf-8"), signing_input, hashlib.sha256).digest()
        signature_segment = cls._b64url_encode(signature)
        return f"{header_segment}.{payload_segment}.{signature_segment}"

    @classmethod
    def decode_access_token(cls, token: str) -> AuthUser:
        try:
            header_segment, payload_segment, signature_segment = token.split(".")
            signing_input = f"{header_segment}.{payload_segment}".encode("utf-8")
            expected_signature = hmac.new(
                settings.jwt_secret_key.encode("utf-8"),
                signing_input,
                hashlib.sha256,
            ).digest()
            provided_signature = cls._b64url_decode(signature_segment)
            if not hmac.compare_digest(expected_signature, provided_signature):
                raise HTTPException(status_code=401, detail=messages.INVALID_ACCESS_TOKEN)

            header = json.loads(cls._b64url_decode(header_segment).decode("utf-8"))
            if header.get("alg") != cls._algorithm:
                raise HTTPException(status_code=401, detail=messages.INVALID_ACCESS_TOKEN)

            payload = json.loads(cls._b64url_decode(payload_segment).decode("utf-8"))
        except Exception as exc:
            if isinstance(exc, HTTPException):
                raise
            raise HTTPException(status_code=401, detail=messages.INVALID_ACCESS_TOKEN) from exc

        now = int(datetime.now(tz=timezone.utc).timestamp())
        if payload.get("type") != "access":
            raise HTTPException(status_code=401, detail=messages.INVALID_ACCESS_TOKEN)
        if int(payload.get("nbf", 0)) > now or int(payload.get("exp", 0)) <= now:
            raise HTTPException(status_code=401, detail=messages.INVALID_ACCESS_TOKEN)

        user_id = payload.get("sub")
        role = payload.get("role")
        if not user_id or role not in {"owner", "tenant"}:
            raise HTTPException(status_code=401, detail=messages.INVALID_ACCESS_TOKEN)
        return AuthUser(user_id=user_id, role=role)


bearer_scheme = HTTPBearer(auto_error=True)


def get_current_user(credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme)) -> AuthUser:
    return SecurityService.decode_access_token(credentials.credentials)


def enforce_user_scope(current_user: AuthUser, user_id: str, role: str | None = None) -> None:
    if current_user.user_id != user_id:
        raise HTTPException(status_code=403, detail=messages.AUTHORIZATION_DENIED)
    if role and current_user.role != role:
        raise HTTPException(status_code=403, detail=messages.AUTHORIZATION_DENIED)
