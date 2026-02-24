class AppTime {
  // Mocked time: 30th January 2026, 07:45
  // ignore: avoid_init_to_null
  static DateTime? _mockTimer = /*DateTime(2026, 1, 30, 7, 45)*/ null;

  static DateTime now() {
    if (_mockTimer != null) {
      return _mockTimer!;
    }
    return DateTime.now();
  }

  static void setMockTime(DateTime time) {
    _mockTimer = time;
  }

  static void clearMockTime() {
    _mockTimer = null;
  }
}
