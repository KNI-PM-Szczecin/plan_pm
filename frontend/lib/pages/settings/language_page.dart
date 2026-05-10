// Strona wyboru języka aplikacji — system, polski, angielski, ukraiński.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:plan_pm/global/theme/colors.dart';
import 'package:plan_pm/global/notifiers/notifiers.dart';
import 'package:plan_pm/global/widgets/app_bar.dart';
import 'package:plan_pm/l10n/app_localizations.dart';

class LanguagePage extends StatelessWidget {
  const LanguagePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final options = [
      _LangOption(
        leading: Icon(LucideIcons.monitor, color: AppColor.onSurfaceVariant, size: 22),
        label: l10n.languageSystem,
        locale: null,
      ),
      _LangOption(
        leading: const Text('🇵🇱', style: TextStyle(fontSize: 22)),
        label: l10n.languagePolish,
        locale: const Locale('pl'),
      ),
      _LangOption(
        leading: const Text('🇬🇧', style: TextStyle(fontSize: 22)),
        label: l10n.languageEnglish,
        locale: const Locale('en'),
      ),
      _LangOption(
        leading: const Text('🇺🇦', style: TextStyle(fontSize: 22)),
        label: l10n.languageUkrainian,
        locale: const Locale('uk'),
      ),
    ];

    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: CustomAppBar(title: l10n.languageHeader),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: ValueListenableBuilder<Locale?>(
              valueListenable: localeNotifier,
              builder: (context, currentLocale, _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.languageHint.toUpperCase(),
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
                            final List<Widget> rows = [];
                            for (int i = 0; i < options.length; i++) {
                              final opt = options[i];
                              final isSelected = opt.locale == null
                                  ? currentLocale == null
                                  : currentLocale?.languageCode == opt.locale!.languageCode;
                              if (i > 0) {
                                rows.add(Divider(height: 1, color: AppColor.outline, indent: 16, endIndent: 16));
                              }
                              rows.add(
                                GestureDetector(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    localeNotifier.setLocale(opt.locale);
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    child: Row(
                                      children: [
                                        SizedBox(width: 28, child: opt.leading),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            opt.label,
                                            style: TextStyle(color: AppColor.onSurface, fontSize: 16),
                                          ),
                                        ),
                                        AnimatedSwitcher(
                                          duration: const Duration(milliseconds: 200),
                                          transitionBuilder: (child, animation) => ScaleTransition(
                                            scale: animation,
                                            child: FadeTransition(opacity: animation, child: child),
                                          ),
                                          child: isSelected
                                              ? Icon(LucideIcons.check, key: const ValueKey('check'), color: AppColor.primary, size: 20)
                                              : const SizedBox(key: ValueKey('empty'), width: 20),
                                        ),
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
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(LucideIcons.languages, color: AppColor.onSurfaceVariant, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          '${l10n.activeLanguageLabel}${_getLanguageName(currentLocale, l10n)}',
                          style: TextStyle(color: AppColor.onSurfaceVariant, fontSize: 13),
                        ),
                      ],
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

  String _getLanguageName(Locale? locale, AppLocalizations l10n) {
    if (locale?.languageCode == 'pl') return l10n.languagePolish;
    if (locale?.languageCode == 'en') return l10n.languageEnglish;
    if (locale?.languageCode == 'uk') return l10n.languageUkrainian;
    return l10n.languageSystem;
  }
}

class _LangOption {
  final Widget leading;
  final String label;
  final Locale? locale;
  const _LangOption({required this.leading, required this.label, required this.locale});
}
