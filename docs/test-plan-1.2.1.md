# Plan testów poprawek 1.2.1

Testy destrukcyjnych operacji wykonuj najpierw na środowisku `test`. Nie używaj
`--force` na produkcji bez ręcznego sprawdzenia pełnego pliku wejściowego.

## 1. Automatyczna weryfikacja

1. Backend:
   ```bash
   cd backend
   uv sync --extra dev
   uv run pytest -m "not slow"
   ```
   Oczekiwane: wszystkie szybkie testy przechodzą.
2. Frontend:
   ```bash
   cd frontend
   flutter pub get
   flutter analyze
   flutter test
   ```
   Oczekiwane: `No issues found` i wszystkie testy przechodzą.
3. Android/Kotlin:
   ```bash
   cd frontend/android
   ./gradlew :app:compileDebugKotlin
   ```
   Oczekiwane: `BUILD SUCCESSFUL`.

## 2. Bramki bezpieczeństwa backendu

1. Utwórz kopię `backend/output/parser.json` z mniej niż 100 elementami w
   `classes` i uruchom w trybie testowym:
   ```bash
   cd backend
   PLANPM_ENV=test uv run python -m json2db.json2db --input /tmp/parser-small.json --clear
   ```
2. Oczekiwane: proces kończy się błędem `Refusing to clear the database` przed
   połączeniem i czyszczeniem bazy.
3. Ten sam plik uruchom z `--dry-run`; powinien się tylko wyświetlić.
4. `--force` sprawdzaj wyłącznie na bazie testowej i po wykonaniu backupu.
5. Dla updatera struktury zamockuj/podmień wynik na pustą listę albo uruchom test
   `test_main_refuses_to_clear_suspiciously_small_structure`. Oczekiwane:
   `Refusing to clear university structure` i brak DELETE w Supabase.
6. W panelu admina i przez MCP uruchom krok `json2db` na małym pliku. Oba wejścia
   muszą pokazać ten sam błąd bramki co CLI.

## 3. Backend — poprawność importu

1. Na bazie testowej uruchom pełny import prawidłowego `parser.json`.
2. Sprawdź dwa programy o tej samej nazwie, ale innym trybie/roku/poziomie:
   zajęcia obu programów muszą istnieć, a prowadzący mają być podpięci do obu.
3. Uruchom import bez `--clear` dwa razy i policz sale z `building IS NULL`.
   Liczba nie może wzrosnąć po drugim imporcie.
4. Podaj scraperowi wiersz z 11 komórkami. Wiersz ma zostać pominięty bez
   `IndexError`; poprawny wiersz z 12 komórkami ma zostać sparsowany.
5. Uruchom:
   ```bash
   cd backend
   uv run python -c "import fastmcp; print(fastmcp.__version__)"
   ```
   Import musi działać na świeżym środowisku.

## 4. Przełączanie roli i cache

1. Zaloguj aplikację jako wykładowca i upewnij się, że jego plan jest widoczny.
2. Ustawienia → rola → student; wypełnij dane studenta i na ekranie grup wybierz
   `Pomiń`.
3. Oczekiwane: aplikacja przechodzi do trybu studenta, plan wykładowcy znika,
   SQLite i widżet zawierają dane studenta, a pusta lista grup pozostaje zapisana.
4. Powtórz, wybierając grupy i `Zapisz`; plan ma być przefiltrowany do wyboru.
5. Wejdź w `Zmień grupy` i wróć bez zapisu. Reset grup pozostaje celowym
   zachowaniem i nie jest regresją w tej wersji.

## 5. Frontend

1. Zmień motyw, akcent i język po uruchomieniu aplikacji. W logach nie może
   pojawić się kolejny pełny `[APP-INIT] Start` ani ponowny start synchronizacji.
2. Ustaw dane testowe z zajęciami 31 stycznia i 1 lutego. Wieczorem 31 stycznia
   sekcja najbliższych zajęć ma pokazać również 1 lutego.
3. Dodaj ponad 20 newsów z różnymi `created_at`. Po synchronizacji widoczne mają
   być najnowsze, w kolejności malejącej.
4. Na home wykonaj pull-to-refresh po zmianie najnowszego newsa w bazie. Karta
   newsa i plan mają odświeżyć się w tym samym cyklu.
5. Edytuj wykładowcę w ustawieniach na świeżej instalacji. Po powrocie muszą być
   dostępne zarówno zajęcia, jak i newsy.

## 6. Widżet Android

1. Ustaw `kDebugWidget=true`, uruchom aplikację i dodaj każdy z trzech rozmiarów
   widżetu. Dane powinny się wyświetlić.
2. Dotknij tła, pustego stanu i karty widżetu. Każdy tap ma otworzyć aplikację.
3. Zmień datę w zapisanym `schedule_data` na wczorajszą i wymuś odświeżenie
   widżetu (`adb shell cmd appwidget update`). Oczekiwany jest pusty stan, nie
   wczorajszy plan. Systemowy refresh następuje też co 30 minut.
4. Zmień język aplikacji na PL/EN/UK, otwórz aplikację, a następnie odśwież
   widżet. Tekst pustego stanu ma odpowiadać językowi aplikacji; etykiety w
   pickerze odpowiadają językowi systemu Android.

## 7. Admin, CI i hook

1. Uruchom panel admina. `GET /pipeline/run/mapper` ma zwrócić 405, a przycisk
   w UI ma uruchomić ten krok przez POST i streamować log.
2. Żądanie z `Host: attacker.example` ma zwrócić 403; `localhost:5050` działa.
3. Ustaw kolejno każdą flagę `const bool` w `env_config.dart` na `true` — check
   deploymentu ma zawieść. Usuń/zmień nazwę flagi — check również ma zawieść.
4. Sprawdź wersje `1.2.2+25`, `1.2.1+26` i niższe: CI ma wymagać osobnego wzrostu
   wersji marketingowej i build numberu.
5. Wpis `## 1.2.10` nie może zaliczyć changelogu dla wersji `1.2.1`.
6. Ustaw `.env_mode` na `test`, literówkę i `prod`: tylko `prod` przechodzi CI.
7. Zainstaluj hook:
   ```bash
   ./scripts/install_hooks.sh
   ```
   Commit w trybie innym niż `prod` ma zostać zablokowany.
