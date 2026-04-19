import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:plan_pm/global/colors.dart';
import 'package:plan_pm/global/widgets/gradient_button.dart';
import 'package:plan_pm/l10n/app_localizations.dart';

class WhatsNewDialog extends StatelessWidget {
  const WhatsNewDialog({
    super.key,
    required this.version,
    required this.changes,
  });

  final String version;
  final List<String> changes;

  static const _gradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFF3B82F6)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
              child: const Icon(LucideIcons.sparkles, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 20),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        l10n.whatsNewTitle,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColor.onSurface,
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        'v$version',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColor.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ...changes.map((change) => _ChangeItem(text: change)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            GradientButton(
              gradient: _gradient,
              label: l10n.whatsNewGotIt,
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChangeItem extends StatelessWidget {
  const _ChangeItem({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                gradient: WhatsNewDialog._gradient,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppColor.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
