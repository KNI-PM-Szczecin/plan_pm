import json
import subprocess
import sys
import threading
from pathlib import Path

from flask import Blueprint, Response, render_template, session, redirect, url_for

from admin.db import get_env_mode

BACKEND_ROOT = Path(__file__).parent.parent.parent

STEPS = {
    "full":      {"label": "Full Pipeline",     "cmd": [sys.executable, "main.py"]},
    "mapper":    {"label": "Mapper",            "cmd": [sys.executable, "-c", "from mapper import Mapper; Mapper(output='./output/mapper.json').run(minID=0, maxID=600)"]},
    "scrapper":  {"label": "Scrapper (HTTP)",   "cmd": [sys.executable, "-c", "from scrapper import HttpScrapper; HttpScrapper(input='./output/mapper.json', output='./output/scrapper.json').run()"]},
    "parser":    {"label": "Parser",            "cmd": [sys.executable, "-c", "from parser import Parser; Parser(input='scrapper.json').run()"]},
    "json2db":   {"label": "Upload to DB",      "cmd": [sys.executable, "-c", "from json2db import json2db; json2db(input='./output/parser.json', clear=True).run()"]},
    "structure": {"label": "Structure Updater", "cmd": [sys.executable, "-m", "structure_updater.structure_updater", "--source", "web"]},
}

_lock = threading.Lock()
_running: dict = {"step": None}

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
    )


@bp.route("/pipeline/run/<step>")
def run(step: str):
    if step not in STEPS:
        return "Unknown step", 404

    if not _lock.acquire(blocking=False):
        return Response(
            "data: [ERROR] Inny krok jest już uruchomiony.\n\n",
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
            yield f"data: [EXIT {code}]\n\n"
        finally:
            _running["step"] = None
            _lock.release()

    return Response(generate(), mimetype="text/event-stream")


@bp.route("/pipeline/logs/<module>")
def logs(module: str):
    allowed = {"mapper", "http_scrapper", "scrapper", "structure_updater"}
    if module not in allowed:
        return "Not found", 404
    log_path = BACKEND_ROOT / "logs" / f"{module}.log"
    if not log_path.exists():
        return Response("data: (brak logów)\n\n", mimetype="text/event-stream")

    def generate():
        lines = log_path.read_text(errors="replace").splitlines()[-200:]
        for line in lines:
            yield f"data: {json.dumps(line)}\n\n"
        yield "data: [EOF]\n\n"

    return Response(generate(), mimetype="text/event-stream")
