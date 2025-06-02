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

output_lock = threading.Lock()


class Scrapper:
    def __init__(self):
        self.output_lock = threading.Lock()

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
        url = f'https://plany.am.szczecin.pl/Plany/PlanyTokow/{flow_id}'
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
            WebDriverWait(driver, 5).until(EC.presence_of_element_located((By.ID, "cc_essential")))
            driver.find_element(By.CSS_SELECTOR, "button.btn.btn-danger.my-2").click()
            driver.find_elements(By.CLASS_NAME, "custom-control-label")[2].click()
            driver.find_element(By.ID, "SzukajLogout").click()

            saveical = WebDriverWait(driver, 5).until(
                EC.presence_of_all_elements_located((By.ID, "WrappingTextLink"))
            )[2]
            saveical.click()
        except Exception as e:
            print(f"❌ {flow_id}: Błąd interakcji ze stroną.")
            driver.quit()
            shutil.rmtree(download_dir, ignore_errors=True)
            return

        ics_file = download_dir / "Plany.ics"
        for _ in range(30):
            if ics_file.exists():
                break
            time.sleep(0.2)

        driver.quit()

        if not ics_file.exists():
            print(f"❌ {flow_id}: Nie pobrano pliku.")
            shutil.rmtree(download_dir, ignore_errors=True)
            return

        try:
            lectures = self.icalToJSON(ics_file)
            with self.output_lock:
                with open("plany.json", "a") as f:
                    for lecture in lectures:
                        json.dump(lecture, f, ensure_ascii=False)
                        f.write(",\n")
        except Exception as e:
            print(f"❌ {flow_id}: Błąd parsowania: {e}")
        finally:
            try:
                ics_file.unlink(missing_ok=True)
                shutil.rmtree(download_dir, ignore_errors=True)
            except Exception:
                pass

        print(f"✅ Gotowe ({time.time() - start_time:.2f} s)")

    def run(self, max_workers=5):
        with open("plany.json", "w") as f:
            f.write("[\n")

        with open("flows.json", "r") as f:
            data = json.load(f)

        with ThreadPoolExecutor(max_workers=max_workers) as executor:
            futures = [executor.submit(self.scrapper, flow_id) for flow_id in data.keys()]
            for future in as_completed(futures):
                pass

        # Usunięcie ostatniego przecinka
        with open("plany.json", "rb+") as f:
            f.seek(-2, os.SEEK_END)
            if f.read(2) == b",\n":
                f.seek(-2, os.SEEK_END)
                f.truncate()
            f.write(b"\n]")

        print("✅ Wszystkie plany pobrane.")