import base64
import binascii
import datetime
import json
import logging
import os
import time
import urllib.request
from pathlib import Path

from flask import Blueprint, render_template, jsonify

from admin.db import get_env_mode

# google-* and PyJWT power the (optional) store-statistics feature only. They are
# imported lazily inside the functions that need them so a missing/half-installed
# stats dependency degrades the Statistics page instead of crashing the whole
# admin panel (news, pipeline, settings) at import time.

bp = Blueprint("stats", __name__)
logger = logging.getLogger(__name__)

BACKEND_ROOT = Path(__file__).parent.parent.parent
PROJECT_ROOT = BACKEND_ROOT.parent
# Legacy fallback path (the broad deploy key). Prefer GOOGLE_STATS_KEY_B64 in .env.
GOOGLE_KEY_PATH = PROJECT_ROOT / "frontend" / "android" / "planpm_deploy_key.json"
PACKAGE_NAME = "com.piotrwittig.plan_pm"
TZ = {"id": "America/Los_Angeles"}
# Chart window. Wider than a week because Google drops days whose distinct-user
# count is below its privacy threshold, so a 7-day request often yields fewer rows.
TIMELINE_DAYS = 14

# Reviews API (replies, ratings) + Play Developer Reporting API (vitals: crash rate,
# ANR rate, distinct users, error issues) use different scopes — request both.
SCOPES = [
    "https://www.googleapis.com/auth/androidpublisher",
    "https://www.googleapis.com/auth/playdeveloperreporting",
]

PL_MONTHS = ["", "sty", "lut", "mar", "kwi", "maj", "cze",
             "lip", "sie", "wrz", "paź", "lis", "gru"]


def _safe(fn, default):
    """Run a section fetch; on any API error log a concise warning and return default.

    Store APIs (Google Reporting, ASC) return transient 503s routinely — a section
    degrading to its fallback is expected, not an error, so we don't dump a traceback.
    """
    try:
        return fn()
    except Exception as exc:
        logger.warning("Stats section fetch failed (%s); using fallback", exc)
        return default


def _credentials():
    try:
        from google.oauth2 import service_account
    except ImportError:
        logger.warning("google-auth not installed — Google Play stats unavailable")
        return None
    # Preferred: read-only stats service account from .env (base64-encoded JSON).
    b64 = os.environ.get("GOOGLE_STATS_KEY_B64")
    if b64:
        try:
            info = json.loads(base64.b64decode(b64))
            return service_account.Credentials.from_service_account_info(info, scopes=SCOPES)
        except (binascii.Error, ValueError, KeyError):
            logger.exception("GOOGLE_STATS_KEY_B64 is set but invalid")
            return None
    # Fallback: legacy key file on disk.
    if GOOGLE_KEY_PATH.exists():
        return service_account.Credentials.from_service_account_file(
            str(GOOGLE_KEY_PATH), scopes=SCOPES
        )
    return None


def _date_dict_to_date(d: dict) -> datetime.date:
    return datetime.date(d["year"], d["month"], d["day"])


def _date_dict(d: datetime.date) -> dict:
    return {"year": d.year, "month": d.month, "day": d.day, "timeZone": TZ}


def _metric_value(row: dict, name: str):
    """Extract a numeric metric value from a Reporting API timeline row."""
    for m in row.get("metrics", []):
        if m.get("metric") == name:
            dv = m.get("decimalValue", {}).get("value")
            if dv is not None:
                return float(dv)
    return None


def _dimension_value(row: dict, name: str):
    for d in row.get("dimensions", []):
        if d.get("dimension") == name:
            return d.get("stringValue") or d.get("int64Value")
    return None


def _daily_end(metric_set_get) -> datetime.date | None:
    """Latest DAILY freshness date for a metric set (so we never over-query)."""
    descriptor = metric_set_get.execute()
    for f in descriptor.get("freshnessInfo", {}).get("freshnesses", []):
        if f.get("aggregationPeriod") == "DAILY":
            return _date_dict_to_date(f["latestEndTime"])
    return None


def _fetch_reviews(publisher):
    reviews_data = publisher.reviews().list(packageName=PACKAGE_NAME).execute()
    reviews = []
    total_rating = 0
    rated = 0
    for r in reviews_data.get("reviews", []):
        # A review's comments list can contain a developerComment (the reply)
        # alongside/before the userComment — pick the one that is the user's.
        comments = r.get("comments", [])
        comment = next((c["userComment"] for c in comments if "userComment" in c), {})
        rating = comment.get("starRating", 0)
        if rating:
            total_rating += rating
            rated += 1
        reviews.append({
            "author": r.get("authorName"),
            "rating": rating,
            "text": comment.get("text"),
            "lastModified": comment.get("lastModified", {}).get("seconds"),
        })
    avg_rating = round(total_rating / rated, 2) if rated else 0
    return reviews, avg_rating


def _fetch_crash_vitals(reporting):
    """crashRateMetricSet → daily distinctUsers timeline + latest stability + per-version split."""
    metric_set = f"apps/{PACKAGE_NAME}/crashRateMetricSet"
    crashrate = reporting.vitals().crashrate()
    end = _daily_end(crashrate.get(name=metric_set))
    if end is None:
        return [], [], None, []
    start = end - datetime.timedelta(days=TIMELINE_DAYS)
    timeline = {"aggregationPeriod": "DAILY",
                "startTime": _date_dict(start), "endTime": _date_dict(end)}

    # 1) Timeline: distinctUsers per day + crash rate for stability
    res = crashrate.query(name=metric_set, body={
        "timelineSpec": timeline,
        "metrics": ["crashRate", "distinctUsers"],
    }).execute()
    labels, users, latest_crash = [], [], None
    for row in res.get("rows", []):
        day = _date_dict_to_date(row["startTime"])
        labels.append(f"{day.day} {PL_MONTHS[day.month]}")
        u = _metric_value(row, "distinctUsers")
        users.append(int(u) if u is not None else 0)
        cr = _metric_value(row, "crashRate")
        if cr is not None:
            latest_crash = cr
    stability = round((1 - latest_crash) * 100, 2) if latest_crash is not None else None

    # 2) Per-version split for the latest available day
    res_v = crashrate.query(name=metric_set, body={
        "timelineSpec": timeline,
        "dimensions": ["versionCode"],
        "metrics": ["distinctUsers"],
    }).execute()
    by_day: dict[datetime.date, list] = {}
    for row in res_v.get("rows", []):
        day = _date_dict_to_date(row["startTime"])
        version = _dimension_value(row, "versionCode")
        u = _metric_value(row, "distinctUsers")
        if version is None or u is None:
            continue
        by_day.setdefault(day, []).append({"version": str(version), "users": int(u)})
    versions = []
    if by_day:
        latest_day = max(by_day)
        versions = sorted(by_day[latest_day], key=lambda v: v["users"], reverse=True)

    return labels, users, stability, versions


def _fetch_anr(reporting):
    """anrRateMetricSet → latest ANR-free percentage."""
    metric_set = f"apps/{PACKAGE_NAME}/anrRateMetricSet"
    anr = reporting.vitals().anrrate()
    end = _daily_end(anr.get(name=metric_set))
    if end is None:
        return None
    start = end - datetime.timedelta(days=7)
    res = anr.query(name=metric_set, body={
        "timelineSpec": {"aggregationPeriod": "DAILY",
                         "startTime": _date_dict(start), "endTime": _date_dict(end)},
        "metrics": ["anrRate"],
    }).execute()
    latest = None
    for row in res.get("rows", []):
        v = _metric_value(row, "anrRate")
        if v is not None:
            latest = v
    return round((1 - latest) * 100, 2) if latest is not None else None


def _fetch_error_issues(reporting):
    """Top error/crash issues grouped (errorIssues). Empty until crashes occur."""
    res = reporting.vitals().errors().issues().search(
        parent=f"apps/{PACKAGE_NAME}", pageSize=5
    ).execute()
    issues = []
    for it in res.get("errorIssues", []):
        cause = it.get("cause", "")
        location = it.get("location", "")
        title = " · ".join(p for p in (cause, location) if p) or "Nieznany błąd"
        issues.append({
            "title": title,
            "type": it.get("type", ""),
            "count": it.get("errorReportCount", 0),
            "users": it.get("distinctUsers", 0),
        })
    return issues


# ── App Store Connect (iOS) ─────────────────────────────────────────────────
# Read-only key (App Manager + Sales and Reports). Reviews work immediately;
# analytics reports start arriving ~24-48h after the ONGOING report request.
APPLE_API_BASE = "https://api.appstoreconnect.apple.com"


def _apple_token():
    """Sign a short-lived ES256 JWT from the read-only ASC key in .env."""
    try:
        import jwt
    except ImportError:
        logger.warning("PyJWT not installed — App Store stats unavailable")
        return None
    key_id = os.environ.get("APPLE_KEY_ID")
    issuer = os.environ.get("APPLE_ISSUER_ID")
    key_b64 = os.environ.get("APPLE_KEY_B64")
    if not (key_id and issuer and key_b64):
        return None
    try:
        private_key = base64.b64decode(key_b64).decode()
    except (binascii.Error, ValueError):
        logger.exception("APPLE_KEY_B64 is set but invalid")
        return None
    now = int(time.time())
    return jwt.encode(
        {"iss": issuer, "iat": now, "exp": now + 600, "aud": "appstoreconnect-v1"},
        private_key, algorithm="ES256", headers={"kid": key_id, "typ": "JWT"},
    )


def _apple_get(path: str, token: str) -> dict:
    req = urllib.request.Request(
        APPLE_API_BASE + path, headers={"Authorization": f"Bearer {token}"}
    )
    with urllib.request.urlopen(req, timeout=30) as r:
        return json.loads(r.read())


def _fetch_apple_reviews(token: str, app_id: str):
    """Most recent customer reviews + average over the fetched page + total count."""
    data = _apple_get(
        f"/v1/apps/{app_id}/customerReviews?sort=-createdDate&limit=10", token
    )
    reviews, total_rating = [], 0
    for d in data.get("data", []):
        a = d.get("attributes", {})
        rating = a.get("rating", 0)
        total_rating += rating
        reviews.append({
            "author": a.get("reviewerNickname"),
            "rating": rating,
            "title": a.get("title"),
            "text": a.get("body"),
            "territory": a.get("territory"),
            "date": a.get("createdDate"),
        })
    avg = round(total_rating / len(reviews), 2) if reviews else 0
    total = data.get("meta", {}).get("paging", {}).get("total", len(reviews))
    return reviews, avg, total


def _apple_analytics_ready(token: str, app_id: str) -> bool:
    """True once Apple has generated at least one report instance for the app."""
    reqs = _apple_get(f"/v1/apps/{app_id}/analyticsReportRequests", token).get("data", [])
    if not reqs:
        return False
    reports = _apple_get(
        f"/v1/analyticsReportRequests/{reqs[0]['id']}/reports?limit=1", token
    ).get("data", [])
    if not reports:
        return False
    instances = _apple_get(
        f"/v1/analyticsReports/{reports[0]['id']}/instances?limit=1", token
    ).get("data", [])
    return bool(instances)


@bp.route("/api/stats/app-store")
def app_store_stats():
    token = _apple_token()
    if token is None:
        return jsonify({"error": "Brak klucza App Store Connect"}), 404
    app_id = os.environ.get("APPLE_APP_ID", "")

    try:
        reviews, avg, total = _safe(
            lambda: _fetch_apple_reviews(token, app_id), ([], 0, 0))
        analytics_ready = _safe(
            lambda: _apple_analytics_ready(token, app_id), False)
        return jsonify({
            "summary": {"avgRating": avg, "totalReviews": total},
            "reviews": reviews[:5],
            # Analytics download/parse is built once Apple generates the first
            # report (~24-48h after the ONGOING request). Until then: pending.
            "analyticsReady": analytics_ready,
        })
    except Exception:
        logger.exception("App Store stats fetch failed")
        return jsonify({"error": "Nie udało się pobrać danych z App Store Connect."}), 500


@bp.route("/stats")
def index():
    return render_template(
        "stats.html",
        title="Statystyki",
        active="stats",
        env_mode=get_env_mode(),
    )


@bp.route("/api/stats/google-play")
def google_play_stats():
    try:
        from googleapiclient.discovery import build
    except ImportError:
        return jsonify({"error": "Biblioteki Google nie są zainstalowane. Uruchom: uv sync (lub pip install -e .)"}), 503

    creds = _credentials()
    if creds is None:
        return jsonify({"error": "Brak klucza Google Play"}), 404

    try:
        publisher = build("androidpublisher", "v3", credentials=creds)
        reporting = build("playdeveloperreporting", "v1beta1", credentials=creds)

        # Each section is fetched independently — a transient Google error in
        # one (e.g. errorIssues 503) degrades that section to empty instead of
        # failing the whole page.
        reviews, avg_rating = _safe(lambda: _fetch_reviews(publisher), ([], 0))
        labels, users, stability, versions = _safe(
            lambda: _fetch_crash_vitals(reporting), ([], [], None, []))
        anr_free = _safe(lambda: _fetch_anr(reporting), None)
        issues = _safe(lambda: _fetch_error_issues(reporting), [])

        data = {
            "summary": {
                "avgRating": avg_rating,
                "totalReviews": len(reviews),
                "stability": f"{stability}%" if stability is not None else "—",
                "anrFree": f"{anr_free}%" if anr_free is not None else "—",
                "activeUsers": users[-1] if users else 0,
            },
            "labels": labels,
            "datasets": [
                {
                    "label": "Aktywne urządzenia (Android)",
                    "data": users,
                    "borderColor": "#a3e635",
                    "backgroundColor": "rgba(163, 230, 53, 0.1)",
                }
            ],
            "versions": versions,
            "issues": issues,
            "reviews": reviews[:5],
        }
        return jsonify(data)
    except Exception:
        logger.exception("Google Play stats fetch failed")
        return jsonify({"error": "Nie udało się pobrać danych z Google Play."}), 500
