import 'package:flutter/material.dart';
import 'package:plan_pm/global/notifiers.dart';
import 'package:plan_pm/global/widgets/navigation_bar.dart';
import 'package:plan_pm/pages/home/home_page.dart';
import 'package:plan_pm/pages/lectures/lectures_page.dart';
import 'package:plan_pm/pages/menu/menu_page.dart';
import 'package:plan_pm/pages/welcome/welcome_page.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  // Tutaj jest głowa aplikacji, najlepiej aby nic nie zmieniać.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Plan PM',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const WelcomePage(),
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

// To jest lista ze wszystkimi stronami i ich tytułami. W przyszłości będzie mozna dodać więcej parametrów.
List<Map<String, dynamic>> pages = [
  {"widget": const HomePage(), "title": "Home"},
  {"widget": const LecturesPage(), "title": "Lectures"},
  {"widget": const MenuPage(), "title": "Menu"},
];

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    // Jezeli wartosc notifiera selectedTab sie zmieni - przebuduj cala strone.
    return ValueListenableBuilder(
      builder: (context, selectedTab, child) {
        return Scaffold(
          appBar: AppBar(
            // Tytul jest brany dynamicznie z listy pages.
            title: Text(pages[selectedTab]['title']),
          ),
          bottomNavigationBar: CustomNavigationBar(),
          body: pages[selectedTab]['widget'],
        );
      },
      // Wartość, którą zmian nasłuchujemy
      valueListenable: Notifiers.selectedTab,
    );
  }
}
