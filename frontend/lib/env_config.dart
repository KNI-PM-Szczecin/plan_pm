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

// Set to true to push fake lecture data to the home screen widget (bypasses real schedule)
const bool kDebugWidget = false;

// Number of fake lectures (0-7) pushed to the widget when kDebugWidget is true (0 = empty state)
const int kDebugWidgetCount = 7;

// Set to true to simulate empty groups response (bypasses Supabase, always returns empty list)
const bool kDebugEmptyGroups = false;

// Set to true to show the GDPR consent screen before confirming lecturer selection
const bool kDebugGdpr = false;
