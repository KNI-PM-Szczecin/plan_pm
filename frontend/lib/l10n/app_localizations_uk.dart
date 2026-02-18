// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Ukrainian (`uk`).
class AppLocalizationsUk extends AppLocalizations {
  AppLocalizationsUk([String locale = 'uk']) : super(locale);

  @override
  String get stage1Title => '';

  @override
  String get stage1Button => 'Ласкаво просимо до Plan PM';

  @override
  String get stage2Title =>
      'Перегляньте всі заняття у зручному тижневому розкладі.';

  @override
  String get stage2Button => 'Далі';

  @override
  String get stage3Title =>
      'Легко знаходьте свої аудиторії завдяки детальній інформації про місцезнаходження.';

  @override
  String get stage3Button => 'Далі';

  @override
  String get stage4Title =>
      'Отримуйте нагадування перед кожним заняттям, щоб ніколи їх не пропустити.';

  @override
  String get stage4Button => 'Розпочати';

  @override
  String get welcomePageSelectionText => 'Повернутися до WelcomeScreen';

  @override
  String get inputPageSelectionText => 'Повернутися до InputPage';

  @override
  String get inputPageLabel => 'Ваші академічні дані';

  @override
  String get facultyLabel => 'Факультет';

  @override
  String get facultyHintText => 'Виберіть факультет';

  @override
  String get fieldLabel => 'Напрямок навчання';

  @override
  String get fieldHintText => 'Виберіть напрямок навчання';

  @override
  String get yearLabel => 'Поточний рік';

  @override
  String get specialisationLabel => 'Спеціалізація';

  @override
  String get specialisationHintText => 'Виберіть спеціалізацію';

  @override
  String get typeLabel => 'Форма навчання';

  @override
  String get campusButton => 'Стаціонарна';

  @override
  String get extramuralButton => 'Заочна';

  @override
  String get continueButton => 'Продовжити';

  @override
  String get homePageLabel => 'Дані студента:';

  @override
  String get facultyText => 'Факультет';

  @override
  String get fieldText => 'Напрямок';

  @override
  String get specialisationText => 'Спеціалізація';

  @override
  String get yearText => 'Рік';

  @override
  String get typeText => 'Форма навчання';

  @override
  String get dataNaN => 'Немає даних';

  @override
  String get studySettings => 'Налаштування навчання';

  @override
  String get skipButton => 'Пропустити';

  @override
  String get fullTimeStudy => 'Стаціонарна';

  @override
  String get partTimeStudy => 'Нестаціонарна';

  @override
  String get groupSelection => 'Вибір групи';

  @override
  String get groupSelectionHint =>
      'Виберіть свій факультет, напрямок і форму, щоб персоналізувати розклад занять';

  @override
  String get groupLoading => 'Завантаження груп...';

  @override
  String get groupSettings => 'Налаштування навчання';

  @override
  String get groupSelectionHintAfterLoad =>
      'На основі ваших налаштувань навчання ми завантажили доступні групи. Виберіть одну або декілька, щоб відстежувати різні розклади.';

  @override
  String get save => 'Зберегти';

  @override
  String get todayDataNaN => 'Немає занять на сьогодні';

  @override
  String pageErrorMess(Object snapshotError) {
    return 'Помилка у FutureBuilder $snapshotError';
  }

  @override
  String lectureLength(num lecturesLength) {
    String _temp0 = intl.Intl.pluralLogic(
      lecturesLength,
      locale: localeName,
      other: '$lecturesLength заняття',
      many: '$lecturesLength занять',
      few: '$lecturesLength заняття',
      one: '1 заняття',
    );
    return '$_temp0';
  }

  @override
  String get recentLecture => 'Ваше найближче заняття';

  @override
  String get lectureLoading => 'Завантаження розкладу';

  @override
  String get todayLecturesNaN => 'Немає занять на сьогодні';

  @override
  String get lectureWigetHint =>
      'Ви в курсі! Скористайтеся вільним часом або перегляньте свій розклад.';

  @override
  String get daysShortMon => 'Пн';

  @override
  String get daysShortTue => 'Вт';

  @override
  String get daysShortWed => 'Ср';

  @override
  String get daysShortThu => 'Чт';

  @override
  String get daysShortFri => 'Пт';

  @override
  String get daysMon => 'понеділок';

  @override
  String get daysTue => 'вівторок';

  @override
  String get daysWed => 'середа';

  @override
  String get daysThu => 'четвер';

  @override
  String get daysFri => 'п\'ятниця';

  @override
  String get selectedGroupsHeader => 'Вибрані групи';

  @override
  String get changeGroupsButton => 'Змінити групи';

  @override
  String get selectedGroupsLabel => 'Вибрані групи';

  @override
  String get noDataAvailable => 'Дані недоступні';

  @override
  String get academicInfoHeader => 'Академічна інформація';

  @override
  String get editButton => 'Редагувати';

  @override
  String studyYear(int year) {
    final intl.NumberFormat yearNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String yearString = yearNumberFormat.format(year);

    String _temp0 = intl.Intl.pluralLogic(
      year,
      locale: localeName,
      other: '$yearString року',
      many: '$yearString років',
      few: '$yearString роки',
      one: '1 рік',
    );
    return '$_temp0';
  }

  @override
  String get studyModeLabel => 'Форма навчання';

  @override
  String get groupTypeAuditorium => 'Аудиторія';

  @override
  String get groupTypeClasses => 'Практичні заняття';

  @override
  String get groupTypeLabs => 'Лабораторні роботи';

  @override
  String get groupTypeOther => 'Інше';

  @override
  String get pageTitleHome => 'Головна';

  @override
  String get pageTitleLectures => 'Заняття';

  @override
  String get pageTitleSettings => 'Налаштування';

  @override
  String get pageTitleNews => 'Новини';

  @override
  String get debugHeader => 'Налагодження';

  @override
  String get returnToLabel => 'Повернутися до';

  @override
  String get welcomeScreenButton => 'Екран привітання';

  @override
  String get inputPageButton => 'Екран вводу даних';

  @override
  String get professorLabel => 'Професор';

  @override
  String get groupLabel => 'Група';

  @override
  String get lengthLabel => 'Тривалість';

  @override
  String get notesLabel => 'Нотатки';

  @override
  String get emptyNotesLabel => 'Пусто';

  @override
  String get newsSectionLabel => 'Останні новини';

  @override
  String get feedbackHeader => 'Відгуки та пропозиції';

  @override
  String get sendFeedbackButton => 'Надіслати відгук';

  @override
  String daysAgo(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days дня тому',
      many: '$days днів тому',
      few: '$days дні тому',
      one: '1 день тому',
      zero: 'сьогодні',
    );
    return '$_temp0';
  }

  @override
  String get professorNaN => 'Немає професора';

  @override
  String get roomNaN => 'Немає аудиторії';

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
  String get details => 'Деталі';

  @override
  String get universityStructureLoading =>
      'Завантаження структури університету';

  @override
  String get noNews => 'Немає новин';

  @override
  String get universityStructureEmpty =>
      'Структура університету порожня. Ви підключені до інтернету?';

  @override
  String get noSpecialisationForField =>
      'Немає спеціалізацій для цього напрямку';

  @override
  String get degreeLevelLabel => 'Ступінь навчання';

  @override
  String get degreeLevelEngineering => 'Інженерний';

  @override
  String get degreeLevelMasters => 'Магістерський';

  @override
  String get unexpectedError => 'Упс! Щось пішло не так.';
}
