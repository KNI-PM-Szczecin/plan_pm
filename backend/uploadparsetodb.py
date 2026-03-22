from parser import Parser
from json2db import json2db
import time

start_time = time.time()
print("Parsing and uploading to DB")

Parser(input="scrapper.json").run()

json2db(input="./output/parser.json", clear=True).run()

print(f"✅ PlanPM gotowy ({time.time() - start_time:.2f} s)")