// Wymusza pełny rebuild drzewa widgetów po zmianie motywu, języka lub koloru akcentu.
// Konieczne bo AppColor używa pól statycznych — bez tego UI odświeżałoby się dopiero
// przy zmianie zakładki, a nie od razu po zmianie ustawień.
import 'package:flutter/material.dart';
import 'package:plan_pm/global/notifiers/notifiers.dart';

class AppRebuilder extends StatefulWidget {
  const AppRebuilder({super.key, required this.child});

  final Widget child;

  @override
  State<AppRebuilder> createState() => _AppRebuilderState();
}

class _AppRebuilderState extends State<AppRebuilder> {
  @override
  void initState() {
    super.initState();
    themeNotifier.addListener(_rebuildAll);
    localeNotifier.addListener(_rebuildAll);
    accentColorNotifier.addListener(_rebuildAll);
    amoledModeNotifier.addListener(_rebuildAll);
    eventColorStyleNotifier.addListener(_rebuildAll);
  }

  @override
  void dispose() {
    themeNotifier.removeListener(_rebuildAll);
    localeNotifier.removeListener(_rebuildAll);
    accentColorNotifier.removeListener(_rebuildAll);
    amoledModeNotifier.removeListener(_rebuildAll);
    eventColorStyleNotifier.removeListener(_rebuildAll);
    super.dispose();
  }

  void _rebuildAll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      void rebuild(Element el) {
        el.markNeedsBuild();
        el.visitChildren(rebuild);
      }
      (context as Element).visitChildren(rebuild);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
