# PM Schedule (Plan PM)

**PM Schedule** is an open-source mobile application providing students and lecturers of the Maritime University of Szczecin (_Politechnika Morska w Szczecinie_) with easy access to class schedules. It features a Flutter frontend and a Python backend data pipeline.

---

## Project Overview

### Frontend (Flutter)
- **Target Platforms:** Android, iOS.
- **Tech Stack:** Flutter (Dart), Supabase Client, SQLite (for local caching).
- **State Management:** `ValueNotifier` + `ValueListenableBuilder`.
- **Key Features:** Schedule viewing, news feed, native home screen widgets, multi-language support (PL, EN, UK).

### Backend (Python)
- **Tech Stack:** Python 3.13+, BeautifulSoup4, Flask, Supabase (PostgreSQL + Storage).
- **Data Pipeline:** `Mapper → Scrapper → Parser → json2db`.
- **Admin Tools:** Local Flask admin panel for news and pipeline management; MCP server for agent-based control.

---

## Building and Running

### Frontend

1. **Setup:**
   ```bash
   cd frontend
   flutter pub get
   ```
2. **Environment Configuration:**
   - Use `scripts/switch_env.py [test|prod]` to configure `env_config.dart`.
   - Ensure `lib/secrets.dart` is present (copy from `secrets_example.dart` and fill keys).
3. **Run App:**
   ```bash
   flutter run
   ```
4. **Localization:**
   ```bash
   flutter gen-l10n # Run after modifying .arb files
   ```

### Backend

1. **Setup:**
   ```bash
   cd backend
   # Using uv (recommended)
   uv sync
   # OR using venv
   python -m venv .venv
   source .venv/bin/activate
   pip install -e .
   ```
2. **Configuration:**
   - Create `.env` based on `.env.example`.
   - Set database mode via `scripts/switch_env.py [test|prod]`.
3. **Run Pipeline:**
   ```bash
   python main.py                                          # Full schedule pipeline
   python -m json2db.json2db --input ./output/parser.json  # Re-upload parser.json only
   ```
4. **Admin Panel:**
   ```bash
   python -m admin.app        # Access at http://localhost:5050
   ```
5. **MCP Server:**
   ```bash
   python -m mcp_server.server
   ```

---

## Testing

### Frontend
- Fast unit/widget tests: `flutter test`.
- Native widgets: See `frontend/WIDGET_TEST_PLAN.md`.

### Backend
- Fast tests (no network): `pytest -m "not slow"`.
- Integration tests (network): `pytest -m slow`.

---

## Development Conventions

### General
- **Language:** All Git artifacts (commits, PRs, documentation) MUST be in **English**. Conversation can be in Polish.
- **Commits:** Use semantic format `type: description` (e.g., `fix: resolve overflow bug`).
- **Secrets:** NEVER commit `.env`, `secrets.dart`, or API keys.

### Frontend
- **Cache Synchronization:** Always call `syncNews()` and `syncLectures()` together to ensure data consistency.
- **Environment Flags:** Do NOT manually edit `env_config.dart` flags for production; use `scripts/switch_env.py prod`.
- **UI:** Adhere to existing patterns for blurred AppBars/BottomNavBars and platform-aware widgets.

### Backend
- **Database:** Use `upsert` for idempotency. Use `.env_mode` to toggle between test/prod databases.
- **Scraping:** The pipeline is HTTP-only (mimics DevExpress AJAX).
- **Logging:** Use the `logging` module; logs are stored in `backend/logs/`.

---

## Repository Structure

```
plan_pm/
├── frontend/          # Flutter Application
├── backend/           # Python Data Pipeline & Admin Tools
├── scripts/           # Utility scripts (switch_env.py)
├── docs/              # Deployment and design documentation
└── output/            # Intermediate pipeline JSON files (gitignored)
```

For more detailed technical notes, refer to `CLAUDE.md` in the root.
