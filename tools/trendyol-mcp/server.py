"""Hermes MCP server (stdio): read-only Trendyol seller data.

Registered with Hermes as a stdio server; it receives ONE non-secret env var,
``TRENDYOL_ENV_FILE`` (path to the profile .env), and reads the API key /
secret / seller id from that file itself. Secrets therefore never enter
config.yaml, process arguments, or this conversation.

Every tool is a GET. There is intentionally no way to change stock, price,
products, orders or claims from here.

stdout is the MCP wire - nothing may print to it; diagnostics go to stderr.
"""

from __future__ import annotations

import functools
import logging
import os
import sys
from typing import Any, Dict, List, Optional

from mcp.server.mcpserver import MCPServer
from mcp.types import ToolAnnotations

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import trendyol_client as tc  # noqa: E402

logging.basicConfig(stream=sys.stderr, level=os.environ.get("TRENDYOL_MCP_LOG", "WARNING"))
log = logging.getLogger("trendyol-mcp")

ENV_FILE = os.environ.get("TRENDYOL_ENV_FILE") or None
# mcp 2.x model fields are snake_case (read_only_hint), not the wire's camelCase.
READ_ONLY = ToolAnnotations(read_only_hint=True, destructive_hint=False, idempotent_hint=True, open_world_hint=True)

# Bulky, analysis-irrelevant keys removed from product payloads unless asked.
_BULKY_KEYS = frozenset({"images", "attributes", "description", "productContentId"})

server = MCPServer(
    name="trendyol",
    instructions=(
        "Trendyol satici hesabinin SALT-OKUNUR verisi. Tarihler 'YYYY-AA-GG' (Istanbul saati), "
        "bitis tarihi dahildir. Siparis/iade uclari tek cagrida en fazla 14 gun, finans uclari 15 gun "
        "kabul eder; daha genis aralik icin trendyol_sales_summary kendisi parcalar. Gelir icin kesin "
        "kaynak trendyol_settlements'tir (komisyon dusulmus); siparis satirlari tahmindir. Alici kisisel "
        "verisi hic dondurulmez. Hicbir arac veri DEGISTIRMEZ; stok/fiyat/reklam islemleri panelden elle yapilir."
    ),
)

_client: Optional[tc.TrendyolClient] = None


def _get_client() -> tc.TrendyolClient:
    global _client
    if _client is None:
        _client = tc.TrendyolClient(tc.load_config(ENV_FILE))
    return _client


def _window(start_date: str, end_date: str) -> tuple[int, int]:
    return tc.parse_date(start_date), tc.parse_date(end_date, end_of_day=True)


def _page_meta(data: Dict[str, Any]) -> Dict[str, Any]:
    return {k: data.get(k) for k in ("page", "size", "totalPages", "totalElements") if k in data}


def _compact(obj: Any) -> Any:
    if isinstance(obj, dict):
        return {k: _compact(v) for k, v in obj.items() if k not in _BULKY_KEYS}
    if isinstance(obj, list):
        return [_compact(v) for v in obj]
    return obj


def _guard(fn):
    """Turn expected failures into a plain ``{"error": ...}`` the model can act on.

    ``functools.wraps`` sets ``__wrapped__`` so ``inspect.signature`` still sees
    the real parameters - without it every tool would advertise an empty schema.
    """

    @functools.wraps(fn)
    def wrapper(*args, **kwargs):
        try:
            return fn(*args, **kwargs)
        except (tc.ConfigError, tc.AuthError, ValueError) as exc:
            return {"error": str(exc)}
        except tc.ApiError as exc:
            return {"error": str(exc), "status": exc.status, "path": exc.path}
        except Exception as exc:  # never leak a traceback onto the wire
            log.exception("tool failure")
            return {"error": f"Beklenmeyen hata: {type(exc).__name__}: {exc}"}

    return wrapper


# --------------------------------------------------------------------------- tools

@server.tool(
    name="trendyol_status",
    description="Baglanti/kimlik durumunu raporlar (degerleri asla dondurmez): kimlik bilgileri tanimli mi, hangi ortam, hangi satici ID.",
    annotations=READ_ONLY,
)
@_guard
def trendyol_status() -> Dict[str, Any]:
    try:
        cfg = tc.load_config(ENV_FILE)
    except tc.ConfigError as exc:
        return {"configured": False, "env_file": ENV_FILE, "how_to_fix": str(exc)}
    return {
        "configured": True,
        "seller_id": cfg.seller_id,
        "environment": "STAGE" if cfg.stage else "PROD",
        "env_file": ENV_FILE,
        "read_only": True,
    }


@server.tool(
    name="trendyol_orders",
    description=(
        "Siparis paketlerini listeler (alici kisisel verisi kaldirilmis). Aralik en fazla 14 gun. "
        "status: Awaiting|Created|Picking|Invoiced|Shipped|Cancelled|Delivered|UnDelivered|Returned|AtCollectionPoint|UnSupplied. "
        "size<=200. Genis aralik icin trendyol_sales_summary kullanin."
    ),
    annotations=READ_ONLY,
)
@_guard
def trendyol_orders(start_date: str, end_date: str, status: Optional[str] = None,
                    page: int = 0, size: int = 200) -> Dict[str, Any]:
    s, e = _window(start_date, end_date)
    data = _get_client().orders(s, e, status=status, page=page, size=size)
    return {**_page_meta(data), "content": [tc.strip_order_pii(p) for p in data.get("content", []) or []]}


@server.tool(
    name="trendyol_claims",
    description=(
        "Iade taleplerini listeler. Aralik en fazla 14 gun. status (claimItemStatus): "
        "Created|WaitingInAction|WaitingFraudCheck|Accepted|Unresolved|Rejected|Cancelled|InAnalysis. size<=200."
    ),
    annotations=READ_ONLY,
)
@_guard
def trendyol_claims(start_date: str, end_date: str, status: Optional[str] = None,
                    page: int = 0, size: int = 200) -> Dict[str, Any]:
    s, e = _window(start_date, end_date)
    data = _get_client().claims(s, e, status=status, page=page, size=size)
    return {**_page_meta(data), "content": data.get("content", []) or []}


@server.tool(
    name="trendyol_settlements",
    description=(
        "Hakedis/finans hareketleri - GELIR ICIN KESIN KAYNAK (komisyon dusulmus sellerRevenue). "
        "Aralik en fazla 15 gun. transaction_types virgullu: Sale,Return,Discount,DiscountCancel,Coupon,CouponCancel,"
        "ProvisionPositive,ProvisionNegative,ManualRefund,ManualRefundCancel,TyDiscount,TyDiscountCancel,TyCoupon,TyCouponCancel,"
        "SellerRevenuePositive,SellerRevenueNegative,CommissionPositive,CommissionNegative,DeliveryFee,DeliveryFeeCancel,PayByLink. size 500|1000."
    ),
    annotations=READ_ONLY,
)
@_guard
def trendyol_settlements(start_date: str, end_date: str, transaction_types: str = tc.DEFAULT_SETTLEMENT_TYPES,
                         page: int = 0, size: int = 500) -> Dict[str, Any]:
    s, e = _window(start_date, end_date)
    data = _get_client().settlements(s, e, transaction_types=transaction_types, page=page, size=size)
    return {**_page_meta(data), "content": data.get("content", []) or []}


@server.tool(
    name="trendyol_other_financials",
    description=(
        "Diger finansal kayitlar (stopaj, avans, havale, fatura kesintileri). Aralik en fazla 15 gun. "
        "transaction_types: Stoppage,CashAdvance,WireTransfer,IncomingTransfer,ReturnInvoice,CommissionAgreementInvoice,PaymentOrder,DeductionInvoices,FinancialItem."
    ),
    annotations=READ_ONLY,
)
@_guard
def trendyol_other_financials(
    start_date: str, end_date: str,
    transaction_types: str = "Stoppage,CashAdvance,WireTransfer,IncomingTransfer,ReturnInvoice,CommissionAgreementInvoice,PaymentOrder,DeductionInvoices",
    page: int = 0, size: int = 500,
) -> Dict[str, Any]:
    s, e = _window(start_date, end_date)
    data = _get_client().other_financials(s, e, transaction_types=transaction_types, page=page, size=size)
    return {**_page_meta(data), "content": data.get("content", []) or []}


@server.tool(
    name="trendyol_products",
    description=(
        "Onayli urunleri listeler (Urun API V2). size<=100, page*size<=10000; daha fazlasi icin next_page_token. "
        "status: archived|blacklisted|locked|onSale. Gorsel/attribute alanlari varsayilan olarak cikarilir (full=true ile dahil)."
    ),
    annotations=READ_ONLY,
)
@_guard
def trendyol_products(page: int = 0, size: int = 100, status: Optional[str] = None, barcode: Optional[str] = None,
                      next_page_token: Optional[str] = None, full: bool = False) -> Dict[str, Any]:
    data = _get_client().approved_products(page=page, size=size, status=status, barcode=barcode,
                                           next_page_token=next_page_token)
    content = data.get("content", []) or []
    return {**_page_meta(data), "nextPageToken": data.get("nextPageToken"),
            "content": content if full else _compact(content)}


@server.tool(
    name="trendyol_sales_summary",
    description=(
        "Reklam butcesi karari icin urun bazli satis tablosu: aralik boyunca TUM siparisleri ve iadeleri "
        "sayfa sayfa ceker (14 gunluk parcalar), barkod bazinda birim, brut, satici indirimi, net tahmin, "
        "iptal/iade adedi ve iade orani hesaplar. En fazla 92 gunluk aralik. Sonuc 'truncated_chunks' bos "
        "degilse toplamlar EKSIKTIR - bunu kullaniciya soyleyin. Gelir tahminidir; kesin rakam settlements'tan."
    ),
    annotations=READ_ONLY,
)
@_guard
def trendyol_sales_summary(start_date: str, end_date: str, max_pages_per_chunk: int = 25) -> Dict[str, Any]:
    s, e = _window(start_date, end_date)
    if e - s > 92 * 24 * 3600 * 1000:
        raise ValueError("Ozet icin aralik en fazla 92 gun olabilir; araligi bolun")
    client = _get_client()
    packages: List[Dict[str, Any]] = list(client.iter_orders(s, e, max_pages_per_chunk=max_pages_per_chunk))
    claims: List[Dict[str, Any]] = list(client.iter_claims(s, e, max_pages_per_chunk=max_pages_per_chunk))
    summary = tc.summarize_sales(packages, claims)
    summary["window"] = {"start_date": start_date, "end_date": end_date, "start_ms": s, "end_ms": e}
    return summary


if __name__ == "__main__":
    server.run(transport="stdio")
