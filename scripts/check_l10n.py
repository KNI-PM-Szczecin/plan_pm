"""Check that every ARB file has exactly the same translation keys as the English baseline.

`flutter gen-l10n` silently falls back to the template (app_pl.arb) for a missing
key, so a forgotten translation only shows up as Polish text in the English or
Ukrainian UI.

Usage: python scripts/check_l10n.py   (exit code 1 on any mismatch)
"""

import json
import sys
from pathlib import Path

L10N_DIR = Path(__file__).resolve().parent.parent / "frontend" / "lib" / "l10n"
BASELINE = "app_en.arb"


def load_keys(path: Path) -> dict[str, object]:
    data = json.loads(path.read_text(encoding="utf-8"))
    # "@key" is metadata, "@@locale" is the file's locale — neither is a translation.
    return {k: v for k, v in data.items() if not k.startswith("@")}


def main() -> int:
    baseline = load_keys(L10N_DIR / BASELINE)
    ok = True

    for path in sorted(L10N_DIR.glob("*.arb")):
        keys = load_keys(path)
        missing = sorted(baseline.keys() - keys.keys())
        extra = sorted(keys.keys() - baseline.keys())
        empty = sorted(k for k, v in keys.items() if not str(v).strip())

        if missing or extra or empty:
            ok = False
            print(f"❌ {path.name}: {len(keys)} keys ({BASELINE}: {len(baseline)})")
            for k in missing:
                print(f"   missing: {k}")
            for k in extra:
                print(f"   not in {BASELINE}: {k}")
            for k in empty:
                print(f"   empty value: {k}")
        else:
            print(f"✅ {path.name}: {len(keys)} keys")

    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
