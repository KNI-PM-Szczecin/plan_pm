// Korzeń aplikacji — MaterialApp z motywem, lokalizacjami i builderem AppColor.
// [AppRebuilder] wymusza rebuild drzewa po zmianie motywu lub języka.
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemChrome, SystemUiOverlayStyle, Brightness;
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:plan_pm/app_initialization.dart';
import 'package:plan_pm/env_config.dart';
import 'package:plan_pm/global/notifiers/notifiers.dart';
import 'package:plan_pm/global/theme/colors.dart';
import 'package:plan_pm/global/widgets/app_rebuilder.dart';
import 'package:plan_pm/l10n/app_localizations.dart';
import 'package:plan_pm/pages/home/home_shell.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

TextTheme _tightTextTheme(TextTheme base) => TextTheme(
  displayLarge: base.displayLarge?.copyWith(letterSpacing: -0.5),
  displayMedium: base.displayMedium?.copyWith(letterSpacing: -0.5),
  displaySmall: base.displaySmall?.copyWith(letterSpacing: -0.4),
  headlineLarge: base.headlineLarge?.copyWith(letterSpacing: -0.4),
  headlineMedium: base.headlineMedium?.copyWith(letterSpacing: -0.3),
  headlineSmall: base.headlineSmall?.copyWith(letterSpacing: -0.3),
  titleLarge: base.titleLarge?.copyWith(letterSpacing: -0.3),
  titleMedium: base.titleMedium?.copyWith(letterSpacing: -0.2),
  titleSmall: base.titleSmall?.copyWith(letterSpacing: -0.2),
  bodyLarge: base.bodyLarge?.copyWith(letterSpacing: -0.2),
  bodyMedium: base.bodyMedium?.copyWith(letterSpacing: -0.2),
  bodySmall: base.bodySmall?.copyWith(letterSpacing: -0.1),
  labelLarge: base.labelLarge?.copyWith(letterSpacing: -0.1),
  labelMedium: base.labelMedium?.copyWith(letterSpacing: -0.1),
  labelSmall: base.labelSmall?.copyWith(letterSpacing: -0.1),
);

SystemUiOverlayStyle _overlayStyleForBrightness(Brightness brightness) {
  return brightness == Brightness.light
      ? SystemUiOverlayStyle.dark
      : SystemUiOverlayStyle.light;
}

AppBarTheme _appBarThemeForBrightness(Brightness brightness) {
  return AppBarTheme(
    systemOverlayStyle: _overlayStyleForBrightness(brightness),
  );
}

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
                fontFamily: defaultTargetPlatform == TargetPlatform.iOS ? '.SF Pro Text' : 'Inter',
                brightness: Brightness.light,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: AppColor.primary,
                  brightness: Brightness.light,
                ),
                appBarTheme: _appBarThemeForBrightness(Brightness.light),
              ).copyWith(
                textTheme: _tightTextTheme(
                  ThemeData(brightness: Brightness.light).textTheme,
                ),
              ),
              darkTheme: ThemeData(
                fontFamily: defaultTargetPlatform == TargetPlatform.iOS ? '.SF Pro Text' : 'Inter',
                brightness: Brightness.dark,
                colorScheme: ColorScheme.fromSeed(
                  seedColor: AppColor.primary,
                  brightness: Brightness.dark,
                ),
                appBarTheme: _appBarThemeForBrightness(Brightness.dark),
              ).copyWith(
                textTheme: _tightTextTheme(
                  ThemeData(brightness: Brightness.dark).textTheme,
                ),
              ),
              builder: (context, child) {
                return Builder(
                  builder: (BuildContext innerContext) {
                    final brightness = Theme.of(innerContext).brightness;
                    AppColor.update(brightness);
                    SystemChrome.setSystemUIOverlayStyle(
                      _overlayStyleForBrightness(brightness),
                    );
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
