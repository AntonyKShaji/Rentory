from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database import get_db
from app.schemas import (
    ChatMessageCreate,
    ChatMessageResponse,
    JoinRequestCreate,
    JoinRequestResponse,
    PropertyDetailsResponse,
    WaterBillStatusUpdateRequest,
)
from app.services.rentory_service import RentoryService

router = APIRouter(prefix="/properties", tags=["properties"])
service = RentoryService()


@router.get("/{property_id}", response_model=PropertyDetailsResponse)
def get_property(property_id: str, db: Session = Depends(get_db)) -> PropertyDetailsResponse:
    return service.get_property(property_id, db)


@router.patch("/{property_id}/water-bill")
def update_water_bill_status(property_id: str, payload: WaterBillStatusUpdateRequest, db: Session = Depends(get_db)) -> dict:
    return service.update_water_bill_status(property_id, payload, db)


@router.get("/{property_id}/chat", response_model=list[ChatMessageResponse])
def list_chat_messages(property_id: str, db: Session = Depends(get_db)) -> list[ChatMessageResponse]:
    return service.list_chat_messages(property_id, db)


@router.post("/{property_id}/chat", response_model=ChatMessageResponse, status_code=201)
def post_chat_message(property_id: str, payload: ChatMessageCreate, db: Session = Depends(get_db)) -> ChatMessageResponse:
    return service.post_chat_message(property_id, payload, db)


@router.post("/{property_id}/tenants/join-requests", response_model=JoinRequestResponse, status_code=201)
def request_join_property(property_id: str, payload: JoinRequestCreate, db: Session = Depends(get_db)) -> JoinRequestResponse:
    return service.request_join_property(property_id, payload, db)
