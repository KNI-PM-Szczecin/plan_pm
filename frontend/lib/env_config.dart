// Managed by scripts/switch_env.py — do not edit manually
const bool kUseTestDb = false;

// Set to true to simulate Supabase errors (all requests will fail)
const bool kSimulateNetworkErrors = false;

// Set to true to always show the announcement dialog (for UI development)
const bool kDebugAnnouncement = false;

// Type of announcement to preview: 'info', 'warning', 'update'
const String kDebugAnnouncementType = 'update';

// Set to true to always show the "What's new" dialog (for UI development)
const bool kDebugWhatsNew = false;

// Set to true to load mock news (bypasses Supabase — for testing image loading)
const bool kDebugNews = false;
// ImgBB URL to use in the mock news entry (paste a real direct URL from imgbb.com)
const String kDebugNewsImageUrl = "";
