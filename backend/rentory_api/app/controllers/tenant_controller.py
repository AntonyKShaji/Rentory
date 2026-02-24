from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.core.security import AuthUser, enforce_user_scope, get_current_user
from app.database import get_db
from app.schemas import TenantDashboardResponse, TenantDetailsResponse
from app.services.rentory_service import RentoryService

router = APIRouter(prefix="/tenants", tags=["tenants"])
service = RentoryService()


@router.get("/{tenant_id}", response_model=TenantDetailsResponse)
def get_tenant(tenant_id: str, db: Session = Depends(get_db), current_user: AuthUser = Depends(get_current_user)) -> TenantDetailsResponse:
    enforce_user_scope(current_user, tenant_id, "tenant")
    return service.get_tenant(tenant_id, db)


@router.get("/{tenant_id}/dashboard", response_model=TenantDashboardResponse)
def tenant_dashboard(tenant_id: str, db: Session = Depends(get_db), current_user: AuthUser = Depends(get_current_user)) -> TenantDashboardResponse:
    enforce_user_scope(current_user, tenant_id, "tenant")
    return service.tenant_dashboard(tenant_id, db)
