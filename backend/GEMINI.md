# PlanPM – Backend

Backend responsible for fetching, processing, and storing class schedules from the Virtual Dean's Office of the Maritime University of Szczecin into a Supabase database.

## Project Overview

The project is a data pipeline that scrapes, parses, and uploads university schedules. It also includes a tool for updating the university structure (faculties, courses, specialisations) and a news management tool for a mobile application.

### Tech Stack
- **Language:** Python 3.13+
- **Database:** Supabase (PostgreSQL + Storage)
- **Scraping:** `requests` (HTTP-only; mimics DevExpress AJAX callbacks)
- **Data Processing:** BeautifulSoup4, Python standard library
- **Admin UI:** Flask
- **Testing:** pytest

## Project Structure

```
backend/
├── main.py                  # Entry point – runs the full schedule pipeline
├── mapper/                  # Step 1 – detects active schedule IDs
├── scrapper/                # Step 2 – scrapes schedules over HTTP (no browser)
├── parser/                  # Step 3 – normalises raw data into structured JSON
├── json2db/                 # Step 4 – uploads processed data to Supabase
├── structure_updater/       # Separate pipeline – updates university structure
├── admin/                   # Flask admin panel (formerly news_tool)
│   ├── app.py               # Flask application
│   ├── routes/              # news, pipeline, stats, settings blueprints
│   ├── static/              # CSS and static assets
│   └── templates/           # HTML templates
├── mcp_server/              # MCP server – drive the backend from an agent
├── output/                  # Intermediate JSON files (gitignored)
└── logs/                    # Process logs (gitignored)
```

## Building and Running

### Setup
1. Create a `.venv` and install dependencies:
   ```bash
   python -m venv .venv
   source .venv/bin/activate
   pip install -r requirements.txt
   ```
2. Configure environment variables in `.env` (see Configuration section).

### Full Schedule Pipeline
```bash
python main.py                          # HTTP scrapper, 10 workers (default)
python main.py --workers 20             # Parallelize with more workers
```

### University Structure Update
```bash
python -m structure_updater.structure_updater            # scrape + write to DB
python -m structure_updater.structure_updater --dry-run  # preview only
```

### Admin Panel
```bash
python -m admin.app
# Access at http://127.0.0.1:5050 (localhost only)
```

### Individual Steps
Each module can be run independently:
```bash
python -m mapper.mapper
python -m scrapper.http_scrapper
python -m parser.parser
python -m json2db.json2db --input ./output/parser.json
```

## Testing

The project uses `pytest` with markers to distinguish between fast and slow tests.

```bash
pytest -m "not slow"          # Unit tests and fast integrations
pytest -m slow                # Integration tests (network)
```

## Development Conventions

### Data Flow
The schedule pipeline follows a strict flow: `Mapper -> Scrapper -> Parser -> json2db`.
- **Mapper:** Outputs `{ "flow_id": "name" }`.
- **Scrapper:** Outputs a list of flat dicts with Polish keys.
- **Parser:** Normalises keys to English, deduplicates, and cross-references entities.
- **json2db:** Handles upserts to Supabase to prevent duplicates.

### Database Interaction
- Prefer `upsert` for all database operations to ensure idempotency.
- Use `.env_mode` to toggle between `test` and `prod` databases.
- `SUPABASE_SERVICE_KEY` is required for administrative tasks like clearing tables.

### Scraping
- **HTTP-only:** the scrapper mimics DevExpress AJAX callbacks (~2s/plan). The old Selenium scrapper has been removed.

### Code Style
- Use `logging` instead of `print` for process-long tasks. Logs are stored in the `logs/` directory.
- Modules should expose a primary class and be re-exported in `__init__.py`.

## Configuration

Required `.env` variables (the backend is trusted server-side and uses the
service-role key only — the anon key was dropped):
```env
SUPABASE_URL=https://<project>.supabase.co
SUPABASE_SERVICE_KEY=<service_role_key>

# Optional test environment
TEST_SUPABASE_URL=...
TEST_SUPABASE_SERVICE_KEY=...
```

Control database target via `.env_mode` file (content: `test` or `prod`),
overridable per-run with the `PLANPM_ENV` environment variable.

## Technical Documentation
For architecture, conventions, data flow, and gotchas, see the repository
`CLAUDE.md` (the primary backend reference).
