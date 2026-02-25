import time
import json
import threading
from concurrent.futures import ThreadPoolExecutor, as_completed
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.chrome.options import Options
import logging
import os
from rich.progress import Progress

class Scrapper:
    def __init__(self, debug = False, output = "./output/scrapper.json", input = "./output/mapper.json"):
        self.logger = logging.getLogger(__name__)
        self.logger.setLevel(logging.INFO)
        self.debug = debug
        self.output = output
        self.input = input
        print("Running scrapper")
        
        output_dir = os.path.dirname(self.output)
        if output_dir:
            os.makedirs(output_dir, exist_ok=True)
        
        if os.path.exists(self.output):
            print("Znaleziono poprzedni plik scrappera. Usuwam.")
            os.remove(self.output)
        
        if not self.logger.handlers:
            os.makedirs("./logs", exist_ok=True)
            handler = logging.FileHandler("./logs/scrapper.log", mode="w+", encoding="utf-8")
            formatter = logging.Formatter("%(asctime)s [%(levelname)s] %(message)s")
            handler.setFormatter(formatter)
            self.logger.addHandler(handler)

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

    def scrapper(self, flow_id, progress=None):
        self.stats["total"] += 1
        url = f'https://plany.am.szczecin.pl/Plany/PlanyTokow/{flow_id}'

        options = Options()
        if not self.debug:
            options.add_argument('--headless=new') 
            options.add_argument('--no-sandbox')
            options.add_argument('--disable-dev-shm-usage')

        start_time = time.time()
        
        log_print = progress.console.print if progress else print
        log_print(f"📥 Scraping plan {flow_id}... ")

        self.logger.info(f"[{flow_id}] Scraping plan")

        driver = webdriver.Chrome(options=options)
        driver.get(url)

        try:
            wait = WebDriverWait(driver, 60)
            self.logger.info(f"[{flow_id}] Czekam na cc_essential")
            wait.until(EC.presence_of_element_located((By.ID, "cc_essential")))

            self.logger.info(f"[{flow_id}] Odrzucam cookies")
            driver.find_elements(By.CSS_SELECTOR, "button.btn.my-2")[1].click()

            self.logger.info(f"[{flow_id}] Otwieram checkdown z językami")
            driver.find_element(By.ID, "ho-language").click()

            self.logger.info(f"[{flow_id}] Wybieram język Polski")
            driver.find_element(By.XPATH, "/html/body/div[1]/div/header/nav/div/div[1]/div/div/ul/li/a").click()

            self.logger.info(f"[{flow_id}] Wybieram 3 radio button")
            driver.find_elements(By.CLASS_NAME, "custom-control-label")[2].click()
            
            self.logger.info(f"[{flow_id}] Ściągam nazwe toku")
            tok = driver.find_element(By.TAG_NAME, "strong").text.strip()
            
            old_table = driver.find_element(By.ID, "gridViewPlanyTokow_DXMainTable")
            
            self.logger.info(f"[{flow_id}] Filtruje dane")
            wait.until(EC.element_to_be_clickable((By.ID, "SzukajLogout"))).click()
            
            self.logger.info(f"[{flow_id}] Czekam na odswiezenie tabeli")
            wait.until(EC.staleness_of(old_table))
            
            schedule_data = []
            current_date = ""
        
            self.logger.info(f"[{flow_id}] Pobieram dane z tabeli")
            table = driver.find_element(By.ID, "gridViewPlanyTokow_DXMainTable")
            rows = table.find_elements(By.TAG_NAME, "tr")
            for row in rows:
                classes = row.get_attribute("class") or ""
                if "dxgvGroupRow_iOS" in classes:
                    date_cells = row.find_elements(By.CSS_SELECTOR, "td.dxgv.dxgRRB")
                    if len(date_cells) > 1:
                        current_date = date_cells[1].text.replace("Data Zajęć: ", "").strip()
                elif "dxgvDataRow_iOS" in classes:
                    all_tds = row.find_elements(By.TAG_NAME, "td")
                    cells = all_tds[1:-1]
                    if len(cells) >= 11:
                        entry = {
                            "Plan dla toku": tok,
                            "Data zajęć": current_date,
                            "Czas od": cells[0].get_attribute('textContent').strip(),
                            "Czas do": cells[1].get_attribute('textContent').strip(),
                            "Liczba godzin": cells[2].get_attribute('textContent').strip(),
                            "Grupy": " ".join(cells[3].get_attribute('textContent').strip().split()),
                            "Przedmiot": cells[4].get_attribute('textContent').strip(),
                            "Forma zajęć": cells[5].get_attribute('textContent').strip(),
                            "Sala": cells[7].get_attribute('textContent').strip(),
                            "Prowadzący": " ".join(cells[8].get_attribute('textContent').strip().split()),
                            "Forma zaliczenia": cells[9].get_attribute('textContent').strip(),
                            "Uwagi": cells[10].get_attribute('textContent').strip()
                        }
                        schedule_data.append(entry)
            
        except Exception as e:
            log_print(f"❌ {flow_id}: Błąd interakcji.")
            self.logger.error(f"{flow_id}: Interakcja ze stroną nie powiodła się: {e}")
            self.failed_flows.append(flow_id)
            self.stats["interaction_fail"] += 1
            driver.quit()
            return

        driver.quit()

        try:
            lectures = schedule_data
            if self.debug:
                print(schedule_data)
            
            with self.output_lock:
                self.results.extend(lectures)
            self.stats["success"] += 1
            self.logger.info(f"{flow_id}: Pobrano i sparsowano poprawnie.")
            self.logger.info(f"[{flow_id}] Lectures: {str(lectures)[:300]}...")
        except Exception as e:
            log_print(f"❌ {flow_id}: Błąd parsowania.")
            self.logger.error(f"{flow_id}: Błąd parsowania pliku: {e}")
            self.failed_flows.append(flow_id)
            self.stats["parse_fail"] += 1

        log_print(f"✅ Gotowe ({time.time() - start_time:.2f} s)")

    def run(self, max_workers=5, flow_id = -1):
        if flow_id == -1:
            print("Debug mode off, running with full threads.")
            with open(self.input, "r", encoding="utf-8") as f:
                data = json.load(f)
            with Progress() as p:
                total = len(data.keys())
                task = p.add_task("Scraping...", total=total)
                with ThreadPoolExecutor(max_workers=max_workers) as executor:
                    futures = [executor.submit(self.scrapper, flow_id, p) for flow_id in sorted(data.keys())]
                    for future in as_completed(futures):

                        future.result() 
                        p.update(task, advance=1, description=f"Scraping... {self.stats['success']} done")
        else:
            self.scrapper(flow_id)
            
        # Zapis wyników do pliku
        with open(self.output, "w+", encoding="utf-8") as f:
            json.dump(self.results, f, ensure_ascii=False, indent=2)

        # Statystyki
        total = self.stats["total"]
        print("\n📊 Statystyki:")
        print(f" - Łącznie prób:        {total}")
        print(f" - Sukcesów:           {self.stats['success']}")
        print(f" - Błędy interakcji:   {self.stats['interaction_fail']}")
        print(f" - Nie pobrano pliku:  {self.stats['download_fail']}")
        print(f" - Błędy parsowania:   {self.stats['parse_fail']}")
        print(f" - Niepowodzenia:      {len(self.failed_flows)}")

        self.logger.info("Zakończono. Statystyki:")
        for k, v in self.stats.items():
            self.logger.info(f"  {k}: {v}")

