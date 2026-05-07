import 'package:plan_pm/global/widgets/plan_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:plan_pm/global/colors.dart';
import 'package:plan_pm/global/notifiers.dart';
import 'package:plan_pm/l10n/app_localizations.dart';

class LanguagePage extends StatelessWidget {
  const LanguagePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: PlanAppBar(title: l10n.languageHeader),
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
                    l10n.languageHint,
                    style: TextStyle(
                      color: AppColor.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ValueListenableBuilder<Locale?>(
                    valueListenable: localeNotifier,
                    builder: (context, currentLocale, _) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _LanguageCard(
                            title: l10n.languageSystem,
                            emojiFlag: '🌐',
                            isSelected: currentLocale == null,
                            onTap: () => _selectLanguage(null),
                            showFlag: false,
                          ),
                          const SizedBox(height: 12),
                          _LanguageCard(
                            title: l10n.languagePolish,
                            emojiFlag: '🇵🇱',
                            isSelected: currentLocale?.languageCode == 'pl',
                            onTap: () => _selectLanguage(const Locale('pl')),
                            showFlag: true,
                          ),
                          const SizedBox(height: 12),
                          _LanguageCard(
                            title: l10n.languageEnglish,
                            emojiFlag: '🇬🇧',
                            isSelected: currentLocale?.languageCode == 'en',
                            onTap: () => _selectLanguage(const Locale('en')),
                            showFlag: true,
                          ),
                          const SizedBox(height: 12),
                          _LanguageCard(
                            title: l10n.languageUkrainian,
                            emojiFlag: '🇺🇦',
                            isSelected: currentLocale?.languageCode == 'uk',
                            onTap: () => _selectLanguage(const Locale('uk')),
                            showFlag: true,
                          ),
                          const SizedBox(height: 24),
                          Divider(color: AppColor.outline, height: 1),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Icon(
                                LucideIcons.languages,
                                color: AppColor.onSurfaceVariant,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: l10n.activeLanguageLabel,
                                      style: TextStyle(
                                        color: AppColor.onSurfaceVariant,
                                        fontSize: 14,
                                      ),
                                    ),
                                    TextSpan(
                                      text: _getLanguageName(currentLocale, l10n),
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

  void _selectLanguage(Locale? locale) {
    HapticFeedback.selectionClick();
    localeNotifier.setLocale(locale);
  }

  String _getLanguageName(Locale? locale, AppLocalizations l10n) {
    if (locale?.languageCode == 'pl') return l10n.languagePolish;
    if (locale?.languageCode == 'en') return l10n.languageEnglish;
    if (locale?.languageCode == 'uk') return l10n.languageUkrainian;
    return l10n.languageSystem;
  }
}

class _LanguageCard extends StatefulWidget {
  final String title;
  final String emojiFlag;
  final bool isSelected;
  final VoidCallback onTap;
  final bool showFlag;

  const _LanguageCard({
    required this.title,
    required this.emojiFlag,
    required this.isSelected,
    required this.onTap,
    this.showFlag = true,
  });

  @override
  State<_LanguageCard> createState() => _LanguageCardState();
}

class _LanguageCardState extends State<_LanguageCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppColor.primary.withAlpha(25)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isSelected ? AppColor.primary : AppColor.outline,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              if (widget.showFlag) ...[
                Text(
                  widget.emojiFlag,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 16),
              ] else ...[
                Icon(
                  LucideIcons.laptop, // 'System' icon
                  color: widget.isSelected ? AppColor.primary : AppColor.onSurfaceVariant,
                  size: 24,
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: Text(
                  widget.title,
                  style: TextStyle(
                    color: widget.isSelected ? AppColor.primary : AppColor.onSurface,
                    fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ),
              if (widget.isSelected)
                Icon(
                  LucideIcons.checkCircle2,
                  color: AppColor.primary,
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
