class NewsModel {
  final String id;
  final DateTime createdAt;
  final String? imageUrl;
  final String title;
  final String content;
  final String messageType;

  NewsModel({
    required this.id,
    required this.createdAt,
    required this.title,
    required this.content,
    required this.messageType,
    this.imageUrl,
  });

  @override
  String toString() {
    final thumb = imageUrl == null ? 'null' : imageUrl!;
    final contentPreview = content.length > 120
        ? '${content.substring(0, 120)}...'
        : content;
    return 'NewsModel(id: $id, createdAt: ${createdAt.toIso8601String()}, thumbnail: $thumb, title: $title, messageType: $messageType, content: $contentPreview)';
  }
}
