--------------------------------------------------------------------------------------
-- FILE NAME:       ThreadTests.lua 
-- AUTHOR:          Michael Peterson
-- ORIGINAL DATE:   10 October, 2022
local _, WoWThreadTests = ...
WoWThreadTests.CommandLine = {}
msg = WoWThreadTests.CommandLine 

local sprintf   = _G.string.format
local E         = threadErrors
local U         = utils

local DEBUG 	= threadErrors.DEBUG
local EMPTY_STR = threadErrors.EMPTY_STR
local SUCCESS   = threadErrors.SUCCESS

local SIG_ALERT             = thread.SIG_ALERT          -- You've returned prematurely from a yield. Do what's appropriate.
local SIG_JOIN_DATA_READY   = thread.SIG_JOIN_DATA_READY
local SIG_TERMINATE         = thread.SIG_TERMINATE
local SIG_METRICS           = thread.SIG_METRICS
local SIG_NONE_PENDING      = thread.SIG_NONE_PENDING    -- default value. Means the handle's signal queue is empty

-----------------------------------------------------------------------------------
--                          COMMANDS                                              =
-----------------------------------------------------------------------------------
local function validateCmd( msg )
    local isValid = true
    
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

    msg = string.lower( msg )  

    ---------------------- TEST 1 -----------------------------
    if msg == "test1" then
        test1:runTest()
        return
    end
    -- NOT IMPLEMENTED
    if msg == "term1" then
        test1:terminate()
        return
    end
    ---------------------- TEST 2 -----------------------------
    if msg == "test2" then
        test2:runTest()
        return
    end
    if msg == "term2" then
        test2:terminate()
        return
    end
    ---------------------- TEST 3 -----------------------------
    if msg == "test3" then
        test3:runTest()
        return
    end

    ---------------------- TEST 6 -----------------------------
    if msg == "test4" then
        test4:runTest()
    end
    if msg == "term6" then
        test4:terminate()
    end
    ---------------------- TEST 7 -----------------------------
    if msg == "test5" then
        test5:runTest()
        return
    end
    if msg == "term7" then
        local result = {SUCCESS, EMPTY_STR, EMPTY_STR} 

        local main_h = test5:getMainThread()
        result = thread:sendSignal( main_h, SIG_TERMINATE)
        if not result[1] then mf:postResult( result ) return end
    end

    if msg == "test6" then
        local loopLimit = 20
        local numThreads = 2
        local clockInterval = 10

        test6:runTest( loopLimit, numThreads, clockInterval )
        return
    end
    if msg == "term8" then
        local result = {SUCCESS, EMPTY_STR, EMPTY_STR} 

        local main_h = test6:getMainThread()
        local result = thread:sendSignal( main_h, SIG_TERMINATE)
        if not result[1] then mf:postResult( result ) return end
    end

    if msg == "stats" then
        local done = false

        while not done do
            local entryTable = mgr:getThreadMetrics()
            for _, entry in ipairs( entryTable ) do
                stats:printEntry( entry )
            end
            done = true
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
