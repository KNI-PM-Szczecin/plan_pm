// Pole wyszukiwania wykładowców — pigułka z lupą i przyciskiem czyszczenia (×).
// Używane w [LecturerSelectionPage].
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:plan_pm/global/theme/colors.dart';
import 'package:plan_pm/global/theme/typography.dart';
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
    return Container(
      height: 40,
      // Z prawej mniej — przycisk czyszczenia ma własne pole dotyku.
      padding: const EdgeInsets.only(left: 12, right: 4),
      decoration: ShapeDecoration(
        color: AppColor.fillTertiary,
        shape: const StadiumBorder(),
      ),
      child: Row(
        spacing: 8,
        children: [
          Icon(LucideIcons.search, size: 18, color: AppColor.labelSecondary),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              style: AppTextStyle.body.copyWith(color: AppColor.onBackground),
              cursorColor: AppColor.primary,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: l10n.searchHint,
                hintStyle: AppTextStyle.body.copyWith(
                  color: AppColor.labelSecondary,
                ),
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            // Przycisk dla czytników ekranu, pole dotyku na całą wysokość pola.
            Semantics(
              button: true,
              label: MaterialLocalizations.of(context).clearButtonTooltip,
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  controller.clear();
                  onChanged('');
                },
                child: SizedBox.square(
                  dimension: 40,
                  child: Icon(
                    LucideIcons.xCircle,
                    size: 18,
                    color: AppColor.labelSecondary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
