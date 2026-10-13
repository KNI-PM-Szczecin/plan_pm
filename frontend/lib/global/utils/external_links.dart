// Adresy stron zewnętrznych otwieranych z aplikacji — w jednym miejscu, bo
// część skrótów jest zarówno w menu bocznym, jak i w ustawieniach.
import 'package:url_launcher/url_launcher.dart';

abstract final class ExternalLinks {
  static const physicalEducation = 'https://wf-zajecia.am.szczecin.pl/login';
  static const studentId = 'https://mlegitymacja.am.szczecin.pl';
  static const virtualUniversity = 'https://wu.pm.szczecin.pl';
  static const feedbackForm = 'https://forms.gle/E8sLgZ1X49kaX5jA6';
}

/// Otwiera [url] w przeglądarce (poza aplikacją).
Future<void> openExternalLink(String url) =>
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
