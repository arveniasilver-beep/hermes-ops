"""Read-only Trendyol Seller API client for the Hermes MCP bridge.

Deliberately narrow: only GET endpoints, only the data an ad-budget analysis
needs. No stock/price/product mutation exists here on purpose - an assistant
driving a live store must not be one bad tool call away from repricing it.

Contracts verified against developers.trendyol.com on 2026-09-18:
  base        https://apigw.trendyol.com/integration  (stage: stageapigw.)
  auth        Basic  base64(apiKey:apiSecret)
  user-agent  "{sellerId} - SelfIntegration"   (missing -> 403)
  rate limit  50 req / 10 s per endpoint (51st -> 429)
  orders      GET /order/sellers/{id}/orders            size<=200
  claims      GET /order/sellers/{id}/claims            size<=200
  settlements GET /finance/che/sellers/{id}/settlements size 500|1000, range<=15d
  otherfin    GET /finance/che/sellers/{id}/otherfinancials          range<=15d
  products    GET /product/sellers/{id}/products/approved (V2) size<=100

Buyer PII (name, e-mail, TCKN, addresses) is stripped from order rows before
they leave this module: the analysis never needs it and KVKK says don't move it.
"""

from __future__ import annotations

import base64
import os
import time
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone
from typing import Any, Callable, Dict, Iterable, List, Optional

import httpx

BASE_PROD = "https://apigw.trendyol.com/integration"
BASE_STAGE = "https://stageapigw.trendyol.com/integration"

ENV_API_KEY = "TRENDYOL_API_KEY"
ENV_API_SECRET = "TRENDYOL_API_SECRET"
ENV_SELLER_ID = "TRENDYOL_SELLER_ID"
ENV_STAGE = "TRENDYOL_STAGE"

FINANCE_MAX_DAYS = 15
# Orders: the docs give no window, but the gateway rejects wide ranges in
# practice; 14 days is the conventional safe chunk.
ORDERS_MAX_DAYS = 14

# Order statuses that carry no (or reversed) seller revenue.
NON_REVENUE_STATUSES = frozenset({"Cancelled", "UnSupplied", "Returned", "UnDelivered"})

# Fields dropped from every order package. Anything else starting with
# "customer" is dropped too (see strip_order_pii).
_PII_FIELDS = frozenset({
    "customerFirstName", "customerLastName", "customerId", "customerEmail",
    "customerTckn", "identityNumber", "taxNumber", "invoiceAddress",
    "shipmentAddress",
})

DEFAULT_SETTLEMENT_TYPES = (
    "Sale,Return,Discount,DiscountCancel,Coupon,CouponCancel,"
    "CommissionPositive,CommissionNegative,SellerRevenuePositive,SellerRevenueNegative"
)


class ConfigError(RuntimeError):
    """Credentials missing or malformed; message says exactly where to put them."""


class AuthError(RuntimeError):
    """401 from the gateway - key/secret wrong or from the other environment."""


class ApiError(RuntimeError):
    def __init__(self, status: int, body: str, path: str):
        self.status, self.body, self.path = status, body, path
        super().__init__(f"Trendyol API {status} on {path}: {body[:300]}")


@dataclass(frozen=True)
class TrendyolConfig:
    api_key: str
    api_secret: str
    seller_id: str
    stage: bool = False

    @property
    def base_url(self) -> str:
        return BASE_STAGE if self.stage else BASE_PROD


def load_config(env_file: Optional[str] = None, environ: Optional[Dict[str, str]] = None) -> TrendyolConfig:
    """Read credentials from ``env_file`` (dotenv) with ``environ`` as fallback.

    The .env file is the single home for secrets; Hermes only hands this
    module the *path* (non-secret) so nothing lands in config.yaml.
    """
    values: Dict[str, str] = {}
    if env_file and os.path.isfile(env_file):
        from dotenv import dotenv_values

        # utf-8-sig, like Hermes's own loader: PowerShell 5.1 and Notepad prepend a
        # BOM, and plain utf-8 would glue U+FEFF onto the first key's name.
        values.update({
            k: v for k, v in dotenv_values(env_file, encoding="utf-8-sig").items() if v is not None
        })
    env = environ if environ is not None else os.environ
    for key in (ENV_API_KEY, ENV_API_SECRET, ENV_SELLER_ID, ENV_STAGE):
        if key in env and env[key]:
            values.setdefault(key, env[key])

    missing = [k for k in (ENV_API_KEY, ENV_API_SECRET, ENV_SELLER_ID) if not values.get(k, "").strip()]
    if missing:
        where = env_file or "Hermes profil .env dosyasi"
        raise ConfigError(
            "Trendyol kimlik bilgileri eksik: " + ", ".join(missing) + ". "
            f"Su dosyaya ekleyin: {where}\n"
            f"  {ENV_API_KEY}=...\n  {ENV_API_SECRET}=...\n  {ENV_SELLER_ID}=...\n"
            "Degerler Trendyol Satici Paneli > Hesap Bilgileri > Entegrasyon Bilgileri "
            "altindadir (yalniz yetkili/master kullanici gorur). Bu asistana degerleri "
            "sohbette YAZMAYIN; dosyaya koyun."
        )
    seller_id = values[ENV_SELLER_ID].strip()
    if not seller_id.isdigit():
        raise ConfigError(f"{ENV_SELLER_ID} sayisal olmali (satici/magaza ID), alinan: {seller_id!r}")
    stage = values.get(ENV_STAGE, "").strip().lower() in {"1", "true", "yes", "stage"}
    return TrendyolConfig(values[ENV_API_KEY].strip(), values[ENV_API_SECRET].strip(), seller_id, stage)


# --------------------------------------------------------------------------- dates

def _istanbul_tz():
    try:
        from zoneinfo import ZoneInfo

        return ZoneInfo("Europe/Istanbul")
    except Exception:  # tzdata missing -> Turkey is fixed UTC+3 since 2016
        return timezone(timedelta(hours=3))


def parse_date(value: str, end_of_day: bool = False) -> int:
    """'YYYY-MM-DD' in Istanbul local time -> epoch milliseconds (UTC)."""
    try:
        day = datetime.strptime(value.strip(), "%Y-%m-%d")
    except ValueError as exc:
        raise ValueError(f"Tarih 'YYYY-AA-GG' bicimde olmali, alinan: {value!r}") from exc
    if end_of_day:
        day = day + timedelta(days=1) - timedelta(milliseconds=1)
    return int(day.replace(tzinfo=_istanbul_tz()).timestamp() * 1000)


def chunk_range(start_ms: int, end_ms: int, max_days: int) -> List[tuple[int, int]]:
    """Split [start, end] into consecutive windows no longer than ``max_days``."""
    if end_ms < start_ms:
        raise ValueError("Bitis tarihi baslangictan once olamaz")
    step = max_days * 24 * 3600 * 1000
    chunks, cur = [], start_ms
    while cur <= end_ms:
        nxt = min(cur + step - 1, end_ms)
        chunks.append((cur, nxt))
        cur = nxt + 1
    return chunks


def _assert_window(start_ms: int, end_ms: int, max_days: int, what: str) -> None:
    if end_ms < start_ms:
        raise ValueError("Bitis tarihi baslangictan once olamaz")
    if end_ms - start_ms > max_days * 24 * 3600 * 1000:
        raise ValueError(f"{what} icin tarih araligi en fazla {max_days} gun olabilir; araligi bolun")


# --------------------------------------------------------------------------- client

class TrendyolClient:
    def __init__(
        self,
        cfg: TrendyolConfig,
        transport: Optional[httpx.BaseTransport] = None,
        sleep: Callable[[float], None] = time.sleep,
        min_interval: float = 0.25,  # 4 req/s -> 40 per 10 s, under the 50 cap
        timeout: float = 30.0,
    ):
        self.cfg = cfg
        token = base64.b64encode(f"{cfg.api_key}:{cfg.api_secret}".encode()).decode()
        self._client = httpx.Client(
            base_url=cfg.base_url,
            headers={
                "Authorization": f"Basic {token}",
                "User-Agent": f"{cfg.seller_id} - SelfIntegration",
                "Accept": "application/json",
            },
            timeout=timeout,
            transport=transport,
        )
        self._sleep = sleep
        self._min_interval = min_interval
        self._last_call = 0.0

    def close(self) -> None:
        self._client.close()

    # -- transport -----------------------------------------------------------

    def _throttle(self) -> None:
        wait = self._min_interval - (time.monotonic() - self._last_call)
        if wait > 0:
            self._sleep(wait)
        self._last_call = time.monotonic()

    def _get(self, path: str, params: Dict[str, Any], retries: int = 3) -> Dict[str, Any]:
        clean = {k: v for k, v in params.items() if v is not None and v != ""}
        for attempt in range(retries + 1):
            self._throttle()
            resp = self._client.get(path, params=clean)
            if resp.status_code == 429 and attempt < retries:
                retry_after = resp.headers.get("Retry-After")
                self._sleep(float(retry_after) if retry_after and retry_after.isdigit() else 2.0 * (attempt + 1))
                continue
            if resp.status_code == 401:
                raise AuthError(
                    "Trendyol 401: API Key/Secret hatali ya da PROD/STAGE ortami karisti. "
                    "Entegrasyon Bilgileri sayfasindan degerleri yeniden kontrol edin."
                )
            if resp.status_code == 403:
                raise ApiError(403, "Erisim reddedildi (User-Agent/yetki). " + resp.text, path)
            if resp.status_code >= 400:
                raise ApiError(resp.status_code, resp.text, path)
            return resp.json()
        raise ApiError(429, "Rate limit asildi, yeniden denemeler tukendi", path)

    # -- endpoints (all GET) ---------------------------------------------------

    def orders(self, start_ms: int, end_ms: int, status: Optional[str] = None,
               page: int = 0, size: int = 200, order_by: str = "CreatedDate") -> Dict[str, Any]:
        _assert_window(start_ms, end_ms, ORDERS_MAX_DAYS, "Siparisler")
        return self._get(f"/order/sellers/{self.cfg.seller_id}/orders", {
            "startDate": start_ms, "endDate": end_ms, "status": status,
            "page": max(0, page), "size": max(1, min(int(size), 200)),
            "orderByField": order_by, "orderByDirection": "DESC",
        })

    def claims(self, start_ms: int, end_ms: int, status: Optional[str] = None,
               page: int = 0, size: int = 200) -> Dict[str, Any]:
        _assert_window(start_ms, end_ms, ORDERS_MAX_DAYS, "Iadeler")
        return self._get(f"/order/sellers/{self.cfg.seller_id}/claims", {
            "startDate": start_ms, "endDate": end_ms, "claimItemStatus": status,
            "page": max(0, page), "size": max(1, min(int(size), 200)),
        })

    def settlements(self, start_ms: int, end_ms: int, transaction_types: str = DEFAULT_SETTLEMENT_TYPES,
                    page: int = 0, size: int = 500) -> Dict[str, Any]:
        _assert_window(start_ms, end_ms, FINANCE_MAX_DAYS, "Hakedis (settlements)")
        return self._get(f"/finance/che/sellers/{self.cfg.seller_id}/settlements", {
            "startDate": start_ms, "endDate": end_ms, "transactionTypes": transaction_types,
            "page": max(0, page), "size": 1000 if int(size) > 500 else 500,
        })

    def other_financials(self, start_ms: int, end_ms: int, transaction_types: str,
                         page: int = 0, size: int = 500) -> Dict[str, Any]:
        _assert_window(start_ms, end_ms, FINANCE_MAX_DAYS, "Diger finansal kayitlar")
        return self._get(f"/finance/che/sellers/{self.cfg.seller_id}/otherfinancials", {
            "startDate": start_ms, "endDate": end_ms, "transactionTypes": transaction_types,
            "page": max(0, page), "size": 1000 if int(size) > 500 else 500,
        })

    def approved_products(self, page: int = 0, size: int = 100, status: Optional[str] = None,
                          barcode: Optional[str] = None, next_page_token: Optional[str] = None) -> Dict[str, Any]:
        size = max(1, min(int(size), 100))
        if next_page_token is None and (page + 1) * size > 10_000:
            raise ValueError("page x size 10.000'i asamaz; nextPageToken kullanin")
        return self._get(f"/product/sellers/{self.cfg.seller_id}/products/approved", {
            "page": max(0, page), "size": size, "status": status,
            "barcode": barcode, "nextPageToken": next_page_token,
        })

    # -- convenience --------------------------------------------------------------

    def iter_orders(self, start_ms: int, end_ms: int, max_pages_per_chunk: int = 25) -> Iterable[Dict[str, Any]]:
        """Every package in the window, PII-stripped, across chunks and pages.

        Yields dicts; the final yielded item may be a ``{"_truncated": True, ...}``
        marker when a chunk had more pages than ``max_pages_per_chunk`` - the
        caller must surface that rather than pretend the total is complete.
        """
        for s, e in chunk_range(start_ms, end_ms, ORDERS_MAX_DAYS):
            page = 0
            while True:
                data = self.orders(s, e, page=page, size=200)
                for pkg in data.get("content", []) or []:
                    yield strip_order_pii(pkg)
                total_pages = int(data.get("totalPages") or 0)
                page += 1
                if page >= total_pages:
                    break
                if page >= max_pages_per_chunk:
                    yield {"_truncated": True, "chunk_start_ms": s, "chunk_end_ms": e,
                           "pages_read": page, "total_pages": total_pages}
                    break

    def iter_claims(self, start_ms: int, end_ms: int, max_pages_per_chunk: int = 25) -> Iterable[Dict[str, Any]]:
        for s, e in chunk_range(start_ms, end_ms, ORDERS_MAX_DAYS):
            page = 0
            while True:
                data = self.claims(s, e, page=page, size=200)
                for claim in data.get("content", []) or []:
                    yield claim
                total_pages = int(data.get("totalPages") or 0)
                page += 1
                if page >= total_pages or page >= max_pages_per_chunk:
                    break


# --------------------------------------------------------------------------- shaping

def strip_order_pii(pkg: Dict[str, Any]) -> Dict[str, Any]:
    """Return a copy of an order package without buyer-identifying fields."""
    return {k: v for k, v in pkg.items() if k not in _PII_FIELDS and not k.startswith("customer")}


def _num(value: Any) -> float:
    try:
        return float(value or 0)
    except (TypeError, ValueError):
        return 0.0


def summarize_sales(packages: Iterable[Dict[str, Any]], claims: Iterable[Dict[str, Any]] = ()) -> Dict[str, Any]:
    """Per-barcode sales table from order packages plus return counts from claims.

    Revenue here is an *estimate* from order lines (``amount`` minus the seller
    funded ``discount``); the authoritative number is the settlements feed,
    which nets out commission. ``tyDiscount`` is Trendyol-funded and therefore
    reported separately, not subtracted.
    """
    rows: Dict[str, Dict[str, Any]] = {}
    truncated: List[Dict[str, Any]] = []
    status_counts: Dict[str, int] = {}
    order_numbers: set = set()

    def row(barcode: str, name: str) -> Dict[str, Any]:
        return rows.setdefault(barcode, {
            "barcode": barcode, "productName": name, "orders": 0, "units": 0,
            "gross": 0.0, "seller_discount": 0.0, "ty_discount": 0.0,
            "cancelled_units": 0, "returned_units": 0, "claim_items": 0,
        })

    for pkg in packages:
        if pkg.get("_truncated"):
            truncated.append(pkg)
            continue
        status = str(pkg.get("status") or "")
        status_counts[status] = status_counts.get(status, 0) + 1
        order_numbers.add(pkg.get("orderNumber"))
        seen_in_pkg: set = set()
        for line in pkg.get("lines", []) or []:
            barcode = str(line.get("barcode") or line.get("sku") or "?")
            r = row(barcode, str(line.get("productName") or ""))
            qty = int(_num(line.get("quantity")) or 0)
            if status in NON_REVENUE_STATUSES:
                key = "returned_units" if status == "Returned" else "cancelled_units"
                r[key] += qty
                continue
            r["units"] += qty
            r["gross"] += _num(line.get("amount")) or _num(line.get("price")) * qty
            r["seller_discount"] += _num(line.get("discount"))
            r["ty_discount"] += _num(line.get("tyDiscount"))
            if barcode not in seen_in_pkg:
                r["orders"] += 1
                seen_in_pkg.add(barcode)

    claim_total = 0
    for claim in claims:
        for item in claim.get("items", []) or []:
            barcode = str(((item.get("orderLine") or {}).get("barcode")) or "?")
            n = len(item.get("claimItems", []) or []) or 1
            claim_total += n
            row(barcode, str((item.get("orderLine") or {}).get("productName") or ""))["claim_items"] += n

    table = []
    for r in rows.values():
        r["net_estimate"] = round(r["gross"] - r["seller_discount"], 2)
        r["gross"] = round(r["gross"], 2)
        r["seller_discount"] = round(r["seller_discount"], 2)
        r["ty_discount"] = round(r["ty_discount"], 2)
        sold = r["units"]
        r["return_rate"] = round(r["claim_items"] / sold, 3) if sold else None
        table.append(r)
    table.sort(key=lambda x: x["net_estimate"], reverse=True)

    return {
        "products": table,
        "totals": {
            "packages": sum(status_counts.values()),
            "orders": len(order_numbers - {None}),
            "units": sum(r["units"] for r in table),
            "gross": round(sum(r["gross"] for r in table), 2),
            "net_estimate": round(sum(r["net_estimate"] for r in table), 2),
            "claim_items": claim_total,
        },
        "status_counts": status_counts,
        "truncated_chunks": truncated,
        "note": (
            "net_estimate = siparis satirlari (amount - satici indirimi); komisyon dusulmemistir. "
            "Kesin gelir icin trendyol_settlements kullanin. Alici kisisel verisi kaldirildi."
        ),
    }
