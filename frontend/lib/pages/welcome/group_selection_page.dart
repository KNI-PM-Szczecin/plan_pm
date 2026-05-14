// Wybór grup zajęciowych studenta — siatka przycisków pogrupowanych po typie (A/C/L/inne).
// W każdej kategorii można wybrać dokładnie jedną grupę.
// Po zapisaniu persystuje wybór i synchronizuje dane przez [CacheService].
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:plan_pm/global/theme/colors.dart';
import 'package:plan_pm/global/models/student.dart';
import 'package:plan_pm/global/widgets/app_bar.dart';
import 'package:plan_pm/global/widgets/states/generic_no_resource.dart';
import 'package:plan_pm/pages/home/home_shell.dart';
import 'package:plan_pm/pages/welcome/widgets/group_builder.dart';
import 'package:plan_pm/pages/welcome/widgets/onboarding_action_bar.dart';
import 'package:plan_pm/global/models/app_mode.dart';
import 'package:plan_pm/global/notifiers/notifiers.dart';
import 'package:plan_pm/service/backend_service.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:plan_pm/service/cache_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plan_pm/l10n/app_localizations.dart';

class GroupSelectionPage extends StatelessWidget {
  const GroupSelectionPage({super.key, this.isRoleSwitch = false});

  final bool isRoleSwitch;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final backendService = BackendService();
    Student.selectedGroups = [];
    return Scaffold(
      backgroundColor: AppColor.background,
      appBar: CustomAppBar(title: l10n.groupSettings),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.miniCenterFloat,
      floatingActionButton: OnboardingActionBar(
        skipLabel: l10n.skipButton,
        onSkip: () async {
          HapticFeedback.lightImpact();
          if (isRoleSwitch) {
            await AppModeManager.setMode(AppMode.student);
            sevenDayModeNotifier.value = false;
          }
          if (!context.mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => const MyHomePage(title: "Plan PM"),
            ),
            (r) => false,
          );
        },
        confirmLabel: l10n.save,
        onConfirm: () async {
          HapticFeedback.lightImpact();
          if (isRoleSwitch) {
            await AppModeManager.setMode(AppMode.student);
            sevenDayModeNotifier.value = false;
          }
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setStringList("groups", Student.selectedGroups ?? []);
          await CacheService().syncNews();
          await CacheService().syncLectures();
          if (!context.mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => const MyHomePage(title: "Plan PM"),
            ),
            (r) => false,
          );
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: SingleChildScrollView(
          child: Column(
            spacing: 10,
            children: [
              Text(
                l10n.groupSelectionHint,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColor.onBackgroundVariant,
                ),
              ),
              FutureBuilder(
                future: backendService.fetchGroups(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      decoration: BoxDecoration(
                        color: AppColor.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DottedBorder(
                        options: RoundedRectDottedBorderOptions(
                          radius: const Radius.circular(12),
                          dashPattern: const [10, 5],
                          color: AppColor.outline,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            spacing: 5,
                            children: [
                              LoadingAnimationWidget.progressiveDots(
                                color: AppColor.onSurfaceVariant,
                                size: 48,
                              ),
                              Text(
                                l10n.groupLoading,
                                style: TextStyle(
                                  color: AppColor.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  if (snapshot.hasError || snapshot.data == null) {
                    return GenericNoResource(
                      label: l10n.unexpectedError,
                      icon: LucideIcons.wifiOff,
                      description: l10n.networkErrorDescription,
                    );
                  }
                  final data = snapshot.data!;
                  if (data.isEmpty) {
                    return GenericNoResource(
                      label: l10n.noGroupsAvailable,
                      icon: LucideIcons.alertCircle,
                      description: l10n.noGroupsAvailableDescription,
                    );
                  }

                  final groups = data
                      .map((g) {
                        final group = g.toString();
                        final first = group.split("/")[0];
                        final key = first.isNotEmpty ? first[0] : "";
                        return {
                          key: [
                            {"short": first, "long": group},
                          ],
                        };
                      })
                      .fold<Map<String, List<Map<String, String>>>>({}, (
                        acc,
                        elem,
                      ) {
                        elem.forEach((k, v) {
                          acc.putIfAbsent(k, () => []).addAll(v);
                        });
                        return acc;
                      });

                  return Column(
                    spacing: 10,
                    children: [GroupBuilder(groups: groups)],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
