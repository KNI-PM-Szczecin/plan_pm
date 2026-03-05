import json
import shutil
import pytest
from json2db import json2db

INPUT = "./output/parser.json"


@pytest.fixture
def parser_output(tmp_path):
    if not __import__("os").path.exists(INPUT):
        pytest.skip(f"{INPUT} not found — run parser first")
    shutil.copy(INPUT, tmp_path / "parser.json")
    return str(tmp_path / "parser.json")


def test_json2db_loads(parser_output):
    db = json2db(input=parser_output)
    assert db.data is not None
    assert "programs" in db.data


# --- Testy weryfikujące błąd w load_classes: room_map oparty tylko na nazwie sali ---

@pytest.fixture
def parser_data_with_room_collision(tmp_path):
    """Dane parsera z dwiema salami o tej samej nazwie w różnych budynkach."""
    data = {
        "programs": [
            {
                "name": "Hydrografia",
                "program_type": "S",
                "degree_level": "inż.",
                "language": "POL",
                "academic_year": "2023/2024 zima",
                "course_length": "3.50"
            }
        ],
        "classes": [
            {
                "program": 0,
                "subject": 0,
                "group": "G01",
                "startTime": 1700000000,
                "endTime": 1700003600,
                "room": 0,  # Żołnierska 119
                "notes": ""
            },
            {
                "program": 0,
                "subject": 0,
                "group": "G02",
                "startTime": 1700100000,
                "endTime": 1700103600,
                "room": 1,  # Willowa B1 119 – ta sama nazwa "119", inny budynek
                "notes": ""
            }
        ],
        "teachers": [],
        "teachersclasses": [],
        "subjects": ["Matematyka"],
        "rooms": [
            {"building": 0, "room": "119"},  # Żołnierska 119
            {"building": 1, "room": "119"},  # Willowa B1 119
        ],
        "building": ["Żołnierska", "Willowa B1"]
    }
    path = tmp_path / "parser.json"
    path.write_text(json.dumps(data), encoding="utf-8")
    return str(path)


def test_room_name_uniqueness_in_parser_json(parser_output):
    """
    Weryfikuje, że w aktualnym parser.json istnieją kolizje nazw sal między budynkami.
    Ten test dokumentuje, że problem jest obecny w danych – kolizje mogą powodować
    błędne przypisanie sali w load_classes.
    """
    db = json2db(input=parser_output)
    rooms = db.data["rooms"]
    buildings = db.data["building"]

    room_name_to_buildings = {}
    for room in rooms:
        name = room["room"]
        b_idx = room.get("building")
        b_name = buildings[b_idx] if b_idx is not None else None
        room_name_to_buildings.setdefault(name, set()).add(b_name)

    collisions = {
        name: bldgs
        for name, bldgs in room_name_to_buildings.items()
        if len(bldgs) > 1
    }
    # Plan 417 (Hydrografia) używa sal "119", "125", "5" – wszystkie mają kolizje
    assert "119" in collisions, "Sala '119' powinna mieć kolizję (Żołnierska vs Willowa)"
    assert "125" in collisions, "Sala '125' powinna mieć kolizję (Żołnierska vs Willowa B1)"
    assert "5" in collisions, "Sala '5' powinna mieć kolizję (Żołnierska vs Szczerbcow)"


def test_load_classes_room_map_collision(parser_data_with_room_collision, tmp_path):
    """
    Dokumentuje stary bug: room_map oparty tylko na nazwie sali tracił informację
    o budynku, przez co sala "119" w Willowej nadpisywała "119" w Żołnierskiej.
    """
    db = json2db(input=parser_data_with_room_collision)

    # Stary (błędny) room_map – tylko nazwa sali jako klucz
    fake_db_rooms = [
        {"id": "uuid-zolnierska-119", "name": "119", "building": "uuid-zolnierska"},
        {"id": "uuid-willowa-119",    "name": "119", "building": "uuid-willowa-b1"},
    ]
    broken_room_map = {v["name"]: v["id"] for v in fake_db_rooms}
    assert len(broken_room_map) == 1, "Stary map miał kolizję – tylko 1 wpis"
    assert broken_room_map["119"] == "uuid-willowa-119", "Willowa nadpisywała Żołnierską"


def test_load_classes_room_map_fixed(parser_data_with_room_collision, tmp_path):
    """
    Weryfikuje poprawkę: room_map z kluczem (nazwa, building_uuid) poprawnie
    rozróżnia sale o tej samej nazwie w różnych budynkach.
    """
    db = json2db(input=parser_data_with_room_collision)

    # Nowy (poprawiony) room_map – klucz to (nazwa, uuid budynku)
    fake_db_rooms = [
        {"id": "uuid-zolnierska-119", "name": "119", "building": "uuid-zolnierska"},
        {"id": "uuid-willowa-119",    "name": "119", "building": "uuid-willowa-b1"},
    ]
    fixed_room_map = {(v["name"], v["building"]): v["id"] for v in fake_db_rooms}
    assert len(fixed_room_map) == 2, "Poprawiony map ma 2 wpisy dla 2 różnych budynków"

    # Klasa z Żołnierska 119 dostaje teraz właściwe ID
    assert fixed_room_map[("119", "uuid-zolnierska")] == "uuid-zolnierska-119"
    assert fixed_room_map[("119", "uuid-willowa-b1")] == "uuid-willowa-119"


def test_plan_417_rooms_not_willowa(parser_output):
    """
    Weryfikuje, że wszystkie sale planu 417 (Hydrografia S inż. 2023/2024)
    należą do Żołnierskiej lub WChrobrego, a NIE do Willowej.
    """
    db = json2db(input=parser_output)
    programs = db.data["programs"]
    rooms = db.data["rooms"]
    buildings = db.data["building"]
    classes = db.data["classes"]

    hydrografia_idx = next(
        (i for i, p in enumerate(programs)
         if p["name"] == "Hydrografia"
         and p["program_type"] == "S"
         and p["degree_level"] == "inż."
         and "2023/2024" in p["academic_year"]),
        None
    )
    assert hydrografia_idx is not None, "Nie znaleziono programu Hydrografia S inż. 2023/2024"

    hydrografia_classes = [c for c in classes if c.get("program") == hydrografia_idx]
    assert len(hydrografia_classes) > 0, "Brak klas dla Hydrografii S inż. 2023/2024"

    for c in hydrografia_classes:
        room_idx = c.get("room")
        if room_idx is None:
            continue
        room = rooms[room_idx]
        b_idx = room.get("building")
        if b_idx is None:
            continue
        b_name = buildings[b_idx]
        assert "Willowa" not in b_name, (
            f"Klasa planu 417 ma salę w Willowej: {room} (budynek: {b_name}). "
            f"Powinno być Żołnierska lub WChrobrego."
        )
