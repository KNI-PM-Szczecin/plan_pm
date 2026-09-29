// Okienko nowego designu: karta na przyciemnionym tle, ikona w kolorowym
// kółku, tytuł, opis, opcjonalna własna treść (np. lista zmian w „Co nowego")
// i przyciski — główny oraz opcjonalny tekstowy pod nim.
//
// Kolor kółka niesie typ komunikatu (info / ostrzeżenie / aktualizacja),
// bez gradientów.
import 'package:flutter/material.dart';
import 'package:plan_pm/global/theme/colors.dart';
import 'package:plan_pm/global/theme/typography.dart';
import 'package:plan_pm/global/widgets/app_button.dart';

Future<T?> showAppDialog<T>({
  required BuildContext context,
  required IconData icon,
  required Color iconColor,
  required String title,
  String? message,
  Widget? content,
  required String primaryLabel,
  required VoidCallback onPrimary,
  String? secondaryLabel,
  VoidCallback? onSecondary,
  bool barrierDismissible = false,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: AppColor.overlay,
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, _, _) => AppDialog(
      icon: icon,
      iconColor: iconColor,
      title: title,
      message: message,
      content: content,
      primaryLabel: primaryLabel,
      onPrimary: onPrimary,
      secondaryLabel: secondaryLabel,
      onSecondary: onSecondary,
    ),
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween(begin: 0.92, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    this.message,
    this.content,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? message;
  final Widget? content;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  static const double radius = 34;

  @override
  Widget build(BuildContext context) {
    final hasSecondary = secondaryLabel != null;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 36),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Material(
            color: AppColor.groupedSurface,
            shape: RoundedSuperellipseBorder(
              borderRadius: BorderRadius.circular(radius),
            ),
            child: Padding(
              // Tekstowy przycisk ma własne 44 pt wysokości — dół jest ciaśniejszy.
              padding: EdgeInsets.fromLTRB(20, 28, 20, hasSecondary ? 12 : 20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 6,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: iconColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 28, color: Colors.white),
                    ),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: AppTextStyle.headline.copyWith(
                        color: AppColor.onSurface,
                      ),
                    ),
                    if (message != null)
                      Text(
                        message!,
                        textAlign: TextAlign.center,
                        style: AppTextStyle.subheadline.copyWith(
                          color: AppColor.labelSecondary,
                        ),
                      ),
                    if (content != null)
                      Padding(
                        // Pod opisem treść odsunięta; bez opisu (np. „Co nowego"
                        // z numerem wersji w treści) przylega do tytułu.
                        padding: EdgeInsets.only(top: message != null ? 12 : 0),
                        child: content,
                      ),
                    const SizedBox(height: 12),
                    AppButton(label: primaryLabel, onPressed: onPrimary),
                    if (hasSecondary)
                      AppButton(
                        label: secondaryLabel!,
                        variant: AppButtonVariant.plain,
                        onPressed: onSecondary ?? () {},
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
