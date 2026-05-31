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

from notifier import notify_discord, pipeline_stats_text

# Pipeline steps worth a Discord notification from here. structure_updater
# notifies itself, so it's excluded to avoid duplicate messages.
_DB_STEPS = {"json2db"}

mcp = FastMCP("plan-pm-backend")

STEP_COMMANDS = {
    "mapper":    [sys.executable, "-c", "from mapper import Mapper; Mapper(output='./output/mapper.json').run(minID=0, maxID=600)"],
    "scrapper":  [sys.executable, "-c", "from scrapper import HttpScrapper; HttpScrapper(input='./output/mapper.json', output='./output/scrapper.json').run()"],
    "parser":    [sys.executable, "-c", "from parser import Parser; Parser(input='scrapper.json').run()"],
    "json2db":   [sys.executable, "-c", "from json2db import json2db; json2db(input='./output/parser.json', clear=True).run()"],
    "structure": [sys.executable, "-m", "structure_updater.structure_updater"],
}


def _resolve_mode(env: str | None) -> str:
    """Explicit env arg wins; otherwise fall back to the global .env_mode file."""
    if env in ("prod", "test"):
        return env
    mode_file = BACKEND_ROOT / ".env_mode"
    return mode_file.read_text().strip() if mode_file.exists() else "prod"


# Cap returned subprocess output: a full pipeline emits a lot, and the whole
# string is fed back to the agent as a tool result (context-window cost).
_MAX_OUTPUT_CHARS = 20000


def _run(cmd: list[str], env: str | None = None) -> tuple[str, int]:
    # Propagate the chosen environment to the subprocess via PLANPM_ENV, which
    # json2db / structure_updater / main read in preference to .env_mode.
    # PYTHONUTF8/IOENCODING keep Windows consoles from crashing on emoji output.
    proc_env = dict(os.environ)
    proc_env["PLANPM_ENV"] = _resolve_mode(env)
    proc_env["PYTHONUTF8"] = "1"
    proc_env["PYTHONIOENCODING"] = "utf-8"
    result = subprocess.run(cmd, capture_output=True, text=True,
                            encoding="utf-8", errors="replace",
                            cwd=str(BACKEND_ROOT), env=proc_env)
    out = (result.stdout + result.stderr).strip()
    if len(out) > _MAX_OUTPUT_CHARS:
        out = "…(output obcięty)…\n" + out[-_MAX_OUTPUT_CHARS:]
    return out, result.returncode


def _get_db(env: str | None = None):
    from supabase import create_client
    prefix = "TEST_" if _resolve_mode(env) == "test" else ""
    return create_client(os.environ[f"{prefix}SUPABASE_URL"], os.environ[f"{prefix}SUPABASE_SERVICE_KEY"])


# ── Pipeline tools ────────────────────────────────────────────────────────────

@mcp.tool()
def run_pipeline_step(step: str, env: str = "prod") -> str:
    """
    Uruchamia jeden krok pipeline'u plan_pm.

    Dostępne kroki: mapper, scrapper, parser, json2db, structure
    env: 'prod' (domyślnie) lub 'test' — na którą bazę danych działać.
    """
    if step not in STEP_COMMANDS:
        return f"Nieznany krok: {step}. Dostępne: {', '.join(STEP_COMMANDS)}"
    mode = _resolve_mode(env)
    output, code = _run(STEP_COMMANDS[step], env=mode)
    if step in _DB_STEPS:
        notify_discord(f"Pipeline: {step}", success=(code == 0),
                       detail="źródło: MCP", env=mode, stats=pipeline_stats_text())
    return f"{output}\n[exit {code}]"


@mcp.tool()
def run_full_pipeline(env: str = "prod") -> str:
    """Uruchamia pełny pipeline: mapper → scrapper → parser → json2db.

    env: 'prod' (domyślnie) lub 'test' — na którą bazę danych działać.
    """
    mode = _resolve_mode(env)
    output, code = _run([sys.executable, "main.py"], env=mode)
    notify_discord("Full Pipeline", success=(code == 0),
                   detail="źródło: MCP", env=mode, stats=pipeline_stats_text())
    return f"{output}\n[exit {code}]"


@mcp.tool()
def get_logs(module: str, lines: int = 50) -> str:
    """
    Zwraca ostatnie N linii logu danego modułu.

    Dostępne moduły: mapper, scrapper, json2db, structure_updater
    """
    allowed = {"mapper", "scrapper", "json2db", "structure_updater"}
    if module not in allowed:
        return f"Nieznany moduł: {module}. Dostępne: {', '.join(allowed)}"
    log_path = BACKEND_ROOT / "logs" / f"{module}.log"
    if not log_path.exists():
        return f"Brak pliku logu: {log_path}"
    all_lines = log_path.read_text(errors="replace").splitlines()
    return "\n".join(all_lines[-lines:])


# ── News tools ────────────────────────────────────────────────────────────────

@mcp.tool()
def list_news(env: str = "prod") -> list:
    """Zwraca listę wszystkich newsów (id, title, message_type, created_at).

    env: 'prod' (domyślnie) lub 'test'.
    """
    db = _get_db(env)
    return db.table("news").select("id, title, message_type, created_at").order("created_at", desc=True).execute().data


@mcp.tool()
def create_news(title: str, content: str, message_type: str = "info", env: str = "prod") -> dict:
    """
    Tworzy nowy news w Supabase.

    message_type: 'info' | 'warning' | 'alert'
    env: 'prod' (domyślnie) lub 'test' — do której bazy zapisać.
    """
    if message_type not in ("info", "warning", "alert"):
        return {"error": f"Nieprawidłowy typ: {message_type}. Użyj: info, warning, alert"}
    mode = _resolve_mode(env)
    db = _get_db(mode)
    result = db.table("news").insert({
        "title": title,
        "content": content,
        "message_type": message_type,
    }).execute()
    if result.data:
        notify_discord("Dodano news", success=True, detail=f"{title} (źródło: MCP)", env=mode)
        return result.data[0]  # type: ignore[return-value]
    notify_discord("Dodanie newsa nie powiodło się", success=False,
                   detail=f"{title} (źródło: MCP)", env=mode)
    return {"error": "Brak danych w odpowiedzi"}


@mcp.tool()
def delete_news(post_id: str, env: str = "prod") -> str:
    """Usuwa news o podanym UUID.

    env: 'prod' (domyślnie) lub 'test'.
    """
    mode = _resolve_mode(env)
    db = _get_db(mode)
    result = db.table("news").delete().eq("id", post_id).execute()
    if not result.data:
        return f"Nie znaleziono newsa o id {post_id} — nic nie usunięto."
    notify_discord("Usunięto news", success=True, detail=f"{post_id} (źródło: MCP)", env=mode)
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
        capture_output=True, text=True, encoding="utf-8", errors="replace",
        cwd=str(REPO_ROOT),
    )
    if result.returncode != 0:
        return f"Błąd przełączania na {mode}: {(result.stderr or result.stdout).strip()}"
    return result.stdout.strip() or f"Przestawiono na: {mode}"


if __name__ == "__main__":
    mcp.run()
