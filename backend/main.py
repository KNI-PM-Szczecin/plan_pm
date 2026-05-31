import argparse
import json
import sys
import time

from console_setup import force_utf8_output

force_utf8_output()

from mapper import Mapper
from scrapper import HttpScrapper
from parser import Parser
from json2db import json2db

# A healthy full scrape yields thousands of classes. If parsing produced far
# fewer, the source site was likely down/blocking — refuse to clear the DB,
# because json2db(clear=True) truncates every table before re-inserting and a
# near-empty parse would wipe the live schedule.
MIN_CLASSES_TO_CLEAR = 100

parser = argparse.ArgumentParser(description="PlanPM pipeline")
parser.add_argument("--workers", type=int, default=None, help="Liczba wątków (domyślnie: 10)")
args = parser.parse_args()

start_time = time.time()
print("Starting PlanPM worker")

Mapper(output="./output/mapper.json").run(minID=0, maxID=600)

workers = args.workers or 10
HttpScrapper(input="./output/mapper.json", output="./output/scrapper.json").run(max_workers=workers)

Parser(input="scrapper.json").run()

# Sanity gate before the destructive upload (HttpScrapper swallows per-thread
# errors, so a failed scrape still produces a small-but-valid parser.json).
try:
    with open("./output/parser.json", encoding="utf-8") as f:
        n_classes = len(json.load(f).get("classes", []))
except (OSError, ValueError) as e:
    print(f"❌ Abort: cannot read parser.json ({e}); refusing to clear the DB.")
    sys.exit(1)

if n_classes < MIN_CLASSES_TO_CLEAR:
    print(
        f"❌ Abort: parser.json has only {n_classes} classes "
        f"(< {MIN_CLASSES_TO_CLEAR}); the scrape likely failed. "
        "Refusing to clear the DB."
    )
    sys.exit(1)

json2db(input="./output/parser.json", clear=True).run()

print(f"✅ PlanPM gotowy ({time.time() - start_time:.2f} s)")
