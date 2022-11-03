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

local SIG_WAKEUP        = dispatch.SIG_WAKEUP  -- You've returned prematurely from a yield. Do what's appropriate.
local SIG_RETURN        = dispatch.SIG_RETURN  -- cleanup state and return from the action routine
local SIG_NONE_PENDING  = dispatch.SIG_NONE_PENDING    -- default value. Means no signal is pending

-- these are test specific globals
local threadTable = {}

function waitLoop()
    local result = {SUCCESS, EMPTY_STR,EMPTY_STR}
    local signal = SIG_NONE_PENDING 

    while signal ~= SIG_RETURN do
        result = thread:yield()
        if not result[1] then mf:postResult(result) return end

        signal, sender_h = thread:getSignal()

        if signal == SIG_RETURN then
            sigName, result = thread:getSigName( signal )
           if not result[1] then mf:postResult( result ) return end

           local thread_h, result = thread:self()
           if not result[1] then mf:postResult( result ) return end

            local threadId, result = thread:getId( thread_h )
            if not result[1] then mf:postResult( result ) return end

            mf:postMsg(sprintf("Thread %d received %s\n", threadId, sigName ))
        end
    end
end

local function main(...)
    local result = {SUCCESS, EMPTY_STR,EMPTY_STR}
    local thread_h = nil
    local numThreads = ...

    mf:postMsg( sprintf("Creating %d threads.\n", numThreads))

    -- Create some threads and insert them into a table, threadTable.
        local ticks = 50 -- about 1 second

        -- Create some threads
    for i = 1, numThreads do 
        thread_h, result = thread:create( ticks, waitLoop )
        if not result[1] then mf:postResult( result ) return end
        table.insert( threadTable, thread_h)
    end

    -- Yield to the newly created threads. Let them begin
    -- executing their while loops.
    result = thread:yield()
    if not result[1] then mf:postResult(result) return end
    -- Now, signal the threads for termination
    for i, thread_h in ipairs( threadTable ) do

        -- Send a signal and then yield the processor.
        result = thread:sendSignal( thread_h, SIG_RETURN )
        if not result[1] then mf:postResult( result ) return end

        result = thread:yield()
        if not result[1] then mf:postResult(result) return end
    end
    -- Now remove the threads from the thread table
    for i = 1, numThreads do
        thread_h = table.remove(threadTable, 1)
    end
    mf:postMsg("tests2 completed successfully\n")
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
function test2:runTest()
    local threads = 10
    local main_h, result = thread:create( 50, main, threads )
    if not result[1] then mf:postResult( result ) return end
end

local fileName = "ThreadTests2.lua"
if E:debuggingIsEnabled() then
	DEFAULT_CHAT_FRAME:AddMessage( sprintf("%s loaded", fileName), 1.0, 1.0, 0.0 )
end
