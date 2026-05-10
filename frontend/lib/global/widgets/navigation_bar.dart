// Dolny pasek nawigacyjny z zakładkami: Strona główna, Plan, Aktualności.
// Montowany jako bottomNavigationBar głównego Scaffold w [main.dart].
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:plan_pm/global/theme/colors.dart';
import 'package:plan_pm/l10n/app_localizations.dart';

class CustomNavigationBar extends StatelessWidget {
  const CustomNavigationBar({
    super.key,
    required this.index,
    required this.onChange,
  });

  final int index;
  final Function(int newIndex) onChange;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColor.outline)),
      ),
      child: BottomNavigationBar(
        backgroundColor: AppColor.background,
        selectedItemColor: AppColor.primary,
        unselectedItemColor: AppColor.onBackgroundVariant,
        currentIndex: index,
        enableFeedback: false,
        onTap: (i) {
          HapticFeedback.lightImpact();
          onChange(i);
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.home),
            label: l10n.pageTitleHome,
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.calendar),
            label: l10n.pageTitleLectures,
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.newspaper),
            label: l10n.pageTitleNews,
          ),
        ],
      ),
    );
  }
}
