--------------------------------------------------------------------------------------
-- FILE NAME:       ThreadTests2.lua 
-- AUTHOR:          Michael Peterson
-- ORIGINAL DATE:   10 October, 2022
local _, WoWThreadTests = ...
WoWThreadTests.ThreadTests2 = {}
test2 = WoWThreadTests.ThreadTests2 

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

-- these are test specific globals

local threadTable = {}
local count = 0
function waitLoop()
    local result = {SUCCESS, EMPTY_STR,EMPTY_STR}
    local signal = SIG_NONE_PENDING 
    local signalName = nil

    local threadId, result = thread:getId()
    if not result[1] then mf:postResult( result ) return end

    -- wait for SIG_ALERT 
    while signal ~= SIG_ALERT do
        thread:yield()
        signal, sender_h = thread:getSignal()
        signalName, result = thread:getSignalName( signal )
        if not result[1] then mf:postResult( result ) return end
    end
    mf:postMsg( sprintf("Thread[%d] received %s\n", threadId, signalName ))
    
    signal = SIG_NONE_PENDING
    while signal ~= SIG_JOIN_DATA_READY do
        thread:yield()
        signal, sender_h = thread:getSignal()
        signalName, result = thread:getSignalName( signal )
        if not result[1] then mf:postResult( result ) return end
    end
    mf:postMsg(sprintf("Thread[%d] received %s\n", threadId, signalName ))

    signal = SIG_NONE_PENDING
    while signal ~= SIG_ALERT do
        thread:yield()
        signal, sender_h = thread:getSignal()
        signalName, result = thread:getSignalName( signal )
        if not result[1] then mf:postResult( result ) return end
    end
    mf:postMsg(sprintf("Thread[%d] received %s\n", threadId, signalName ))

    signal = SIG_NONE_PENDING
    while signal ~= SIG_TERMINATE do
        thread:yield()
        signal, sender_h = thread:getSignal()
        signalName, result = thread:getSignalName( signal )
        if not result[1] then mf:postResult( result ) return end
    end
    mf:postMsg(sprintf("Thread[%d] received %s\n", threadId, signalName ))
end

local function main(...)
    local result = {SUCCESS, EMPTY_STR,EMPTY_STR}
    local thread_h = nil
    local numThreads = ...

    mf:postMsg( sprintf("Creating %d threads.\n", numThreads ))

    -- Create some threads and insert them into a table, threadTable.
        local ticks = 400 -- about 6 seconds

        -- Create some threads
    for i = 1, numThreads do 
        thread_h, result = thread:create( ticks, waitLoop )
        if not result[1] then mf:postResult( result ) return end
        table.insert( threadTable, thread_h)
    end

    -- Yield to the newly created threads. Let them begin
    -- executing their while loops.
    thread:yield()
    for i, thread_h in ipairs( threadTable ) do
        -- Send a signal and then yield the processor.
        result = thread:sendSignal( thread_h, SIG_ALERT )
        if not result[1] then mf:postResult( result ) return end
        thread:yield()
    end

    thread:yield()
    for i, thread_h in ipairs( threadTable ) do
        -- Send a signal and then yield the processor.
        result = thread:sendSignal( thread_h, SIG_JOIN_DATA_READY)
        if not result[1] then mf:postResult( result ) return end
        thread:yield()
    end

    thread:yield()
    for i, thread_h in ipairs( threadTable ) do
        -- Send a signal and then yield the processor.
        result = thread:sendSignal( thread_h, SIG_ALERT )
        if not result[1] then mf:postResult( result ) return end
        thread:yield()
    end

    thread:yield()
    for i, thread_h in ipairs( threadTable ) do

        -- Send a signal and then yield the processor.
        result = thread:sendSignal( thread_h, SIG_TERMINATE)
        if not result[1] then mf:postResult( result ) return end
        thread:yield()
    end


    local threadId, result = thread:getId()
    if not result[1] then mf:postResult( result ) return end

    mf:postMsg( sprintf("In TEST2: Thread %d (main_h) waiting for SIG_TERMINATE.", threadId ))
    signal = SIG_NONE_PENDING
    while signal ~= SIG_TERMINATE do
        thread:yield()
        signal, sender_h = thread:getSignal()
    end

    mf:postMsg(sprintf("\nTest2 completed successfully\n"))
end
---------------------------------------------------------------------
--                      TEST 1                                      -
-- Creates the main thread, main_h, which runs the main() method.   -
-- The main() method creates multiple child threads, childN_h, each - 
-- of which runs the waitLoop() method.                             -
-- The waitLoop() method

-- waitLoop() function.
-- The waitLoop() method creates a single child thread
-- The main thread creates 
----------------------------------------------------------------------
local NUM_THREADS = 2
local main_h = nil

function test2:runTest()
    local result = {SUCCESS, EMPTY_STR,EMPTY_STR}

    main_h, result = thread:create( 50, main, NUM_THREADS )
    if not result[1] then mf:postResult( result ) return end
end
function test2:terminate()
    result = thread:sendSignal( main_h, SIG_TERMINATE )
   if not result[1] then mf:postResult( result ) return end
end

local fileName = "ThreadTests2.lua"
if E:debuggingIsEnabled() then
	DEFAULT_CHAT_FRAME:AddMessage( sprintf("%s loaded", fileName), 1.0, 1.0, 0.0 )
end
