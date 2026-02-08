from datetime import datetime
from typing import Dict, List, Literal, Optional
from uuid import uuid4

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel, Field

app = FastAPI(title="Rentory API", version="0.1.0")


class LoginRequest(BaseModel):
    identifier: str = Field(min_length=3)
    otp: str = Field(min_length=4)


class LoginResponse(BaseModel):
    access_token: str
    role: Literal["owner", "tenant"]


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


class PaymentCreate(BaseModel):
    property_id: str
    tenant_id: str
    bill_type: Literal["rent", "electricity", "water"]
    amount: float = Field(gt=0)


class BroadcastCreate(BaseModel):
    owner_id: str
    title: str
    body: str
    property_ids: List[str] = Field(default_factory=list)


class MaintenanceCreate(BaseModel):
    property_id: str
    tenant_id: str
    issue_title: str
    issue_description: Optional[str] = None


owners: Dict[str, dict] = {
    "owner-1": {"id": "owner-1", "name": "Demo Owner"},
}
properties_by_owner: Dict[str, List[dict]] = {"owner-1": []}
join_requests: List[dict] = []
payments: List[dict] = []
notifications: List[dict] = []
maintenance_tickets: List[dict] = []


@app.get("/health")
def health() -> dict:
    return {"status": "ok", "service": "rentory-api"}


@app.post("/auth/login", response_model=LoginResponse)
def login(payload: LoginRequest) -> LoginResponse:
    role: Literal["owner", "tenant"] = "owner" if payload.identifier.startswith("owner") else "tenant"
    return LoginResponse(access_token=f"demo-token-{uuid4()}", role=role)


@app.get("/owners/{owner_id}/properties", response_model=List[PropertyResponse])
def list_properties(owner_id: str) -> List[PropertyResponse]:
    if owner_id not in owners:
        raise HTTPException(status_code=404, detail="Owner not found")
    return [PropertyResponse(**item) for item in properties_by_owner.get(owner_id, [])]


@app.post("/owners/{owner_id}/properties", response_model=PropertyResponse, status_code=201)
def create_property(owner_id: str, payload: PropertyCreateRequest) -> PropertyResponse:
    if owner_id not in owners:
        raise HTTPException(status_code=404, detail="Owner not found")

    item = {
        "id": str(uuid4()),
        "owner_id": owner_id,
        "location": payload.location,
        "name": payload.name,
        "unit_type": payload.unit_type,
        "capacity": payload.capacity,
        "occupied_count": 0,
    }
    properties_by_owner.setdefault(owner_id, []).append(item)
    return PropertyResponse(**item)


@app.get("/properties/{property_id}")
def get_property(property_id: str) -> dict:
    for owner_properties in properties_by_owner.values():
        for item in owner_properties:
            if item["id"] == property_id:
                return {
                    "property": item,
                    "tenants": [
                        req for req in join_requests if req["property_id"] == property_id and req["status"] == "active"
                    ],
                    "bills": [pay for pay in payments if pay["property_id"] == property_id],
                }
    raise HTTPException(status_code=404, detail="Property not found")


@app.post("/properties/{property_id}/tenants/join-requests", status_code=201)
def request_join_property(property_id: str, payload: JoinRequestCreate) -> dict:
    request = {
        "id": str(uuid4()),
        "property_id": property_id,
        "tenant_id": payload.tenant_id,
        "status": "pending",
        "created_at": datetime.utcnow().isoformat(),
    }
    join_requests.append(request)
    return request


@app.post("/payments", status_code=201)
def create_payment(payload: PaymentCreate) -> dict:
    payment = {
        "id": str(uuid4()),
        "property_id": payload.property_id,
        "tenant_id": payload.tenant_id,
        "bill_type": payload.bill_type,
        "amount": payload.amount,
        "paid_at": datetime.utcnow().isoformat(),
    }
    payments.append(payment)
    return payment


@app.post("/notifications/broadcast", status_code=202)
def broadcast(payload: BroadcastCreate) -> dict:
    item = {
        "id": str(uuid4()),
        "owner_id": payload.owner_id,
        "title": payload.title,
        "body": payload.body,
        "property_ids": payload.property_ids,
        "created_at": datetime.utcnow().isoformat(),
    }
    notifications.append(item)
    return {"queued": True, "notification_id": item["id"]}


@app.post("/maintenance-tickets", status_code=201)
def create_maintenance(payload: MaintenanceCreate) -> dict:
    ticket = {
        "id": str(uuid4()),
        "property_id": payload.property_id,
        "tenant_id": payload.tenant_id,
        "issue_title": payload.issue_title,
        "issue_description": payload.issue_description,
        "status": "open",
        "created_at": datetime.utcnow().isoformat(),
    }
    maintenance_tickets.append(ticket)
    return ticket
