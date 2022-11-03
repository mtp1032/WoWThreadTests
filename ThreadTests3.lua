--------------------------------------------------------------------------------------
-- FILE NAME:       ThreadTests3.lua 
-- AUTHOR:          Michael Peterson
-- ORIGINAL DATE:   11 October, 2022
local _, WoWThreads = ...
WoWThreads.ThreadTests3 = {}
test3 = WoWThreads.ThreadTests3

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
local NUM_THREADS   = 50

function test3:getStats()
    local result = {SUCCESS, EMPTY_STR, EMPTY_STR}

    local t = mgr:getStatsTable()

    -- entry = {
    --      thread handle, 
    --      ticks per yield interval, 
    --      number of times yielded, 
    --      thread lifetime 
    -- }
    for _, entry in ipairs( t ) do
        local threadId = dispatch:getThreadId( entry[1])
        local ticksPerInterval  = entry[2]
        local numYields      = entry[3]
        local lifeTimeMS        = entry[4] -- this is already in milliseconds

        local timePerTickMS = (1/GetFramerate())*1000
        local timePerIntervalMS = ticksPerInterval * timePerTickMS  -- milliseconds
        local timeSuspendedMS = timePerIntervalMS * numYields
        local perCent = timeSuspendedMS / lifeTimeMS

        local s1 = sprintf("Thread %d: time suspended: %.2f sec, life time %.2f sec, percent suspended %.1f%%\n", threadId, timeSuspendedMS/1000, lifeTimeMS/1000, perCent*100 )
        mf:postMsg( s1 )
    end
end
local function threadFunc()
    local result = {SUCCESS, EMPTY_STR, EMPTY_STR}
    local signal = SIG_NONE_PENDING
    local sender_h = nil

    while signal ~= SIG_RETURN do
        result = thread:yield()
        signal, sender_h = thread:getSignal()
    end

    local thread_h, result = thread:self()
    if not result[1] then mf:postResult( result ) return end

    local threadId, result = thread:getId( thread_h )
    if not result[1] then mf:postResult( result ) return end

    local senderId, result = thread:getId( sender_h )
    if not result[1] then mf:postResult( result ) return end
    mf:postMsg( sprintf("Thread %d received SIG_RETURN from sender %d and is exiting.\n", threadId, senderId  ))
end
local function main()
    local result = {SUCCESS, EMPTY_STR, EMPTY_STR}

    for i = 1, NUM_THREADS do
        -- local yieldTicks = math.random( 40, 60)
        local yieldTicks = 20
        local thread_h, result = thread:create( yieldTicks, threadFunc )
        table.insert( threadTable, thread_h )
    end
    result = thread:yield()
    if not result[1] then mf:postResult( result ) return end

    for i = 1, NUM_THREADS do
        result = thread:sendSignal( threadTable[i], SIG_RETURN )
        if not result[1] then mf:postResult( result ) return end
        
        result = thread:yield()
        if not result[1] then mf:postResult( result ) return end
    end
    local before = debugprofilestop()
    result = thread:yield()
    if not result[1] then mf:postResult( result ) return end
    local elapsedTime = debugprofilestop() - before

    mf:postMsg( sprintf("\n ***** TEST3 COMPLETE *****\n"))
end
function test3:runTest()
    local result = {SUCCESS, EMPTY_STR, EMPTY_STR}

    local mainTicks = 60    -- about 1 second
    local main_h, result = thread:create( mainTicks, main )
    if not result[1] then mf:postResult( result ) return end
end