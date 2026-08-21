#!/bin/sh
set -eu

project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)
compiled_path=$(mktemp "${TMPDIR:-/tmp}/workbuddy-checkin.XXXXXX.scpt")
plist_path=$(mktemp "${TMPDIR:-/tmp}/com.workbuddy.daily-checkin.XXXXXX.plist")
trap 'rm -f "$compiled_path" "$plist_path"' EXIT HUP INT TERM

osacompile -o "$compiled_path" "$project_dir/workbuddy-checkin.applescript"
sed \
  -e 's|__INSTALL_DIR__|/tmp/workbuddy-daily-checkin|g' \
  -e 's|__HOUR__|0|g' \
  -e 's|__MINUTE__|30|g' \
  "$project_dir/com.workbuddy.daily-checkin.plist.template" > "$plist_path"
plutil -lint "$plist_path" >/dev/null

python_tool="/usr/bin/python3"
if [ ! -x "$python_tool" ]; then
  python_tool="/Library/Frameworks/Python.framework/Versions/3.12/bin/python3"
fi
if [ ! -x "$python_tool" ]; then
  python_tool=$(command -v python3 || true)
fi
if [ -z "${python_tool:-}" ] || [ ! -x "$python_tool" ]; then
  echo "ERROR: Python 3 is required to validate verify-claim.py." >&2
  exit 1
fi

PYTHONPYCACHEPREFIX="${TMPDIR:-/tmp}/workbuddy-daily-checkin-pycache" \
  "$python_tool" -m py_compile "$project_dir/scripts/verify-claim.py"
echo "AppleScript, verification script, and LaunchAgent template are valid."
