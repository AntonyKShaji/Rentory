from datetime import datetime
from urllib.parse import quote
from uuid import uuid4

from fastapi import Depends, FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import func, select, text as sql_text
from sqlalchemy.orm import Session

from .database import Base, engine, get_db
from .models import (
    Bill,
    ChatGroup,
    ChatGroupMember,
    ChatMessage,
    MaintenanceTicket,
    Notification,
    Payment,
    Property,
    PropertyTenant,
    User,
)
from .schemas import (
    BroadcastCreate,
    BroadcastResponse,
    ChatMessageCreate,
    ChatMessageResponse,
    JoinRequestCreate,
    JoinRequestResponse,
    LoginRequest,
    LoginResponse,
    MaintenanceCreate,
    MaintenanceResponse,
    OwnerAnalyticsResponse,
    OwnerSignupRequest,
    PaymentCreate,
    PaymentResponse,
    PropertyCardResponse,
    PropertyCreateRequest,
    PropertyDetailsResponse,
    TenantDashboardResponse,
    TenantDetailsResponse,
    TenantRegistrationRequest,
    TenantSummaryResponse,
    WaterBillStatusUpdateRequest,
)

app = FastAPI(title="Rentory API", version="1.1.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


def _hash_password(password: str) -> str:
    return f"plain::{password}"


def _qr_code_url(qr_code: str) -> str:
    return f"https://api.qrserver.com/v1/create-qr-code/?size=220x220&data={quote(qr_code)}"


def _property_card(row: Property) -> PropertyCardResponse:
    return PropertyCardResponse(
        id=row.id,
        owner_id=row.owner_id,
        location=row.location,
        name=row.name,
        unit_type=row.unit_type,
        capacity=row.capacity,
        occupied_count=row.occupied_count,
        rent=row.rent,
        image_url=row.image_url,
        qr_code=row.qr_code,
        qr_code_url=_qr_code_url(row.qr_code),
    )


def _ensure_chat_membership(db: Session, group_id: str, user_id: str, role: str) -> None:
    existing = db.scalar(select(ChatGroupMember).where(ChatGroupMember.group_id == group_id, ChatGroupMember.user_id == user_id))
    if existing is None:
        db.add(ChatGroupMember(id=str(uuid4()), group_id=group_id, user_id=user_id, role=role))


@app.on_event("startup")
def startup() -> None:
    Base.metadata.create_all(bind=engine)
    _widen_legacy_image_columns()


def _widen_legacy_image_columns() -> None:
    """Upgrade old Postgres schemas that still use VARCHAR(500) for image URLs."""
    with engine.begin() as connection:
        if connection.dialect.name != "postgresql":
            return

        connection.execute(sql_text("ALTER TABLE IF EXISTS properties ALTER COLUMN image_url TYPE TEXT"))
        connection.execute(sql_text("ALTER TABLE IF EXISTS chat_messages ALTER COLUMN image_url TYPE TEXT"))


@app.get("/health")
def health() -> dict:
    return {"status": "ok", "service": "rentory-api", "db": "connected"}


@app.post("/auth/owners/signup", response_model=LoginResponse, status_code=201)
def owner_signup(payload: OwnerSignupRequest, db: Session = Depends(get_db)) -> LoginResponse:
    existing_user = db.scalar(select(User).where(User.phone == payload.phone))
    if existing_user is not None:
        raise HTTPException(status_code=409, detail="Phone already registered")

    user = User(
        id=str(uuid4()),
        role="owner",
        full_name=payload.full_name,
        phone=payload.phone,
        email=payload.email,
        password_hash=_hash_password(payload.password),
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return LoginResponse(access_token=f"demo-token-{uuid4()}", role="owner", user_id=user.id)


@app.post("/auth/tenants/register", response_model=LoginResponse, status_code=201)
def tenant_register(payload: TenantRegistrationRequest, db: Session = Depends(get_db)) -> LoginResponse:
    property_row = db.scalar(select(Property).where(Property.qr_code == payload.qr_code))
    if property_row is None:
        raise HTTPException(status_code=404, detail="Invalid QR code")

    if property_row.occupied_count >= property_row.capacity:
        raise HTTPException(status_code=409, detail="Property is full")

    existing_user = db.scalar(select(User).where(User.phone == payload.phone))
    if existing_user is not None:
        raise HTTPException(status_code=409, detail="Phone already registered")

    tenant = User(
        id=str(uuid4()),
        role="tenant",
        full_name=payload.full_name,
        age=payload.age,
        phone=payload.phone,
        email=payload.email,
        documents=payload.documents,
        assigned_property_id=property_row.id,
        password_hash=_hash_password(payload.password),
    )
    db.add(tenant)
    db.flush()

    link = PropertyTenant(
        id=str(uuid4()),
        property_id=property_row.id,
        tenant_id=tenant.id,
        status="active",
        created_at=datetime.utcnow(),
    )
    property_row.occupied_count += 1
    db.add(link)

    group = db.scalar(select(ChatGroup).where(ChatGroup.property_id == property_row.id))
    if group is not None:
        _ensure_chat_membership(db, group.id, tenant.id, "tenant")

    db.commit()
    return LoginResponse(access_token=f"demo-token-{uuid4()}", role="tenant", user_id=tenant.id)


@app.post("/auth/login", response_model=LoginResponse)
def login(payload: LoginRequest, db: Session = Depends(get_db)) -> LoginResponse:
    user = db.scalar(select(User).where((User.phone == payload.identifier) | (User.email == payload.identifier)))
    if user is None:
        raise HTTPException(status_code=401, detail="Invalid credentials")

    if user.role != payload.role:
        raise HTTPException(status_code=401, detail="Role mismatch")

    if user.password_hash != _hash_password(payload.password):
        raise HTTPException(status_code=401, detail="Invalid credentials")

    return LoginResponse(access_token=f"demo-token-{uuid4()}", role=user.role, user_id=user.id)


@app.get("/owners/{owner_id}/properties", response_model=list[PropertyCardResponse])
def list_properties(owner_id: str, db: Session = Depends(get_db)) -> list[PropertyCardResponse]:
    owner = db.get(User, owner_id)
    if owner is None or owner.role != "owner":
        raise HTTPException(status_code=404, detail="Owner not found")

    rows = db.scalars(select(Property).where(Property.owner_id == owner_id)).all()
    return [_property_card(row) for row in rows]


@app.get("/owners/{owner_id}/analytics", response_model=OwnerAnalyticsResponse)
def owner_analytics(owner_id: str, db: Session = Depends(get_db)) -> OwnerAnalyticsResponse:
    owner = db.get(User, owner_id)
    if owner is None or owner.role != "owner":
        raise HTTPException(status_code=404, detail="Owner not found")

    grouped_rows = db.execute(
        select(Property.location, func.count(Property.id)).where(Property.owner_id == owner_id).group_by(Property.location)
    ).all()
    total_tenants = db.scalar(
        select(func.count(PropertyTenant.id))
        .join(Property, Property.id == PropertyTenant.property_id)
        .where(Property.owner_id == owner_id)
        .where(PropertyTenant.status == "active")
    )

    grouped = {location: count for location, count in grouped_rows}
    return OwnerAnalyticsResponse(
        grouped_by_place=grouped,
        total_properties=sum(grouped.values()),
        total_tenants=total_tenants or 0,
    )


@app.post("/owners/{owner_id}/properties", response_model=PropertyCardResponse, status_code=201)
def create_property(owner_id: str, payload: PropertyCreateRequest, db: Session = Depends(get_db)) -> PropertyCardResponse:
    owner = db.get(User, owner_id)
    if owner is None or owner.role != "owner":
        raise HTTPException(status_code=404, detail="Owner not found")

    property_row = Property(
        id=str(uuid4()),
        owner_id=owner_id,
        location=payload.location,
        name=payload.name,
        unit_type=payload.unit_type,
        description=payload.description,
        image_url=payload.image_url,
        qr_code=f"QR-{uuid4().hex[:10]}",
        capacity=payload.capacity,
        occupied_count=0,
        rent=payload.rent,
        current_bill_amount=payload.rent,
        water_bill_status="unpaid",
    )
    db.add(property_row)
    db.flush()

    chat_group = ChatGroup(
        id=str(uuid4()),
        property_id=property_row.id,
        group_name=property_row.name,
    )
    db.add(chat_group)
    db.flush()
    _ensure_chat_membership(db, chat_group.id, owner_id, "owner")

    db.commit()
    db.refresh(property_row)
    return _property_card(property_row)


@app.get("/properties/{property_id}", response_model=PropertyDetailsResponse)
def get_property(property_id: str, db: Session = Depends(get_db)) -> PropertyDetailsResponse:
    row = db.get(Property, property_id)
    if row is None:
        raise HTTPException(status_code=404, detail="Property not found")

    owner = db.get(User, row.owner_id)
    chat_group = db.scalar(select(ChatGroup).where(ChatGroup.property_id == property_id))
    tenants = db.execute(
        select(PropertyTenant.id, PropertyTenant.tenant_id, PropertyTenant.status, User.full_name, User.phone)
        .join(User, User.id == PropertyTenant.tenant_id)
        .where(PropertyTenant.property_id == property_id)
    ).all()

    return PropertyDetailsResponse(
        property=_property_card(row),
        description=row.description,
        current_bill_amount=row.current_bill_amount,
        water_bill_status=row.water_bill_status,
        owner_phone=owner.phone if owner else "",
        chat_group_name=chat_group.group_name if chat_group else row.name,
        tenants=[
            TenantSummaryResponse(
                join_id=t.id,
                tenant_id=t.tenant_id,
                status=t.status,
                full_name=t.full_name,
                phone=t.phone,
            )
            for t in tenants
        ],
    )


@app.patch("/properties/{property_id}/water-bill")
def update_water_bill_status(property_id: str, payload: WaterBillStatusUpdateRequest, db: Session = Depends(get_db)) -> dict:
    row = db.get(Property, property_id)
    if row is None:
        raise HTTPException(status_code=404, detail="Property not found")

    row.water_bill_status = payload.status
    db.commit()
    return {"property_id": property_id, "water_bill_status": payload.status}


@app.get("/tenants/{tenant_id}", response_model=TenantDetailsResponse)
def get_tenant(tenant_id: str, db: Session = Depends(get_db)) -> TenantDetailsResponse:
    tenant = db.get(User, tenant_id)
    if tenant is None or tenant.role != "tenant":
        raise HTTPException(status_code=404, detail="Tenant not found")

    return TenantDetailsResponse(
        id=tenant.id,
        full_name=tenant.full_name,
        age=tenant.age,
        phone=tenant.phone,
        email=tenant.email,
        documents=tenant.documents,
    )


@app.get("/tenants/{tenant_id}/dashboard", response_model=TenantDashboardResponse)
def tenant_dashboard(tenant_id: str, db: Session = Depends(get_db)) -> TenantDashboardResponse:
    tenant = db.get(User, tenant_id)
    if tenant is None or tenant.role != "tenant":
        raise HTTPException(status_code=404, detail="Tenant not found")

    if tenant.assigned_property_id is None:
        raise HTTPException(status_code=404, detail="Tenant has no property assigned")

    property_row = db.get(Property, tenant.assigned_property_id)
    if property_row is None:
        raise HTTPException(status_code=404, detail="Property not found")

    owner = db.get(User, property_row.owner_id)
    return TenantDashboardResponse(
        property=_property_card(property_row),
        owner_phone=owner.phone if owner else "",
        rent=property_row.rent,
    )


@app.get("/properties/{property_id}/chat", response_model=list[ChatMessageResponse])
def list_chat_messages(property_id: str, db: Session = Depends(get_db)) -> list[ChatMessageResponse]:
    group = db.scalar(select(ChatGroup).where(ChatGroup.property_id == property_id))
    if group is None:
        raise HTTPException(status_code=404, detail="Chat group not found")

    rows = db.scalars(select(ChatMessage).where(ChatMessage.group_id == group.id).order_by(ChatMessage.created_at)).all()
    return [
        ChatMessageResponse(
            id=row.id,
            group_id=row.group_id,
            sender_id=row.sender_id,
            sender_name=row.sender_name,
            text=row.text,
            image_url=row.image_url,
            created_at=row.created_at,
        )
        for row in rows
    ]


@app.post("/properties/{property_id}/chat", response_model=ChatMessageResponse, status_code=201)
def post_chat_message(property_id: str, payload: ChatMessageCreate, db: Session = Depends(get_db)) -> ChatMessageResponse:
    group = db.scalar(select(ChatGroup).where(ChatGroup.property_id == property_id))
    if group is None:
        raise HTTPException(status_code=404, detail="Chat group not found")

    sender = db.get(User, payload.sender_id)
    if sender is None:
        raise HTTPException(status_code=404, detail="Sender not found")

    membership = db.scalar(
        select(ChatGroupMember).where(ChatGroupMember.group_id == group.id, ChatGroupMember.user_id == sender.id)
    )
    if membership is None:
        raise HTTPException(status_code=403, detail="Sender is not a member of this group")

    if not payload.text and not payload.image_url:
        raise HTTPException(status_code=422, detail="Message text or image is required")

    row = ChatMessage(
        id=str(uuid4()),
        group_id=group.id,
        sender_id=sender.id,
        sender_name=sender.full_name,
        text=payload.text,
        image_url=payload.image_url,
    )
    db.add(row)
    db.commit()
    db.refresh(row)

    return ChatMessageResponse(
        id=row.id,
        group_id=row.group_id,
        sender_id=row.sender_id,
        sender_name=row.sender_name,
        text=row.text,
        image_url=row.image_url,
        created_at=row.created_at,
    )


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
            password_hash=_hash_password("demo"),
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
            password_hash=_hash_password("demo"),
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
            password_hash=_hash_password("demo"),
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
