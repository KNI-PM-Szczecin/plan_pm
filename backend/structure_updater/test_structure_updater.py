import textwrap
import pytest
from unittest.mock import MagicMock
from structure_updater.structure_updater import (
    _extract_items,
    propagate_structure_to_db,
    fetch_structure_from_web,
)

# ── _extract_items ─────────────────────────────────────────────────────────────

SAMPLE_HTML = textwrap.dedent("""
    ASPx.createControl(MVCxClientListBox,'Kierunki_DDD_L','',{
        'itemsInfo':[
            {'value':'','text':''},
            {'value':'787','text':'Informatyka'},
            {'value':'791','text':'Teleinformatyka'}
        ],'hoverClasses':['x']
    });
""")


def test_extract_items_returns_non_empty_values():
    items = _extract_items(SAMPLE_HTML, 'Kierunki')
    assert len(items) == 2


def test_extract_items_filters_out_blank_value():
    items = _extract_items(SAMPLE_HTML, 'Kierunki')
    assert all(item['value'] for item in items)


def test_extract_items_preserves_text_and_value():
    items = _extract_items(SAMPLE_HTML, 'Kierunki')
    assert {'value': '787', 'text': 'Informatyka'} in items
    assert {'value': '791', 'text': 'Teleinformatyka'} in items


def test_extract_items_strips_whitespace():
    html = SAMPLE_HTML.replace("'Informatyka'", "'  Informatyka  '")
    items = _extract_items(html, 'Kierunki')
    texts = [i['text'] for i in items]
    assert 'Informatyka' in texts


def test_extract_items_collapses_internal_spaces():
    html = SAMPLE_HTML.replace("'Informatyka'", "'Inżynieria  i  Bezpieczeństwo'")
    items = _extract_items(html, 'Kierunki')
    assert items[0]['text'] == 'Inżynieria i Bezpieczeństwo'


def test_extract_items_unknown_control_returns_empty():
    items = _extract_items(SAMPLE_HTML, 'Nieistniejacy')
    assert items == []


def test_extract_items_preserves_capitalisation():
    html = SAMPLE_HTML.replace("'Informatyka'", "'programowanie Systemów Informatycznych'")
    items = _extract_items(html, 'Kierunki')
    assert items[0]['text'] == 'programowanie Systemów Informatycznych'



# ── propagate_structure_to_db ─────────────────────────────────────────────────

STRUCTURE_STUB = [
    {
        "name": "Wydział A",
        "degree_courses": [
            {"name": "Kierunek X", "specialisations": ["Spec 1", "Spec 2"]},
            {"name": "Kierunek Y", "specialisations": []},
        ],
    }
]


def _make_db_mock(faculty_ids=None, dc_ids=None):
    """Build a minimal Supabase client mock with stable per-table objects.

    insert() echoes the inserted rows back with an "id" attached (like PostgREST
    RETURNING *), so propagate_structure_to_db can match ids to inputs by name.
    """
    db = MagicMock()
    _tables = {}
    id_pools = {
        "faculties": list(faculty_ids or [1]),
        "degree_courses": list(dc_ids or [10, 20]),
    }

    def _tbl(name):
        if name not in _tables:
            tbl = MagicMock()

            def _insert(rows, _name=name):
                ids = id_pools.get(_name, [])
                data = [{**row, "id": (ids[i] if i < len(ids) else 1000 + i)}
                        for i, row in enumerate(rows)]
                result = MagicMock()
                result.execute.return_value.data = data
                return result

            tbl.insert.side_effect = _insert
            _tables[name] = tbl
        return _tables[name]

    db.table.side_effect = _tbl
    return db


def test_propagate_inserts_faculties():
    db = _make_db_mock()
    propagate_structure_to_db(db, STRUCTURE_STUB)
    db.table("faculties").insert.assert_called_once_with([{"name": "Wydział A"}])


def test_propagate_inserts_degree_courses():
    db = _make_db_mock(faculty_ids=[1])
    propagate_structure_to_db(db, STRUCTURE_STUB)
    db.table("degree_courses").insert.assert_called_once_with([
        {"name": "Kierunek X", "faculty_id": 1},
        {"name": "Kierunek Y", "faculty_id": 1},
    ])


def test_propagate_inserts_specialisations():
    db = _make_db_mock(faculty_ids=[1], dc_ids=[10, 20])
    propagate_structure_to_db(db, STRUCTURE_STUB)
    db.table("specialisations").insert.assert_called_once_with([
        {"name": "Spec 1", "degree_course_id": 10},
        {"name": "Spec 2", "degree_course_id": 10},
    ])


def test_propagate_skips_specialisations_insert_when_none():
    structure = [{"name": "Wydział A", "degree_courses": [{"name": "Kierunek X", "specialisations": []}]}]
    db = _make_db_mock(faculty_ids=[1], dc_ids=[10])
    propagate_structure_to_db(db, structure)
    db.table("specialisations").insert.assert_not_called()


# ── fetch_structure_from_web ──────────────────────────────────────────────────

def test_extract_items_no_itemsinfo_returns_empty():
    """Linia 40: marker kontrolki znaleziony, ale brak 'itemsInfo':[ za nim."""
    html = "ASPx.createControl(MVCxClientListBox,'Kierunki_DDD_L','',{});"
    items = _extract_items(html, 'Kierunki')
    assert items == []


def test_extract_items_unbalanced_brackets_returns_empty():
    """Linia 55: pętla kończy się bez znalezienia zamykającego ] → return []."""
    html = "ASPx.createControl(MVCxClientListBox,'Kierunki_DDD_L','',{'itemsInfo':[{'value':'1','text':'Informatyka'}"
    items = _extract_items(html, 'Kierunki')
    assert items == []


# ── clear_structure_tables ────────────────────────────────────────────────────

def test_clear_structure_tables_calls_delete_on_all_tables():
    from structure_updater.structure_updater import clear_structure_tables
    db = MagicMock()
    _tables: dict = {}

    def _tbl(name):
        if name not in _tables:
            _tables[name] = MagicMock()
        return _tables[name]

    db.table.side_effect = _tbl
    clear_structure_tables(db)

    _tables["specialisations"].delete.assert_called_once()
    _tables["degree_courses"].delete.assert_called_once()
    _tables["faculties"].delete.assert_called_once()


# ── main() ────────────────────────────────────────────────────────────────────

_FAKE_STRUCTURE = [
    {"name": "Wydział Testowy",
     "degree_courses": [{"name": "Kierunek A", "specialisations": ["Spec 1"]}]},
]


def test_main_dry_run(tmp_path, monkeypatch, capsys):
    """main() z --dry-run wypisuje strukturę (z web) i nie zapisuje do bazy."""
    import sys
    from structure_updater import structure_updater as su

    monkeypatch.chdir(tmp_path)
    monkeypatch.setattr(su, "fetch_structure_from_web", lambda: _FAKE_STRUCTURE)
    monkeypatch.setattr(sys, "argv", ["structure_updater", "--dry-run"])

    su.main()

    output = capsys.readouterr().out
    assert "Wydział Testowy" in output
    assert "Kierunek A" in output


def test_main_missing_env_vars(tmp_path, monkeypatch, capsys):
    """main() bez SUPABASE_URL/SERVICE_KEY drukuje błąd i nie crashuje."""
    import sys
    from structure_updater import structure_updater as su

    monkeypatch.chdir(tmp_path)
    monkeypatch.setattr(su, "fetch_structure_from_web", lambda: _FAKE_STRUCTURE)
    # Clear both prefixed and non-prefixed vars so the missing-env path triggers
    # regardless of .env_mode (the module reads TEST_* in test mode).
    for var in ("SUPABASE_URL", "SUPABASE_SERVICE_KEY",
                "TEST_SUPABASE_URL", "TEST_SUPABASE_SERVICE_KEY"):
        monkeypatch.delenv(var, raising=False)
    monkeypatch.setattr(sys, "argv", ["structure_updater", "--force"])

    su.main()

    assert "SUPABASE" in capsys.readouterr().out


def test_main_clear_tables_error(tmp_path, monkeypatch):
    """main() propaguje RuntimeError gdy aktualizacja struktury zawodzi."""
    import sys
    from structure_updater import structure_updater as su

    monkeypatch.chdir(tmp_path)
    monkeypatch.setattr(su, "fetch_structure_from_web", lambda: _FAKE_STRUCTURE)
    monkeypatch.setattr(su, "notify_discord", lambda *a, **k: None)
    for var in ("SUPABASE_URL", "SUPABASE_SERVICE_KEY",
                "TEST_SUPABASE_URL", "TEST_SUPABASE_SERVICE_KEY"):
        monkeypatch.setenv(var, "https://example.supabase.co" if "URL" in var else "fake-key")
    monkeypatch.setattr(sys, "argv", ["structure_updater", "--force"])

    fake_db = MagicMock()
    fake_db.table.return_value.delete.return_value.gte.return_value.execute.side_effect = Exception("RLS error")
    monkeypatch.setattr(su, "create_client", lambda *_: fake_db)

    with pytest.raises(RuntimeError, match="Failed to update structure"):
        su.main()


def test_main_refuses_to_clear_suspiciously_small_structure(tmp_path, monkeypatch):
    import sys
    from structure_updater import structure_updater as su

    monkeypatch.chdir(tmp_path)
    monkeypatch.setattr(su, "fetch_structure_from_web", lambda: [])
    monkeypatch.setattr(sys, "argv", ["structure_updater"])
    monkeypatch.setattr(su, "create_client", MagicMock())

    with pytest.raises(ValueError, match="Refusing to clear university structure"):
        su.main()


@pytest.mark.slow
def test_fetch_structure_from_web_shape():
    data = fetch_structure_from_web()
    assert isinstance(data, list)
    assert len(data) > 0
    for faculty in data:
        assert "name" in faculty
        assert isinstance(faculty["name"], str) and faculty["name"]
        assert "degree_courses" in faculty
        for dc in faculty["degree_courses"]:
            assert "name" in dc
            assert "specialisations" in dc


@pytest.mark.slow
def test_fetch_structure_from_web_no_trailing_spaces():
    data = fetch_structure_from_web()
    for faculty in data:
        assert faculty["name"] == faculty["name"].strip()
        for dc in faculty["degree_courses"]:
            assert dc["name"] == dc["name"].strip()
            for spec in dc["specialisations"]:
                assert spec == spec.strip()
                assert "  " not in spec
