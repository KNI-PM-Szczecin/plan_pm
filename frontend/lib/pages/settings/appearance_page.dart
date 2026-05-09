// Strona ustawień wyglądu — motyw, kolor akcentu, styl kolorów zajęć.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:plan_pm/global/theme/colors.dart';
import 'package:plan_pm/global/notifiers/notifiers.dart';
import 'package:plan_pm/global/widgets/app_bar.dart';
import 'package:plan_pm/pages/settings/utils/appearance_utils.dart';
import 'package:plan_pm/pages/settings/widgets/controls/theme_card.dart';
import 'package:plan_pm/l10n/app_localizations.dart';

class AppearancePage extends StatelessWidget {
  const AppearancePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: CustomAppBar(title: l10n.appearanceHeader),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: ValueListenableBuilder<ThemeMode>(
              valueListenable: themeNotifier,
              builder: (context, currentMode, _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Theme picker card ──────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColor.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Text(
                            l10n.appearanceHint,
                            style: TextStyle(
                              color: AppColor.onSurfaceVariant,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ThemeCard(
                                title: l10n.themeLight,
                                imageAsset: 'assets/theme_light.png',
                                isSelected: currentMode == ThemeMode.light,
                                onTap: () => _selectTheme(ThemeMode.light),
                              ),
                              const SizedBox(width: 12),
                              ThemeCard(
                                title: l10n.themeDark,
                                imageAsset: 'assets/theme_dark.png',
                                isSelected: currentMode == ThemeMode.dark,
                                onTap: () => _selectTheme(ThemeMode.dark),
                              ),
                              const SizedBox(width: 12),
                              ThemeCard(
                                title: l10n.themeSystem,
                                imageAsset: 'assets/theme_mixed.png',
                                isSelected: currentMode == ThemeMode.system,
                                onTap: () => _selectTheme(ThemeMode.system),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Active theme pill ──────────────────────────────
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppColor.surface,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            currentMode == ThemeMode.light
                                ? LucideIcons.sun
                                : (currentMode == ThemeMode.dark
                                    ? LucideIcons.moon
                                    : LucideIcons.monitor),
                            color: AppColor.onSurfaceVariant,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: l10n.activeThemeLabel,
                                  style: TextStyle(
                                    color: AppColor.onSurfaceVariant,
                                    fontSize: 14,
                                  ),
                                ),
                                TextSpan(
                                  text: getThemeName(currentMode, l10n),
                                  style: TextStyle(
                                    color: AppColor.onSurface,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Accent Color (no container) ────────────────────
                    Text(
                      l10n.accentColorTitle,
                      style: TextStyle(
                        color: AppColor.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ValueListenableBuilder<AppAccentColor>(
                      valueListenable: accentColorNotifier,
                      builder: (context, currentColor, _) {
                        return AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          transitionBuilder: (child, animation) =>
                              FadeTransition(opacity: animation, child: child),
                          child: Row(
                            key: ValueKey(currentColor),
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: AppAccentColor.values.map((color) {
                              return GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  accentColorNotifier.setAccentColor(color);
                                },
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: getAccentColorValue(
                                      color,
                                      Theme.of(context).brightness,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: currentColor == color
                                      ? Icon(
                                          LucideIcons.check,
                                          color: Colors.white,
                                          size: 22,
                                        )
                                      : null,
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),

                    // ── Event Style ────────────────────────────────────
                    ValueListenableBuilder<EventColorStyle>(
                      valueListenable: eventColorStyleNotifier,
                      builder: (context, currentStyle, _) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.eventStyleTitle.toUpperCase(),
                              style: TextStyle(
                                color: AppColor.onSurfaceVariant,
                                fontSize: 12,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: AppColor.surface,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Column(
                                  children: () {
                                    final styles = EventColorStyle.values;
                                    final List<Widget> rows = [];
                                    for (int i = 0; i < styles.length; i++) {
                                      final style = styles[i];
                                      final isSelected = style == currentStyle;
                                      if (i > 0) {
                                        rows.add(Divider(height: 1, color: AppColor.outline, indent: 16, endIndent: 16));
                                      }
                                      rows.add(
                                        InkWell(
                                          onTap: () {
                                            HapticFeedback.selectionClick();
                                            eventColorStyleNotifier.setEventStyle(style);
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    getEventStyleName(style, l10n),
                                                    style: TextStyle(color: AppColor.onSurface, fontSize: 16),
                                                  ),
                                                ),
                                                if (isSelected)
                                                  Icon(LucideIcons.check, color: AppColor.primary, size: 20),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                    return rows;
                                  }(),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _selectTheme(ThemeMode mode) {
    HapticFeedback.selectionClick();
    themeNotifier.setTheme(mode);
  }
}
