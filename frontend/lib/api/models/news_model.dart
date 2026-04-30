/// Pojedynczy news pobierany z Supabase i cachowany w SQLite.
///
/// Newsy to ogłoszenia uczelniane wyświetlane w zakładce Aktualności.
/// W przeciwieństwie do [AnnouncementModel] nie przerywają użytkownika przy
/// starcie — są przeglądane dobrowolnie.
///
/// Pełny cykl życia:
///   1. [BackendService.fetchNews] pobiera wszystkie newsy z Supabase
///   2. [CacheService.syncNews] zapisuje je do lokalnego SQLite
///   3. [DatabaseService.fetchNews] odczytuje je do wyświetlenia
///   4. [NewsBuilder] renderuje listę; [FullNewsPage] pokazuje widok szczegółowy
class NewsModel {
  final String id;
  final DateTime createdAt;
  final String? imageUrl;
  final String title;

  /// Pełna treść newsa (HTML lub plain text).
  /// Renderowana w [FullNewsPage] przez web view / HTML renderer.
  final String content;

  /// Kategoria wizualna (np. 'info', 'warning', 'event').
  /// Używana przez [NewsCard] do wyboru koloru badge'a.
  final String messageType;

  NewsModel({
    required this.id,
    required this.createdAt,
    required this.title,
    required this.content,
    required this.messageType,
    this.imageUrl,
  });

  /// Skraca [content] do 120 znaków dla czytelnego debugowania.
  @override
  String toString() {
    final thumb = imageUrl == null ? 'null' : imageUrl!;
    final contentPreview = content.length > 120
        ? '${content.substring(0, 120)}...'
        : content;
    return 'NewsModel(id: $id, createdAt: ${createdAt.toIso8601String()}, thumbnail: $thumb, title: $title, messageType: $messageType, content: $contentPreview)';
  }
}
