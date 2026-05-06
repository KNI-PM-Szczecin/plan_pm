/// Ogłoszenie systemowe pobierane z Supabase.
///
/// Ogłoszenia to wiadomości push od administratorów — informują użytkowników
/// o przerwach technicznych, przełomowych zmianach lub wymaganych aktualizacjach.
/// NIE są tym samym co newsy: ogłoszenie przerywa użytkownika dialogiem przy
/// starcie apki, newsy pojawiają się biernie w zakładce Aktualności.
///
/// Przepływ:
///   1. [BackendService.fetchAnnouncement] pobiera najnowsze aktywne ogłoszenie
///   2. [main.dart] (appInitialization) sprawdza czy ogłoszenie jest nowe i
///      wyświetla [AnnouncementDialog]
///
/// Pole [type] decyduje o wyglądzie dialogu i dostępnych akcjach:
///   - 'info'    → wiadomość informacyjna, tylko przycisk zamknięcia
///   - 'warning' → ostrzeżenie, tylko przycisk zamknięcia
///   - 'update'  → prośba o aktualizację — dialog pokazuje przycisk prowadzący do [storeUrl]
class AnnouncementModel {
  final String id;
  final String title;
  final String message;
  final String type; // 'info' | 'warning' | 'update'

  /// Bezpośredni link do App Store / Play Store.
  /// Relevantny tylko gdy [type] == 'update'.
  final String? storeUrl;

  const AnnouncementModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.storeUrl,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) =>
      AnnouncementModel(
        id: json['id'] as String,
        title: json['title'] as String,
        message: json['message'] as String,
        type: json['type'] as String,
        storeUrl: json['store_url'] as String?,
      );
}
