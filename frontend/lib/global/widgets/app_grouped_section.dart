// Karta listy w stylu iOS „inset grouped": zaokrąglona, na tle strony,
// wiersze rozdzielone cienką linią. Wiersze to zwykle [AppListRow].
// Nagłówek, akcję i stopkę dokłada [AppSection].
import 'package:flutter/material.dart';
import 'package:plan_pm/global/theme/colors.dart';

class AppGroupedSection extends StatelessWidget {
  const AppGroupedSection({
    super.key,
    required this.children,
    this.dividerIndent = 0,
  });

  final List<Widget> children;

  /// Wcięcie separatora od lewej. 0 = na całą szerokość; przy wierszach
  /// z ikoną linia zaczyna się pod tekstem — [iconRowDividerIndent].
  final double dividerIndent;

  static const double radius = 26;

  /// Wcięcie dla wierszy z [AppIconBadge] 30 pt: padding 16 + ikona 30 + odstęp 12.
  static const double iconRowDividerIndent = 58;

  @override
  Widget build(BuildContext context) {
    return ClipRSuperellipse(
      borderRadius: BorderRadius.circular(radius),
      child: ColoredBox(
        color: AppColor.groupedSurface,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0)
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: dividerIndent,
                  color: AppColor.separator,
                ),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}
