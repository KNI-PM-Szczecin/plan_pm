// Główna powłoka nawigacyjna aplikacji — AppBar z hamburgerem, Sidebar, BottomBar i PageView.
// Sidebar używa AnimationController — treść przesuwa się w prawo, sidebar wsuwa się z lewej.

import 'dart:ui' show ImageFilter;

import 'package:cupertino_native/cupertino_native.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:plan_pm/api/models/announcement_model.dart';
import 'package:plan_pm/changelog.dart';
import 'package:plan_pm/env_config.dart';
import 'package:plan_pm/global/pages/external_link_page.dart';
import 'package:plan_pm/global/theme/colors.dart';
import 'package:plan_pm/global/widgets/announcement_dialog.dart';
import 'package:plan_pm/global/widgets/navigation_bar.dart';
import 'package:plan_pm/global/widgets/sidebar.dart';
import 'package:plan_pm/global/widgets/whats_new_dialog.dart';
import 'package:plan_pm/l10n/app_localizations.dart';
import 'package:plan_pm/pages/home/home_page.dart';
import 'package:plan_pm/pages/lectures/lectures_page.dart';
import 'package:plan_pm/pages/news/news_page.dart';
import 'package:plan_pm/pages/settings/settings_page.dart';
import 'package:plan_pm/global/utils/routing.dart';
import 'package:plan_pm/service/backend_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:preload_page_view/preload_page_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

List<Map<String, dynamic>> getPages(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  return [
    {"widget": const HomePage(), "title": l10n.pageTitleHome},
    {"widget": const LecturesPage(), "title": l10n.pageTitleLectures},
    {"widget": const NewsPage(), "title": l10n.pageTitleNews},
  ];
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late final AnimationController _sidebarController;
  late final Animation<Offset> _sidebarSlide;
  late final Animation<Offset> _contentSlide;
  final PreloadPageController _preloadPageController = PreloadPageController(
    initialPage: 0,
  );

  @override
  void initState() {
    super.initState();
    _sidebarController = AnimationController(
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 220),
      vsync: this,
    );
    _sidebarSlide =
        Tween<Offset>(begin: const Offset(-1.0, 0.0), end: Offset.zero).animate(
          CurvedAnimation(parent: _sidebarController, curve: Curves.easeOut),
        );
    _contentSlide =
        Tween<Offset>(begin: Offset.zero, end: const Offset(0.85, 0.0)).animate(
          CurvedAnimation(parent: _sidebarController, curve: Curves.easeOut),
        );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _checkWhatsNew();
      await _checkAnnouncement();
    });
  }

  @override
  void dispose() {
    _sidebarController.dispose();
    _preloadPageController.dispose();
    super.dispose();
  }

  void _openSidebar() => _sidebarController.forward();
  void _closeSidebar() => _sidebarController.reverse();

  Future<void> _checkWhatsNew() async {
    final info = await PackageInfo.fromPlatform();
    final version = info.version;
    if (!mounted) return;
    final locale = Localizations.localeOf(context);
    final changes = await loadChangelogForLocale(version, locale);

    if (kDebugWhatsNew) {
      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => WhatsNewDialog(version: version, changes: changes),
      );
      return;
    }

    if (changes.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final lastSeen = prefs.getString('last_whats_new_version');

    if (lastSeen == null) {
      await prefs.setString('last_whats_new_version', version);
      return;
    }
    if (lastSeen == version) return;

    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => WhatsNewDialog(version: version, changes: changes),
    );
    await prefs.setString('last_whats_new_version', version);
  }

  Future<void> _checkAnnouncement() async {
    final AnnouncementModel? announcement;

    if (kDebugAnnouncement) {
      announcement = AnnouncementModel(
        id: 'debug',
        title: switch (kDebugAnnouncementType) {
          'warning' => 'Uwaga!',
          'update' => 'Dostępna aktualizacja!',
          _ => 'Komunikat systemowy',
        },
        message: switch (kDebugAnnouncementType) {
          'warning' =>
            'Trwają prace serwisowe dla kierunku Mechatronika. Przepraszamy za utrudnienia.',
          'update' =>
            'Wprowadziliśmy nowe funkcje i poprawiliśmy wydajność. Zaktualizuj aplikację do najnowszej wersji, aby działała jeszcze lepiej.',
          _ => 'Mamy dla Ciebie ważną informację. Sprawdź szczegóły poniżej.',
        },
        type: kDebugAnnouncementType,
        storeUrl: 'https://example.com',
      );
    } else {
      announcement = await BackendService().fetchAnnouncement();
      if (announcement == null) return;
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString('dismissed_announcement') == announcement.id) return;
    }

    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AnnouncementDialog(announcement: announcement!),
    );

    if (!kDebugAnnouncement) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('dismissed_announcement', announcement.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = getPages(context);
    final l10n = AppLocalizations.of(context)!;
    final sidebarWidth = MediaQuery.of(context).size.width * 0.85;

    return Stack(
      children: [
        // ── Main content ─────────────────────────────────────────────
        SlideTransition(
          position: _contentSlide,
          child: Scaffold(
            extendBody: true,
            extendBodyBehindAppBar: true,
            backgroundColor: AppColor.background,
            appBar: AppBar(
              systemOverlayStyle: Theme.of(context).brightness == Brightness.light
                  ? SystemUiOverlayStyle.dark
                  : SystemUiOverlayStyle.light,
              backgroundColor: Colors.transparent,
              forceMaterialTransparency: true,
              shape: Border(bottom: BorderSide(color: AppColor.outline)),
              flexibleSpace: Builder(
                builder: (context) {
                  final isLight = Theme.of(context).brightness == Brightness.light;
                  return ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        color: AppColor.background.withValues(alpha: isLight ? 0.92 : 0.5),
                      ),
                    ),
                  );
                },
              ),
              leading: Builder(
                builder: (ctx) => defaultTargetPlatform == TargetPlatform.iOS
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: CNButton.icon(
                            icon: const CNSymbol('line.3.horizontal', size: 20),
                            style: CNButtonStyle.glass,
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              _openSidebar();
                            },
                          ),
                        ),
                      )
                    : IconButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          _openSidebar();
                        },
                        icon: Icon(
                          LucideIcons.menu,
                          color: AppColor.onBackgroundVariant,
                        ),
                      ),
              ),
              centerTitle: true,
              title: Text(
                pages[_currentIndex]['title'],
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColor.onBackground,
                ),
              ),
            ),
            bottomNavigationBar: defaultTargetPlatform == TargetPlatform.iOS
                ? CNTabBar(
                    tint: AppColor.primary,
                    currentIndex: _currentIndex,
                    onTap: (newIndex) {
                      setState(() => _currentIndex = newIndex);
                      _preloadPageController.animateToPage(
                        newIndex,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                      );
                    },
                    items: [
                      CNTabBarItem(
                        label: l10n.pageTitleHome,
                        icon: const CNSymbol('house.fill'),
                      ),
                      CNTabBarItem(
                        label: l10n.pageTitleLectures,
                        icon: const CNSymbol('calendar'),
                      ),
                      CNTabBarItem(
                        label: l10n.pageTitleNews,
                        icon: const CNSymbol('newspaper'),
                      ),
                    ],
                  )
                : CustomNavigationBar(
                    index: _currentIndex,
                    onChange: (newIndex) {
                      setState(() => _currentIndex = newIndex);
                      _preloadPageController.animateToPage(
                        newIndex,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                      );
                    },
                  ),
            body: Stack(
              children: [
                PreloadPageView.builder(
                  itemCount: pages.length,
                  itemBuilder: (context, index) => pages[index]["widget"],
                  preloadPagesCount: 2,
                  onPageChanged: (value) {
                    setState(() => _currentIndex = value);
                  },
                  controller: _preloadPageController,
                ),
                // Left-edge drag zone to open sidebar — does not compete with PageView swipes
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  width: 30,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onHorizontalDragEnd: (details) {
                      if ((details.primaryVelocity ?? 0) > 300) _openSidebar();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Scrim + Sidebar ───────────────────────────────────────────
        AnimatedBuilder(
          animation: _sidebarController,
          builder: (_, _) {
            if (_sidebarController.value == 0) return const SizedBox.shrink();
            return Stack(
              children: [
                // Scrim — tap to close
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _closeSidebar,
                  child: Container(
                    color: Colors.black.withAlpha(
                      (_sidebarController.value * 150).round(),
                    ),
                  ),
                ),
                // Sidebar with drag-to-close
                SlideTransition(
                  position: _sidebarSlide,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragUpdate: (details) {
                      _sidebarController.value =
                          (_sidebarController.value +
                                  details.delta.dx / sidebarWidth)
                              .clamp(0.0, 1.0);
                    },
                    onHorizontalDragEnd: (details) {
                      final v = details.primaryVelocity ?? 0;
                      if (v < -500 || _sidebarController.value < 0.5) {
                        _closeSidebar();
                      } else {
                        _openSidebar();
                      }
                    },
                    child: Sidebar(
                      onPeTap: () {
                        _closeSidebar();
                        Navigator.push(
                          context,
                          appRoute(
                            (_) => ExternalLinkPage(
                              url: 'https://wf-zajecia.am.szczecin.pl/login',
                              icon: LucideIcons.dumbbell,
                              title: l10n.pePageTitle,
                              description: l10n.pePageDescription,
                              buttonLabel: l10n.pePageButton,
                            ),
                          ),
                        );
                      },
                      onStudentIdTap: () {
                        _closeSidebar();
                        Navigator.push(
                          context,
                          appRoute(
                            (_) => ExternalLinkPage(
                              url: 'https://mlegitymacja.am.szczecin.pl',
                              icon: LucideIcons.creditCard,
                              title: l10n.studentIdPageTitle,
                              description: l10n.studentIdPageDescription,
                              buttonLabel: l10n.studentIdPageButton,
                            ),
                          ),
                        );
                      },
                      onVirtualUniversityTap: () {
                        _closeSidebar();
                        Navigator.push(
                          context,
                          appRoute(
                            (_) => ExternalLinkPage(
                              url: 'https://wu.pm.szczecin.pl',
                              icon: LucideIcons.landmark,
                              title: l10n.virtualUniversityPageTitle,
                              description:
                                  l10n.virtualUniversityPageDescription,
                              buttonLabel: l10n.virtualUniversityPageButton,
                            ),
                          ),
                        );
                      },
                      onSettingsTap: () {
                        _closeSidebar();
                        Navigator.push(
                          context,
                          appRoute((_) => const SettingsPage()),
                        );
                      },
                      onWhatsNewTap: () async {
                        _closeSidebar();
                        final info = await PackageInfo.fromPlatform();
                        final version = info.version;
                        if (!context.mounted) return;
                        final locale = Localizations.localeOf(context);
                        final changes = await loadChangelogForLocale(
                          version,
                          locale,
                        );
                        if (!context.mounted) return;
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => WhatsNewDialog(
                            version: version,
                            changes: changes,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
