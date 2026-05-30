# PlanPM – Backend

Backend responsible for fetching, processing, and storing class schedules from the Virtual Dean's Office of the Maritime University of Szczecin into a Supabase database.

## Project Overview

The project is a data pipeline that scrapes, parses, and uploads university schedules. It also includes a tool for updating the university structure (faculties, courses, specialisations) and a news management tool for a mobile application.

### Tech Stack
- **Language:** Python 3.13+
- **Database:** Supabase (PostgreSQL + Storage)
- **Scraping:** Selenium (Chrome) or `requests` (HTTP-only)
- **Data Processing:** BeautifulSoup4, Python standard library
- **Admin UI:** Flask
- **Testing:** pytest with coverage reporting

## Project Structure

```
backend/
├── main.py                  # Entry point – runs the full schedule pipeline
├── mapper/                  # Step 1 – detects active schedule IDs
├── scrapper/                # Step 2 – scrapes schedules (HTTP or Selenium)
├── parser/                  # Step 3 – normalises raw data into structured JSON
├── json2db/                 # Step 4 – uploads processed data to Supabase
├── structure_updater/       # Separate pipeline – updates university structure
├── admin/                   # Flask admin UI (formerly news_tool)
│   ├── app.py               # Flask application
│   ├── static/              # CSS and static assets
│   └── templates/           # HTML templates
├── docs/                    # Technical documentation and reference files
├── output/                  # Intermediate JSON files (gitignored, but examples exist)
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
python main.py                          # Run with default HTTP scrapper
python main.py --workers 20             # Parallelize with more workers
python main.py --old-scrapper           # Fallback to Selenium scrapper
```

### University Structure Update
```bash
python -m structure_updater.structure_updater --source web
python -m structure_updater.structure_updater --source xml --xml-path docs/structure.xml
```

### Admin UI (News Management)
```bash
python admin/app.py
# Access at http://localhost:5050
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
pytest -m slow                # Integration tests (network/Selenium)
pytest --cov=.                # Run with coverage report
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
- **HTTP Scrapper (Preferred):** Faster and more reliable. It mimics DevExpress AJAX callbacks.
- **Selenium Scrapper (Fallback):** Used if the HTTP protocol changes. Requires a headless Chrome environment.

### Code Style
- Use `logging` instead of `print` for process-long tasks. Logs are stored in the `logs/` directory.
- Modules should expose a primary class and be re-exported in `__init__.py`.

## Configuration

Required `.env` variables:
```env
SUPABASE_URL=https://<project>.supabase.co
SUPABASE_KEY=<anon_key>
SUPABASE_SERVICE_KEY=<service_role_key>

# Optional test environment
TEST_SUPABASE_URL=...
TEST_SUPABASE_KEY=...
TEST_SUPABASE_SERVICE_KEY=...
```

Control database target via `.env_mode` file (content: `test` or `prod`).

## Technical Documentation
For detailed insights into the scraping logic and DevExpress grid internals, refer to `docs/agent.md`.
