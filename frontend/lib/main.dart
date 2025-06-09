import 'package:flutter/material.dart';
import 'package:plan_pm/global/student.dart';
import 'package:plan_pm/welcome/welcome_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: const WelcomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          spacing: 20,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Dane studenta to: '),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 10,
                children: [
                  Column(
                    spacing: 5,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Wydział",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "Kierunek",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "Specjalizacja",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "Rok",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "Tryb studiów",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  Column(
                    spacing: 5,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      SizedBox(
                        width: 250,
                        child: Text(Student.faculty ?? "Brak danych"),
                      ),
                      SizedBox(
                        width: 250,
                        child: Text(Student.degreeCourse ?? "Brak danych"),
                      ),
                      SizedBox(
                        width: 250,
                        child: Text(Student.specialisation ?? "Brak danych"),
                      ),
                      Text(
                        Student.year != 0
                            ? Student.year.toString()
                            : "Brak danych",
                      ),
                      Text(Student.term ?? "Brak danych"),
                    ],
                  ),
                ],
              ),
            ),
            Text(
              "Piotr Wittig was here.",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
