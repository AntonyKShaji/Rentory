import os
import sys
from pathlib import Path

os.environ["DATABASE_URL"] = "sqlite:///./rentory_test.db"
sys.path.append(str(Path(__file__).resolve().parents[1]))

from fastapi.testclient import TestClient

from app.database import Base, engine
from app.main import app
from app.models import Property

client = TestClient(app)


def setup_function():
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)


def auth_headers(token: str) -> dict[str, str]:
    return {"Authorization": f"Bearer {token}"}


def test_health():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"


def test_property_image_field_supports_long_data_uris():
    owner_signup = client.post(
        "/auth/owners/signup",
        json={
            "full_name": "Demo Owner",
            "phone": "900000100",
            "email": "owner-image@rentory.local",
            "password": "1234",
        },
    )
    assert owner_signup.status_code == 201
    owner_id = owner_signup.json()["user_id"]
    owner_headers = auth_headers(owner_signup.json()["access_token"])

    long_data_uri = "data:image/jpeg;base64," + ("A" * 5000)
    create_property = client.post(
        f"/owners/{owner_id}/properties",
        headers=owner_headers,
        json={
            "location": "Kaloor",
            "name": "Image Heavy Home",
            "unit_type": "2BHK",
            "capacity": 2,
            "rent": 15000,
            "image_url": long_data_uri,
            "description": "Supports base64 uploads",
        },
    )

    assert create_property.status_code == 201
    assert create_property.json()["image_url"] == long_data_uri
    assert Property.__table__.c.image_url.type.length is None


def test_owner_property_qr_chat_and_tenant_registration_flow():
    owner_signup = client.post(
        "/auth/owners/signup",
        json={
            "full_name": "Demo Owner",
            "phone": "900000001",
            "email": "owner1@rentory.local",
            "password": "1234",
        },
    )
    assert owner_signup.status_code == 201
    owner_id = owner_signup.json()["user_id"]
    owner_headers = auth_headers(owner_signup.json()["access_token"])

    create_property = client.post(
        f"/owners/{owner_id}/properties",
        headers=owner_headers,
        json={
            "location": "Kaloor",
            "name": "Kaloor Residency A",
            "unit_type": "2BHK",
            "capacity": 2,
            "rent": 25000,
            "image_url": "https://example.com/property.jpg",
            "description": "Near metro station",
        },
    )
    assert create_property.status_code == 201
    property_data = create_property.json()
    property_id = property_data["id"]

    detail_before_tenant = client.get(f"/properties/{property_id}", headers=owner_headers)
    assert detail_before_tenant.status_code == 200

    tenant_register = client.post(
        "/auth/tenants/register",
        json={
            "qr_code": property_data["qr_code"],
            "full_name": "Alice Tenant",
            "age": 27,
            "phone": "900000002",
            "email": "alice@rentory.local",
            "documents": "aadhar-front.png",
            "password": "1234",
        },
    )
    assert tenant_register.status_code == 201
    tenant_id = tenant_register.json()["user_id"]
    tenant_headers = auth_headers(tenant_register.json()["access_token"])

    chat_post_owner = client.post(
        f"/properties/{property_id}/chat",
        headers=owner_headers,
        json={"sender_id": owner_id, "text": "Welcome to the property group"},
    )
    assert chat_post_owner.status_code == 201

    chat_post_tenant = client.post(
        f"/properties/{property_id}/chat",
        headers=tenant_headers,
        json={"sender_id": tenant_id, "image_url": "https://example.com/bill.jpg"},
    )
    assert chat_post_tenant.status_code == 201

    chat_list = client.get(f"/properties/{property_id}/chat", headers=tenant_headers)
    assert chat_list.status_code == 200
    assert len(chat_list.json()) == 2


def test_qr_capacity_limit_and_existing_integrations():
    owner_signup = client.post(
        "/auth/owners/signup",
        json={
            "full_name": "Owner Seed",
            "phone": "owner-seeded",
            "email": "owner-seeded@rentory.local",
            "password": "1234",
        },
    )
    owner_id = owner_signup.json()["user_id"]
    owner_headers = auth_headers(owner_signup.json()["access_token"])

    create_property = client.post(
        f"/owners/{owner_id}/properties",
        headers=owner_headers,
        json={
            "location": "Edappally",
            "name": "Edappally Homes",
            "unit_type": "1BHK",
            "capacity": 1,
            "rent": 12000,
            "image_url": "https://example.com/home.jpg",
            "description": "Compact home",
        },
    )
    property_data = create_property.json()
    property_id = property_data["id"]

    first_tenant = client.post(
        "/auth/tenants/register",
        json={
            "qr_code": property_data["qr_code"],
            "full_name": "Tenant One",
            "age": 24,
            "phone": "900000010",
            "email": "t1@rentory.local",
            "documents": "passport.pdf",
            "password": "1234",
        },
    )
    assert first_tenant.status_code == 201
    tenant_headers = auth_headers(first_tenant.json()["access_token"])

    second_tenant = client.post(
        "/auth/tenants/register",
        json={
            "qr_code": property_data["qr_code"],
            "full_name": "Tenant Two",
            "age": 25,
            "phone": "900000011",
            "email": "t2@rentory.local",
            "documents": "id.png",
            "password": "1234",
        },
    )
    assert second_tenant.status_code == 409

    payment_resp = client.post(
        "/payments",
        headers=tenant_headers,
        json={
            "property_id": property_id,
            "tenant_id": first_tenant.json()["user_id"],
            "bill_type": "rent",
            "amount": 12000,
        },
    )
    assert payment_resp.status_code == 201

    maintenance_resp = client.post(
        "/maintenance-tickets",
        headers=tenant_headers,
        json={
            "property_id": property_id,
            "tenant_id": first_tenant.json()["user_id"],
            "issue_title": "Water leakage",
            "issue_description": "Kitchen sink leaking",
        },
    )
    assert maintenance_resp.status_code == 201

    broadcast_resp = client.post(
        "/notifications/broadcast",
        headers=owner_headers,
        json={
            "owner_id": owner_id,
            "title": "Reminder",
            "body": "Please pay rent",
            "property_ids": [property_id],
        },
    )
    assert broadcast_resp.status_code == 202


def test_forbidden_without_token():
    owner_signup = client.post(
        "/auth/owners/signup",
        json={
            "full_name": "Demo Owner",
            "phone": "900000777",
            "email": "owner7@rentory.local",
            "password": "1234",
        },
    )
    owner_id = owner_signup.json()["user_id"]

    response = client.get(f"/owners/{owner_id}/properties")
    assert response.status_code == 403
