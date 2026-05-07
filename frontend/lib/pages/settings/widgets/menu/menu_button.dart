// Klikalny wiersz w menu ustawień — opcjonalna ikona z kolorowym tłem po lewej, chevron po prawej.
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:plan_pm/global/theme/colors.dart';

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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              if (leadingIcon != null) ...[
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: leadingColor ?? AppColor.primary,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Icon(leadingIcon, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(color: AppColor.onSurface),
                  softWrap: true,
                ),
              ),
              Icon(LucideIcons.chevronRight, color: AppColor.onSurfaceVariant, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
