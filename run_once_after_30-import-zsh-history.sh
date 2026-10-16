#!/bin/sh
# Imports ~/.zsh_history into fish history once if present.
set -eu

zsh_hist="${HISTFILE:-$HOME/.zsh_history}"
[ -f "$zsh_hist" ] || exit 0
[ -s "$zsh_hist" ] || exit 0

fish_data_dir="${XDG_DATA_HOME:-$HOME/.local/share}/fish"
marker="$fish_data_dir/.zsh_history_imported"
[ -f "$marker" ] && exit 0

command -v python3 >/dev/null || exit 0

python3 - <<'EOF'
import os
import re
import subprocess
import sys
import time

zsh_hist = os.path.expanduser(os.environ.get("HISTFILE", "~/.zsh_history"))
if not os.path.isfile(zsh_hist) or os.path.getsize(zsh_hist) == 0:
    sys.exit(0)

fish_data_dir = os.path.expanduser(
    os.environ.get("XDG_DATA_HOME", "~/.local/share")
) + "/fish"
marker = os.path.join(fish_data_dir, ".zsh_history_imported")
if os.path.exists(marker):
    sys.exit(0)

os.makedirs(fish_data_dir, exist_ok=True)
fish_hist = os.path.join(fish_data_dir, "fish_history")

existing = set()
if os.path.exists(fish_hist):
    with open(fish_hist, "r", encoding="utf-8", errors="replace") as f:
        curr_cmd = None
        for line in f:
            line = line.strip("\r\n")
            if line.startswith("- cmd: "):
                curr_cmd = line[7:]
            elif line.startswith("  when: ") and curr_cmd is not None:
                try:
                    existing.add((curr_cmd, int(line[8:])))
                except ValueError:
                    existing.add((curr_cmd, 0))
                curr_cmd = None

def get_entries_zsh(path):
    cmd = [
        "zsh", "-f", "-c",
        'HISTFILE="$1"; HISTSIZE=10000000; SAVEHIST=10000000; fc -R "$HISTFILE" 2>/dev/null; fc -l -n -t "%s" 1 2>/dev/null',
        "_", path
    ]
    try:
        res = subprocess.run(
            cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.DEVNULL,
            text=True,
            errors="replace"
        )
        if res.returncode == 0 and res.stdout:
            entries = []
            for line in res.stdout.splitlines():
                line = line.strip("\r\n")
                if not line:
                    continue
                parts = line.split("  ", 1)
                if len(parts) == 2 and parts[0].isdigit():
                    ts = int(parts[0])
                    c = parts[1].rstrip("\r\n")
                    if c.endswith("\\n"):
                        c = c[:-2]
                    if c:
                        entries.append((ts, c))
            return entries
    except Exception:
        pass
    return None

def get_entries_fallback(path):
    ext_re = re.compile(r"^:\s*(\d+):(?:\d+);(.*)$", re.DOTALL)
    entries = []
    current_ts = int(time.time())
    current_cmd = []
    with open(path, "r", encoding="utf-8", errors="replace") as f:
        for line in f:
            m = ext_re.match(line)
            if m:
                if current_cmd:
                    entries.append((current_ts, "".join(current_cmd)))
                current_ts = int(m.group(1))
                current_cmd = [m.group(2)]
            else:
                if current_cmd:
                    current_cmd.append(line)
                else:
                    if line.strip():
                        entries.append((int(time.time()), line))
        if current_cmd:
            entries.append((current_ts, "".join(current_cmd)))
    cleaned = []
    for ts, cmd in entries:
        c = cmd.rstrip("\r\n")
        c = c.replace("\\\n", "\\n").replace("\n", "\\n")
        if c.endswith("\\n"):
            c = c[:-2]
        if c:
            cleaned.append((ts, c))
    return cleaned

entries = get_entries_zsh(zsh_hist)
if entries is None:
    entries = get_entries_fallback(zsh_hist)

to_write = [
    (ts, cmd) for ts, cmd in entries
    if (cmd, ts) not in existing and cmd.strip()
]

if to_write:
    with open(fish_hist, "a", encoding="utf-8") as f:
        for ts, cmd in to_write:
            f.write(f"- cmd: {cmd}\n  when: {ts}\n")

with open(marker, "w", encoding="utf-8") as f:
    f.write(f"imported {len(to_write)} commands at {int(time.time())}\n")

print(f"Imported {len(to_write)} command(s) from ~/.zsh_history into fish history.")
EOF
