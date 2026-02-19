import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:plan_pm/global/colors.dart';
import 'package:plan_pm/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class FeedbackPage extends StatelessWidget {
  const FeedbackPage({super.key});

  Future<void> launchFeedbackForm(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final Uri url = Uri.parse("https://forms.gle/E8sLgZ1X49kaX5jA6");

    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (!context.mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.feedbackFormOpenGenericError)),
        );
        return;
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.feedbackFormOpenError(e.toString()))),
        );
      }
    }
  }

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
          l10n.sendFeedbackButton,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColor.onBackground,
          ),
        ),
        shape: Border(bottom: BorderSide(color: AppColor.outline)),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.messageSquare,
                size: 64,
                color: AppColor.primary,
              ),
              const SizedBox(height: 24),
              Text(
                l10n.feedbackPageHeadline,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColor.onBackground,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.feedbackPageDescription,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColor.onBackgroundVariant),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => launchFeedbackForm(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primary,
                  foregroundColor: AppColor.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                icon: const Icon(LucideIcons.externalLink),
                label: Text(l10n.sendFeedbackButton),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
