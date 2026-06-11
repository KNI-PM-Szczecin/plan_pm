// Jednorazowy, blokujący ekran zgody RODO — pokazywany raz przy pierwszym uruchomieniu.
// Użytkownik musi zaakceptować, żeby kontynuować; nie można go zamknąć przyciskiem wstecz.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:plan_pm/global/theme/colors.dart';
import 'package:plan_pm/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GdprConsentPage extends StatelessWidget {
  const GdprConsentPage({super.key, this.nextPage, this.onAccepted})
      : assert(nextPage != null || onAccepted != null);

  // Normal flow: replace this route with nextPage after acceptance.
  final Widget? nextPage;
  // Debug/override flow: pop this route and call the callback instead.
  final VoidCallback? onAccepted;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColor.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.security_rounded,
                    size: 48,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.gdprTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColor.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Text(
                      l10n.gdprBody,
                      style: TextStyle(
                        color: AppColor.onSurface,
                        height: 1.6,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50.0),
                    backgroundColor: colorScheme.primaryContainer,
                    foregroundColor: colorScheme.onPrimaryContainer,
                  ),
                  onPressed: () async {
                    HapticFeedback.lightImpact();
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString("gdpr_consent", "true");
                    if (!context.mounted) return;
                    if (onAccepted != null) {
                      Navigator.of(context).pop();
                      onAccepted!();
                    } else {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => nextPage!),
                      );
                    }
                  },
                  child: Text(l10n.gdprAccept),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
