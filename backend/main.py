from mapper import Mapper
from scrapper import Scrapper
from parser import Parser
from json2db import json2db
import time

start_time = time.time()
print("Starting PlanPM worker")

Mapper(output="./output/mapper.json").run(minID=0, maxID=600)

Scrapper(input="./output/mapper.json", output="./output/scrapper.json").run(max_workers=5)

Parser(input="scrapper.json").run()

json2db(input="./output/parser.json").run()

print(f"✅ PlanPM gotowy ({time.time() - start_time:.2f} s)")
