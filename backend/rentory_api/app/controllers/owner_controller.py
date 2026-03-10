from typing import Literal

from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session

from app.core.security import AuthUser, enforce_user_scope, get_current_user
from app.database import get_db
from app.schemas import (
    NotificationListResponse,
    NotificationMarkReadResponse,
    OwnerAnalyticsResponse,
    OwnerProfileResponse,
    PropertyCardResponse,
    PropertyCreateRequest,
)
from app.services.rentory_service import RentoryService

router = APIRouter(prefix="/owners", tags=["owners"])
service = RentoryService()


@router.get("/{owner_id}/properties", response_model=list[PropertyCardResponse])
def list_properties(
    owner_id: str,
    db: Session = Depends(get_db),
    current_user: AuthUser = Depends(get_current_user),
) -> list[PropertyCardResponse]:
    enforce_user_scope(current_user, owner_id, "owner")
    return service.list_properties(owner_id, db)


@router.get("/{owner_id}/profile", response_model=OwnerProfileResponse)
def owner_profile(
    owner_id: str,
    db: Session = Depends(get_db),
    current_user: AuthUser = Depends(get_current_user),
) -> OwnerProfileResponse:
    enforce_user_scope(current_user, owner_id, "owner")
    return service.owner_profile(owner_id, db)


@router.get("/{owner_id}/analytics", response_model=OwnerAnalyticsResponse)
def owner_analytics(
    owner_id: str,
    db: Session = Depends(get_db),
    current_user: AuthUser = Depends(get_current_user),
) -> OwnerAnalyticsResponse:
    enforce_user_scope(current_user, owner_id, "owner")
    return service.owner_analytics(owner_id, db)


@router.post(
    "/{owner_id}/properties", response_model=PropertyCardResponse, status_code=201
)
def create_property(
    owner_id: str,
    payload: PropertyCreateRequest,
    db: Session = Depends(get_db),
    current_user: AuthUser = Depends(get_current_user),
) -> PropertyCardResponse:
    enforce_user_scope(current_user, owner_id, "owner")
    return service.create_property(owner_id, payload, db)


@router.get("/{owner_id}/notifications", response_model=NotificationListResponse)
def list_notifications(
    owner_id: str,
    property_id: str | None = Query(default=None),
    category: Literal["all", "payment", "maintenance", "general"] = Query(
        default="all"
    ),
    search: str | None = Query(default=None),
    db: Session = Depends(get_db),
    current_user: AuthUser = Depends(get_current_user),
) -> NotificationListResponse:
    enforce_user_scope(current_user, owner_id, "owner")
    return service.list_notifications(
        owner_id, db, property_id=property_id, category=category, search=search
    )


@router.patch(
    "/{owner_id}/notifications/mark-read", response_model=NotificationMarkReadResponse
)
def mark_notifications_read(
    owner_id: str,
    property_id: str | None = Query(default=None),
    db: Session = Depends(get_db),
    current_user: AuthUser = Depends(get_current_user),
) -> NotificationMarkReadResponse:
    enforce_user_scope(current_user, owner_id, "owner")
    return service.mark_notifications_read(owner_id, db, property_id=property_id)
