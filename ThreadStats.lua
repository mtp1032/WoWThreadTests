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


-- entry = { threadId, ticksPerYield, actualTimeSuspended, numYields, lifeTime }
function stats:printEntry( e )
    local result = {SUCCESS, EMPTY_STR, EMPTY_STR}

	local threadId 					= e[1]
	local ticksPerYield				= e[2]
	local actualTimeSuspended 		= e[3]				-- milliseconds
	local numYields					= e[4]
	local actualLifeTime			= e[5]			-- milliseconds
	local calculatedTimeSuspended 	= e[2] * (1/GetFramerate()) * 1000 * numYields 	--milliseconds
	local efficiencyPerCent			= ((calculatedTimeSuspended) / actualTimeSuspended) * 100

	local s1 = sprintf("\nThread Id: %d\n", threadId )
	local s2 = sprintf("  Millseconds per tick: %.3f\n", (1/GetFramerate()) * 1000 )
	local s3 = sprintf("  Ticks per Yield: %d, thread interval time %.2f ms\n", ticksPerYield, ticksPerYield * (1/GetFramerate()) * 1000 )
	local s4 = sprintf("  Yield count: %d\n", numYields )
	local s5 = sprintf("  Calculated time suspended: %.2f ms\n", calculatedTimeSuspended )
	local s6 = sprintf("  Actual time suspended: %.2f ms\n", actualTimeSuspended)
	local s7 = sprintf("  Efficiency: %.2f%%\n", efficiencyPerCent )
	local s8 = sprintf("  Lifetime: %d ms.\n\n", actualLifeTime )

	mf:postMsg( s1 .. s2 .. s3 .. s4 .. s5 .. s6 .. s7 .. s8 )
	return result
end

function stats:dumpTableEntries()
	local result = {SUCCESS, EMPTY_STR, EMPTY_STR}
	local entry, numEntries = mgr:getStatsEntry()

	while entry ~= nil do
		result = stats:printEntry( entry )
		if not result[1] then mf:postResult( result ) return end

		entry, numEntries = mgr:getStatsEntry()
	end
end
	

local fileName = "ThreadStats.lua"
if E:debuggingIsEnabled() then
	DEFAULT_CHAT_FRAME:AddMessage( sprintf("%s loaded", fileName), 1.0, 1.0, 0.0 )
end
