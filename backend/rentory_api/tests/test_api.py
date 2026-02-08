from fastapi.testclient import TestClient

from app.main import app


client = TestClient(app)


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


def test_tenant_requests_and_payments():
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
    assert join_resp.json()['status'] == 'pending'

    pay_resp = client.post(
        '/payments',
        json={
            'property_id': property_id,
            'tenant_id': 'tenant-100',
            'bill_type': 'rent',
            'amount': 12000,
        },
    )
    assert pay_resp.status_code == 201

    detail_resp = client.get(f'/properties/{property_id}')
    assert detail_resp.status_code == 200
    body = detail_resp.json()
    assert body['property']['id'] == property_id
    assert len(body['bills']) >= 1
