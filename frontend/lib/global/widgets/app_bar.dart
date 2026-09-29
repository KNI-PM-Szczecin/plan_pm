// Paski nawigacji (iOS 27 Flat):
//   * [CustomAppBar] — podstrony: „wstecz" po lewej, tytuł headline na środku,
//   * [AppLargeTitleBar] — zakładki głównego ekranu: przycisk menu i pod nim
//     duży tytuł z lewej (Strona główna, Zajęcia, Nowości).
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

class _CustomAppBarState extends State<CustomAppBar> with _ScrollEdgeMixin {
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
      flexibleSpace: ScrollEdgeBackground(
        scrolledUnder: scrolledUnder,
        color: pageColor,
      ),
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

/// Pasek zakładek głównego ekranu: okrągły przycisk (menu) w wierszu 52 pt,
/// pod nim duży tytuł z lewej. Tytuł nie zwija się przy przewijaniu — to
/// wymagałoby przebudowy list zakładek (w tym planu zajęć) na slivery;
/// zamiast tego pod paskiem włącza się to samo tło co w [CustomAppBar].
class AppLargeTitleBar extends StatefulWidget implements PreferredSizeWidget {
  const AppLargeTitleBar({
    super.key,
    required this.title,
    required this.leading,
    this.resetKey,
  });

  final String title;
  final Widget leading;

  /// Zmiana tej wartości (np. indeksu zakładki) zeruje stan przewinięcia —
  /// nowa zakładka zaczyna z przezroczystym paskiem.
  final Object? resetKey;

  /// Wiersz tytułu: Large Title 41 pt + 8 pt odstępu pod spodem.
  static const double titleHeight = 49;

  @override
  Size get preferredSize =>
      const Size.fromHeight(CustomAppBar.height + titleHeight);

  @override
  State<AppLargeTitleBar> createState() => _AppLargeTitleBarState();
}

class _AppLargeTitleBarState extends State<AppLargeTitleBar>
    with _ScrollEdgeMixin {
  // Listy zakładek siedzą w PageView (poziomy scrollable = depth 0), więc
  // ich pionowe przewijanie przychodzi z depth 1.
  @override
  int get scrollDepth => 1;

  @override
  void didUpdateWidget(AppLargeTitleBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.resetKey != widget.resetKey) scrolledUnder = false;
  }

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
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
      flexibleSpace: ScrollEdgeBackground(
        scrolledUnder: scrolledUnder,
        color: AppColor.background,
      ),
      leadingWidth: 60,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Center(child: widget.leading),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(AppLargeTitleBar.titleHeight),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: Text(
                widget.title,
                key: ValueKey(widget.title),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyle.largeTitleEmphasized.copyWith(
                  color: AppColor.onBackground,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Nasłuchuje przewijania głównej listy ekranu (przez ScrollNotificationObserver
/// Scaffoldu) i trzyma [scrolledUnder] — czy treść wjechała pod pasek.
mixin _ScrollEdgeMixin<T extends StatefulWidget> on State<T> {
  ScrollNotificationObserverState? _observer;
  bool _scrolledUnder = false;

  bool get scrolledUnder => _scrolledUnder;
  set scrolledUnder(bool value) {
    if (value != _scrolledUnder) setState(() => _scrolledUnder = value);
  }

  /// Głębokość scrollable, którego słuchamy (0 = bezpośrednio w body).
  int get scrollDepth => 0;

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
    if (notification is! ScrollUpdateNotification ||
        notification.depth != scrollDepth) {
      return;
    }
    final metrics = notification.metrics;
    if (metrics.axis != Axis.vertical) return;
    scrolledUnder = metrics.extentBefore > 0;
  }
}

/// Tło paska zależne od przewinięcia: przezroczyste na górze, po przewinięciu
/// iOS — blur z półprzezroczystym [color] i cienką linią, Android — pełny [color].
class ScrollEdgeBackground extends StatelessWidget {
  const ScrollEdgeBackground({
    super.key,
    required this.scrolledUnder,
    required this.color,
  });

  final bool scrolledUnder;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    // Bez Opacity/AnimatedOpacity: BackdropFilter wewnątrz warstwy
    // przezroczystości nie rysuje się na iOS. Animujemy więc wprost siłę
    // blura, krycie tła i linii.
    return TweenAnimationBuilder<double>(
      tween: Tween(end: scrolledUnder ? 1 : 0),
      duration: const Duration(milliseconds: 180),
      builder: (context, t, _) {
        if (t == 0) return const SizedBox.expand();
        // flexibleSpace dostaje luźne ograniczenia — bez SizedBox.expand
        // ColoredBox bez dziecka zwija się do 0 px i tła nie widać wcale.
        if (!isApplePlatform) {
          return SizedBox.expand(
            child: ColoredBox(color: color.withValues(alpha: t)),
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
                  color: color.withValues(alpha: (isLight ? 0.92 : 0.5) * t),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
