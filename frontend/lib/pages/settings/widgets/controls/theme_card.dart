// Karta wyboru motywu z podglądem obrazka i animacją naciśnięcia.
// Używana w [AppearancePage] — wydzielona bo to niebanalny StatefulWidget.
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:plan_pm/global/theme/colors.dart';

class ThemeCard extends StatefulWidget {
  const ThemeCard({
    super.key,
    required this.title,
    required this.imageAsset,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final String imageAsset;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<ThemeCard> createState() => _ThemeCardState();
}

class _ThemeCardState extends State<ThemeCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.isSelected
                        ? AppColor.primary
                        : Colors.transparent,
                    width: 2.0,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(widget.imageAsset, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        color: widget.isSelected
                            ? AppColor.onSurface
                            : AppColor.onSurfaceVariant,
                        fontWeight: widget.isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.isSelected) ...[
                    const SizedBox(width: 4),
                    Icon(LucideIcons.check, color: AppColor.primary, size: 14),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
