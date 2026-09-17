import argparse
import time

from console_setup import force_utf8_output

force_utf8_output()

from mapper import Mapper
from scrapper import HttpScrapper
from parser import Parser
from json2db import json2db
from structure_check.structure_check import check_from_env as structure_check
from notifier import caller_handles_notification, notify_discord, pipeline_stats_text

parser = argparse.ArgumentParser(description="PlanPM pipeline")
parser.add_argument("--workers", type=int, default=None, help="Liczba wątków (domyślnie: 10)")
args = parser.parse_args()

start_time = time.time()
print("Starting PlanPM worker")

Mapper(output="./output/mapper.json").run(minID=0, maxID=600)

workers = args.workers or 10
HttpScrapper(input="./output/mapper.json", output="./output/scrapper.json").run(max_workers=workers)

Parser(input="scrapper.json").run()

# The destructive safety gate lives inside json2db so every caller (CLI,
# admin, MCP and this full pipeline) gets exactly the same protection.
ok = True
try:
    json2db(input="./output/parser.json", clear=True).run()
except Exception:
    ok = False
    raise
finally:
    # Report to Discord unless the caller (admin, MCP) notifies for us.
    if not caller_handles_notification():
        notify_discord("Full Pipeline", success=ok, detail="źródło: CLI",
                       stats=pipeline_stats_text())

# A plan whose name has no node in the structure tree is invisible in the app:
# the student cannot pick it, and the only signal used to be a support message
# months later. Never fail the pipeline over it — the data is already loaded and
# correct, it is the naming that drifted.
if ok:
    try:
        structure_check()
    except Exception as exc:  # noqa: BLE001 — guardrail must not break the run
        print(f"Structure check pominięty: {exc}")

print(f"✅ PlanPM gotowy ({time.time() - start_time:.2f} s)")
