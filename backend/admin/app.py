import ipaddress
import os
import sys
from pathlib import Path

from dotenv import load_dotenv
from flask import Flask

BACKEND_ROOT = Path(__file__).parent.parent
load_dotenv(BACKEND_ROOT / ".env")
sys.path.insert(0, str(BACKEND_ROOT))

from admin.routes.news import bp as news_bp
from admin.routes.pipeline import bp as pipeline_bp
from admin.routes.settings import bp as settings_bp
from admin.routes.stats import bp as stats_bp


def _app_version() -> str | None:
    """Read the mobile app version from frontend/pubspec.yaml (e.g. 1.1.2+22)."""
    pubspec = BACKEND_ROOT.parent / "frontend" / "pubspec.yaml"
    try:
        for line in pubspec.read_text(encoding="utf-8").splitlines():
            if line.startswith("version:"):
                return line.split(":", 1)[1].strip()
    except OSError:
        pass
    return None


def _last_deploy() -> str | None:
    """Date of the last commit on origin/deployment — deploy.yml runs on push
    there, so it approximates the last production deploy. Reflects the last
    fetched state of the branch."""
    import subprocess
    try:
        result = subprocess.run(
            ["git", "log", "-1", "--format=%cd", "--date=format:%d.%m.%Y %H:%M",
             "origin/deployment"],
            cwd=str(BACKEND_ROOT.parent),
            capture_output=True, text=True, timeout=5,
        )
        out = result.stdout.strip()
        return out or None
    except (OSError, subprocess.SubprocessError):
        return None


_LOOPBACK_HOSTS = ("localhost", "127.0.0.1", "::1")
_LOOPBACK_ADDRS = ("127.0.0.1", "::1")
# Tailscale hands every node an address out of the 100.64.0.0/10 CGNAT range.
_TAILNET = ipaddress.ip_network("100.64.0.0/10")


def _expose_to_tailnet() -> bool:
    """Opt-in. The default stays loopback-only so nothing is exposed by accident."""
    return os.environ.get("ADMIN_ALLOW_TAILNET", "").lower() == "true"


def _allowed_hosts() -> tuple[str, ...]:
    """Host header allowlist. Stays explicit even when exposed: a wildcard would
    throw away the DNS-rebinding protection, whereas naming the tailnet host does
    not -- an attacker-owned domain still fails to match."""
    extra = os.environ.get("ADMIN_ALLOWED_HOSTS", "")
    return _LOOPBACK_HOSTS + tuple(
        h.strip().lower() for h in extra.split(",") if h.strip()
    )


def _peer_allowed(addr: str) -> bool:
    """Loopback always; tailnet peers only when explicitly enabled. Without this
    range check, binding off loopback would let any LAN host reach a panel that
    has no authentication at all."""
    # Normalize IPv4-mapped IPv6 (e.g. '::ffff:127.0.0.1') from dual-stack binds.
    if addr.startswith("::ffff:"):
        addr = addr[len("::ffff:"):]
    if addr in _LOOPBACK_ADDRS:
        return True
    if not _expose_to_tailnet():
        return False
    try:
        return ipaddress.ip_address(addr) in _TAILNET
    except ValueError:
        return False


def create_app() -> Flask:
    app = Flask(__name__, template_folder="templates", static_folder="static")
    app.config["MAX_CONTENT_LENGTH"] = 10 * 1024 * 1024
    app.secret_key = os.environ.get("FLASK_SECRET_KEY") or os.urandom(24)

    app.register_blueprint(news_bp)
    app.register_blueprint(pipeline_bp)
    app.register_blueprint(settings_bp)
    app.register_blueprint(stats_bp)

    app_version = _app_version()
    last_deploy = _last_deploy()

    @app.context_processor
    def inject_meta():
        return {"app_version": app_version, "last_deploy": last_deploy}

    @app.before_request
    def guard():
        from flask import request
        # Flask's loopback bind is not sufficient against DNS rebinding: the
        # TCP peer can still be local while the browser sends an attacker-owned
        # Host header. Only accept the hostnames this local tool is meant for.
        host = request.host.split(":", 1)[0].strip("[]").lower()
        if host not in _allowed_hosts():
            return "Forbidden", 403
        # Reject cross-origin requests (CSRF). State-changing pipeline runs use
        # POST; the browser-set Sec-Fetch-Site header adds another boundary.
        # A browser cannot forge
        # this header, so we only ALLOW values that mean "from our own page":
        # 'same-origin' (fetch/EventSource) and 'none' (address-bar navigation).
        # 'same-site' (another localhost origin) and 'cross-site' are blocked.
        # Absent header (curl / non-browser) is allowed since it can't be set by
        # a hostile page anyway, and the loopback check below still applies.
        fetch_site = request.headers.get("Sec-Fetch-Site")
        if fetch_site is not None and fetch_site not in ("same-origin", "none"):
            return "Forbidden", 403
        # Loopback by default; tailnet peers only when ADMIN_ALLOW_TAILNET=true.
        if not _peer_allowed(request.remote_addr or ""):
            return "Forbidden", 403

    return app


if __name__ == "__main__":
    debug = os.environ.get("FLASK_DEBUG", "false").lower() == "true"
    # Default bind stays loopback. Point ADMIN_BIND_HOST at the tailnet address
    # rather than 0.0.0.0 so the panel never listens on the university LAN.
    host = os.environ.get("ADMIN_BIND_HOST", "127.0.0.1")
    create_app().run(debug=debug, host=host, port=5050)
