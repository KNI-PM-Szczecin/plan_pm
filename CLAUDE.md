# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

---

# Plan PM

Aplikacja mobilna (Flutter) planu zajęć dla Politechniki Morskiej w Szczecinie, z backendem Python do scrappowania i przetwarzania danych. Open-source, obsługuje studentów i wykładowców.

---

## Struktura repozytorium

```
plan_pm/
├── frontend/          # Aplikacja Flutter (iOS + Android)
├── backend/           # Pipeline Python (scraping → Supabase)
├── scripts/           # switch_env.py — przełącza tryb test/prod
├── docs/              # Dokumentacja deploymentu
└── .github/workflows/ # CI/CD (deploy, walidacje)
```

---

## Frontend (Flutter)

### Uruchamianie

```bash
cd frontend
flutter pub get
flutter run
```

Lokalizacje generuje się po zmianie plików `.arb`:
```bash
flutter gen-l10n
```

### Wersja

`pubspec.yaml` → `version: X.Y.Z+build` — **oba człony muszą być wyższe niż na branchu `deployment` przy PR**.

### Kluczowe pliki

| Plik | Rola |
|------|------|
| `lib/main.dart` | Inicjalizacja Supabase, notifierów, splash screen |
| `lib/app.dart` | Root `MaterialApp` — tema, lokalizacja, routing |
| `lib/app_initialization.dart` | Logika startowa: sprawdza wersję, ładuje prefs, syncuje dane |
| `lib/env_config.dart` | Flagi debug (zarządzane przez `scripts/switch_env.py`) |
| `lib/secrets.dart` | Klucze Supabase (generowany w CI, nie commitować ręcznie) |
| `CHANGELOG.md` | Release notes — **max 500 znaków na język**, format `## X.Y.Z → ### pl-PL / ### en-US` |

### Architektura

**State management:** `ValueNotifier` + `ValueListenableBuilder` — brak Providera/Riverpoda.

Notifery (`lib/global/notifiers/`):
- `themeNotifier` — jasny/ciemny/systemowy motyw
- `accentColorNotifier` — kolor akcentu
- `eventColorStyleNotifier` — styl kolorów kart zajęć
- `localeNotifier` — język (pl/en/uk)
- `sevenDayModeNotifier` — tryb 7-dniowy (domyślnie dla wykładowców)

**Dwa tryby aplikacji** (`AppMode` w `lib/global/models/app_mode.dart`):
- `AppMode.student` — dane w statycznym `Student` (wydział, kierunek, rok, grupy)
- `AppMode.lecturer` — dane w statycznym `Lecturer` (id, name, title)

Tryb persystowany w SharedPreferences, ładowany w `app_initialization.dart`.

**Dostępność kombinacji studiów (onboarding):**

`ProgramAvailability` ([`lib/service/program_availability.dart`](frontend/lib/service/program_availability.dart))
łączy drzewko struktury (`v_academic_structure`) z planami, które **mają grupy**
(`v_unique_groups`), i to po tym kaskaduje `InputPage` — nie po samym drzewku.
Powód: od 2. roku plan jest wystawiany pod nazwą **specjalizacji**, nie kierunku,
więc z samego drzewka dało się złożyć zestaw bez ani jednej grupy.

- Dopasowanie idzie po nazwie (jedyny wspólny klucz): normalizacja białych znaków
  + lowercase, a końcówka językowa (`ang.`) odcinana do osobnego wariantu.
- Zapisujemy `programName` z bazy **1:1** (`Student.specialisation`/`degreeCourse`),
  żeby `.eq("program_name", …)` trafiało też przy nazwie z podwójną spacją.
- Wymiar z jedną możliwą wartością wybiera się sam; niedostępne lata/stopnie/tryby
  są wyszarzone, nie ukryte.
- Plan, którego nazwa nie pasuje do żadnego węzła struktury, trafia do
  `unmatchedProgramNames` — to samo liczy backendowy `structure_check`.
- Testy: [`test/program_availability_test.dart`](frontend/test/program_availability_test.dart)
  — jeden test na każdy kierunek, na snapshocie produkcji
  (`test/fixtures/availability_snapshot.json`, regeneracja:
  `backend/scripts/dump_availability_fixture.py`).

**Wybór grup (`group_categories.dart`):**

Kod grupy to `KOD/PULA/ROCZNIK`, np. `P0A04/WIET/2024/2025 ZS`.
[`buildGroupSections`](frontend/lib/service/group_categories.dart) dzieli grupy na sekcje:
audytorium / ćwiczenia / laboratoria / projekt / symulator (pojedynczy wybór — student
należy do jednej grupy) oraz **przedmioty obieralne** (pula `WIET`, kod `P0<litera><numer>`)
— jedyna sekcja **wielokrotnego wyboru**. Wcześniej kategoria brała pierwszą literę kodu,
więc grupa projektowa i cała pula obieralnych trafiały do jednego worka „Inne" z jednym
slotem, a plan wychodził niepełny (3 zgłoszenia). Zapytanie o zajęcia już wcześniej
używało `inFilter("group", …)`, więc backend nie wymagał zmian.
Testy: [`test/group_categories_test.dart`](frontend/test/group_categories_test.dart) —
po jednym teście na każdy plan z obieralnymi, na kodach ze snapshotu produkcji.

**Przepływ danych:**
```
BackendService.fetchLectures() [Supabase]
        ↓
CacheService.syncLectures/syncNews() — zawsze wywołuj OBA razem
        ↓
DatabaseService [SQLite lokalny cache]
        ↓
Widgety czytają z DatabaseService → opcjonalnie WidgetService.pushTodayLectures()
                                    pisze do natywnych home screen widgetów
```

> **Ważne:** `syncNews()` i `syncLectures()` muszą być wywoływane razem wszędzie, gdzie sync ma miejsce (onboarding, przełączanie roli, app_initialization). Pominięcie `syncNews()` powoduje brak aktualności przy pierwszym uruchomieniu.

> **Re-entrancy guard:** `CacheService.syncLectures()` i `syncNews()` cache'ują aktualnie trwający `Future`. Równoległe wywołania zwracają to samo Future zamiast startować drugi sync — chroni przed duplikacją w SQLite (każdy sync robi `clearLectures()` + insert loop na auto-incremented ID). Nie obchodź tego mechanizmu wywołując prywatne `_runLecturesSync`.

**Fetchowanie zajęć z SQLite:**
- `DatabaseService.fetchLectures()` zawsze używa `ORDER BY date ASC, start_time ASC`
- Kolor karty zajęć zależy od `idx` — licznika incremented w loopie budującym widgety. `idx` **musi być zadeklarowany wewnątrz callbacka FutureBuildera**, nie w `build()` — inaczej stale-while-revalidate przesuwa indeksy między renderami i kolory się zmieniają.

### Struktura stron

```
lib/pages/
├── home/           # Ekran główny (dzisiejsze zajęcia + newsy)
│   ├── home_shell.dart        # Główna nawigacja (AppBar blur, BottomBar, Sidebar)
│   ├── home_page.dart         # RefreshIndicator + TodayLectures + NewsBuilder
│   └── utils/lecture_filters.dart  # getClosestLectures() — filtruje i sortuje
├── lectures/       # Pełny plan (widok dzienny/tygodniowy)
├── news/           # Feed aktualności
├── settings/       # Ustawienia (wygląd, język, rola, grupy, o aplikacji)
├── welcome/        # Onboarding (welcome → role → input → group_selection)
└── lecturer/       # Wybór wykładowcy
```

### Onboarding i przełączanie roli

**Pierwsza instalacja — student:**
`WelcomePage` → `RoleSelectionPage` → `InputPage` → `GroupSelectionPage` → home

**Pierwsza instalacja — wykładowca:**
`WelcomePage` → `RoleSelectionPage` → `LecturerSelectionPage` (przy `kDebugGdpr=true` najpierw `GdprConsentPage` — ekran zgody RODO; back = anuluj) → `onContinue`:
  1. Zapisz dane w SharedPreferences
  2. `AppModeManager.setMode(AppMode.lecturer)`
  3. `sevenDayModeNotifier.value = true`
  4. `DatabaseService.clearLectures()`
  5. `CacheService().syncLectures()` + `CacheService().syncNews()` ← oba!
  6. Nawiguj do `/home`

**Przełączanie roli w ustawieniach** (`role_info.dart`):
- Wykładowca → student: `_switchToStudent()` **nie zmienia trybu od razu** — tylko otwiera `InputPage(isRoleSwitch: true)`. Tryb zmienia się dopiero w `GroupSelectionPage.onConfirm/onSkip`.
- Student → wykładowca: `_switchToLecturer()` → `LecturerSelectionPage` → po wyborze: zmień tryb, sync obu cache.

### UI — wzorce

**AppBar i BottomNavBar (blur):**
- Oba używają `BackdropFilter(blur 20) + Container(alpha: isLight ? 0.92 : 0.5)`
- Ramka `AppColor.outline` musi być **na zewnątrz** `ClipRect`/`BackdropFilter`, inaczej blenduje się z tłem

**Platform-aware back button:** Zawsze używaj `AppBackButton` z `lib/global/widgets/back_button.dart` — iOS daje `CNButton.icon(glass)`, Android daje `IconButton`.

**AnimatedSwitcher na checkmarkach:** Wzorzec `ScaleTransition + FadeTransition` z `ValueKey('check')`/`ValueKey('empty')` — użyty w language_page i appearance_page.

**RefreshIndicator za AppBarem:** Ustaw `edgeOffset: MediaQuery.of(context).padding.top + kToolbarHeight` żeby spinner nie chował się za paskiem.

### Native home screen widgets

Architektura "data bridge": Flutter zapisuje JSON do shared storage, natywny widget go odczytuje i renderuje.

**Pliki Dart:**
- [`lib/service/widget_service.dart`](frontend/lib/service/widget_service.dart) — `WidgetService.pushTodayLectures()` zapisuje dzisiejsze zajęcia do App Group (iOS) / `HomeWidgetPreferences` (Android). Wywoływane na końcu `CacheService.syncLectures()`.
- Flaga `kDebugWidget` (w `env_config.dart`) podstawia stałe fake dane (`_debugLectures`) zamiast czytać z DB — przydatne do iteracji nad UI widgetów.

**iOS (WidgetKit):**
- Extension target: `ios/com.piotrwittig.plan_pm.ScheduleWidget/`
- **`IPHONEOS_DEPLOYMENT_TARGET` extension = `17.0`, aplikacja = `15.0`** — rozjazd
  jest celowy i wymuszony przez kod. `.containerBackground(for: .widget)` oraz
  `.contentMarginsDisabled()` są iOS 17+ i użyte **bez** `#available`, więc niżej
  widget się nie kompiluje (sprawdzone: przy 15.0 cztery błędy, wiążący jest
  `containerBackground`). Wyższe minimum na extension niż na hoście jest legalne
  — widget jest po prostu niedostępny poniżej 17. Nie zrównywać z aplikacją bez
  przepisania tych dwóch wywołań; nie zostawiać też domyślnego z Xcode (było
  `26.0`, czyli widget dla prawie nikogo).
- Widget `kind` musi być **dokładnie** `PlanPMScheduleWidget` (matchuje `_iosName` w Dart)
- App Group: `group.com.piotrwittig.plan_pm` (dodany w `Info.plist` jako `HomeWidgetAppGroupName`)
- URL scheme `planpm://schedule` (`CFBundleURLTypes` w `Info.plist`) — `widgetURL` na widoku otwiera apkę po tapnięciu
- Wielkości: `systemSmall` i `systemMedium` (do 2 kart; small bez sali), `systemLarge` (do 5 kart)
- Live progress bar przez `ProgressView(timerInterval:)` (iOS 16+) — aktualizuje się sam, bez timeline refresh
- `Provider.getTimeline()` generuje wpisy przy każdym końcu zajęcia — widget przechodzi do następnego stanu automatycznie

**Android (RemoteViews / `AppWidgetProvider`):**
- **Jeden skalowalny (resizable) widżet** — pojedyncza klasa `ScheduleWidgetProvider` w [`ScheduleWidgetProvider.kt`](frontend/android/app/src/main/kotlin/com/piotrwittig/plan_pm/ScheduleWidgetProvider.kt) (iOS ma osobne, stałe rozmiary — to dotyczy tylko Androida):
  - **Liczba kart dopasowuje się do realnej wysokości** przez `cardCountForHeight()` — czyta bieżącą wysokość z `getAppWidgetOptions()` (`onUpdate` i `onAppWidgetOptionsChanged`), więc jeden kod obsługuje widżet od 1 karty (mały) do `MAX_CARDS` (=10) kart (pełna wysokość). Wzór rezerwuje stały border (`2 × CARD_INSET_DP`) i upycha tyle kart, ile się mieści. **Brak dynamicznego paddingu w runtime** — border jest wpieczony w layout (patrz niżej), więc marginesy nie „skaczą" przy resize. `MAX_CARDS` **musi równać się** liczbie slotów `widget_card_*` w layoucie; gradienty (grad_0..7, 8 szt.) cyklują dla slotów 9–10.
  - Provider-info: [`schedule_widget.xml`](frontend/android/app/src/main/res/xml/schedule_widget.xml) z `android:resizeMode="horizontal|vertical"` → skalowalny w obu osiach. Domyślny rozmiar `targetCellWidth=4`/`targetCellHeight=3` (Android 12+) oraz `minWidth`/`minHeight` (starsze). Zakres skalowania: `minResizeWidth`(110dp ≈ 2 kolumny)/`minResizeHeight` … `maxResizeWidth`/`maxResizeHeight`. **Uwaga na stary algorytm launchera `ceil((minHeight+30)/70)` wierszy** — za duże `minHeight` sprawia, że launcher **chowa widżet z pickera**; dlatego `minHeight=224dp` (≈3 karty), nie więcej.
  - **Skracanie nazw do inicjałów przy wąskim widżecie:** provider mierzy szerokość tytułu (`Paint.measureText`, font 14sp bold) względem realnej szerokości widżetu (`OPTION_APPWIDGET_MIN_WIDTH` − inset − padding karty). Gdy nazwa się nie mieści, `fitTitle()` skraca wszystkie słowa poza ostatnim do inicjału, np. „Bazy danych" → „B.Danych" (jednowyrazowe zostają bez zmian, `maxLines=1 ellipsize=end` to ostateczny fallback). Karty rektorskie rezerwują dodatkowo miejsce na ikonę ostrzeżenia.
  - **Sala chowana na najmniejszym widżecie:** poniżej `LOCATION_MIN_WIDTH_DP` (200dp ≈ 2 kolumny) `showLocation=false` → pole sali jest `GONE` (nie zawija się, nie ściska czasu). Powyżej progu sala pokazuje się w całości; ma `maxLines=1`+`ellipsize=end`, więc przy średniej szerokości nie zawija się (najwyżej ucina).
  - Jeden `<receiver name=".ScheduleWidgetProvider">` w `AndroidManifest.xml`, etykieta `widget_label` w `res/values/strings.xml`. Flutter odświeża tę jedną nazwę w `widget_service.dart` (`_androidWidgetName`).
- Layout współdzielony: [`widget_schedule.xml`](frontend/android/app/src/main/res/layout/widget_schedule.xml) — 10 slotów kart. **Białe tło (`widget_box`) jest `match_parent`** — wypełnia cały footprint (brak przezroczystej martwej strefy, cały widżet klikalny). Karty są przyklejone do góry (`gravity="top"`) ze **stałym** paddingiem `@dimen/widget_card_inset` — border góra/boki jest zawsze jednakowy, a karty **nie ruszają się** przy resize (brak pulsowania). Gdy footprint jest wyższy niż potrzeba na karty, nadwyżka to białe wypełnienie pod ostatnią kartą (pojawia się tylko gdy widżet jest wyższy niż wypełniają go zajęcia).
- **Wysokość kart:** na Androidzie 12+ (API 31) karty mają **elastyczną** wysokość w zakresie `[MIN_CARD_DP, MAX_CARD_DP]` (60–74dp) — provider liczy `flexCapacity()` (ile kart wejdzie przy MIN) i rozdziela wysokość równo przez `RemoteViews.setViewLayoutHeight(...)`, więc stos kart **wypełnia box dokładnie**: karty rosną (do MAX), żeby zjeść mały nadmiar, albo kurczą się (do MIN), żeby zmieścić jeszcze jedną. Na starszych API — fallback: stała wysokość `@dimen/widget_card_height` (62dp) i `cardCountForHeight()`. **`widget_card_height` w layoucie to wartość nominalna/fallback; runtime i tak ją nadpisuje na 12+.** Nie wracać do `layout_weight="1"` (rozciągało karty do absurdu przy 2 zajęciach). **Wartości MUSZĄ się zgadzać:** `CARD_INSET_DP` ↔ `widget_card_inset` (Kotlin ↔ [`dimens.xml`](frontend/android/app/src/main/res/values/dimens.xml)).
- Czyta z `HomeWidgetPreferences` shared preferences plik, klucz `schedule_data` (**nie** `flutter.schedule_data` z `FlutterSharedPreferences`)
- Każdy wpis `schedule_data` ma datę `yyyy-MM-dd`; provider odrzuca stare lub bezdatowe dane po północy. Cały `widget_box` ma `PendingIntent` otwierający `planpm://schedule`.
- **Progress bar statyczny** — RemoteViews nie obsługuje live timerów. Pasek odświeża się przy `updateAppWidget` (push z apki, resize, kolejny entry timeline w iOS-sty­lu nie istnieje)
- **Glance dependency exclusion w [`android/app/build.gradle.kts`](frontend/android/app/build.gradle.kts):** `home_widget` transitively wymaga `glance-appwidget` (AGP 9.1+, compileSdk 37+). Wykluczone bo używamy klasycznego `AppWidgetProvider`, nie Glance. Nie odblokowywuj bez upgradeu całego toolchainu.

### Lokalizacja

Pliki źródłowe: `lib/l10n/app_pl.arb` (szablon), `app_en.arb`, `app_uk.arb`.
**Nigdy nie edytuj wygenerowanych plików** `lib/l10n/app_localizations*.dart`.
Po każdej zmianie ARB: `flutter gen-l10n`.

### Flagi debug (`env_config.dart`)

| Flaga | Opis | Wymagana wartość przed deployem |
|-------|------|--------------------------------|
| `kUseTestDb` | Używaj testowego Supabase | `false` |
| `kSimulateNetworkErrors` | Symuluj błędy sieci | `false` |
| `kDebugAnnouncement` | Wymuszaj dialog ogłoszenia | `false` |
| `kDebugAnnouncementType` | Typ podglądanego ogłoszenia (`info`/`warning`/`update`) | bez znaczenia (string, używane tylko przy `kDebugAnnouncement`) |
| `kDebugWhatsNew` | Wymuszaj dialog "Co nowego" | `false` |
| `kDebugNews` | Mock newsy | `false` |
| `kDebugNewsImageUrl` | URL (ImgBB) obrazka dla mock newsów, pusty = brak | bez znaczenia (string, używane tylko przy `kDebugNews`) |
| `kDebugRectorHours` | Wymuszaj baner godzin rektorskich | `false` |
| `kDebugWidget` | Fake dane w widgecie ekranu głównego | `false` |
| `kDebugWidgetCount` | Liczba fake zajęć (0–7) w widgecie gdy `kDebugWidget=true` (0 = pusty stan) | bez znaczenia (używane tylko przy `kDebugWidget`) |
| `kDebugEmptyGroups` | Symuluj pustą listę grup | `false` |
| `kDebugGdpr` | Pokazuj ekran zgody RODO przed potwierdzeniem wyboru wykładowcy | `false` |

Przełączane przez: `python scripts/switch_env.py [test|prod]`

> **WAŻNE:** `switch_env.py` **nadpisuje cały plik** `env_config.dart` przy każdym wywołaniu. Dodając nową flagę do `env_config.dart`, **zawsze jednocześnie** dodaj ją też do `switch_env.py` (w bloku `ENV_CONFIG_DART.write_text(...)`). Pominięcie tego powoduje utratę flagi po następnym przełączeniu środowiska i błąd kompilacji.

---

## Backend (Python)

### Setup

Zależności i wersja Pythona (>=3.13) opisane w `pyproject.toml` (+ `uv.lock`). Środowisko możesz postawić **uv** albo klasycznym **venv + pip** — wybór należy do Ciebie.

```bash
cd backend

# Wariant A — uv (szybszy, używa uv.lock)
uv sync                    # tworzy .venv i instaluje zależności
# polecenia: uv run python main.py / uv run pytest

# Wariant B — venv + pip
python -m venv .venv
source .venv/bin/activate   # lub .venv\Scripts\activate na Windows
pip install -e .            # instaluje zależności z pyproject.toml

cp .env.example .env        # uzupełnij klucze Supabase (jeśli plik istnieje)
```

### Pipeline

```
main.py
  └── Mapper      → odkrywa ID planów (output/mapper.json)
  └── HttpScrapper → pobiera dane HTML przez POST (output/scrapper.json)
  └── Parser      → normalizuje, deduplikuje, parsuje (output/parser.json)
  └── json2db     → upsertuje do Supabase
```

Pipeline jest tylko HTTP — `HttpScrapper` (`scrapper/http_scrapper.py`).

**Uruchamianie:**
```bash
python main.py [--workers N]      # pełny pipeline (domyślnie 10 workerów)
python -m json2db.json2db --input ./output/parser.json [--clear] [--dry-run]
python -m structure_updater.structure_updater [--dry-run]
python -m structure_check.structure_check [--no-notify] [--strict]
python -m admin.app               # panel admina pod localhost:5050
python -m mcp_server.server        # MCP server (stdio) do sterowania backendem przez agenta
```

> **Sanity gates:** `json2db(clear=True)` sam sprawdza `MIN_CLASSES_TO_CLEAR` (100), więc ochrona obejmuje pełny pipeline, CLI, admina i MCP. `structure_updater` analogicznie wymaga co najmniej 2 wydziałów i 5 kierunków. `--force`/`force=True` omija bramkę wyłącznie do świadomego użycia po ręcznej weryfikacji artefaktu.

**Testy:**
```bash
pytest -m "not slow"     # szybkie (bez sieci)
pytest -m slow           # wymaga sieci
pytest path/to/test.py::test_name   # pojedynczy test
```

Pliki testów leżą obok kodu (`*/test_*.py`).
W workerach używaj `return`, nie `os._exit()`.
MagicMock dla Supabase: cachuj obiekty tabel w dict lub `assert_called_once_with` może sprawdzać inny obiekt.

### Zmiana trybu bazy

Dwa poziomy wyboru środowiska (test/prod):

1. **Globalny** — plik `.env_mode` (`prod` lub `test`). Moduły czytają go i dobierają klucze: prefix `TEST_` dla testu (`TEST_SUPABASE_URL`/`TEST_SUPABASE_SERVICE_KEY`), bez prefiksu dla produkcji.
   ```bash
   python scripts/switch_env.py test   # test DB
   python scripts/switch_env.py prod   # produkcja
   ```
   `.env_mode` musi zawierać `prod` przed PR do `main`.

2. **Per-run override** — zmienna `PLANPM_ENV=prod|test` ma pierwszeństwo nad `.env_mode` dla jednego uruchomienia. Ustawiają ją admin panel i MCP server, żeby celować w wybraną bazę bez globalnego przełączania. `json2db` i `structure_updater` ją honorują.

### Admin Panel (`admin/`)

Flask, localhost-only (`python -m admin.app`, port 5050). `create_app()` rejestruje blueprinty z `admin/routes/`:
- **news** — CRUD newsów + upload/resize zdjęć (Pillow → imgbb.com)
- **pipeline** — uruchamia kroki pipeline'u przez SSE z live logami; single-flight guard (zakłada jednoprocesowy dev server)
- **stats** — recenzje i wskaźniki z Google Play (Reviews + Play Developer Reporting API) oraz App Store Connect (JWT ze sklucza Apple)
- **settings** — przełącza `.env_mode` przez `switch_env.py`

Zabezpieczenia (`@app.before_request`): odrzuca żądania, których `Sec-Fetch-Site` nie jest `same-origin`/`none`/brak (blokuje cross-site **i** same-site — CSRF, w tym SSE), oraz spoza loopbacka. `admin/db.py` dobiera klienta Supabase wg `.env_mode`.

### MCP Server (`mcp_server/server.py`)

FastMCP (`plan-pm-backend`), narzędzia agenta do sterowania backendem: `run_pipeline_step` (kroki: `mapper|scrapper|parser|json2db|structure`), `run_full_pipeline`, `get_logs`, `list_news`/`create_news`/`delete_news`, `get_env_mode`/`set_env_mode`. Narzędzia pipeline'owe i newsowe przyjmują `env="prod"|"test"` (**domyślnie `prod`**, niezależnie od `.env_mode`!) i propagują je do podprocesów przez `PLANPM_ENV`; `get_logs` i `get_env_mode`/`set_env_mode` nie mają parametru `env`.

### Structure check (`structure_check/`)

Strażnik: aplikacja dopasowuje studenta do planu po **nazwie**, więc plan, którego
nazwy nie ma w drzewku struktury, jest dla studenta niewidoczny (tak przez miesiące
znikał rocznik z `Inżynieria i Bezpieczeństwo  w Transporcie Drogowym` — podwójna
spacja). Moduł odtwarza reguły dopasowania z `program_availability.dart`
(normalizacja spacji, lowercase, końcówka językowa) i raportuje rozjazdy: log +
Discord. Wołany automatycznie na końcu `main.py` oraz jako osobny etap w Jenkinsie;
**nie przerywa pipeline'u** — dane są poprawne, rozjechała się nazwa. `--strict`
zwraca kod 1 (do CI).

### Powiadomienia (`notifier.py`)

`notify_discord(...)` wysyła embed na webhook z `DISCORD_WEBHOOK_URL` (brak zmiennej = no-op). Współdzielony przez admin panel i MCP dla operacji destrukcyjnych (zapisy do DB). Błędy powiadomienia nigdy nie przerywają operacji. `structure_updater` powiadamia się sam — nie dubluj.

---

## CI/CD

### Branching strategy

```
feature/*  ──PR──►  main  ──PR──►  deployment  ──push──►  App Store / Play Store
```

### Jenkins — dzienna propagacja ([`Jenkinsfile`](Jenkinsfile))

`Checkout → Set up Python → Scrape → Sanity gate → Load into production →
Refresh structure → Structure check`. Dwa ostatnie etapy pilnują tego, co widzi
student: `structure_updater` odświeża listy w onboardingu (bez tego nowa
specjalizacja jest niewybieralna), a `structure_check` raportuje plany, których
nazwa wypadła z drzewka. Żaden z nich nie czyści zajęć — bramka bezpieczeństwa
dotyczy wyłącznie `json2db`.

> **Kolejność `Load` przed `Refresh structure` jest celowa.** To dwa niezależne
> zapisy destrukcyjne bez wspólnej transakcji, więc jeden może wejść bez
> drugiego. Zajęcia najpierw + nieodświeżona struktura = nowa specjalizacja
> jeszcze niewybieralna (stan normalny każdego dnia przed zmianą nazwy, zgłasza
> to `structure_check`). Odwrotnie = onboarding oferuje kombinacje bez zajęć,
> czyli aplikacja wygląda na zepsutą. Nie zamieniać z powrotem.

> **Powiadomienia Discord w tym jobie.** `json2db` i `structure_updater`
> raportują się same (własne `finally`), więc ich etapy ustawiają
> `env.STEP_REPORTED_ITSELF='true'` i `post { failure }` nie dokłada drugiego
> embeda. `structure_check` milczy o własnym wywrotce — jego etap zeruje flagę.
> Sam webhook jest **opcjonalny naprawdę**: `withCredentials` rzuca
> `CredentialNotFoundException` jeszcze przed wejściem w blok, więc jest
> sondowany raz w `Checkout` (`webhookConfigured()`) i bindowany tylko tam,
> gdzie istnieje.

### Jenkins — deploy na store'y ([`Jenkinsfile.deploy`](Jenkinsfile.deploy))

`Checkout → Preflight → Provision Flutter → Release metadata → Generate
secrets.dart → Flutter dependencies → iOS → Android`. Deploy **zszedł z GitHub
Actions** (`deploy.yml` usunięty): workflow nie przypinał ani Fluttera, ani
fastlane'a, więc psuł się od zmian w toolchainie runnera, nie od zmian w repo —
5 z ostatnich 9 przebiegów padło z tego powodu.

Tu toolchain jest przypięty: Flutter przez `FLUTTER_VERSION` (job sam klonuje SDK
do `~/.jenkins-toolchains/flutter-<wersja>`), fastlane przez
`frontend/{ios,android}/Gemfile`, Xcode przez `DEVELOPER_DIR` (globalny
`xcode-select` na tej maszynie wskazuje CommandLineTools i ma tak zostać).

> **Fastlane ↔ Fastfile są sprzężone.** Od 2.237 gym sam wstrzykuje
> `-authenticationKey*` do `-exportArchive`, więc `ios/fastlane/Fastfile` podaje
> je wyłącznie przez `xcargs`. Zejście poniżej 2.237 wymaga przywrócenia
> `export_xcargs: signing_xcargs` **w tym samym commicie**.

iOS i Android idą sekwencyjnie (jeden workspace, jeden `frontend/build`), ale
każdy w `catchError` — porażka jednego nie blokuje drugiego. `DRY_RUN` ustawia
`PLANPM_SKIP_UPLOAD=true`, które oba Fastfile'e honorują tuż przed
`upload_to_*`; tak puszcza się pierwszy build na nowej maszynie, bo store'y nie
przyjmą dwa razy tego samego numeru builda.

### Workflow checks (GitHub Actions — zostały tylko bramki PR)

| Workflow | Trigger | Co sprawdza |
|----------|---------|-------------|
| `check_env_mode.yml` | PR → main | `.env_mode` == `prod` |
| `deployment-env-check.yml` | PR → deployment | 4 flagi debug == `false` (`kUseTestDb`, `kSimulateNetworkErrors`, `kDebugAnnouncement`, `kDebugWhatsNew` — **pozostałe flagi NIE są sprawdzane przez CI**, weryfikuj ręcznie) |
| `deployment-changelog-check.yml` | PR → deployment | `CHANGELOG.md` ma wpis dla aktualnej wersji |
| `version-check.yml` | PR → deployment lub production | wersja w `pubspec.yaml` > bazy |
| `deployment-source-check.yml` | PR → deployment | źródłowy branch == `main` |

### Pomijanie deployu

Dodaj do **treści commita** (nie tytułu PR) — czyta to `Jenkinsfile.deploy`:
- `[skip ios]` — pomija etap iOS
- `[skip android]` — pomija etap Android
- `[skip deploy]` — pomija oba

### Secrets w CI

`secrets.dart` jest generowany w trakcie buildu z credentiali Jenkinsa
(`planpm-supabase-prod-url`, `planpm-supabase-prod-anon-key`) — nie istnieje
w repo i jest kasowany w `post { always }`. Lokalnie utwórz go ręcznie (skopiuj
`lib/secrets_example.dart` i uzupełnij klucze — `switch_env.py` go **nie**
generuje). Pełna lista credentiali: [`docs/deployment.md`](docs/deployment.md).

---

## Konwencje

- **Wszystkie artefakty Git po angielsku** — commit subject + body, PR title, PR description (włącznie z sekcjami "Summary"/"Test plan"/"Out of scope" i punktami). Konwersacja z użytkownikiem może być po polsku; tylko historia git i UI GitHuba muszą być po angielsku.
- Format commita: `type: opis` (fix, feat, chore, refactor, docs)
- **Nigdy nie commituj/pushuj bez wyraźnej zgody użytkownika** w danej rozmowie. Pull request też wymaga zgody przed `gh pr create`.
- Push bezpośrednio na `main` jest dozwolony. PR mile widziany przy większych
  zmianach, ale nie jest wymagany (ochrona zdjęta 15.09.2026 decyzją zespołu).
  Force push i usunięcie `main` pozostają zablokowane.
- Nie używaj `git push --force` (na żadnym branchu) bez wyraźnej zgody w danym momencie
- Nie commituj `.env`, `secrets.dart`, kluczy API
- Nie dodawaj atrybucji Claude w commitach (`Co-Authored-By: Claude …` ani podobnych)
