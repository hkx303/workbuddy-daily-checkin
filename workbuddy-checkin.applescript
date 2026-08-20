-- WorkBuddy daily check-in. It relies only on the existing WorkBuddy login.
-- Give /usr/bin/osascript Accessibility permission when macOS asks.
-- Update claimKeywords if WorkBuddy changes its button labels.

property claimKeywords : {"领取", "签到"}
property gasStationKeywords : {"Buddy 加油站", "Buddy加油站"}
property profileMenuExclusions : {"消息中心", "扫码", "选择工作空间"}
property maximumDepth : 18

on isClaimLabel(elementName)
    if elementName is missing value then return false
    repeat with keyword in claimKeywords
        if elementName contains (contents of keyword) then return true
    end repeat
    return false
end isClaimLabel

on containsKeyword(elementName, keywords)
    if elementName is missing value then return false
    repeat with keyword in keywords
        if elementName contains (contents of keyword) then return true
    end repeat
    return false
end containsKeyword

on isProfileMenu(elementRef)
    try
        if role of elementRef is not "AXPopUpButton" then return false
        set elementName to name of elementRef
        repeat with excludedName in profileMenuExclusions
            if elementName contains (contents of excludedName) then return false
        end repeat
        return true
    end try
    return false
end isProfileMenu

using terms from application "System Events"
on pressFirstProfileMenu(elementRef, depth)
    if depth > maximumDepth then return false
    try
        if my isProfileMenu(elementRef) then
            click elementRef
            return true
        end if
        set childElements to UI elements of elementRef
        repeat with childElement in childElements
            if my pressFirstProfileMenu(contents of childElement, depth + 1) then return true
        end repeat
    end try
    return false
end pressFirstProfileMenu

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

on pressGasStationEntry(elementRef, depth)
    if depth > maximumDepth then return false
    try
        set elementName to name of elementRef
        if (my containsKeyword(elementName, gasStationKeywords)) and (enabled of elementRef) then
            click elementRef
            return true
        end if
        set childElements to UI elements of elementRef
        repeat with childElement in childElements
            if my pressGasStationEntry(contents of childElement, depth + 1) then return true
        end repeat
    end try
    return false
end pressGasStationEntry
end using terms from

tell application "WorkBuddy" to activate
delay 8

with timeout of 120 seconds
    tell application "System Events"
        if not (exists process "WorkBuddy") then return "ERROR: WorkBuddy did not start."
        tell process "WorkBuddy"
            set frontmost to true
            repeat 30 times
                if my pressFirstProfileMenu(window 1, 0) then exit repeat
                delay 1
            end repeat
            delay 1
            repeat 10 times
                if my pressGasStationEntry(window 1, 0) then exit repeat
                delay 1
            end repeat
            delay 2
            repeat 10 times
                if my pressClaimButton(window 1, 0) then return "SUCCESS: opened Buddy 加油站 and clicked the daily claim button."
                delay 1
            end repeat
        end tell
    end tell
end timeout

return "SKIP: no enabled claim button found (already checked in, still loading, or label changed)."
