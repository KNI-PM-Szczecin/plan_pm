// Uniwersalna strona otwierająca zewnętrzny link w przeglądarce.
// Używana przez PE, Wirtualny Dziekanat, Legitymację i Feedback
// zamiast czterech identycznych stron.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:plan_pm/global/theme/colors.dart';
import 'package:url_launcher/url_launcher.dart';

class ExternalLinkPage extends StatelessWidget {
  const ExternalLinkPage({
    super.key,
    required this.url,
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonLabel,
  });

  final String url;
  final IconData icon;
  final String title;
  final String description;
  final String buttonLabel;

  Future<void> _launch() async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        backgroundColor: AppColor.background,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(LucideIcons.chevronLeft, color: AppColor.onBackgroundVariant),
        ),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w600, color: AppColor.onBackground),
        ),
        forceMaterialTransparency: true,
        shape: Border(bottom: BorderSide(color: AppColor.outline)),
      ),
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
                child: Icon(icon, size: 64, color: AppColor.primary),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColor.onBackground,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: TextStyle(fontSize: 16, color: AppColor.onBackgroundVariant),
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
                    _launch();
                  },
                  child: Text(
                    buttonLabel,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
