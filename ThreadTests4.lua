--------------------------------------------------------------------------------------
-- FILE NAME:       ThreadTests4.lua 
-- AUTHOR:          Michael Peterson
-- ORIGINAL DATE:   11 October, 2022
local _, WoWThreads = ...
WoWThreads.ThreadTests4 = {}
test4 = WoWThreads.ThreadTests4

--------------------------------------------------------------------------------------
--      This is the public interface to WoWThreads.                                 --
--------------------------------------------------------------------------------------
local L = WoWThreads.L
local E = threadErrors
local U = threadUtils

local sprintf = _G.string.format

local EMPTY_STR = core.EMPTY_STR
local SUCCESS   = threadErrors.SUCCESS

local SIG_WAKEUP        = thread.SIG_WAKEUP
local SIG_RETURN        = thread.SIG_RETURN
local SIG_NONE_PENDING  = thread.SIG_NONE_PENDING

local main_h        = nil
local threadTable   = {}
local NUM_THREADS   = 100

local function threadFunc()
    local result = {SUCCESS, EMPTY_STR, EMPTY_STR}
    local signal = SIG_NONE_PENDING
    local sender_h = nil
    local loopCount = 1

    while loopCount < 101 do
        result = thread:yield()
        if not result[1] then mf:postResult( result ) return end

        loopCount = loopCount + 1
    end

    local thread_h, result = thread:self()
    if not result[1] then mf:postResult( result ) return end

    local threadId, result = thread:getId( thread_h )
    if not result[1] then mf:postResult( result ) return end

    local senderId, result = thread:getId( sender_h )
    if not result[1] then mf:postResult( result ) return end
    mf:postMsg( sprintf("Thread %d yielded %d times and is exiting.\n", threadId, loopCount  ))
end
local main_h = nil
local function main()
    local result = {SUCCESS, EMPTY_STR, EMPTY_STR}

    for i = 1, NUM_THREADS do
        local yieldTicks = math.random( 20, 40)
        local thread_h, result = thread:create( yieldTicks, threadFunc )
        table.insert( threadTable, thread_h )
    end
    result = thread:yield()
    if not result[1] then mf:postResult( result ) return end

    for i = 1, NUM_THREADS do
        local thread_h = threadTable[i]
        local state = thread:getExecutionState( thread_h )
        if not result[1] then mf:postResult( result ) return end
      
        if state ~= completed then
            wasSent, result = thread:sendSignal( thread_h, SIG_RETURN )
            if not wasSent then 
                if not result[1] then 
                    mf:postResult( result ) 
                    return 
                end
            end
        
            result = thread:yield()
            if not result[1] then mf:postResult( result ) return end
        else
            local threadId, result = thread:getId( thread_h )
            if not result[1] then mf:postResult( result ) return end

            mf:postMsg( sprintf("     *** Thread %d has already completed ***\n", threadId ))
        end
    end
    mf:postMsg( sprintf("\n ***** test4 COMPLETE *****\n"))

    local done = false
    local threadId, result = thread:getId( main_h )
    E:dbgPrint( sprintf("Thread %d (main_h) entering while-loop.", threadId ))
    while not done do
        thread:yield()
        local signal, sender_h = thread:getSignal()
        if signal == SIG_RETURN then done = true end
        if signal == SIG_WAKEUP then done = true end
    end
end
function test4:runTest()
    local result = {SUCCESS, EMPTY_STR, EMPTY_STR}
    local done = false

    local mainTicks = 60    -- about 1 second
    main_h, result = thread:create( mainTicks, main )
    if not result[1] then mf:postResult( result ) return end
end
