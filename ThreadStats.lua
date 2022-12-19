--------------------------------------------------------------------------------------
-- FILE NAME:       ThreadStats.lua 
-- AUTHOR:          Michael Peterson
-- ORIGINAL DATE:   1 November, 2022
local _, WoWThreadTests = ...
WoWThreadTests.ThreadStats = {}
stats = WoWThreadTests.ThreadStats 

local sprintf = _G.string.format 
local E = threadErrors
local U = utils

local DEBUG 	= threadErrors.DEBUG
local EMPTY_STR = threadErrors.EMPTY_STR
local SUCCESS   = threadErrors.SUCCESS

-- NOTE:
-- SIG_ALERT - requires recipient to return from yield() and exit while loop.
-- SIG_TERMINATE - requires thread to cleanup state and complete.
local SIG_ALERT             = thread.SIG_ALERT          -- You've returned prematurely from a yield. Do what's appropriate.
local SIG_JOIN_DATA_READY   = thread.SIG_JOIN_DATA_READY
local SIG_TERMINATE         = thread.SIG_TERMINATE
local SIG_METRICS           = thread.SIG_METRICS
local SIG_NONE_PENDING      = thread.SIG_NONE_PENDING    -- default value. Means the handle's signal queue is empty

-- returns a table of metrics where each entry = 
--		{threadId, ticksPerYield, yieldCount, measuredTimeSuspended, lifeTime }
function stats:getThreadMetrics( thread_h )
	return mgr:getThreadMetrics( thread_h )
end
function stats:printEntry( e )
    local result = {SUCCESS, EMPTY_STR, EMPTY_STR}

	local threadId 					= e[1]
	local ticksPerYield				= e[2]
	local yieldCount				= e[3]
	local measuredTimeSuspended 	= e[4]			-- milliseconds
	local measuredLifetime			= e[5]			-- milliseconds

	local meanFramerate = measuredTimeSuspended/(ticksPerYield * yieldCount )
	local totalTicks 	= measuredTimeSuspended / meanFramerate
	local congestion 	= 1 - (measuredTimeSuspended / measuredLifetime)

	local s1 = sprintf("\n\nThread %d\n", threadId )
	local s2 = sprintf("  time suspended: %.2f ms\n", measuredTimeSuspended)
	local s3 = sprintf("  Lifetime: %d ms.\n", measuredLifetime )
	local s4 = sprintf("  Congestion: %.3f%%\n", congestion * 100 )

	mf:postMsg( s1 .. s2 .. s3 .. s4 )
	return result
end

-- action routine for metrics_h thread
local function printMetrics()
	local result = {SUCCESS, EMPTY_STR, EMPTY_STR}
    local done = false
	local signal = SIG_NONE_PENDING

	local threadId, result  = thread:getId()
	if not result[1] then mf:postResult(result) return end

    while not done do
		thread:yield()
		signal, sender_h = thread:getSignal()
		if signal == SIG_ALERT then
			thread:yield()
			local entryTable = mgr:getThreadMetrics()
			if entryTable ~= nil then
        		for _, entry in ipairs( entryTable ) do
					stats:printEntry( entry )
        		end
			end

		elseif signal == SIG_TERMINATE then
			done = true
		else
			local sigName, result = thread:getSignalName( signal )
			if not result[1] then mf:postResult(result) return end
		end
    end
end
local metrics_h = nil
function stats:getMetricsThread()
    return metrics_h
end

local result = {SUCCESS, EMPTY_STR, EMPTY_STR}
metrics_h, result = thread:create( 100, printMetrics )
if not result[1] then mf:postResult( result ) return end

local fileName = "ThreadStats.lua"
if E:debuggingIsEnabled() then
	DEFAULT_CHAT_FRAME:AddMessage( sprintf("%s loaded", fileName), 1.0, 1.0, 0.0 )
end
