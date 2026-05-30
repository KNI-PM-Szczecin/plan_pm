# PlanPM Backend - Project Instructions

## Project Overview
PlanPM Backend is a Python-based system for fetching, processing, and storing class schedules from the Virtual Dean's Office of the Maritime University of Szczecin into a Supabase database.

### Core Architecture
The system operates as a multi-stage pipeline:
1.  **Mapper:** Scans for valid schedule IDs on the university website.
2.  **Scrapper:** Fetches raw timetable data using either a high-performance HTTP scraper or a Selenium-based fallback.
3.  **Parser:** Normalizes raw HTML data into structured JSON, handling deduplication, entity extraction (teachers, rooms, subjects), and date conversion.
4.  **json2db:** Upserts the normalized data into Supabase PostgreSQL tables.

### Key Components
- `main.py`: The entry point for running the full pipeline.
- `mapper/`: Schedule ID discovery logic.
- `scrapper/`: Web scraping implementations (`HttpScrapper` preferred, `Scrapper` for Selenium).
- `parser/`: Data normalization and transformation logic.
- `json2db/`: Database upload utility.
- `structure_updater/`: Independent pipeline for updating the university hierarchy (Faculties → Courses → Specialisations).
- `news_tool/`: Local Flask-based admin UI for managing news posts displayed in the mobile app.
- `database_manager/`: Utility for database schema migrations and data synchronization between production and test environments.

## Technologies
- **Language:** Python 3.13+
- **Database:** Supabase (PostgreSQL)
- **Scraping:** Requests, BeautifulSoup4, Selenium (Headless Chrome)
- **Admin Tool:** Flask, Jinja2, Pillow
- **Testing:** Pytest
- **Utilities:** python-dotenv, Rich (logging)

## Development Workflow

### Setup & Configuration
1.  **Environment:** Create a `.env` file at the root with the following keys:
    - `SUPABASE_URL`
    - `SUPABASE_SERVICE_KEY` (Required for all DB operations and news management)
    - `TEST_SUPABASE_URL`, `TEST_SUPABASE_SERVICE_KEY`, `TEST_DB_URL` (For testing)
2.  **Mode Switching:** Use `.env_mode` to toggle between `prod` and `test` environments:
    ```bash
    echo "test" > .env_mode
    ```
3.  **Dependencies:** Managed via `uv` or `pip`. Key dependencies are in `pyproject.toml` and `requirements.txt`.

### Key Commands
- **Full Pipeline:** `python main.py`
- **Re-upload Only:** `python uploadparsetodb.py` (Skips scraping, uses existing `output/parser.json`)
- **University Structure:** `python -m structure_updater.structure_updater`
- **News Tool:** `python news_tool/app.py`
- **Database Management:**
    - `python database_manager/database_manager.py --schema` (Apply schema to test DB)
    - `python database_manager/database_manager.py --sync` (Sync prod schema and data to test DB)

### Testing Practices
- **Run Tests:** `pytest`
- **Fast Tests Only:** `pytest -m "not slow"` (Excludes live network and Selenium tests)
- **Slow Tests Only:** `pytest -m slow` (Requires browser and internet access)
- **Coverage:** `pytest --cov=. -m "not slow"`

## Coding Conventions
- **Module Structure:** Each module (mapper, scrapper, etc.) should re-export its primary class/function in its `__init__.py`.
- **Logging:** All pipeline steps should log to the `logs/` directory.
- **Data Output:** Intermediate data should be stored in the `output/` directory as JSON.
- **Type Safety:** Use type hints wherever possible.
- **Database Safety:** Prefer upsert operations to handle existing data gracefully.

## Technical Context
For deep technical details on the DevExpress grid scraping logic, AJAX callbacks, and specific data normalization rules, refer to `docs/agent.md`.
