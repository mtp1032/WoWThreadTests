--------------------------------------------------------------------------------------
-- FILE NAME:       ThreadTests6.lua 
-- AUTHOR:          Michael Peterson
-- ORIGINAL DATE:   10 October, 2022
local _, WoWThreadTests = ...
WoWThreadTests.ThreadTests6 = {}
test6 = WoWThreadTests.ThreadTests6 

-------------- Required constants from WoWThreads -------------------
local sprintf = _G.string.format 
local E = threadErrors
local U = utils
local sprintf = _G.string.format

local DEBUG 	= threadErrors.DEBUG
local EMPTY_STR = threadErrors.EMPTY_STR
local SUCCESS   = threadErrors.SUCCESS

-- NOTE:
-- SIG_ALERT:      requires recipient to return from yield() and exit while loop.
-- SIG_TERMINATE:   requires thread to cleanup state and complete.
local SIG_ALERT            = thread.SIG_ALERT          -- You've returned prematurely from a yield. Do what's appropriate.
local SIG_JOIN_DATA_READY   = thread.SIG_JOIN_DATA_READY
local SIG_TERMINATE         = thread.SIG_TERMINATE
local SIG_METRICS           = thread.SIG_METRICS
local SIG_NONE_PENDING      = thread.SIG_NONE_PENDING    -- default value. Means the handle's signal queue is empty

local main_h            = nil
function test6:getMainThread()
    return main_h
end

local testThreads       = {}
local LOOP_LIMIT        = nil
local CLOCK_INTERVAL    = nil
local NUM_THREADS       = nil

local function childProc( ... )
    local result = {SUCCESS, EMPTY_STR, EMPTY_STR} 
    local signal = SIG_NONE_PENDING
    local threadName = ...
    local iterations = 0
    local DONE = false
    local self_h = nil

    mf:postMsg( sprintf("%s (%d) entered childProc()\n", threadName, threadId ))
    mf:postMsg( sprintf("Iterations: " ))

    -- when iterations == LOOP_LIMIT exit the while() loop.
    while not DONE do
        thread:yield()
        iterations = iterations + 1
        mf:postMsg( sprintf("%d ", iterations ))
        if iterations == LOOP_LIMIT then 
            DONE = true
        end
    end
    mf:postMsg( sprintf("\n" ))

    local metrics_h = stats:getMetricsThread()

    result = thread:sendSignal( metrics_h, SIG_ALERT)
    if not result[1] then mf:postResult( result ) return end

    mf:postMsg( "SIG_ALERT sent to metrics_h")
end

local function main( ... )
    local result = {SUCCESS, EMPTY_STR, EMPTY_STR} 
    local signal = SIG_NONE_PENDING
    local sender_h = nil
    local numThreads = ...

    for i = 1, NUM_THREADS do
        local threadName = sprintf("child[%d]", i )
        testThreads[i], result = thread:create( CLOCK_INTERVAL, childProc, threadName )
        if not result[1] then mf:postResult( result ) return end
    end

    while signal ~= SIG_TERMINATE do
        thread:yield()
        signal, sender_h = thread:getSignal()
    end

    local mainId, result = thread:getId()
    mf:postMsg( sprintf("TEST COMPLETE: Main thread %s terminated.\n", mainId ))
end
function test6:runTest(  loopLimit, numThreads, clockInterval)
    local result = {SUCCESS, EMPTY_STR, EMPTY_STR} 

    LOOP_LIMIT = loopLimit
    NUM_THREADS = numThreads
    CLOCK_INTERVAL = clockInterval

    mf:postMsg( sprintf("\n*** THREAD CONGESTION TESTS ***\n"))

    -- create the main thread with a yield interval of approx 10 seconds.
    local clockTicks = 6000 -- ~10 second
    main_h, result = thread:create( clockTicks, main, numThreads )
    if not result[1] then mf:postResult( result ) return end
end
function test6:terminate()
    local result = {SUCCESS, EMPTY_STR, EMPTY_STR}

    result = thread:sendSignal( main_h, SIG_TERMINATE )
    if not result[1] then mf:postResult( result ) end
end

local fileName = "ThreadTests6.lua"
if E:debuggingIsEnabled() then
	DEFAULT_CHAT_FRAME:AddMessage( sprintf("%s loaded", fileName), 1.0, 1.0, 0.0 )
end
