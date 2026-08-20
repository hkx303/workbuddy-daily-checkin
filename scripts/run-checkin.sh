#!/bin/sh
set -eu

project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)

# System Events can occasionally stop responding while an Electron app is
# rebuilding its accessibility tree. Kill the one-shot run rather than leave a
# launchd child process hanging indefinitely.
exec /usr/bin/perl -e '
  my $seconds = shift @ARGV;
  alarm $seconds;
  exec @ARGV or die "Unable to start check-in: $!\\n";
' 75 /usr/bin/osascript "$project_dir/workbuddy-checkin.applescript"
