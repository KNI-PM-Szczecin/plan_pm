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
