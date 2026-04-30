/// Uproszczona reprezentacja wykładowcy zwracana przez wyszukiwarkę.
///
/// Używana wyłącznie podczas onboardingu wykładowcy — gdy użytkownik wybierze
/// "Jestem wykładowcą", apka pobiera wszystkich nauczycieli i wyświetla ich
/// w [LecturerSelectionPage] jako przeszukiwalną listę [LecturerItem]ów.
/// Po wyborze wykładowcy jego [id], [name] i [title] są zapisywane do
/// SharedPreferences i ładowane do statycznej klasy [Lecturer] przy kolejnym
/// uruchomieniu.
///
/// Model jest celowo minimalistyczny — zawiera tylko to, czego potrzebuje UI
/// do wyboru (wyświetlanie imienia, inicjały awatara). Pełny plan zajęć jest
/// pobierany osobno przez [BackendService._fetchLecturesForLecturer] przy użyciu [id].
///
/// Używany w:
///   - [BackendService.fetchTeachers] — buduje listę z Supabase
///   - [LecturerSelectionPage] — wyświetla i filtruje listę
///   - [LecturerTile] — renderuje pojedynczy wiersz na liście
///   - [RoleSelectionPage] / [RoleInfo] — przekazuje wybrany element przez
///     callback onContinue do zmiany trybu
///
class LecturerItem {
  final String id;
  final String name;

  /// Tytuł naukowy (np. "dr", "mgr inż."). Null jeśli nie ustawiony w bazie.
  final String? title;

  const LecturerItem({required this.id, required this.name, this.title});

  /// Pełne imię z tytułem, np. "dr Jan Kowalski".
  /// Pomija tytuł jeśli jest null lub pusty.
  String get displayName =>
      [title, name].where((s) => s != null && s.isNotEmpty).join(' ');

  factory LecturerItem.fromJson(Map<String, dynamic> json) {
    return LecturerItem(
      id: json['id'].toString(),
      name: (json['fullName'] as String?)?.trim() ?? '',
      title: (json['title'] as String?)?.trim(),
    );
  }

  /// Dwuliterowe inicjały z pierwszego i ostatniego słowa [name].
  /// Fallback do pierwszych 1–2 znaków gdy imię jest jednowyrazowe.
  /// Używane przez [LecturerTile] do renderowania kółka z awatarem.
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.substring(0, name.length.clamp(0, 2)).toUpperCase();
  }
}
