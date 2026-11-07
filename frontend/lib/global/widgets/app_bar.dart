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
    this.scrollEdgeOffset = 0,
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

  /// Treść zaczyna się od elementu na pełną szerokość pod paskiem — okładka
  /// artykułu (hero). Pasek liczy się za „przewinięty" dopiero, gdy lista
  /// przejedzie tyle pikseli (hero minus pasek statusu i pasek): do tego
  /// czasu jest przezroczysty, bez tytułu, a przycisk wstecz pływa nad
  /// obrazem ([AppBackButton.floating]). 0 = zwykły ekran.
  final double scrollEdgeOffset;

  static const double height = 52;

  @override
  Size get preferredSize =>
      Size.fromHeight(height + (bottom?.preferredSize.height ?? 0));

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> with _ScrollEdgeMixin {
  @override
  double get scrollEdgeOffset => widget.scrollEdgeOffset;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final pageColor = widget.backgroundColor ?? AppColor.background;
    final hero = widget.scrollEdgeOffset > 0;
    final overHero = hero && !scrolledUnder;
    final Widget? title = widget.title == null
        ? null
        : Text(
            widget.title!,
            style: AppTextStyle.headline.copyWith(color: AppColor.onBackground),
          );
    return AppBar(
      // Nad hero pasek statusu leży na zdjęciu — jasne ikony (okładki
      // newsów są ciemne); po przewinięciu wraca styl z motywu.
      systemOverlayStyle: overHero || brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
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
          child:
              widget.leading ??
              AppBackButton(onPressed: widget.onBack, floating: overHero),
        ),
      ),
      centerTitle: true,
      // Nad hero tytuł leżałby na zdjęciu — pojawia się razem z tłem.
      title: hero && title != null
          ? AnimatedOpacity(
              opacity: scrolledUnder ? 1 : 0,
              duration: const Duration(milliseconds: 180),
              child: title,
            )
          : title,
      actions: [...?widget.actions, const SizedBox(width: 16)],
      bottom: widget.bottom,
    );
  }
}

/// Pasek zakładek głównego ekranu: okrągły przycisk (menu) w wierszu 52 pt,
/// pod nim duży tytuł z lewej. Tytuł nie zwija się przy przewijaniu — to
/// wymagałoby przebudowy list zakładek (w tym planu zajęć) na slivery;
/// zamiast tego pod paskiem włącza się to samo tło co w [CustomAppBar].
///
/// Stan przewinięcia podaje powłoka ([scrolledUnder]) — zakładki żyją w jednym
/// Scaffoldzie i PageView trzyma je wszystkie, więc pasek nie może sam
/// nasłuchiwać (jak [CustomAppBar]): słyszałby ostatnio przewijaną zakładkę,
/// nie bieżącą, a po zmianie zakładki nie wiedziałby, czy nowa jest
/// przewinięta. Każdą zakładkę owija [ScrollEdgeListener].
class AppLargeTitleBar extends StatelessWidget implements PreferredSizeWidget {
  const AppLargeTitleBar({
    super.key,
    required this.title,
    required this.leading,
    this.scrolledUnder = false,
  });

  final String title;
  final Widget leading;

  /// Czy treść bieżącej zakładki wjechała pod pasek.
  final bool scrolledUnder;

  /// Wiersz tytułu: Large Title 41 pt + 8 pt odstępu pod spodem.
  static const double titleHeight = 49;

  @override
  Size get preferredSize =>
      const Size.fromHeight(CustomAppBar.height + titleHeight);

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
        child: Center(child: leading),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(AppLargeTitleBar.titleHeight),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              // Domyślny layout centruje stary i nowy tytuł względem siebie —
              // tytuły mają różną szerokość, więc krótszy przez czas przejścia
              // stał przesunięty i na końcu „skakał" w lewo.
              layoutBuilder: (current, previous) => Stack(
                alignment: Alignment.centerLeft,
                children: [...previous, ?current],
              ),
              child: Text(
                title,
                key: ValueKey(title),
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

/// Owija treść jednej zakładki i zgłasza przez [onChanged], czy jej główna
/// pionowa lista jest przewinięta (treść pod paskiem). Reaguje też na
/// [ScrollMetricsNotification], więc zakładka zbudowana z już przewiniętą
/// pozycją (PageStorage, powrót do zakładki) zgłasza stan bez ruchu palcem.
/// Nasłuchuje tylko listy bezpośrednio w zakładce (`depth == 0`), nie
/// zagnieżdżonych karuzel.
class ScrollEdgeListener extends StatelessWidget {
  const ScrollEdgeListener({
    super.key,
    required this.onChanged,
    required this.child,
  });

  final ValueChanged<bool> onChanged;
  final Widget child;

  bool _report(ScrollMetrics metrics, int depth) {
    if (depth == 0 && metrics.axis == Axis.vertical) {
      onChanged(metrics.hasPixels && metrics.extentBefore > 0);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: (n) => _report(n.metrics, n.depth),
      child: NotificationListener<ScrollUpdateNotification>(
        onNotification: (n) => _report(n.metrics, n.depth),
        child: child,
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

  /// Ile pikseli przewinięcia mieści się „nad" paskiem, zanim treść wjedzie
  /// pod niego (hero na pełną szerokość). 0 = pasek od razu nad treścią.
  double get scrollEdgeOffset => 0;

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
    scrolledUnder = metrics.extentBefore > scrollEdgeOffset;
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
