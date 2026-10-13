// Mały kolorowy kafelek z białą ikoną albo znakiem (np. numer kroku) —
// początek wiersza listy, jak w Ustawieniach iOS. Kolor niesie znaczenie,
// więc podawaj stały kolor systemowy ([AppColor.systemBlue] itd.), a nie akcent.
import 'package:flutter/material.dart';

class AppIconBadge extends StatelessWidget {
  const AppIconBadge({
    super.key,
    required this.color,
    this.icon,
    this.label,
    this.size = 30,
  }) : assert(
         (icon == null) != (label == null),
         'Podaj dokładnie jedno: icon albo label',
       );

  final Color color;
  final IconData? icon;

  /// Krótki tekst zamiast ikony, np. „1".
  final String? label;

  /// 30 pt w wierszach list, 36 pt przy dwulinijkowych wierszach wyboru.
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: ShapeDecoration(
        color: color,
        shape: RoundedSuperellipseBorder(
          // 8 pt przy 30 pt — proporcja z makiet.
          borderRadius: BorderRadius.circular(size * 0.27),
        ),
      ),
      child: icon != null
          ? Icon(icon, size: size * 0.6, color: Colors.white)
          : Text(
              label!,
              style: TextStyle(
                fontSize: size * 0.47,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
    );
  }
}
