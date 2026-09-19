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

## Deploy — Jenkins na `mac-mini-wiit1`

Deploy **nie działa już na GitHub Actions**. Robi go job Jenkinsa `planpm-deploy`
na mac mini M2 (opis maszyny: `CommandCenter/mac-mini-wiit1`), definicja w
[`Jenkinsfile.deploy`](../Jenkinsfile.deploy).

### Dlaczego przeniesione

5 z ostatnich 9 realnych przebiegów `deploy.yml` padło i **żadnej awarii nie
wywołała zmiana w tym repo**. Workflow nie przypinał niczego poza Xcode, więc
każdy build rozwiązywał najnowszego Fluttera i najnowszego fastlane'a na obrazie
runnera, który też się ruszał pod spodem:

| Co się zmieniło | Co padło |
|-----------------|----------|
| Flutter 3.44.1 | `IconData` |
| Flutter 3.44.8 | domyślnie włączony Swift Package Manager → `Module 'app_links' not found` |
| gym 2.237 | przeniesienie flag `-authenticationKey*` do fazy exportu |

Żadna z tych awarii nie odtwarzała się lokalnie. Na własnej maszynie toolchain
jest przypięty i zmienia się tylko commitem.

### Co job przypina

| Element | Gdzie | Wartość |
|---------|-------|---------|
| Flutter | `FLUTTER_VERSION` w `Jenkinsfile.deploy` | `3.44.4` — job sam klonuje SDK do `~/.jenkins-toolchains/flutter-<wersja>` |
| fastlane | `frontend/{ios,android}/Gemfile` | `2.237.0` |
| Xcode | `xcode-select` **oraz** `DEVELOPER_DIR` w etapie iOS | `/Applications/Xcode.app/Contents/Developer` |
| Zależności Darta | `frontend/pubspec.lock` | commitowany |
| Zależności Ruby | `frontend/{ios,android}/Gemfile.lock` | commitowane |

> **`frontend/.gitignore` miał `*.lock`** (odziedziczone z .gitignore repo
> Fluttera), więc każdy build rozwiązywał zależności od nowa. Pierwszy build
> tego joba na czystej maszynie dostał **44 pakiety w innych wersjach** niż te,
> na których apka jest rozwijana, i padł na `html` 0.15.6 → 0.15.7 wewnątrz
> `flutter_html` (`Method not found: 'matches'`). Ten sam build z lockiem
> przeszedł. Przypięcie samego Fluttera i fastlane'a **by tego nie złapało** —
> to była najprawdopodobniej realna przyczyna części awarii na GitHub Actions.

> ⚠️ Zejście z fastlane poniżej 2.237 wymaga **w tym samym commicie** przywrócenia
> `export_xcargs: signing_xcargs` w `ios/fastlane/Fastfile`. Od 2.237 gym sam
> wstrzykuje `-authenticationKey*` do `-exportArchive`; wcześniej nie, a podanie
> ich dwa razy wywala `xcodebuild`.

### Przebieg

`Checkout → Preflight → Provision Flutter → Release metadata → Generate
secrets.dart → Flutter dependencies → iOS → Android`.

- **Preflight** sprawdza toolchain maszyny i przy braku podaje komendę `brew`,
  która to naprawia (log czyta się zwykle zdalnie, maszyna stoi w piwnicy).
- **iOS i Android idą po kolei**, nie równolegle — dzielą jeden workspace
  i jeden `frontend/build`. Każdy jest w `catchError`, więc zepsuty podpis iOS
  nie blokuje wydania Androida, tak jak wcześniej dwa osobne joby.
- **`post { always }`** kasuje `secrets.dart`, certyfikat, keystore,
  `key.properties`, `.p8` z `TMPDIR`, usuwa keychain CI i przywraca domyślny
  keychain maszyny. Bez tego build zostawiałby certyfikat dystrybucyjny
  w workspace na maszynie, która nie należy do projektu.

### Parametry

| Parametr | Domyślnie | Do czego |
|----------|-----------|----------|
| `DEPLOY_IOS` | `true` | wyłącz, żeby pominąć iOS |
| `DEPLOY_ANDROID` | `true` | wyłącz, żeby pominąć Androida |
| `DRY_RUN` | `false` | zbuduj i podpisz wszystko, **nie wysyłaj nigdzie** |

`DRY_RUN` ustawia `PLANPM_SKIP_UPLOAD=true`, które oba Fastfile'e honorują tuż
przed `upload_to_*`. Pierwszy build na świeżo postawionej maszynie puszczaj
właśnie tak: TestFlight i Play nie przyjmą drugi raz tego samego numeru builda,
więc nieudana próba „na ostro" kosztowałaby bump wersji w `pubspec.yaml`.

### Flagi `[skip deploy]` / `[skip ios]` / `[skip android]`

Działają jak wcześniej — czytane z **treści commita** (nie tytułu PR), bo to
treść merge commita ląduje na `deployment`.

```
git commit -m "chore: update CI config [skip deploy]"
```

### Credentiale w Jenkinsie

GitHub nie ma sekretów plikowych, więc workflow trzymał certyfikat, keystore
i `.p8` jako base64. Jenkins ma — są plikami, czyli o jedno kodowanie mniej do
pomylenia i nic nie przechodzi przez `echo`.

| ID | Typ | Zmienna w jobie |
|----|-----|-----------------|
| `planpm-supabase-prod-url` | Secret text | `SUPABASE_PROD_URL` |
| `planpm-supabase-prod-anon-key` | Secret text | `SUPABASE_PROD_ANON_KEY` |
| `planpm-ios-certificate` | Secret file | certyfikat dystrybucyjny `.p12` |
| `planpm-ios-certificate-password` | Secret text | `IOS_CERTIFICATE_PASSWORD` |
| `planpm-appstore-key-id` | Secret text | `APP_STORE_KEY_ID` |
| `planpm-appstore-issuer-id` | Secret text | `APP_STORE_ISSUER_ID` |
| `planpm-appstore-private-key` | Secret file | `AuthKey_<KEY_ID>.p8` |
| `planpm-android-keystore` | Secret file | `upload-keystore.jks` |
| `planpm-android-keystore-password` | Secret text | `ANDROID_KEYSTORE_PASSWORD` |
| `planpm-android-key-password` | Secret text | `ANDROID_KEY_PASSWORD` |
| `planpm-android-key-alias` | Secret text | `ANDROID_KEY_ALIAS` |
| `planpm-play-store-json-key` | Secret file | service account Play |
| `planpm-discord-webhook` | Secret text | opcjonalny ping o porażce; brak = cisza |

> ⚠️ Mac mini należy do Koła Naukowego i dostęp do niego jest tymczasowy.
> Trzymanie na nim certyfikatu dystrybucyjnego Apple i keystore'a uploadowego
> Play oznacza, że **przy oddawaniu maszyny te klucze trzeba zrotować** — razem
> z kluczami z `backend/.env`, o których mówi wpis w CommandCenter.

### Jednorazowe postawienie maszyny

```bash
brew install ruby cocoapods openjdk@21

# NDK + cmdline-tools MUSZĄ być w środku ANDROID_HOME (cask brew kładzie
# cmdline-tools gdzie indziej i Flutter ich tam nie znajduje)
SDK=~/Library/Android/sdk
sdkmanager --sdk_root="$SDK" "cmdline-tools;latest" "ndk;28.2.13676358"

# Xcode — trzy OSOBNE kroki, każdy blokuje build na swój sposób.
# Wołaj binarkę z Xcode.app, nie /usr/bin/xcodebuild (ta idzie za globalnym
# xcode-select, który na tej maszynie wskazuje CommandLineTools).
XC=/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild
sudo "$XC" -license accept     # bez tego każde wywołanie xcodebuild = exit 69
sudo "$XC" -runFirstLaunch     # bez tego "xcodebuild failed to load a required plug-in"
"$XC" -downloadPlatform iOS    # bez tego "iOS 26.5 is not installed" przy buildzie na device (8,5 GB)
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

> **`xcode-select` musi wskazywać Xcode — `DEVELOPER_DIR` nie wystarczy.**
> Hooki native assets Darta (`objective_c`) Flutter odpala z wyczyszczonym
> środowiskiem, **bez `DEVELOPER_DIR`**, więc rozwiązują SDK przez globalny
> `xcode-select`. Wskazujący CommandLineTools daje `xcrun: error: SDK "iphoneos"
> cannot be located` → pusty stdout → hook wywala się stacktrace'em Darta, który
> nie wspomina ani o Xcode, ani o SDK. Etap iOS sprawdza to wprost i podaje
> komendę.

> **`-license accept` ≠ `-runFirstLaunch` ≠ `-downloadPlatform`.** Po samej
> licencji `xcodebuild -version` i `-showsdks` działają i wygląda to na
> skonfigurowane, ale build pada na nieładującym się `IDESimulatorFoundation`.
> Po `-runFirstLaunch` pada z kolei na braku platformy — a `-showsdks` cały czas
> pokazuje `iOS 26.5` i `Platforms/iPhoneOS.platform/Developer/SDKs/` zawiera
> `iPhoneOS26.5.sdk`, więc **po ścieżkach na dysku tego nie wykryjesz**. Dlatego
> Preflight sprawdza tylko licencję i first launch (`-checkFirstLaunchStatus`),
> a brak platformy zostawia komunikatowi `xcodebuild`, który mówi wprost, co
> zrobić.

> **Dlaczego NDK i cmdline-tools:** release appbundle jest strippowany z symboli
> debug. Bez nich Flutter mówi tylko „Release app bundle failed to strip debug
> symbols from native libraries. Please run flutter doctor" — a `flutter doctor`
> nie zgłasza żadnego problemu. Prawdziwy komunikat („Failed to find
> cmdline-tools") widać dopiero pod `flutter build -v`. Stage *Preflight*
> sprawdza teraz oba i podaje gotową komendę.

Job sam pobiera SDK Fluttera przy pierwszym użyciu danej wersji. Reszty pilnuje
stage *Preflight* — jeśli czegoś brakuje, build pada od razu z komendą naprawczą,
a nie po 20 minutach w środku archiwizacji.

Job w Jenkinsie: Pipeline → *Pipeline script from SCM* → repo `plan_pm`,
branch `*/deployment`, script path `Jenkinsfile.deploy`.

---

## Co zostało na GitHub Actions

Bramki PR zostają — są tanie, chodzą na Ubuntu i nie zależą od toolchainu
mobilnego, czyli od tego, co psuło deploy:

`deployment-source-check`, `deployment-env-check`, `changelog-check`,
`version-check`, `check-env-mode`.

Zniknął **tylko** `deploy.yml`.

---

## Fastlane

### iOS — `frontend/ios/fastlane/Fastfile`

Lane `beta`:
- Czyta wersję i build number z `pubspec.yaml`
- W CI: tworzy tymczasowy keychain i importuje do niego certyfikat `.p12`
- Changelog dla TestFlight: łączy sekcje `pl-PL` i `en-US` z `CHANGELOG.md` przez `\n\n`
- `PLANPM_SKIP_UPLOAD=true` → buduje i podpisuje, ale nie wysyła

**Podpis w CI jest w pełni ręczny** (`signingStyle: "manual"`, `use_automatic_signing: false`
dla obu targetów). Lokalnie zostaje automatyczny, bo tam jest zalogowany Xcode.
Dwa powody, oba wykryte realnym buildem:

1. **Eksport automatyczny nie działa na tym koncie.** Prosi Apple o wystawienie
   profili przez cloud signing, do czego klucz API nie ma uprawnień —
   `Cloud signing permission error` + `No profiles for 'com.piotrwittig.planpm'
   were found`, mimo że sama archiwizacja podpisała się poprawnie.
2. **`-allowProvisioningUpdates` zaśmiecał konto.** Xcode uznawał, że brakuje
   certyfikatu **deweloperskiego** dla maszyny, tworzył go na koncie, a klucz
   prywatny zapisywał w tymczasowym keychainie CI, który jest kasowany na końcu
   builda. Każdy kolejny build padał wtedy na „your account already has an Apple
   Development signing certificate for this machine, but its private key is not
   installed in your keychain", a na koncie zostawał martwy wpis
   `Apple Development: Created via API` — po jednym na przebieg (trzy z nich
   pochodzą jeszcze z deployów na GitHub Actions). W CI ta flaga jest wyłączona.

Aplikacja i rozszerzenie widżetu to **osobne bundle ID**, więc potrzebują osobnych
profili — stąd mapa `bundleId → nazwa profilu`, nie pojedynczy profil. Profile
pobiera `sigh` z `readonly: true`, czyli tylko ściąga to, co już istnieje na koncie.

> **Rotacja certyfikatu unieważnia profile.** Po wymianie certyfikatu
> dystrybucyjnego trzeba odtworzyć oba profile wskazujące na nowy — inaczej
> eksport zgłosi brak profili. W samym Fastfile nic się wtedy nie zmienia,
> bo szuka po bundle ID.

**Stan na 19.09.2026:** certyfikat `6FK4AGSNKY` (ważny do 19.09.2027), profile
`PlanPM App Store 2026` i `PlanPM Widget App Store 2026`. Materiał źródłowy
(klucz, CSR, `.cer`, `.p12`, hasło) leży w `~/keys/apple/planpm_distribution_2026-09-19.*`
— **poza repo**.

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

## Checklist nowego release

1. Zaktualizuj wersję w `frontend/pubspec.yaml` (np. `1.0.8+18` → `1.0.9+19`)
2. Dodaj sekcję `## 1.0.9` w `frontend/CHANGELOG.md` z pl-PL i en-US
3. Upewnij się że wszystkie flagi debug w `env_config.dart` są `false`
4. Otwórz PR z `main` → `deployment`
5. Poczekaj aż 4 statusy CI przejdą
6. Merge → deploy uruchamia się automatycznie
