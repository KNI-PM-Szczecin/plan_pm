import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:plan_pm/api/models/announcement_model.dart';
import 'package:plan_pm/global/colors.dart';
import 'package:plan_pm/global/widgets/gradient_button.dart';
import 'package:plan_pm/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

class AnnouncementDialog extends StatelessWidget {
  const AnnouncementDialog({super.key, required this.announcement});

  final AnnouncementModel announcement;

  static const _gradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  IconData get _icon => switch (announcement.type) {
        'warning' => LucideIcons.alertTriangle,
        'update' => LucideIcons.rocket,
        _ => LucideIcons.info,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isUpdate = announcement.type == 'update';
    final hasUrl = announcement.storeUrl != null;

    return Dialog(
      backgroundColor: AppColor.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: AppColor.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: _gradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(_icon, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 20),
            Text(
              announcement.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColor.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              announcement.message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppColor.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 28),
            GradientButton(
              gradient: _gradient,
              label: (isUpdate && hasUrl)
                  ? l10n.announcementUpdate
                  : l10n.announcementDismiss,
              onTap: () async {
                if (isUpdate && hasUrl) {
                  try {
                    await launchUrl(
                      Uri.parse(announcement.storeUrl!),
                      mode: LaunchMode.externalApplication,
                    );
                  } catch (_) {}
                }
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
            if (isUpdate && hasUrl) ...[
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  l10n.announcementSkip,
                  style: TextStyle(color: AppColor.onSurfaceVariant),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
