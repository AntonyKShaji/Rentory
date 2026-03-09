from collections import defaultdict

from fastapi import APIRouter, Depends, HTTPException, WebSocket, WebSocketDisconnect, status
from fastapi.encoders import jsonable_encoder
from sqlalchemy.orm import Session

from app.core import messages
from app.core.security import AuthUser, SecurityService, get_current_user
from app.database import SessionLocal, get_db
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


class ChatConnectionManager:
    def __init__(self) -> None:
        self._connections: dict[str, set[WebSocket]] = defaultdict(set)

    async def connect(self, property_id: str, websocket: WebSocket) -> None:
        await websocket.accept()
        self._connections[property_id].add(websocket)

    def disconnect(self, property_id: str, websocket: WebSocket) -> None:
        connections = self._connections.get(property_id)
        if not connections:
            return
        connections.discard(websocket)
        if not connections:
            self._connections.pop(property_id, None)

    async def broadcast(self, property_id: str, payload: dict) -> None:
        for connection in list(self._connections.get(property_id, set())):
            await connection.send_json(payload)


connection_manager = ChatConnectionManager()


def _authenticate_websocket(websocket: WebSocket) -> AuthUser:
    authorization = websocket.headers.get("authorization", "")
    token = websocket.query_params.get("token")
    if authorization.lower().startswith("bearer "):
        token = authorization.split(" ", 1)[1].strip()
    if not token:
        raise HTTPException(status_code=401, detail=messages.INVALID_ACCESS_TOKEN)
    return SecurityService.decode_access_token(token)


@router.get("/{property_id}", response_model=PropertyDetailsResponse)
def get_property(property_id: str, db: Session = Depends(get_db), _: AuthUser = Depends(get_current_user)) -> PropertyDetailsResponse:
    return service.get_property(property_id, db)


@router.patch("/{property_id}/water-bill")
def update_water_bill_status(
    property_id: str,
    payload: WaterBillStatusUpdateRequest,
    db: Session = Depends(get_db),
    current_user: AuthUser = Depends(get_current_user),
) -> dict:
    if current_user.role != "owner":
        raise HTTPException(status_code=403, detail=messages.AUTHORIZATION_DENIED)
    return service.update_water_bill_status(property_id, payload, db)


@router.get("/{property_id}/chat", response_model=list[ChatMessageResponse])
def list_chat_messages(property_id: str, db: Session = Depends(get_db), _: AuthUser = Depends(get_current_user)) -> list[ChatMessageResponse]:
    return service.list_chat_messages(property_id, db)


@router.post("/{property_id}/chat", response_model=ChatMessageResponse, status_code=201)
def post_chat_message(
    property_id: str,
    payload: ChatMessageCreate,
    db: Session = Depends(get_db),
    current_user: AuthUser = Depends(get_current_user),
) -> ChatMessageResponse:
    if current_user.user_id != payload.sender_id:
        raise HTTPException(status_code=403, detail=messages.AUTHORIZATION_DENIED)
    message = service.post_chat_message(property_id, payload, db)
    return message


@router.websocket("/{property_id}/chat/ws")
async def chat_websocket(websocket: WebSocket, property_id: str) -> None:
    db = SessionLocal()
    try:
        current_user = _authenticate_websocket(websocket)
    except HTTPException:
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
        db.close()
        return

    try:
        await connection_manager.connect(property_id, websocket)
        history = service.list_chat_messages(property_id, db)
        await websocket.send_json({"type": "history", "messages": jsonable_encoder(history)})

        while True:
            data = await websocket.receive_json()
            payload = ChatMessageCreate(**data)
            if current_user.user_id != payload.sender_id:
                await websocket.send_json({"type": "error", "detail": messages.AUTHORIZATION_DENIED})
                continue

            message = service.post_chat_message(property_id, payload, db)
            await connection_manager.broadcast(
                property_id,
                {"type": "message", "message": jsonable_encoder(message)},
            )
    except WebSocketDisconnect:
        pass
    finally:
        connection_manager.disconnect(property_id, websocket)
        db.close()


@router.post("/{property_id}/tenants/join-requests", response_model=JoinRequestResponse, status_code=201)
def request_join_property(
    property_id: str,
    payload: JoinRequestCreate,
    db: Session = Depends(get_db),
    current_user: AuthUser = Depends(get_current_user),
) -> JoinRequestResponse:
    if current_user.role != "tenant" or current_user.user_id != payload.tenant_id:
        raise HTTPException(status_code=403, detail=messages.AUTHORIZATION_DENIED)
    return service.request_join_property(property_id, payload, db)
