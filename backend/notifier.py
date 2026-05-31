"""Discord webhook notifications for destructive backend operations.

Shared by the admin panel and the MCP server. Every notification reports
whether the operation succeeded, when it ran, the mobile app version, and
which environment (prod/test) it targeted. Failures to notify never raise —
notification must not break the operation it reports on.

Webhook URL is read from DISCORD_WEBHOOK_URL in .env (absent = no-op).
"""

import datetime
import json
import os
import urllib.request
from pathlib import Path

BACKEND_ROOT = Path(__file__).parent

_COLOR_OK = 0x2ECC71
_COLOR_FAIL = 0xE74C3C


def _app_version() -> str:
    pubspec = BACKEND_ROOT.parent / "frontend" / "pubspec.yaml"
    try:
        for line in pubspec.read_text(encoding="utf-8").splitlines():
            if line.startswith("version:"):
                return line.split(":", 1)[1].strip()
    except OSError:
        pass
    return "nieznana"


def _env_mode() -> str:
    path = BACKEND_ROOT / ".env_mode"
    return path.read_text().strip() if path.exists() else "prod"


def notify_discord(action: str, success: bool, detail: str = "", env: str | None = None) -> None:
    """Post an embed to the Discord webhook. No-op if the webhook is unset.

    `env` ("prod"/"test") overrides the environment label — pass it when the
    operation targeted a specific DB rather than the global .env_mode.
    """
    url = os.environ.get("DISCORD_WEBHOOK_URL")
    if not url:
        return

    mode = env if env in ("prod", "test") else _env_mode()
    env_label = "PRODUKCJA" if mode == "prod" else "TEST"
    status = "✅ Sukces" if success else "❌ Błąd"
    now = datetime.datetime.now().strftime("%d.%m.%Y %H:%M:%S")

    fields = [
        {"name": "Status", "value": status, "inline": True},
        {"name": "Środowisko", "value": env_label, "inline": True},
        {"name": "Wersja aplikacji", "value": _app_version(), "inline": True},
        {"name": "Czas", "value": now, "inline": False},
    ]
    if detail:
        fields.append({"name": "Szczegóły", "value": detail[:1000], "inline": False})

    payload = {
        "embeds": [{
            "title": f"{status} — {action}",
            "color": _COLOR_OK if success else _COLOR_FAIL,
            "fields": fields,
        }]
    }

    try:
        req = urllib.request.Request(
            url,
            data=json.dumps(payload).encode("utf-8"),
            # Discord rejects requests without a proper User-Agent (403).
            headers={"Content-Type": "application/json", "User-Agent": "PlanPM-Admin/1.0"},
            method="POST",
        )
        urllib.request.urlopen(req, timeout=5)
    except Exception:
        # Notification is best-effort; never break the caller.
        pass
