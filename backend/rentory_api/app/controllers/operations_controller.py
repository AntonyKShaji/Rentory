from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from app.core import messages
from app.core.security import AuthUser, get_current_user
from app.database import get_db
from app.schemas import (
    BroadcastCreate,
    BroadcastResponse,
    MaintenanceCreate,
    MaintenanceResponse,
    PaymentCreate,
    PaymentResponse,
)
from app.services.rentory_service import RentoryService

router = APIRouter(tags=["operations"])
service = RentoryService()


@router.post("/payments", response_model=PaymentResponse, status_code=201)
def create_payment(payload: PaymentCreate, db: Session = Depends(get_db), current_user: AuthUser = Depends(get_current_user)) -> PaymentResponse:
    if current_user.role != "tenant" or current_user.user_id != payload.tenant_id:
        raise HTTPException(status_code=403, detail=messages.AUTHORIZATION_DENIED)
    return service.create_payment(payload, db)


@router.post("/notifications/broadcast", response_model=BroadcastResponse, status_code=202)
def broadcast(payload: BroadcastCreate, db: Session = Depends(get_db), current_user: AuthUser = Depends(get_current_user)) -> BroadcastResponse:
    if current_user.role != "owner" or current_user.user_id != payload.owner_id:
        raise HTTPException(status_code=403, detail=messages.AUTHORIZATION_DENIED)
    return service.broadcast(payload, db)


@router.post("/maintenance-tickets", response_model=MaintenanceResponse, status_code=201)
def create_maintenance(payload: MaintenanceCreate, db: Session = Depends(get_db), current_user: AuthUser = Depends(get_current_user)) -> MaintenanceResponse:
    if current_user.role != "tenant" or current_user.user_id != payload.tenant_id:
        raise HTTPException(status_code=403, detail=messages.AUTHORIZATION_DENIED)
    return service.create_maintenance(payload, db)
