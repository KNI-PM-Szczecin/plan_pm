import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:plan_pm/global/colors.dart';
import 'package:plan_pm/global/student.dart';
import 'package:plan_pm/global/widgets/navigation_bar.dart';
import 'package:plan_pm/pages/home/home_page.dart';
import 'package:plan_pm/pages/lectures/lectures_page.dart';
import 'package:plan_pm/pages/settings/settings_page.dart';
import 'package:plan_pm/pages/news/news_page.dart';
import 'package:plan_pm/pages/welcome/input_page.dart';
import 'package:plan_pm/pages/welcome/welcome_page.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:plan_pm/l10n/app_localizations.dart';
import 'package:plan_pm/secrets.dart';
import 'package:plan_pm/service/cache_service.dart';
import 'package:preload_page_view/preload_page_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Funkcja odpowiada za inicjalizację aplikacji na wejściu - robi wszystkie rzeczy, a następnie zdejmuje splashScreen
Future<Widget> appInitialization() async {
  print("[APP-INIT] Start");
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  // Jezeli nie ma flagi skip_welcome to znaczy, ze uzytkownik jest pierwszy raz w apce
  if (!prefs.containsKey("skip_welcome")) {
    return const WelcomePage();
  }

  Student.course = prefs.getString("course");
  Student.degreeCourse = prefs.getString("degree_course");
  Student.faculty = prefs.getString("faculty");
  Student.specialisation = prefs.getString("specialisation");
  Student.year = prefs.getInt("year");
  Student.term = prefs.getString("term");
  Student.degreeLevel = prefs.getString("degree_level");
  Student.selectedGroups = prefs.getStringList("groups");

  // Sprawdź czy student ma wszystkie mozliwe wypełnione dane
  final bool allFieldsArePresent =
      Student.course != null &&
      Student.degreeCourse != null &&
      Student.faculty != null &&
      Student.specialisation != null &&
      Student.year != null &&
      Student.term != null &&
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
    print("[APP-INIT] Caching error: $error");
  }

  return const MyHomePage(title: "Strona główna");
}

Future<void> main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  if (Secrets.supabaseUrl.isEmpty || Secrets.supabaseAnonKey.isEmpty) {
    print(
      "Secrets file is not defined! Visit secrets_example.dart for more information!",
    );
    return;
  }

  await Supabase.initialize(
    url: Secrets.supabaseUrl,
    anonKey: Secrets.supabaseAnonKey,
  );
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      themeMode: ThemeMode.system,
      title: 'Plan PM',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: "Inter",
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: ColorThemes.lightPrimary,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        fontFamily: "Inter",
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: ColorThemes.darkPrimary,
          brightness: Brightness.dark,
        ),
      ),

      builder: (context, child) {
        return Builder(
          builder: (BuildContext innerContext) {
            final brightness = Theme.of(innerContext).brightness;
            AppColor.update(brightness);
            return child!;
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
  Widget build(BuildContext context) {
    final pages = getPages(context);
    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        backgroundColor: AppColor.background,
        actions: <Widget>[
          IconButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
            icon: Icon(
              LucideIcons.settings,
              color: AppColor.onBackgroundVariant,
            ),
          ),
        ],
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
