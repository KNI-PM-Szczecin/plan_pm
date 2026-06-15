// Ekran zgody RODO — pokazywany przy wyborze wykładowcy (gdy kDebugGdpr = true).
// Żeby przejść dalej, użytkownik musi zaakceptować; przyciskiem wstecz może anulować.
// Nie zapisuje stanu zgody — każde wejście wymaga ponownej akceptacji.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:plan_pm/global/theme/colors.dart';
import 'package:plan_pm/global/widgets/back_button.dart';
import 'package:plan_pm/l10n/app_localizations.dart';

class GdprConsentPage extends StatelessWidget {
  const GdprConsentPage({super.key, required this.onAccepted});

  final VoidCallback onAccepted;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: AppColor.background,
        body: SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SizedBox(width: 56, child: AppBackButton()),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),
                      Icon(
                        Icons.verified_user_outlined,
                        size: 56,
                        color: AppColor.onSurface,
                      ),
                      const SizedBox(height: 32),
                      Text(
                        l10n.gdprTitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColor.onSurface,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 32),
                      _InfoCard(
                        icon: Icons.account_balance_rounded,
                        title: l10n.gdprCard1Title,
                        body: l10n.gdprCard1Body,
                        iconColor: AppColor.primary,
                      ),
                      const SizedBox(height: 12),
                      _InfoCard(
                        icon: Icons.description_rounded,
                        title: l10n.gdprCard2Title,
                        body: l10n.gdprCard2Body,
                        iconColor: AppColor.primary,
                      ),
                      const SizedBox(height: 12),
                      _InfoCard(
                        icon: Icons.task_alt_rounded,
                        title: l10n.gdprCard3Title,
                        body: l10n.gdprCard3Body,
                        iconColor: AppColor.primary,
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  children: [
                    FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 54),
                        backgroundColor: AppColor.primary,
                        foregroundColor: AppColor.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pop();
                        onAccepted();
                      },
                      child: Text(l10n.gdprAccept),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.gdprRevoke,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColor.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.iconColor,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColor.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: TextStyle(
              fontSize: 14,
              color: AppColor.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
