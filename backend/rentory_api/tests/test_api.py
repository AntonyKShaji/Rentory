import os

os.environ["DATABASE_URL"] = "sqlite:///./rentory_test.db"

from fastapi.testclient import TestClient

from app.main import app
from app.database import Base, SessionLocal, engine
from app.models import User

client = TestClient(app)


def setup_function():
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)

    db = SessionLocal()
    db.add(User(id="owner-1", role="owner", full_name="Demo Owner", phone="owner-1", email="owner-1@rentory.local"))
    db.commit()
    db.close()


def test_health():
    response = client.get('/health')
    assert response.status_code == 200
    assert response.json()['status'] == 'ok'


def test_owner_property_flow():
    create_resp = client.post(
        '/owners/owner-1/properties',
        json={
            'location': 'Kaloor',
            'name': 'Kaloor Residency A',
            'unit_type': '2BHK',
            'capacity': 4,
        },
    )
    assert create_resp.status_code == 201
    property_id = create_resp.json()['id']

    list_resp = client.get('/owners/owner-1/properties')
    assert list_resp.status_code == 200
    assert any(item['id'] == property_id for item in list_resp.json())


def test_other_api_connections():
    create_property = client.post(
        '/owners/owner-1/properties',
        json={
            'location': 'Edappally',
            'name': 'Edappally Homes',
            'unit_type': '1BHK',
            'capacity': 2,
        },
    )
    property_id = create_property.json()['id']

    join_resp = client.post(
        f'/properties/{property_id}/tenants/join-requests',
        json={'tenant_id': 'tenant-100'},
    )
    assert join_resp.status_code == 201

    payment_resp = client.post(
        '/payments',
        json={
            'property_id': property_id,
            'tenant_id': 'tenant-100',
            'bill_type': 'rent',
            'amount': 12000,
        },
    )
    assert payment_resp.status_code == 201

    maintenance_resp = client.post(
        '/maintenance-tickets',
        json={
            'property_id': property_id,
            'tenant_id': 'tenant-100',
            'issue_title': 'Water leakage',
            'issue_description': 'Kitchen sink leaking',
        },
    )
    assert maintenance_resp.status_code == 201

    broadcast_resp = client.post(
        '/notifications/broadcast',
        json={
            'owner_id': 'owner-1',
            'title': 'Reminder',
            'body': 'Please pay rent',
            'property_ids': [property_id],
        },
    )
    assert broadcast_resp.status_code == 202

    detail_resp = client.get(f'/properties/{property_id}')
    assert detail_resp.status_code == 200
    assert detail_resp.json()['property']['id'] == property_id
