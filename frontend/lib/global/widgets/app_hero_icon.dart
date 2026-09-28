// Duża ikona w kolorowym kółku nad tytułem ekranu (onboarding, puste stany).
// Zmiana [icon] lub [color] animuje się sama — np. ikona idzie za wyborem na liście.
import 'package:flutter/material.dart';

class AppHeroIcon extends StatelessWidget {
  const AppHeroIcon({
    super.key,
    required this.icon,
    required this.color,
    this.size = 72,
  });

  final IconData icon;
  final Color color;
  final double size;

  static const _duration = Duration(milliseconds: 200);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: _duration,
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: AnimatedSwitcher(
        duration: _duration,
        transitionBuilder: (child, animation) => ScaleTransition(
          scale: Tween(begin: 0.6, end: 1.0).animate(animation),
          child: FadeTransition(opacity: animation, child: child),
        ),
        child: Icon(
          icon,
          key: ValueKey(icon),
          size: size * 0.5,
          color: Colors.white,
        ),
      ),
    );
  }
}
