// Pasek nawigacji podstron (iOS 27 Flat): „wstecz" po lewej, tytuł headline
// na środku, bez linii pod spodem. Tło przezroczyste — pasek przejmuje kolor
// tła Scaffoldu, więc pasuje i do zwykłych, i do grupowanych ekranów.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:plan_pm/global/theme/colors.dart';
import 'package:plan_pm/global/theme/typography.dart';
import 'package:plan_pm/global/widgets/back_button.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.bottom,
    this.onBack,
  });

  /// `null` = sam przycisk powrotu (ekran ma własny duży nagłówek w treści).
  final String? title;
  final Widget? leading;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final VoidCallback? onBack;

  static const double height = 52;

  @override
  Size get preferredSize =>
      Size.fromHeight(height + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return AppBar(
      systemOverlayStyle: brightness == Brightness.light
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
      toolbarHeight: height,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      // 16 pt marginesu + 44 pt przycisku.
      leadingWidth: 60,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Center(child: leading ?? AppBackButton(onPressed: onBack)),
      ),
      centerTitle: true,
      title: title == null
          ? null
          : Text(
              title!,
              style: AppTextStyle.headline.copyWith(
                color: AppColor.onBackground,
              ),
            ),
      actions: [...?actions, const SizedBox(width: 16)],
      bottom: bottom,
    );
  }
}
