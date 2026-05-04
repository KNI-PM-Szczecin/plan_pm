// Strona wyboru języka aplikacji — system, polski, angielski, ukraiński.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:plan_pm/global/theme/colors.dart';
import 'package:plan_pm/global/notifiers/notifiers.dart';
import 'package:plan_pm/global/widgets/standard_app_bar.dart';
import 'package:plan_pm/pages/settings/widgets/controls/selection_card.dart';
import 'package:plan_pm/l10n/app_localizations.dart';

class LanguagePage extends StatelessWidget {
  const LanguagePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: StandardAppBar(title: l10n.languageHeader),
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
                          SelectionCard(
                            leading: Icon(
                              LucideIcons.laptop,
                              color: AppColor.onSurfaceVariant,
                              size: 24,
                            ),
                            label: l10n.languageSystem,
                            isSelected: currentLocale == null,
                            onTap: () => _selectLanguage(null),
                          ),
                          const SizedBox(height: 12),
                          SelectionCard(
                            leading: Text(
                              '🇵🇱',
                              style: TextStyle(fontSize: 24),
                            ),
                            label: l10n.languagePolish,
                            isSelected: currentLocale?.languageCode == 'pl',
                            onTap: () => _selectLanguage(const Locale('pl')),
                          ),
                          const SizedBox(height: 12),
                          SelectionCard(
                            leading: Text(
                              '🇬🇧',
                              style: TextStyle(fontSize: 24),
                            ),
                            label: l10n.languageEnglish,
                            isSelected: currentLocale?.languageCode == 'en',
                            onTap: () => _selectLanguage(const Locale('en')),
                          ),
                          const SizedBox(height: 12),
                          SelectionCard(
                            leading: Text(
                              '🇺🇦',
                              style: TextStyle(fontSize: 24),
                            ),
                            label: l10n.languageUkrainian,
                            isSelected: currentLocale?.languageCode == 'uk',
                            onTap: () => _selectLanguage(const Locale('uk')),
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
