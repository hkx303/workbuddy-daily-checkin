-- Returns the current WorkBuddy window geometry as x,y,width,height.
-- The mouse-click sequence lives in scripts/run-checkin.sh because Electron's
-- accessibility tree is too unstable for reliable element-based clicks.

tell application "System Events"
    if not (exists process "Electron") then error "WorkBuddy did not start."
    tell process "Electron"
        if not (exists window 1) then error "WorkBuddy window did not appear."

        -- Electron exposes small helper windows before its visible main window.
        -- Use the largest window so the click offsets attach to the app UI.
        set largestArea to 0
        set mainWindowPosition to missing value
        set mainWindowSize to missing value
        repeat with candidateWindow in windows
            try
                set candidateSize to size of candidateWindow
                set candidateArea to (item 1 of candidateSize) * (item 2 of candidateSize)
                if candidateArea > largestArea then
                    set largestArea to candidateArea
                    set mainWindowPosition to position of candidateWindow
                    set mainWindowSize to candidateSize
                end if
            end try
        end repeat

        if mainWindowPosition is missing value then error "WorkBuddy main window did not appear."
        return ((item 1 of mainWindowPosition) as text) & "," & ((item 2 of mainWindowPosition) as text) & "," & ((item 1 of mainWindowSize) as text) & "," & ((item 2 of mainWindowSize) as text)
    end tell
end tell
