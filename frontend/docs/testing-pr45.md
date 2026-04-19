# Testing Plan — PR #45

## 1. Announcement modal — basic flow

- [*] Insert a row into `app_announcements` (`active = true`, `type = 'info'`) → launch app → modal appears on home screen
- [*] Tap "Rozumiem" → close and relaunch → modal does **not** appear again
- [*] Set `active = false` → launch → no modal
- [*] Insert a new row (new UUID, `active = true`) → modal appears again

## 2. Announcement modal — `update` type

- [*] Insert row `type = 'update'`, `store_url` filled in → "Aktualizuj" button opens URL **and closes the dialog**
- [*] Insert row `type = 'update'`, `store_url = null` → button shows "Rozumiem" (not "Aktualizuj") and closes dialog
- [ * ] "Pomiń" button closes dialog without opening URL

## 3. Announcement debug flags

- [*] `kDebugAnnouncement = true`, `kDebugAnnouncementType = 'warning'` → modal with triangle icon
- [*] `kDebugAnnouncementType = 'update'` → modal with rocket icon and "Aktualizuj" button
- [*] `kDebugAnnouncementType = 'info'` → modal with info icon

## 4. What's new dialog

- [*] `kDebugWhatsNew = true` → dialog appears on every launch
- [*] Long changelog list in `kChangelog` → list is scrollable, title and version scroll together
- [*] "Super!" button closes the dialog
- [*] `kDebugWhatsNew = false` → remove `last_whats_new_version` from SharedPreferences (reinstall or clear data) → dialog appears once, not on next launch
- [*] First launch (no key in prefs) → dialog does **not** appear

## 5. Dialog order

- [*] Both active (`kDebugWhatsNew = true` + active announcement in DB) → "Co nowego" appears first, after tapping "Super!" the announcement appears

## 6. Version in App Store (Info.plist)

- [ ] Build on device (`flutter build ios`) → check app version in iPhone Settings → should match `pubspec.yaml` (`1.0.8`)

## 7. Regression — navigation

- [*] On iOS bottom nav bar works correctly (tab switching, swipe)
- [*] On Android standard nav bar works without changes
