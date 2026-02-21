from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database import get_db
from app.schemas import OwnerAnalyticsResponse, PropertyCardResponse, PropertyCreateRequest
from app.services.rentory_service import RentoryService

router = APIRouter(prefix="/owners", tags=["owners"])
service = RentoryService()


@router.get("/{owner_id}/properties", response_model=list[PropertyCardResponse])
def list_properties(owner_id: str, db: Session = Depends(get_db)) -> list[PropertyCardResponse]:
    return service.list_properties(owner_id, db)


@router.get("/{owner_id}/analytics", response_model=OwnerAnalyticsResponse)
def owner_analytics(owner_id: str, db: Session = Depends(get_db)) -> OwnerAnalyticsResponse:
    return service.owner_analytics(owner_id, db)


@router.post("/{owner_id}/properties", response_model=PropertyCardResponse, status_code=201)
def create_property(owner_id: str, payload: PropertyCreateRequest, db: Session = Depends(get_db)) -> PropertyCardResponse:
    return service.create_property(owner_id, payload, db)
