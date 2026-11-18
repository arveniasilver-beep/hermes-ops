"""Unit tests for trendyol_client - no network, httpx.MockTransport throughout."""

import base64
import json
import sys
from pathlib import Path

import httpx
import pytest

sys.path.insert(0, str(Path(__file__).parent))

import trendyol_client as tc  # noqa: E402

CFG = tc.TrendyolConfig(api_key="key", api_secret="secret", seller_id="123456")


def make_client(handler, sleeps=None):
    calls = []

    def sleep(sec):
        if sleeps is not None:
            sleeps.append(sec)

    def wrapped(request):
        calls.append(request)
        return handler(request)

    client = tc.TrendyolClient(CFG, transport=httpx.MockTransport(wrapped), sleep=sleep, min_interval=0)
    return client, calls


def ok(payload):
    return lambda request: httpx.Response(200, json=payload)


# --------------------------------------------------------------------------- config

def test_load_config_missing_lists_every_var(tmp_path):
    with pytest.raises(tc.ConfigError) as exc:
        tc.load_config(str(tmp_path / "nope.env"), environ={})
    msg = str(exc.value)
    for name in (tc.ENV_API_KEY, tc.ENV_API_SECRET, tc.ENV_SELLER_ID):
        assert name in msg
    assert "Entegrasyon Bilgileri" in msg


def test_load_config_reads_env_file_and_stage_flag(tmp_path):
    env = tmp_path / ".env"
    env.write_text(
        "TRENDYOL_API_KEY=k1\nTRENDYOL_API_SECRET=s1\nTRENDYOL_SELLER_ID=42\nTRENDYOL_STAGE=1\n",
        encoding="utf-8",
    )
    cfg = tc.load_config(str(env), environ={})
    assert (cfg.api_key, cfg.api_secret, cfg.seller_id, cfg.stage) == ("k1", "s1", "42", True)
    assert cfg.base_url == tc.BASE_STAGE


def test_load_config_survives_bom_on_first_key(tmp_path):
    # PowerShell 5.1 `Set-Content -Encoding utf8` and Notepad write a BOM; if the
    # first line is a key, plain utf-8 parsing would name it "﻿TRENDYOL_API_KEY".
    env = tmp_path / ".env"
    env.write_bytes(b"\xef\xbb\xbfTRENDYOL_API_KEY=k\nTRENDYOL_API_SECRET=s\nTRENDYOL_SELLER_ID=7\n")
    cfg = tc.load_config(str(env), environ={})
    assert (cfg.api_key, cfg.seller_id) == ("k", "7")


def test_load_config_rejects_non_numeric_seller_id(tmp_path):
    env = tmp_path / ".env"
    env.write_text("TRENDYOL_API_KEY=k\nTRENDYOL_API_SECRET=s\nTRENDYOL_SELLER_ID=abc\n", encoding="utf-8")
    with pytest.raises(tc.ConfigError):
        tc.load_config(str(env), environ={})


def test_env_file_wins_over_process_environ(tmp_path):
    env = tmp_path / ".env"
    env.write_text("TRENDYOL_API_KEY=file\nTRENDYOL_API_SECRET=s\nTRENDYOL_SELLER_ID=1\n", encoding="utf-8")
    cfg = tc.load_config(str(env), environ={"TRENDYOL_API_KEY": "proc"})
    assert cfg.api_key == "file"


# --------------------------------------------------------------------------- headers

def test_auth_and_user_agent_headers():
    client, calls = make_client(ok({"content": [], "totalPages": 0}))
    client.approved_products()
    req = calls[0]
    assert req.headers["Authorization"] == "Basic " + base64.b64encode(b"key:secret").decode()
    assert req.headers["User-Agent"] == "123456 - SelfIntegration"
    assert str(req.url).startswith(tc.BASE_PROD + "/product/sellers/123456/products/approved")


# --------------------------------------------------------------------------- dates

def test_parse_date_is_istanbul_midnight_in_utc_ms():
    ms = tc.parse_date("2026-09-01")
    # 2026-09-01 00:00 Istanbul (UTC+3) == 2026-08-31 21:00:00 UTC
    # (plain UTC midnight would be 1788220800000 - the 3 h gap proves the tz applied)
    assert ms == 1788210000000
    assert tc.parse_date("2026-09-01", end_of_day=True) == ms + 24 * 3600 * 1000 - 1


def test_parse_date_rejects_bad_format():
    with pytest.raises(ValueError):
        tc.parse_date("01.09.2026")


def test_chunk_range_splits_into_max_days_windows():
    day = 24 * 3600 * 1000
    chunks = tc.chunk_range(0, 35 * day - 1, 15)
    assert chunks == [(0, 15 * day - 1), (15 * day, 30 * day - 1), (30 * day, 35 * day - 1)]
    assert tc.chunk_range(5, 5, 15) == [(5, 5)]
    with pytest.raises(ValueError):
        tc.chunk_range(10, 5, 15)


# --------------------------------------------------------------------------- endpoints

def test_orders_params_and_size_cap():
    client, calls = make_client(ok({"content": [], "totalPages": 0}))
    client.orders(1000, 2000, status="Delivered", page=2, size=999)
    q = dict(calls[0].url.params)
    assert q["startDate"] == "1000" and q["endDate"] == "2000"
    assert q["status"] == "Delivered" and q["page"] == "2" and q["size"] == "200"
    assert q["orderByField"] == "CreatedDate"


def test_orders_rejects_window_over_14_days():
    client, _ = make_client(ok({}))
    with pytest.raises(ValueError):
        client.orders(0, 15 * 24 * 3600 * 1000)


def test_settlements_rejects_window_over_15_days_and_snaps_size():
    client, calls = make_client(ok({"content": []}))
    with pytest.raises(ValueError):
        client.settlements(0, 16 * 24 * 3600 * 1000)
    client.settlements(0, 1000, size=700)
    assert dict(calls[0].url.params)["size"] == "1000"
    assert "transactionTypes" in dict(calls[0].url.params)


def test_products_page_size_rule():
    client, _ = make_client(ok({}))
    with pytest.raises(ValueError):
        client.approved_products(page=100, size=100)  # 101*100 > 10000


def test_401_raises_auth_error():
    client, _ = make_client(lambda r: httpx.Response(401, json={"exception": "ClientApiAuthenticationException"}))
    with pytest.raises(tc.AuthError):
        client.approved_products()


def test_403_and_500_raise_api_error_with_status():
    for code in (403, 500):
        client, _ = make_client(lambda r, c=code: httpx.Response(c, text="boom"))
        with pytest.raises(tc.ApiError) as exc:
            client.approved_products()
        assert exc.value.status == code


def test_429_retries_then_succeeds_and_honours_retry_after():
    sleeps = []
    state = {"n": 0}

    def handler(request):
        state["n"] += 1
        if state["n"] == 1:
            return httpx.Response(429, headers={"Retry-After": "3"})
        return httpx.Response(200, json={"content": ["x"], "totalPages": 1})

    client, calls = make_client(handler, sleeps=sleeps)
    data = client.approved_products()
    assert data["content"] == ["x"] and len(calls) == 2
    assert 3.0 in sleeps


def test_429_exhausted_raises():
    client, calls = make_client(lambda r: httpx.Response(429))
    with pytest.raises(tc.ApiError) as exc:
        client.approved_products()
    assert exc.value.status == 429 and len(calls) == 4  # 1 + 3 retries


# --------------------------------------------------------------------------- shaping

def test_strip_order_pii_removes_buyer_fields_keeps_lines():
    pkg = {
        "orderNumber": "1", "status": "Delivered", "customerFirstName": "A", "customerEmail": "a@b",
        "customerTckn": "111", "shipmentAddress": {"city": "X"}, "invoiceAddress": {}, "taxNumber": "9",
        "customerSomethingNew": "z", "cargoProviderName": "Yurtici", "lines": [{"barcode": "B1"}],
    }
    out = tc.strip_order_pii(pkg)
    assert set(out) == {"orderNumber", "status", "cargoProviderName", "lines"}
    assert pkg["customerFirstName"] == "A"  # original untouched


def test_iter_orders_paginates_chunks_and_strips_pii():
    day = 24 * 3600 * 1000
    seen = []

    def handler(request):
        q = dict(request.url.params)
        seen.append((q["startDate"], q["page"]))
        page = int(q["page"])
        return httpx.Response(200, json={
            "totalPages": 2,
            "content": [{"orderNumber": f"{q['startDate']}-{page}", "customerEmail": "x", "lines": []}],
        })

    client, _ = make_client(handler)
    rows = list(client.iter_orders(0, 20 * day - 1))
    # two 14-day chunks x two pages = 4 packages, none carrying PII
    assert len(rows) == 4 and all("customerEmail" not in r for r in rows)
    assert [p for _, p in seen] == ["0", "1", "0", "1"]


def test_iter_orders_marks_truncation_instead_of_lying():
    client, _ = make_client(ok({"totalPages": 99, "content": [{"orderNumber": "o", "lines": []}]}))
    rows = list(client.iter_orders(0, 1000, max_pages_per_chunk=2))
    assert rows[-1]["_truncated"] is True and rows[-1]["total_pages"] == 99
    assert len([r for r in rows if not r.get("_truncated")]) == 2


def test_summarize_sales_aggregates_and_joins_claims():
    packages = [
        {"orderNumber": "A", "status": "Delivered", "lines": [
            {"barcode": "K1", "productName": "Kolye", "quantity": 2, "amount": 400, "discount": 40, "tyDiscount": 10},
            {"barcode": "Y1", "productName": "Yuzuk", "quantity": 1, "amount": 150, "discount": 0},
        ]},
        {"orderNumber": "B", "status": "Shipped", "lines": [
            {"barcode": "K1", "productName": "Kolye", "quantity": 1, "amount": 200, "discount": 0},
        ]},
        {"orderNumber": "C", "status": "Cancelled", "lines": [
            {"barcode": "K1", "productName": "Kolye", "quantity": 5, "amount": 1000},
        ]},
        {"orderNumber": "D", "status": "Returned", "lines": [
            {"barcode": "Y1", "productName": "Yuzuk", "quantity": 1, "amount": 150},
        ]},
        {"_truncated": True, "total_pages": 50},
    ]
    claims = [{"items": [{"orderLine": {"barcode": "K1", "productName": "Kolye"}, "claimItems": [{}, {}]}]}]

    out = tc.summarize_sales(packages, claims)
    by = {r["barcode"]: r for r in out["products"]}
    k1, y1 = by["K1"], by["Y1"]
    assert (k1["units"], k1["orders"], k1["gross"], k1["seller_discount"], k1["ty_discount"]) == (3, 2, 600.0, 40.0, 10.0)
    assert k1["net_estimate"] == 560.0 and k1["cancelled_units"] == 5 and k1["claim_items"] == 2
    assert k1["return_rate"] == round(2 / 3, 3)
    assert y1["returned_units"] == 1 and y1["units"] == 1 and y1["return_rate"] == 0.0
    assert out["products"][0]["barcode"] == "K1"  # sorted by net_estimate desc
    assert out["totals"] == {"packages": 4, "orders": 4, "units": 4, "gross": 750.0, "net_estimate": 710.0, "claim_items": 2}
    assert out["status_counts"] == {"Delivered": 1, "Shipped": 1, "Cancelled": 1, "Returned": 1}
    assert out["truncated_chunks"] == [{"_truncated": True, "total_pages": 50}]
    json.dumps(out)  # must be serialisable for the MCP response
