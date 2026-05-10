import 'package:flutter_test/flutter_test.dart';
import 'package:plan_pm/l10n/app_localizations_en.dart';
import 'package:plan_pm/pages/lectures/utils/lecture_utils.dart';

void main() {
  group('computeLectureProgress', () {
    test('returns zero progress before lecture start', () {
      final result = computeLectureProgress(
        '08:00',
        '09:30',
        DateTime(2026, 3, 23, 7, 59),
      );

      expect(result.progress, 0.0);
      expect(result.isInProgress, isFalse);
    });

    test('marks lecture as in progress at exact start time', () {
      final result = computeLectureProgress(
        '08:00',
        '09:30',
        DateTime(2026, 3, 23, 8),
      );

      expect(result.progress, 0.0);
      expect(result.isInProgress, isTrue);
    });

    test('calculates proportional progress during lecture', () {
      final result = computeLectureProgress(
        '08:00',
        '09:30',
        DateTime(2026, 3, 23, 8, 45),
      );

      expect(result.progress, closeTo(0.5, 0.001));
      expect(result.isInProgress, isTrue);
    });

    test('marks lecture as in progress at exact end time', () {
      final result = computeLectureProgress(
        '08:00',
        '09:30',
        DateTime(2026, 3, 23, 9, 30),
      );

      expect(result.progress, 1.0);
      expect(result.isInProgress, isTrue);
    });

    test('returns full progress after lecture end', () {
      final result = computeLectureProgress(
        '08:00',
        '09:30',
        DateTime(2026, 3, 23, 9, 31),
      );

      expect(result.progress, 1.0);
      expect(result.isInProgress, isFalse);
    });

    test('handles zero duration as not in progress', () {
      final result = computeLectureProgress(
        '08:00',
        '08:00',
        DateTime(2026, 3, 23, 8),
      );

      expect(result.progress, 0.0);
      expect(result.isInProgress, isFalse);
    });
  });

  group('formatDuration', () {
    final l10n = AppLocalizationsEn();

    test('formats minutes below an hour', () {
      expect(formatDuration('45 min', l10n), '45 min');
    });

    test('formats hours and minutes', () {
      expect(formatDuration('90 min', l10n), '1h 30min');
    });

    test('trims supported minute input', () {
      expect(formatDuration(' 75 min ', l10n), '1h 15min');
    });

    test('returns raw value for unsupported format', () {
      expect(formatDuration('1h 30min', l10n), '1h 30min');
    });
  });

  group('longToShort', () {
    test('extracts group code before first slash', () {
      expect(longToShort('L01/WI-S-AI-N/2024'), 'L01');
    });

    test('extracts multiple comma separated group codes', () {
      expect(longToShort('L01/WI-S-AI-N/2024, L02/WI-S-AI-N/2024'), 'L01, L02');
    });

    test('deduplicates group codes while preserving order', () {
      expect(
        longToShort('L01/WI-S-AI-N/2024,L01/WI-S-AI-S/2024,L02'),
        'L01, L02',
      );
    });

    test('keeps already short group codes readable', () {
      expect(longToShort('L01,L02'), 'L01, L02');
    });

    test('ignores empty pieces', () {
      expect(longToShort('L01,, L02/ABC'), 'L01, L02');
      expect(longToShort(''), '');
    });
  });
}
