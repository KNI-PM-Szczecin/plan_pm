// Wiersz wykładowcy na liście wyboru — awatar z inicjałami, imię i nazwisko, ptaszek gdy zaznaczony.
// Używany w [LecturerSelectionPage].
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:plan_pm/api/models/lecturer_item.dart';
import 'package:plan_pm/global/theme/colors.dart';

class LecturerTile extends StatelessWidget {
  const LecturerTile({
    super.key,
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final LecturerItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? AppColor.primary.withValues(alpha: 0.15)
          : AppColor.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColor.primary.withValues(alpha: 0.18),
                child: Text(
                  item.initials,
                  style: TextStyle(
                    color: AppColor.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  item.displayName,
                  style: TextStyle(
                    color: AppColor.onSurface,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 15,
                  ),
                ),
              ),
              if (selected)
                Icon(LucideIcons.checkCircle,
                    color: AppColor.primary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
