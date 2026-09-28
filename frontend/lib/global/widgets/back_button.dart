// Przycisk powrotu dopasowany do platformy:
//   iOS     — płaskie kółko 44 pt z chevronem (iOS 27 Flat, bez Liquid Glass),
//   Android — zwykły IconButton ze strzałką ←, jak w aplikacjach systemowych.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:plan_pm/global/theme/colors.dart';
import 'package:plan_pm/global/utils/platform.dart';
import 'package:plan_pm/global/widgets/app_pressable.dart';

class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final callback = onPressed ?? () => Navigator.of(context).maybePop();
    final label = MaterialLocalizations.of(context).backButtonTooltip;

    if (!isApplePlatform) {
      return IconButton(
        tooltip: label,
        icon: Icon(Icons.arrow_back, color: AppColor.onBackground),
        onPressed: callback,
      );
    }

    return Semantics(
      button: true,
      label: label,
      child: AppPressable(
        color: AppColor.fillTertiary,
        shape: const CircleBorder(),
        onTap: () {
          HapticFeedback.lightImpact();
          callback();
        },
        child: SizedBox.square(
          dimension: 44,
          child: Icon(
            LucideIcons.chevronLeft,
            size: 24,
            color: AppColor.onBackground,
          ),
        ),
      ),
    );
  }
}
