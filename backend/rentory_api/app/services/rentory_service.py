from datetime import datetime
from urllib.parse import quote
from uuid import uuid4

from fastapi import HTTPException
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core import messages
from app.core.security import SecurityService
from app.models import (
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
from app.schemas import (
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
    NotificationListResponse,
    NotificationMarkReadResponse,
    NotificationResponse,
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


class RentoryService:

    @staticmethod
    def qr_code_url(qr_code: str) -> str:
        return f"https://api.qrserver.com/v1/create-qr-code/?size=220x220&data={quote(qr_code)}"

    @classmethod
    def property_card(cls, row: Property, unread_notifications: int = 0) -> PropertyCardResponse:
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
            qr_code_url=cls.qr_code_url(row.qr_code),
            is_active=row.is_active,
            unread_notifications=unread_notifications,
        )

    @staticmethod
    def ensure_chat_membership(db: Session, group_id: str, user_id: str, role: str) -> None:
        existing = db.scalar(select(ChatGroupMember).where(ChatGroupMember.group_id == group_id, ChatGroupMember.user_id == user_id))
        if existing is None:
            db.add(ChatGroupMember(id=str(uuid4()), group_id=group_id, user_id=user_id, role=role))

    def owner_signup(self, payload: OwnerSignupRequest, db: Session) -> LoginResponse:
        if db.scalar(select(User).where(User.phone == payload.phone)) is not None:
            raise HTTPException(status_code=409, detail=messages.PHONE_ALREADY_REGISTERED)

        user = User(
            id=str(uuid4()),
            role="owner",
            full_name=payload.full_name,
            phone=payload.phone,
            email=payload.email,
            password_hash=SecurityService.hash_password(payload.password),
        )
        db.add(user)
        db.commit()
        db.refresh(user)
        return LoginResponse(access_token=SecurityService.create_access_token(user.id, "owner"), role="owner", user_id=user.id)

    def tenant_register(self, payload: TenantRegistrationRequest, db: Session) -> LoginResponse:
        property_row = db.scalar(select(Property).where(Property.qr_code == payload.qr_code))
        if property_row is None:
            raise HTTPException(status_code=404, detail=messages.INVALID_QR_CODE)
        if property_row.occupied_count >= property_row.capacity:
            raise HTTPException(status_code=409, detail=messages.PROPERTY_FULL)
        if db.scalar(select(User).where(User.phone == payload.phone)) is not None:
            raise HTTPException(status_code=409, detail=messages.PHONE_ALREADY_REGISTERED)

        tenant = User(
            id=str(uuid4()),
            role="tenant",
            full_name=payload.full_name,
            age=payload.age,
            phone=payload.phone,
            email=payload.email,
            documents=payload.documents,
            assigned_property_id=property_row.id,
            password_hash=SecurityService.hash_password(payload.password),
        )
        db.add(tenant)
        db.flush()

        db.add(
            PropertyTenant(
                id=str(uuid4()),
                property_id=property_row.id,
                tenant_id=tenant.id,
                status="active",
                created_at=datetime.utcnow(),
            )
        )
        property_row.occupied_count += 1

        group = db.scalar(select(ChatGroup).where(ChatGroup.property_id == property_row.id))
        if group is not None:
            self.ensure_chat_membership(db, group.id, tenant.id, "tenant")

        db.commit()
        return LoginResponse(access_token=SecurityService.create_access_token(tenant.id, "tenant"), role="tenant", user_id=tenant.id)

    def login(self, payload: LoginRequest, db: Session) -> LoginResponse:
        user = db.scalar(select(User).where((User.phone == payload.identifier) | (User.email == payload.identifier)))
        if user is None:
            raise HTTPException(status_code=401, detail=messages.INVALID_CREDENTIALS)
        if user.role != payload.role:
            raise HTTPException(status_code=401, detail=messages.ROLE_MISMATCH)
        if not SecurityService.verify_password(payload.password, user.password_hash):
            raise HTTPException(status_code=401, detail=messages.INVALID_CREDENTIALS)

        if user.password_hash and user.password_hash.startswith("plain::"):
            user.password_hash = SecurityService.hash_password(payload.password)
            db.commit()

        return LoginResponse(access_token=SecurityService.create_access_token(user.id, user.role), role=user.role, user_id=user.id)

    def list_properties(self, owner_id: str, db: Session) -> list[PropertyCardResponse]:
        owner = db.get(User, owner_id)
        if owner is None or owner.role != "owner":
            raise HTTPException(status_code=404, detail=messages.OWNER_NOT_FOUND)
        rows = db.scalars(select(Property).where(Property.owner_id == owner_id)).all()
        if not rows:
            return []

        notification_counts = {
            property_id: count
            for property_id, count in db.execute(
                select(Notification.property_id, func.count(Notification.id))
                .where(Notification.owner_id == owner_id)
                .where(Notification.property_id.is_not(None))
                .where(Notification.is_read.is_(False))
                .group_by(Notification.property_id)
            ).all()
        }
        return [self.property_card(row, unread_notifications=notification_counts.get(row.id, 0)) for row in rows]

    def owner_analytics(self, owner_id: str, db: Session) -> OwnerAnalyticsResponse:
        owner = db.get(User, owner_id)
        if owner is None or owner.role != "owner":
            raise HTTPException(status_code=404, detail=messages.OWNER_NOT_FOUND)

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

    def create_property(self, owner_id: str, payload: PropertyCreateRequest, db: Session) -> PropertyCardResponse:
        owner = db.get(User, owner_id)
        if owner is None or owner.role != "owner":
            raise HTTPException(status_code=404, detail=messages.OWNER_NOT_FOUND)

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
            is_active=payload.is_active,
            area_sqft=payload.area_sqft,
            parking_details=payload.parking_details,
            preferred_residents=payload.preferred_residents,
            advance_amount=payload.advance_amount,
            full_address=payload.full_address,
            caretaker_enabled=payload.caretaker_enabled,
            caretaker_name=payload.caretaker_name,
            caretaker_contact=payload.caretaker_contact,
            property_reference=payload.property_reference,
        )
        db.add(property_row)
        db.flush()

        chat_group = ChatGroup(id=str(uuid4()), property_id=property_row.id, group_name=property_row.name)
        db.add(chat_group)
        db.flush()
        self.ensure_chat_membership(db, chat_group.id, owner_id, "owner")

        db.commit()
        db.refresh(property_row)
        return self.property_card(property_row)

    def get_property(self, property_id: str, db: Session) -> PropertyDetailsResponse:
        row = db.get(Property, property_id)
        if row is None:
            raise HTTPException(status_code=404, detail=messages.PROPERTY_NOT_FOUND)

        owner = db.get(User, row.owner_id)
        chat_group = db.scalar(select(ChatGroup).where(ChatGroup.property_id == property_id))
        tenants = db.execute(
            select(PropertyTenant.id, PropertyTenant.tenant_id, PropertyTenant.status, User.full_name, User.phone)
            .join(User, User.id == PropertyTenant.tenant_id)
            .where(PropertyTenant.property_id == property_id)
        ).all()

        unread_notifications = db.scalar(
            select(func.count(Notification.id)).where(Notification.owner_id == row.owner_id, Notification.property_id == property_id, Notification.is_read.is_(False))
        )

        return PropertyDetailsResponse(
            property=self.property_card(row, unread_notifications=unread_notifications or 0),
            description=row.description,
            current_bill_amount=row.current_bill_amount,
            water_bill_status=row.water_bill_status,
            owner_phone=owner.phone if owner else "",
            chat_group_name=chat_group.group_name if chat_group else row.name,
            area_sqft=row.area_sqft,
            parking_details=row.parking_details,
            preferred_residents=row.preferred_residents,
            advance_amount=row.advance_amount,
            full_address=row.full_address,
            caretaker_enabled=row.caretaker_enabled,
            caretaker_name=row.caretaker_name,
            caretaker_contact=row.caretaker_contact,
            property_reference=row.property_reference,
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

    def update_water_bill_status(self, property_id: str, payload: WaterBillStatusUpdateRequest, db: Session) -> dict:
        row = db.get(Property, property_id)
        if row is None:
            raise HTTPException(status_code=404, detail=messages.PROPERTY_NOT_FOUND)
        row.water_bill_status = payload.status
        db.commit()
        return {"property_id": property_id, "water_bill_status": payload.status}

    def get_tenant(self, tenant_id: str, db: Session) -> TenantDetailsResponse:
        tenant = db.get(User, tenant_id)
        if tenant is None or tenant.role != "tenant":
            raise HTTPException(status_code=404, detail=messages.TENANT_NOT_FOUND)
        return TenantDetailsResponse(
            id=tenant.id,
            full_name=tenant.full_name,
            age=tenant.age,
            phone=tenant.phone,
            email=tenant.email,
            documents=tenant.documents,
        )

    def tenant_dashboard(self, tenant_id: str, db: Session) -> TenantDashboardResponse:
        tenant = db.get(User, tenant_id)
        if tenant is None or tenant.role != "tenant":
            raise HTTPException(status_code=404, detail=messages.TENANT_NOT_FOUND)
        if tenant.assigned_property_id is None:
            raise HTTPException(status_code=404, detail=messages.TENANT_HAS_NO_PROPERTY)

        property_row = db.get(Property, tenant.assigned_property_id)
        if property_row is None:
            raise HTTPException(status_code=404, detail=messages.PROPERTY_NOT_FOUND)

        owner = db.get(User, property_row.owner_id)
        return TenantDashboardResponse(
            property=self.property_card(property_row),
            owner_phone=owner.phone if owner else "",
            rent=property_row.rent,
        )

    def list_chat_messages(self, property_id: str, db: Session) -> list[ChatMessageResponse]:
        group = db.scalar(select(ChatGroup).where(ChatGroup.property_id == property_id))
        if group is None:
            raise HTTPException(status_code=404, detail=messages.CHAT_GROUP_NOT_FOUND)

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

    def post_chat_message(self, property_id: str, payload: ChatMessageCreate, db: Session) -> ChatMessageResponse:
        group = db.scalar(select(ChatGroup).where(ChatGroup.property_id == property_id))
        if group is None:
            raise HTTPException(status_code=404, detail=messages.CHAT_GROUP_NOT_FOUND)

        sender = db.get(User, payload.sender_id)
        if sender is None:
            raise HTTPException(status_code=404, detail=messages.SENDER_NOT_FOUND)

        membership = db.scalar(select(ChatGroupMember).where(ChatGroupMember.group_id == group.id, ChatGroupMember.user_id == sender.id))
        if membership is None:
            raise HTTPException(status_code=403, detail=messages.SENDER_NOT_GROUP_MEMBER)

        if not payload.text and not payload.image_url:
            raise HTTPException(status_code=422, detail=messages.MESSAGE_CONTENT_REQUIRED)

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

    def request_join_property(self, property_id: str, payload: JoinRequestCreate, db: Session) -> JoinRequestResponse:
        if db.get(Property, property_id) is None:
            raise HTTPException(status_code=404, detail=messages.PROPERTY_NOT_FOUND)
        tenant = db.get(User, payload.tenant_id)
        if tenant is None:
            db.add(
                User(
                    id=payload.tenant_id,
                    role="tenant",
                    full_name="Tenant User",
                    phone=f"tenant-{payload.tenant_id}",
                    email=f"{payload.tenant_id}@rentory.local",
                    password_hash=self.hash_password("demo"),
                )
            )

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

    def create_payment(self, payload: PaymentCreate, db: Session) -> PaymentResponse:
        if db.get(Property, payload.property_id) is None:
            raise HTTPException(status_code=404, detail=messages.PROPERTY_NOT_FOUND)
        tenant = db.get(User, payload.tenant_id)
        if tenant is None:
            db.add(
                User(
                    id=payload.tenant_id,
                    role="tenant",
                    full_name="Tenant User",
                    phone=f"tenant-{payload.tenant_id}",
                    email=f"{payload.tenant_id}@rentory.local",
                    password_hash=self.hash_password("demo"),
                )
            )

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

    def broadcast(self, payload: BroadcastCreate, db: Session) -> BroadcastResponse:
        owner = db.get(User, payload.owner_id)
        if owner is None or owner.role != "owner":
            raise HTTPException(status_code=404, detail=messages.OWNER_NOT_FOUND)

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
                category=payload.category,
            )
            db.add(notification)
            created_ids.append(notification.id)

        db.commit()
        return BroadcastResponse(queued=True, notification_ids=created_ids)

    @staticmethod
    def notification_item(row: Notification) -> NotificationResponse:
        return NotificationResponse(
            id=row.id,
            owner_id=row.owner_id,
            property_id=row.property_id,
            title=row.title,
            body=row.body,
            category=row.category,
            is_read=row.is_read,
            read_at=row.read_at,
            created_at=row.created_at,
        )

    def list_notifications(
        self,
        owner_id: str,
        db: Session,
        property_id: str | None = None,
        category: str | None = None,
        search: str | None = None,
    ) -> NotificationListResponse:
        owner = db.get(User, owner_id)
        if owner is None or owner.role != "owner":
            raise HTTPException(status_code=404, detail=messages.OWNER_NOT_FOUND)

        query = select(Notification).where(Notification.owner_id == owner_id)
        if property_id:
            query = query.where(Notification.property_id == property_id)
        if category and category != "all":
            query = query.where(Notification.category == category)
        if search:
            like_term = f"%{search.strip()}%"
            query = query.where((Notification.title.ilike(like_term)) | (Notification.body.ilike(like_term)))

        rows = db.scalars(query.order_by(Notification.created_at.desc())).all()
        unread_count = db.scalar(
            select(func.count(Notification.id)).where(Notification.owner_id == owner_id, Notification.is_read.is_(False))
        )
        return NotificationListResponse(
            items=[self.notification_item(row) for row in rows],
            unread_count=unread_count or 0,
        )

    def mark_notifications_read(self, owner_id: str, db: Session, property_id: str | None = None) -> NotificationMarkReadResponse:
        owner = db.get(User, owner_id)
        if owner is None or owner.role != "owner":
            raise HTTPException(status_code=404, detail=messages.OWNER_NOT_FOUND)

        query = select(Notification).where(Notification.owner_id == owner_id, Notification.is_read.is_(False))
        if property_id:
            query = query.where(Notification.property_id == property_id)

        rows = db.scalars(query).all()
        for row in rows:
            row.is_read = True
            row.read_at = datetime.utcnow()

        db.commit()
        return NotificationMarkReadResponse(updated=len(rows))

    def create_maintenance(self, payload: MaintenanceCreate, db: Session) -> MaintenanceResponse:
        if db.get(Property, payload.property_id) is None:
            raise HTTPException(status_code=404, detail=messages.PROPERTY_NOT_FOUND)

        tenant = db.get(User, payload.tenant_id)
        if tenant is None:
            db.add(
                User(
                    id=payload.tenant_id,
                    role="tenant",
                    full_name="Tenant User",
                    phone=f"tenant-{payload.tenant_id}",
                    email=f"{payload.tenant_id}@rentory.local",
                    password_hash=self.hash_password("demo"),
                )
            )

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
