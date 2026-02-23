import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:plan_pm/global/colors.dart';
import 'package:plan_pm/global/notifiers.dart';
import 'package:plan_pm/l10n/app_localizations.dart';

class AppearancePage extends StatelessWidget {
  const AppearancePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        backgroundColor: AppColor.background,
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(
            LucideIcons.chevronLeft,
            color: AppColor.onBackgroundVariant,
          ),
        ),
        title: Text(
          l10n.appearanceHeader,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColor.onBackground,
          ),
        ),
        shape: Border(bottom: BorderSide(color: AppColor.outline)),
      ),
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
                                imageAsset: 'assets/light_theme.png',
                                isSelected: currentMode == ThemeMode.light,
                                onTap: () => _selectTheme(ThemeMode.light),
                              ),
                              const SizedBox(width: 12),
                              _ThemeCard(
                                title: l10n.themeDark,
                                imageAsset: 'assets/dark_theme.png',
                                isSelected: currentMode == ThemeMode.dark,
                                onTap: () => _selectTheme(ThemeMode.dark),
                              ),
                              const SizedBox(width: 12),
                              _ThemeCard(
                                title: l10n.themeSystem,
                                imageAsset: 'assets/mixed_theme.png',
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
                          )
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