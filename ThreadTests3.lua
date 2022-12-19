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

-- NOTE:
-- SIG_ALERT - requires recipient to return from yield() and exit while loop.
-- SIG_TERMINATE - requires thread to cleanup state and complete.
local SIG_ALERT            = thread.SIG_ALERT          -- You've returned prematurely from a yield. Do what's appropriate.
local SIG_JOIN_DATA_READY   = thread.SIG_JOIN_DATA_READY
local SIG_TERMINATE         = thread.SIG_TERMINATE
local SIG_METRICS           = thread.SIG_METRICS
local SIG_NONE_PENDING      = thread.SIG_NONE_PENDING    -- default value. Means the handle's signal queue is empty

local main_h        = nil
local threadTable   = {}
local NUM_THREADS   = 5

local function threadFunc()
    local result = {SUCCESS, EMPTY_STR, EMPTY_STR}
    local signal = SIG_NONE_PENDING
    local sender_h = nil

    while signal ~= SIG_ALERT do
        thread:yield()
        signal, sender_h = thread:getSignal()
    end

    local thread_h = thread:self()
    local threadId, result = thread:getId( thread_h )
    if not result[1] then mf:postResult( result ) return end

    local senderId, result = thread:getId( sender_h )
    if not result[1] then mf:postResult( result ) return end
    mf:postMsg( sprintf("Thread %d received SIG_ALERT from sender %d and is exiting.\n", threadId, senderId  ))
end
local function main()
    local result = {SUCCESS, EMPTY_STR, EMPTY_STR}

    for i = 1, NUM_THREADS do
        -- local yieldTicks = math.random( 40, 60)
        local yieldTicks = 20
        local thread_h, result = thread:create( yieldTicks, threadFunc )
        if not result[1] then mf:postResult( result ) return end

        table.insert( threadTable, thread_h )
    end
    thread:yield()

    for i = 1, NUM_THREADS do
        result = thread:sendSignal( threadTable[i], SIG_ALERT )
        if not result[1] then mf:postResult( result ) return end        
        thread:yield()
    end
    thread:yield()

    mf:postMsg( sprintf("\n ***** TEST3 COMPLETE *****\n"))
end
function test3:runTest()
    local result = {SUCCESS, EMPTY_STR, EMPTY_STR}

    local mainTicks = 60    -- about 1 second
    local main_h = thread:create( mainTicks, main )
    if not result[1] then mf:postResult( result ) return end
end

local fileName = "ThreadTests3.lua"
if E:debuggingIsEnabled() then
	DEFAULT_CHAT_FRAME:AddMessage( sprintf("%s loaded", fileName), 1.0, 1.0, 0.0 )
end
