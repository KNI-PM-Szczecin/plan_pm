import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:plan_pm/welcome/input_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> stages = [
      {
        "title": " ",
        "lottie": "assets/lotties/calendar.json",
        "buttonLabel": "Witaj w Plan PM",
        "color": Colors.blueAccent
      },
      {
        "title": "Zobacz wszystkie zajęcia w przejrzystym planie tygodniowym.",
        "lottie": "assets/lotties/womanschedule.json",
        "buttonLabel": "Dalej",
        "color": Colors.redAccent
      },
      {
        "title":
            "Znajdź swoje sale łatwo dzięki szczegółowym informacjom o lokalizacji.",
        "lottie": "assets/lotties/search.json",
        "buttonLabel": "Dalej",
        "color": Colors.amberAccent,
      },
      {
        "title":
            "Otrzymuj przypomnienia przed kadymi zajęciami, zeby nigdy ich nie przegapić.",
        "lottie": "assets/lotties/bell.json",
        "buttonLabel": "Rozpocznij",
        "color": Colors.green,
      },
    ];
    final PageController controller = PageController();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SafeArea(
          child: PageView.builder(
            controller: controller,
            itemCount: stages.length,
            itemBuilder: (context, index) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    spacing: 10,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(9999),
                          color: stages[index]["color"].withAlpha(50)
                        ),

                        child: Lottie.asset(
                          stages[index]["lottie"]!,
                          
                          width: 250,
                          height: 250,
                        ),
                      ),
                      Text(
                        stages[index]["title"]!,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: Size(double.infinity, 50.0),
                      backgroundColor: stages[index]["color"]
                    ),
                    onPressed: () {
                      if (index == stages.length - 1) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const InputPage(),
                          ),
                        );
                      }
                      controller.nextPage(
                        duration: Duration(milliseconds: 250),
                        curve: Curves.easeIn,
                      );
                    },
                    child: Text(stages[index]["buttonLabel"]!),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
