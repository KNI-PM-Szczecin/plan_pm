// Klikalny wiersz w menu ustawień — opcjonalna ikona z kolorowym tłem po lewej, chevron po prawej.
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:plan_pm/global/theme/colors.dart';
import 'package:plan_pm/global/theme/typography.dart';

class MenuButton extends StatelessWidget {
  const MenuButton({
    super.key,
    required this.title,
    this.leadingIcon,
    this.leadingColor,
    this.onTap,
  });

  final String title;
  final IconData? leadingIcon;
  final Color? leadingColor;
  final Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColor.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(
            children: [
              if (leadingIcon != null) ...[
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: (leadingColor ?? AppColor.primary).withValues(
                      alpha: 0.85,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(leadingIcon, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: AppTextSize.body,
                    color: AppColor.onBackground,
                  ),
                  softWrap: true,
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                color: AppColor.onSurfaceVariant,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
