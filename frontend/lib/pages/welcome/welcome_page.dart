// Onboarding carousel — 4 slajdy z animacjami Lottie przedstawiające funkcje aplikacji.
// Po ostatnim slajdzie zapisuje "skip_welcome" i przechodzi do [RoleSelectionPage].
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:plan_pm/global/theme/colors.dart';
import 'package:plan_pm/pages/welcome/role_selection_page.dart';
import 'package:plan_pm/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  // PageController musi być w state — tworzenie go w build() resetuje pozycję przy każdym rebuildie.
  late final PageController _controller = PageController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context).colorScheme;
    final List<Map<String, dynamic>> stages = [
      {
        "title": l10n.stage1Title,
        "lottie": "assets/lotties/calendar.json",
        "buttonLabel": l10n.stage1Button,
        "color": Colors.blueAccent,
        "colorLight": Colors.blue,
      },
      {
        "title": l10n.stage2Title,
        "lottie": "assets/lotties/womanschedule.json",
        "buttonLabel": l10n.stage2Button,
        "color": Colors.redAccent,
        "colorLight": Colors.red,
      },
      {
        "title": l10n.stage3Title,
        "lottie": "assets/lotties/search.json",
        "buttonLabel": l10n.stage3Button,
        "color": Colors.amberAccent,
        "colorLight": Colors.amber,
      },
      {
        "title": l10n.stage4Title,
        "lottie": "assets/lotties/bell.json",
        "buttonLabel": l10n.stage4Button,
        "color": Colors.green,
        "colorLight": Colors.green,
      },
    ];

    return Scaffold(
      backgroundColor: AppColor.background,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SafeArea(
          child: PageView.builder(
            controller: _controller,
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
                          borderRadius: BorderRadius.circular(100),
                          color: theme.brightness == Brightness.dark
                              ? stages[index]["color"].withAlpha(50)
                              : stages[index]["colorLight"].withAlpha(150),
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
                        style: TextStyle(color: AppColor.onSurface),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(300, 50.0),
                      backgroundColor: theme.brightness == Brightness.dark
                          ? stages[index]["color"].withAlpha(100)
                          : stages[index]["colorLight"],
                    ),
                    onPressed: () async {
                      HapticFeedback.lightImpact();
                      if (index == stages.length - 1) {
                        final SharedPreferences prefs =
                            await SharedPreferences.getInstance();
                        await prefs.setBool("skip_welcome", true);
                        if (!context.mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RoleSelectionPage(),
                          ),
                        );
                      }
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeIn,
                      );
                    },
                    child: Text(
                      stages[index]["buttonLabel"]!,
                      style: TextStyle(color: AppColor.onPrimary),
                    ),
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
