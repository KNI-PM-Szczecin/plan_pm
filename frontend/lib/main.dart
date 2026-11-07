import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show DeviceOrientation, SystemChrome;
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:plan_pm/app.dart';
import 'package:plan_pm/global/notifiers/notifiers.dart';
import 'package:plan_pm/global/utils/logger.dart';
import 'package:plan_pm/secrets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Aplikacja działa wyłącznie w pionie (decyzja produktowa, 11.2026) —
  // natywnie blokują to też Info.plist i AndroidManifest; tu dodatkowo, żeby
  // Flutter nie próbował obracać widoków, gdy system na chwilę pozwoli.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  if (Secrets.supabaseUrl.isEmpty || Secrets.supabaseAnonKey.isEmpty) {
    AppLogger.e(
      "Secrets file is not defined! Visit secrets_example.dart for more information!",
    );
    return;
  }

  await Supabase.initialize(
    url: Secrets.supabaseUrl,
    publishableKey: Secrets.supabaseAnonKey,
  );

  themeNotifier = ThemeNotifier();
  await themeNotifier.loadFromPrefs();

  localeNotifier = LocaleNotifier();
  await localeNotifier.loadFromPrefs();

  accentColorNotifier = AccentColorNotifier();
  await accentColorNotifier.loadFromPrefs();

  eventColorStyleNotifier = EventColorStyleNotifier();
  await eventColorStyleNotifier.loadFromPrefs();

  await SevenDayModeNotifier.init();

  runApp(const App());
}
