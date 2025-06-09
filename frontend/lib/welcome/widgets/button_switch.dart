import 'package:flutter/material.dart';

class ButtonSwitch extends StatefulWidget {
  const ButtonSwitch({
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    required this.buttonAmount,
    required this.buttonLabels,
    required this.onValueChanged
  });
  final IconData icon;
  final Color color;
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
    ButtonStyle buttonStyle = ButtonStyle(
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(12)),
      ),
    );

    return Column(
      spacing: 10,
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
        SizedBox(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 10,
            children: [
              for (int i = 0; i < widget.buttonAmount; i++)
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: selectedButton == i
                        ? FilledButton(
                            style: buttonStyle,
                            onPressed: () {
                              setState(() {
                                selectedButton = i;
                                widget.onValueChanged(i);
                              });
                            },
                            child: Text(widget.buttonLabels[i]),
                          )
                        : OutlinedButton(
                            style: buttonStyle,
                            onPressed: () {
                              setState(() {
                                selectedButton = i;
                                widget.onValueChanged(i);
                              });
                            },
                            child: Text(widget.buttonLabels[i]),
                          ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
