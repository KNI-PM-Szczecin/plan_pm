import 'package:cupertino_native/cupertino_native.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:plan_pm/global/theme/colors.dart';

class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final callback = onPressed ?? () => Navigator.of(context).pop();
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: CNButton.icon(
            icon: const CNSymbol('chevron.left', size: 20),
            style: CNButtonStyle.glass,
            onPressed: () {
              HapticFeedback.lightImpact();
              callback();
            },
          ),
        ),
      );
    }
    return IconButton(
      icon: Icon(LucideIcons.chevronLeft, color: AppColor.onBackgroundVariant),
      onPressed: callback,
    );
  }
}
