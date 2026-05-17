// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get stage1Title => '';

  @override
  String get stage1Button => 'Witaj w Plan PM';

  @override
  String get stage2Title =>
      'Zobacz wszystkie zajęcia w przejrzystym planie tygodniowym.';

  @override
  String get stage2Button => 'Dalej';

  @override
  String get stage3Title =>
      'Znajdź swoje sale łatwo dzięki szczegółowym informacjom o lokalizacji.';

  @override
  String get stage3Button => 'Dalej';

  @override
  String get stage4Title =>
      'Otrzymuj przypomnienia przed każdym zajęciami, żeby nigdy ich nie przegapić.';

  @override
  String get stage4Button => 'Rozpocznij';

  @override
  String get welcomePageSelectionText => 'Powrót do WelcomeScreen';

  @override
  String get inputPageSelectionText => 'Powrót do InputPage';

  @override
  String get inputPageLabel => 'Twoje Dane Akademickie';

  @override
  String get facultyLabel => 'Wydział';

  @override
  String get facultyHintText => 'Wybierz wydział';

  @override
  String get fieldLabel => 'Kierunek studiów';

  @override
  String get fieldHintText => 'Wybierz kierunek studiów';

  @override
  String get yearLabel => 'Aktualny Rok';

  @override
  String get specialisationLabel => 'Specjalizacja';

  @override
  String get specialisationHintText => 'Wybierz specjalizacje';

  @override
  String get typeLabel => 'Tryb studiów';

  @override
  String get campusButton => 'Stacjonarne';

  @override
  String get extramuralButton => 'Zaoczne';

  @override
  String get continueButton => 'Kontynuuj';

  @override
  String get homePageLabel => 'Dane studenta to: ';

  @override
  String get facultyText => 'Wydział';

  @override
  String get fieldText => 'Kierunek';

  @override
  String get specialisationText => 'Specjalizacja';

  @override
  String get yearText => 'Rok';

  @override
  String get typeText => 'Tryb studiów';

  @override
  String get dataNaN => 'Brak danych';

  @override
  String get studySettings => 'Ustawienia studiów';

  @override
  String get skipButton => 'Pomiń';

  @override
  String get fullTimeStudy => 'Stacjonarne';

  @override
  String get partTimeStudy => 'Niestacjonarne';

  @override
  String get groupSelection => 'Wybór grupy';

  @override
  String get groupSelectionHint =>
      'Wybierz swój wydział, kierunek i tryb, aby spersonalizować plan zajęć';

  @override
  String get groupLoading => 'Ładowanie grup...';

  @override
  String get groupSettings => 'Ustawienia studiów';

  @override
  String get groupSelectionHintAfterLoad =>
      'Na podstawie Twoich ustawień studiów pobraliśmy dostępne grupy. Wybierz jedną lub wiele, aby śledzić kilka planów.';

  @override
  String get save => 'Zapisz';

  @override
  String get todayDataNaN => 'Brak zajęć na dziś';

  @override
  String pageErrorMess(Object snapshotError) {
    return 'Błąd w FutureBuilder $snapshotError';
  }

  @override
  String lectureLength(num lecturesLength) {
    return '$lecturesLength zajęcia';
  }

  @override
  String get recentLecture => 'Twoje 3 najbliższe zajęcia';

  @override
  String get lectureLoading => 'Ładowanie planu';

  @override
  String get todayLecturesNaN => 'Brak zajęć na dziś';

  @override
  String get lectureWigetHint =>
      'Jesteś na bieżąco! Skorzystaj z wolnego czasu lub przejrzyj swój harmonogram.';

  @override
  String get daysShortMon => 'Pon';

  @override
  String get daysShortTue => 'Wt';

  @override
  String get daysShortWed => 'Śr';

  @override
  String get daysShortThu => 'Czw';

  @override
  String get daysShortFri => 'Pt';

  @override
  String get daysShortSat => 'Sob';

  @override
  String get daysShortSun => 'Nd';

  @override
  String get daysMon => 'poniedziałek';

  @override
  String get daysTue => 'wtorek';

  @override
  String get daysWed => 'środa';

  @override
  String get daysThu => 'czwartek';

  @override
  String get daysFri => 'piątek';

  @override
  String get selectedGroupsHeader => 'Wybrane grupy';

  @override
  String get changeGroupsButton => 'Zmień grupy';

  @override
  String get selectedGroupsLabel => 'Wybrane grupy';

  @override
  String get noDataAvailable => 'Brak danych';

  @override
  String get academicInfoHeader => 'Dane studenta';

  @override
  String get lecturerInfoHeader => 'Dane wykładowcy';

  @override
  String get editButton => 'Edytuj';

  @override
  String studyYear(int year) {
    return '$year. rok';
  }

  @override
  String get studyModeLabel => 'Tryb studiów';

  @override
  String get groupTypeAuditorium => 'Audytorium';

  @override
  String get groupTypeClasses => 'Ćwiczenia';

  @override
  String get groupTypeLabs => 'Laboratoria';

  @override
  String get groupTypeOther => 'Inne';

  @override
  String get pageTitleHome => 'Strona główna';

  @override
  String get pageTitleLectures => 'Zajęcia';

  @override
  String get pageTitleSettings => 'Ustawienia';

  @override
  String get pageTitleNews => 'Nowości';

  @override
  String get debugHeader => 'Debug';

  @override
  String get returnToLabel => 'Powrót do';

  @override
  String get welcomeScreenButton => 'Welcome screen';

  @override
  String get inputPageButton => 'Podaj dane';

  @override
  String get professorLabel => 'Prowadzący';

  @override
  String get groupLabel => 'Grupa';

  @override
  String get lengthLabel => 'Czas trwania';

  @override
  String get additionalInformation => 'INFORMACJE DODATKOWE';

  @override
  String get notesLabel => 'Notatki';

  @override
  String get emptyNotesLabel => 'Puste';

  @override
  String get rectorHoursBadge => 'Godziny rektorskie';

  @override
  String get newsSectionLabel => 'Nowości z uczelni';

  @override
  String get feedbackHeader => 'Opinie i sugestie';

  @override
  String get sendFeedbackButton => 'Prześlij opinie';

  @override
  String get feedbackPageHeadline => 'Twoja opinia jest dla nas ważna!';

  @override
  String get feedbackPageDescription =>
      'Formularz otworzy się w Twojej przeglądarce, abyś mógł bezpiecznie się zalogować.';

  @override
  String get feedbackFormOpenGenericError =>
      'Nie udało się otworzyć formularza opinii.';

  @override
  String feedbackFormOpenError(String error) {
    return 'Nie udało się otworzyć formularza opinii: $error';
  }

  @override
  String daysAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days dni temu',
      many: '$days dni temu',
      few: '$days dni temu',
      one: '1 dzień temu',
      zero: 'dzisiaj',
    );
    return '$_temp0';
  }

  @override
  String get professorNaN => 'Brak wykładowcy';

  @override
  String get roomNaN => 'Brak sali';

  @override
  String dateWithWeekday(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.yMMMEd(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString';
  }

  @override
  String dateDayMonth(DateTime date1) {
    final intl.DateFormat date1DateFormat = intl.DateFormat.MMMM(localeName);
    final String date1String = date1DateFormat.format(date1);

    return '$date1String';
  }

  @override
  String get details => 'Szczegóły';

  @override
  String get universityStructureLoading => 'Ładowanie struktury uczelni';

  @override
  String get noNews => 'Brak aktualności';

  @override
  String get universityStructureEmpty =>
      'Struktura uczelni jest pusta. Czy jesteś podłączony do internetu?';

  @override
  String get noSpecialisationOption => 'Brak specjalizacji';

  @override
  String get noSpecialisationForField => 'Brak specjalizacji dla tego kierunku';

  @override
  String get pePageTitle => 'Zapisy na WF';

  @override
  String get pePageDescription =>
      'Wybierz zajęcia z wychowania fizycznego na ten semestr. Pamiętaj, że zapisy odbywają się okresowo.';

  @override
  String get pePageButton => 'Przejdź do zapisów';

  @override
  String get pePageUrlError => 'Nie udało się otworzyć strony zapisów.';

  @override
  String get studentIdPageTitle => 'Legitymacja studencka';

  @override
  String get studentIdPageDescription =>
      'Wyrobienie lub odnowienie legitymacji studenckiej odbywa się przez uczelniane konto. Pamiętaj, że legitymacja jest ważna przez semestr.';

  @override
  String get studentIdPageButton => 'Przejdź do wyrobienia';

  @override
  String get studentIdPageUrlError =>
      'Nie udało się otworzyć strony legitymacji.';

  @override
  String get virtualUniversityPageTitle => 'Wirtualna uczelnia';

  @override
  String get virtualUniversityPageDescription =>
      'Sprawdź swoje oceny, dane osobowe i załatwiaj sprawy uczelniane przez portal Wirtualnej Uczelni.';

  @override
  String get virtualUniversityPageButton => 'Otwórz portal';

  @override
  String get virtualUniversityPageUrlError =>
      'Nie udało się otworzyć portalu Wirtualnej Uczelni.';

  @override
  String get degreeLevelLabel => 'Stopień studiów';

  @override
  String get degreeLevelEngineering => 'Inżynierskie';

  @override
  String get degreeLevelMasters => 'Magisterskie';

  @override
  String get unexpectedError => 'Ojej! Coś poszło nie tak.';

  @override
  String get networkErrorDescription =>
      'Sprawdź połączenie z internetem i spróbuj ponownie.';

  @override
  String get announcementDismiss => 'Rozumiem';

  @override
  String get announcementUpdate => 'Aktualizuj';

  @override
  String get announcementSkip => 'Pomiń';

  @override
  String get appearanceHeader => 'Wygląd';

  @override
  String get themeLight => 'Jasny';

  @override
  String get themeDark => 'Ciemny';

  @override
  String get themeSystem => 'Systemowy';

  @override
  String get appearanceHint => 'Wybierz motyw, który najbardziej Ci odpowiada';

  @override
  String get activeThemeLabel => 'Aktywny motyw: ';

  @override
  String get personalizationHeader => 'Personalizacja';

  @override
  String get languageHeader => 'Język';

  @override
  String get languageSystem => 'Systemowy';

  @override
  String get languagePolish => 'Polski';

  @override
  String get languageEnglish => 'Angielski';

  @override
  String get languageUkrainian => 'Ukraiński';

  @override
  String get languageHint => 'Wybierz język aplikacji';

  @override
  String get activeLanguageLabel => 'Aktywny język: ';

  @override
  String get accentColorTitle => 'Kolor wiodący';

  @override
  String get amoledModeTitle => 'Prawdziwa czerń';

  @override
  String get amoledModeDesc => 'Całkowicie czarne tło w trybie ciemnym';

  @override
  String get eventStyleTitle => 'Styl kolorowania zajęć';

  @override
  String get eventStyleCurrent => 'Domyślny';

  @override
  String get eventStylePastel => 'Pastelowe';

  @override
  String get eventStyleVibrant => 'Żywe';

  @override
  String get eventStyleMonochrome => 'Jednokolorowe';

  @override
  String get aboutApp => 'O aplikacji';

  @override
  String get version => 'Wersja';

  @override
  String get createdBy => 'Stworzono przez';

  @override
  String get kniName =>
      'Koło Naukowe Informatyki\nPolitechniki Morskiej w Szczecinie';

  @override
  String get openSourceInfo => 'Ta aplikacja jest open-source';

  @override
  String get githubRepo => 'Otwórz repozytorium na Github';

  @override
  String get couldNotOpenRepo => 'Nie udało się otworzyć repozytorium';

  @override
  String get appDescription =>
      'Przejrzysty i szybki plan zajęć z podglądem na żywo. Stworzony specjalnie dla studentów Politechniki Morskiej, aby ułatwić organizację i śledzenie codziennych wykładów.';

  @override
  String get debugReturnToWelcome => 'Powrót do Welcome Screen';

  @override
  String get debugModeUnlocked => 'Jesteś już deweloperem';

  @override
  String debugTapsRemaining(int count) {
    return 'Zostało jeszcze $count naciśnięć, aby zostać deweloperem';
  }

  @override
  String get debugModeDisable => 'Wyłącz tryb dewelopera';

  @override
  String get debugModeDisabled => 'Tryb dewelopera wyłączony';

  @override
  String get infoSection => 'Informacje';

  @override
  String get readMore => 'Czytaj dalej';

  @override
  String get whatsNewTitle => 'Co nowego';

  @override
  String get whatsNewGotIt => 'Super!';

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '${hours}h ${minutes}min';
  }

  @override
  String durationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get roleSelectionTitle => 'Jak chcesz korzystać z PlanPM?';

  @override
  String get roleSelectionSubtitle =>
      'Wybierz rolę, która najlepiej opisuje Twoje potrzeby';

  @override
  String get roleStudentButton => 'Jestem studentem';

  @override
  String get roleLecturerButton => 'Jestem wykładowcą';

  @override
  String get lecturerSelectionTitle => 'Wybierz prowadzącego';

  @override
  String get lecturerSelectionSubtitle =>
      'Wpisz imię, nazwisko lub nazwę przedmiotu';

  @override
  String get lecturerSearchNoResults => 'Brak wyników';

  @override
  String get lecturerLabel => 'Wykładowca';

  @override
  String get roleSectionTitle => 'Rola';

  @override
  String get roleStudentViewTitle => 'Widok studenta';

  @override
  String get roleStudentViewSubtitle => 'Przełącz na plan studenta';

  @override
  String get roleViewingAsStudent => 'Przeglądasz aktualnie plan jako student.';

  @override
  String get roleViewingAsLecturer =>
      'Przeglądasz aktualnie plan jako wykładowca.';

  @override
  String get roleCurrentlyActive => 'Aktualnie aktywny';

  @override
  String get roleLecturerViewTitle => 'Widok wykładowcy';

  @override
  String get roleLecturerViewSubtitle => 'Przełącz na widok wykładowcy';

  @override
  String get debugRoleSelector => 'Wybór roli';

  @override
  String get debugClearCache => 'Wyczyść cache';

  @override
  String get debugCacheCleared => 'Cache wyczyszczony';

  @override
  String get debugSevenDayMode => 'Tryb 7-dniowy';

  @override
  String get newsLoading => 'Ładowanie aktualności';

  @override
  String get newsNoDataDescription =>
      'Brak nowych wiadomości. Sprawdź później, aby zobaczyć aktualizacje.';

  @override
  String get searchHint => 'Szukaj...';
}
