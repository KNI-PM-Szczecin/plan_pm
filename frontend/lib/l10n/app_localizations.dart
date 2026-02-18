import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pl.dart';
import 'app_localizations_uk.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pl'),
    Locale('uk'),
  ];

  /// onboarding_screen.dart - Title/Header for the first onboarding step. (Empty value is intentional)
  ///
  /// In pl, this message translates to:
  /// **''**
  String get stage1Title;

  /// onboarding_screen.dart - Action button on the first welcome screen.
  ///
  /// In pl, this message translates to:
  /// **'Witaj w Plan PM'**
  String get stage1Button;

  /// onboarding_screen.dart - Feature description for the second step.
  ///
  /// In pl, this message translates to:
  /// **'Zobacz wszystkie zajęcia w przejrzystym planie tygodniowym.'**
  String get stage2Title;

  /// onboarding_screen.dart - Navigation button to the next onboarding step.
  ///
  /// In pl, this message translates to:
  /// **'Dalej'**
  String get stage2Button;

  /// onboarding_screen.dart - Feature description for the third step.
  ///
  /// In pl, this message translates to:
  /// **'Znajdź swoje sale łatwo dzięki szczegółowym informacjom o lokalizacji.'**
  String get stage3Title;

  /// onboarding_screen.dart - Navigation button to the next onboarding step.
  ///
  /// In pl, this message translates to:
  /// **'Dalej'**
  String get stage3Button;

  /// onboarding_screen.dart - Feature description for the final step.
  ///
  /// In pl, this message translates to:
  /// **'Otrzymuj przypomnienia przed każdym zajęciami, żeby nigdy ich nie przegapić.'**
  String get stage4Title;

  /// onboarding_screen.dart - Button to finalize onboarding and start configuration.
  ///
  /// In pl, this message translates to:
  /// **'Rozpocznij'**
  String get stage4Button;

  /// debug_menu.dart - Debug/Navigation link to return to the Welcome screen.
  ///
  /// In pl, this message translates to:
  /// **'Powrót do WelcomeScreen'**
  String get welcomePageSelectionText;

  /// debug_menu.dart - Debug/Navigation link to return to the Data Input screen.
  ///
  /// In pl, this message translates to:
  /// **'Powrót do InputPage'**
  String get inputPageSelectionText;

  /// input_page.dart - Header for the screen where the user enters academic data.
  ///
  /// In pl, this message translates to:
  /// **'Twoje Dane Akademickie'**
  String get inputPageLabel;

  /// input_page.dart - Label for the 'Faculty' selection field.
  ///
  /// In pl, this message translates to:
  /// **'Wydział'**
  String get facultyLabel;

  /// input_page.dart - Placeholder text for the faculty selection.
  ///
  /// In pl, this message translates to:
  /// **'Wybierz wydział'**
  String get facultyHintText;

  /// input_page.dart - Label for the 'Field of Study' selection field.
  ///
  /// In pl, this message translates to:
  /// **'Kierunek studiów'**
  String get fieldLabel;

  /// input_page.dart - Placeholder text for the field of study selection.
  ///
  /// In pl, this message translates to:
  /// **'Wybierz kierunek studiów'**
  String get fieldHintText;

  /// input_page.dart - Label for the 'Current Year' selector.
  ///
  /// In pl, this message translates to:
  /// **'Aktualny Rok'**
  String get yearLabel;

  /// input_page.dart - Label for the 'Specialization' selection field.
  ///
  /// In pl, this message translates to:
  /// **'Specjalizacja'**
  String get specialisationLabel;

  /// input_page.dart - Placeholder text for the specialization selection.
  ///
  /// In pl, this message translates to:
  /// **'Wybierz specjalizacje'**
  String get specialisationHintText;

  /// input_page.dart - Label for the Study Mode selection section.
  ///
  /// In pl, this message translates to:
  /// **'Tryb studiów'**
  String get typeLabel;

  /// input_page.dart - Option button for 'Full-time' study mode.
  ///
  /// In pl, this message translates to:
  /// **'Stacjonarne'**
  String get campusButton;

  /// input_page.dart - Option button for 'Part-time/Extramural' study mode.
  ///
  /// In pl, this message translates to:
  /// **'Zaoczne'**
  String get extramuralButton;

  /// input_page.dart - Main action button to proceed after data input.
  ///
  /// In pl, this message translates to:
  /// **'Kontynuuj'**
  String get continueButton;

  /// home_page.dart - Header for the student data summary section.
  ///
  /// In pl, this message translates to:
  /// **'Dane studenta to: '**
  String get homePageLabel;

  /// home_page.dart - Label for the displayed 'Faculty' value.
  ///
  /// In pl, this message translates to:
  /// **'Wydział'**
  String get facultyText;

  /// home_page.dart - Label for the displayed 'Field of Study' value.
  ///
  /// In pl, this message translates to:
  /// **'Kierunek'**
  String get fieldText;

  /// home_page.dart - Label for the displayed 'Specialization' value.
  ///
  /// In pl, this message translates to:
  /// **'Specjalizacja'**
  String get specialisationText;

  /// home_page.dart - Label for the displayed 'Year' value.
  ///
  /// In pl, this message translates to:
  /// **'Rok'**
  String get yearText;

  /// home_page.dart - Label for the displayed 'Study Mode' value.
  ///
  /// In pl, this message translates to:
  /// **'Tryb studiów'**
  String get typeText;

  /// home_page.dart - Message shown when specific academic data is missing.
  ///
  /// In pl, this message translates to:
  /// **'Brak danych'**
  String get dataNaN;

  /// settings_page.dart - Title for the study settings section or button.
  ///
  /// In pl, this message translates to:
  /// **'Ustawienia studiów'**
  String get studySettings;

  /// group_selection_page.dart - Button to skip the current configuration step.
  ///
  /// In pl, this message translates to:
  /// **'Pomiń'**
  String get skipButton;

  /// settings_page.dart - Full name of the Full-time study mode.
  ///
  /// In pl, this message translates to:
  /// **'Stacjonarne'**
  String get fullTimeStudy;

  /// settings_page.dart - Full name of the Part-time study mode.
  ///
  /// In pl, this message translates to:
  /// **'Niestacjonarne'**
  String get partTimeStudy;

  /// group_selection_page.dart - Title for the Group Selection screen/section.
  ///
  /// In pl, this message translates to:
  /// **'Wybór grupy'**
  String get groupSelection;

  /// group_selection_page.dart - Initial hint/instruction for group selection.
  ///
  /// In pl, this message translates to:
  /// **'Wybierz swój wydział, kierunek i tryb, aby spersonalizować plan zajęć'**
  String get groupSelectionHint;

  /// group_selection_page.dart - Loading message while fetching available groups.
  ///
  /// In pl, this message translates to:
  /// **'Ładowanie grup...'**
  String get groupLoading;

  /// group_selection_page.dart - Header for the study settings context within group selection.
  ///
  /// In pl, this message translates to:
  /// **'Ustawienia studiów'**
  String get groupSettings;

  /// group_selection_page.dart - Hint/Instruction displayed after groups have been successfully loaded.
  ///
  /// In pl, this message translates to:
  /// **'Na podstawie Twoich ustawień studiów pobraliśmy dostępne grupy. Wybierz jedną lub wiele, aby śledzić kilka planów.'**
  String get groupSelectionHintAfterLoad;

  /// group_selection_page.dart - Action button to save settings or selected groups.
  ///
  /// In pl, this message translates to:
  /// **'Zapisz'**
  String get save;

  /// schedule_view.dart - Message shown on the 'Today' tab when no classes are scheduled.
  ///
  /// In pl, this message translates to:
  /// **'Brak zajęć na dziś'**
  String get todayDataNaN;

  /// No description provided for @pageErrorMess.
  ///
  /// In pl, this message translates to:
  /// **'Błąd w FutureBuilder {snapshotError}'**
  String pageErrorMess(Object snapshotError);

  /// No description provided for @lectureLength.
  ///
  /// In pl, this message translates to:
  /// **'{lecturesLength} zajęcia'**
  String lectureLength(num lecturesLength);

  /// today_lectures.dart - Label for the next upcoming class/lecture.
  ///
  /// In pl, this message translates to:
  /// **'Twoje najblizsze zajęcia'**
  String get recentLecture;

  /// schedule_view.dart - General loading indicator text for the schedule.
  ///
  /// In pl, this message translates to:
  /// **'Ładowanie planu'**
  String get lectureLoading;

  /// today_lectures.dart - Message shown when there are no lectures for the current day.
  ///
  /// In pl, this message translates to:
  /// **'Brak zajęć na dziś'**
  String get todayLecturesNaN;

  /// today_lectures.dart - Hint/message shown after the last lecture of the day has finished.
  ///
  /// In pl, this message translates to:
  /// **'Jesteś na bieżąco! Skorzystaj z wolnego czasu lub przejrzyj swój harmonogram.'**
  String get lectureWigetHint;

  /// day_selection.dart - Short name for Monday (Poniedziałek).
  ///
  /// In pl, this message translates to:
  /// **'Pon'**
  String get daysShortMon;

  /// day_selection.dart - Short name for Tuesday (Wtorek).
  ///
  /// In pl, this message translates to:
  /// **'Wt'**
  String get daysShortTue;

  /// day_selection.dart - Short name for Wednesday (Środa).
  ///
  /// In pl, this message translates to:
  /// **'Śr'**
  String get daysShortWed;

  /// day_selection.dart - Short name for Thursday (Czwartek).
  ///
  /// In pl, this message translates to:
  /// **'Czw'**
  String get daysShortThu;

  /// day_selection.dart - Short name for Friday (Piątek).
  ///
  /// In pl, this message translates to:
  /// **'Pt'**
  String get daysShortFri;

  /// day_selection.dart - Full lowercase name for Monday.
  ///
  /// In pl, this message translates to:
  /// **'poniedziałek'**
  String get daysMon;

  /// day_selection.dart - Full lowercase name for Tuesday.
  ///
  /// In pl, this message translates to:
  /// **'wtorek'**
  String get daysTue;

  /// day_selection.dart - Full lowercase name for Wednesday.
  ///
  /// In pl, this message translates to:
  /// **'środa'**
  String get daysWed;

  /// day_selection.dart - Full lowercase name for Thursday.
  ///
  /// In pl, this message translates to:
  /// **'czwartek'**
  String get daysThu;

  /// day_selection.dart - Full lowercase name for Friday.
  ///
  /// In pl, this message translates to:
  /// **'piątek'**
  String get daysFri;

  /// group_info.dart - Header for the selected groups section.
  ///
  /// In pl, this message translates to:
  /// **'Wybrane grupy'**
  String get selectedGroupsHeader;

  /// group_info.dart - Label for the button to navigate to group selection.
  ///
  /// In pl, this message translates to:
  /// **'Zmień grupy'**
  String get changeGroupsButton;

  /// group_info.dart - Small label/title above the list of selected group tags.
  ///
  /// In pl, this message translates to:
  /// **'Wybrane grupy'**
  String get selectedGroupsLabel;

  /// group_info.dart - Placeholder text displayed when no groups have been selected.
  ///
  /// In pl, this message translates to:
  /// **'Brak danych'**
  String get noDataAvailable;

  /// student_info.dart - Header for the section displaying the user's academic details.
  ///
  /// In pl, this message translates to:
  /// **'Informacje akademickie'**
  String get academicInfoHeader;

  /// student_info.dart - Label for the button to navigate to the input/edit page.
  ///
  /// In pl, this message translates to:
  /// **'Edytuj'**
  String get editButton;

  /// student_info.dart - Displays the current year of study with proper pluralization (e.g., 1 rok, 2 lata, 5 lat).
  ///
  /// In pl, this message translates to:
  /// **'{year, plural, one{1 rok} few{{year} lata} many{{year} lat} other{{year} roku}}'**
  String studyYear(int year);

  /// student_info.dart - Label for the study mode (e.g., 'Full-time').
  ///
  /// In pl, this message translates to:
  /// **'Tryb studiów'**
  String get studyModeLabel;

  /// group_builder.dart - Full name for group type 'A' (Audytorium).
  ///
  /// In pl, this message translates to:
  /// **'Audytorium'**
  String get groupTypeAuditorium;

  /// group_builder.dart - Full name for group type 'C' (Classes/Ćwiczenia).
  ///
  /// In pl, this message translates to:
  /// **'Ćwiczenia'**
  String get groupTypeClasses;

  /// group_builder.dart - Full name for group type 'L' (Laboratoria).
  ///
  /// In pl, this message translates to:
  /// **'Laboratoria'**
  String get groupTypeLabs;

  /// group_builder.dart - Default name for unmapped group types.
  ///
  /// In pl, this message translates to:
  /// **'Inne'**
  String get groupTypeOther;

  /// main.dart - Title for the Home page in the navigation bar.
  ///
  /// In pl, this message translates to:
  /// **'Strona główna'**
  String get pageTitleHome;

  /// main.dart - Title for the Lectures/Schedule page in the navigation bar.
  ///
  /// In pl, this message translates to:
  /// **'Zajęcia'**
  String get pageTitleLectures;

  /// main.dart - Title for the Settings page in the navigation bar.
  ///
  /// In pl, this message translates to:
  /// **'Ustawienia'**
  String get pageTitleSettings;

  /// news_page.dart - Title for the NewsPage page in the navigation bar.
  ///
  /// In pl, this message translates to:
  /// **'Nowości'**
  String get pageTitleNews;

  /// menu_page.dart - Header for the debug/development section.
  ///
  /// In pl, this message translates to:
  /// **'Debug'**
  String get debugHeader;

  /// menu_page.dart - Introductory label for navigation buttons in the debug section (e.g., 'Return to [Welcome screen]').
  ///
  /// In pl, this message translates to:
  /// **'Powrót do'**
  String get returnToLabel;

  /// menu_page.dart - Label for the button that resets navigation to the Welcome Page.
  ///
  /// In pl, this message translates to:
  /// **'Welcome screen'**
  String get welcomeScreenButton;

  /// menu_page.dart - Label for the button that resets navigation to the Input Page.
  ///
  /// In pl, this message translates to:
  /// **'Podaj dane'**
  String get inputPageButton;

  /// lecture.dart - Label for the lecture wiget professor header.
  ///
  /// In pl, this message translates to:
  /// **'Profesor'**
  String get professorLabel;

  /// lecture.dart - Label for the lecture wiget group header.
  ///
  /// In pl, this message translates to:
  /// **'Grupa'**
  String get groupLabel;

  /// lecture.dart - Label for the lecture wiget lecture length header.
  ///
  /// In pl, this message translates to:
  /// **'Czas trwania'**
  String get lengthLabel;

  /// lecture.dart - Label for the lecture wiget notes header.
  ///
  /// In pl, this message translates to:
  /// **'Notatki'**
  String get notesLabel;

  /// lecture.dart - Label for the lecture wiget if there are no notes.
  ///
  /// In pl, this message translates to:
  /// **'Puste'**
  String get emptyNotesLabel;

  /// news_page.dart - Label/header for the section showing university news.
  ///
  /// In pl, this message translates to:
  /// **'Nowości z uczelni'**
  String get newsSectionLabel;

  /// settings_page.dart - Header for the feedback and suggestions section.
  ///
  /// In pl, this message translates to:
  /// **'Opinie i sugestie'**
  String get feedbackHeader;

  /// settings_page.dart - Button label to submit feedback/suggestions.
  ///
  /// In pl, this message translates to:
  /// **'Prześlij opinie'**
  String get sendFeedbackButton;

  /// General - Relative time label like '1 dzień temu', '0 dni temu (dzisiaj)', '4 dni temu'.
  ///
  /// In pl, this message translates to:
  /// **'{days, plural, =0{dzisiaj} one{1 dzień temu} few{{days} dni temu} many{{days} dni temu} other{{days} dni temu}}'**
  String daysAgo(int days);

  /// lecture.dart - Message shown when a lecture has no professor assigned.
  ///
  /// In pl, this message translates to:
  /// **'Brak wykładowcy'**
  String get professorNaN;

  /// lecture.dart - Message shown when a lecture has no assigned room.
  ///
  /// In pl, this message translates to:
  /// **'Brak sali'**
  String get roomNaN;

  /// Ogólne — data w formacie dd.MM.yyyy oraz skrócony dzień tygodnia (EEE). Przykład: 16.11.2025 - nie
  ///
  /// In pl, this message translates to:
  /// **'{date}'**
  String dateWithWeekday(DateTime date);

  /// Ogólne — pełna nazwa dnia tygodnia (EEEE). Przykład: „poniedziałek”
  ///
  /// In pl, this message translates to:
  /// **'{date1}'**
  String dateDayMonth(DateTime date1);

  /// No description provided for @details.
  ///
  /// In pl, this message translates to:
  /// **'Szczegóły'**
  String get details;

  /// university_structure.dart - Loading message while fetching the university structure.
  ///
  /// In pl, this message translates to:
  /// **'Ładowanie struktury uczelni'**
  String get universityStructureLoading;

  /// news_page.dart - Message shown when there are no news items.
  ///
  /// In pl, this message translates to:
  /// **'Brak aktualności'**
  String get noNews;

  /// university_structure.dart - Message shown when the university structure couldn't be loaded; suggests checking internet connection.
  ///
  /// In pl, this message translates to:
  /// **'Struktura uczelni jest pusta. Czy jesteś podłączony do internetu?'**
  String get universityStructureEmpty;

  /// group_selection_page.dart - Message shown when there are no specialisations available for the selected field.
  ///
  /// In pl, this message translates to:
  /// **'Brak specjalizacji dla tego kierunku'**
  String get noSpecialisationForField;

  /// input_page.dart - Label for the degree level selector.
  ///
  /// In pl, this message translates to:
  /// **'Stopień studiów'**
  String get degreeLevelLabel;

  /// input_page.dart - Button label for engineering degree level.
  ///
  /// In pl, this message translates to:
  /// **'Inżynierskie'**
  String get degreeLevelEngineering;

  /// input_page.dart - Button label for masters degree level.
  ///
  /// In pl, this message translates to:
  /// **'Magisterskie'**
  String get degreeLevelMasters;

  /// Ogólny komunikat wyświetlany, gdy w kodzie wystąpi wyjątek.
  ///
  /// In pl, this message translates to:
  /// **'Ojej! Coś poszło nie tak.'**
  String get unexpectedError;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pl', 'uk'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pl':
      return AppLocalizationsPl();
    case 'uk':
      return AppLocalizationsUk();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
