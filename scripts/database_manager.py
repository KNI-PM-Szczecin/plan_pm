#!/usr/bin/env python3
"""
Zarządzanie bazą danych plan_pm.

Użycie:
  python scripts/database_manager.py --schema   # zastosuj schemat prod do testowej bazy
  python scripts/database_manager.py --sync     # skopiuj schemat + dane prod → test
"""

import argparse
import os
import sys
from pathlib import Path

from dotenv import load_dotenv
from supabase import create_client

REPO_ROOT = Path(__file__).parent.parent
load_dotenv(REPO_ROOT / "backend" / ".env")

# Kolejność tabel respektująca zależności FK (dzieci przed rodzicami przy usuwaniu)
BIGINT_ID_TABLES = {"faculties", "degree_courses", "specialisations"}

TABLES = [
    "building",
    "teachers",
    "faculties",
    "degree_courses",
    "specialisations",
    "programs",
    "program_faculties",
    "rooms",
    "classes",
    "teachersclasses",
    "news",
    "admin_users",
    "student_clubs",
    "teacher_assignments",
    "schedule_events",
    "class_cancellations",
    "class_reschedules",
    "rector_hours",
]


def get_client(prefix: str = ""):
    url = os.environ[f"{prefix}SUPABASE_URL"]
    key = os.environ[f"{prefix}SUPABASE_SERVICE_KEY"]
    return create_client(url, key)


def fetch_all(client, table: str) -> list[dict]:
    """Pobiera wszystkie wiersze z tabeli (z paginacją)."""
    rows = []
    page_size = 1000
    offset = 0
    while True:
        batch = (
            client.table(table)
            .select("*")
            .range(offset, offset + page_size - 1)
            .execute()
            .data
        )
        rows.extend(batch)
        if len(batch) < page_size:
            break
        offset += page_size
    return rows


def clear_test_data(test_client):
    """Usuwa wszystkie dane z testowej bazy w odwrotnej kolejności FK."""
    for table in reversed(TABLES):
        print(f"  Czyszczenie: {table}...")
        if table in BIGINT_ID_TABLES:
            test_client.table(table).delete().gte("id", 0).execute()
        else:
            test_client.table(table).delete().neq(
                "id", "00000000-0000-0000-0000-000000000000"
            ).execute()


def apply_schema():
    """Resetuje schemat testowej bazy i stosuje migrations/schema.sql."""
    try:
        import psycopg2
    except ImportError:
        print("Błąd: psycopg2 nie jest zainstalowany.")
        print("Uruchom: pip install psycopg2-binary")
        sys.exit(1)

    db_url = os.environ.get("TEST_DB_URL", "").strip()
    if not db_url:
        print("Błąd: TEST_DB_URL nie jest ustawiony w .env")
        print("Skopiuj Session Pooler connection string z: Supabase Dashboard → Connect → Session Pooler")
        sys.exit(1)

    schema_sql = (REPO_ROOT / "backend" / "migrations" / "schema.sql").read_text()

    print(f"Łączenie z testową bazą...")
    conn = psycopg2.connect(db_url, sslmode="require")
    try:
        with conn.cursor() as cur:
            print("Resetowanie schematu...")
            cur.execute("DROP SCHEMA public CASCADE; CREATE SCHEMA public;")
            print("Stosowanie migrations/schema.sql...")
            cur.execute(schema_sql)
            cur.execute("""
                GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
                GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated, service_role;
                GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, service_role;
            """)
        conn.commit()
        print("Schemat zastosowany pomyślnie.")
    finally:
        conn.close()


def sync_data():
    """Kopiuje wszystkie dane z produkcji do testowej bazy."""
    prod = get_client("")
    test = get_client("TEST_")

    print("Czyszczenie danych w testowej bazie...")
    clear_test_data(test)

    print("\nKopiowanie danych prod → test...")
    total = 0
    for table in TABLES:
        rows = fetch_all(prod, table)
        if rows:
            test.table(table).upsert(rows).execute()
        print(f"  {table}: {len(rows)} wierszy")
        total += len(rows)

    print(f"\nSynchronizacja zakończona. Skopiowano {total} wierszy.")


def cmd_schema(_args):
    apply_schema()


def cmd_sync(_args):
    apply_schema()
    print()
    sync_data()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Zarządzanie bazą danych plan_pm",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Przykłady:
  python scripts/database_manager.py --schema   # zastosuj schemat do testowej bazy
  python scripts/database_manager.py --sync     # schemat + dane prod → test
        """,
    )
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument(
        "--schema",
        action="store_true",
        help="Zastosuj schemat (migrations/schema.sql) do testowej bazy",
    )
    group.add_argument(
        "--sync",
        action="store_true",
        help="Skopiuj schemat i dane z produkcji do testowej bazy",
    )
    args = parser.parse_args()

    if args.schema:
        cmd_schema(args)
    elif args.sync:
        cmd_sync(args)
