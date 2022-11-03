--------------------------------------------------------------------------------------
-- FILE NAME:       ThreadTests5.lua 
-- AUTHOR:          Michael Peterson
-- ORIGINAL DATE:   10 October, 2022
local _, WoWThreadTests = ...
WoWThreadTests.ThreadTests5 = {}
test5 = WoWThreadTests.ThreadTests5 

local sprintf = _G.string.format 
local E = threadErrors
local U = utils
local sprintf = _G.string.format

local DEBUG 	= threadErrors.DEBUG
local EMPTY_STR = threadErrors.EMPTY_STR
local SUCCESS   = threadErrors.SUCCESS

local SIG_WAKEUP        = dispatch.SIG_WAKEUP  -- You've returned prematurely from a yield. Do what's appropriate.
local SIG_RETURN        = dispatch.SIG_RETURN  -- cleanup state and return from the action routine
local SIG_NONE_PENDING  = dispatch.SIG_NONE_PENDING    -- default value. Means no signal is pending

local threadPool = {}
local NUM_THREADS = 5
local function childProc( threadName )
    local result = {SUCCESS, EMPTY_STR, EMPTY_STR}
    local yieldCount = 0

    while yieldCount < 10 do
        result = thread:yield()
        if not result[1] then mf:postResult( result ) return end
        yieldCount = yieldCount + 1
    end
    mf:postMsg( sprintf("%s thread complete\n", threadName )) 
end
function test5:runTest()
    local result = {SUCCESS, EMPTY_STR, EMPTY_STR} 
    local child_h

    -- Monitor thread creates child threads that execute the various tests.

    for i = 1, NUM_THREADS do
        local clockTicks = math.random( 20, 60)
        threadPool[i], result = thread:create( clockTicks, childProc, "child" )
        if not result[1] then mf:postResult( result ) return end
    end
end

local fileName = "ThreadTests1.lua"
if E:debuggingIsEnabled() then
	DEFAULT_CHAT_FRAME:AddMessage( sprintf("%s loaded", fileName), 1.0, 1.0, 0.0 )
end
