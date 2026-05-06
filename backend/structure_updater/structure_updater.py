import os
import re
import json
import logging
import argparse
import xml.etree.ElementTree as ET
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed

import requests
from dotenv import load_dotenv
from supabase import create_client

load_dotenv(os.path.join(os.path.dirname(__file__), "..", ".env"))

_env_mode_path = os.path.join(os.path.dirname(__file__), "..", ".env_mode")
_prefix = "TEST_" if open(_env_mode_path).read().strip() == "test" else ""

BASE_URL = "https://plany.am.szczecin.pl"
FACULTIES_TABLE_NAME: str = "faculties"
DEGREE_COURSES_TABLE_NAME: str = "degree_courses"
SPECIALISATIONS_TABLE_NAME: str = "specialisations"

os.makedirs("./logs", exist_ok=True)
logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)
if not logger.handlers:
    _handler = logging.FileHandler("./logs/structure_updater.log", mode="w+", encoding="utf-8")
    _handler.setFormatter(logging.Formatter("%(asctime)s [%(levelname)s] %(message)s"))
    logger.addHandler(_handler)


# ── Scraping ──────────────────────────────────────────────────────────────────

def _extract_items(html: str, control_name: str) -> list[dict]:
    """Extract itemsInfo array from a DevExpress listbox init block."""
    marker = f"'{control_name}_DDD_L'"
    idx = html.find(marker)
    if idx == -1:
        return []
    start = html.find("'itemsInfo':[", idx)
    if start == -1:
        return []
    start += len("'itemsInfo':[") - 1  # position of '['
    depth = 0
    for i, ch in enumerate(html[start:], start):
        if ch == '[':
            depth += 1
        elif ch == ']':
            depth -= 1
            if depth == 0:
                raw = html[start:i + 1]
                raw = re.sub(r"'([^'\\]*(?:\\.[^'\\]*)*)'",
                             lambda m: '"' + m.group(1).replace('"', '\\"') + '"',
                             raw)
                items = json.loads(raw)
                return [{'value': x['value'], 'text': ' '.join(x['text'].split())} for x in items if x.get('value')]
    return []


def fetch_structure_from_web() -> list[dict]:
    """Scrape university structure (Wydziały → Kierunki → Specjalności) from the website."""
    session = requests.Session()
    headers = {'X-Requested-With': 'XMLHttpRequest'}

    logger.info("Fetching page")
    page = session.get(f"{BASE_URL}/Plany/ZnajdzTok?Ukryj=True", timeout=30)
    wydzialy = _extract_items(page.text, 'Wydzialy')
    logger.info(f"Found {len(wydzialy)} faculties")

    def fetch_kierunki(wydz: dict) -> tuple[dict, list[dict]]:
        r = session.post(
            f"{BASE_URL}/Plany/ZnajdzTokKierunekCombo",
            data={'wydzialy': wydz['value']},
            headers=headers,
            timeout=30,
        )
        return wydz, _extract_items(r.text, 'Kierunki')

    def fetch_specjalnosci(wydz_value: str, kier: dict) -> tuple[dict, list[str]]:
        r = session.post(
            f"{BASE_URL}/Plany/ZnajdzTokSpecjalnoscCombo",
            data={'wydzialy': wydz_value, 'kierunki': kier['value']},
            headers=headers,
            timeout=30,
        )
        specs = _extract_items(r.text, 'Specjalnosci')
        return kier, [s['text'] for s in specs]

    structure = []

    with ThreadPoolExecutor(max_workers=7) as executor:
        kierunki_futures = {executor.submit(fetch_kierunki, w): w for w in wydzialy}
        wydz_kierunki: dict[str, tuple[dict, list[dict]]] = {}
        for future in as_completed(kierunki_futures):
            wydz, kierunki = future.result()
            wydz_kierunki[wydz['value']] = (wydz, kierunki)
            logger.info(f"  {wydz['text']}: {len(kierunki)} kierunki")

    for wydz_value, (wydz, kierunki) in sorted(wydz_kierunki.items()):
        degree_courses = []

        with ThreadPoolExecutor(max_workers=10) as executor:
            spec_futures = {executor.submit(fetch_specjalnosci, wydz_value, k): k for k in kierunki}
            kier_specs: dict[str, tuple[dict, list[str]]] = {}
            for future in as_completed(spec_futures):
                kier, specs = future.result()
                kier_specs[kier['value']] = (kier, specs)

        for _, (kier, specs) in sorted(kier_specs.items()):
            degree_courses.append({"name": kier['text'], "specialisations": specs})

        structure.append({"name": wydz['text'], "degree_courses": degree_courses})

    return structure


# ── XML fallback ──────────────────────────────────────────────────────────────

def parse_university_structure(xml_path: str = "structure.xml") -> list[dict]:
    root = ET.parse(Path(xml_path)).getroot()
    data: list[dict] = []

    for faculty in root.findall("faculty"):
        faculty_entry: dict = {"name": faculty.get("name", "Unknown faculty"), "degree_courses": []}
        for degree_course in faculty.findall("degree_course"):
            specialisations = [
                s.text.strip()
                for s in degree_course.findall("specialisation")
                if s.text and s.text.strip()
            ]
            faculty_entry["degree_courses"].append(
                {"name": degree_course.get("name", "Unknown degree course"), "specialisations": specialisations}
            )
        data.append(faculty_entry)

    return data


# ── Database ──────────────────────────────────────────────────────────────────

def propagate_structure_to_db(db, structure: list[dict]) -> None:
    # 1 insert — all faculties
    faculty_rows = db.table(FACULTIES_TABLE_NAME).insert(
        [{"name": f["name"]} for f in structure]
    ).execute()

    # flatten degree courses, attaching the returned faculty IDs
    degree_courses_flat = [
        {"name": dc["name"], "faculty_id": row["id"], "specialisations": dc["specialisations"]}
        for faculty, row in zip(structure, faculty_rows.data)
        for dc in faculty["degree_courses"]
    ]

    # 1 insert — all degree courses
    dc_rows = db.table(DEGREE_COURSES_TABLE_NAME).insert(
        [{"name": dc["name"], "faculty_id": dc["faculty_id"]} for dc in degree_courses_flat]
    ).execute()

    # flatten specialisations, attaching the returned degree course IDs
    specialisations_flat = [
        {"name": spec, "degree_course_id": row["id"]}
        for dc, row in zip(degree_courses_flat, dc_rows.data)
        for spec in dc["specialisations"]
    ]

    # 1 insert — all specialisations
    if specialisations_flat:
        db.table(SPECIALISATIONS_TABLE_NAME).insert(specialisations_flat).execute()


def clear_structure_tables(db) -> None:
    db.table(SPECIALISATIONS_TABLE_NAME).delete().gte("id", 0).execute()
    db.table(DEGREE_COURSES_TABLE_NAME).delete().gte("id", 0).execute()
    db.table(FACULTIES_TABLE_NAME).delete().gte("id", 0).execute()


# ── Entry point ───────────────────────────────────────────────────────────────

def main() -> None:
    parser = argparse.ArgumentParser(description="Aktualizacja struktury uczelni w bazie danych")
    parser.add_argument(
        "--source", choices=["web", "xml"], default="web",
        help="Źródło danych: 'web' (scraping, domyślnie) lub 'xml' (plik structure.xml)",
    )
    parser.add_argument(
        "--xml-path", default="structure.xml",
        help="Ścieżka do pliku XML (używane tylko z --source xml)",
    )
    parser.add_argument(
        "--dry-run", action="store_true",
        help="Wyświetl strukturę bez zapisywania do bazy danych",
    )
    args = parser.parse_args()

    logger.info(f"Uruchomiono (source={args.source}, dry_run={args.dry_run})")

    if args.source == "web":
        structure = fetch_structure_from_web()
    else:
        structure = parse_university_structure(args.xml_path)

    total_courses = sum(len(f["degree_courses"]) for f in structure)
    total_specs = sum(len(dc["specialisations"]) for f in structure for dc in f["degree_courses"])
    logger.info(f"Pobrano strukturę: {len(structure)} wydziałów, {total_courses} kierunków, {total_specs} specjalności")

    os.makedirs("./output", exist_ok=True)
    with open("./output/structure_updater.json", "w", encoding="utf-8") as f:
        json.dump(structure, f, ensure_ascii=False, indent=2)
    logger.info("Zapisano strukturę do ./output/structure_updater.json")

    if args.dry_run:
        logger.info("Tryb dry-run — pominięto zapis do bazy danych")
        print(json.dumps(structure, ensure_ascii=False, indent=2))
        return

    url = os.environ.get(f"{_prefix}SUPABASE_URL")
    key = os.environ.get(f"{_prefix}SUPABASE_KEY")
    service_key = os.environ.get(f"{_prefix}SUPABASE_SERVICE_KEY")
    if not url or not key:
        logger.error("Brak SUPABASE_URL lub SUPABASE_KEY w zmiennych środowiskowych")
        print("Brak SUPABASE_URL lub SUPABASE_KEY w zmiennych środowiskowych.")
        return

    db = create_client(url, key)
    admin_db = create_client(url, service_key) if service_key else db

    try:
        clear_structure_tables(admin_db)
        logger.info("Wyczyszczono tabele struktury")
    except Exception as exc:
        logger.error(f"Błąd podczas czyszczenia tabel: {exc}")
        raise RuntimeError(
            "Failed to clear structure tables. Check Supabase delete policies/RLS."
        ) from exc

    propagate_structure_to_db(db, structure)
    logger.info("Struktura zaktualizowana w bazie danych")
    print("Structure propagated to Supabase.")


if __name__ == "__main__":
    main()
