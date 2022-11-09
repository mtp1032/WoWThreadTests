--------------------------------------------------------------------------------------
-- FILE NAME:       ThreadTests.lua 
-- AUTHOR:          Michael Peterson
-- ORIGINAL DATE:   10 October, 2022
local _, WoWThreadTests = ...
WoWThreadTests.CommandLine = {}
msg = WoWThreadTests.CommandLine 

local sprintf = _G.string.format
local E = threadErrors
local sprintf = _G.string.format
-----------------------------------------------------------------------------------
--                          COMMANDS                                              =
-----------------------------------------------------------------------------------
local function validateCmd( msg )
    local isValid = true
    local msg = strupper( msg )

    if msg == nil then
        isValid = false
    end
    if msg == EMPTY_STR then
        isValid = false
    end
    return isValid
end
SLASH_WOWTHREADS_COMMANDS1 = "/run"
SLASH_WOWTHREADS_COMMANDS2 = "/do"
SLASH_WOWTHREADS_COMMANDS3 = "/test"

SlashCmdList["WOWTHREADS_COMMANDS"] = function( msg )
    local isValid = validateCmd( msg )

    msg = string.upper( msg )
    if msg == "TEST1" then
        test1:runTest()
        return
    end
    if msg == "TEST2" then
        test2:runTest()
        return
    end
    if msg == "TEST3" then
        test3:runTest()
        return
    end

    if msg == "TEST4" then
        test4:runTest()
        return
    end

    if msg == "TEST5" then
        test5:runTest()
        return
    end

    if msg == "STATS" then
        local done = false

        while not done do
            local entry = stats:getThreadMetrics()
            if entry ~= nil then
                stats:printEntry( entry )
            else
                done = true
            end
        end
    end
    if not isValid then 
        mf:postMsg(sprintf("%s %s not a valid command.", E:prefix(), msg ))
        return
    end
end -- end of test

local fileName = "CommandLine.lua"
if E:debuggingIsEnabled() then
	DEFAULT_CHAT_FRAME:AddMessage( sprintf("%s loaded", fileName), 1.0, 1.0, 0.0 )
end
