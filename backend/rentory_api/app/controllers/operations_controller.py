from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

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
def create_payment(payload: PaymentCreate, db: Session = Depends(get_db)) -> PaymentResponse:
    return service.create_payment(payload, db)


@router.post("/notifications/broadcast", response_model=BroadcastResponse, status_code=202)
def broadcast(payload: BroadcastCreate, db: Session = Depends(get_db)) -> BroadcastResponse:
    return service.broadcast(payload, db)


@router.post("/maintenance-tickets", response_model=MaintenanceResponse, status_code=201)
def create_maintenance(payload: MaintenanceCreate, db: Session = Depends(get_db)) -> MaintenanceResponse:
    return service.create_maintenance(payload, db)
