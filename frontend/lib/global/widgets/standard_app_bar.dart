// AppBar z przyciskiem powrotu, współdzielony przez wszystkie podstrony aplikacji.
// Implementuje [PreferredSizeWidget] aby móc być użyty bezpośrednio jako [Scaffold.appBar].
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:plan_pm/global/theme/colors.dart';

class StandardAppBar extends StatelessWidget implements PreferredSizeWidget {
  const StandardAppBar({
    super.key,
    required this.title,
    this.actions,
    this.onBack,
  });

  final String title;
  final List<Widget>? actions;

  /// Opcjonalne nadpisanie domyślnego zachowania przycisku back ([Navigator.pop]).
  final VoidCallback? onBack;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return AppBar(
      systemOverlayStyle: brightness == Brightness.light
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
      backgroundColor: AppColor.background,
      automaticallyImplyLeading: false,
      leading: IconButton(
        onPressed: onBack ?? () => Navigator.pop(context),
        icon: Icon(LucideIcons.chevronLeft, color: AppColor.onBackgroundVariant),
      ),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w600, color: AppColor.onBackground),
      ),
      shape: Border(bottom: BorderSide(color: AppColor.outline)),
      actions: actions,
    );
  }
}
