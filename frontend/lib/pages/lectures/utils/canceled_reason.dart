enum CanceledReason {
  rectorHours,
  rectorDay,
  canceled
}

/// Determines the canceled/rector status of a lecture from its `notes` field.
///
/// Single source of truth shared by the in-app lecture card
/// (`lecture.dart::_determineStatus`) and the home-screen widget bridge
/// (`widget_service.dart`), so both detect the state identically.
CanceledReason? canceledReasonFromNotes(String? notes) {
  final n = notes?.toLowerCase() ?? '';
  if (n.contains('godziny rektorskie')) return CanceledReason.rectorHours;
  if (n.contains('dzień rektorski')) return CanceledReason.rectorDay;
  if (n.contains('zajęcia odwołane')) return CanceledReason.canceled;
  return null;
}
