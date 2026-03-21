import argparse
import time

from mapper import Mapper
from scrapper import HttpScrapper, Scrapper
from parser import Parser
from json2db import json2db

parser = argparse.ArgumentParser(description="PlanPM pipeline")
parser.add_argument("--old-scrapper", action="store_true", help="Użyj Selenium scrappera zamiast HTTP (fallback)")
parser.add_argument("--workers", type=int, default=None, help="Liczba wątków (domyślnie: 10 dla HTTP, 5 dla Selenium)")
args = parser.parse_args()

start_time = time.time()
print("Starting PlanPM worker")

Mapper(output="./output/mapper.json").run(minID=0, maxID=600)

if args.old_scrapper:
    workers = args.workers or 5
    print(f"⚠️  Tryb fallback: Selenium scrapper ({workers} wątków)")
    Scrapper(input="./output/mapper.json", output="./output/scrapper.json").run(max_workers=workers)
else:
    workers = args.workers or 10
    HttpScrapper(input="./output/mapper.json", output="./output/scrapper.json").run(max_workers=workers)

Parser(input="scrapper.json").run()

json2db(input="./output/parser.json", clear=True).run()

print(f"✅ PlanPM gotowy ({time.time() - start_time:.2f} s)")
