// Pole wyszukiwania wykładowców z ikoną lupy i przyciskiem czyszczenia (×).
// Używane w [LecturerSelectionPage].
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:plan_pm/global/theme/colors.dart';
import 'package:plan_pm/l10n/app_localizations.dart';

class LecturerSearchField extends StatelessWidget {
  const LecturerSearchField({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: TextStyle(color: AppColor.onBackground),
      decoration: InputDecoration(
        hintText: l10n.searchHint,
        hintStyle: TextStyle(color: AppColor.onBackgroundVariant),
        prefixIcon: Icon(LucideIcons.search, color: AppColor.primary, size: 20),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: Icon(LucideIcons.xCircle,
                    color: AppColor.onBackgroundVariant, size: 20),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              )
            : null,
        filled: true,
        fillColor: AppColor.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColor.primary, width: 1.5),
        ),
      ),
    );
  }
}
