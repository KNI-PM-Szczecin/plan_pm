// Pozioma karta wyboru z animacją naciśnięcia — używana w [LanguagePage] i podobnych.
// [leading] to ikona lub emoji po lewej, [label] to tekst po prawej.
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:plan_pm/global/theme/colors.dart';

class SelectionCard extends StatefulWidget {
  const SelectionCard({
    super.key,
    required this.leading,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final Widget leading;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<SelectionCard> createState() => _SelectionCardState();
}

class _SelectionCardState extends State<SelectionCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? AppColor.primary.withAlpha(25)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isSelected ? AppColor.primary : AppColor.outline,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              widget.leading,
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    color: widget.isSelected
                        ? AppColor.primary
                        : AppColor.onSurface,
                    fontWeight: widget.isSelected
                        ? FontWeight.w600
                        : FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
              ),
              if (widget.isSelected)
                Icon(LucideIcons.checkCircle2, color: AppColor.primary, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}
