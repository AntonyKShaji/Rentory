from datetime import datetime
from typing import Literal

from pydantic import BaseModel, Field


class LoginRequest(BaseModel):
    identifier: str = Field(min_length=3)
    otp: str = Field(min_length=4)


class LoginResponse(BaseModel):
    access_token: str
    role: Literal["owner", "tenant"]
    user_id: str


class PropertyCreateRequest(BaseModel):
    location: str
    name: str
    unit_type: str
    capacity: int = Field(gt=0)


class PropertyResponse(BaseModel):
    id: str
    owner_id: str
    location: str
    name: str
    unit_type: str
    capacity: int
    occupied_count: int


class JoinRequestCreate(BaseModel):
    tenant_id: str


class JoinRequestResponse(BaseModel):
    id: str
    property_id: str
    tenant_id: str
    status: str
    created_at: datetime


class PaymentCreate(BaseModel):
    property_id: str
    tenant_id: str
    bill_type: Literal["rent", "electricity", "water"]
    amount: float = Field(gt=0)


class PaymentResponse(BaseModel):
    id: str
    property_id: str
    tenant_id: str
    bill_type: str
    amount: float
    paid_at: datetime


class BroadcastCreate(BaseModel):
    owner_id: str
    title: str
    body: str
    property_ids: list[str] = Field(default_factory=list)


class BroadcastResponse(BaseModel):
    queued: bool
    notification_ids: list[str]


class MaintenanceCreate(BaseModel):
    property_id: str
    tenant_id: str
    issue_title: str
    issue_description: str | None = None


class MaintenanceResponse(BaseModel):
    id: str
    property_id: str
    tenant_id: str
    issue_title: str
    issue_description: str | None
    status: str
    created_at: datetime
