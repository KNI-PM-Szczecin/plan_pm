// Zarządzane przez scripts/switch_env.py — nie edytować ręcznie
const bool kUseTestDb = false;

// Ustaw na true aby symulować błędy Supabase (wszystkie requesty będą kończyć się błędem)
const bool kSimulateNetworkErrors = false;

// Ustaw na true aby zawsze wyświetlać dialog ogłoszenia (do pracy nad UI)
const bool kDebugAnnouncement = false;

// Typ ogłoszenia do podglądu: 'info', 'warning', 'update'
const String kDebugAnnouncementType = 'update';

// Ustaw na true aby zawsze wyświetlać dialog "Co nowego" (do pracy nad UI)
const bool kDebugWhatsNew = false;

// Set to true to load mock news (bypasses Supabase — for testing image loading)
const bool kDebugNews = false;
// ImgBB URL to use in the mock news entry (paste a real direct URL from imgbb.com)
const String kDebugNewsImageUrl = "";
