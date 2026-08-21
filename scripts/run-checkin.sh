#!/bin/sh
set -eu

project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)
click_tool="/opt/homebrew/opt/cliclick/bin/cliclick"
workbuddy_app="${WORKBUDDY_APP_PATH:-/Applications/WorkBuddy.app}"

if [ ! -x "$click_tool" ]; then
  click_tool=$(command -v cliclick || true)
fi

if [ -z "${click_tool:-}" ] || [ ! -x "$click_tool" ]; then
  echo "ERROR: cliclick is required. Install it with: brew install cliclick" >&2
  exit 2
fi

if [ ! -d "$workbuddy_app" ]; then
  echo "ERROR: WorkBuddy app not found at: $workbuddy_app" >&2
  echo "Set WORKBUDDY_APP_PATH to its .app path and run again." >&2
  exit 4
fi

if ! /usr/bin/pgrep -f "$workbuddy_app/Contents/MacOS/Electron" >/dev/null; then
  if ! /usr/bin/open "$workbuddy_app"; then
    echo "ERROR: macOS could not launch WorkBuddy. Reinstall WorkBuddy, then open it once manually." >&2
    exit 5
  fi
fi

window_geometry=""
attempt=0
while [ "$attempt" -lt 15 ]; do
  if window_geometry=$(/usr/bin/osascript "$project_dir/workbuddy-checkin.applescript" 2>/dev/null); then
    break
  fi
  attempt=$((attempt + 1))
  sleep 2
done

if [ -z "$window_geometry" ]; then
  echo "ERROR: WorkBuddy window did not become available within 30 seconds." >&2
  exit 6
fi

IFS=, read -r window_x window_y window_width window_height <<EOF
$window_geometry
EOF

for coordinate in "$window_x" "$window_y" "$window_width" "$window_height"; do
  case "$coordinate" in
    '' | *[!0-9]*)
      echo "ERROR: invalid WorkBuddy window geometry: $window_geometry" >&2
      exit 3
      ;;
  esac
done

# These offsets are measured from WorkBuddy's normal desktop layout, then
# anchored to the current window. They follow the intended visible flow:
# account avatar (bottom-left) -> Buddy 加油站 -> 立即领取.
profile_x=$((window_x + 70))
profile_y=$((window_y + window_height - 34))
station_x=$((window_x + 106))
station_y=$((window_y + window_height - 463))
claim_x=$((window_x + 76))
claim_y=$((window_y + window_height - 92))
verification_image="$project_dir/workbuddy-checkin-verification.png"
verification_bitmap="${TMPDIR:-/tmp}/workbuddy-checkin-verification.bmp"
verification_x=$((window_x + 10))
verification_y=$((window_y + window_height - 300))
verification_button_x=$((claim_x - verification_x))
verification_button_y=$((claim_y - verification_y))
python_tool="/usr/bin/python3"

if [ ! -x "$python_tool" ]; then
  python_tool="/Library/Frameworks/Python.framework/Versions/3.12/bin/python3"
fi
if [ ! -x "$python_tool" ]; then
  python_tool=$(command -v python3 || true)
fi
if [ -z "${python_tool:-}" ] || [ ! -x "$python_tool" ]; then
  echo "ERROR: Python 3 is required for verification." >&2
  exit 8
fi

echo "WorkBuddy window: $window_geometry"
echo "Clicking account avatar, Buddy 加油站, then 立即领取."
"$click_tool" c:"$profile_x,$profile_y"
sleep 1
"$click_tool" c:"$station_x,$station_y"
sleep 2
"$click_tool" c:"$claim_x,$claim_y"
sleep 3

/usr/sbin/screencapture -x -R "$verification_x,$verification_y,280,290" "$verification_image"
trap 'rm -f "$verification_bitmap"' EXIT HUP INT TERM
/usr/bin/sips -s format bmp "$verification_image" --out "$verification_bitmap" >/dev/null
if "$python_tool" "$project_dir/scripts/verify-claim.py" "$verification_bitmap" "$verification_button_x" "$verification_button_y"; then
  echo "SUCCESS: claim flow completed and verified."
else
  echo "ERROR: click sequence was sent, but WorkBuddy did not show 今日已领." >&2
  echo "Verification screenshot: $verification_image" >&2
  exit 7
fi
