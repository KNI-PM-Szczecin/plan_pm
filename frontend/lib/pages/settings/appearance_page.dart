import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:plan_pm/global/theme/colors.dart';
import 'package:plan_pm/global/notifiers/notifiers.dart';
import 'package:plan_pm/global/widgets/standard_app_bar.dart';
import 'package:plan_pm/pages/settings/widgets/setting_switch_tile.dart';
import 'package:plan_pm/l10n/app_localizations.dart';

class AppearancePage extends StatelessWidget {
  const AppearancePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: StandardAppBar(title: l10n.appearanceHeader),
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
                border: Border.all(color: AppColor.outline),
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
                              _ThemeCard(
                                title: l10n.themeLight,
                                imageAsset: 'assets/theme_light.png',
                                isSelected: currentMode == ThemeMode.light,
                                onTap: () => _selectTheme(ThemeMode.light),
                              ),
                              const SizedBox(width: 12),
                              _ThemeCard(
                                title: l10n.themeDark,
                                imageAsset: 'assets/theme_dark.png',
                                isSelected: currentMode == ThemeMode.dark,
                                onTap: () => _selectTheme(ThemeMode.dark),
                              ),
                              const SizedBox(width: 12),
                              _ThemeCard(
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
                                    : (currentMode == ThemeMode.dark ? LucideIcons.moon : LucideIcons.monitor),
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
                                      text: _getThemeName(currentMode, l10n),
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
                          
                          // AMOLED Toggle
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
                          
                          // Accent Color
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
                                        color: _getAccentColorValue(color, Theme.of(context).brightness),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: currentColor == color ? AppColor.onSurface : Colors.transparent,
                                          width: 3,
                                        ),
                                      ),
                                      child: currentColor == color
                                          ? Icon(LucideIcons.check, color: Colors.white, size: 22)
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
                          
                          // Event Color Style
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
                                      border: Border.all(color: AppColor.outline),
                                    ),
                                    child: RadioGroup<EventColorStyle>(
                                      groupValue: currentStyle,
                                      onChanged: (val) {
                                        if (val != null) {
                                          HapticFeedback.selectionClick();
                                          eventColorStyleNotifier.setEventStyle(val);
                                        }
                                      },
                                      child: Column(
                                        children: EventColorStyle.values.map((style) {
                                          return RadioListTile<EventColorStyle>(
                                            activeColor: AppColor.primary,
                                            title: Text(_getEventStyleName(style, l10n), style: TextStyle(color: AppColor.onSurface)),
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

  String _getThemeName(ThemeMode mode, AppLocalizations l10n) {
    if (mode == ThemeMode.light) return l10n.themeLight;
    if (mode == ThemeMode.dark) return l10n.themeDark;
    return l10n.themeSystem;
  }

  Color _getAccentColorValue(AppAccentColor color, Brightness brightness) {
    if (brightness == Brightness.light) {
      switch (color) {
        case AppAccentColor.blue: return ColorThemes.lightPrimary;
        case AppAccentColor.green: return const Color(0xFF10B981);
        case AppAccentColor.purple: return const Color(0xFF8B5CF6);
        case AppAccentColor.orange: return const Color(0xFFF59E0B);
        case AppAccentColor.red: return const Color(0xFFEF4444);
        case AppAccentColor.pink: return const Color(0xFFEC4899);
      }
    } else {
      switch (color) {
        case AppAccentColor.blue: return ColorThemes.darkPrimary;
        case AppAccentColor.green: return const Color(0xFF34D399);
        case AppAccentColor.purple: return const Color(0xFFA855F7);
        case AppAccentColor.orange: return const Color(0xFFFBBF24);
        case AppAccentColor.red: return const Color(0xFFF87171);
        case AppAccentColor.pink: return const Color(0xFFF472B6);
      }
    }
  }

  String _getEventStyleName(EventColorStyle style, AppLocalizations l10n) {
    switch (style) {
      case EventColorStyle.current: return l10n.eventStyleCurrent;
      case EventColorStyle.pastel: return l10n.eventStylePastel;
      case EventColorStyle.vibrant: return l10n.eventStyleVibrant;
      case EventColorStyle.monochrome: return l10n.eventStyleMonochrome;
    }
  }
}

class _ThemeCard extends StatefulWidget {
  final String title;
  final String imageAsset;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeCard({
    required this.title,
    required this.imageAsset,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_ThemeCard> createState() => _ThemeCardState();
}

class _ThemeCardState extends State<_ThemeCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.isSelected ? AppColor.primary : Colors.transparent,
                    width: 2.0,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    widget.imageAsset,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        color: widget.isSelected ? AppColor.onSurface : AppColor.onSurfaceVariant,
                        fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.isSelected) ...[
                    const SizedBox(width: 4),
                    Icon(
                      LucideIcons.check,
                      color: AppColor.primary,
                      size: 14,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}