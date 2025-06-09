import 'package:flutter/material.dart';

class FacultyDropDownMenu extends StatefulWidget {
  const FacultyDropDownMenu({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.hint,
    required this.itemList,
    this.enabled = true,
    this.onChanged,
    this.selectedValue,
    required this.controller,
  });

  final String label;
  final IconData icon;
  final Color color;
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
    
    return Column(
      spacing: 5,
      children: [
        Row(
          spacing: 5,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(widget.icon, color: widget.color, size: 16,),
            Text(
              widget.label,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ],
        ),
        DropdownMenu(
          enabled: widget.enabled!,
          controller: widget.controller,
          initialSelection: widget.selectedValue,
          hintText: widget.hint,
          onSelected: widget.onChanged,
          menuStyle: MenuStyle(),
          width: double.infinity,
          inputDecorationTheme: InputDecorationTheme(
            hintStyle: TextStyle(fontWeight: FontWeight.w500),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white70),
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
          ),

          dropdownMenuEntries: widget.itemList
              .map(
                (faculty) => DropdownMenuEntry(value: faculty, label: faculty, leadingIcon: faculty == widget.selectedValue ? Icon(Icons.check) : null),
              )
              .toList(),
        ),
      ],
    );
  }
}
