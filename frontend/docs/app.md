# Plan PM – Frontend

Flutter app for students of the Maritime University of Szczecin. Displays class schedules, news, and quick links to university services.

---

## Architecture

```
Supabase (remote) → BackendService → CacheService → SQLite (local)
                                                         ↓
                                                      Pages / Widgets
```

**State management:** `ValueNotifier` + `SharedPreferences` (no Bloc/Redux).  
**Persistence:** SQLite via `sqflite` for lectures and news; `SharedPreferences` for settings.  
**Offline support:** Data is fetched on launch/pull-to-refresh and stored locally. App works offline from cache.

---

## Navigation

### Entry point logic (`main.dart`)
- First launch → `WelcomePage` → `InputPage` → `GroupSelectionPage` → `MyHomePage`
- Returning user → `MyHomePage` directly

### Bottom navigation (3 tabs)
| Tab | Page | Description |
|-----|------|-------------|
| Home | `HomePage` | Latest news + today's lectures |
| Lectures | `LecturesPage` | Full schedule with day selector |
| News | `NewsPage` | Full news list |

### Sidebar drawer
| Item | Destination |
|------|-------------|
| PE Enrollment | `PePage` (external URL) |
| Student ID | `StudentIdPage` (external URL) |
| Virtual University | `VirtualUniversityPage` (external URL) |
| Settings | `SettingsPage` |

---

## Pages

### Onboarding

| File | Description |
|------|-------------|
| `pages/welcome/welcome_page.dart` | 4-slide carousel with Lottie animations introducing the app |
| `pages/welcome/input_page.dart` | Selects faculty, field of study, year, degree level, study mode. Fetches university structure from Supabase |
| `pages/welcome/group_selection_page.dart` | Selects class groups after study settings are saved |

### Main

| File | Description |
|------|-------------|
| `pages/home/home_page.dart` | Dashboard — latest news (limit 1) + `TodayLectures` widget. Pull-to-refresh |
| `pages/lectures/lectures_page.dart` | Calendar view with `DaySelection` + skeleton loading. Handles stationary/extramural initial dates |
| `pages/news/news_page.dart` | Full news list via `NewsBuilder` |
| `pages/news/full_news_page.dart` | News detail — cached image, HTML content, type badge, timestamp |

### Settings

| File | Description |
|------|-------------|
| `pages/settings/settings_page.dart` | Hub — student info summary, links to sub-pages. Debug section (unlocked by 7 taps on version in About) |
| `pages/settings/appearance_page.dart` | Theme (Light/Dark/System), AMOLED mode, accent color (6 options), event color style (4 options) |
| `pages/settings/language_page.dart` | Language: Polish, English, Ukrainian, System |
| `pages/settings/about_page.dart` | App version, KNI info, GitHub link. Easter egg: 7 taps → debug mode |
| `pages/settings/pe_page.dart` | Opens PE enrollment URL in WebView |
| `pages/settings/student_id_page.dart` | Opens student ID system URL in WebView |
| `pages/settings/virtual_university_page.dart` | Opens virtual university URL in WebView |
| `pages/feedback/feedback_page.dart` | Opens Google Form in external browser |

---

## Services

| File | Responsibility |
|------|---------------|
| `service/backend_service.dart` | Supabase queries: `fetchLectures`, `fetchNews`, `fetchGroups`, `fetchStructure` |
| `service/cache_service.dart` | Orchestrates fetch → clear → insert cycle for lectures and news |
| `service/database_service.dart` | SQLite CRUD for `lectures` and `news` tables |

---

## Global

| File | Description |
|------|-------------|
| `global/student.dart` | Static class holding current student profile (faculty, course, year, groups, study mode) |
| `global/colors.dart` | `AppColor` — dynamic color system supporting themes, AMOLED, 6 accent colors |
| `global/notifiers.dart` | ValueNotifiers for theme, locale, accent color, AMOLED, event style, 7-day mode. Also holds `newsCacheManager` |
| `global/extensions.dart` | String helpers, `DateTime.next()` for finding next weekday |
| `global/logger.dart` | Thin wrapper around `logger` package |
| `global/widgets/navigation_bar.dart` | `CustomNavigationBar` (bottom tabs) + `CustomSidebar` (drawer) |
| `global/widgets/generic_loading.dart` | Dotted-border loading placeholder with label |
| `global/widgets/generic_no_resource.dart` | Empty / error state with icon, label, description |

---

## Localization

3 languages: **Polish** (pl), **English** (en), **Ukrainian** (uk).  
Source files in `lib/l10n/`. Generated via `flutter gen-l10n`.  
~145 translatable strings.

---

## Known issues / missing

| # | Location | Issue |
|---|----------|-------|
| 1 | `pages/welcome/group_selection_page.dart:205` | `Text("Null")` shown when snapshot data is null — missing proper error state |
| 2 | `pages/home/widgets/news_builder.dart` | "Brak aktualności" and description hardcoded in Polish, not using l10n |
| 3 | `main.dart` comment | `// przetlumaczyc date w dayselection` — dates in `DaySelection` not fully localized |
| 4 | `pages/settings/settings_page.dart` | "Tryb 7-dniowy" label hardcoded in Polish, not using l10n |
| 5 | `env_config.dart` | `kSimulateNetworkErrors` flag wires into Supabase init but has no effect on local SQLite reads — offline cache still works normally when flag is on |
| 6 | General | `webview_flutter` is in `pubspec.yaml` and used in PE/StudentId/VirtualUniversity pages for in-app browsing — previously these opened external URLs; the package is wired in but pages may still fall back to `url_launcher` depending on platform error handling |
