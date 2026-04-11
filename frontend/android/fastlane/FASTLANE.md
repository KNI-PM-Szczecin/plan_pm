# Fastlane – ściągawka

## Struktura

```
android/
├── Gemfile                  # zależność: gem "fastlane"
├── fastlane/
│   ├── Appfile              # package name + ścieżka do klucza Google Play
│   └── Fastfile             # definicje lane'ów
└── planpm_deploy_key.json   # klucz service account do Google Play API
```

## Konfiguracja (Appfile)

```ruby
json_key_file("android/planpm_deploy_key.json")
package_name("com.piotrwittig.plan_pm")
```

## Dostępne lane'y

| Lane | Komenda | Co robi |
|---|---|---|
| `test` | `fastlane test` | Uruchamia testy Gradle |
| `beta` | `fastlane beta` | Buduje release APK + wysyła do Crashlytics |
| `deploy` | `fastlane deploy` | Buduje release APK + wysyła do Google Play |

## Typowy flow wdrożenia

```bash
# 1. Zbuduj AAB we Flutterze (z katalogu frontend/)
flutter build appbundle --release

# 2. Wejdź do katalogu android i odpal lane
cd android
bundle exec fastlane deploy
```

> Fastlane należy uruchamiać przez `bundle exec fastlane` (nie `fastlane` bezpośrednio),
> żeby używał wersji z Gemfile.

## Wgranie do Google Play – track'i

`upload_to_play_store` domyślnie wgrywa na track `production`.
Żeby wysłać na inny track, dodaj parametr:

```ruby
upload_to_play_store(track: "internal")   # internal testing
upload_to_play_store(track: "alpha")
upload_to_play_store(track: "beta")
upload_to_play_store(track: "production") # domyślnie
```

Żeby wgrać AAB zamiast APK (zalecane przez Google Play):

```ruby
upload_to_play_store(
  track: "internal",
  aab: "../build/app/outputs/bundle/release/app-release.aab"
)
```

## Klucz Google Play (`planpm_deploy_key.json`)

- Service account JSON z Google Cloud Console
- Musi mieć uprawnienia do Google Play Android Developer API
- Nie commitować do publicznego repo
- Ścieżka skonfigurowana w `Appfile`

## Instalacja (jednorazowo)

```bash
cd android
bundle install   # instaluje fastlane z Gemfile
```

## Przydatne komendy

```bash
bundle exec fastlane lanes          # lista wszystkich lane'ów
bundle exec fastlane action <name>  # dokumentacja konkretnej akcji
bundle exec fastlane env            # wyświetl zmienne środowiskowe
```
