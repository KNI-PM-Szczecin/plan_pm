import sys
import pytest
from unittest.mock import MagicMock, call, patch


# ── Helpers ──────────────────────────────────────────────────

def make_supabase_mock():
    """Zwraca MagicMock imitujący supabase client z fluent API."""
    client = MagicMock()
    # MagicMock automatycznie zwraca mocki dla każdego wywołania,
    # więc fluent chain (.table().select().range().execute()) działa od razu.
    return client


# ── fetch_all ────────────────────────────────────────────────

def test_fetch_all_single_page():
    """Jedna strona danych (< 1000 wierszy) — brak dodatkowych requestów."""
    import database_manager.database_manager as dm

    rows = [{"id": str(i)} for i in range(5)]
    client = make_supabase_mock()
    client.table().select().range().execute.return_value.data = rows

    result = dm.fetch_all(client, "building")

    assert result == rows
    client.table().select().range.assert_called_with(0, 999)


def test_fetch_all_pagination():
    """Dwie pełne strony + niepełna trzecia — łączy wszystkie wyniki."""
    import database_manager.database_manager as dm

    page1 = [{"id": str(i)} for i in range(1000)]
    page2 = [{"id": str(i)} for i in range(1000, 2000)]
    page3 = [{"id": str(i)} for i in range(2000, 2050)]

    client = make_supabase_mock()
    client.table().select().range().execute.return_value.data = page1

    execute_mock = client.table().select().range().execute
    execute_mock.side_effect = [
        MagicMock(data=page1),
        MagicMock(data=page2),
        MagicMock(data=page3),
    ]

    result = dm.fetch_all(client, "classes")

    assert len(result) == 2050
    assert result[:1000] == page1
    assert result[1000:2000] == page2
    assert result[2000:] == page3


def test_fetch_all_empty_table():
    """Pusta tabela — zwraca pustą listę bez błędu."""
    import database_manager.database_manager as dm

    client = make_supabase_mock()
    client.table().select().range().execute.return_value.data = []

    result = dm.fetch_all(client, "news")

    assert result == []


# ── clear_test_data ──────────────────────────────────────────

def test_clear_test_data_uuid_tables():
    """Tabele UUID używają neq z sentinel UUID."""
    import database_manager.database_manager as dm

    client = make_supabase_mock()
    dm.clear_test_data(client)

    # Sprawdź kilka tabel UUID
    for uuid_table in ["building", "classes", "programs", "news"]:
        client.table(uuid_table).delete().neq.assert_any_call(
            "id", "00000000-0000-0000-0000-000000000000"
        )


def test_clear_test_data_bigint_tables():
    """Tabele bigint używają gte zamiast neq z UUID."""
    import database_manager.database_manager as dm

    client = make_supabase_mock()
    dm.clear_test_data(client)

    for bigint_table in ["faculties", "degree_courses", "specialisations"]:
        client.table(bigint_table).delete().gte.assert_any_call("id", 0)


def test_clear_test_data_order():
    """Tabele są czyszczone w odwrotnej kolejności FK (dzieci przed rodzicami)."""
    import database_manager.database_manager as dm

    call_order = []
    client = make_supabase_mock()
    client.table.side_effect = lambda name: (call_order.append(name), MagicMock())[1]

    dm.clear_test_data(client)

    assert call_order == list(reversed(dm.TABLES))


# ── apply_schema ─────────────────────────────────────────────

def test_apply_schema_missing_db_url(monkeypatch, capsys):
    """Brak TEST_DB_URL → sys.exit(1) i czytelny komunikat błędu."""
    import database_manager.database_manager as dm

    monkeypatch.delenv("TEST_DB_URL", raising=False)

    with pytest.raises(SystemExit) as exc:
        dm.apply_schema()

    assert exc.value.code == 1
    assert "TEST_DB_URL" in capsys.readouterr().out


def test_apply_schema_runs_correct_sql(monkeypatch):
    """apply_schema wykonuje DROP SCHEMA, schema.sql i GRANT w jednej transakcji."""
    import database_manager.database_manager as dm

    monkeypatch.setenv("TEST_DB_URL", "postgresql://fake")

    fake_conn = MagicMock()
    fake_cursor = MagicMock()
    fake_conn.__enter__ = MagicMock(return_value=fake_conn)
    fake_conn.__exit__ = MagicMock(return_value=False)
    fake_conn.cursor.return_value.__enter__ = MagicMock(return_value=fake_cursor)
    fake_conn.cursor.return_value.__exit__ = MagicMock(return_value=False)

    with patch("psycopg2.connect", return_value=fake_conn):
        dm.apply_schema()

    executed = [c.args[0] for c in fake_cursor.execute.call_args_list]
    assert any("DROP SCHEMA" in sql for sql in executed)
    assert any("GRANT" in sql for sql in executed)
    assert any("create table" in sql.lower() for sql in executed)
    fake_conn.commit.assert_called_once()


def test_apply_schema_closes_conn_on_error(monkeypatch):
    """Połączenie jest zamykane nawet gdy execute rzuca wyjątek."""
    import database_manager.database_manager as dm

    monkeypatch.setenv("TEST_DB_URL", "postgresql://fake")

    fake_conn = MagicMock()
    fake_cursor = MagicMock()
    fake_cursor.execute.side_effect = Exception("db error")
    fake_conn.cursor.return_value.__enter__ = MagicMock(return_value=fake_cursor)
    fake_conn.cursor.return_value.__exit__ = MagicMock(return_value=False)

    with patch("psycopg2.connect", return_value=fake_conn):
        with pytest.raises(Exception, match="db error"):
            dm.apply_schema()

    fake_conn.close.assert_called_once()


# ── sync_data ────────────────────────────────────────────────

def test_sync_data_copies_rows(monkeypatch):
    """sync_data czyta dane z prod i wstawia do test dla każdej tabeli."""
    import database_manager.database_manager as dm

    prod = make_supabase_mock()
    test = make_supabase_mock()

    sample_rows = [{"id": "abc", "name": "test"}]
    prod.table().select().range().execute.return_value.data = sample_rows

    monkeypatch.setattr(dm, "get_client", lambda prefix="": prod if prefix == "" else test)

    dm.sync_data()

    # Upsert powinien być wywołany dla każdej tabeli która ma wiersze
    assert test.table().upsert.called


def test_sync_data_skips_upsert_for_empty_tables(monkeypatch):
    """sync_data nie wywołuje upsert dla pustych tabel."""
    import database_manager.database_manager as dm

    prod = make_supabase_mock()
    test = make_supabase_mock()

    # Prod zwraca puste tabele
    prod.table().select().range().execute.return_value.data = []

    monkeypatch.setattr(dm, "get_client", lambda prefix="": prod if prefix == "" else test)

    dm.sync_data()

    test.table().upsert.assert_not_called()


# ── get_client ───────────────────────────────────────────────

def test_get_client_prod(monkeypatch):
    """Bez prefiksu używa SUPABASE_URL i SUPABASE_SERVICE_KEY."""
    import database_manager.database_manager as dm

    monkeypatch.setenv("SUPABASE_URL", "https://prod.supabase.co")
    monkeypatch.setenv("SUPABASE_SERVICE_KEY", "prod-key")

    with patch("database_manager.database_manager.create_client") as mock_cc:
        dm.get_client("")
        mock_cc.assert_called_once_with("https://prod.supabase.co", "prod-key")


def test_get_client_test(monkeypatch):
    """Z prefiksem TEST_ używa TEST_SUPABASE_URL i TEST_SUPABASE_SERVICE_KEY."""
    import database_manager.database_manager as dm

    monkeypatch.setenv("TEST_SUPABASE_URL", "https://test.supabase.co")
    monkeypatch.setenv("TEST_SUPABASE_SERVICE_KEY", "test-key")

    with patch("database_manager.database_manager.create_client") as mock_cc:
        dm.get_client("TEST_")
        mock_cc.assert_called_once_with("https://test.supabase.co", "test-key")
