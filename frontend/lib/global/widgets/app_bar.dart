// Pasek nawigacji podstron (iOS 27 Flat): „wstecz" po lewej, tytuł headline
// na środku.
//
// Zachowanie przy przewijaniu („scroll edge", jak w aplikacjach systemowych):
//   * treść na górze — pasek całkiem przezroczysty, bez linii (jak w makiecie),
//   * treść wjechała pod pasek — iOS: blur z półprzezroczystym tłem i cienką
//     linią; Android: pełne tło strony, jak górny pasek w Material 3 (blur na
//     słabszych telefonach potrafi zacinać przewijanie).
// Żeby treść mogła wjechać pod pasek, ekran ustawia
// `Scaffold(extendBodyBehindAppBar: true)`; Scaffold dolicza wtedy wysokość
// paska do `MediaQuery.padding.top` treści.
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:plan_pm/global/theme/colors.dart';
import 'package:plan_pm/global/theme/typography.dart';
import 'package:plan_pm/global/utils/platform.dart';
import 'package:plan_pm/global/widgets/back_button.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.bottom,
    this.onBack,
    this.backgroundColor,
  });

  /// `null` = sam przycisk powrotu (ekran ma własny duży nagłówek w treści).
  final String? title;
  final Widget? leading;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final VoidCallback? onBack;

  /// Tło strony pod paskiem — pasek po przewinięciu przyjmuje ten kolor.
  /// Domyślnie [AppColor.background].
  final Color? backgroundColor;

  static const double height = 52;

  @override
  Size get preferredSize =>
      Size.fromHeight(height + (bottom?.preferredSize.height ?? 0));

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {
  ScrollNotificationObserverState? _observer;
  bool _scrolledUnder = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _observer?.removeListener(_handleScroll);
    _observer = ScrollNotificationObserver.maybeOf(context);
    _observer?.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _observer?.removeListener(_handleScroll);
    super.dispose();
  }

  void _handleScroll(ScrollNotification notification) {
    // Tylko główna, pionowa lista ekranu — nie menu ani poziome karuzele.
    if (notification is! ScrollUpdateNotification || notification.depth != 0) {
      return;
    }
    final metrics = notification.metrics;
    if (metrics.axis != Axis.vertical) return;
    final scrolled = metrics.extentBefore > 0;
    if (scrolled != _scrolledUnder) setState(() => _scrolledUnder = scrolled);
  }

  Widget _background(Color pageColor) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    // Bez Opacity/AnimatedOpacity: BackdropFilter wewnątrz warstwy
    // przezroczystości nie rysuje się na iOS. Animujemy więc wprost siłę
    // blura, krycie tła i linii.
    return TweenAnimationBuilder<double>(
      tween: Tween(end: _scrolledUnder ? 1 : 0),
      duration: const Duration(milliseconds: 180),
      builder: (context, t, _) {
        if (t == 0) return const SizedBox.expand();
        // flexibleSpace dostaje luźne ograniczenia — bez SizedBox.expand
        // ColoredBox bez dziecka zwija się do 0 px i tła nie widać wcale.
        if (!isApplePlatform) {
          return SizedBox.expand(
            child: ColoredBox(color: pageColor.withValues(alpha: t)),
          );
        }
        return SizedBox.expand(
          child: DecoratedBox(
            // Linia na zewnątrz ClipRect/BackdropFilter — inaczej blenduje się z tłem.
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: AppColor.separator.withValues(
                    alpha: AppColor.separator.a * t,
                  ),
                ),
              ),
            ),
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20 * t, sigmaY: 20 * t),
                child: ColoredBox(
                  color: pageColor.withValues(
                    alpha: (isLight ? 0.92 : 0.5) * t,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final pageColor = widget.backgroundColor ?? AppColor.background;
    return AppBar(
      systemOverlayStyle: brightness == Brightness.light
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
      toolbarHeight: CustomAppBar.height,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: _background(pageColor),
      // 16 pt marginesu + 44 pt przycisku.
      leadingWidth: 60,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Center(
          child: widget.leading ?? AppBackButton(onPressed: widget.onBack),
        ),
      ),
      centerTitle: true,
      title: widget.title == null
          ? null
          : Text(
              widget.title!,
              style: AppTextStyle.headline.copyWith(
                color: AppColor.onBackground,
              ),
            ),
      actions: [...?widget.actions, const SizedBox(width: 16)],
      bottom: widget.bottom,
    );
  }
}
