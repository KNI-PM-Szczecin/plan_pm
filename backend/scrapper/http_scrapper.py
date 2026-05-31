"""
HTTP Scrapper - pobieranie planów bez przeglądarki.
~2s per plan vs ~15-20s z Selenium.

Odkrycia:
- Dane zwracane przez /*DXHTML*/ część odpowiedzi DevExpress
- Serwer czyta 'parametry' z POST body (format: 'YYYY-M-D;YYYY-M-D;zazButton;flow_id')
- Grid state (customOperationState + callbackState) pobierany z GET /PlanyTokowGrid/{id}
- Nie wymaga klikania, cookie banners, JS execution
"""
import json
import logging
import os
import re
import threading
import time
from concurrent.futures import ThreadPoolExecutor, as_completed

import requests
from bs4 import BeautifulSoup
from rich.progress import Progress

BASE_URL = "https://plany.am.szczecin.pl"
# Stałe stany okien (niezmienne w DevExpress)
WINDOW_STATE_HTML = '{"windowsState":"0:0:-1:0:0:0:-10000:-10000:1:0:0:0"}'.replace('"', '&quot;')
DX_CALLBACK_ARG = "c0:KV|2;[];GB|35;14|CUSTOMCALLBACK15|[object Object];"


def fetch_plan_http(flow_id, zaz_button=2):
    """
    Pobierz plan zajęć bez przeglądarki.

    zaz_button: 0=Dzisiaj, 1=Ten tydzień/zjazd, 2=Najbliższe zajęcia (domyślnie)

    Returns: lista wpisów (dict) zgodna z formatem scrapper.py
    """
    plan_url = f"{BASE_URL}/Plany/PlanyTokow/{flow_id}"
    grid_url = f"{BASE_URL}/Plany/PlanyTokowGrid/{flow_id}"
    custom_url = f"{BASE_URL}/Plany/PlanyTokowGridCustom/{flow_id}"

    session = requests.Session()
    session.headers.update({
        "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/146.0.0.0 Safari/537.36",
        "Accept-Language": "pl-PL,pl;q=0.9",
        "Accept": "*/*",
    })

    # Krok 1: Ustaw język PL + inicjalizuj sesję
    session.get(f"{BASE_URL}/ZmienJezyk?lang=pl", timeout=15)
    r_main = session.get(plan_url, timeout=30)

    # Krok 2: Wyciągnij daty z radio buttonów
    soup_main = BeautifulSoup(r_main.text, "html.parser")
    radios = soup_main.find_all("input", type="radio")
    tok_name = soup_main.find("strong")
    tok = tok_name.text.strip() if tok_name else str(flow_id)

    date_od, date_do = None, None
    if len(radios) > zaz_button:
        radio_val = radios[zaz_button].get("value", "")
        # Format: "2026,3,16\2026,4,15\2"
        parts_val = radio_val.split("\\")
        if len(parts_val) >= 2:
            od = parts_val[0].split(",")
            do = parts_val[1].split(",")
            if len(od) >= 3 and len(do) >= 3:
                date_od = f"{od[0]}-{od[1]}-{od[2]}"
                date_do = f"{do[0]}-{do[1]}-{do[2]}"

    if not date_od:
        from datetime import date
        today = date.today()
        date_od = date_do = f"{today.year}-{today.month}-{today.day}"

    # Krok 3: Pobierz stan gridu
    r_grid = session.get(grid_url, timeout=30)
    co_match = re.search(r"'customOperationState':'([^']+)'", r_grid.text)
    cb_match = re.search(r"'callbackState':'([^']+)'", r_grid.text)
    if not co_match or not cb_match:
        raise ValueError(f"[{flow_id}] Brak stanu gridu w odpowiedzi")

    co_state = co_match.group(1)
    cb_state = cb_match.group(1)

    state_html = json.dumps({
        "customOperationState": co_state,
        "callbackState": cb_state,
        "selection": "",
        "keys": []
    }, ensure_ascii=False).replace('"', '&quot;')

    # Krok 4: POST - wywołaj FiltrujDane server-side
    parametr = f"{date_od};{date_do};{zaz_button};{flow_id}"

    post_data = {
        "DXCallbackName": "gridViewPlanyTokow",
        "__DXCallbackArgument": DX_CALLBACK_ARG,
        "gridViewPlanyTokow": state_html,
        "gridViewPlanyTokow$custwindowState": WINDOW_STATE_HTML,
        "gridViewPlanyTokow$DXHFPState": WINDOW_STATE_HTML,
        "gridViewPlanyTokow$DXHFP$TPCFCm1$O": "Ustaw",
        "gridViewPlanyTokow$DXHFP$TPCFCm1$C": "Zaniechaj",
        "DXMVCEditorsValues": "{}",
        "parametry": parametr,
        "id": str(flow_id),
    }

    r = session.post(custom_url, data=post_data,
                     headers={"Content-Type": "application/x-www-form-urlencoded; charset=UTF-8",
                              "X-Requested-With": "XMLHttpRequest",
                              "Referer": plan_url,
                              "Origin": BASE_URL},
                     timeout=30)

    # Krok 5: Parsuj odpowiedź DevExpress (format: /*DX*/({...})/*DXHTML*/<HTML>)
    response_parts = r.text.split("/*DXHTML*/")
    if len(response_parts) < 2:
        raise ValueError(f"[{flow_id}] Brak /*DXHTML*/ w odpowiedzi (len={len(r.text)})")

    html_part = response_parts[1]
    soup = BeautifulSoup(html_part, "html.parser")

    # Krok 6: Wyciągnij dane z tabeli
    schedule_data = []
    current_date = ""

    all_rows = soup.find_all("tr", class_=True)
    for row in all_rows:
        classes = row.get("class", [])
        class_str = " ".join(classes)

        if "dxgvGroupRow_iOS" in class_str:
            tds = row.find_all("td")
            for td in tds:
                text = td.get_text(strip=True)
                if "Data Zajęć:" in text:
                    current_date = text.replace("Data Zajęć:", "").strip()
                    break
                elif any(str(y) in text for y in range(2020, 2032)) and "." in text:
                    current_date = text.strip()
                    break

        elif "dxgvDataRow_iOS" in class_str:
            all_tds = row.find_all("td")
            cells = all_tds[1:-1] if len(all_tds) > 2 else all_tds
            if len(cells) >= 11:
                entry = {
                    "Plan dla toku": tok,
                    "Data zajęć": current_date,
                    "Czas od": cells[0].get_text(strip=True),
                    "Czas do": cells[1].get_text(strip=True),
                    "Liczba godzin": cells[2].get_text(strip=True),
                    "Grupy": " ".join(cells[3].get_text(separator=" ", strip=True).split()),
                    "Przedmiot": cells[4].get_text(strip=True),
                    "Forma zajęć": cells[5].get_text(strip=True),
                    "Sala": cells[7].get_text(strip=True),
                    "Prowadzący": " ".join(cells[8].get_text(separator=" ", strip=True).split()),
                    "Forma zaliczenia": cells[9].get_text(strip=True),
                    "Uwagi": cells[11].get_text(strip=True),
                }
                schedule_data.append(entry)

    return schedule_data


class HttpScrapper:
    def __init__(self, output="./output/scrapper.json", input="./output/mapper.json"):
        self.logger = logging.getLogger(__name__)
        self.logger.setLevel(logging.INFO)
        self.logger.propagate = False  # keep other modules' logs out of scrapper.log
        self.output = output
        self.input = input
        print("Running HTTP scrapper")

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
            "total": 0,
        }
        self.failed_flows = []

    def scrapper(self, flow_id, progress=None):
        self.stats["total"] += 1
        log_print = progress.console.print if progress else print
        log_print(f"📥 Scraping plan {flow_id}... ")
        self.logger.info(f"[{flow_id}] Scraping plan")

        start_time = time.time()

        try:
            schedule_data = fetch_plan_http(str(flow_id))
        except Exception as e:
            log_print(f"❌ {flow_id}: Błąd pobierania.")
            self.logger.error(f"{flow_id}: Pobieranie nie powiodło się: {e}")
            with self.output_lock:
                self.failed_flows.append(flow_id)
                self.stats["interaction_fail"] += 1
            return

        with self.output_lock:
            self.results.extend(schedule_data)
            self.stats["success"] += 1

        self.logger.info(f"{flow_id}: Pobrano i sparsowano poprawnie — {len(schedule_data)} rekordów.")
        log_print(f"✅ Gotowe ({time.time() - start_time:.2f} s)")

    def run(self, max_workers=10, flow_id=-1):
        if flow_id == -1:
            with open(self.input, "r", encoding="utf-8") as f:
                data = json.load(f)
            with Progress() as p:
                total = len(data.keys())
                task = p.add_task("Scraping...", total=total)
                with ThreadPoolExecutor(max_workers=max_workers) as executor:
                    futures = [executor.submit(self.scrapper, fid, p) for fid in sorted(data.keys())]
                    for future in as_completed(futures):
                        try:
                            future.result()
                        except Exception as e:
                            self.logger.error(f"Nieoczekiwany błąd wątku: {e}")
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


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="HTTP Scrapper planów toków (bez przeglądarki)")
    parser.add_argument("--id", type=str, default=None, help="Scrape tylko jeden tok o podanym ID")
    parser.add_argument("--workers", type=int, default=10, help="Liczba równoległych wątków (domyślnie 10)")
    parser.add_argument("--output", type=str, default="./output/scrapper.json", help="Plik wyjściowy JSON")
    parser.add_argument("--input", type=str, default="./output/mapper.json", help="Plik wejściowy (mapper)")
    args = parser.parse_args()

    s = HttpScrapper(output=args.output, input=args.input)
    s.run(max_workers=args.workers, flow_id=args.id if args.id else -1)
