// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get welcomeTagline =>
      'A clear, fast class schedule with a live preview.';

  @override
  String get welcomeButton => 'Welcome to Plan PM';

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
  String get yearText => 'Year';

  @override
  String get dataNaN => 'No data';

  @override
  String get studySettings => 'Study Settings';

  @override
  String get skipButton => 'Skip';

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
  String get save => 'Save';

  @override
  String get todayDataNaN => 'No classes for today';

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
  String get previousWeek => 'Previous week';

  @override
  String get nextWeek => 'Next week';

  @override
  String get selectedGroupsHeader => 'Selected Groups';

  @override
  String get changeGroupsButton => 'Change Groups';

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
  String get groupTypeProject => 'Project';

  @override
  String get groupTypeSimulator => 'Simulator';

  @override
  String get groupTypeElective => 'Electives';

  @override
  String get groupTypeElectiveHint => 'You can select several';

  @override
  String get groupTypeOther => 'Other';

  @override
  String get groupsSectionHeader => 'Groups';

  @override
  String selectedCount(int count) {
    return 'Selected: $count';
  }

  @override
  String get groupNotSelected => 'Not selected';

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
  String get professorLabel => 'Professor';

  @override
  String get groupLabel => 'Group';

  @override
  String get lengthLabel => 'Duration';

  @override
  String get additionalInformation => 'Additional information';

  @override
  String get notesLabel => 'Notes';

  @override
  String get emptyNotesLabel => 'Empty';

  @override
  String get rectorHoursBadge => 'Rector\'s hours';

  @override
  String get rectorDayBadge => 'Rector\'s day';

  @override
  String get canceledClassBadge => 'Class canceled';

  @override
  String get newsSectionLabel => 'Recent news';

  @override
  String get feedbackHeader => 'Feedback and suggestions';

  @override
  String get sendFeedbackButton => 'Send feedback';

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
  String get details => 'Details';

  @override
  String get universityStructureLoading => 'Loading university structure...';

  @override
  String get noNews => 'No news';

  @override
  String get universityStructureEmptyTitle => 'No university data';

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
  String get studentIdPageTitle => 'Student ID Card';

  @override
  String get virtualUniversityPageTitle => 'Virtual University';

  @override
  String get degreeLevelLabel => 'Degree Level';

  @override
  String get degreeLevelEngineering => 'Engineer';

  @override
  String get degreeLevelMasters => 'Master';

  @override
  String get degreeLevelBachelor => 'Bachelor';

  @override
  String get unexpectedError => 'Oops! Something went wrong.';

  @override
  String get networkErrorDescription =>
      'Check your internet connection and try again.';

  @override
  String get retryButton => 'Try again';

  @override
  String get unavailableOptionsHint =>
      'Unavailable options are not offered for this field of study.';

  @override
  String get noGroupsAvailable => 'No groups available';

  @override
  String get noGroupsAvailableDescription =>
      'No schedule has been published for these settings. From the second year onwards classes are usually filed under a specialisation — check whether you picked the right one. You can also continue without groups and see the whole year\'s schedule.';

  @override
  String noGroupsAvailableSettings(String settings) {
    return 'Selected settings: $settings';
  }

  @override
  String get changeStudyDetails => 'Change study details';

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
  String get openSourceHeader => 'Open source';

  @override
  String get themeSystemHint => 'System follows your phone\'s settings.';

  @override
  String get themeHeader => 'Theme';

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
  String get debugModeUnlocked => 'You are now a developer';

  @override
  String debugTapsRemaining(int count) {
    return '$count more taps to become a developer';
  }

  @override
  String get debugModeDisable => 'Disable developer mode';

  @override
  String get debugModeDisabled => 'Developer mode disabled';

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
  String get roleStudentSubtitle => 'Schedule by field of study and group';

  @override
  String get roleLecturerSubtitle => 'Schedule by lecturer';

  @override
  String get nextButton => 'Next';

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
  String get roleViewingAsStudent =>
      'You are currently viewing the schedule as a student.';

  @override
  String get roleViewingAsLecturer =>
      'You are currently viewing the schedule as a lecturer.';

  @override
  String get roleLecturerViewTitle => 'Lecturer View';

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

  @override
  String get debugShowGdpr => 'Show GDPR consent screen';

  @override
  String get gdprTitle => 'Privacy & Data';

  @override
  String get gdprAccept => 'I understand and accept';

  @override
  String get gdprCard1Title => 'University data';

  @override
  String get gdprCard1Body =>
      'Plan PM displays names, academic titles and schedules of lecturers at the Maritime University of Szczecin. This data is sourced from publicly accessible university systems.';

  @override
  String get gdprCard2Title => 'GDPR';

  @override
  String get gdprCard2Body =>
      'This data constitutes personal data under the General Data Protection Regulation (GDPR).';

  @override
  String get gdprCard3Title => 'Your consent';

  @override
  String get gdprCard3Body =>
      'By using the app, you confirm that you understand the purpose for which this data is displayed and consent to its use.';

  @override
  String get gdprRevoke =>
      'You can withdraw your consent at any time in settings.';
}
