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
claim_x=$((window_x + 204))
claim_y=$((window_y + window_height - 92))

echo "WorkBuddy window: $window_geometry"
echo "Clicking account avatar, Buddy 加油站, then 立即领取."
"$click_tool" c:"$profile_x,$profile_y"
sleep 1
"$click_tool" c:"$station_x,$station_y"
sleep 2
"$click_tool" c:"$claim_x,$claim_y"
sleep 3

# The current compact Buddy 加油站 card renders 立即领取 in near-black and
# 今日已领 as a light-gray disabled button. cliclick can sample this exact
# point without the Screen Recording permission required by screencapture.
claim_color=$("$click_tool" cp:"$claim_x,$claim_y" 2>&1) || {
  echo "ERROR: unable to read the claim button color: $claim_color" >&2
  exit 7
}
set -- $claim_color
if [ "$#" -ne 3 ]; then
  echo "ERROR: unexpected claim button color output: $claim_color" >&2
  exit 7
fi
for component in "$@"; do
  case "$component" in
    '' | *[!0-9]*)
      echo "ERROR: unexpected claim button color output: $claim_color" >&2
      exit 7
      ;;
  esac
done

claim_brightness=$((($1 + $2 + $3) / 3))
echo "Claim button RGB: $claim_color (brightness: $claim_brightness)"
if [ "$claim_brightness" -ge 150 ]; then
  echo "VERIFIED: WorkBuddy claim button is in the completed (今日已领) state."
  echo "SUCCESS: claim flow completed and verified."
else
  echo "ERROR: WorkBuddy claim button is still in the unclaimed state." >&2
  exit 7
fi
