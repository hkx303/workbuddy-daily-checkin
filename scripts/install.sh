#!/bin/sh
set -eu

label="com.workbuddy.daily-checkin"
hour=0
minute=30

usage() {
  echo "Usage: $0 [--hour 0-23] [--minute 0-59]" >&2
  exit 1
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --hour) hour=${2-}; shift 2 ;;
    --minute) minute=${2-}; shift 2 ;;
    *) usage ;;
  esac
done

case "$hour" in ''|*[!0-9]*) usage ;; esac
case "$minute" in ''|*[!0-9]*) usage ;; esac
[ "$hour" -le 23 ] && [ "$minute" -le 59 ] || usage

project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)
agent_dir="$HOME/Library/LaunchAgents"
agent_path="$agent_dir/$label.plist"
template="$project_dir/$label.plist.template"
tmp_path=$(mktemp "${TMPDIR:-/tmp}/$label.XXXXXX")
trap 'rm -f "$tmp_path"' EXIT HUP INT TERM

sed \
  -e "s|__INSTALL_DIR__|$project_dir|g" \
  -e "s|__HOUR__|$hour|g" \
  -e "s|__MINUTE__|$minute|g" \
  "$template" > "$tmp_path"
plutil -lint "$tmp_path" >/dev/null

mkdir -p "$agent_dir"
launchctl bootout "gui/$(id -u)/$label" 2>/dev/null || true
cp "$tmp_path" "$agent_path"
launchctl bootstrap "gui/$(id -u)" "$agent_path"

echo "Installed $label: runs daily at $(printf '%02d:%02d' "$hour" "$minute")."
