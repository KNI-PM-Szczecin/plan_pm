"""
plan-pm MCP server — narzędzia do zarządzania backendem przez agenta.

Uruchomienie:
    python -m mcp_server.server
"""

import os
import subprocess
import sys
from pathlib import Path

from dotenv import load_dotenv
from fastmcp import FastMCP

BACKEND_ROOT = Path(__file__).parent.parent
REPO_ROOT = BACKEND_ROOT.parent

load_dotenv(BACKEND_ROOT / ".env")
sys.path.insert(0, str(BACKEND_ROOT))

mcp = FastMCP("plan-pm-backend")

STEP_COMMANDS = {
    "mapper":    [sys.executable, "-c", "from mapper import Mapper; Mapper(output='./output/mapper.json').run(minID=0, maxID=600)"],
    "scrapper":  [sys.executable, "-c", "from scrapper import HttpScrapper; HttpScrapper(input='./output/mapper.json', output='./output/scrapper.json').run()"],
    "parser":    [sys.executable, "-c", "from parser import Parser; Parser(input='scrapper.json').run()"],
    "json2db":   [sys.executable, "-c", "from json2db import json2db; json2db(input='./output/parser.json', clear=True).run()"],
    "structure": [sys.executable, "-m", "structure_updater.structure_updater", "--source", "web"],
}


def _run(cmd: list[str]) -> str:
    result = subprocess.run(cmd, capture_output=True, text=True, cwd=str(BACKEND_ROOT))
    out = (result.stdout + result.stderr).strip()
    return out + f"\n[exit {result.returncode}]"


def _get_db():
    from supabase import create_client
    mode_file = BACKEND_ROOT / ".env_mode"
    prefix = "TEST_" if mode_file.exists() and mode_file.read_text().strip() == "test" else ""
    return create_client(os.environ[f"{prefix}SUPABASE_URL"], os.environ[f"{prefix}SUPABASE_SERVICE_KEY"])


# ── Pipeline tools ────────────────────────────────────────────────────────────

@mcp.tool()
def run_pipeline_step(step: str) -> str:
    """
    Uruchamia jeden krok pipeline'u plan_pm.

    Dostępne kroki: mapper, scrapper, parser, json2db, structure
    """
    if step not in STEP_COMMANDS:
        return f"Nieznany krok: {step}. Dostępne: {', '.join(STEP_COMMANDS)}"
    return _run(STEP_COMMANDS[step])


@mcp.tool()
def run_full_pipeline() -> str:
    """Uruchamia pełny pipeline: mapper → scrapper → parser → json2db."""
    return _run([sys.executable, "main.py"])


@mcp.tool()
def get_logs(module: str, lines: int = 50) -> str:
    """
    Zwraca ostatnie N linii logu danego modułu.

    Dostępne moduły: mapper, http_scrapper, scrapper, structure_updater
    """
    allowed = {"mapper", "http_scrapper", "scrapper", "structure_updater"}
    if module not in allowed:
        return f"Nieznany moduł: {module}. Dostępne: {', '.join(allowed)}"
    log_path = BACKEND_ROOT / "logs" / f"{module}.log"
    if not log_path.exists():
        return f"Brak pliku logu: {log_path}"
    all_lines = log_path.read_text(errors="replace").splitlines()
    return "\n".join(all_lines[-lines:])


# ── News tools ────────────────────────────────────────────────────────────────

@mcp.tool()
def list_news() -> list[dict]:
    """Zwraca listę wszystkich newsów (id, title, message_type, created_at)."""
    db = _get_db()
    rows = db.table("news").select("id, title, message_type, created_at").order("created_at", desc=True).execute().data
    return rows


@mcp.tool()
def create_news(title: str, content: str, message_type: str = "info") -> dict:
    """
    Tworzy nowy news w Supabase.

    message_type: 'info' | 'warning' | 'alert'
    """
    if message_type not in ("info", "warning", "alert"):
        return {"error": f"Nieprawidłowy typ: {message_type}. Użyj: info, warning, alert"}
    db = _get_db()
    result = db.table("news").insert({
        "title": title,
        "content": content,
        "message_type": message_type,
    }).execute()
    return result.data[0] if result.data else {"error": "Brak danych w odpowiedzi"}


@mcp.tool()
def delete_news(post_id: str) -> str:
    """Usuwa news o podanym UUID."""
    db = _get_db()
    db.table("news").delete().eq("id", post_id).execute()
    return f"Usunięto post {post_id}"


# ── Environment tools ─────────────────────────────────────────────────────────

@mcp.tool()
def get_env_mode() -> str:
    """Zwraca aktualny tryb środowiska: 'prod' lub 'test'."""
    path = BACKEND_ROOT / ".env_mode"
    return path.read_text().strip() if path.exists() else "prod"


@mcp.tool()
def set_env_mode(mode: str) -> str:
    """
    Przełącza środowisko między 'prod' a 'test'.
    Wywołuje scripts/switch_env.py który aktualizuje backend i frontend.
    """
    if mode not in ("prod", "test"):
        return f"Nieprawidłowy tryb: {mode}. Użyj: prod lub test"
    result = subprocess.run(
        [sys.executable, "scripts/switch_env.py", mode],
        capture_output=True, text=True, cwd=str(REPO_ROOT),
    )
    return result.stdout.strip() or f"Przestawiono na: {mode}"


if __name__ == "__main__":
    mcp.run()
