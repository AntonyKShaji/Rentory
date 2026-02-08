from datetime import datetime
from uuid import uuid4

from fastapi import Depends, FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import select
from sqlalchemy.orm import Session

from .database import Base, engine, get_db
from .models import Bill, MaintenanceTicket, Notification, Payment, Property, PropertyTenant, User
from .schemas import (
    BroadcastCreate,
    BroadcastResponse,
    JoinRequestCreate,
    JoinRequestResponse,
    LoginRequest,
    LoginResponse,
    MaintenanceCreate,
    MaintenanceResponse,
    PaymentCreate,
    PaymentResponse,
    PropertyCreateRequest,
    PropertyResponse,
)

app = FastAPI(title="Rentory API", version="0.2.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.on_event("startup")
def startup() -> None:
    Base.metadata.create_all(bind=engine)


@app.get("/health")
def health() -> dict:
    return {"status": "ok", "service": "rentory-api", "db": "connected"}


@app.post("/auth/login", response_model=LoginResponse)
def login(payload: LoginRequest, db: Session = Depends(get_db)) -> LoginResponse:
    user = db.scalar(select(User).where((User.phone == payload.identifier) | (User.email == payload.identifier)))

    if user is None:
        role = "owner" if payload.identifier.startswith("owner") else "tenant"
        user = User(
            id=str(uuid4()),
            role=role,
            full_name=f"{role.title()} User",
            phone=payload.identifier,
            email=f"{payload.identifier}@rentory.local" if "@" not in payload.identifier else payload.identifier,
        )
        db.add(user)
        db.commit()
        db.refresh(user)

    return LoginResponse(access_token=f"demo-token-{uuid4()}", role=user.role, user_id=user.id)


@app.get("/owners/{owner_id}/properties", response_model=list[PropertyResponse])
def list_properties(owner_id: str, db: Session = Depends(get_db)) -> list[PropertyResponse]:
    owner = db.get(User, owner_id)
    if owner is None or owner.role != "owner":
        raise HTTPException(status_code=404, detail="Owner not found")

    rows = db.scalars(select(Property).where(Property.owner_id == owner_id)).all()
    return [
        PropertyResponse(
            id=row.id,
            owner_id=row.owner_id,
            location=row.location,
            name=row.name,
            unit_type=row.unit_type,
            capacity=row.capacity,
            occupied_count=row.occupied_count,
        )
        for row in rows
    ]


@app.post("/owners/{owner_id}/properties", response_model=PropertyResponse, status_code=201)
def create_property(owner_id: str, payload: PropertyCreateRequest, db: Session = Depends(get_db)) -> PropertyResponse:
    owner = db.get(User, owner_id)
    if owner is None or owner.role != "owner":
        raise HTTPException(status_code=404, detail="Owner not found")

    row = Property(
        id=str(uuid4()),
        owner_id=owner_id,
        location=payload.location,
        name=payload.name,
        unit_type=payload.unit_type,
        capacity=payload.capacity,
        occupied_count=0,
    )
    db.add(row)
    db.commit()
    db.refresh(row)

    return PropertyResponse(
        id=row.id,
        owner_id=row.owner_id,
        location=row.location,
        name=row.name,
        unit_type=row.unit_type,
        capacity=row.capacity,
        occupied_count=row.occupied_count,
    )


@app.get("/properties/{property_id}")
def get_property(property_id: str, db: Session = Depends(get_db)) -> dict:
    row = db.get(Property, property_id)
    if row is None:
        raise HTTPException(status_code=404, detail="Property not found")

    tenants = db.execute(
        select(PropertyTenant.id, PropertyTenant.tenant_id, PropertyTenant.status, User.full_name, User.phone)
        .join(User, User.id == PropertyTenant.tenant_id)
        .where(PropertyTenant.property_id == property_id)
    ).all()

    bills = db.scalars(select(Bill).where(Bill.property_id == property_id)).all()

    return {
        "property": {
            "id": row.id,
            "owner_id": row.owner_id,
            "location": row.location,
            "name": row.name,
            "unit_type": row.unit_type,
            "capacity": row.capacity,
            "occupied_count": row.occupied_count,
        },
        "tenants": [
            {
                "join_id": t.id,
                "tenant_id": t.tenant_id,
                "status": t.status,
                "full_name": t.full_name,
                "phone": t.phone,
            }
            for t in tenants
        ],
        "bills": [
            {
                "id": b.id,
                "tenant_id": b.tenant_id,
                "bill_type": b.bill_type,
                "amount": b.amount,
                "status": b.status,
                "created_at": b.created_at.isoformat(),
            }
            for b in bills
        ],
    }


@app.post("/properties/{property_id}/tenants/join-requests", response_model=JoinRequestResponse, status_code=201)
def request_join_property(property_id: str, payload: JoinRequestCreate, db: Session = Depends(get_db)) -> JoinRequestResponse:
    property_row = db.get(Property, property_id)
    if property_row is None:
        raise HTTPException(status_code=404, detail="Property not found")

    tenant = db.get(User, payload.tenant_id)
    if tenant is None:
        tenant = User(
            id=payload.tenant_id,
            role="tenant",
            full_name="Tenant User",
            phone=f"tenant-{payload.tenant_id}",
            email=f"{payload.tenant_id}@rentory.local",
        )
        db.add(tenant)

    row = PropertyTenant(
        id=str(uuid4()),
        property_id=property_id,
        tenant_id=payload.tenant_id,
        status="pending",
        created_at=datetime.utcnow(),
    )
    db.add(row)
    db.commit()
    db.refresh(row)

    return JoinRequestResponse(
        id=row.id,
        property_id=row.property_id,
        tenant_id=row.tenant_id,
        status=row.status,
        created_at=row.created_at,
    )


@app.post("/payments", response_model=PaymentResponse, status_code=201)
def create_payment(payload: PaymentCreate, db: Session = Depends(get_db)) -> PaymentResponse:
    if db.get(Property, payload.property_id) is None:
        raise HTTPException(status_code=404, detail="Property not found")

    tenant = db.get(User, payload.tenant_id)
    if tenant is None:
        tenant = User(
            id=payload.tenant_id,
            role="tenant",
            full_name="Tenant User",
            phone=f"tenant-{payload.tenant_id}",
            email=f"{payload.tenant_id}@rentory.local",
        )
        db.add(tenant)

    payment = Payment(
        id=str(uuid4()),
        property_id=payload.property_id,
        tenant_id=payload.tenant_id,
        bill_type=payload.bill_type,
        amount=payload.amount,
    )
    bill = Bill(
        id=str(uuid4()),
        property_id=payload.property_id,
        tenant_id=payload.tenant_id,
        bill_type=payload.bill_type,
        amount=payload.amount,
        status="paid",
    )
    db.add(payment)
    db.add(bill)
    db.commit()
    db.refresh(payment)

    return PaymentResponse(
        id=payment.id,
        property_id=payment.property_id,
        tenant_id=payment.tenant_id,
        bill_type=payment.bill_type,
        amount=payment.amount,
        paid_at=payment.paid_at,
    )


@app.post("/notifications/broadcast", response_model=BroadcastResponse, status_code=202)
def broadcast(payload: BroadcastCreate, db: Session = Depends(get_db)) -> BroadcastResponse:
    owner = db.get(User, payload.owner_id)
    if owner is None or owner.role != "owner":
        raise HTTPException(status_code=404, detail="Owner not found")

    target_property_ids = payload.property_ids
    if not target_property_ids:
        target_property_ids = [p.id for p in db.scalars(select(Property).where(Property.owner_id == payload.owner_id)).all()]

    created_ids: list[str] = []
    for property_id in target_property_ids:
        notification = Notification(
            id=str(uuid4()),
            owner_id=payload.owner_id,
            property_id=property_id,
            title=payload.title,
            body=payload.body,
        )
        db.add(notification)
        created_ids.append(notification.id)

    db.commit()
    return BroadcastResponse(queued=True, notification_ids=created_ids)


@app.post("/maintenance-tickets", response_model=MaintenanceResponse, status_code=201)
def create_maintenance(payload: MaintenanceCreate, db: Session = Depends(get_db)) -> MaintenanceResponse:
    if db.get(Property, payload.property_id) is None:
        raise HTTPException(status_code=404, detail="Property not found")

    tenant = db.get(User, payload.tenant_id)
    if tenant is None:
        tenant = User(
            id=payload.tenant_id,
            role="tenant",
            full_name="Tenant User",
            phone=f"tenant-{payload.tenant_id}",
            email=f"{payload.tenant_id}@rentory.local",
        )
        db.add(tenant)

    row = MaintenanceTicket(
        id=str(uuid4()),
        property_id=payload.property_id,
        tenant_id=payload.tenant_id,
        issue_title=payload.issue_title,
        issue_description=payload.issue_description,
        status="open",
    )
    db.add(row)
    db.commit()
    db.refresh(row)

    return MaintenanceResponse(
        id=row.id,
        property_id=row.property_id,
        tenant_id=row.tenant_id,
        issue_title=row.issue_title,
        issue_description=row.issue_description,
        status=row.status,
        created_at=row.created_at,
    )
