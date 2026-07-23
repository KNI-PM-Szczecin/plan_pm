# Deployment — zabezpieczenia i quirki

## Architektura gałęzi

```
main  ──────►  deployment  ──────►  App Store / Play Store
(dev)          (release)             (via Fastlane CI)
```

- `main` — gałąź developerska. Wszystkie zmiany trafiają tu najpierw.
- `deployment` — gałąź release. Merge z `main` uruchamia deploy.
- Bezpośredni push do `deployment` wymaga uprawnień admina (branch protection).

---

## CI guards na PR do `deployment`

Każdy PR z `main` → `deployment` musi przejść 4 obowiązkowe statusy:

### 1. `source-branch-check` — `.github/workflows/deployment-source-check.yml`
PRy do `deployment` mogą pochodzić **wyłącznie z `main`**. Każdy inny branch źródłowy powoduje fail.

### 2. `deployment-env-check` — `.github/workflows/deployment-env-check.yml`
Sprawdza `frontend/lib/env_config.dart`. Wszystkie cztery flagi muszą być `false`:

| Flaga | Rola |
|-------|------|
| `kUseTestDb` | Połączenie z testową bazą Supabase |
| `kSimulateNetworkErrors` | Symulacja błędów sieciowych |
| `kDebugAnnouncement` | Zawsze pokazuj dialog ogłoszenia |
| `kDebugWhatsNew` | Zawsze pokazuj dialog "Co nowego" |

Jeśli którakolwiek jest `true` — PR nie przejdzie.

### 3. `changelog-check` — `.github/workflows/deployment-changelog-check.yml`
Sprawdza czy `frontend/CHANGELOG.md` zawiera sekcję `## <VERSION>` dla wersji z `pubspec.yaml`. Bez wpisu w CHANGELOG merge jest zablokowany.

### 4. `Verify pubspec.yaml version is bumped` — `.github/workflows/version-check.yml`
Porównuje wersję z PR z wersją na `deployment`. Wersja musi być wyższa (sprawdzane przez `sort -V`). Działa też na PRy do `production`.

---

## CI guard na PR do `main`

### `check-env-mode` — `.github/workflows/check_env_mode.yml`
Sprawdza plik `backend/.env_mode`. Musi zawierać `prod` (nie `test`). Zarządzany przez `scripts/switch_env.py`.

---

## Deploy workflow — `.github/workflows/deploy.yml`

Trigger: **push do `deployment`** (po merge).

Uruchamia dwa równoległe joby: iOS i Android.

### Flagi `[skip deploy]` / `[skip ios]` / `[skip android]`
Jeśli commit message (treść commita, nie tytuł PR) zawiera `[skip deploy]`, oba joby są pomijane. `[skip ios]` pomija tylko job iOS, `[skip android]` tylko job Android. Używaj przy pushach technicznych (synchronizacja gałęzi, hotfixy konfiguracji) które nie powinny trafić na store.

```
git commit -m "chore: update CI config [skip deploy]"
```

### Job iOS → TestFlight
1. Checkout + setup Xcode w wersji przypiętej w `deploy.yml` (obecnie `26.5` na runnerze `macos-26`; Apple wymaga aktualnego SDK od 28 kwietnia 2026)
2. Flutter pub get
3. Generowanie `secrets.dart` z GitHub Secrets przez Python (heredoc — jedyna metoda odporna na line breaki w JWT)
4. Pod install
5. Decode certificate `.p12` + provisioning profile `.mobileprovision` z base64
6. `bundle exec fastlane ios beta`

### Job Android → Play Store
1. Checkout + Java 17 + Flutter
2. `ruby/setup-ruby@v1` z `bundler-cache: true` (wymagane na Ubuntu — system Ruby nie ma uprawnień do `gem install`)
3. Generowanie `secrets.dart` z GitHub Secrets przez Python
4. Decode keystora z base64
5. `bundle exec fastlane android deploy`

---

## Fastlane

### iOS — `frontend/ios/fastlane/Fastfile`

Lane `beta`:
- Czyta wersję i build number z `pubspec.yaml`
- W CI: tworzy keychain, importuje certyfikat, instaluje profil
- `install_provisioning_profile` zwraca **ścieżkę pliku**, nie UUID — UUID wyciągany przez `File.basename(path, ".mobileprovision")`
- Changelog dla TestFlight: łączy sekcje `pl-PL` i `en-US` z `CHANGELOG.md` przez `\n\n`

### Android — `frontend/android/fastlane/Fastfile`

Lane `deploy`:
- Zapisuje `key.properties` z env vars przed buildem (signing konfiguracja)
- Czyta wersję z `pubspec.yaml`
- Release notes dla Play Store: osobne sekcje `pl-PL` i `en-US` jako hash

### Android — `frontend/android/fastlane/Appfile`

`json_key_file` jest ustawiany **warunkowo** (`if File.exist?`). Bez tego guard Fastlane rzuca błąd walidacji przy starcie, nawet gdy `json_key_data` jest przekazywane bezpośrednio do akcji.

---

## CHANGELOG — jedno źródło prawdy

Plik: `frontend/CHANGELOG.md`

Format:
```markdown
## 1.0.9

### pl-PL
- Opis po polsku

### en-US
- Description in English

## 1.0.8
...
```

Ten plik jest używany przez:
1. **Fastlane iOS** — jako `changelog:` w `upload_to_testflight`
2. **Fastlane Android** — jako `release_notes:` w `upload_to_play_store`
3. **Flutter in-app** — jako asset (`rootBundle.loadString`) w dialogu "Co nowego" — locale-aware (pl/en)

Przy każdym version bumpie należy dodać nową sekcję `## X.Y.Z` — wymagane przez `changelog-check` CI.

---

## GitHub Secrets

| Sekret | Używany przez |
|--------|---------------|
| `SUPABASE_PROD_URL` | iOS + Android CI (secrets.dart) |
| `SUPABASE_PROD_ANON_KEY` | iOS + Android CI (secrets.dart) |
| `APP_STORE_KEY_ID` | iOS Fastlane |
| `APP_STORE_ISSUER_ID` | iOS Fastlane |
| `APP_STORE_PRIVATE_KEY` | iOS Fastlane |
| `IOS_CERTIFICATE_BASE64` | iOS CI (certificate.p12) |
| `IOS_CERTIFICATE_PASSWORD` | iOS CI |
| `IOS_PROVISIONING_PROFILE_BASE64` | iOS CI (profile.mobileprovision) |
| `PLAY_STORE_JSON_KEY` | Android Fastlane |
| `ANDROID_KEYSTORE_BASE64` | Android CI (upload-keystore.jks) |
| `ANDROID_KEYSTORE_PASSWORD` | Android Fastlane |
| `ANDROID_KEY_ALIAS` | Android Fastlane |
| `ANDROID_KEY_PASSWORD` | Android Fastlane |

---

## Checklist nowego release

1. Zaktualizuj wersję w `frontend/pubspec.yaml` (np. `1.0.8+18` → `1.0.9+19`)
2. Dodaj sekcję `## 1.0.9` w `frontend/CHANGELOG.md` z pl-PL i en-US
3. Upewnij się że wszystkie flagi debug w `env_config.dart` są `false`
4. Otwórz PR z `main` → `deployment`
5. Poczekaj aż 4 statusy CI przejdą
6. Merge → deploy uruchamia się automatycznie
