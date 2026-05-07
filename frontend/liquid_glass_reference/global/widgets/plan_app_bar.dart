import 'package:flutter/material.dart';
import 'package:plan_pm/global/colors.dart';
import 'package:plan_pm/global/widgets/glass_back_button.dart';

class PlanAppBar extends StatelessWidget implements PreferredSizeWidget {
  const PlanAppBar({
    super.key,
    required this.title,
    this.leading,
    this.actions,
    this.bottom,
  });

  final String title;
  final Widget? leading;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColor.background,
      automaticallyImplyLeading: false,
      leading: leading ?? const GlassBackButton(),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: AppColor.onBackground,
        ),
      ),
      shape: Border(bottom: BorderSide(color: AppColor.outline)),
      actions: actions,
      bottom: bottom,
    );
  }
}
