import json
import os
import queue
import subprocess
import sys
import threading
from pathlib import Path

from flask import Blueprint, Response, render_template, session

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

STEP_INPUTS = {
    "scrapper": {
        "path": BACKEND_ROOT / "output" / "mapper.json",
        "message": "Brak danych wejściowych: output/mapper.json. Uruchom najpierw Mapper albo Full Pipeline.",
    },
    "parser": {
        "path": BACKEND_ROOT / "output" / "scrapper.json",
        "message": "Brak danych wejściowych: output/scrapper.json. Uruchom najpierw Scrapper albo Full Pipeline.",
    },
    "json2db": {
        "path": BACKEND_ROOT / "output" / "parser.json",
        "message": "Brak danych wejściowych: output/parser.json. Uruchom najpierw Parser albo Full Pipeline.",
    },
}

NO_LOGS_MESSAGE = "Brak logów."

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

    required_input = STEP_INPUTS.get(step)
    if required_input and not required_input["path"].exists():
        return Response(
            f"data: {json.dumps('[ERROR] ' + required_input['message'])}\n\n"
            f"data: {json.dumps('[EXIT 1]')}\n\n",
            mimetype="text/event-stream",
        )

    if not _lock.acquire(blocking=False):
        return Response(
            f"data: {json.dumps('[ERROR] Inny krok jest już uruchomiony: ' + str(_running['step']))}\n\n"
            f"data: {json.dumps('[EXIT 1]')}\n\n",
            mimetype="text/event-stream",
        )

    _running["step"] = step

    # The subprocess runs in a worker thread that OWNS the lock release and
    # process cleanup, so the lock can't leak if the client disconnects. The SSE
    # generator only relays lines from a queue; on disconnect it kills the proc.
    q: "queue.Queue" = queue.Queue()
    DONE = object()
    proc_holder: list = []

    def worker():
        proc = None
        try:
            # Match the displayed env exactly, and force UTF-8 + unbuffered so
            # Windows consoles don't crash on emoji and logs stream live.
            env = {
                **os.environ,
                "PLANPM_ENV": get_env_mode(),
                "PYTHONUTF8": "1",
                "PYTHONIOENCODING": "utf-8",
                "PYTHONUNBUFFERED": "1",
            }
            proc = subprocess.Popen(
                STEPS[step]["cmd"],
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                encoding="utf-8",
                errors="replace",
                cwd=str(BACKEND_ROOT),
                env=env,
            )
            proc_holder.append(proc)
            for line in proc.stdout:
                q.put(("log", line.rstrip()))
            code = proc.wait()
            q.put(("exit", code))
            # Notify Discord for DB-touching steps. structure_updater notifies
            # itself (any caller), so it's excluded here to avoid duplicates.
            if step in ("full", "json2db"):
                notify_discord(STEPS[step]["label"], success=(code == 0),
                               stats=pipeline_stats_text())
        except Exception as e:
            q.put(("log", f"[ERROR] Nie udało się uruchomić kroku: {e}"))
            q.put(("exit", 1))
        finally:
            if proc and proc.poll() is None:
                proc.kill()
            _running["step"] = None
            _lock.release()
            q.put((DONE, None))

    threading.Thread(target=worker, daemon=True).start()

    def generate():
        try:
            while True:
                kind, val = q.get()
                if kind is DONE:
                    break
                if kind == "log":
                    yield f"data: {json.dumps(val)}\n\n"
                else:  # exit
                    yield f"data: {json.dumps(f'[EXIT {val}]')}\n\n"
        except GeneratorExit:
            # Client disconnected mid-run — stop the subprocess so it doesn't keep
            # writing to the DB; the worker's finally still releases the lock.
            if proc_holder and proc_holder[0].poll() is None:
                proc_holder[0].kill()
            raise

    return Response(generate(), mimetype="text/event-stream")


@bp.route("/pipeline/logs/<module>")
def logs(module: str):
    allowed = {"mapper", "scrapper", "json2db", "structure_updater"}
    if module not in allowed:
        return "Not found", 404
    log_path = BACKEND_ROOT / "logs" / f"{module}.log"
    if not log_path.exists():
        return Response(
            f"data: {json.dumps(NO_LOGS_MESSAGE)}\n\ndata: {json.dumps('[EOF]')}\n\n",
            mimetype="text/event-stream",
        )

    def generate():
        # Per-run logs (files open in mode="w+") stay bounded, so serve the whole
        # file; 5000 is just a safety cap against a pathological run.
        lines = log_path.read_text(encoding="utf-8", errors="replace").splitlines()[-5000:]
        if not lines:
            yield f"data: {json.dumps(NO_LOGS_MESSAGE)}\n\n"
            yield f"data: {json.dumps('[EOF]')}\n\n"
            return
        for line in lines:
            yield f"data: {json.dumps(line)}\n\n"
        yield f"data: {json.dumps('[EOF]')}\n\n"

    return Response(generate(), mimetype="text/event-stream")
