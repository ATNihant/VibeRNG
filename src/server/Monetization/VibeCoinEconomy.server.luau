-- VibeCoinEconomy.server.luau — Vibe Coin utility functions
-- Wraps DataManager coin operations for use by other server scripts
-- Source of truth: docs/game-design-document.md (Monetization section)

-- This script provides a clean API for other server scripts to manage coins.
-- The actual coin operations delegate to DataManager.

-- Daily login reward
local Players = game:GetService("Players")
local DAILY_LOGIN_REWARD = 100

local function awardDailyLogin(player)
	-- Wait for DataManager
	while not _G.DataManager do
		task.wait(0.1)
	end
	local DataManager = _G.DataManager

	local data = DataManager.GetData(player)
	if not data then return end

	local today = os.date("!%Y-%m-%d")
	local lastRewardDay = os.date("!%Y-%m-%d", data.LastDailyReward or 0)

	if lastRewardDay == today then
		return -- Already awarded today
	end

	data.LastDailyReward = os.time()
	DataManager.AddCoins(player, DAILY_LOGIN_REWARD)

	print("[VibeCoinEconomy] Daily login reward (" .. DAILY_LOGIN_REWARD .. " coins) given to " .. player.Name)
end

-- Award daily login on join
Players.PlayerAdded:Connect(function(player)
	-- Slight delay to let DataManager load player data first
	task.wait(3)
	awardDailyLogin(player)
end)



print("[VibeCoinEconomy] Initialized")

return nil
