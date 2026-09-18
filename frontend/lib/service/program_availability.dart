// Łączy drzewko struktury uczelni (v_academic_structure) z planami, które
// realnie mają grupy (v_unique_groups), i wystawia z tego listę istniejących
// kombinacji studiów.
//
// Po co: plan zajęć od 2. roku jest wystawiany pod nazwą SPECJALIZACJI, a nie
// kierunku, więc formularz zbudowany z samego drzewka pozwalał złożyć
// kombinację, dla której w bazie nie ma ani jednej grupy (patrz zgłoszenia z
// 09.2026). Tutaj liczymy zbiór kombinacji, które istnieją, a [InputPage]
// kaskaduje wyłącznie po nich.
//
// Dopasowanie idzie po nazwie, bo to jedyny wspólny klucz obu źródeł:
// `program_name` planu równa się nazwie specjalizacji albo nazwie kierunku.
// Normalizujemy białe znaki i wielkość liter, a końcówkę językową ("ang.")
// odcinamy do osobnego pola — plan angielskojęzyczny to ta sama specjalizacja,
// tylko inna ścieżka, i student musi móc wybrać którą chce.

/// Znaczniki obcojęzycznej ścieżki, jakie uczelnia dokleja do nazwy toku.
/// "POL"/"pol." celowo nie ma na liście — polski jest domyślny i nie tworzy
/// osobnego wariantu do wyboru.
const Set<String> _languageTokens = {"ang", "ang.", "eng", "eng."};

/// Zwija białe znaki (także twardą spację) i sprowadza do lowercase.
String normalizeProgramName(String value) {
  final collapsed = value
      .replaceAll("\u00a0", " ")
      .split(RegExp(r"\s+"))
      .where((part) => part.isNotEmpty)
      .join(" ");
  return collapsed.toLowerCase();
}

/// Rozdziela "Transport Morski ang." na nazwę bazową i znacznik języka.
({String base, String? language}) splitLanguageSuffix(String programName) {
  final parts = programName
      .replaceAll("\u00a0", " ")
      .split(RegExp(r"\s+"))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.length > 1 && _languageTokens.contains(parts.last.toLowerCase())) {
    return (base: parts.sublist(0, parts.length - 1).join(" "), language: parts.last);
  }
  return (base: parts.join(" "), language: null);
}

/// Wiersz drzewka struktury (jeden rekord v_academic_structure).
class StructureEntry {
  const StructureEntry({
    required this.faculty,
    required this.degreeCourse,
    this.specialisation,
  });

  final String faculty;
  final String degreeCourse;
  final String? specialisation;
}

/// Plan, który ma w bazie przynajmniej jedną grupę.
class ProgramRow {
  const ProgramRow({
    required this.programName,
    required this.year,
    required this.programType,
    required this.degreeLevel,
  });

  final String programName;
  final int year;
  final String programType;
  final String degreeLevel;
}

/// Jedna kombinacja, którą wolno wybrać w formularzu.
class ProgramOption {
  const ProgramOption({
    required this.faculty,
    required this.degreeCourse,
    required this.specialisation,
    required this.year,
    required this.programType,
    required this.degreeLevel,
    required this.programName,
    required this.language,
  });

  final String faculty;
  final String degreeCourse;

  /// null = plan wystawiony pod samym kierunkiem (zwykle 1. rok).
  final String? specialisation;

  final int year;
  final String programType;
  final String degreeLevel;

  /// Dokładna nazwa z bazy — to ona leci do `.eq("program_name", …)`.
  final String programName;

  /// Znacznik ścieżki językowej ("ang.") albo null dla domyślnej.
  final String? language;

  /// Klucz odróżniający pozycje na liście specjalizacji.
  String get specialisationKey => "${specialisation ?? ""}|${language ?? ""}";
}

/// Zbiór realnie istniejących kombinacji + nazwy planów, których nie dało się
/// przypiąć do struktury (patrz [unmatchedProgramNames] — to sygnał, że nazwa
/// na stronie uczelni się rozjechała i ktoś zniknął z aplikacji).
class ProgramAvailability {
  ProgramAvailability._(this.options, this.unmatchedProgramNames);

  final List<ProgramOption> options;
  final List<String> unmatchedProgramNames;

  factory ProgramAvailability.from({
    required List<StructureEntry> structure,
    required List<ProgramRow> programs,
  }) {
    // Specjalizacja wygrywa z kierunkiem: jeśli nazwa planu pasuje do obu
    // (zdarza się, np. "Hydrografia" jest i kierunkiem, i specjalizacją),
    // chcemy wszystkie pasujące węzły — student wybiera swój kierunek sam.
    final Map<String, List<StructureEntry>> specNodes = {};
    final Map<String, List<StructureEntry>> courseNodes = {};
    for (final entry in structure) {
      courseNodes
          .putIfAbsent(normalizeProgramName(entry.degreeCourse), () => [])
          .add(entry);
      final spec = entry.specialisation;
      if (spec != null && spec.isNotEmpty) {
        specNodes.putIfAbsent(normalizeProgramName(spec), () => []).add(entry);
      }
    }

    final List<ProgramOption> options = [];
    final Set<String> unmatched = {};

    for (final program in programs) {
      final split = splitLanguageSuffix(program.programName);
      final key = normalizeProgramName(split.base);

      final specMatches = specNodes[key] ?? const <StructureEntry>[];
      final courseMatches = courseNodes[key] ?? const <StructureEntry>[];
      if (specMatches.isEmpty && courseMatches.isEmpty) {
        unmatched.add(program.programName);
        continue;
      }

      final seen = <String>{};
      for (final node in specMatches) {
        if (!seen.add("${node.faculty}|${node.degreeCourse}")) continue;
        options.add(
          ProgramOption(
            faculty: node.faculty,
            degreeCourse: node.degreeCourse,
            specialisation: node.specialisation,
            year: program.year,
            programType: program.programType,
            degreeLevel: program.degreeLevel,
            programName: program.programName,
            language: split.language,
          ),
        );
      }
      for (final node in courseMatches) {
        if (!seen.add("${node.faculty}|${node.degreeCourse}")) continue;
        options.add(
          ProgramOption(
            faculty: node.faculty,
            degreeCourse: node.degreeCourse,
            specialisation: null,
            year: program.year,
            programType: program.programType,
            degreeLevel: program.degreeLevel,
            programName: program.programName,
            language: split.language,
          ),
        );
      }
    }

    final unmatchedSorted = unmatched.toList()..sort();
    return ProgramAvailability._(List.unmodifiable(options), unmatchedSorted);
  }

  bool get isEmpty => options.isEmpty;

  /// Kombinacje pasujące do już dokonanych wyborów. Każdy argument null =
  /// wymiar jeszcze nie wybrany, więc nie zawęża.
  List<ProgramOption> filter({
    String? faculty,
    String? degreeCourse,
    String? specialisationKey,
    int? year,
    String? programType,
    String? degreeLevel,
  }) {
    return options.where((o) {
      if (faculty != null && o.faculty != faculty) return false;
      if (degreeCourse != null && o.degreeCourse != degreeCourse) return false;
      if (specialisationKey != null && o.specialisationKey != specialisationKey) {
        return false;
      }
      if (year != null && o.year != year) return false;
      if (programType != null && o.programType != programType) return false;
      if (degreeLevel != null && o.degreeLevel != degreeLevel) return false;
      return true;
    }).toList();
  }

  List<String> faculties() {
    final set = options.map((o) => o.faculty).toSet().toList()..sort();
    return set;
  }

  List<String> degreeCourses(String faculty) {
    final set = filter(faculty: faculty).map((o) => o.degreeCourse).toSet().toList()
      ..sort();
    return set;
  }

  /// Pozycje listy specjalizacji dla danego kierunku i (opcjonalnie) już
  /// wybranego roku/trybu/stopnia. Pozycja ze specialisation == null to
  /// "brak specjalizacji" — pojawia się tylko gdy plan pod samym kierunkiem
  /// naprawdę istnieje.
  List<ProgramOption> specialisationChoices({
    required String faculty,
    required String degreeCourse,
    int? year,
    String? programType,
    String? degreeLevel,
  }) {
    final matching = filter(
      faculty: faculty,
      degreeCourse: degreeCourse,
      year: year,
      programType: programType,
      degreeLevel: degreeLevel,
    );
    final Map<String, ProgramOption> byKey = {};
    for (final option in matching) {
      byKey.putIfAbsent(option.specialisationKey, () => option);
    }
    final list = byKey.values.toList()
      ..sort((a, b) {
        // "brak specjalizacji" zawsze na górze, reszta alfabetycznie.
        if (a.specialisation == null) return -1;
        if (b.specialisation == null) return 1;
        final byName = a.specialisation!.compareTo(b.specialisation!);
        if (byName != 0) return byName;
        return (a.language ?? "").compareTo(b.language ?? "");
      });
    return list;
  }

  Set<int> years({
    required String faculty,
    required String degreeCourse,
    String? specialisationKey,
    String? programType,
    String? degreeLevel,
  }) {
    return filter(
      faculty: faculty,
      degreeCourse: degreeCourse,
      specialisationKey: specialisationKey,
      programType: programType,
      degreeLevel: degreeLevel,
    ).map((o) => o.year).toSet();
  }

  Set<String> degreeLevels({
    required String faculty,
    required String degreeCourse,
    String? specialisationKey,
    int? year,
    String? programType,
  }) {
    return filter(
      faculty: faculty,
      degreeCourse: degreeCourse,
      specialisationKey: specialisationKey,
      year: year,
      programType: programType,
    ).map((o) => o.degreeLevel).toSet();
  }

  Set<String> programTypes({
    required String faculty,
    required String degreeCourse,
    String? specialisationKey,
    int? year,
    String? degreeLevel,
  }) {
    return filter(
      faculty: faculty,
      degreeCourse: degreeCourse,
      specialisationKey: specialisationKey,
      year: year,
      degreeLevel: degreeLevel,
    ).map((o) => o.programType).toSet();
  }

  /// Dokładnie jedna kombinacja albo null, gdy wybór jest jeszcze niepełny
  /// lub (czego nie powinno być) prowadzi donikąd.
  ProgramOption? resolve({
    required String faculty,
    required String degreeCourse,
    required String specialisationKey,
    required int year,
    required String programType,
    required String degreeLevel,
  }) {
    final matches = filter(
      faculty: faculty,
      degreeCourse: degreeCourse,
      specialisationKey: specialisationKey,
      year: year,
      programType: programType,
      degreeLevel: degreeLevel,
    );
    return matches.isEmpty ? null : matches.first;
  }
}
