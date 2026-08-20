-- WorkBuddy daily check-in. It relies only on the existing WorkBuddy login.
-- Give /usr/bin/osascript Accessibility permission when macOS asks.
-- Update claimKeywords if WorkBuddy changes its button labels.

property claimKeywords : {"领取", "签到"}
property maximumDepth : 18

on isClaimLabel(elementName)
    if elementName is missing value then return false
    repeat with keyword in claimKeywords
        if elementName contains (contents of keyword) then return true
    end repeat
    return false
end isClaimLabel

using terms from application "System Events"
on pressClaimButton(elementRef, depth)
    if depth > maximumDepth then return false
    try
        set elementName to name of elementRef
        if (isClaimLabel(elementName)) and (enabled of elementRef) then
            click elementRef
            return true
        end if

        -- Do not request "entire contents": Electron can expose a very large
        -- accessibility tree, which causes System Events to time out.
        set childElements to UI elements of elementRef
        repeat with childElement in childElements
            if pressClaimButton(contents of childElement, depth + 1) then return true
        end repeat
    end try
    return false
end pressClaimButton
end using terms from

tell application "WorkBuddy" to activate
delay 8

with timeout of 120 seconds
    tell application "System Events"
        if not (exists process "WorkBuddy") then return "ERROR: WorkBuddy did not start."
        tell process "WorkBuddy"
            set frontmost to true
            repeat 30 times
                if my pressClaimButton(window 1, 0) then return "SUCCESS: clicked WorkBuddy daily claim button."
                delay 1
            end repeat
        end tell
    end tell
end timeout

return "SKIP: no enabled claim button found (already checked in, still loading, or label changed)."
