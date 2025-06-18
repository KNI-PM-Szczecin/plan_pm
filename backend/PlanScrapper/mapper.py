# Mapper by Piotr Wittig
# Mapper ma na celu znalezienie id, które istnieją, a następnie zapisać je w pliku .json

import requests
from bs4 import BeautifulSoup
from concurrent.futures import ThreadPoolExecutor, as_completed
import time
import os
import json
import logging

class Mapper:
    def __init__(self):
        self.stats = {
            "success": 0,
            "interaction_fail": 0,
            "total": 0
        }
        self.valid_records = {}

        logging.basicConfig(
            filename="./logs/mapper.log",
            filemode="w",
            level=logging.INFO,
            format="%(asctime)s [%(levelname)s] %(message)s"
        )

    def check_page(self, flow_id):
        url = f"https://plany.am.szczecin.pl/Plany/PlanyTokow/{flow_id}"
        self.stats["total"] += 1
        try:
            response = requests.get(url, timeout=20)
            if response.status_code == 200:
                soup = BeautifulSoup(response.text, "html.parser")
                plan_header = soup.find(string=lambda text: text and "Plan dla toku:" in text)
                if plan_header:
                    parent = plan_header.parent
                    strong_tag = parent.find_next("strong")
                    if strong_tag:
                        name = strong_tag.text.strip()
                        logging.info(f"{flow_id}: ✅ Nazwa toku: {name}")
                        self.stats["success"] += 1
                        return flow_id, name
        except requests.RequestException as e:
            logging.error(f"{flow_id}: ❌ Błąd połączenia: {e}")

        logging.warning(f"{flow_id}: ❌ Nie znaleziono lub brak planu.")
        self.stats["interaction_fail"] += 1
        return flow_id, None

    def run(self, minID: int = 380, maxID: int = 430, output: str = "flows.json"):
        start_time = time.time()

        with ThreadPoolExecutor(max_workers=10) as executor:
            futures = {executor.submit(self.check_page, flow_id): flow_id for flow_id in range(minID, maxID)}
            for future in as_completed(futures):
                flow_id, result = future.result()
                if result:
                    self.valid_records[flow_id] = result
                    print(f"✅ ID found: {flow_id}, Nazwa toku: {result}")
                else:
                    print(f"❌ ID {flow_id} — brak planu.")

        # Zapis do pliku
        if os.path.exists(output):
            os.remove(output)
        with open(output, "w", encoding="utf-8") as f:
            json.dump(self.valid_records, f, indent=4, ensure_ascii=False)

        end_time = time.time()
        total_time = end_time - start_time

        # Statystyki
        print("\n📊 Statystyki:")
        print(f" - Przetworzono ID:     {self.stats['total']}")
        print(f" - Poprawne plany:      {self.stats['success']}")
        print(f" - Brak lub błąd:       {self.stats['interaction_fail']}")
        print(f" - Czas wykonania:      {total_time:.2f} s")

        logging.info("\n==== ZAKOŃCZONO MAPOWANIE ====")
        for k, v in self.stats.items():
            logging.info(f"  {k}: {v}")
        logging.info(f"  Czas wykonania: {total_time:.2f} s")