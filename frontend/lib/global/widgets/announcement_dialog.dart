// Dialog wyświetlany przy starcie aplikacji gdy pojawi się nowe ogłoszenie systemowe.
// Wygląd zależy od [AnnouncementModel.type]: 'info' i 'warning' pokazują tylko
// przycisk zamknięcia, 'update' dodatkowo przycisk otwierający [storeUrl]
// w App Store / Play Store. Wywoływany wyłącznie z home_shell.dart przy starcie.
//
// Typ niesie kolor kółka z ikoną (bez gradientu): info niebieski,
// ostrzeżenie pomarańczowy, aktualizacja indygo.
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:plan_pm/api/models/announcement_model.dart';
import 'package:plan_pm/global/theme/colors.dart';
import 'package:plan_pm/global/widgets/app_dialog.dart';
import 'package:plan_pm/l10n/app_localizations.dart';
import 'package:plan_pm/global/utils/logger.dart';
import 'package:url_launcher/url_launcher.dart';

class AnnouncementDialog extends StatelessWidget {
  const AnnouncementDialog({super.key, required this.announcement});

  final AnnouncementModel announcement;

  (IconData, Color) get _style => switch (announcement.type) {
    'warning' => (LucideIcons.alertTriangle, AppColor.systemOrange),
    'update' => (LucideIcons.rocket, AppColor.systemIndigo),
    _ => (LucideIcons.info, AppColor.systemBlue),
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final canUpdate =
        announcement.type == 'update' && announcement.storeUrl != null;
    final (icon, color) = _style;

    return AppDialog(
      icon: icon,
      iconColor: color,
      title: announcement.title,
      message: announcement.message,
      primaryLabel: canUpdate
          ? l10n.announcementUpdate
          : l10n.announcementDismiss,
      onPrimary: () async {
        if (canUpdate) {
          try {
            await launchUrl(
              Uri.parse(announcement.storeUrl!),
              mode: LaunchMode.externalApplication,
            );
          } catch (e) {
            AppLogger.w(
              "[ANNOUNCEMENT] Nie udało się otworzyć linku w sklepie",
              e,
            );
          }
        }
        if (context.mounted) Navigator.of(context).pop();
      },
      secondaryLabel: canUpdate ? l10n.announcementSkip : null,
      onSecondary: () => Navigator.of(context).pop(),
    );
  }
}
