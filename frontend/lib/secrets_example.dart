// Instrukcja:
// 1. Skopiuj ten plik i zmień nazwę na 'secrets.dart'
// 2. Wklej swoje klucze Supabase poniżej (prod obowiązkowo, test opcjonalnie)
// 3. Upewnij się, że secrets.dart jest w .gitignore
//
// Klucze znajdziesz w panelu Supabase: Settings → API → Project URL / anon key.
// Jeśli nie masz dostępu — napisz na discordzie do schoji.

import 'env_config.dart';

class Secrets {
  static const bool _useTestDb = kUseTestDb;

  // Production
  static const String _prodUrl = ""; // Wklej URL produkcyjnej bazy
  static const String _prodAnonKey = ""; // Wklej klucz produkcyjnej bazy

  // Test (opcjonalne — wypełnij tylko jeśli testujesz na osobnej bazie)
  static const String _testUrl = ""; // Wklej URL testowej bazy
  static const String _testAnonKey = ""; // Wklej klucz testowej bazy

  static const String _activeUrl = _useTestDb ? _testUrl : _prodUrl;
  static const String _activeAnonKey = _useTestDb ? _testAnonKey : _prodAnonKey;

  static const String supabaseUrl = kSimulateNetworkErrors
      ? "http://localhost:9999"
      : _activeUrl;
  static const String supabaseAnonKey = kSimulateNetworkErrors
      ? "invalid_key"
      : _activeAnonKey;
}
