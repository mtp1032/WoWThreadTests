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
local sprintf = _G.string.format

local DEBUG 	= threadErrors.DEBUG
local EMPTY_STR = threadErrors.EMPTY_STR
local SUCCESS   = threadErrors.SUCCESS

local SIG_WAKEUP        = dispatch.SIG_WAKEUP  -- You've returned prematurely from a yield. Do what's appropriate.
local SIG_RETURN        = dispatch.SIG_RETURN  -- cleanup state and return from the action routine
local SIG_NONE_PENDING  = dispatch.SIG_NONE_PENDING    -- default value. Means no signal is pending

-- entry = {threadId, ticksPerYield, yieldCount, measuredTimeSuspended, lifeTime }
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

	local s1 = sprintf("\nThread %d\n", threadId )
	local s2 = sprintf("  time suspended: %.2f ms\n", measuredTimeSuspended)
	local s3 = sprintf("  Lifetime: %d ms.\n", measuredLifetime )
	local s4 = sprintf("  Congestion: %.3f%%\n", congestion * 100 )

	mf:postMsg( s1 .. s2 .. s3 .. s4 )
	return result
end

local fileName = "ThreadStats.lua"
if E:debuggingIsEnabled() then
	DEFAULT_CHAT_FRAME:AddMessage( sprintf("%s loaded", fileName), 1.0, 1.0, 0.0 )
end
