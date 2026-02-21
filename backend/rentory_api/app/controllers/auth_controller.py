from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database import get_db
from app.schemas import LoginRequest, LoginResponse, OwnerSignupRequest, TenantRegistrationRequest
from app.services.rentory_service import RentoryService

router = APIRouter(prefix="/auth", tags=["auth"])
service = RentoryService()


@router.post("/owners/signup", response_model=LoginResponse, status_code=201)
def owner_signup(payload: OwnerSignupRequest, db: Session = Depends(get_db)) -> LoginResponse:
    return service.owner_signup(payload, db)


@router.post("/tenants/register", response_model=LoginResponse, status_code=201)
def tenant_register(payload: TenantRegistrationRequest, db: Session = Depends(get_db)) -> LoginResponse:
    return service.tenant_register(payload, db)


@router.post("/login", response_model=LoginResponse)
def login(payload: LoginRequest, db: Session = Depends(get_db)) -> LoginResponse:
    return service.login(payload, db)
