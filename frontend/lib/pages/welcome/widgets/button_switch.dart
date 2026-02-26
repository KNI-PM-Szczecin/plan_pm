import 'package:flutter/material.dart';
import 'package:plan_pm/global/colors.dart';

class ButtonSwitch extends StatefulWidget {
  const ButtonSwitch({
    super.key,
    required this.icon,
    required this.label,
    required this.buttonAmount,
    required this.buttonLabels,
    required this.onValueChanged,
  });
  final IconData icon;
  final String label;
  final int buttonAmount;
  final List<String> buttonLabels;
  final void Function(int) onValueChanged;
  @override
  State<ButtonSwitch> createState() => _ButtonSwitchState();
}

class _ButtonSwitchState extends State<ButtonSwitch> {
  int? selectedButton;
  @override
  Widget build(BuildContext context) {
    final ButtonStyle unselectedStyle = OutlinedButton.styleFrom(
      backgroundColor: AppColor.surface,
      side: BorderSide(color: AppColor.outline), // outline color
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );

    final ButtonStyle selectedStyle = FilledButton.styleFrom(
      backgroundColor: AppColor.primary,
      foregroundColor: AppColor.onPrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(color: AppColor.onBackgroundVariant, fontSize: 14),
        ),
        const SizedBox(height: 5),
        Row(
          spacing: 10,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int i = 0; i < widget.buttonAmount; i++)
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: selectedButton == i
                      ? FilledButton(
                          style: selectedStyle,
                          onPressed: () {
                            setState(() {
                              selectedButton = i;
                              widget.onValueChanged(i);
                            });
                          },
                          child: Text(
                            widget.buttonLabels[i],
                            style: TextStyle(color: AppColor.onPrimary),
                          ),
                        )
                      : OutlinedButton(
                          style: unselectedStyle,
                          onPressed: () {
                            setState(() {
                              selectedButton = i;
                              widget.onValueChanged(i);
                            });
                          },
                          child: Text(
                            widget.buttonLabels[i],
                            style: TextStyle(color: AppColor.onSurface),
                          ),
                        ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
