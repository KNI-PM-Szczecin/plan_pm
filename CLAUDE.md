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
`WelcomePage` → `RoleSelectionPage` → `LecturerSelectionPage.onContinue`:
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
- Widget `kind` musi być **dokładnie** `PlanPMScheduleWidget` (matchuje `_iosName` w Dart)
- App Group: `group.com.piotrwittig.plan_pm` (dodany w `Info.plist` jako `HomeWidgetAppGroupName`)
- URL scheme `planpm://schedule` (`CFBundleURLTypes` w `Info.plist`) — `widgetURL` na widoku otwiera apkę po tapnięciu
- Wielkości: `systemSmall` (1 karta, bez sali), `systemMedium` (2 karty), `systemLarge` (5 kart)
- Live progress bar przez `ProgressView(timerInterval:)` (iOS 16+) — aktualizuje się sam, bez timeline refresh
- `Provider.getTimeline()` generuje wpisy przy każdym końcu zajęcia — widget przechodzi do następnego stanu automatycznie

**Android (RemoteViews / `AppWidgetProvider`):**
- Provider: [`android/app/src/main/kotlin/com/piotrwittig/plan_pm/ScheduleWidgetProvider.kt`](frontend/android/app/src/main/kotlin/com/piotrwittig/plan_pm/ScheduleWidgetProvider.kt)
- Layout: [`android/app/src/main/res/layout/widget_schedule.xml`](frontend/android/app/src/main/res/layout/widget_schedule.xml) — 8 slotów kart (gradient 0..7)
- Dimens (per-card min height, padding, gap) w [`res/values/dimens.xml`](frontend/android/app/src/main/res/values/dimens.xml)
- Liczba widocznych kart wyliczana dynamicznie w `onAppWidgetOptionsChanged` z `OPTION_APPWIDGET_MAX/MIN_HEIGHT` (`cardsThatFit`) — Android nie ma równowartości iOS-owego "snap" do rozmiaru
- Czyta z `HomeWidgetPreferences` shared preferences plik, klucz `schedule_data` (**nie** `flutter.schedule_data` z `FlutterSharedPreferences`)
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
| `kDebugWhatsNew` | Wymuszaj dialog "Co nowego" | `false` |
| `kDebugNews` | Mock newsy | `false` |
| `kDebugRectorHours` | Wymuszaj baner godzin rektorskich | `false` |
| `kDebugWidget` | Fake dane w widgecie ekranu głównego | `false` |
| `kDebugEmptyGroups` | Symuluj pustą listę grup | `false` |

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
python uploadparsetodb.py         # tylko upload istniejącego parser.json
python -m json2db.json2db --input ./output/parser.json [--clear] [--dry-run]
python -m structure_updater.structure_updater --source web [--dry-run]
python -m admin.app               # panel admina pod localhost:5050
python -m mcp_server.server        # MCP server (stdio) do sterowania backendem przez agenta
```

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
- **news** — CRUD newsów + upload/resize zdjęć (Pillow → Supabase Storage)
- **pipeline** — uruchamia kroki pipeline'u przez SSE z live logami; single-flight guard (zakłada jednoprocesowy dev server)
- **stats** — recenzje i wskaźniki z Google Play (Reviews + Play Developer Reporting API) oraz App Store Connect (JWT ze sklucza Apple)
- **settings** — przełącza `.env_mode` przez `switch_env.py`

Zabezpieczenia (`@app.before_request`): odrzuca żądania z `Sec-Fetch-Site: cross-site` (CSRF, w tym SSE) oraz spoza loopbacka. `admin/db.py` dobiera klienta Supabase wg `.env_mode`.

### MCP Server (`mcp_server/server.py`)

FastMCP (`plan-pm-backend`), narzędzia agenta do sterowania backendem: `run_pipeline_step`, `run_full_pipeline`, `get_logs`, `list_news`/`create_news`/`delete_news`, `get_env_mode`/`set_env_mode`. Każde przyjmuje `env="prod"|"test"` i propaguje je do podprocesów przez `PLANPM_ENV`.

### Powiadomienia (`notifier.py`)

`notify_discord(...)` wysyła embed na webhook z `DISCORD_WEBHOOK_URL` (brak zmiennej = no-op). Współdzielony przez admin panel i MCP dla operacji destrukcyjnych (zapisy do DB). Błędy powiadomienia nigdy nie przerywają operacji. `structure_updater` powiadamia się sam — nie dubluj.

---

## CI/CD

### Branching strategy

```
feature/*  ──PR──►  main  ──PR──►  deployment  ──push──►  App Store / Play Store
```

### Workflow checks

| Workflow | Trigger | Co sprawdza |
|----------|---------|-------------|
| `check_env_mode.yml` | PR → main | `.env_mode` == `prod` |
| `deployment-env-check.yml` | PR → deployment | wszystkie flagi debug == `false` |
| `deployment-changelog-check.yml` | PR → deployment | `CHANGELOG.md` ma wpis dla aktualnej wersji |
| `version-check.yml` | PR → deployment | wersja w `pubspec.yaml` > bazy |
| `deployment-source-check.yml` | PR → deployment | źródłowy branch == `main` |
| `deploy.yml` | push → deployment | buduje iOS + Android, deployuje |

### Pomijanie deployu

Dodaj do **treści commita** (nie tytułu PR):
- `[skip ios]` — pomija job iOS
- `[skip android]` — pomija job Android
- `[skip deploy]` — pomija oba

### Secrets w CI

`secrets.dart` jest generowany w trakcie buildu ze zmiennych GitHub Secrets — nie istnieje w repo. Lokalnie utwórz go ręcznie lub przez `switch_env.py`.

---

## Konwencje

- **Wszystkie artefakty Git po angielsku** — commit subject + body, PR title, PR description (włącznie z sekcjami "Summary"/"Test plan"/"Out of scope" i punktami). Konwersacja z użytkownikiem może być po polsku; tylko historia git i UI GitHuba muszą być po angielsku.
- Format commita: `type: opis` (fix, feat, chore, refactor, docs)
- **Nigdy nie commituj/pushuj bez wyraźnej zgody użytkownika** w danej rozmowie. Pull request też wymaga zgody przed `gh pr create`.
- Nie pushuj bezpośrednio na `main` (branch protected)
- Nie używaj `git push --force` (na żadnym branchu) bez wyraźnej zgody w danym momencie
- Nie commituj `.env`, `secrets.dart`, kluczy API
- Nie dodawaj atrybucji Claude w commitach (`Co-Authored-By: Claude …` ani podobnych)
