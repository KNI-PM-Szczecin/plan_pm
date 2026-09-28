// Presety rozmiarów i wag czcionek zgodne z iOS HIG Dynamic Type (ustawienie "Large").
//
// AppTextSize  — rozmiary w punktach
// AppTextWeight — semantyczne aliasy FontWeight
//
// Użycie: Text('Hello', style: TextStyle(fontSize: AppTextSize.body, fontWeight: AppTextWeight.regular))
import 'package:flutter/material.dart';

class AppTextSize {
  AppTextSize._();

  static const double largeTitle = 34; // Large Title
  static const double title1     = 28; // Title 1
  static const double title2     = 22; // Title 2
  static const double title3     = 20; // Title 3
  static const double headline   = 17; // Headline — używaj z AppTextWeight.semibold
  static const double body       = 17; // Body
  static const double callout    = 16; // Callout
  static const double subhead    = 15; // Subhead
  static const double footnote   = 13; // Footnote
  static const double caption1   = 12; // Caption 1
  static const double caption2   = 11; // Caption 2
}

class AppTextWeight {
  AppTextWeight._();

  static const FontWeight regular  = FontWeight.w400;
  static const FontWeight medium   = FontWeight.w500;
  static const FontWeight semibold = FontWeight.w600;
  static const FontWeight bold     = FontWeight.w700;
}

/// Gotowe style Dynamic Type z design systemu (iOS 27 Flat): rozmiar,
/// interlinia i tracking każdej roli. Tracking jest częścią roli — nie gubić
/// go przy `copyWith`. Kolor dokładaj na miejscu (`.copyWith(color: …)`),
/// bo zależy od tła, na którym tekst leży.
class AppTextStyle {
  AppTextStyle._();

  static TextStyle _role(
    double size,
    double lineHeight,
    double tracking,
    FontWeight weight,
  ) => TextStyle(
    fontSize: size,
    height: lineHeight / size,
    letterSpacing: tracking,
    fontWeight: weight,
  );

  static final TextStyle largeTitle = _role(34, 41, 0.4, AppTextWeight.regular);
  static final TextStyle largeTitleEmphasized = _role(
    34,
    41,
    0.4,
    AppTextWeight.bold,
  );
  static final TextStyle title1 = _role(28, 34, 0.38, AppTextWeight.regular);
  static final TextStyle title1Emphasized = _role(
    28,
    34,
    0.38,
    AppTextWeight.bold,
  );
  static final TextStyle title2 = _role(22, 28, -0.26, AppTextWeight.regular);
  static final TextStyle title2Emphasized = _role(
    22,
    28,
    -0.26,
    AppTextWeight.bold,
  );
  static final TextStyle title3 = _role(20, 25, -0.45, AppTextWeight.regular);
  static final TextStyle title3Emphasized = _role(
    20,
    25,
    -0.45,
    AppTextWeight.semibold,
  );
  static final TextStyle headline = _role(
    17,
    22,
    -0.43,
    AppTextWeight.semibold,
  );
  static final TextStyle body = _role(17, 22, -0.43, AppTextWeight.regular);
  static final TextStyle bodyEmphasized = _role(
    17,
    22,
    -0.43,
    AppTextWeight.semibold,
  );
  static final TextStyle callout = _role(16, 21, -0.31, AppTextWeight.regular);
  static final TextStyle subheadline = _role(
    15,
    20,
    -0.23,
    AppTextWeight.regular,
  );
  static final TextStyle subheadlineEmphasized = _role(
    15,
    20,
    -0.23,
    AppTextWeight.semibold,
  );
  static final TextStyle footnote = _role(13, 18, -0.08, AppTextWeight.regular);
  static final TextStyle footnoteEmphasized = _role(
    13,
    18,
    -0.08,
    AppTextWeight.semibold,
  );
  static final TextStyle caption1 = _role(12, 16, 0, AppTextWeight.regular);
  static final TextStyle caption2 = _role(11, 13, 0.06, AppTextWeight.regular);
}
