import json
import subprocess
import sys
import threading
from pathlib import Path

from flask import Blueprint, Response, render_template, session, redirect, url_for

from admin.db import get_env_mode
from notifier import notify_discord, pipeline_stats_text

BACKEND_ROOT = Path(__file__).parent.parent.parent

STEPS = {
    "full":      {"label": "Full Pipeline",     "cmd": [sys.executable, "main.py"]},
    "mapper":    {"label": "Mapper",            "cmd": [sys.executable, "-c", "from mapper import Mapper; Mapper(output='./output/mapper.json').run(minID=0, maxID=600)"]},
    "scrapper":  {"label": "Scrapper",          "cmd": [sys.executable, "-c", "from scrapper import HttpScrapper; HttpScrapper(input='./output/mapper.json', output='./output/scrapper.json').run()"]},
    "parser":    {"label": "Parser",            "cmd": [sys.executable, "-c", "from parser import Parser; Parser(input='scrapper.json').run()"]},
    "json2db":   {"label": "Upload to DB",      "cmd": [sys.executable, "-c", "from json2db import json2db; json2db(input='./output/parser.json', clear=True).run()"]},
    "structure": {"label": "Structure Updater", "cmd": [sys.executable, "-m", "structure_updater.structure_updater"]},
}

# Single-flight guard for pipeline runs. In-process only — assumes the admin
# runs on the single-process Flask dev server (app.run). It would NOT serialize
# across multiple gunicorn/uwsgi workers; move to a DB/Redis lock if that changes.
_lock = threading.Lock()
_running: dict = {"step": None}

# Quick-access resource links shown on the pipeline page.
LINKS = [
    {"title": "YouTrack", "subtitle": "Issues & tasks", "icon": "bi-kanban",
     "color": "#4a9eff", "url": "https://mobilesigmas.youtrack.cloud/agiles/183-3/current"},
    {"title": "GitHub", "subtitle": "Source code", "icon": "bi-github",
     "color": "#ffffff", "url": "https://github.com/KNI-PM-Szczecin/plan_pm"},
    {"title": "Knowledge Base", "subtitle": "Docs & guides", "icon": "bi-journal-text",
     "color": "#a855f7", "url": "https://mobilesigmas.youtrack.cloud/articles/PLPM"},
    {"title": "Supabase", "subtitle": "Database", "icon": "bi-lightning-charge-fill",
     "color": "#3ecf8e", "url": "https://supabase.com/dashboard/project/tuhxoqjndjgbdmlhicws"},
]

bp = Blueprint("pipeline", __name__)


@bp.route("/")
@bp.route("/pipeline")
def index():
    flash = session.pop("flash", None)
    return render_template(
        "pipeline.html",
        title="Pipeline",
        active="pipeline",
        env_mode=get_env_mode(),
        flash=flash,
        steps=STEPS,
        running=_running["step"],
        links=LINKS,
    )


@bp.route("/pipeline/run/<step>")
def run(step: str):
    if step not in STEPS:
        return "Unknown step", 404

    if not _lock.acquire(blocking=False):
        return Response(
            f"data: {json.dumps('[ERROR] Inny krok jest już uruchomiony.')}\n\n",
            mimetype="text/event-stream",
        )

    _running["step"] = step

    def generate():
        try:
            proc = subprocess.Popen(
                STEPS[step]["cmd"],
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                cwd=str(BACKEND_ROOT),
            )
            for line in proc.stdout:
                yield f"data: {json.dumps(line.rstrip())}\n\n"
            code = proc.wait()
            yield f"data: {json.dumps(f'[EXIT {code}]')}\n\n"
            # Notify Discord for DB-touching steps. structure_updater notifies
            # itself (any caller), so it's excluded here to avoid duplicates.
            if step in ("full", "json2db"):
                notify_discord(STEPS[step]["label"], success=(code == 0),
                               stats=pipeline_stats_text())
        finally:
            _running["step"] = None
            _lock.release()

    return Response(generate(), mimetype="text/event-stream")


@bp.route("/pipeline/logs/<module>")
def logs(module: str):
    allowed = {"mapper", "scrapper", "json2db", "structure_updater"}
    if module not in allowed:
        return "Not found", 404
    log_path = BACKEND_ROOT / "logs" / f"{module}.log"
    if not log_path.exists():
        return Response(
            f"data: {json.dumps('(brak logów)')}\n\ndata: {json.dumps('[EOF]')}\n\n",
            mimetype="text/event-stream",
        )

    def generate():
        # Per-run logs (files open in mode="w+") stay bounded, so serve the whole
        # file; 5000 is just a safety cap against a pathological run.
        lines = log_path.read_text(errors="replace").splitlines()[-5000:]
        for line in lines:
            yield f"data: {json.dumps(line)}\n\n"
        yield f"data: {json.dumps('[EOF]')}\n\n"

    return Response(generate(), mimetype="text/event-stream")
