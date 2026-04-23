import 'package:plan_pm/global/widgets/plan_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:plan_pm/global/colors.dart';
import 'package:plan_pm/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class VirtualUniversityPage extends StatelessWidget {
  const VirtualUniversityPage({super.key});

  final String _url = "https://wu.pm.szczecin.pl";

  Future<void> _launchUrl(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final Uri uri = Uri.parse(_url);

    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.virtualUniversityPageUrlError)),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${l10n.virtualUniversityPageUrlError}: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: PlanAppBar(title: l10n.virtualUniversityPageTitle),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColor.surface,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  LucideIcons.landmark,
                  size: 64,
                  color: AppColor.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.virtualUniversityPageTitle,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColor.onBackground,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.virtualUniversityPageDescription,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColor.onBackgroundVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColor.primary,
                    foregroundColor: AppColor.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _launchUrl(context);
                  },
                  child: Text(
                    l10n.virtualUniversityPageButton,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
