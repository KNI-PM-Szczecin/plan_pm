// Wspólny feedback dotyku dla komponentów `App*`. Design jest jeden, ale
// reakcja na dotyk należy do platformy:
//   iOS     — [AppPressFeedback.dim] przygasza treść, [AppPressFeedback.highlight]
//             podświetla tło (komórka listy),
//   Android — zawsze ripple (InkWell) przycięty do [shape].
//
// Tło elementu podawaj przez [color], nie w [child]: ripple rysuje się na
// Material pod dziećmi, więc kolorowy kontener w środku by go zasłonił.
import 'package:flutter/material.dart';
import 'package:plan_pm/global/theme/colors.dart';
import 'package:plan_pm/global/utils/platform.dart';

enum AppPressFeedback {
  /// Przycisk — cały element blednie.
  dim,

  /// Wiersz listy — tło dostaje [AppColor.fillQuaternary].
  highlight,
}

class AppPressable extends StatefulWidget {
  const AppPressable({
    super.key,
    required this.child,
    required this.onTap,
    this.feedback = AppPressFeedback.dim,
    this.shape = const RoundedRectangleBorder(),
    this.color = Colors.transparent,
  });

  final Widget child;

  /// `null` = element nieaktywny (bez feedbacku).
  final VoidCallback? onTap;
  final AppPressFeedback feedback;

  /// Kształt tła; do niego przycinany jest ripple i podświetlenie.
  final ShapeBorder shape;
  final Color color;

  @override
  State<AppPressable> createState() => _AppPressableState();
}

class _AppPressableState extends State<AppPressable> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    if (!isApplePlatform) {
      return Material(
        color: widget.color,
        shape: widget.shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(onTap: widget.onTap, child: widget.child),
      );
    }

    final highlight = widget.feedback == AppPressFeedback.highlight && _pressed;
    final Widget content = AnimatedContainer(
      duration: Duration(milliseconds: _pressed ? 0 : 200),
      decoration: ShapeDecoration(
        shape: widget.shape,
        color: highlight
            ? Color.alphaBlend(AppColor.fillQuaternary, widget.color)
            : widget.color,
      ),
      child: widget.child,
    );

    final enabled = widget.onTap != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => _setPressed(true) : null,
      onTapUp: enabled ? (_) => _setPressed(false) : null,
      onTapCancel: enabled ? () => _setPressed(false) : null,
      onTap: widget.onTap,
      child: widget.feedback == AppPressFeedback.dim
          ? AnimatedOpacity(
              opacity: _pressed ? 0.6 : 1,
              duration: Duration(milliseconds: _pressed ? 0 : 150),
              child: content,
            )
          : content,
    );
  }
}
