// Główna powłoka nawigacyjna aplikacji — AppBar z hamburgerem, Sidebar, BottomBar i PageView.
// Przy pierwszym renderze sprawdza dialog "Co nowego" i ogłoszenia systemowe.
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

class _MyHomePageState extends State<MyHomePage> {
  int _currentIndex = 0;
  final PreloadPageController _preloadPageController = PreloadPageController(
    initialPage: 0,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _checkWhatsNew();
      await _checkAnnouncement();
    });
  }

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
    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        backgroundColor: AppColor.background,
        leading: Builder(
          builder: (context) => IconButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              Scaffold.of(context).openDrawer();
            },
            icon: Icon(LucideIcons.menu, color: AppColor.onBackgroundVariant),
          ),
        ),
        centerTitle: true,
        forceMaterialTransparency: true,
        shape: Border(bottom: BorderSide(color: AppColor.outline)),
        title: Text(
          pages[_currentIndex]['title'],
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColor.onBackground,
          ),
        ),
      ),
      drawer: Sidebar(
        onPeTap: () {
          Navigator.of(context).pop();
          final l10n = AppLocalizations.of(context)!;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ExternalLinkPage(
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
          Navigator.of(context).pop();
          final l10n = AppLocalizations.of(context)!;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ExternalLinkPage(
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
          Navigator.of(context).pop();
          final l10n = AppLocalizations.of(context)!;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ExternalLinkPage(
                url: 'https://wu.pm.szczecin.pl',
                icon: LucideIcons.landmark,
                title: l10n.virtualUniversityPageTitle,
                description: l10n.virtualUniversityPageDescription,
                buttonLabel: l10n.virtualUniversityPageButton,
              ),
            ),
          );
        },
        onSettingsTap: () {
          Navigator.of(context).pop();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SettingsPage()),
          );
        },
        onWhatsNewTap: () async {
          Navigator.of(context).pop();
          final info = await PackageInfo.fromPlatform();
          final version = info.version;
          if (!context.mounted) return;
          final locale = Localizations.localeOf(context);
          final changes = await loadChangelogForLocale(version, locale);
          if (!context.mounted) return;
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => WhatsNewDialog(version: version, changes: changes),
          );
        },
      ),
      bottomNavigationBar: CustomNavigationBar(
        index: _currentIndex,
        onChange: (newIndex) {
          setState(() {
            _currentIndex = newIndex;
          });
          _preloadPageController.animateToPage(
            newIndex,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        },
      ),
      body: PreloadPageView.builder(
        itemCount: pages.length,
        itemBuilder: (context, index) => pages[index]["widget"],
        preloadPagesCount: 2,
        onPageChanged: (value) {
          setState(() {
            _currentIndex = value;
          });
        },
        controller: _preloadPageController,
      ),
    );
  }
}
