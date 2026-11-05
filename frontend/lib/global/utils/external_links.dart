// Adresy stron zewnętrznych otwieranych z aplikacji — w jednym miejscu, bo
// część skrótów jest zarówno w menu bocznym, jak i w ustawieniach.
import 'package:flutter/material.dart';
import 'package:plan_pm/global/utils/logger.dart';
import 'package:plan_pm/l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';

abstract final class ExternalLinks {
  static const physicalEducation = 'https://wf-zajecia.am.szczecin.pl/login';
  static const studentId = 'https://mlegitymacja.am.szczecin.pl';
  static const virtualUniversity = 'https://wu.pm.szczecin.pl';
  static const feedbackForm = 'https://forms.gle/E8sLgZ1X49kaX5jA6';
}

/// Otwiera [url] w przeglądarce (poza aplikacją). `false`, gdy system odmówił
/// albo rzucił (`PlatformException` — brak przeglądarki, zły URL); `launchUrl`
/// zgłasza odmowę raz jako `false`, a raz wyjątkiem, więc łapiemy oba.
Future<bool> openExternalLink(String url) async {
  try {
    return await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
  } catch (error, stackTrace) {
    AppLogger.w("[LINKS] Nie udało się otworzyć $url", error, stackTrace);
    return false;
  }
}

/// Jak [openExternalLink], ale przy porażce pokazuje snackbar
/// „Nie udało się otworzyć linku". [message] nadpisuje treść.
Future<void> openExternalLinkOrNotify(
  BuildContext context,
  String url, {
  String? message,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (!await openExternalLink(url)) {
    messenger?.showSnackBar(
      SnackBar(content: Text(message ?? l10n.couldNotOpenLink)),
    );
  }
}
