-- WorkBuddy daily check-in. It relies only on the existing WorkBuddy login.
-- Give /usr/bin/osascript Accessibility permission when macOS asks.
-- Update claimKeywords if WorkBuddy changes its button labels.

set claimKeywords to {"领取", "签到"}

tell application "WorkBuddy" to activate
delay 3

tell application "System Events"
    if not (exists process "WorkBuddy") then return "ERROR: WorkBuddy is not running."
    tell process "WorkBuddy"
        set frontmost to true
        repeat 30 times
            try
                set claimButtons to every button of entire contents whose enabled is true and ((name contains item 1 of claimKeywords) or (name contains item 2 of claimKeywords))
                if (count of claimButtons) > 0 then
                    click item 1 of claimButtons
                    return "SUCCESS: clicked WorkBuddy daily claim button."
                end if
            end try
            delay 1
        end repeat
    end tell
end tell

return "SKIP: no enabled claim button found (usually already checked in)."
