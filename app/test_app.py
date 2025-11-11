from fastapi.testclient import TestClient
from main import app

client = TestClient(app)

def test_healthz():
    res = client.get("/healthz")
    assert res.status_code == 200
    assert res.json() == {"status": "ok"}

def test_work():
    res = client.get("/work?ms=150")
    assert res.status_code == 200
    data = res.json()
    assert "slept_ms" in data
    assert "latency_s" in data
    assert data["ok"] is True

def test_random():
    res = client.get("/random")
    assert res.status_code == 200
    data = res.json()
    assert "value" in data
    assert 0 <= data["value"] <= 1

def test_metrics():
    res = client.get("/metrics")
    assert res.status_code == 200
    assert "demo_requests_total" in res.text
