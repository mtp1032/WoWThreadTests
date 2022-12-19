--------------------------------------------------------------------------------------
-- FILE NAME:       ThreadTests1.lua 
-- AUTHOR:          Michael Peterson
-- ORIGINAL DATE:   10 October, 2022
local _, WoWThreadTests = ...
WoWThreadTests.ThreadTests1 = {}
test1 = WoWThreadTests.ThreadTests1 

local sprintf = _G.string.format 
local E = threadErrors
local U = utils

local DEBUG 	= threadErrors.DEBUG
local EMPTY_STR = threadErrors.EMPTY_STR
local SUCCESS   = threadErrors.SUCCESS
local FAILURE   = threadErrors.FAILURE

-- NOTE:
-- SIG_ALERT - requires recipient to return from yield() and exit while loop.
-- SIG_TERMINATE - requires thread to cleanup state and complete.
local SIG_ALERT            = thread.SIG_ALERT          -- You've returned prematurely from a yield. Do what's appropriate.
local SIG_JOIN_DATA_READY   = thread.SIG_JOIN_DATA_READY
local SIG_TERMINATE         = thread.SIG_TERMINATE
local SIG_METRICS           = thread.SIG_METRICS
local SIG_NONE_PENDING      = thread.SIG_NONE_PENDING    -- default value. Means the handle's signal queue is empty

local main_h    = nil
local childTable = {}
local NUM_THREADS = 5
local threadsSignaled = 0

local function childProc( threadNum )
    local result = {SUCCESS, EMPTY_STR, EMPTY_STR}
    local signal = SIG_NONE_PENDING
    local threadName = sprintf("Child[%d]", threadNum )

    mf:postMsg( sprintf("%s Entered %s's function.\n", E:prefix(), threadName ))

    -- wait to be terminated
    while signal ~= SIG_TERMINATE do
        thread:yield()
        signal, sender_h = thread:getSignal()
    end
    mf:postMsg( sprintf("%s received %s.\n", threadName, thread:getSignalName(signal )))

    -- terminate main_h if this is the last thread.
    threadsSignaled = threadsSignaled + 1
    if threadsSignaled == NUM_THREADS then
        local parent_h, result = thread:getParent()
        if not result[1] then mf:postResult( result ) return end

        local state, result = thread:getState( parent_h )
        if not result[1] then mf:postResult( result ) return end

        result = thread:sendSignal( parent_h, SIG_TERMINATE )
        if not result[1] then mf:postResult( result ) return end

    end
    mf:postMsg(sprintf("%s completed test successfully.\n", threadName ))
end

local function main(...)
    local result = {SUCCESS, EMPTY_STR, EMPTY_STR}
    local threadName = ...
    local sender_h = nil
    local senderId = nil 
    local child_h = nil
    local childId = 0

    local self_h, selfId = thread:self()
    mf:postMsg( sprintf("%s Entered %s's (Id = %d) function.\n", E:prefix(), threadName, selfId ) )

    ------------------ CREATE THE CHILD THREADS -------------------------
    local clockTicks = 90
    for i = 1, NUM_THREADS do
        local name = sprintf("Child[%d]", i )
        child_h, result = thread:create(clockTicks, childProc, i )
        if not result[1] then mf:postResult( result ) return end
        childId = thread:getId( child_h )
    end
    -------------------------------------------------------------------
    -- pause and let the child threads execute a time or two.
    thread:yield()
    -- retrieve a table of the calling thread's children
    local children, result = thread:getChildren()
    if not result[1] then mf:postResult( result ) return end
    assert( #children == NUM_THREADS, "ASSERT_FAILED!")

   for i = 1, NUM_THREADS do
        child_h = children[i]
        local parent_h, result = thread:getParent( child_h )
        if not result[1] then mf:postResult( result ) return end

        -- make sure the child's parent thread is the running thread.
        local thread_h, threadId = thread:self()
        local areEqual, result = thread:areEqual( parent_h, thread_h )
        if not result[1] then mf:postResult( result ) return end
        assert( areEqual == true, "ASSERT FAILED: threads are not equal." )
        
        childId, result = thread:getId( child_h )
        result = thread:sendSignal( child_h, SIG_TERMINATE )

        if not result[1] then mf:postResult(result) return end
    end

    mf:postMsg( sprintf("Chidren-Parent Test SUCCESSFUL\n"))   
end

function test1:runTest()
    local result = {SUCCESS, EMPTY_STR, EMPTY_STR} 

    ------------------------- CREATE MAIN_H ---------------------------------
    local clockTicks = 100    -- about 4 seconds
    main_h, result = thread:create( clockTicks, main, "main" )
    if not result[1] then mf:postResult( result ) return end

    local threadId, result = thread:getId( main_h )
    if not result[1] then mf:postResult(result) return end
end
    -------------------------------------------------------------------------
local fileName = "ThreadTests1.lua"
if E:debuggingIsEnabled() then
	DEFAULT_CHAT_FRAME:AddMessage( sprintf("%s loaded", fileName), 1.0, 1.0, 0.0 )
end
