import subprocess
import sys
from pathlib import Path

from flask import Blueprint, redirect, request, session

from admin.db import get_env_mode

REPO_ROOT = Path(__file__).parent.parent.parent.parent

bp = Blueprint("settings", __name__)


@bp.route("/settings/toggle-env", methods=["POST"])
def toggle_env():
    new_mode = "test" if get_env_mode() == "prod" else "prod"
    try:
        subprocess.run(
            [sys.executable, "scripts/switch_env.py", new_mode],
            cwd=str(REPO_ROOT),
            check=True,
            capture_output=True,
            text=True,
        )
        session["flash"] = f"Przełączono na: {new_mode.upper()}"
    except subprocess.CalledProcessError as e:
        session["flash"] = f"Nie udało się przełączyć środowiska: {e.stderr or e}"
    return redirect(request.referrer or "/")
