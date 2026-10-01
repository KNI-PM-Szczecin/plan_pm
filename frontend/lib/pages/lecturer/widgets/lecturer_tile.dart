// Wiersz wykładowcy na liście wyboru — awatar z inicjałami, tytuł naukowy nad
// imieniem i nazwiskiem, haczyk gdy zaznaczony. Kładziony w jednej zgrupowanej
// liście: [isFirst]/[isLast] zaokrąglają jej rogi, bo lista buduje się leniwie
// (setki pozycji) i nie da się jej owinąć jedną kartą.
import 'package:flutter/material.dart';
import 'package:plan_pm/api/models/lecturer_item.dart';
import 'package:plan_pm/global/theme/colors.dart';
import 'package:plan_pm/global/theme/typography.dart';
import 'package:plan_pm/global/widgets/app_grouped_section.dart';
import 'package:plan_pm/global/widgets/app_list_row.dart';

class LecturerTile extends StatelessWidget {
  const LecturerTile({
    super.key,
    required this.item,
    required this.selected,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
  });

  final LecturerItem item;
  final bool selected;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;

  /// Wcięcie separatora: padding 16 + awatar 40 + odstęp 12.
  static const double dividerIndent = 68;

  @override
  Widget build(BuildContext context) {
    const r = Radius.circular(AppGroupedSection.radius);
    final accent = AppColor.primary;
    return ClipRRect(
      borderRadius: BorderRadius.vertical(
        top: isFirst ? r : Radius.zero,
        bottom: isLast ? r : Radius.zero,
      ),
      child: ColoredBox(
        color: AppColor.groupedSurface,
        child: Column(
          children: [
            AppListRow(
              leading: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? accent : accent.withValues(alpha: 0.22),
                ),
                child: Text(
                  item.initials,
                  style: AppTextStyle.subheadlineEmphasized.copyWith(
                    color: selected ? Colors.white : accent,
                  ),
                ),
              ),
              label: (item.title?.isNotEmpty ?? false) ? item.title : null,
              title: item.name,
              selected: selected,
              accessory: selected
                  ? AppListRowAccessory.checkmark
                  : AppListRowAccessory.none,
              onTap: onTap,
            ),
            if (!isLast)
              Divider(
                height: 1,
                thickness: 1,
                indent: dividerIndent,
                color: AppColor.separator,
              ),
          ],
        ),
      ),
    );
  }
}
