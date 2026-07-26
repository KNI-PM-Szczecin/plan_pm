"""Console encoding setup — fixes Windows charmap crashes.

On Windows the console defaults to a legacy code page (e.g. cp1252). Printing
emoji (❌ ✅ 📊) or rich output then raises
`UnicodeEncodeError: 'charmap' codec can't encode character ...`. Reconfiguring
stdout/stderr to UTF-8 makes those writes succeed (rich writes through the same
streams). No-op on POSIX, where the streams are already UTF-8.

Call force_utf8_output() once at the start of every entry point / pipeline
module so it applies whether the module is run directly, via `python -m`, or
through the admin panel / MCP subprocess.
"""

import sys


def force_utf8_output() -> None:
    if sys.platform != "win32":
        return
    for stream in (sys.stdout, sys.stderr):
        reconfigure = getattr(stream, "reconfigure", None)
        if reconfigure is None:
            continue
        try:
            reconfigure(encoding="utf-8", errors="replace")
        except (ValueError, OSError):
            pass
