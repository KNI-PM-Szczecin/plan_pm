// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get stage1Title => '';

  @override
  String get stage1Button => 'Welcome to Plan PM';

  @override
  String get stage2Title => 'See all classes in a clear weekly schedule.';

  @override
  String get stage2Button => 'Next';

  @override
  String get stage3Title =>
      'Easily find your rooms with detailed location information.';

  @override
  String get stage3Button => 'Next';

  @override
  String get stage4Title =>
      'Receive reminders before every class so you never miss them.';

  @override
  String get stage4Button => 'Start';

  @override
  String get welcomePageSelectionText => 'Back to WelcomeScreen';

  @override
  String get inputPageSelectionText => 'Back to InputPage';

  @override
  String get inputPageLabel => 'Your Academic Data';

  @override
  String get facultyLabel => 'Faculty';

  @override
  String get facultyHintText => 'Select faculty';

  @override
  String get fieldLabel => 'Field of Study';

  @override
  String get fieldHintText => 'Select field of study';

  @override
  String get yearLabel => 'Current Year';

  @override
  String get specialisationLabel => 'Specialization';

  @override
  String get specialisationHintText => 'Select specialization';

  @override
  String get typeLabel => 'Study Mode';

  @override
  String get campusButton => 'Full-time';

  @override
  String get extramuralButton => 'Part-time';

  @override
  String get continueButton => 'Continue';

  @override
  String get homePageLabel => 'Student data is:';

  @override
  String get facultyText => 'Faculty';

  @override
  String get fieldText => 'Field';

  @override
  String get specialisationText => 'Specialization';

  @override
  String get yearText => 'Year';

  @override
  String get typeText => 'Study mode';

  @override
  String get dataNaN => 'No data';

  @override
  String get studySettings => 'Study Settings';

  @override
  String get skipButton => 'Skip';

  @override
  String get fullTimeStudy => 'Full-time';

  @override
  String get partTimeStudy => 'Part-time';

  @override
  String get groupSelection => 'Group Selection';

  @override
  String get groupSelectionHint =>
      'Select your faculty, field, and mode to personalize your schedule';

  @override
  String get groupLoading => 'Loading groups...';

  @override
  String get groupSettings => 'Study Settings';

  @override
  String get groupSelectionHintAfterLoad =>
      'Based on your study settings, we have downloaded available groups. Select one or multiple to track several schedules.';

  @override
  String get save => 'Save';

  @override
  String get todayDataNaN => 'No classes for today';

  @override
  String pageErrorMess(Object snapshotError) {
    return 'Error in FutureBuilder $snapshotError';
  }

  @override
  String lectureLength(num lecturesLength) {
    String _temp0 = intl.Intl.pluralLogic(
      lecturesLength,
      locale: localeName,
      other: '$lecturesLength lectures',
      one: '1 lecture',
    );
    return '$_temp0';
  }

  @override
  String get recentLecture => 'Your 3 upcoming classes';

  @override
  String get lectureLoading => 'Loading schedule';

  @override
  String get todayLecturesNaN => 'No classes for today';

  @override
  String get lectureWigetHint =>
      'You\'re up to date! Use your free time or review your schedule.';

  @override
  String get daysShortMon => 'Mon';

  @override
  String get daysShortTue => 'Tue';

  @override
  String get daysShortWed => 'Wed';

  @override
  String get daysShortThu => 'Thu';

  @override
  String get daysShortFri => 'Fri';

  @override
  String get daysShortSat => 'Sat';

  @override
  String get daysShortSun => 'Sun';

  @override
  String get daysMon => 'monday';

  @override
  String get daysTue => 'tuesday';

  @override
  String get daysWed => 'wednesday';

  @override
  String get daysThu => 'thursday';

  @override
  String get daysFri => 'friday';

  @override
  String get selectedGroupsHeader => 'Selected Groups';

  @override
  String get changeGroupsButton => 'Change Groups';

  @override
  String get selectedGroupsLabel => 'Selected Groups';

  @override
  String get noDataAvailable => 'No data available';

  @override
  String get academicInfoHeader => 'Academic Information';

  @override
  String get lecturerInfoHeader => 'Lecturer Information';

  @override
  String get editButton => 'Edit';

  @override
  String studyYear(int year) {
    return 'Year $year';
  }

  @override
  String get studyModeLabel => 'Study Mode';

  @override
  String get groupTypeAuditorium => 'Auditorium';

  @override
  String get groupTypeClasses => 'Classes';

  @override
  String get groupTypeLabs => 'Laboratories';

  @override
  String get groupTypeOther => 'Other';

  @override
  String get pageTitleHome => 'Home';

  @override
  String get pageTitleLectures => 'Classes';

  @override
  String get pageTitleSettings => 'Settings';

  @override
  String get pageTitleNews => 'News';

  @override
  String get debugHeader => 'Debug';

  @override
  String get returnToLabel => 'Return to';

  @override
  String get welcomeScreenButton => 'Welcome screen';

  @override
  String get inputPageButton => 'Input page';

  @override
  String get professorLabel => 'Professor';

  @override
  String get groupLabel => 'Group';

  @override
  String get lengthLabel => 'Duration';

  @override
  String get additionalInformation => 'ADDITIONAL INFORMATION';

  @override
  String get notesLabel => 'Notes';

  @override
  String get emptyNotesLabel => 'Empty';

  @override
  String get newsSectionLabel => 'Recent news';

  @override
  String get feedbackHeader => 'Feedback and suggestions';

  @override
  String get sendFeedbackButton => 'Send feedback';

  @override
  String get feedbackPageHeadline => 'Your feedback matters to us!';

  @override
  String get feedbackPageDescription =>
      'The form will open in your browser so you can sign in securely.';

  @override
  String get feedbackFormOpenGenericError =>
      'Could not open the feedback form.';

  @override
  String feedbackFormOpenError(String error) {
    return 'Could not open the feedback form: $error';
  }

  @override
  String daysAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days ago',
      one: '1 day ago',
      zero: 'today',
    );
    return '$_temp0';
  }

  @override
  String get professorNaN => 'No professor';

  @override
  String get roomNaN => 'No room';

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
  String get details => 'Details';

  @override
  String get universityStructureLoading => 'Loading university structure...';

  @override
  String get noNews => 'No news';

  @override
  String get universityStructureEmpty =>
      'The university structure is empty. Are you connected to the internet?';

  @override
  String get noSpecialisationOption => 'No specialisation';

  @override
  String get noSpecialisationForField =>
      'No specialisation available for this field';

  @override
  String get pePageTitle => 'PE Enrollment';

  @override
  String get pePageDescription =>
      'Choose your physical education classes for this semester. Remember that enrollment happens periodically.';

  @override
  String get pePageButton => 'Go to enrollment';

  @override
  String get pePageUrlError => 'Could not open the enrollment page.';

  @override
  String get studentIdPageTitle => 'Student ID Card';

  @override
  String get studentIdPageDescription =>
      'Apply for or renew your student ID card through your university account. Remember that the card is valid for one semester.';

  @override
  String get studentIdPageButton => 'Go to application';

  @override
  String get studentIdPageUrlError => 'Could not open the student ID page.';

  @override
  String get virtualUniversityPageTitle => 'Virtual University';

  @override
  String get virtualUniversityPageDescription =>
      'Check your grades, personal information, and handle university matters through the Virtual University portal.';

  @override
  String get virtualUniversityPageButton => 'Open portal';

  @override
  String get virtualUniversityPageUrlError =>
      'Could not open the Virtual University portal.';

  @override
  String get degreeLevelLabel => 'Degree Level';

  @override
  String get degreeLevelEngineering => 'Engineering';

  @override
  String get degreeLevelMasters => 'Masters';

  @override
  String get unexpectedError => 'Oops! Something went wrong.';

  @override
  String get networkErrorDescription =>
      'Check your internet connection and try again.';

  @override
  String get announcementDismiss => 'Got it';

  @override
  String get announcementUpdate => 'Update';

  @override
  String get announcementSkip => 'Skip';

  @override
  String get appearanceHeader => 'Appearance';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System';

  @override
  String get appearanceHint => 'Choose the theme that suits you best';

  @override
  String get activeThemeLabel => 'Active theme: ';

  @override
  String get personalizationHeader => 'Personalization';

  @override
  String get languageHeader => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get languagePolish => 'Polish';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageUkrainian => 'Ukrainian';

  @override
  String get languageHint => 'Choose the application language';

  @override
  String get activeLanguageLabel => 'Active language: ';

  @override
  String get accentColorTitle => 'Accent Color';

  @override
  String get amoledModeTitle => 'AMOLED Black';

  @override
  String get amoledModeDesc => 'Pitch black background for dark mode';

  @override
  String get eventStyleTitle => 'Event Style';

  @override
  String get eventStyleCurrent => 'Default';

  @override
  String get eventStylePastel => 'Pastel';

  @override
  String get eventStyleVibrant => 'Vibrant';

  @override
  String get eventStyleMonochrome => 'Monochrome';

  @override
  String get aboutApp => 'About application';

  @override
  String get version => 'Version';

  @override
  String get createdBy => 'Created by';

  @override
  String get kniName => 'IT Science Club\nMaritime University of Szczecin';

  @override
  String get openSourceInfo => 'This app is open-source';

  @override
  String get githubRepo => 'Open repository on Github';

  @override
  String get couldNotOpenRepo => 'Could not open repository';

  @override
  String get appDescription =>
      'A clear and fast schedule with live preview. Created specifically for students of the Maritime University to help organize and track daily lectures.';

  @override
  String get debugReturnToWelcome => 'Return to Welcome Screen';

  @override
  String get debugModeUnlocked => 'Debug mode unlocked!';

  @override
  String debugTapsRemaining(int count) {
    return '$count more taps to unlock debug';
  }

  @override
  String get infoSection => 'Information';

  @override
  String get readMore => 'Read more';

  @override
  String get whatsNewTitle => 'What\'s new';

  @override
  String get whatsNewGotIt => 'Got it!';

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '${hours}h ${minutes}min';
  }

  @override
  String durationMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get roleSelectionTitle => 'How do you want to use PlanPM?';

  @override
  String get roleSelectionSubtitle =>
      'Choose the role that best describes your needs';

  @override
  String get roleStudentButton => 'I\'m a student';

  @override
  String get roleLecturerButton => 'I\'m a lecturer';

  @override
  String get lecturerSelectionTitle => 'Select lecturer';

  @override
  String get lecturerSelectionSubtitle => 'Enter name, surname or subject name';

  @override
  String get lecturerSearchNoResults => 'No results';

  @override
  String get lecturerLabel => 'Lecturer';

  @override
  String get roleSectionTitle => 'Role';

  @override
  String get roleStudentViewTitle => 'Student View';

  @override
  String get roleStudentViewSubtitle => 'Switch to student schedule';

  @override
  String get roleCurrentlyActive => 'Currently active';

  @override
  String get roleLecturerViewTitle => 'Lecturer View';

  @override
  String get roleLecturerViewSubtitle => 'Switch to manage classes';

  @override
  String get debugRoleSelector => 'Role Selector';

  @override
  String get debugClearCache => 'Clear cache';

  @override
  String get debugCacheCleared => 'Cache cleared';

  @override
  String get debugSevenDayMode => '7-day mode';

  @override
  String get newsLoading => 'Loading news';

  @override
  String get newsNoDataDescription =>
      'No new messages. Check back later for updates.';

  @override
  String get searchHint => 'Search...';
}
