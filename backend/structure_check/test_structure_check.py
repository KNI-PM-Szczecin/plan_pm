"""Testy strażnika dopasowania planów do struktury — po jednym na każdy kierunek.

Snapshot produkcji jest współdzielony z testami aplikacji
(frontend/test/fixtures/availability_snapshot.json). To celowe: reguły
dopasowania są zaimplementowane dwa razy (tu i w program_availability.dart)
i muszą dawać ten sam werdykt na tych samych danych — inaczej strażnik milczy,
a student i tak nie znajdzie swojego planu.
"""

import json
import os
from unittest.mock import MagicMock

import pytest

from structure_check.structure_check import (
    check,
    find_unmatched,
    normalize_name,
    strip_language_suffix,
)

SNAPSHOT = os.path.join(
    os.path.dirname(__file__), "..", "..", "frontend", "test", "fixtures",
    "availability_snapshot.json",
)


def _load_snapshot():
    if not os.path.exists(SNAPSHOT):
        pytest.skip("brak snapshotu — uruchom scripts/dump_availability_fixture.py")
    with open(SNAPSHOT, encoding="utf-8") as f:
        return json.load(f)


def _structure_names(snapshot) -> list[str]:
    names = [row["degreeCourse"] for row in snapshot["structure"]]
    names += [row["specialisation"] for row in snapshot["structure"] if row["specialisation"]]
    return names


def _degree_courses(snapshot) -> list[tuple[str, str]]:
    return sorted({(row["faculty"], row["degreeCourse"]) for row in snapshot["structure"]})


_SNAPSHOT = None
try:
    if os.path.exists(SNAPSHOT):
        with open(SNAPSHOT, encoding="utf-8") as _f:
            _SNAPSHOT = json.load(_f)
except OSError:  # pragma: no cover — snapshot jest opcjonalny
    _SNAPSHOT = None

_COURSES = _degree_courses(_SNAPSHOT) if _SNAPSHOT else []


# ── Jeden test na kierunek ────────────────────────────────────────────────────

@pytest.mark.skipif(not _COURSES, reason="brak snapshotu produkcji")
@pytest.mark.parametrize("faculty,degree_course", _COURSES, ids=[f"{f} — {d}" for f, d in _COURSES])
def test_every_plan_of_degree_course_is_reachable(faculty, degree_course):
    """Każdy plan przypisany do kierunku (wprost lub przez specjalizację) musi
    dać się wybrać w aplikacji."""
    snapshot = _load_snapshot()
    structure_names = _structure_names(snapshot)

    own_names = {normalize_name(degree_course)}
    own_names |= {
        normalize_name(row["specialisation"])
        for row in snapshot["structure"]
        if row["faculty"] == faculty
        and row["degreeCourse"] == degree_course
        and row["specialisation"]
    }

    plans_of_course = [
        program["programName"]
        for program in snapshot["programs"]
        if normalize_name(strip_language_suffix(program["programName"])) in own_names
    ]

    assert find_unmatched(plans_of_course, structure_names) == [], (
        f"plany kierunku {degree_course} nie do wybrania w aplikacji"
    )


@pytest.mark.skipif(not _SNAPSHOT, reason="brak snapshotu produkcji")
def test_production_snapshot_has_no_unreachable_plan():
    snapshot = _load_snapshot()
    names = [program["programName"] for program in snapshot["programs"]]
    assert find_unmatched(names, _structure_names(snapshot)) == []


# ── Reguły dopasowania ────────────────────────────────────────────────────────

def test_doubled_space_still_matches():
    # Nazwa, która przez miesiące chowała cały rocznik.
    assert find_unmatched(
        ["Inżynieria i Bezpieczeństwo  w Transporcie Drogowym"],
        ["Inżynieria i Bezpieczeństwo w Transporcie Drogowym"],
    ) == []


def test_nbsp_still_matches():
    assert find_unmatched(["Transport\xa0Morski"], ["Transport Morski"]) == []


def test_case_difference_still_matches():
    assert find_unmatched(["informatyka"], ["Informatyka"]) == []


def test_english_track_matches_its_polish_node():
    assert find_unmatched(["Transport Morski ang."], ["Transport Morski"]) == []
    assert find_unmatched(["Transport Morski ANG"], ["Transport Morski"]) == []


def test_polish_marker_is_not_stripped():
    # "POL" nie jest znacznikiem wariantu — gdyby był, "Logistyka POL" pasowałaby
    # do "Logistyka", a to już zgadywanie.
    assert find_unmatched(["Logistyka POL"], ["Logistyka"]) == ["Logistyka POL"]


def test_unknown_plan_is_reported():
    assert find_unmatched(["Kierunek Widmo"], ["Informatyka"]) == ["Kierunek Widmo"]


def test_result_is_sorted_and_deduplicated():
    assert find_unmatched(["B", "A", "A"], ["Informatyka"]) == ["A", "B"]


def test_strip_language_suffix_leaves_single_word_names():
    assert strip_language_suffix("ANG") == "ANG"
    assert strip_language_suffix("Nawigacja") == "Nawigacja"


# ── check() ───────────────────────────────────────────────────────────────────

def _db_mock(program_names, structure_rows):
    """Minimalny klient Supabase: v_unique_groups (stronicowane) + v_academic_structure."""
    db = MagicMock()

    def _table(name):
        tbl = MagicMock()
        if name == "v_unique_groups":
            selected = MagicMock()
            ranged = MagicMock()
            ranged.execute.return_value.data = [
                {"program_name": n} for n in program_names
            ]
            selected.range.return_value = ranged
            tbl.select.return_value = selected
        else:
            selected = MagicMock()
            selected.execute.return_value.data = structure_rows
            tbl.select.return_value = selected
        return tbl

    db.table.side_effect = _table
    return db


STRUCTURE_ROWS = [
    {
        "faculty_name": "Mechaniczny",
        "degree_course_name": "Mechanika i Budowa Maszyn",
        "specialisation_name": "Eksploatacja Siłowni Okrętowych",
    }
]


def test_check_returns_unmatched_and_notifies(monkeypatch):
    sent = {}

    def _fake_notify(title, **kwargs):
        sent["title"] = title
        sent["detail"] = kwargs.get("detail", "")
        sent["success"] = kwargs.get("success")

    monkeypatch.setattr("structure_check.structure_check.notify_discord", _fake_notify)

    db = _db_mock(["Eksploatacja Siłowni Okrętowych", "Kierunek Widmo"], STRUCTURE_ROWS)
    assert check(db) == ["Kierunek Widmo"]
    assert sent["success"] is False
    assert "Kierunek Widmo" in sent["detail"]


def test_check_is_quiet_when_everything_matches(monkeypatch):
    calls = []
    monkeypatch.setattr(
        "structure_check.structure_check.notify_discord",
        lambda *a, **k: calls.append(a),
    )
    db = _db_mock(["Mechanika i Budowa Maszyn"], STRUCTURE_ROWS)
    assert check(db) == []
    assert calls == []


def test_check_can_skip_notification(monkeypatch):
    calls = []
    monkeypatch.setattr(
        "structure_check.structure_check.notify_discord",
        lambda *a, **k: calls.append(a),
    )
    db = _db_mock(["Kierunek Widmo"], STRUCTURE_ROWS)
    assert check(db, notify=False) == ["Kierunek Widmo"]
    assert calls == []
