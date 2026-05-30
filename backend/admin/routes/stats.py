import datetime
import logging
from pathlib import Path

from flask import Blueprint, render_template, jsonify
from google.oauth2 import service_account
from googleapiclient.discovery import build

from admin.db import get_env_mode

bp = Blueprint("stats", __name__)
logger = logging.getLogger(__name__)

BACKEND_ROOT = Path(__file__).parent.parent.parent
PROJECT_ROOT = BACKEND_ROOT.parent
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


def _credentials():
    if not GOOGLE_KEY_PATH.exists():
        return None
    return service_account.Credentials.from_service_account_file(
        str(GOOGLE_KEY_PATH), scopes=SCOPES
    )


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
    for r in reviews_data.get("reviews", []):
        comment = r.get("comments", [{}])[0].get("userComment", {})
        rating = comment.get("starRating", 0)
        total_rating += rating
        reviews.append({
            "author": r.get("authorName"),
            "rating": rating,
            "text": comment.get("text"),
            "lastModified": comment.get("lastModified", {}).get("seconds"),
        })
    avg_rating = round(total_rating / len(reviews), 2) if reviews else 0
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
    creds = _credentials()
    if creds is None:
        return jsonify({"error": "Brak klucza Google Play"}), 404

    try:
        publisher = build("androidpublisher", "v3", credentials=creds)
        reporting = build("playdeveloperreporting", "v1beta1", credentials=creds)

        reviews, avg_rating = _fetch_reviews(publisher)
        labels, users, stability, versions = _fetch_crash_vitals(reporting)
        anr_free = _fetch_anr(reporting)
        issues = _fetch_error_issues(reporting)

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
