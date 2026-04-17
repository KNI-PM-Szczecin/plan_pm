class AnnouncementModel {
  final String id;
  final String title;
  final String message;
  final String type; // 'info' | 'warning' | 'update'
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
