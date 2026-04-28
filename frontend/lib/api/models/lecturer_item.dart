class LecturerItem {
  final String id;
  final String name;
  final String? title;

  const LecturerItem({required this.id, required this.name, this.title});

  String get displayName =>
      [title, name].where((s) => s != null && s.isNotEmpty).join(' ');

  factory LecturerItem.fromJson(Map<String, dynamic> json) {
    return LecturerItem(
      id: json['id'].toString(),
      name: (json['fullName'] as String?)?.trim() ?? '',
      title: (json['title'] as String?)?.trim(),
    );
  }

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name.substring(0, name.length.clamp(0, 2)).toUpperCase();
  }
}
