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

// Set to true to return mock news data (bypasses Supabase)
const bool kDebugNews = false;

// ImgBB URL to use for the mock news image (empty = no image)
const String kDebugNewsImageUrl = "";

// Set to true to always show the rector hours banner (for UI development)
const bool kDebugRectorHours = false;

// Set to true to return an empty groups list (bypasses Supabase, for UI development)
const bool kDebugEmptyGroups = false;

// Set to true to use hardcoded fake schedule data in the home screen widget (bypasses DB)
const bool kDebugWidget = false;
