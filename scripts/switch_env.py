#!/usr/bin/env python3
"""Użycie: python scripts/switch_env.py [test|prod]"""
import sys
from pathlib import Path

reconfigure = getattr(sys.stdout, "reconfigure", None)
if reconfigure is not None:
    reconfigure(encoding="utf-8", errors="replace")

REPO_ROOT = Path(__file__).parent.parent
ENV_MODE_FILE = REPO_ROOT / "backend" / ".env_mode"
ENV_CONFIG_DART = REPO_ROOT / "frontend" / "lib" / "env_config.dart"

if len(sys.argv) != 2 or sys.argv[1] not in ("test", "prod"):
    print("Użycie: python scripts/switch_env.py [test|prod]")
    sys.exit(1)

mode = sys.argv[1]

ENV_MODE_FILE.write_text(f"{mode}\n")
ENV_CONFIG_DART.write_text(
    "// Managed by scripts/switch_env.py — do not edit manually\n"
    f"const bool kUseTestDb = {str(mode == 'test').lower()};\n"
    "\n"
    "// Set to true to simulate Supabase errors (all requests will fail)\n"
    "const bool kSimulateNetworkErrors = false;\n"
    "\n"
    "// Set to true to always show the announcement dialog (for UI development)\n"
    "const bool kDebugAnnouncement = false;\n"
    "\n"
    "// Type of announcement to preview: 'info', 'warning', 'update'\n"
    "const String kDebugAnnouncementType = 'update';\n"
    "\n"
    "// Set to true to always show the \"What's new\" dialog (for UI development)\n"
    "const bool kDebugWhatsNew = false;\n"
    "\n"
    "// Set to true to return mock news data (bypasses Supabase)\n"
    "const bool kDebugNews = false;\n"
    "\n"
    "// ImgBB URL to use for the mock news image (empty = no image)\n"
    "const String kDebugNewsImageUrl = \"\";\n"
    "\n"
    "// Set to true to always show the rector hours banner (for UI development)\n"
    "const bool kDebugRectorHours = false;\n"
    "\n"
    "// Set to true to push fake lecture data to the home screen widget (bypasses real schedule)\n"
    "const bool kDebugWidget = false;\n"
    "\n"
    "// Number of fake lectures (0-7) pushed to the widget when kDebugWidget is true (0 = empty state)\n"
    "const int kDebugWidgetCount = 7;\n"
    "\n"
    "// Set to true to simulate empty groups response (bypasses Supabase, always returns empty list)\n"
    "const bool kDebugEmptyGroups = false;\n"
    "\n"
    "// Set to true to show the GDPR consent screen before confirming lecturer selection\n"
    "const bool kDebugGdpr = false;\n"
)

print(f"Przestawiono na: {mode}")
if mode == "test":
    print("  Backend:  TEST_SUPABASE_URL / TEST_SUPABASE_KEY")
    print("  Frontend: kUseTestDb = true")
    print()
    print("UWAGA: commit i merge PR są zablokowane w trybie test.")
else:
    print("  Backend:  SUPABASE_URL / SUPABASE_KEY")
    print("  Frontend: kUseTestDb = false")
