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
  String get recentLecture => 'Future classes';

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
  String get editButton => 'Edit';

  @override
  String studyYear(int year) {
    final intl.NumberFormat yearNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String yearString = yearNumberFormat.format(year);

    String _temp0 = intl.Intl.pluralLogic(
      year,
      locale: localeName,
      other: '$yearString years',
      one: '1 year',
    );
    return '$_temp0';
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
  String get noSpecialisationForField =>
      'No specialisation available for this field';

  @override
  String get degreeLevelLabel => 'Degree Level';

  @override
  String get degreeLevelEngineering => 'Engineering';

  @override
  String get degreeLevelMasters => 'Masters';

  @override
  String get unexpectedError => 'Oops! Something went wrong.';
}
