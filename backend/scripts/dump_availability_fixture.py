"""Zrzuca stan produkcji do fixture'u używanego przez testy.

Jeden snapshot obsługuje dwa zestawy testów, które muszą się zgadzać:
  • frontend/test/program_availability_test.dart — kaskada formularza,
  • backend/structure_check/test_structure_check.py — strażnik nazw.

Uruchomienie (z katalogu backend/):
    .venv/bin/python scripts/dump_availability_fixture.py

Odświeżaj po zmianie oferty uczelni — testy sprawdzają realne dane, więc
snapshot jest jednocześnie migawką tego, co widzą studenci.
"""

import json
import os
import sys

from dotenv import load_dotenv
from supabase import create_client

BACKEND_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, BACKEND_DIR)
load_dotenv(os.path.join(BACKEND_DIR, ".env"))

OUTPUT = os.path.join(
    BACKEND_DIR, "..", "frontend", "test", "fixtures", "availability_snapshot.json"
)


def _resolve_env_mode() -> str:
    override = os.environ.get("PLANPM_ENV")
    if override in ("prod", "test"):
        return override
    try:
        return open(os.path.join(BACKEND_DIR, ".env_mode")).read().strip()
    except OSError:
        return "prod"


def main() -> None:
    prefix = "TEST_" if _resolve_env_mode() == "test" else ""
    url = os.environ.get(f"{prefix}SUPABASE_URL")
    key = os.environ.get(f"{prefix}SUPABASE_SERVICE_KEY") or os.environ.get(
        f"{prefix}SUPABASE_KEY"
    )
    if not url or not key:
        raise SystemExit("Brak SUPABASE_URL lub klucza w zmiennych środowiskowych.")

    db = create_client(url, key)
    structure = db.table("v_academic_structure").select("*").execute().data

    rows, start = [], 0
    while True:
        page = (
            db.table("v_unique_groups")
            .select("group,program_name,year,program_type,degree_level")
            .range(start, start + 999)
            .execute()
            .data
        )
        rows += page
        if len(page) < 1000:
            break
        start += 1000

    programs = sorted(
        {(r["program_name"], r["year"], r["program_type"], r["degree_level"]) for r in rows}
    )

    # Grupy per plan — testy klasyfikacji (obieralne vs grupy rocznika) muszą
    # widzieć realne kody, a nie wymyślone.
    groups: dict[str, list[str]] = {}
    for r in rows:
        key = f"{r['program_name']}|{r['year']}|{r['program_type']}|{r['degree_level']}"
        groups.setdefault(key, []).append(r["group"])
    groups = {k: sorted(set(v)) for k, v in sorted(groups.items())}
    snapshot = {
        "_comment": (
            "Snapshot produkcji: v_academic_structure + distinct v_unique_groups. "
            "Regeneracja: backend/scripts/dump_availability_fixture.py"
        ),
        "structure": [
            {
                "faculty": s["faculty_name"],
                "degreeCourse": s["degree_course_name"],
                "specialisation": s["specialisation_name"],
            }
            for s in sorted(
                structure,
                key=lambda s: (
                    s["faculty_name"],
                    s["degree_course_name"],
                    s["specialisation_name"] or "",
                ),
            )
        ],
        "groups": groups,
        "programs": [
            {
                "programName": p[0],
                "year": p[1],
                "programType": p[2],
                "degreeLevel": p[3],
            }
            for p in programs
        ],
    }

    with open(OUTPUT, "w", encoding="utf-8") as f:
        json.dump(snapshot, f, ensure_ascii=False, indent=2)
        f.write("\n")
    print(
        f"Zapisano {os.path.normpath(OUTPUT)}: "
        f"{len(snapshot['structure'])} węzłów struktury, {len(snapshot['programs'])} planów, "
        f"{sum(len(v) for v in groups.values())} przypisań grup"
    )


if __name__ == "__main__":
    main()
