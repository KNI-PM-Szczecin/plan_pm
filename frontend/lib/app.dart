// Korzeń aplikacji — MaterialApp z motywem, lokalizacjami i builderem AppColor.
// [AppRebuilder] wymusza rebuild drzewa po zmianie motywu lub języka.
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:plan_pm/app_initialization.dart';
import 'package:plan_pm/env_config.dart';
import 'package:plan_pm/global/notifiers/notifiers.dart';
import 'package:plan_pm/global/theme/colors.dart';
import 'package:plan_pm/global/widgets/app_rebuilder.dart';
import 'package:plan_pm/l10n/app_localizations.dart';
import 'package:plan_pm/pages/home/home_shell.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale?>(
      valueListenable: localeNotifier,
      builder: (context, currentLocale, _) {
        return ValueListenableBuilder<ThemeMode>(
          valueListenable: themeNotifier,
          builder: (context, currentThemeMode, _) {
            return MaterialApp(
              locale: currentLocale,
              themeMode: currentThemeMode,
              title: 'Plan PM',
              debugShowCheckedModeBanner: kUseTestDb,
              theme: ThemeData(
                fontFamily: "Inter",
                brightness: Brightness.light,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: AppColor.primary,
                  brightness: Brightness.light,
                ),
              ),
              darkTheme: ThemeData(
                fontFamily: "Inter",
                brightness: Brightness.dark,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: AppColor.primary,
                  brightness: Brightness.dark,
                ),
              ),
              builder: (context, child) {
                return Builder(
                  builder: (BuildContext innerContext) {
                    final brightness = Theme.of(innerContext).brightness;
                    AppColor.update(brightness);
                    return KeyedSubtree(
                      key: ValueKey(brightness),
                      child: AppRebuilder(child: child!),
                    );
                  },
                );
              },
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('en'),
                Locale('pl'),
                Locale('uk'),
              ],
              routes: {
                '/home': (_) => const MyHomePage(title: 'Strona główna'),
              },
              home: FutureBuilder<Widget>(
                future: appInitialization(),
                builder: (context, AsyncSnapshot<Widget> screen) {
                  if (screen.connectionState != ConnectionState.done) {
                    return Container(color: AppColor.background);
                  }
                  FlutterNativeSplash.remove();
                  return screen.data!;
                },
              ),
            );
          },
        );
      },
    );
  }
}
