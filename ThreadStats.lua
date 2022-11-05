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

-- entry = {addonName, threadId, ticksPerYield, yieldCount, measuredTimeSuspended, lifeTime }
function stats:printEntry( e )
    local result = {SUCCESS, EMPTY_STR, EMPTY_STR}

	local addonName					= e[1]
	local threadId 					= e[2]
	local ticksPerYield				= e[3]
	local yieldCount				= e[4]
	local measuredTimeSuspended 	= e[5]			-- milliseconds
	local measuredLifetime			= e[6]			-- milliseconds
	-- local calculatedTimeSuspended 	= ticksPerYield * yieldCount * framerate

	local meanFramerate = measuredTimeSuspended/(ticksPerYield * yieldCount )
	local totalTicks = measuredTimeSuspended / meanFramerate
	congestion 	= 1 - (measuredTimeSuspended / measuredLifetime)

	-- local s1 = sprintf("\nThread Id: %d\n", threadId )
	-- local s2 = sprintf("  Milliseconds per tick: %.3f\n", (1/GetFramerate()) * 1000 )
	-- local s3 = sprintf("  Ticks per Yield: %d (calculated interval time %.2f ms)\n", ticksPerYield, ticksPerYield * (1/GetFramerate()) * 1000 )
	-- local s4 = sprintf("  Yield count: %d\n", yieldCount )
	-- local s5 = sprintf("  Calculated time suspended: %.2f ms\n", calculatedTimeSuspended )
	local s5 = sprintf("\nThread %d\n", threadId )
	local s6 = sprintf("  time suspended: %.2f ms\n", measuredTimeSuspended)
	local s7 = sprintf("  Lifetime: %d ms.\n", measuredLifetime )
	local s8 = sprintf("  Congestion: %.3f%%\n", congestion * 100 )

	mf:postMsg( s5 .. s6 .. s7 .. s8 )
	return result
end
function stats:dumpTableEntries()

	local result = {SUCCESS, EMPTY_STR, EMPTY_STR}
	local entryTable = mgr:getStatsEntries()
	local numEntries = #entryTable
	E:dbgPrint( sprintf("%d entries in stats table.", numEntries ))

	for _, e in ipairs( entryTable ) do		
		stats:printEntry( e )
	end
end
	
local fileName = "ThreadStats.lua"
if E:debuggingIsEnabled() then
	DEFAULT_CHAT_FRAME:AddMessage( sprintf("%s loaded", fileName), 1.0, 1.0, 0.0 )
end
