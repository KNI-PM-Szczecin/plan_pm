import os
from pathlib import Path

from supabase import create_client

BACKEND_ROOT = Path(__file__).parent.parent


def get_env_mode() -> str:
    path = BACKEND_ROOT / ".env_mode"
    return path.read_text().strip() if path.exists() else "prod"


def get_db():
    prefix = "TEST_" if get_env_mode() == "test" else ""
    return create_client(
        os.environ[f"{prefix}SUPABASE_URL"],
        os.environ[f"{prefix}SUPABASE_SERVICE_KEY"],
    )
