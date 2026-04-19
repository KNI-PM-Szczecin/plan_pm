import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:plan_pm/global/notifiers.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:plan_pm/global/colors.dart';
import 'package:plan_pm/global/student.dart';
import 'package:plan_pm/global/widgets/navigation_bar.dart';
import 'package:plan_pm/pages/home/home_page.dart';
import 'package:plan_pm/pages/lectures/lectures_page.dart';
import 'package:plan_pm/pages/settings/pe_page.dart';
import 'package:plan_pm/pages/settings/student_id_page.dart';
import 'package:plan_pm/pages/settings/virtual_university_page.dart';
import 'package:plan_pm/pages/settings/settings_page.dart';
import 'package:plan_pm/pages/news/news_page.dart';
import 'package:plan_pm/pages/welcome/input_page.dart';
import 'package:plan_pm/pages/welcome/welcome_page.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:plan_pm/l10n/app_localizations.dart';
import 'package:plan_pm/secrets.dart';
import 'package:plan_pm/env_config.dart';
import 'package:plan_pm/service/cache_service.dart';
import 'package:preload_page_view/preload_page_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:plan_pm/global/logger.dart';
import 'package:plan_pm/api/models/announcement_model.dart';

import 'package:plan_pm/global/widgets/announcement_dialog.dart';
import 'package:plan_pm/global/widgets/whats_new_dialog.dart';
import 'package:plan_pm/service/backend_service.dart';
import 'package:plan_pm/changelog.dart';
import 'package:package_info_plus/package_info_plus.dart';

// Funkcja odpowiada za inicjalizację aplikacji na wejściu - robi wszystkie rzeczy, a następnie zdejmuje splashScreen
Future<Widget> appInitialization() async {
  AppLogger.i("[APP-INIT] Start");
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  // Jezeli nie ma flagi skip_welcome to znaczy, ze uzytkownik jest pierwszy raz w apce
  if (!prefs.containsKey("skip_welcome")) {
    return const WelcomePage();
  }

  Student.course = prefs.getString("course");
  Student.degreeCourse = prefs.getString("degree_course");
  Student.faculty = prefs.getString("faculty");
  String? spec = prefs.getString("specialisation");
  Student.specialisation = (spec != null && spec.isNotEmpty) ? spec : null;
  Student.year = prefs.getInt("year");

  final String? rawStudyMode =
      prefs.getString("study_mode") ?? prefs.getString("term");
  Student.studyMode = switch (rawStudyMode) {
    "S" || "Stacjonarne" => StudyMode.stationary,
    "N" || "Niestacjonarne" => StudyMode.notStationary,
    _ => null,
  };
  Student.degreeLevel = prefs.getString("degree_level");
  Student.selectedGroups = prefs.getStringList("groups");

  // Sprawdź czy student ma wszystkie mozliwe wypełnione dane
  final bool allFieldsArePresent =
      Student.course != null &&
      Student.degreeCourse != null &&
      Student.faculty != null &&
      Student.year != null &&
      Student.studyMode != null &&
      Student.selectedGroups != null;

  // Jezeli uzytkownik nie ma danych o kierunku to przenieś go do InputPage
  if (!allFieldsArePresent) {
    return const InputPage();
  }

  try {
    final cacheService = CacheService();
    await cacheService.syncLectures();
    await cacheService.syncNews();
  } catch (error) {
    AppLogger.e("[APP-INIT] Caching error", error);
  }

  return const MyHomePage(title: "Strona główna");
}

Future<void> main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  if (Secrets.supabaseUrl.isEmpty || Secrets.supabaseAnonKey.isEmpty) {
    AppLogger.e(
      "Secrets file is not defined! Visit secrets_example.dart for more information!",
    );
    return;
  }

  await Supabase.initialize(
    url: Secrets.supabaseUrl,
    anonKey: Secrets.supabaseAnonKey,
  );

  themeNotifier = ThemeNotifier();
  await themeNotifier.loadFromPrefs();

  localeNotifier = LocaleNotifier();
  await localeNotifier.loadFromPrefs();

  accentColorNotifier = AccentColorNotifier();
  await accentColorNotifier.loadFromPrefs();

  amoledModeNotifier = AmoledModeNotifier();
  await amoledModeNotifier.loadFromPrefs();

  eventColorStyleNotifier = EventColorStyleNotifier();
  await eventColorStyleNotifier.loadFromPrefs();

  await SevenDayModeNotifier.init();

  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale?>(
      valueListenable: localeNotifier,
      builder: (context, currentLocale, _) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: themeNotifier,
          builder: (context, currentThemeMode, _) {
            return MaterialApp(
              locale: currentLocale,
              themeMode: currentThemeMode,
              title: 'Plan PM',
              debugShowCheckedModeBanner: kUseTestDb,
              theme: ThemeData(
                fontFamily: "Inter",
                brightness: Brightness.light,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: AppColor.primary,
                  brightness: Brightness.light,
                ),
              ),
              darkTheme: ThemeData(
                fontFamily: "Inter",
                brightness: Brightness.dark,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: AppColor.primary,
                  brightness: Brightness.dark,
                ),
              ),

              builder: (context, child) {
                return Builder(
                  builder: (BuildContext innerContext) {
                    final brightness = Theme.of(innerContext).brightness;
                    AppColor.update(brightness);
                    return KeyedSubtree(
                      key: ValueKey(brightness),
                      child: AppRebuilder(child: child!),
                    );
                  },
                );
              },

              localizationsDelegates: [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: [
                Locale('en'), // English
                Locale('pl'), // Polish
                Locale('uk'), // Ukrainian
              ],
              home: FutureBuilder<Widget>(
                future: appInitialization(),
                builder: (context, AsyncSnapshot<Widget> screen) {
                  if (screen.connectionState != ConnectionState.done) {
                    return Container(color: AppColor.background);
                  }
                  FlutterNativeSplash.remove();
                  // Zwróć odpowiednią stronę
                  return screen.data!;
                },
              ),
            );
          },
        );
      },
    );
  }
}

// To jest nasz główny widok aplikacji. Tutaj mamy zakładki, po których będzie mozna się poruszać w apce.
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

List<Map<String, dynamic>> getPages(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  return [
    {"widget": const HomePage(), "title": l10n.pageTitleHome},
    {"widget": const LecturesPage(), "title": l10n.pageTitleLectures},
    {"widget": const NewsPage(), "title": l10n.pageTitleNews},
  ];
}
// prze†łumaczyć date w today Lectures
// przetlumaczyc date w dayselection

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
    final changes = kChangelog[version] ?? kChangelog.values.last;

    if (kDebugWhatsNew) {
      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => WhatsNewDialog(version: version, changes: changes),
      );
      return;
    }

    if (kChangelog[version] == null) return;

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
          'warning' => 'Trwają prace serwisowe dla kierunku Mechatronika. Przepraszamy za utrudnienia.',
          'update' => 'Wprowadziliśmy nowe funkcje i poprawiliśmy wydajność. Zaktualizuj aplikację do najnowszej wersji, aby działała jeszcze lepiej.',
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
            icon: Icon(
              LucideIcons.menu,
              color: AppColor.onBackgroundVariant,
            ),
          ),
        ),
        centerTitle: true,
        forceMaterialTransparency: true,
        shape: Border(bottom: BorderSide(color: AppColor.outline)),
        // Tytul jest brany dynamicznie z listy pages.
        title: Text(
          pages[_currentIndex]['title'],
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColor.onBackground,
          ),
        ),
      ),
      drawer: CustomSidebar(
        onPeTap: () {
          Navigator.of(context).pop();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PePage()),
          );
        },
        onStudentIdTap: () {
          Navigator.of(context).pop();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const StudentIdPage()),
          );
        },
        onVirtualUniversityTap: () {
          Navigator.of(context).pop();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const VirtualUniversityPage()),
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
          final changes = kChangelog[version] ?? kChangelog.values.last;
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

class AppRebuilder extends StatefulWidget {
  final Widget child;
  const AppRebuilder({super.key, required this.child});

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
    // PL: Wymuszamy rebuild wszystkich elementów drzewa, bo klasa AppColor używa pól statycznych.
    // PL: Bez tego GUI nie odświeżałoby się od razu po zmianie motywu, tylko po zmianie zakładki.
    // EN: We force a complete rebuild of the element tree because AppColor is based on static fields.
    // EN: Without this, the UI wouldn't magically update right after changing the theme but on tab change.
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
  Widget build(BuildContext context) {
    return widget.child;
  }
}
