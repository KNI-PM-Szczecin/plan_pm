import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:plan_pm/global/colors.dart';
import 'package:plan_pm/pages/feedback/feedback_page.dart';
import 'package:plan_pm/pages/settings/widgets/group_info.dart';
import 'package:plan_pm/pages/settings/widgets/menu_button.dart';
import 'package:plan_pm/pages/settings/widgets/menu_section.dart';
import 'package:plan_pm/pages/settings/widgets/student_info.dart';
import 'package:plan_pm/pages/welcome/welcome_page.dart';
import 'package:plan_pm/l10n/app_localizations.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: AppBar(
        backgroundColor: AppColor.background,
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(
            LucideIcons.chevronLeft,
            color: AppColor.onBackgroundVariant,
          ),
        ),
        title: Text(
          l10n.pageTitleSettings,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColor.onBackground,
          ),
        ),
        shape: Border(bottom: BorderSide(color: AppColor.outline)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                spacing: 10,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  StudentInfo(),
                  GroupInfo(),
                  MenuSection(
                    title: l10n.feedbackHeader,
                    child: MenuButton(
                      title: l10n.sendFeedbackButton,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FeedbackPage(),
                          ),
                        );
                      },
                    ),
                  ),
                  // MenuSection(
                  //   title: l10n.debugHeader,
                  //   child: MenuButton(
                  //     title: "Powrót do Welcome Screen",
                  //     onTap: () {
                  //       HapticFeedback.lightImpact();
                  //       Navigator.push(
                  //         context,
                  //         MaterialPageRoute(
                  //           builder: (context) => const WelcomePage(),
                  //         ),
                  //       );
                  //     },
                  //   ),
                  // ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
