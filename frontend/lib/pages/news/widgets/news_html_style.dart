// Style HTML wspólne dla podglądu i pełnego widoku wiadomości.
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:plan_pm/global/theme/colors.dart';

Map<String, Style> newsHtmlStyle = {
  "body": Style(margin: Margins.zero, padding: HtmlPaddings.zero),
  "p": Style(
    margin: Margins.zero,
    padding: HtmlPaddings.zero,
    fontSize: FontSize.medium,
    color: AppColor.onSurfaceVariant,
  ),
  "a": Style(color: Colors.blue, textDecoration: TextDecoration.underline),
  "h1": Style(fontSize: FontSize.xxLarge, fontWeight: FontWeight.bold),
};
