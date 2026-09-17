"""Guardrail: every published plan must be reachable from the app's dropdowns.

The app has no id linking a student to a plan — it matches `program_name`
against the university structure tree (faculty -> degree course -> specialisation)
and queries with an exact `.eq()`. A plan whose name does not appear anywhere in
that tree is invisible: the cohort simply cannot select it, and nobody finds out
until a student writes in. That is exactly how a doubled space in
"Inżynieria i Bezpieczeństwo  w Transporcie Drogowym" hid a whole year group for
months.

This module reproduces the app's matching rules (frontend/lib/service/
program_availability.dart) and reports the plans that fall outside them. Run it
after every load; it writes to the log and pings Discord when something drifts.
"""

import argparse
import logging
import os

from dotenv import load_dotenv
from supabase import create_client

from notifier import notify_discord
from console_setup import force_utf8_output

force_utf8_output()

load_dotenv(os.path.join(os.path.dirname(__file__), "..", ".env"))

# Keep in sync with _languageTokens in program_availability.dart. Polish is the
# default track, so "POL" never makes a name a separate variant.
LANGUAGE_TOKENS = {"ang", "ang.", "eng", "eng."}

os.makedirs("./logs", exist_ok=True)
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)
logger.propagate = False
logging.getLogger("httpx").setLevel(logging.WARNING)
if not logger.handlers:
    _handler = logging.FileHandler("./logs/structure_check.log", mode="w+", encoding="utf-8")
    _handler.setFormatter(logging.Formatter("%(asctime)s [%(levelname)s] %(message)s"))
    logger.addHandler(_handler)


def _resolve_env_mode() -> str:
    # PLANPM_ENV overrides the global .env_mode file for a single run.
    override = os.environ.get("PLANPM_ENV")
    if override in ("prod", "test"):
        return override
    path = os.path.join(os.path.dirname(__file__), "..", ".env_mode")
    try:
        return open(path).read().strip()
    except OSError:
        return "prod"


def normalize_name(name: str) -> str:
    """Collapse whitespace and case — the app compares names this way."""
    return " ".join(name.replace("\xa0", " ").split()).casefold()


def strip_language_suffix(name: str) -> str:
    """Drop a trailing language marker: "Transport Morski ang." -> base name."""
    parts = name.replace("\xa0", " ").split()
    if len(parts) > 1 and parts[-1].casefold() in LANGUAGE_TOKENS:
        return " ".join(parts[:-1])
    return " ".join(parts)


def find_unmatched(program_names: list[str], structure_names: list[str]) -> list[str]:
    """Plan names with no node in the structure tree — invisible in the app."""
    known = {normalize_name(name) for name in structure_names if name}
    unmatched = {
        name
        for name in program_names
        if normalize_name(strip_language_suffix(name)) not in known
    }
    return sorted(unmatched)


def fetch_state(db) -> tuple[list[str], list[str]]:
    """Plan names that have groups, and every name in the structure tree."""
    program_names: list[str] = []
    start = 0
    while True:
        page = (
            db.table("v_unique_groups")
            .select("program_name")
            .range(start, start + 999)
            .execute()
            .data
        )
        program_names += [row["program_name"] for row in page]
        if len(page) < 1000:
            break
        start += 1000

    structure = db.table("v_academic_structure").select("*").execute().data
    structure_names = [row["degree_course_name"] for row in structure]
    structure_names += [
        row["specialisation_name"] for row in structure if row["specialisation_name"]
    ]
    return sorted(set(program_names)), structure_names


def check(db, notify: bool = True) -> list[str]:
    """Return plan names unreachable from the app; report them when notify=True."""
    program_names, structure_names = fetch_state(db)
    unmatched = find_unmatched(program_names, structure_names)

    logger.info(
        f"Sprawdzono {len(program_names)} planów wobec {len(set(structure_names))} "
        f"węzłów struktury — niedopasowanych: {len(unmatched)}"
    )
    for name in unmatched:
        logger.warning(f"Plan bez węzła w strukturze: {name!r}")

    if unmatched and notify:
        listing = "\n".join(f"• {name}" for name in unmatched)
        notify_discord(
            "Structure check",
            success=False,
            detail=(
                f"{len(unmatched)} planów nie da się wybrać w aplikacji — nazwa nie "
                f"pasuje do żadnego kierunku ani specjalizacji:\n{listing}\n"
                "Sprawdź, czy structure_updater jest aktualny i czy nazwa toku "
                "na stronie uczelni się nie zmieniła."
            ),
            env=_resolve_env_mode(),
        )
    return unmatched


def client_from_env():
    """Klient Supabase dla środowiska z PLANPM_ENV/.env_mode."""
    prefix = "TEST_" if _resolve_env_mode() == "test" else ""
    url = os.environ.get(f"{prefix}SUPABASE_URL")
    key = os.environ.get(f"{prefix}SUPABASE_SERVICE_KEY") or os.environ.get(
        f"{prefix}SUPABASE_KEY"
    )
    if not url or not key:
        raise RuntimeError("Brak SUPABASE_URL lub klucza w zmiennych środowiskowych.")
    return create_client(url, key)


def check_from_env(notify: bool = True) -> list[str]:
    """Wygodne wejście dla pipeline'u — sam dobiera bazę wg środowiska."""
    return check(client_from_env(), notify=notify)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Sprawdza, czy każdy opublikowany plan da się wybrać w aplikacji"
    )
    parser.add_argument(
        "--no-notify", action="store_true",
        help="Nie wysyłaj powiadomienia na Discorda, tylko wypisz wynik",
    )
    parser.add_argument(
        "--strict", action="store_true",
        help="Zakończ kodem 1, gdy jakikolwiek plan jest nieosiągalny (do CI)",
    )
    args = parser.parse_args()

    try:
        unmatched = check_from_env(notify=not args.no_notify)
    except RuntimeError as exc:
        raise SystemExit(str(exc))
    if unmatched:
        print(f"Plany nieosiągalne z aplikacji ({len(unmatched)}):")
        for name in unmatched:
            print(f"  - {name!r}")
        if args.strict:
            raise SystemExit(1)
    else:
        print("Każdy opublikowany plan da się wybrać w aplikacji.")


if __name__ == "__main__":
    main()
