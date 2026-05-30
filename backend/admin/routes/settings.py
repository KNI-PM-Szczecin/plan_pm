import subprocess
import sys
from pathlib import Path

from flask import Blueprint, redirect, request

from admin.db import get_env_mode

REPO_ROOT = Path(__file__).parent.parent.parent.parent

bp = Blueprint("settings", __name__)


@bp.route("/settings/toggle-env", methods=["POST"])
def toggle_env():
    new_mode = "test" if get_env_mode() == "prod" else "prod"
    subprocess.run(
        [sys.executable, "scripts/switch_env.py", new_mode],
        cwd=str(REPO_ROOT),
    )
    return redirect(request.referrer or "/")
