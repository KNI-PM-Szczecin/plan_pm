import argparse
import time

from console_setup import force_utf8_output

force_utf8_output()

from mapper import Mapper
from scrapper import HttpScrapper
from parser import Parser
from json2db import json2db

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
json2db(input="./output/parser.json", clear=True).run()

print(f"✅ PlanPM gotowy ({time.time() - start_time:.2f} s)")
