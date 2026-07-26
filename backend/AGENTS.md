# Repository Guidelines

## Project Structure & Module Organization
This Python 3.13 backend is organized as a schedule-processing pipeline. `main.py` runs the full flow: `mapper/` discovers active schedule IDs, `scrapper/` fetches schedule rows, `parser/` normalizes raw data, and `json2db/` uploads results to Supabase. `structure_updater/` is a separate university-structure import pipeline. `admin/` contains the Flask admin UI, with templates in `admin/templates/` and static files in `admin/static/`. Tests are colocated with modules as `test_*.py`. Generated artifacts live in `output/`, `logs/`, and `coverage/`; avoid committing new generated data unless it is intentionally used as a fixture or example.

## Build, Test, and Development Commands
Create and activate a virtual environment, then install dependencies:

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

Run the full schedule pipeline with `python main.py`; use `python main.py --workers 20` for higher parallelism. Start the admin panel with `python -m admin.app` and open `http://127.0.0.1:5050` (localhost only). Run individual stages with module commands such as `python -m json2db.json2db --input ./output/parser.json --dry-run` or `python -m structure_updater.structure_updater --dry-run`.

## Coding Style & Naming Conventions
Follow existing Python style: 4-space indentation, snake_case modules/functions, PascalCase classes, and clear module-level entry points. Prefer `logging` for pipeline output instead of `print`. Keep data-shape changes explicit and localized to the pipeline stage that owns them. No formatter is configured in `pyproject.toml`; keep edits consistent with surrounding code.

## Testing Guidelines
The project uses `pytest`. Fast tests should avoid real network, browser, or database work:

```bash
pip install -e ".[dev]"   # installs pytest
pytest -m "not slow"
pytest -m slow
```

Use the existing `slow` marker for integration tests that require network or external services. Name new tests `test_<module>.py` and keep fixtures close to the module unless they are shared broadly.

## Commit & Pull Request Guidelines
Recent history uses Conventional Commit-style messages, often scoped, for example `fix(admin): ...`, `feat: ...`, `refactor: ...`, and `chore: ...`. Keep commits focused and imperative. Pull requests should include a short summary, testing performed, linked issues when applicable, and screenshots for `admin/` UI changes.

## Security & Configuration Tips
Store secrets in `.env`, not in source. Use `.env.example` for new variable documentation. `.env_mode` selects `test` or `prod`; verify it before running database writes. Prefer `--dry-run` when touching Supabase-backed import paths.
