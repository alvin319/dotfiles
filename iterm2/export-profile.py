#!/usr/bin/env python3
"""Re-export an iTerm2 profile from this Mac's preferences into iterm2/Dotfiles.json.

Normally unnecessary: iTerm2 writes edits to a dynamic profile back into its JSON,
and Dotfiles.json is symlinked from the repo, so tweaking colors in iTerm2 already
lands here. Use this once to migrate a regular (non-dynamic) profile.

    python3 iterm2/export-profile.py [profile-name]     (default: "Default")
"""
import json, math, plistlib, subprocess, sys, pathlib

name = sys.argv[1] if len(sys.argv) > 1 else "Default"
prefs = plistlib.loads(subprocess.check_output(["defaults", "export", "com.googlecode.iterm2", "-"]))
src = next((b for b in prefs.get("New Bookmarks", []) if b.get("Name") == name), None)
if src is None:
    sys.exit(f"no iTerm2 profile named {name!r}; have: {[b.get('Name') for b in prefs.get('New Bookmarks', [])]}")

b = dict(src)
b["Name"] = "Dotfiles"
b["Guid"] = "D07F11E5-0000-4000-8000-A1B1C1D1E1F1"   # fixed: install.sh uses it to set the default
b["Working Directory"] = ""                          # machine-specific; "Custom Directory" governs use
for k in ("Bound Hosts", "Triggers", "Initial Text", "Badge Text"):
    b.pop(k, None)
b["Tags"] = ["dotfiles"]

# The plist stores some status-bar widths as inf. Python would emit `Infinity`,
# which is not valid JSON and iTerm2 refuses the whole file. Clamp to a big finite number.
def _finite(o):
    if isinstance(o, dict):  return {k: _finite(v) for k, v in o.items()}
    if isinstance(o, list):  return [_finite(v) for v in o]
    if isinstance(o, float) and not math.isfinite(o):
        return 0.0 if math.isnan(o) else (1e9 if o > 0 else -1e9)
    return o
b = _finite(b)

out = pathlib.Path(__file__).with_name("Dotfiles.json")
out.write_text(json.dumps({"Profiles": [b]}, indent=2, sort_keys=True, allow_nan=False) + "\n")
print(f"wrote {out} ({len(b)} keys) from profile {name!r}")
