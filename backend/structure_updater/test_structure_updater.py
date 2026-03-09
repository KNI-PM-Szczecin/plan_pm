import os
import textwrap
import pytest
from unittest.mock import MagicMock
from structure_updater.structure_updater import (
    _extract_items,
    parse_university_structure,
    propagate_structure_to_db,
    fetch_structure_from_web,
)

XML = "structure.xml"

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


# ── parse_university_structure ────────────────────────────────────────────────

def test_parse_university_structure_shape(tmp_path):
    xml = tmp_path / "structure.xml"
    xml.write_text(textwrap.dedent("""\
        <?xml version="1.0" encoding="UTF-8"?>
        <university>
            <faculty name="Wydział Informatyki">
                <degree_course name="Informatyka">
                    <specialisation>Programowanie</specialisation>
                    <specialisation>Sieci komputerowe</specialisation>
                </degree_course>
                <degree_course name="Teleinformatyka">
                </degree_course>
            </faculty>
        </university>
    """), encoding="utf-8")
    data = parse_university_structure(str(xml))
    assert len(data) == 1
    faculty = data[0]
    assert faculty["name"] == "Wydział Informatyki"
    assert len(faculty["degree_courses"]) == 2


def test_parse_university_structure_specialisations(tmp_path):
    xml = tmp_path / "structure.xml"
    xml.write_text(textwrap.dedent("""\
        <?xml version="1.0" encoding="UTF-8"?>
        <university>
            <faculty name="Wydział Informatyki">
                <degree_course name="Informatyka">
                    <specialisation>Programowanie</specialisation>
                    <specialisation>  Sieci komputerowe  </specialisation>
                </degree_course>
            </faculty>
        </university>
    """), encoding="utf-8")
    data = parse_university_structure(str(xml))
    specs = data[0]["degree_courses"][0]["specialisations"]
    assert specs == ["Programowanie", "Sieci komputerowe"]


def test_parse_university_structure_empty_specialisations(tmp_path):
    xml = tmp_path / "structure.xml"
    xml.write_text(textwrap.dedent("""\
        <?xml version="1.0" encoding="UTF-8"?>
        <university>
            <faculty name="Wydział Nawigacyjny">
                <degree_course name="Oceanotechnika">
                </degree_course>
            </faculty>
        </university>
    """), encoding="utf-8")
    data = parse_university_structure(str(xml))
    assert data[0]["degree_courses"][0]["specialisations"] == []


def test_parse_university_structure_real_xml():
    if not os.path.exists(XML):
        pytest.skip(f"{XML} not found")
    data = parse_university_structure(XML)
    assert len(data) > 0
    for faculty in data:
        assert "name" in faculty
        assert "degree_courses" in faculty
        for dc in faculty["degree_courses"]:
            assert "name" in dc
            assert "specialisations" in dc


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
    """Build a minimal Supabase client mock with stable per-table objects."""
    db = MagicMock()
    _tables = {}

    def _tbl(name):
        if name not in _tables:
            tbl = MagicMock()
            if name == "faculties":
                tbl.insert.return_value.execute.return_value.data = [
                    {"id": fid} for fid in (faculty_ids or [1])
                ]
            elif name == "degree_courses":
                tbl.insert.return_value.execute.return_value.data = [
                    {"id": did} for did in (dc_ids or [10, 20])
                ]
            else:
                tbl.insert.return_value.execute.return_value.data = []
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

def test_main_dry_run_xml(tmp_path, monkeypatch, capsys):
    """main() z --source xml --dry-run wypisuje strukturę i nie zapisuje do bazy."""
    import sys
    from structure_updater.structure_updater import main

    xml = tmp_path / "structure.xml"
    xml.write_text(textwrap.dedent("""\
        <?xml version="1.0" encoding="UTF-8"?>
        <university>
            <faculty name="Wydział Testowy">
                <degree_course name="Kierunek A">
                    <specialisation>Spec 1</specialisation>
                </degree_course>
            </faculty>
        </university>
    """), encoding="utf-8")

    monkeypatch.chdir(tmp_path)
    monkeypatch.setattr(sys, "argv", [
        "structure_updater", "--source", "xml",
        "--xml-path", str(xml), "--dry-run"
    ])

    main()

    output = capsys.readouterr().out
    assert "Wydział Testowy" in output
    assert "Kierunek A" in output


def test_main_missing_env_vars(tmp_path, monkeypatch, capsys):
    """main() bez SUPABASE_URL/KEY drukuje błąd i nie crashuje."""
    import sys
    from structure_updater.structure_updater import main

    xml = tmp_path / "structure.xml"
    xml.write_text(textwrap.dedent("""\
        <?xml version="1.0" encoding="UTF-8"?>
        <university>
            <faculty name="W">
                <degree_course name="K"></degree_course>
            </faculty>
        </university>
    """), encoding="utf-8")

    monkeypatch.chdir(tmp_path)
    monkeypatch.delenv("SUPABASE_URL", raising=False)
    monkeypatch.delenv("SUPABASE_KEY", raising=False)
    monkeypatch.setattr(sys, "argv", [
        "structure_updater", "--source", "xml", "--xml-path", str(xml)
    ])

    main()

    output = capsys.readouterr().out
    assert "SUPABASE" in output


def test_main_clear_tables_error(tmp_path, monkeypatch):
    """main() propaguje RuntimeError gdy clear_structure_tables zawodzi."""
    import sys
    from structure_updater import structure_updater as su

    xml = tmp_path / "structure.xml"
    xml.write_text(textwrap.dedent("""\
        <?xml version="1.0" encoding="UTF-8"?>
        <university>
            <faculty name="W">
                <degree_course name="K"></degree_course>
            </faculty>
        </university>
    """), encoding="utf-8")

    monkeypatch.chdir(tmp_path)
    monkeypatch.setenv("SUPABASE_URL", "https://example.supabase.co")
    monkeypatch.setenv("SUPABASE_KEY", "fake-key")
    monkeypatch.setattr(sys, "argv", [
        "structure_updater", "--source", "xml", "--xml-path", str(xml)
    ])

    fake_db = MagicMock()
    fake_db.table.return_value.delete.return_value.gte.return_value.execute.side_effect = Exception("RLS error")
    monkeypatch.setattr(su, "create_client", lambda *_: fake_db)

    with pytest.raises(RuntimeError, match="Failed to clear structure tables"):
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
