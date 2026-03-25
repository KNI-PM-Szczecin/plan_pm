import json
import os
import pytest
from scrapper import Scrapper
from scrapper.http_scrapper import fetch_plan_http


# ─── Helpers ────────────────────────────────────────────────────────────────

MAPPER_PATH = os.path.join(os.path.dirname(__file__), "..", "output", "mapper.json")

# Known plan with confirmed data (flow 404 = Programowanie systemów multimedialnych 2023/2024)
KNOWN_VALID_ID = "404"

# Plan ID that doesn't exist / never loads
KNOWN_INVALID_ID = "1"


def _entry_key(entry: dict) -> tuple:
    """Canonical sort key for comparing entries regardless of order."""
    return (
        entry.get("Data zajęć", ""),
        entry.get("Czas od", ""),
        entry.get("Czas do", ""),
        entry.get("Przedmiot", ""),
        entry.get("Grupy", ""),
    )


def _normalize(entry: dict) -> dict:
    """Strip whitespace from all string values for stable comparison."""
    return {k: " ".join(v.split()) if isinstance(v, str) else v for k, v in entry.items()}


def _selenium_results(flow_id) -> list[dict]:
    import tempfile
    with tempfile.NamedTemporaryFile(suffix=".json", delete=False) as f:
        tmp = f.name
    s = Scrapper(output=tmp)
    s.scrapper(str(flow_id))
    try:
        os.unlink(tmp)
    except FileNotFoundError:
        pass  # Scrapper.__init__ already deleted the file if it existed before
    return s.results


def _http_results(flow_id) -> list[dict]:
    return fetch_plan_http(str(flow_id))


# ─── Existing tests (unchanged) ──────────────────────────────────────────────

@pytest.mark.slow
def test_scrapper_known_id(tmp_path):
    # ID 404 is a known plan with data
    output = str(tmp_path / "scrapper.json")
    s = Scrapper(output=output)
    s.scrapper(404)
    assert s.stats["success"] == 1
    assert len(s.results) > 0


@pytest.mark.slow
def test_scrapper_invalid_id(tmp_path):
    # ID 1 does not exist — page never loads the grid, expect interaction failure
    output = str(tmp_path / "scrapper.json")
    s = Scrapper(output=output)
    s.scrapper(1)
    assert s.stats["interaction_fail"] == 1
    assert s.stats["success"] == 0


# ─── HTTP scrapper basic tests ────────────────────────────────────────────────

@pytest.mark.slow
def test_http_scrapper_known_id():
    results = _http_results(KNOWN_VALID_ID)
    assert len(results) > 0, "HTTP scrapper zwrócił 0 wpisów dla ID 404"


@pytest.mark.slow
def test_http_scrapper_invalid_id():
    """Plan ID 1 nie istnieje — powinien zwrócić pustą listę (nie błąd)."""
    results = _http_results(KNOWN_INVALID_ID)
    assert results == []


@pytest.mark.slow
def test_http_scrapper_required_fields():
    """Każdy wpis musi mieć wszystkie wymagane klucze."""
    required = {
        "Plan dla toku", "Data zajęć", "Czas od", "Czas do",
        "Liczba godzin", "Grupy", "Przedmiot", "Forma zajęć",
        "Sala", "Prowadzący", "Forma zaliczenia", "Uwagi",
    }
    results = _http_results(KNOWN_VALID_ID)
    assert results, "Brak wyników"
    for i, entry in enumerate(results):
        missing = required - entry.keys()
        assert not missing, f"Wpis {i} brakuje pól: {missing}"


# ─── Side-by-side comparison ──────────────────────────────────────────────────

@pytest.mark.slow
def test_http_vs_selenium_count():
    """HTTP scrapper i Selenium muszą zwrócić tę samą liczbę wpisów."""
    http = _http_results(KNOWN_VALID_ID)
    sel = _selenium_results(KNOWN_VALID_ID)
    assert len(http) == len(sel), (
        f"Liczba wpisów różni się: HTTP={len(http)}, Selenium={len(sel)}"
    )


@pytest.mark.slow
def test_http_vs_selenium_entries():
    """Każdy wpis HTTP musi odpowiadać wpisowi Selenium (po posortowaniu)."""
    http = sorted([_normalize(e) for e in _http_results(KNOWN_VALID_ID)], key=_entry_key)
    sel = sorted([_normalize(e) for e in _selenium_results(KNOWN_VALID_ID)], key=_entry_key)

    assert len(http) == len(sel), f"HTTP={len(http)}, Selenium={len(sel)}"

    for i, (h, s) in enumerate(zip(http, sel)):
        for field in ("Data zajęć", "Czas od", "Czas do", "Przedmiot", "Grupy", "Sala", "Prowadzący"):
            assert h.get(field) == s.get(field), (
                f"Wpis {i} różni się w polu '{field}': "
                f"HTTP={h.get(field)!r} vs Selenium={s.get(field)!r}"
            )


@pytest.mark.slow
def test_http_vs_selenium_dates_coverage():
    """HTTP i Selenium muszą pokrywać te same daty zajęć."""
    http_dates = {e["Data zajęć"] for e in _http_results(KNOWN_VALID_ID)}
    sel_dates = {e["Data zajęć"] for e in _selenium_results(KNOWN_VALID_ID)}
    assert http_dates == sel_dates, (
        f"Różne daty: HTTP_only={http_dates - sel_dates}, Selenium_only={sel_dates - http_dates}"
    )


# ─── Multi-plan comparison from mapper ────────────────────────────────────────

def _get_plans_with_data(limit: int = 3) -> list[str]:
    """
    Wyciąga z mapper.json plany z lat 2024/2025 i 2025/2026.
    Zwraca listę flow_id (stringi).
    """
    if not os.path.exists(MAPPER_PATH):
        return [KNOWN_VALID_ID]
    with open(MAPPER_PATH, encoding="utf-8") as f:
        mapper = json.load(f)
    recent = [
        fid for fid, name in mapper.items()
        if "2025/2026" in name or "2024/2025" in name
    ]
    return recent[:limit]


@pytest.mark.slow
@pytest.mark.parametrize("flow_id", _get_plans_with_data(limit=3))
def test_http_vs_selenium_multiple_plans(flow_id):
    """
    Dla kilku planów z mapper.json porównuje HTTP i Selenium.
    Oba muszą zwrócić tę samą liczbę wpisów i te same dane.
    """
    http = _http_results(flow_id)
    sel = _selenium_results(flow_id)

    # Jeśli oba puste — OK (plan bez zajęć w "Najbliższe")
    if not http and not sel:
        pytest.skip(f"Plan {flow_id} nie ma nadchodzących zajęć — pomijam")

    assert len(http) == len(sel), (
        f"[{flow_id}] Liczba wpisów: HTTP={len(http)}, Selenium={len(sel)}"
    )

    http_sorted = sorted([_normalize(e) for e in http], key=_entry_key)
    sel_sorted = sorted([_normalize(e) for e in sel], key=_entry_key)

    for i, (h, s) in enumerate(zip(http_sorted, sel_sorted)):
        for field in ("Data zajęć", "Czas od", "Czas do", "Przedmiot", "Grupy"):
            assert h.get(field) == s.get(field), (
                f"[{flow_id}] Wpis {i}, pole '{field}': "
                f"HTTP={h.get(field)!r} vs Selenium={s.get(field)!r}"
            )
