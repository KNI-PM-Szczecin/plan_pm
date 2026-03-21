#!/usr/bin/env python3
"""Użycie: python scripts/switch_env.py [test|prod]"""
import sys
from pathlib import Path

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
