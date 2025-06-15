import time
import json
from selenium import webdriver 
from selenium.webdriver.chrome.service import Service as ChromeService
from selenium.webdriver.firefox.service import Service as FirefoxService
from selenium.webdriver.common.by import By
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.chrome.options import Options as ChromeOptions
from selenium.webdriver.firefox.options import Options as FirefoxOptions
from webdriver_manager.chrome import ChromeDriverManager
from webdriver_manager.firefox import GeckoDriverManager

def create_driver():
    driver = None
    
    try:
        print("🦊 Próba uruchomienia Firefox...")
        firefox_options = FirefoxOptions()
        firefox_options.add_argument("--headless")
        
        firefox_service = FirefoxService(GeckoDriverManager().install())
        driver = webdriver.Firefox(service=firefox_service, options=firefox_options)
        print("✅ Firefox uruchomiony pomyślnie!")
        return driver

    except Exception as e:
        print(f"❌ Firefox nie działa: {e}")
        print("🔄 Przełączanie na Chrome...")

        try:
            chrome_options = ChromeOptions()
            chrome_options.add_argument("--headless=new")
            
            chrome_service = ChromeService(ChromeDriverManager().install())
            driver = webdriver.Chrome(service=chrome_service, options=chrome_options)
            print("✅ Chrome uruchomiony pomyślnie!")
            return driver
            
        except Exception as chrome_error:
            print(f"❌ Chrome też nie działa: {chrome_error}")
            raise Exception("Nie udało się uruchomić ani Firefox, ani Chrome")

driver = create_driver()

url = f'https://plany.am.szczecin.pl/Index/Jezyk?lang=pl&url=%2FPlany%2FZnajdzTok%3FTrybStudiowId%3D-1%26WydzialId%3D735%26naborId%3D-1%26kierunekId%3D%26specjalnoscId%3D'

driver.get(url)

WebDriverWait(driver, 5).until(EC.presence_of_element_located((By.ID, "cc_essential")))
driver.find_element(By.CSS_SELECTOR, "button.btn.btn-danger.my-2").click()

rows = driver.find_elements(By.CLASS_NAME, "dxgvDataRow_iOS")

kierunki = {}
from collections import defaultdict

kierunki = defaultdict(lambda: defaultdict(lambda: defaultdict(lambda: defaultdict(set))))

for row in rows:
    driver.execute_script("arguments[0].style.backgroundColor = 'lightblue';", row)
    children = row.find_elements(By.CSS_SELECTOR, "*")

    kierunek = ""
    specjalizacja = ""
    rok = None
    stopien = ""
    tryb = ""

    for index, child in enumerate(children):
        child.text
        if index == 2:
            kierunek = child.text.strip()
        elif index == 3:
            specjalizacja = child.text.strip()
        elif index == 4:
            tok = child.text.split()
            try:
                if "mgr" in tok:
                    idx = tok.index("mgr")
                elif "inż." in tok:
                    idx = tok.index("inż.")
                elif "lic" in tok:
                    idx = tok.index("lic")
                else:
                    print("⚠️ Nie znaleziono stopnia")
                    continue

                stopien = tok[idx]
                rok = int(float(tok[idx + 1]))
                tryb = tok[idx - 1]
            except Exception as e:
                print(f"❌ Błąd parsowania tok: {tok} – {e}")
                continue

    if not kierunek or not rok:
        print(f"POMINIĘTO: kierunek={kierunek}, specjalizacja={specjalizacja}, rok={rok}")
        continue

    specjalizacja_do_zapisu = specjalizacja if specjalizacja else kierunek
    kierunki[kierunek][stopien][tryb][rok].add(specjalizacja_do_zapisu)
    
def convert_sets_to_lists(obj):
    if isinstance(obj, dict):
        return {k: convert_sets_to_lists(v) for k, v in obj.items()}
    elif isinstance(obj, set):
        return list(obj)
    return obj

final_json = convert_sets_to_lists(kierunki)
with open("kierunki.json", "w", encoding="utf-8") as f:
    json.dump(final_json, f, ensure_ascii=False, indent=2)


time.sleep(15)
driver.quit()