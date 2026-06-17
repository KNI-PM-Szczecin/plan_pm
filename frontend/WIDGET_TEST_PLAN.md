# Widget Test Plan (QA)

Plan testów natywnych widżetów ekranu głównego (Android + iOS) po przebudowie rozmiarów
i dodaniu flag debugowych.

## Setup — flagi debug (`lib/env_config.dart`)

Dane do widżetu można wymusić bez realnego planu:

| Flaga | Typ | Rola |
|-------|-----|------|
| `kDebugWidget` | `bool` | `true` = wstrzykuje fake zajęcia do widżetu (omija DB). Domyślnie `false`. |
| `kDebugWidgetCount` | `int` (0–7) | Ile fake zajęć wypchnąć gdy `kDebugWidget=true`. `0` = pusty stan. |

> **Uwaga:** wartość poza 0–7 jest przycinana (`clamp`), więc nie wywali apki.

**Procedura po każdej zmianie flagi:**
1. Ustaw `kDebugWidget = true` i `kDebugWidgetCount = N`.
2. `flutter run` (Android) lub `flutter run` + build extension w Xcode (iOS).
3. **Uruchom apkę** (sync zapisuje dane do widżetu — bez tego widżet się nie odświeży).
4. Na ekranie głównym: **usuń i dodaj widżet na nowo** (Android cache'uje stary rozmiar instancji).

> Przed mergem do `deployment`: `kDebugWidget` MUSI być `false` (widżet czyta wtedy realny plan z SQLite).

---

## Android — trzy stałe rozmiary (nieskalowalne)

W pickerze: **Plan PM — mały / średni / duży**. Każdy ma stały rozmiar (brak resize).

| Widżet | Szerokość | Maks. kart |
|--------|-----------|-----------|
| Mały | 3 kafelki | **3** |
| Średni | 4 kafelki | **5** |
| Duży | 5 kafelków (pełna szer.) | **7** |

**Oczekiwane (gdy `kDebugWidgetCount` ≥ pojemności rozmiaru):**
- Mały pokazuje 3 karty, średni 5, duży 7.
- Karty mają **stałą wysokość**, są **wyśrodkowane w pionie**, z **równym marginesem ze wszystkich stron**.
- **Żadna karta nie jest ucięta** na dole/krawędzi.
- Widżeta **nie da się rozciągnąć** (brak uchwytów resize).

### Przypadki do przejścia (Android)

1. `kDebugWidgetCount = 0` → wszystkie rozmiary: „Brak zajęć na dziś" wyśrodkowane.
2. `kDebugWidgetCount = 1` → każdy rozmiar: 1 karta wyśrodkowana, równe marginesy.
3. `kDebugWidgetCount = 3` → mały pełny (3), średni 3, duży 3.
4. `kDebugWidgetCount = 5` → mały 3 (cap), średni pełny (5), duży 5.
5. `kDebugWidgetCount = 7` → mały 3, średni 5, duży pełny (7).
6. Karta trwającego zajęcia ma pasek postępu; marginesy/wysokości się nie rozjeżdżają.
7. Stan rector/odwołane (niżej): szara karta + przekreślenie + ikona + **plakietka z tekstem**.

---

## iOS — trzy systemowe rozmiary (osobna implementacja)

iOS to oddzielny WidgetKit — **nie odzwierciedla liczb z Androida**. Limity sztywne:

| Rozmiar | Maks. kart |
|---------|-----------|
| systemSmall | 2 |
| systemMedium | 2 |
| systemLarge | 5 |

**Różnice względem Androida (świadome):**
- iOS pokazuje tylko zajęcia **jeszcze nie zakończone** (`end ≥ teraz`) z **bieżącego dnia** — przeszłe znikają.
  W trybie debug payload iOS startuje „od teraz", więc fake zajęcia są widoczne o każdej porze.
- Stos kart jest **wyśrodkowany** gdy pełny (np. 5/5 na large), inaczej **dosunięty do góry**.
- iOS **nie renderuje tekstu plakietki** — rector i odwołane wyglądają identycznie (szara karta + przekreślenie + ikona).

### Przypadki do przejścia (iOS)

1. `kDebugWidgetCount = 0` → „Brak zajęć na dziś" wyśrodkowane (każdy rozmiar).
2. `kDebugWidgetCount = 1` → 1 karta u góry (large) / 1 karta (small, medium).
3. `kDebugWidgetCount = 5`/`7` → small/medium: 2 karty; large: 5 kart (pełny → wyśrodkowane).
4. Pierwsza (bieżąca) karta w debug jest **odwołana** → szara, przekreślona, z ikoną, bez paska postępu.
5. Pasek postępu (live) pojawia się na trwającym, nieodwołanym zajęciu (iOS 16+).

---

## Stan rector / odwołane

Wykrywany z pola `notes` (`canceledReasonFromNotes` — wspólne dla apki i widżetu):
`godziny rektorskie` → rector hours, `dzień rektorski` → rector day, `zajęcia odwołane` → canceled.

**Oczekiwane na karcie:**
- Szare tło (Android: `widget_card_rector`, iOS: szary + ukośne paski).
- Przekreślony tytuł / godziny / sala.
- Ikona ostrzeżenia przy tytule.
- Brak paska postępu.
- **Android dodatkowo:** plakietka z tekstem (np. „Odwołane", „Godziny rektorskie"). iOS — bez tekstu.

W debug: 2. zajęcie jest oznaczone jako godziny rektorskie (oba payloady); na iOS dodatkowo 1. zajęcie jako odwołane.

---

## Real data (regression)

Z `kDebugWidget = false` i realnym planem w aplikacji:
- Widżet pokazuje faktyczne dzisiejsze zajęcia (Android) / nadchodzące z tygodnia (iOS).
- Odświeżenie po `CacheService.syncLectures` działa bez ponownego otwierania apki (iOS timeline).
