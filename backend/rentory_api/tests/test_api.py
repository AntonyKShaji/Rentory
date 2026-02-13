import sys
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parents[1]))

import os

os.environ["DATABASE_URL"] = "sqlite:///./rentory_test.db"

from fastapi.testclient import TestClient

from app.database import Base, SessionLocal, engine
from app.main import app
from app.models import User

client = TestClient(app)


def setup_function():
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)


def test_health():
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"


def test_owner_and_property_flow_with_analytics_and_chat():
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

    create_resp = client.post(
        f"/owners/{owner_id}/properties",
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
    assert create_resp.status_code == 201
    property_data = create_resp.json()
    property_id = property_data["id"]

    analytics_resp = client.get(f"/owners/{owner_id}/analytics")
    assert analytics_resp.status_code == 200
    assert analytics_resp.json()["total_properties"] == 1

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

    water_bill = client.patch(f"/properties/{property_id}/water-bill", json={"status": "paid"})
    assert water_bill.status_code == 200

    chat_post = client.post(
        f"/properties/{property_id}/chat",
        json={"sender_id": tenant_id, "text": "Hello everyone"},
    )
    assert chat_post.status_code == 201

    chat_list = client.get(f"/properties/{property_id}/chat")
    assert chat_list.status_code == 200
    assert len(chat_list.json()) == 1

    detail_resp = client.get(f"/properties/{property_id}")
    assert detail_resp.status_code == 200
    payload = detail_resp.json()
    assert payload["property"]["id"] == property_id
    assert payload["water_bill_status"] == "paid"
    assert payload["tenants"][0]["tenant_id"] == tenant_id

    tenant_detail = client.get(f"/tenants/{tenant_id}")
    assert tenant_detail.status_code == 200
    assert tenant_detail.json()["full_name"] == "Alice Tenant"


def test_qr_capacity_limit_and_existing_integrations():
    db = SessionLocal()
    owner = User(
        id="owner-seeded",
        role="owner",
        full_name="Owner Seed",
        phone="owner-seeded",
        email="owner-seeded@rentory.local",
        password_hash="plain::1234",
    )
    db.add(owner)
    db.commit()
    db.close()

    create_property = client.post(
        "/owners/owner-seeded/properties",
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
        json={
            "owner_id": "owner-seeded",
            "title": "Reminder",
            "body": "Please pay rent",
            "property_ids": [property_id],
        },
    )
    assert broadcast_resp.status_code == 202
