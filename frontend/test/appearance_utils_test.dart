import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plan_pm/global/notifiers/notifiers.dart';
import 'package:plan_pm/global/theme/colors.dart';
import 'package:plan_pm/pages/settings/utils/appearance_utils.dart';

void main() {
  group('getAccentColorValue', () {
    test('returns light theme accent colors', () {
      final expected = <AppAccentColor, Color>{
        AppAccentColor.blue: ColorThemes.lightPrimary,
        AppAccentColor.green: const Color(0xFF10B981),
        AppAccentColor.purple: const Color(0xFF8B5CF6),
        AppAccentColor.orange: const Color(0xFFF59E0B),
        AppAccentColor.red: const Color(0xFFEF4444),
        AppAccentColor.pink: const Color(0xFFEC4899),
      };

      for (final entry in expected.entries) {
        expect(
          getAccentColorValue(entry.key, Brightness.light),
          entry.value,
          reason: entry.key.name,
        );
      }
    });

    test('returns dark theme accent colors', () {
      final expected = <AppAccentColor, Color>{
        AppAccentColor.blue: ColorThemes.darkPrimary,
        AppAccentColor.green: const Color(0xFF34D399),
        AppAccentColor.purple: const Color(0xFFA855F7),
        AppAccentColor.orange: const Color(0xFFFBBF24),
        AppAccentColor.red: const Color(0xFFF87171),
        AppAccentColor.pink: const Color(0xFFF472B6),
      };

      for (final entry in expected.entries) {
        expect(
          getAccentColorValue(entry.key, Brightness.dark),
          entry.value,
          reason: entry.key.name,
        );
      }
    });
  });
}
