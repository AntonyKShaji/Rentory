from datetime import datetime
from typing import Literal

from pydantic import BaseModel, Field


class LoginRequest(BaseModel):
    identifier: str = Field(min_length=3)
    password: str = Field(min_length=4)
    role: Literal["owner", "tenant"]


class LoginResponse(BaseModel):
    access_token: str
    role: Literal["owner", "tenant"]
    user_id: str


class OwnerSignupRequest(BaseModel):
    full_name: str
    phone: str
    email: str | None = None
    password: str = Field(min_length=4)


class TenantRegistrationRequest(BaseModel):
    qr_code: str
    full_name: str
    age: int = Field(gt=0)
    phone: str
    email: str | None = None
    documents: str
    password: str = Field(min_length=4)


class PropertyCreateRequest(BaseModel):
    location: str
    name: str
    unit_type: str
    capacity: int = Field(gt=0)
    rent: float = Field(gt=0)
    image_url: str
    description: str | None = None


class PropertyCardResponse(BaseModel):
    id: str
    owner_id: str
    location: str
    name: str
    unit_type: str
    capacity: int
    occupied_count: int
    rent: float
    image_url: str | None
    qr_code: str
    qr_code_url: str


class OwnerAnalyticsResponse(BaseModel):
    grouped_by_place: dict[str, int]
    total_properties: int
    total_tenants: int


class TenantSummaryResponse(BaseModel):
    join_id: str
    tenant_id: str
    status: str
    full_name: str
    phone: str


class PropertyDetailsResponse(BaseModel):
    property: PropertyCardResponse
    description: str | None
    current_bill_amount: float
    water_bill_status: str
    owner_phone: str
    chat_group_name: str
    tenants: list[TenantSummaryResponse]


class TenantDetailsResponse(BaseModel):
    id: str
    full_name: str
    age: int | None
    phone: str
    email: str | None
    documents: str | None


class WaterBillStatusUpdateRequest(BaseModel):
    status: Literal["paid", "unpaid"]


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


class ChatMessageCreate(BaseModel):
    sender_id: str
    text: str | None = None
    image_url: str | None = None


class ChatMessageResponse(BaseModel):
    id: str
    group_id: str
    sender_id: str
    sender_name: str
    text: str | None
    image_url: str | None
    created_at: datetime


class TenantDashboardResponse(BaseModel):
    property: PropertyCardResponse
    owner_phone: str
    rent: float
