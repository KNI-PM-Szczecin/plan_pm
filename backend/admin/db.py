import os
from pathlib import Path

from supabase import create_client

BACKEND_ROOT = Path(__file__).parent.parent


def get_env_mode() -> str:
    override = os.environ.get("PLANPM_ENV")
    if override in ("prod", "test"):
        return override
    path = BACKEND_ROOT / ".env_mode"
    mode = path.read_text().strip() if path.exists() else "prod"
    return mode if mode in ("prod", "test") else "prod"


def get_db():
    prefix = "TEST_" if get_env_mode() == "test" else ""
    return create_client(
        os.environ[f"{prefix}SUPABASE_URL"],
        os.environ[f"{prefix}SUPABASE_SERVICE_KEY"],
    )
