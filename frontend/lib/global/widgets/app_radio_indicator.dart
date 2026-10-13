// Kółko wyboru pojedynczego: puste obramowanie albo wypełnione akcentem
// z haczykiem. Sam wskaźnik — tap obsługuje wiersz, w którym leży.
import 'package:flutter/material.dart';
import 'package:plan_pm/global/theme/colors.dart';

class AppRadioIndicator extends StatelessWidget {
  const AppRadioIndicator({super.key, required this.selected, this.size = 22});

  final bool selected;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? AppColor.primary : Colors.transparent,
        border: selected
            ? null
            : Border.all(color: AppColor.labelTertiary, width: 1.5),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 150),
        transitionBuilder: (child, animation) => ScaleTransition(
          scale: animation,
          child: FadeTransition(opacity: animation, child: child),
        ),
        child: selected
            ? Icon(
                Icons.check_rounded,
                key: const ValueKey('check'),
                size: size * 0.7,
                color: Colors.white,
              )
            : const SizedBox.shrink(key: ValueKey('empty')),
      ),
    );
  }
}
