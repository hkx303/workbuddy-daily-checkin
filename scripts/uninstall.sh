#!/bin/sh
set -eu

label="com.workbuddy.daily-checkin"
agent_path="$HOME/Library/LaunchAgents/$label.plist"

launchctl bootout "gui/$(id -u)/$label" 2>/dev/null || true
rm -f "$agent_path"
echo "Removed $label."
