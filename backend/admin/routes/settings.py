import subprocess
import sys
from pathlib import Path

from flask import Blueprint, redirect, request, session

from admin.db import get_env_mode

REPO_ROOT = Path(__file__).parent.parent.parent.parent

bp = Blueprint("settings", __name__)


@bp.route("/settings/set-env", methods=["POST"])
def set_env():
    # Target mode comes from the env dropdown; fall back to a toggle.
    new_mode = request.form.get("mode")
    if new_mode not in ("prod", "test"):
        new_mode = "test" if get_env_mode() == "prod" else "prod"

    if new_mode == get_env_mode():
        return redirect(request.referrer or "/")

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
