import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:plan_pm/global/theme/colors.dart';
import 'package:plan_pm/global/models/student.dart';
import 'package:plan_pm/global/widgets/states/generic_no_resource.dart';
import 'package:plan_pm/main.dart';
import 'package:plan_pm/pages/welcome/widgets/group_builder.dart';
import 'package:plan_pm/service/backend_service.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:plan_pm/service/cache_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:plan_pm/l10n/app_localizations.dart';

ButtonStyle buttonStyle = ButtonStyle(
  shape: WidgetStatePropertyAll(
    RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(12)),
  ),
);

String longToShort(String long) {
  final pieces = long
      .split(",")
      .map((piece) => piece.split("/")[0])
      .toString()
      .replaceAll("(", "")
      .replaceAll(")", "");

  return pieces;
}

class GroupSelectionPage extends StatelessWidget {
  const GroupSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final backendService = BackendService();
    Student.selectedGroups = [];
    return Scaffold(
      backgroundColor: AppColor.background,
      floatingActionButtonLocation:
          FloatingActionButtonLocation.miniCenterFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          spacing: 10,
          children: [
            Expanded(
              child: SizedBox(
                height: 50,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: AppColor.surface,
                  ),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColor.outline),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const MyHomePage(title: "Plan PM"),
                        ),
                        (r) => false,
                      );
                    },
                    child: Text(
                      l10n.skipButton,
                      style: TextStyle(color: AppColor.onSurface),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: SizedBox(
                height: 50,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColor.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadiusGeometry.circular(16),
                    ),
                  ),
                  onPressed: () async {
                    HapticFeedback.lightImpact();
                    final SharedPreferences prefs =
                        await SharedPreferences.getInstance();
                    await prefs.setStringList(
                      "groups",
                      Student.selectedGroups ?? [],
                    );

                    final CacheService cacheService = CacheService();
                    await cacheService.syncNews();
                    await cacheService.syncLectures();

                    if (!context.mounted) return;
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const MyHomePage(title: "Plan PM"),
                      ),
                      (r) => false,
                    );
                  },
                  child: Text(
                    l10n.save,
                    style: TextStyle(color: AppColor.onPrimary),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      appBar: AppBar(
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
        backgroundColor: AppColor.background,
        shape: Border(bottom: BorderSide(color: AppColor.outline)),
        title: Text(
          l10n.groupSettings,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColor.onBackground,
          ),
        ),
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
                          radius: Radius.circular(12),
                          dashPattern: [10, 5],
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
                  if (snapshot.hasError) {
                    return GenericNoResource(
                      label: l10n.unexpectedError,
                      icon: LucideIcons.wifiOff,
                      description: l10n.networkErrorDescription,
                    );
                  }
                  if (snapshot.data == null) {
                    return Center(child: Text("Null"));
                  }
                  final data = snapshot.data!;

                  final groups = data
                      .map((g) {
                        final group = g.toString();
                        final first = group.split("/")[0];
                        final shortName = first;
                        final longName = group;
                        final key = shortName.isNotEmpty ? shortName[0] : "";

                        return {
                          key: [
                            {"short": shortName, "long": longName},
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
