// Nagłówek ekranu bez paska nawigacji (onboarding, puste stany): grafika,
// wyśrodkowany tytuł i podtytuł. Tekst ma ograniczoną szerokość, żeby łamał
// się w zwartą kolumnę jak w makietach, a nie rozlewał na cały ekran.
import 'package:flutter/material.dart';
import 'package:plan_pm/global/theme/colors.dart';
import 'package:plan_pm/global/theme/typography.dart';

class AppScreenHeader extends StatelessWidget {
  const AppScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.titleStyle,
    this.leadingSpacing = 24,
    this.maxTextWidth = 300,
  });

  final String title;
  final String? subtitle;

  /// Grafika nad tytułem, np. [AppIconTile] albo [AppHeroIcon].
  final Widget? leading;

  /// Domyślnie Title 1 Emphasized. Large Title tylko na ekranie powitalnym.
  final TextStyle? titleStyle;
  final double leadingSpacing;

  /// Szerokość kolumny tekstu — decyduje, gdzie łamią się tytuł i podtytuł.
  final double maxTextWidth;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (leading != null) ...[leading!, SizedBox(height: leadingSpacing)],
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxTextWidth),
          child: Column(
            spacing: 8,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: (titleStyle ?? AppTextStyle.title1Emphasized).copyWith(
                  color: AppColor.onBackground,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: AppTextStyle.body.copyWith(
                    color: AppColor.labelSecondary,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
