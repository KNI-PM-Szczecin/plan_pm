// Dropdown menu z obsługą stanu wyłączonego i zaznaczenia aktywnego elementu checkmarkiem.
// Używany w [InputPage] dla wydziału, kierunku i specjalizacji.
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:plan_pm/global/theme/colors.dart';

class FacultyDropDownMenu extends StatefulWidget {
  const FacultyDropDownMenu({
    super.key,
    required this.label,
    required this.icon,
    required this.hint,
    required this.itemList,
    this.enabled = true,
    this.onChanged,
    this.selectedValue,
    required this.controller,
  });

  final String label;
  final IconData icon;
  final String hint;
  final List<String> itemList;
  final bool? enabled;
  final ValueChanged<String?>? onChanged;
  final String? selectedValue;
  final TextEditingController controller;

  @override
  State<FacultyDropDownMenu> createState() => _FacultyDropDownMenuState();
}

class _FacultyDropDownMenuState extends State<FacultyDropDownMenu> {
  @override
  Widget build(BuildContext context) {
    final bool isEnabled = widget.enabled ?? true;
    final Color disabledFillColor = Color.alphaBlend(
      Colors.black.withAlpha(70),
      AppColor.surface,
    );
    final Color disabledForegroundColor = AppColor.onSurfaceVariant.withAlpha(
      110,
    );

    return Column(
      spacing: 5,
      children: [
        Row(
          spacing: 5,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 14,
                color: AppColor.onBackgroundVariant,
              ),
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: isEnabled ? AppColor.surface : disabledFillColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownMenu(
            trailingIcon: Icon(
              LucideIcons.chevronDown,
              color: isEnabled ? AppColor.onSurface : disabledForegroundColor,
            ),
            enabled: isEnabled,
            controller: widget.controller,
            initialSelection: widget.selectedValue,
            hintText: widget.hint,
            onSelected: widget.onChanged,
            menuStyle: MenuStyle(
              backgroundColor: WidgetStatePropertyAll(AppColor.surface),
            ),
            textStyle: TextStyle(
              color: isEnabled ? AppColor.onSurface : disabledForegroundColor,
            ),
            width: double.infinity,
            inputDecorationTheme: InputDecorationTheme(
              hintStyle: TextStyle(
                color: isEnabled
                    ? AppColor.onSurfaceVariant
                    : disabledForegroundColor,
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColor.outline),
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),

              disabledBorder: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              filled: true,
              fillColor: isEnabled ? AppColor.surface : disabledFillColor,
              helperStyle: TextStyle(color: Colors.red),

              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
            ),

            dropdownMenuEntries: widget.itemList
                .map(
                  (faculty) => DropdownMenuEntry(
                    style: MenuItemButton.styleFrom(
                      foregroundColor: AppColor.onSurface,
                    ),
                    value: faculty,
                    label: faculty,
                    leadingIcon: faculty == widget.selectedValue
                        ? Icon(Icons.check, color: AppColor.onSurfaceVariant)
                        : null,
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}
