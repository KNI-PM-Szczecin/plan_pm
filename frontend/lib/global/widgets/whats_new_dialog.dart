// Dialog "Co nowego" wyświetlany przy starcie po aktualizacji aplikacji.
// Pokazuje listę zmian z aktualnej wersji zdefiniowaną w [changelog.dart].
// Wywoływany z home_shell.dart (start aplikacji i pozycja w menu bocznym).
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:plan_pm/global/theme/colors.dart';
import 'package:plan_pm/global/theme/typography.dart';
import 'package:plan_pm/global/widgets/app_dialog.dart';
import 'package:plan_pm/l10n/app_localizations.dart';

class WhatsNewDialog extends StatelessWidget {
  const WhatsNewDialog({
    super.key,
    required this.version,
    required this.changes,
  });

  final String version;
  final List<String> changes;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppDialog(
      icon: LucideIcons.sparkles,
      iconColor: AppColor.systemPurple,
      title: l10n.whatsNewTitle,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              '${l10n.version} $version',
              style: AppTextStyle.footnote.copyWith(
                color: AppColor.labelSecondary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Długa lista zmian przewija się w okienku, przycisk zostaje widoczny.
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: SingleChildScrollView(
              child: Column(
                spacing: 10,
                children: [for (final change in changes) _ChangeItem(change)],
              ),
            ),
          ),
        ],
      ),
      primaryLabel: l10n.whatsNewGotIt,
      onPrimary: () => Navigator.of(context).pop(),
    );
  }
}

class _ChangeItem extends StatelessWidget {
  const _ChangeItem(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 10,
      children: [
        Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(top: 7),
          decoration: BoxDecoration(
            color: AppColor.primary,
            shape: BoxShape.circle,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: AppTextStyle.subheadline.copyWith(color: AppColor.onSurface),
          ),
        ),
      ],
    );
  }
}
