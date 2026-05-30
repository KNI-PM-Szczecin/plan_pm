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


def create_app() -> Flask:
    app = Flask(__name__, template_folder="templates", static_folder="static")
    app.config["MAX_CONTENT_LENGTH"] = 10 * 1024 * 1024
    app.secret_key = os.environ.get("FLASK_SECRET_KEY") or os.urandom(24)

    app.register_blueprint(news_bp)
    app.register_blueprint(pipeline_bp)
    app.register_blueprint(settings_bp)
    app.register_blueprint(stats_bp)

    @app.before_request
    def check_origin():
        from flask import request
        if request.method == "POST":
            if request.remote_addr not in ("127.0.0.1", "::1"):
                return "Forbidden", 403

    return app


if __name__ == "__main__":
    debug = os.environ.get("FLASK_DEBUG", "false").lower() == "true"
    create_app().run(debug=debug, port=5050)
