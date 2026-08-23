#!/bin/sh
set -eu

project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)
compiled_path=$(mktemp "${TMPDIR:-/tmp}/workbuddy-checkin.XXXXXX.scpt")
plist_path=$(mktemp "${TMPDIR:-/tmp}/com.workbuddy.daily-checkin.XXXXXX.plist")
trap 'rm -f "$compiled_path" "$plist_path"' EXIT HUP INT TERM

osacompile -o "$compiled_path" "$project_dir/workbuddy-checkin.applescript"
for shell_script in "$project_dir"/scripts/*.sh; do
  sh -n "$shell_script"
done
sed \
  -e 's|__INSTALL_DIR__|/tmp/workbuddy-daily-checkin|g' \
  -e 's|__HOUR__|0|g' \
  -e 's|__MINUTE__|30|g' \
  "$project_dir/com.workbuddy.daily-checkin.plist.template" > "$plist_path"
plutil -lint "$plist_path" >/dev/null

echo "AppleScript, shell scripts, and LaunchAgent template are valid."
