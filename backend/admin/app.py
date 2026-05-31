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
        # Reject cross-site requests (CSRF). This also covers the SSE GET
        # endpoints (/pipeline/run, /pipeline/logs) which can run the pipeline
        # and rewrite the prod DB — EventSource can't carry a CSRF token, so we
        # rely on the browser-set Sec-Fetch-Site header. Absent header (older
        # clients / curl) is allowed; only an explicit cross-site is blocked.
        if request.headers.get("Sec-Fetch-Site") == "cross-site":
            return "Forbidden", 403
        # The admin tool is localhost-only — reject anything off loopback.
        if request.remote_addr not in ("127.0.0.1", "::1"):
            return "Forbidden", 403

    return app


if __name__ == "__main__":
    debug = os.environ.get("FLASK_DEBUG", "false").lower() == "true"
    create_app().run(debug=debug, port=5050)
