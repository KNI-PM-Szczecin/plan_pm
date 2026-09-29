// Przyciski paska nawigacji dopasowane do platformy:
//   iOS     — natywny przycisk Liquid Glass (CNButton, styl glass). Makiety są
//             płaskie, bo kit „iOS 27 Flat" celowo pominął materiały — sam iOS
//             zostaje przy szkle, a szklany jest też dolny pasek (CNTabBar),
//   Android — zwykły IconButton, jak w aplikacjach systemowych.
// [AppBackButton] — powrót (chevron ‹ / strzałka ←), [AppNavButton] — dowolna
// ikona, np. menu na głównym ekranie.
import 'package:cupertino_native/cupertino_native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:plan_pm/global/theme/colors.dart';
import 'package:plan_pm/global/utils/platform.dart';

class AppNavButton extends StatelessWidget {
  const AppNavButton({
    super.key,
    required this.icon,
    required this.symbol,
    required this.onPressed,
    required this.label,
    this.androidIcon,
  });

  /// Ikona na Androidzie.
  final IconData icon;

  /// Nazwa SF Symbol dla natywnego przycisku na iOS, np. `chevron.left`.
  final String symbol;

  /// Ikona na Androidzie, gdy konwencja platformy jest inna (← zamiast ‹).
  final IconData? androidIcon;
  final VoidCallback onPressed;

  /// Etykieta dla czytników ekranu (i tooltip na Androidzie).
  final String label;

  @override
  Widget build(BuildContext context) {
    if (!isApplePlatform) {
      return IconButton(
        tooltip: label,
        icon: Icon(androidIcon ?? icon, color: AppColor.onBackground),
        onPressed: onPressed,
      );
    }

    return Semantics(
      button: true,
      label: label,
      child: CNButton.icon(
        icon: CNSymbol(symbol, size: 20),
        style: CNButtonStyle.glass,
        onPressed: () {
          HapticFeedback.lightImpact();
          onPressed();
        },
      ),
    );
  }
}

class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return AppNavButton(
      icon: LucideIcons.chevronLeft,
      symbol: 'chevron.left',
      androidIcon: Icons.arrow_back,
      label: MaterialLocalizations.of(context).backButtonTooltip,
      onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
    );
  }
}
