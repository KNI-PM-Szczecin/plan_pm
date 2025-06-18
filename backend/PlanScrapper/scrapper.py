import os
import time
import json
import shutil
import threading
from pathlib import Path
from concurrent.futures import ThreadPoolExecutor, as_completed
from selenium import webdriver 
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.chrome.options import Options
import icalendar
import logging

class Scrapper:
    def __init__(self):
        self.output_lock = threading.Lock()
        self.results = []
        self.stats = {
            "success": 0,
            "download_fail": 0,
            "interaction_fail": 0,
            "parse_fail": 0,
            "total": 0
        }
        self.failed_flows = []

        logging.basicConfig(
            filename="./logs/scraper.log",
            filemode="w",
            level=logging.INFO,
            format="%(asctime)s [%(levelname)s] %(message)s"
        )

    def icalToJSON(self, ics_path):
        calendar = icalendar.Calendar.from_ical(ics_path.read_bytes())
        lectures = []
        for event in calendar.walk('VEVENT'):
            desc = str(event.get("DESCRIPTION")).split("\n")
            subject = {}
            for lecture in desc:
                if len(lecture.strip()) == 0:
                    continue
                parts = lecture.split(":")
                if len(parts) < 2:
                    continue 
                header = parts[0].strip()
                content = ':'.join(parts[1:]).strip()
                subject[header] = content
            lectures.append(subject)
        return lectures

    def scrapper(self, flow_id):
        self.stats["total"] += 1
        url = f'https://plany.am.szczecin.pl/Index/Jezyk?lang=pl&url=%2FPlany%2FPlanyTokow%2F/{flow_id}'
        download_dir = Path(f"./downloads/{flow_id}")
        download_dir.mkdir(parents=True, exist_ok=True)

        service = Service(executable_path="./chromedriver")
        options = Options()
        options.add_argument("--headless=new")
        options.add_experimental_option("prefs", {
            "download.default_directory": str(download_dir.resolve()),
            "download.directory_upgrade": True,
            "download.prompt_for_download": False
        })

        start_time = time.time()
        print(f"📥 Scraping plan {flow_id}... ", end="")

        driver = webdriver.Chrome(service=service, options=options)
        driver.get(url)

        try:
            WebDriverWait(driver, 60).until(EC.presence_of_element_located((By.ID, "cc_essential")))
            driver.find_element(By.CSS_SELECTOR, "button.btn.btn-danger.my-2").click()
            driver.find_elements(By.CLASS_NAME, "custom-control-label")[2].click()
            driver.find_element(By.ID, "SzukajLogout").click()

            saveical = WebDriverWait(driver, 60).until(
                EC.presence_of_all_elements_located((By.ID, "WrappingTextLink"))
            )[2]
            time.sleep(1) #Odczekaj jedną sekundę od załadowania strony. To powoduje, ze wyniki są bardziej consistent.
            saveical.click()
        except Exception as e:
            print(f"❌ {flow_id}: Błąd interakcji.")
            logging.error(f"{flow_id}: Interakcja ze stroną nie powiodła się: {e}")
            self.failed_flows.append(flow_id)
            self.stats["interaction_fail"] += 1
            driver.quit()
            shutil.rmtree(download_dir, ignore_errors=True)
            return

        ics_file = download_dir / "Plany.ics"
        # Sprawdzaj 30 razy co 0.2 sekunde czy plan juz sie pobral. Jezeli tak, to wyjdz z petli wczesniej
        for _ in range(30):
            if ics_file.exists():
                break
            time.sleep(0.2)

        driver.quit()

        # Jezeli ics nie istnieje, to daj to do loga.
        if not ics_file.exists():
            print(f"❌ {flow_id}: Nie pobrano pliku.")
            logging.warning(f"{flow_id}: Nie udało się pobrać pliku .ics.")
            self.failed_flows.append(flow_id)
            self.stats["download_fail"] += 1
            shutil.rmtree(download_dir, ignore_errors=True)
            return

        try:
            lectures = self.icalToJSON(ics_file)
            with self.output_lock:
                self.results.extend(lectures)
            self.stats["success"] += 1
            logging.info(f"{flow_id}: Pobrano i sparsowano poprawnie.")
        except Exception as e:
            print(f"❌ {flow_id}: Błąd parsowania.")
            logging.error(f"{flow_id}: Błąd parsowania pliku: {e}")
            self.failed_flows.append(flow_id)
            self.stats["parse_fail"] += 1
        finally:
            try:
                ics_file.unlink(missing_ok=True)
                shutil.rmtree(download_dir, ignore_errors=True)
            except Exception:
                pass

        print(f"✅ Gotowe ({time.time() - start_time:.2f} s)")

    def run(self, max_workers=5):
        with open("./output/flows.json", "r") as f:
            data = json.load(f)

        with ThreadPoolExecutor(max_workers=max_workers) as executor:
            futures = [executor.submit(self.scrapper, flow_id) for flow_id in sorted(data.keys())]
            for future in as_completed(futures):
                pass

        # Zapis wyników do pliku
        with open("./output/plany.json", "w", encoding="utf-8") as f:
            json.dump(self.results, f, ensure_ascii=False, indent=2)

        # Zapis nieudanych do osobnego pliku
        with open("./output/failed.json", "w", encoding="utf-8") as f:
            json.dump(self.failed_flows, f, indent=2)

        # Statystyki
        total = self.stats["total"]
        print("\n📊 Statystyki:")
        print(f" - Łącznie prób:        {total}")
        print(f" - Sukcesów:           {self.stats['success']}")
        print(f" - Błędy interakcji:   {self.stats['interaction_fail']}")
        print(f" - Nie pobrano pliku:  {self.stats['download_fail']}")
        print(f" - Błędy parsowania:   {self.stats['parse_fail']}")
        print(f" - Niepowodzenia:      {len(self.failed_flows)} zapisane w failed.json")

        logging.info("Zakończono. Statystyki:")
        for k, v in self.stats.items():
            logging.info(f"  {k}: {v}")