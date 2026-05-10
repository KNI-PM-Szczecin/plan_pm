// Globalny logger aplikacji oparty na pakiecie `logger`.
// Zastępuje print() — w buildzie produkcyjnym (release) Flutter stripuje wywołania
// print(), przez co logi znikają. AppLogger działa poprawnie w każdym trybie.
// Udostępnia statyczne metody d/i/w/e (debug, info, warning, error) z jednolitą
// konfiguracją PrettyPrinter — bez numerów linii metod, z emoji i znacznikiem
// czasu. Używany w [main.dart], [BackendService], [CacheService] i [HomePage].
import 'package:logger/logger.dart';

class AppLogger {
  static final _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 120,
      colors: false,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
  );

  static Logger get instance => _logger;

  static void d(dynamic message, [dynamic error, StackTrace? stackTrace]) =>
      _logger.d(message, error: error, stackTrace: stackTrace);

  static void i(dynamic message, [dynamic error, StackTrace? stackTrace]) =>
      _logger.i(message, error: error, stackTrace: stackTrace);

  static void w(dynamic message, [dynamic error, StackTrace? stackTrace]) =>
      _logger.w(message, error: error, stackTrace: stackTrace);

  static void e(dynamic message, [dynamic error, StackTrace? stackTrace]) =>
      _logger.e(message, error: error, stackTrace: stackTrace);
}
