--------------------------------------------------------------------------------------
-- FILE NAME:       ThreadTests4.lua 
-- AUTHOR:          Michael Peterson
-- ORIGINAL DATE:   10 October, 2022
local _, WoWThreadTests = ...
WoWThreadTests.ThreadTests4 = {}
test4 = WoWThreadTests.ThreadTests4 

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

local NUM_THREADS   = 10
local threadHandles = {}
local producer_h    = nil
local main_h        = nil

function test4:terminate()
    local result = {SUCCESS, EMPTY_STR, EMPTY_STR}

    local state, result = thread:getState( main_h )
    if not result[1] then mf:postResult(result) return end

    if state == "completed" then -- thread cannot be sent.
        mf:postMsg( "Cannot signal main_h. Thread has completed.")
        return
    end
    result = thread:sendSignal( main_h, SIG_TERMINATE)
    if not result[1] then mf:postResult( result ) return end
end
   
---------------------------------------------------------------------
--          CREATES SOME TEST DATA RETURNED TO ALL THREADS
--          THAT HAVE JOINED WITH THIS THREAD.
---------------------------------------------------------------------
local function producerFunc( threadName )
    local result = {SUCCESS, EMPTY_STR, EMPTY_STR} 
    local signal = SIG_NONE_PENDING

    -- yield to let the other threads get established in their
    -- while loops
    thread:yield()

    -- create some test data, just a string
    local joinData = sprintf("*** Data %s thread. ***\n", threadName )
    thread:exit( joinData )
end
--------------------------------------------------------------------
--          JOINS WITH THE PRODUCER THREAD
-------------------------------------------------------------------
local function consumerFunc( threadName )
    local result = {SUCCESS, EMPTY_STR, EMPTY_STR} 
    local signal = SIG_NONE_PENDING

    -- now we wait. will not return from thread:join() until
    -- the data is retrieved.
    mf:postMsg( sprintf("%s calling thread:join().\n", threadName ))
    local joinData, result = thread:join( producer_h )
    if not result[1] then mf:postResult(result) return end

    local s = sprintf("\nSUCCESS: Retrieved join data: %s\n", threadName, joinData )
    mf:postMsg( s )
end
----------------------------------------------------------------------------------
--              CREATES A CONSUMER AND A PRODUCER THREAD
----------------------------------------------------------------------------------
local function main()
    local result = {SUCCESS, EMPTY_STR, EMPTY_STR} 
    local signal = SIG_NONE_PENDING
    local sender_h = nl

    -- create the producer thread to create some data
    local clockTicks = 30
    producer_h, result = thread:create( clockTicks, producerFunc, "Producer thread" )
    if not result[1] then mf:postResult(result) return end

    -- create a consumer thread retrieve and print the data
    clockTicks = 60
    for i = 1, NUM_THREADS do
        local threadName = sprintf("Consumer[%d]", i )
        threadHandles[i], result = thread:create( clockTicks, consumerFunc, threadName )
        if not result[1] then mf:postResult( result ) return end
    end

    -- does not exit while loop until receives
    -- SIG_TERMINATE
    local DONE = false
    while not DONE do
        thread:yield()
        signal, sender_h = thread:getSignal()
        if signal == SIG_TERMINATE then
            DONE = true
            mf:postMsg(sprintf("\nMain thread received SIG_TERMINATE signal.\n"))
        end
    end
    mf:postMsg(sprintf("main thread complete\n"))
end
-----------------------------------------------------------------------
--              CREATES THE MAIN THREAD
-----------------------------------------------------------------------
function test4:runTest()
    local result = {SUCCESS, EMPTY_STR, EMPTY_STR} 

    mf:postMsg( sprintf("\n*** JOIN/EXIT TESTS ***\n"))

    -- create the main thread with a yield interval of approx 5 seconds.
    local clockTicks = 300
    main_h, result = thread:create( clockTicks, main )
    if not result[1] then mf:postResult( result ) return end
end

local fileName = "ThreadTests4.lua"
if E:debuggingIsEnabled() then
	DEFAULT_CHAT_FRAME:AddMessage( sprintf("%s loaded", fileName), 1.0, 1.0, 0.0 )
end
