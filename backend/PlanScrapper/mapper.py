# Mapper by Piotr Wittig
# Mapper ma na celu znalezienie id, które istnieją, a następnie zapisać je w pliku .json
import requests
from bs4 import BeautifulSoup
from concurrent.futures import ThreadPoolExecutor, as_completed
import time
import os
import json

class Mapper():
    def run(minID: int = 380, maxID: int = 430, output: str = "flows.json"):
        def check_page(flow_id):
            url = f"https://plany.am.szczecin.pl/Plany/PlanyTokow/{flow_id}"
            try:
                response = requests.get(url, timeout=5)
                if response.status_code == 200:
                    soup = BeautifulSoup(response.text, "html.parser")
                    plan_header = soup.find(string=lambda text: text and "Plan dla toku:" in text)
                    if plan_header:
                        parent = plan_header.parent
                        strong_tag = parent.find_next("strong")
                        if strong_tag:
                            return flow_id, strong_tag.text.strip()
            except requests.RequestException as e:
                print(f"Error connecting to {url}: {e}")
            return flow_id, None

        start_time = time.time()
        valid_records = {}

        with ThreadPoolExecutor(max_workers=10) as executor:
            futures = {executor.submit(check_page, flow_id): flow_id for flow_id in range(minID, maxID)}
            for future in as_completed(futures):
                flow_id, result = future.result()
                if result:
                    print(f"✅ ID found: {flow_id}, Nazwa toku: {result}")
                    valid_records[flow_id] = result
                    
        if os.path.exists(output):
            os.remove(output)
        with open(output, "a") as f:
            print("\nPoprawne rekordy:")
            for flow_id, name in valid_records.items():
                print(f"ID: {flow_id}, Nazwa toku: {name}")
            json.dump(valid_records, f, indent=4, ensure_ascii=False)

        end_time = time.time()
        total_time = end_time - start_time
        print(f"\nTotal execution time: {total_time:.2f} seconds")