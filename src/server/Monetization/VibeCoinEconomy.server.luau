-- VibeCoinEconomy.server.luau — Vibe Coin utility functions
-- Wraps DataManager coin operations for use by other server scripts
-- Source of truth: docs/game-design-document.md (Monetization section)

-- This script provides a clean API for other server scripts to manage coins.
-- The actual coin operations delegate to DataManager.

-- Daily login reward
local Players = game:GetService("Players")
local DAILY_LOGIN_REWARD = 100
local DAILY_LOGIN_KEY = "DailyLogin"

-- Track daily logins per session (simple in-memory, resets on server restart)
local dailyLoginTracker = {}

local function awardDailyLogin(player)
	-- Wait for DataManager
	while not _G.DataManager do
		task.wait(0.1)
	end
	local DataManager = _G.DataManager

	local userId = player.UserId
	local today = os.date("!%Y-%m-%d")

	if dailyLoginTracker[userId] == today then
		return -- Already awarded today
	end

	DataManager.AddCoins(player, DAILY_LOGIN_REWARD)
	dailyLoginTracker[userId] = today

	print("[VibeCoinEconomy] Daily login reward (" .. DAILY_LOGIN_REWARD .. " coins) given to " .. player.Name)
end

-- Award daily login on join
Players.PlayerAdded:Connect(function(player)
	-- Slight delay to let DataManager load player data first
	task.wait(3)
	awardDailyLogin(player)
end)

-- Clean up tracker on leave
Players.PlayerRemoving:Connect(function(player)
	dailyLoginTracker[player.UserId] = nil
end)

print("[VibeCoinEconomy] Initialized")

return nil
