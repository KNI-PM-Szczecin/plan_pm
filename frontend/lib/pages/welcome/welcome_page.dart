// Ekran powitalny — ikona, nazwa i hasło aplikacji oraz jeden przycisk.
// Zapisuje "skip_welcome" i przechodzi do [RoleSelectionPage].
import 'package:flutter/material.dart';
import 'package:plan_pm/global/theme/colors.dart';
import 'package:plan_pm/global/theme/typography.dart';
import 'package:plan_pm/global/widgets/app_button.dart';
import 'package:plan_pm/global/widgets/app_icon_tile.dart';
import 'package:plan_pm/global/widgets/app_screen_header.dart';
import 'package:plan_pm/l10n/app_localizations.dart';
import 'package:plan_pm/pages/welcome/role_selection_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  Future<void> _continue(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("skip_welcome", true);
    if (!context.mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RoleSelectionPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColor.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppScreenHeader(
                          leading: const AppIconTile(),
                          leadingSpacing: 28,
                          maxTextWidth: 340,
                          title: "Plan PM",
                          titleStyle: AppTextStyle.largeTitleEmphasized,
                          subtitle: l10n.welcomeTagline,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              AppButton(
                label: l10n.welcomeButton,
                onPressed: () => _continue(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
