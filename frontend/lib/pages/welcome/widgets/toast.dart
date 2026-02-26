import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:plan_pm/global/colors.dart';

// ########################################
// DEPRECATED - COULD BE USED IN THE FUTURE
// ########################################

class Toast extends StatelessWidget {
  const Toast({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.green.withAlpha(100)),
        borderRadius: BorderRadius.circular(12),
        color: Colors.lightGreen.withAlpha(50),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 10,
          children: [
            Icon(
              LucideIcons.checkCircle2,
              size: 30,
              color: Colors.green.withAlpha(255),
            ),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Plan znaleziony!",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                  ),
                  Text(
                    "Znalezliśmy twój plan. Teraz wybierz po jedną grupę z kazdej kategorii.",
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColor.onPrimaryVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
