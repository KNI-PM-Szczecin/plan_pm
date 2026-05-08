// Strona ustawień wyglądu — motyw, tryb AMOLED, kolor akcentu, styl kolorów zajęć.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:plan_pm/global/theme/colors.dart';
import 'package:plan_pm/global/notifiers/notifiers.dart';
import 'package:plan_pm/global/widgets/app_bar.dart';
import 'package:plan_pm/pages/settings/utils/appearance_utils.dart';
import 'package:plan_pm/pages/settings/widgets/controls/setting_switch_tile.dart';
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
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: AppColor.surface,
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.appearanceHint,
                    style: TextStyle(
                      color: AppColor.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ValueListenableBuilder<ThemeMode>(
                    valueListenable: themeNotifier,
                    builder: (context, currentMode, _) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                          const SizedBox(height: 24),
                          Divider(color: AppColor.outline, height: 1),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Icon(
                                currentMode == ThemeMode.light
                                    ? LucideIcons.sun
                                    : (currentMode == ThemeMode.dark
                                        ? LucideIcons.moon
                                        : LucideIcons.monitor),
                                color: AppColor.onSurfaceVariant,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
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
                          const SizedBox(height: 24),
                          Divider(color: AppColor.outline, height: 1),
                          const SizedBox(height: 16),
                          ValueListenableBuilder<bool>(
                            valueListenable: amoledModeNotifier,
                            builder: (context, isAmoled, _) {
                              return SettingSwitchTile(
                                label: l10n.amoledModeTitle,
                                subtitle: l10n.amoledModeDesc,
                                value: isAmoled,
                                onChanged: (val) {
                                  HapticFeedback.selectionClick();
                                  amoledModeNotifier.setAmoledMode(val);
                                },
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          Divider(color: AppColor.outline, height: 1),
                          const SizedBox(height: 16),
                          Text(
                            l10n.accentColorTitle,
                            style: TextStyle(
                              color: AppColor.onSurfaceVariant,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ValueListenableBuilder<AppAccentColor>(
                            valueListenable: accentColorNotifier,
                            builder: (context, currentColor, _) {
                              return Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
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
                                        border: Border.all(
                                          color: currentColor == color
                                              ? AppColor.onSurface
                                              : Colors.transparent,
                                          width: 3,
                                        ),
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
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          Divider(color: AppColor.outline, height: 1),
                          const SizedBox(height: 16),
                          ValueListenableBuilder<EventColorStyle>(
                            valueListenable: eventColorStyleNotifier,
                            builder: (context, currentStyle, _) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.eventStyleTitle,
                                    style: TextStyle(
                                      color: AppColor.onSurfaceVariant,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: AppColor.background,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: AppColor.outline,
                                      ),
                                    ),
                                    child: RadioGroup<EventColorStyle>(
                                      groupValue: currentStyle,
                                      onChanged: (val) {
                                        if (val != null) {
                                          HapticFeedback.selectionClick();
                                          eventColorStyleNotifier
                                              .setEventStyle(val);
                                        }
                                      },
                                      child: Column(
                                        children:
                                            EventColorStyle.values.map((style) {
                                              return RadioListTile<
                                                EventColorStyle
                                              >(
                                                activeColor: AppColor.primary,
                                                title: Text(
                                                  getEventStyleName(style, l10n),
                                                  style: TextStyle(
                                                    color: AppColor.onSurface,
                                                  ),
                                                ),
                                                value: style,
                                              );
                                            }).toList(),
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
                ],
              ),
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
