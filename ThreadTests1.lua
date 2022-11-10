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
local sprintf = _G.string.format

local DEBUG 	= threadErrors.DEBUG
local EMPTY_STR = threadErrors.EMPTY_STR
local SUCCESS   = threadErrors.SUCCESS

local SIG_WAKEUP        = dispatch.SIG_WAKEUP  -- You've returned prematurely from a yield. Do what's appropriate.
local SIG_RETURN        = dispatch.SIG_RETURN  -- cleanup state and return from the action routine
local SIG_NONE_PENDING  = dispatch.SIG_NONE_PENDING    -- default value. Means no signal is pending

local function childProc( threadName )
    -- mf:postMsg( sprintf("%s Entered %s's function.\n", E:prefix(), threadName ))
    local result = {SUCCESS, EMPTY_STR, EMPTY_STR}
    local thread_h = nil
    local wasSent = false

    local signal = SIG_NONE_PENDING

    result = thread:yield()
    if not result[1] then mf:postResult(result) return end

    while signal ~= SIG_RETURN do
        signal, sender_h = thread:getSignal()
        result = thread:yield()
        if not result[1] then mf:postResult( result ) return end
    end

    -- return to sender if sender was non-threaded.
    if sender_h ~= EMPTY_STR then
        wasSent, result = thread:sendSignal( sender_h, SIG_RETURN )
        if not result[1] then mf:postResult(result) return end
    end

    result = thread:yield()
    if not result[1] then mf:postResult(result) return end

    mf:postMsg( sprintf("\n%s %s complete.\n", E:prefix(), threadName )) 
end
local function monitor(...)
    local signal = SIG_NONE_PENDING
    local monitorId = nil
    local threadName = ...
    local sender_h = nil
    local senderId = nil

    mf:postMsg( sprintf("%s Entered %s's function.\n", E:prefix(), threadName ))
    monitor_h, result = thread:self()
    if not result[1] then mf:postResult( result ) return end
    
    monitorId, result = thread:getId( monitor_h)
    if not result[1] then mf:postResult( result ) return end

    -- local clockTicks = math.random( 50, 80 )
    local clockTicks = 50
    local child_h, result = thread:create(clockTicks, childProc, "Child" )
    if not result[1] then mf:postResult( result ) return end
    
    -- Wait before sending SIG_RETURN to the child thread
    result = thread:yield()
    if not result[1] then mf:postResult(result) return end
    
    wasSent, result = thread:sendSignal( child_h, SIG_RETURN )
    if not wasSent then mf:postResult(result) return end
    
    -- Now, loop until we get a signal from the child
    mf:postMsg( sprintf("%s Monitor thread created\n", E:prefix() ) )
    while signal ~= SIG_RETURN do
        result = thread:yield()
        if not result[1] then mf:postResult(result) return end
              
        signal, sender_h  = thread:getSignal() 
        if sender_h ~= EMPTY_STR then
            local threadsAreEqual = thread:areEqual( sender_h, child_h )
            if not threadsAreEqual then  -- ignore the signal
                signal = SIG_NONE_PENDING
            end
            senderId, result = thread:getId( sender_h )
            if not result[1] then mf:postResult( result ) return end
        end
    
        mf:postMsg( sprintf(" %s Received SIG_RETURN from thread %d.\n", E:prefix(), senderId )) 
        if not result[1] then mf:postResult( result ) return end
     
        local sigName, result = thread:getSigName( signal )
        if not result[1] then mf:postResult( result ) return end

        mf:postMsg(sprintf("%s Received %s signal from thread %d\n", E:prefix(), sigName, senderId ))
        local s =  sprintf("\n%s %s completed.\n", E:prefix(), threadName )
        mf:postMsg( s )
    end
end
function test1:runTest()
    local result = {SUCCESS, EMPTY_STR, EMPTY_STR} 

    -- Monitor thread creates child threads that execute the various tests.
    local clockTicks = 100
    monitor_h, result = thread:create( clockTicks, monitor, "Monitor" )
    if not result[1] then mf:postResult( result ) return end
end

local fileName = "ThreadTests1.lua"
if E:debuggingIsEnabled() then
	DEFAULT_CHAT_FRAME:AddMessage( sprintf("%s loaded", fileName), 1.0, 1.0, 0.0 )
end
