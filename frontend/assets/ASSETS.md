# Assets

## Obrazki runtime (`assets/`)

| Plik | Używany w |
|---|---|
| `logo_light.png` | `lib/global/widgets/sidebar.dart` — logo w nagłówku bocznego panelu nawigacyjnego |
| `kni_logo.png` | `lib/pages/settings/about_page.dart` — logo KNI na stronie "O aplikacji" |
| `theme_light.png` | `lib/pages/settings/appearance_page.dart` — podgląd jasnego motywu |
| `theme_dark.png` | `lib/pages/settings/appearance_page.dart` — podgląd ciemnego motywu |
| `theme_mixed.png` | `lib/pages/settings/appearance_page.dart` — podgląd motywu systemowego |

## Ikony aplikacji (`launcher_icons/`)

Źródła dla `flutter_launcher_icons` (konfiguracja w `pubspec.yaml`).
Generowanie: `dart run flutter_launcher_icons`

| Plik | Rola |
|---|---|
| `logo.png` | Ikona główna (iOS + Android fallback) |
| `logo_foreground.png` | Warstwa przednia adaptacyjnej ikony Android |
| `logo_monochrome.png` | Warstwa monochromatyczna adaptacyjnej ikony Android |
| `logo_dark.png` | Ikona w trybie ciemnym |
| `logo_dark_android.png` | Ikona Android w trybie ciemnym |
| `logo_light_android.png` | Ikona Android w trybie jasnym |

## Splash screen (`native_splash/`)

Źródła dla `flutter_native_splash` (konfiguracja w `pubspec.yaml`).
Generowanie: `dart run flutter_native_splash:create`

| Plik | Rola |
|---|---|
| `background.png` | Tło splash screena (tryb jasny) |
| `background_dark.png` | Tło splash screena (tryb ciemny) |

## Animacje (`lotties/`)

| Plik | Używany w |
|---|---|
| `bell.json` | `lib/pages/welcome/welcome_page.dart` — animacja powiadomień (slajd onboardingu) |
| `calendar.json` | `lib/pages/welcome/welcome_page.dart` — animacja kalendarza (slajd onboardingu) |
| `search.json` | `lib/pages/welcome/welcome_page.dart` — animacja wyszukiwania (slajd onboardingu) |
| `womanschedule.json` | `lib/pages/welcome/welcome_page.dart` — animacja planu zajęć (slajd onboardingu) |
