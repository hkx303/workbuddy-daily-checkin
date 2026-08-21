-- Returns the current WorkBuddy window geometry as x,y,width,height.
-- The mouse-click sequence lives in scripts/run-checkin.sh because Electron's
-- accessibility tree is too unstable for reliable element-based clicks.

tell application "System Events"
    if not (exists process "Electron") then error "WorkBuddy did not start."
    tell process "Electron"
        if not (exists window 1) then error "WorkBuddy window did not appear."
        set windowPosition to position of window 1
        set windowSize to size of window 1
        return ((item 1 of windowPosition) as text) & "," & ((item 2 of windowPosition) as text) & "," & ((item 1 of windowSize) as text) & "," & ((item 2 of windowSize) as text)
    end tell
end tell
