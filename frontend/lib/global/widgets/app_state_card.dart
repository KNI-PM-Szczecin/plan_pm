// Stan zamiast treści: ładowanie, błąd albo brak danych — karta z ikoną
// w szarym kółku, tytułem, opisem i opcjonalną akcją (np. „Spróbuj ponownie").
// Zajmuje miejsce formularza/listy, bez przerywanej ramki (makieta 5c).
//
// Nie mylić z GenericNoResource/GenericLoading — te zostają na ekranach zajęć,
// których redesign nie obejmuje.
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:plan_pm/global/theme/colors.dart';
import 'package:plan_pm/global/theme/typography.dart';
import 'package:plan_pm/global/utils/platform.dart';
import 'package:plan_pm/global/widgets/app_button.dart';
import 'package:plan_pm/global/widgets/app_grouped_section.dart';

class AppStateCard extends StatelessWidget {
  const AppStateCard({
    super.key,
    required this.title,
    this.icon,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  /// Karta ładowania: spinner zamiast ikony, sam tytuł.
  const AppStateCard.loading({super.key, required this.title})
    : icon = null,
      message = null,
      actionLabel = null,
      onAction = null;

  final String title;

  /// `null` = spinner (stan ładowania).
  final IconData? icon;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      decoration: ShapeDecoration(
        color: AppColor.groupedSurface,
        shape: RoundedSuperellipseBorder(
          borderRadius: BorderRadius.circular(AppGroupedSection.radius),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 6,
        children: [
          Container(
            width: 56,
            height: 56,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppColor.fillTertiary,
              shape: BoxShape.circle,
            ),
            child: icon != null
                ? Icon(icon, size: 26, color: AppColor.labelSecondary)
                : Center(
                    child: isApplePlatform
                        ? const CupertinoActivityIndicator()
                        : SizedBox.square(
                            dimension: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColor.labelSecondary,
                            ),
                          ),
                  ),
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyle.headline.copyWith(color: AppColor.onSurface),
          ),
          if (message != null)
            Text(
              message!,
              textAlign: TextAlign.center,
              style: AppTextStyle.subheadline.copyWith(
                color: AppColor.labelSecondary,
              ),
            ),
          if (actionLabel != null) ...[
            const SizedBox(height: 10),
            AppButton(
              label: actionLabel!,
              size: AppButtonSize.small,
              variant: AppButtonVariant.secondary,
              expand: false,
              onPressed: onAction,
            ),
          ],
        ],
      ),
    );
  }
}
