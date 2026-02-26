import json
import datetime
import locale

def analyze_weekend_classes(input_file="./output/parser.json"):
    """
    Analizuje plik parser.json w poszukiwaniu zajęć odbywających się w soboty i niedziele,
    uwzględniając typ programu studiów.
    """
    try:
        # Ustawienie polskiej lokalizacji dla nazw dni tygodnia
        locale.setlocale(locale.LC_TIME, 'pl_PL.UTF-8')
    except locale.Error:
        print("Ostrzeżenie: Polska lokalizacja 'pl_PL.UTF-8' nie jest dostępna. Nazwy dni mogą być po angielsku.")

    try:
        with open(input_file, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except FileNotFoundError:
        print(f"Błąd: Plik {input_file} nie został znaleziony.")
        return

    # POPRAWKA: Stworzenie mapy ID -> obiekt z nazwą i typem programu
    program_map = {i: {'name': program['name'], 'type': program['program_type']} for i, program in enumerate(data['programs'])}

    weekend_classes = {}

    print("Analizowanie danych...\n")

    for sclass in data.get("classes", []):
        try:
            timestamp = int(sclass["startTime"])
            dt_object = datetime.datetime.fromtimestamp(timestamp)

            if dt_object.weekday() >= 5: # 5 = Sobota, 6 = Niedziela
                program_id = sclass["program"]
                
                # POPRAWKA: Pobranie całego obiektu informacji o programie
                program_info = program_map.get(program_id, {"name": "Nieznany program", "type": "N/A"})
                program_name = program_info['name']
                program_type = program_info['type']
                
                subject_name = data["subjects"][sclass["subject"]]
                
                class_info = {
                    "przedmiot": subject_name,
                    "data": dt_object.strftime("%Y-%m-%d (%A)"),
                    "godzina_start": dt_object.strftime("%H:%M")
                }

                if program_name not in weekend_classes:
                    # POPRAWKA: Inicjalizacja struktury przechowującej typ i listę zajęć
                    weekend_classes[program_name] = {
                        'type': program_type,
                        'classes': []
                    }
                
                weekend_classes[program_name]['classes'].append(class_info)

        except (ValueError, TypeError) as e:
            print(f"Pominięto wpis z powodu błędu danych: {sclass} - Błąd: {e}")

    if not weekend_classes:
        print("Nie znaleziono żadnych zajęć odbywających się w weekendy.")
        return

    print("Znaleziono zajęcia weekendowe dla następujących kierunków:\n")
    # POPRAWKA: Aktualizacja pętli, aby wyświetlać typ programu
    for program, program_data in weekend_classes.items():
        type_string = "Niestacjonarne" if program_data['type'] == 'N' else "Stacjonarne"
        print(f"--- {program} ({type_string}) ---")
        for c in program_data['classes']:
            print(f"  - Przedmiot: {c['przedmiot']}, Data: {c['data']} {c['godzina_start']}")
        print("\n")


def xd(input_file="./output/parser.json"):
    with open(input_file, 'r', encoding='utf-8') as f:
            data = json.load(f)
            # print(data["teachersclasses"])
            for tc in data["teachersclasses"]:
                if (len(tc["teachers"]) > 1):
                    print(tc)
                    sclass = tc["class"]
                    print(data["classes"][sclass])

if __name__ == "__main__":
    # analyze_weekend_classes()
    xd()
