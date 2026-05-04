import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:plan_pm/app.dart';
import 'package:plan_pm/global/notifiers/notifiers.dart';
import 'package:plan_pm/global/utils/logger.dart';
import 'package:plan_pm/secrets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  if (Secrets.supabaseUrl.isEmpty || Secrets.supabaseAnonKey.isEmpty) {
    AppLogger.e(
      "Secrets file is not defined! Visit secrets_example.dart for more information!",
    );
    return;
  }

  await Supabase.initialize(
    url: Secrets.supabaseUrl,
    anonKey: Secrets.supabaseAnonKey,
  );

  themeNotifier = ThemeNotifier();
  await themeNotifier.loadFromPrefs();

  localeNotifier = LocaleNotifier();
  await localeNotifier.loadFromPrefs();

  accentColorNotifier = AccentColorNotifier();
  await accentColorNotifier.loadFromPrefs();

  amoledModeNotifier = AmoledModeNotifier();
  await amoledModeNotifier.loadFromPrefs();

  eventColorStyleNotifier = EventColorStyleNotifier();
  await eventColorStyleNotifier.loadFromPrefs();

  await SevenDayModeNotifier.init();

  runApp(const App());
}
