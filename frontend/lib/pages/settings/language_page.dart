// Strona wyboru języka aplikacji — system, polski, angielski, ukraiński.
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:plan_pm/global/theme/colors.dart';
import 'package:plan_pm/global/notifiers/notifiers.dart';
import 'package:plan_pm/global/widgets/app_grouped_page.dart';
import 'package:plan_pm/global/widgets/app_grouped_section.dart';
import 'package:plan_pm/global/widgets/app_icon_badge.dart';
import 'package:plan_pm/global/widgets/app_list_row.dart';
import 'package:plan_pm/global/widgets/app_section.dart';
import 'package:plan_pm/pages/settings/utils/appearance_utils.dart';
import 'package:plan_pm/l10n/app_localizations.dart';

class LanguagePage extends StatelessWidget {
  const LanguagePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final options = <(Widget, String, Locale?)>[
      (
        AppIconBadge(icon: LucideIcons.smartphone, color: AppColor.systemGray),
        l10n.languageSystem,
        null,
      ),
      (const _Flag(_Country.pl), l10n.languagePolish, const Locale('pl')),
      (const _Flag(_Country.gb), l10n.languageEnglish, const Locale('en')),
      (const _Flag(_Country.ua), l10n.languageUkrainian, const Locale('uk')),
    ];

    return ValueListenableBuilder<Locale?>(
      valueListenable: localeNotifier,
      builder: (context, currentLocale, _) => AppGroupedPage(
        title: l10n.languageHeader,
        children: [
          AppSection(
            header: l10n.languageHint,
            footer:
                '${l10n.activeLanguageLabel}${getLanguageName(currentLocale, l10n)}',
            child: AppGroupedSection(
              dividerIndent: AppGroupedSection.iconRowDividerIndent,
              children: [
                for (final (leading, label, locale) in options)
                  () {
                    final isSelected = locale == null
                        ? currentLocale == null
                        : currentLocale?.languageCode == locale.languageCode;
                    return AppListRow(
                      leading: leading,
                      title: label,
                      selected: isSelected,
                      accessory: isSelected
                          ? AppListRowAccessory.checkmark
                          : AppListRowAccessory.none,
                      onTap: () => localeNotifier.setLocale(locale),
                    );
                  }(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _Country { pl, gb, ua }

/// Flaga 28×20 pt z zaokrągleniem i obwódką, jak w makiecie (5a) — rysowana,
/// nie emoji: emoji wyglądają różnie na iOS i Androidzie i nie mają obwódki,
/// przez co biało-czerwona zlewa się z białym tłem. Pole 30 pt, tej samej
/// szerokości co [AppIconBadge], żeby tytuły i separatory się zgadzały.
class _Flag extends StatelessWidget {
  const _Flag(this.country);

  final _Country country;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 30,
      child: Center(
        child: Container(
          width: 28,
          height: 20,
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppColor.separator),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: CustomPaint(painter: _FlagPainter(country)),
          ),
        ),
      ),
    );
  }
}

class _FlagPainter extends CustomPainter {
  const _FlagPainter(this.country);

  final _Country country;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    void stripes(Color top, Color bottom) {
      canvas.drawRect(Rect.fromLTWH(0, 0, w, h / 2), Paint()..color = top);
      canvas.drawRect(
        Rect.fromLTWH(0, h / 2, w, h / 2),
        Paint()..color = bottom,
      );
    }

    switch (country) {
      case _Country.pl:
        stripes(Colors.white, const Color(0xFFDC143C));
      case _Country.ua:
        stripes(const Color(0xFF0057B7), const Color(0xFFFFD700));
      case _Country.gb:
        // Union Jack w siatce 60×40 z makiety, przeskalowany do pola.
        canvas.scale(w / 60, h / 40);
        canvas.drawRect(
          const Rect.fromLTWH(0, 0, 60, 40),
          Paint()..color = const Color(0xFF012169),
        );
        void cross(Color color, double width, {required bool diagonal}) {
          final paint = Paint()
            ..color = color
            ..strokeWidth = width;
          if (diagonal) {
            canvas.drawLine(Offset.zero, const Offset(60, 40), paint);
            canvas.drawLine(const Offset(60, 0), const Offset(0, 40), paint);
          } else {
            canvas.drawLine(const Offset(30, 0), const Offset(30, 40), paint);
            canvas.drawLine(const Offset(0, 20), const Offset(60, 20), paint);
          }
        }

        cross(Colors.white, 8, diagonal: true);
        cross(const Color(0xFFC8102E), 3, diagonal: true);
        cross(Colors.white, 12, diagonal: false);
        cross(const Color(0xFFC8102E), 7, diagonal: false);
    }
  }

  @override
  bool shouldRepaint(_FlagPainter old) => old.country != country;
}
