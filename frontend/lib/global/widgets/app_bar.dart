import 'package:flutter/material.dart';
import 'package:plan_pm/global/theme/colors.dart';
import 'package:plan_pm/global/widgets/back_button.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    required this.title,
    this.leading,
    this.actions,
    this.bottom,
    this.onBack,
  });

  final String title;
  final Widget? leading;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final VoidCallback? onBack;

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColor.background,
      automaticallyImplyLeading: false,
      leading: leading ?? AppBackButton(onPressed: onBack),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w600, color: AppColor.onBackground),
      ),
      shape: Border(bottom: BorderSide(color: AppColor.outline)),
      actions: actions,
      bottom: bottom,
    );
  }
}
