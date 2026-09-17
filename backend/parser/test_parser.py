import json
import os
import shutil
import pytest
from parser import Parser

INPUT = "./output/scrapper.json"


@pytest.fixture
def scrapper_output(tmp_path):
    if not os.path.exists(INPUT):
        pytest.skip(f"{INPUT} not found — run scrapper first")
    shutil.copy(INPUT, tmp_path / "scrapper.json")
    return str(tmp_path)


def test_parser_runs(scrapper_output):
    p = Parser(input="scrapper.json", output=scrapper_output)
    p.run()
    assert os.path.exists(os.path.join(scrapper_output, "parser.json"))


# --- Testy dla sala_idx w normalizeClasses ---

@pytest.fixture
def scrapper_with_duplicate_room(tmp_path):
    """Dane scrapera gdzie sala to ta sama sala dwa razy z \xa0 przed przecinkiem."""
    data = [
        {
            "Plan dla toku": "Programowanie systemów multimedialnych S inż. 3.50 2024/2025 zima",
            "Data zajęć": "2025.01.20 poniedziałek",
            "Czas od": "9:45",
            "Czas do": "10:30",
            "Liczba godzin": "1h00m",
            "Grupy": "L01/PSM/2024/2025 ZS",
            "Przedmiot": "Projektowanie analiz przestrzennych",
            "Forma zajęć": "Labor",
            "Sala": "Żołnierska 5\xa0, Żołnierska 5",
            "Prowadzący": "dr inż. Jan Kowalski",
            "Forma zaliczenia": "Zaliczenie ocena",
            "Uwagi": ""
        }
    ]
    path = tmp_path / "scrapper.json"
    path.write_text(json.dumps(data), encoding="utf-8")
    return str(tmp_path)


def test_duplicate_room_with_nbsp_resolves_to_single_room(scrapper_with_duplicate_room):
    """
    Reprodukuje buga z planem 457: sala 'Żołnierska 5\xa0, Żołnierska 5'
    (ta sama sala dwa razy z non-breaking space) powinna być sparsowana do
    jednej sali 'Żołnierska 5', a nie zwracać None.
    """
    p = Parser(input="scrapper.json", output=scrapper_with_duplicate_room)
    p.getTokAndPlan()

    classes = p.sched.classes
    rooms = p.sched.rooms

    assert len(classes) == 1
    room_idx = classes[0]["Sala"]
    assert room_idx is not None, (
        "Sala powinna być rozpoznana jako 'Żołnierska 5', a nie None. "
        "Bug: normalizeClasses szukało oryginalnego stringa zamiast sparsowanego."
    )
    assert rooms[room_idx]["room"] == "5", f"Numer sali powinien być '5', dostano: {rooms[room_idx]}"


def test_parseRooms_deduplicates_nbsp_duplicates():
    """
    parseRooms powinno stripować \xa0 i deduplikować tę samą salę.
    """
    result = Parser.parseRooms("Żołnierska 5\xa0, Żołnierska 5")
    assert result == ["Żołnierska 5"], f"Oczekiwano ['Żołnierska 5'], dostano: {result}"


# --- Testy dla parseTeachers ---

def test_parseTeachers_single_dr():
    p = Parser.__new__(Parser)
    result = p.parseTeachers("dr inż. Jan Kowalski")
    assert result == ["dr inż. Jan Kowalski"]


def test_parseTeachers_multiple_dr():
    p = Parser.__new__(Parser)
    result = p.parseTeachers("dr inż. Jan Kowalski dr hab. Anna Nowak")
    assert "dr inż. Jan Kowalski" in result
    assert "dr hab. Anna Nowak" in result
    assert len(result) == 2


def test_parseTeachers_prof_branch():
    """Gałąź prof w parseTeachers — kiedy drugi nauczyciel zaczyna od 'prof.'"""
    p = Parser.__new__(Parser)
    # "dr " jest na pozycji 0 więc find("dr ", 7) nie znajdzie go → wchodzi w gałąź prof
    result = p.parseTeachers("dr inż. Jan Kowalski prof. Anna Nowak")
    assert "dr inż. Jan Kowalski" in result
    assert "prof. Anna Nowak" in result
    assert len(result) == 2


def test_parseTeachers_empty():
    p = Parser.__new__(Parser)
    assert p.parseTeachers("") == []


def test_parseTeachers_kpt_compound_title_splits_correctly():
    """Both teachers have 'mgr inż. kpt. ż. w.' — compound title should not split on the first kpt."""
    p = Parser.__new__(Parser)
    result = p.parseTeachers(
        "mgr inż. kpt. ż. w. Tomasz Pluta mgr inż. kpt. ż. w. Barbara Kwiecińska"
    )
    assert len(result) == 2
    assert any("Tomasz Pluta" in r for r in result)
    assert any("Barbara Kwiecińska" in r for r in result)


def test_parseTeachers_kpt_standalone_after_mgr():
    """Second teacher has only 'kpt. ż. w.' title (no mgr/dr), must still split."""
    p = Parser.__new__(Parser)
    result = p.parseTeachers("mgr inż. Jan Kowalski kpt. ż. w. Anna Nowak")
    assert len(result) == 2
    assert any("Jan Kowalski" in r for r in result)
    assert any("Anna Nowak" in r for r in result)


def test_parseTeachers_kpt_single_teacher():
    """Single teacher with kpt. ż. w. title — must NOT split."""
    p = Parser.__new__(Parser)
    result = p.parseTeachers("kpt. ż. w. Jan Kowalski")
    assert result == ["kpt. ż. w. Jan Kowalski"]


def test_parseTeachers_kpt_both_standalone():
    """Both teachers have only 'kpt. ż. w.' — splits on second occurrence."""
    p = Parser.__new__(Parser)
    result = p.parseTeachers("kpt. ż. w. Jan Kowalski kpt. ż. w. Anna Nowak")
    assert len(result) == 2
    assert any("Jan Kowalski" in r for r in result)
    assert any("Anna Nowak" in r for r in result)


# --- Testy dla tokStringToDic ---

def test_tokStringToDic_standard():
    result = Parser.tokStringToDic("Informatyka S inż. 3.50 2024/2025 zima")
    assert result["name"] == "Informatyka"
    assert result["program_type"] == "S"
    assert result["degree_level"] == "inż."
    assert result["course_length"] == "3.50"
    assert result["academic_year"] == "2024/2025 zima"


def test_tokStringToDic_no_degree_level_is_handled():
    result = Parser.tokStringToDic("Kurs bez stopnia 3.50 2024/2025 zima")
    assert result["name"] == "Kurs bez stopnia 3.50 2024/2025 zima"
    assert result["degree_level"] == ""


def test_parseTeachers_whitespace_returns_empty():
    parser = Parser.__new__(Parser)
    assert parser.parseTeachers("   ") == []


# --- Test trybu DEBUG ---

def test_parser_debug_mode_small_data(tmp_path):
    """
    Parser(debug=True) powinien działać poprawnie na małym zbiorze danych.
    Wcześniej crashował z IndexError przez hardcoded self.sched.classes[535].
    """
    data = [
        {
            "Plan dla toku": "Informatyka S inż. 3.50 2024/2025 zima",
            "Data zajęć": "2025.01.20 poniedziałek",
            "Czas od": "9:45",
            "Czas do": "10:30",
            "Liczba godzin": "1h00m",
            "Grupy": "L01",
            "Przedmiot": "Matematyka",
            "Forma zajęć": "Wykład",
            "Sala": "Żołnierska 5",
            "Prowadzący": "dr inż. Jan Kowalski",
            "Forma zaliczenia": "Zaliczenie ocena",
            "Uwagi": ""
        }
    ]
    path = tmp_path / "scrapper.json"
    path.write_text(__import__("json").dumps(data), encoding="utf-8")

    p = Parser(debug=True, input="scrapper.json", output=str(tmp_path))
    p.run()
    assert os.path.exists(os.path.join(str(tmp_path), "parser.json"))


def test_plan_457_duplicate_room_not_none(scrapper_output):
    """
    Weryfikuje na realnych danych że klasy planu 457 z salą
    'Żołnierska 5\\xa0, Żołnierska 5' mają room != None po parsowaniu.
    Klasy z pustą salą (np. WF) są pomijane – None jest dla nich prawidłowe.
    """
    import json as _json

    # Zbieramy timestampy klas które miały niepustą salę w scrapper.json
    plan_name = "Programowanie systemów multimedialnych S inż. 3.50 2024/2025 zima"
    scrapper_path = os.path.join(scrapper_output, "scrapper.json")
    with open(scrapper_path, encoding="utf-8") as f:
        raw = _json.load(f)
    entries_with_sala = {
        (e["Czas od"], e["Data zajęć"])
        for e in raw
        if e.get("Plan dla toku") == plan_name and e.get("Sala", "").strip()
    }
    if not entries_with_sala:
        pytest.skip("Plan 457 nie ma klas z salą w scrapper.json")

    p = Parser(input="scrapper.json", output=scrapper_output)
    p.getTokAndPlan()

    programs = p.sched.programs
    prog_idx = next(
        (i for i, prog in enumerate(programs)
         if isinstance(prog, dict)
         and prog.get("name") == "Programowanie systemów multimedialnych"
         and prog.get("program_type") == "S"
         and "2024/2025" in prog.get("academic_year", "")),
        None
    )
    if prog_idx is None:
        pytest.skip("Plan 457 nie jest w scrapper.json")

    classes_457 = [c for c in p.sched.classes if c.get("Plan dla toku") == prog_idx]
    # Sprawdzamy tylko klasy, które scrapper miał z niepustą salą
    none_with_sala = [
        c for c in classes_457
        if c.get("Sala") is None and (
            # Sala była niepusta – po parsowaniu nie powinna być None
            any(c.get("startTime") == st for st in
                [p.convertDateToTimestamp(d, t, t)[0] for t, d in entries_with_sala
                 if True])
        )
    ]
    # Prostsze sprawdzenie: żadna klasa z sali != '' nie powinna mieć None
    # Korelujemy przez czas startowy
    from datetime import datetime as _dt
    sala_by_time = {}
    for e in raw:
        if e.get("Plan dla toku") != plan_name:
            continue
        sala = e.get("Sala", "").strip()
        if not sala:
            continue
        start, _ = Parser.convertDateToTimestamp(e["Data zajęć"], e["Czas od"], e["Czas do"])
        sala_by_time[start] = sala

    bad = [
        c for c in classes_457
        if c.get("Sala") is None and c.get("startTime") in sala_by_time
    ]
    assert len(bad) == 0, (
        f"{len(bad)} klas planu 457 z niepustą salą ma room=None po parsowaniu.\n"
        f"Przykłady: { [(sala_by_time[c['startTime']], c) for c in bad[:3]] }"
    )
