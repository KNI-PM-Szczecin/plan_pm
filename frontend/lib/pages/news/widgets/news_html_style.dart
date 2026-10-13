// Style HTML treści wiadomości (pełny widok, makieta 6a): akapity body
// w kolorze drugorzędnym, nagłówki jako headline, pogrubienia i linki
// wyróżnione. Funkcja, nie stała mapa — kolory zależą od motywu.
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:plan_pm/global/theme/colors.dart';

Map<String, Style> newsHtmlStyle() {
  final heading = Style(
    fontSize: FontSize(17),
    fontWeight: FontWeight.w600,
    lineHeight: const LineHeight(22 / 17),
    color: AppColor.onBackground,
    margin: Margins.only(top: 16, bottom: 4),
  );
  return {
    "body": Style(
      margin: Margins.zero,
      padding: HtmlPaddings.zero,
      fontSize: FontSize(17),
      lineHeight: const LineHeight(22 / 17),
      letterSpacing: -0.43,
      color: AppColor.labelSecondary,
    ),
    "p": Style(margin: Margins.only(bottom: 12), padding: HtmlPaddings.zero),
    "strong": Style(fontWeight: FontWeight.w600, color: AppColor.onBackground),
    "b": Style(fontWeight: FontWeight.w600, color: AppColor.onBackground),
    // Kursywa SF Pro na treści 17 pt wygląda ciężko — wyróżniamy kolorem
    // (pełny zamiast drugorzędnego), bez pochylenia i bez pogrubienia.
    "em": Style(fontStyle: FontStyle.normal, color: AppColor.onBackground),
    "i": Style(fontStyle: FontStyle.normal, color: AppColor.onBackground),
    "a": Style(color: AppColor.primary, textDecoration: TextDecoration.none),
    "h1": heading,
    "h2": heading,
    "h3": heading,
    "h4": heading,
  };
}
