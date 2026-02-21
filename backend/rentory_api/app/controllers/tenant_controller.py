from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from app.database import get_db
from app.schemas import TenantDashboardResponse, TenantDetailsResponse
from app.services.rentory_service import RentoryService

router = APIRouter(prefix="/tenants", tags=["tenants"])
service = RentoryService()


@router.get("/{tenant_id}", response_model=TenantDetailsResponse)
def get_tenant(tenant_id: str, db: Session = Depends(get_db)) -> TenantDetailsResponse:
    return service.get_tenant(tenant_id, db)


@router.get("/{tenant_id}/dashboard", response_model=TenantDashboardResponse)
def tenant_dashboard(tenant_id: str, db: Session = Depends(get_db)) -> TenantDashboardResponse:
    return service.tenant_dashboard(tenant_id, db)
