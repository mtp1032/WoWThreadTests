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

-- NOTE:
-- SIG_ALERT - requires recipient to return from yield() and exit while loop.
-- SIG_TERMINATE - requires thread to cleanup state and complete.
local SIG_ALERT            = thread.SIG_ALERT          -- You've returned prematurely from a yield. Do what's appropriate.
local SIG_JOIN_DATA_READY   = thread.SIG_JOIN_DATA_READY
local SIG_TERMINATE         = thread.SIG_TERMINATE
local SIG_METRICS           = thread.SIG_METRICS
local SIG_NONE_PENDING      = thread.SIG_NONE_PENDING    -- default value. Means the handle's signal queue is empty

local main_h        = nil
local testThreads   = {}
local NUM_THREADS   = 2
function test5:getMainThread()
    return main_h
end

local function childProc( ... )
    local result = {SUCCESS, EMPTY_STR, EMPTY_STR} 
    local signal = SIG_NONE_PENDING
    local threadName = ...

    mf:postMsg( sprintf("%s entered childProc()\n", threadName ))

    while signal ~= SIG_TERMINATE do
        thread:yield()
        signal, sender_h = thread:getSignal()
    end

    mf:postMsg( sprintf("%s terminated.\n", threadName ))
end

local function main()
    local result = {SUCCESS, EMPTY_STR, EMPTY_STR} 
    local signal = SIG_NONE_PENDING
    local sender_h = nil
    local DONE = false

    for i = 1, NUM_THREADS do
        local threadName = sprintf("thread[%d]", i )
        testThreads[i], result = thread:create( 120, childProc, threadName )
        if not result[1] then mf:postResult( result ) return end
    end

    for i = 1, NUM_THREADS do
        local parent_h, result = thread:getParent( testThreads[i])
        if not result[1] then mf:postResult( result ) return end

        local parentId, result = thread:getId( parent_h )
        if not result[1] then mf:postResult( result ) return end
        mf:postMsg( sprintf("Thread[%d] is parent of child thread[%d]\n", parentId, i ))
    end

    for i = 1, NUM_THREADS do
        result = thread:sendSignal( testThreads[i], SIG_TERMINATE )
        if not result[1] then mf:postResult( result ) return end
    end

    while signal ~= SIG_TERMINATE do
        thread:yield()
        signal, sender_h = thread:getSignal()
    end

    local mainId, result = thread:getId()
    mf:postMsg( sprintf("TEST COMPLETE: Main thread %s terminated.\n", mainId ))
end
function test5:runTest()
    local result = {SUCCESS, EMPTY_STR, EMPTY_STR} 

    mf:postMsg( sprintf("\n*** PARENT/CHILD TESTS ***\n"))

    -- create the main thread with a yield interval of approx 5 seconds.
    local clockTicks = 60 -- ~1 second
    main_h, result = thread:create( clockTicks, main )
    if not result[1] then mf:postResult( result ) return end
end

local fileName = "ThreadTests5.lua"
if E:debuggingIsEnabled() then
	DEFAULT_CHAT_FRAME:AddMessage( sprintf("%s loaded", fileName), 1.0, 1.0, 0.0 )
end
