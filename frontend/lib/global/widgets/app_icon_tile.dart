// Ikona aplikacji (delfin) w kafelku o kształcie ikony z ekranu głównego —
// ekran powitalny, a w przyszłości np. „O aplikacji".
//
// Kafelek jest biały w obu motywach (jak prawdziwa ikona), obrys [AppColor.separator]
// oddziela go od białego tła w jasnym motywie.
import 'package:flutter/material.dart';
import 'package:plan_pm/global/theme/colors.dart';

class AppIconTile extends StatelessWidget {
  const AppIconTile({super.key, this.size = 120});

  final double size;

  @override
  Widget build(BuildContext context) {
    // Proporcja promienia ikon iOS (~22,5% boku).
    final radius = BorderRadius.circular(size * 0.225);
    return Container(
      width: size,
      height: size,
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedSuperellipseBorder(
          borderRadius: radius,
          side: BorderSide(color: AppColor.separator),
        ),
      ),
      // Delfin na przezroczystym tle; margines jak na ikonie z launchera.
      padding: EdgeInsets.all(size * 0.06),
      child: Image.asset(
        'assets/logo_light.png',
        fit: BoxFit.contain,
        // Obrazek jest dekoracją — nazwa aplikacji stoi obok jako tekst.
        excludeFromSemantics: true,
      ),
    );
  }
}
