-- RollHandler.server.luau — Core roll mechanic
-- Handles weighted random item selection, cooldowns, and result distribution
-- Source of truth: docs/architecture.md Section 3, docs/game-design-document.md

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Data = ReplicatedStorage:WaitForChild("Data")
local AestheticsData = require(Data:WaitForChild("AestheticsData"))
local RarityConfig = require(Data:WaitForChild("RarityConfig"))

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local RollRequested = RemoteEvents:WaitForChild("RollRequested")
local RollResult = RemoteEvents:WaitForChild("RollResult")
local ServerAnnouncement = RemoteEvents:WaitForChild("ServerAnnouncement")

-- ============================================================
-- CONFIGURATION
-- ============================================================
local ROLL_COOLDOWN = 5 -- seconds
local ROLL_COST = 100 -- Vibe Coins per standard roll
local SLOTS = { "Head", "Body", "Legs" }

-- ============================================================
-- STATE
-- ============================================================
local playerCooldowns = {} -- [userId] = os.clock() of last roll
local activeCapsuleId = nil -- Set by HypeDropScheduler via _G

-- ============================================================
-- WEIGHTED RANDOM SELECTION
-- ============================================================
local function weightedRandom(items)
	-- Calculate total weight from rarity weights
	local totalWeight = 0
	local weightedItems = {}

	for _, item in ipairs(items) do
		-- Skip capsule items unless capsule is active and matches
		if item.isCapsule and (activeCapsuleId == nil or item.id ~= activeCapsuleId) then
			continue
		end
		-- Skip vaulted items
		if item.isVaulted then
			continue
		end

		local weight = RarityConfig.weights[item.rarity]
		if weight then
			totalWeight = totalWeight + weight
			table.insert(weightedItems, { item = item, weight = weight })
		end
	end

	if totalWeight == 0 or #weightedItems == 0 then
		warn("[RollHandler] No items available for rolling!")
		return nil
	end

	-- Pick a random value and walk through
	local roll = math.random(1, totalWeight)
	local cumulative = 0

	for _, entry in ipairs(weightedItems) do
		cumulative = cumulative + entry.weight
		if roll <= cumulative then
			return entry.item
		end
	end

	-- Fallback (should never reach here)
	return weightedItems[#weightedItems].item
end

-- ============================================================
-- ROLL HANDLER
-- ============================================================
local function handleRollRequest(player)
	local userId = player.UserId

	-- Check cooldown
	local now = os.clock()
	if playerCooldowns[userId] and (now - playerCooldowns[userId]) < ROLL_COOLDOWN then
		return -- Silently ignore (no error to client)
	end

	-- Wait for DataManager to be available
	while not _G.DataManager do
		task.wait(0.1)
	end
	local DataManager = _G.DataManager

	-- Check if player can afford a roll (100 Vibe Coins for standard roll)
	local playerData = DataManager.GetData(player)
	if not playerData then return end

	-- Deduct coins (free rolls during early testing if player has 0 coins and 0 total rolls)
	local isFreeRoll = (playerData.VibeCoin < ROLL_COST and playerData.TotalRolls < 5)
	if not isFreeRoll then
		if not DataManager.SpendCoins(player, ROLL_COST) then
			-- Not enough coins — could fire an error event to client in the future
			return
		end
	end

	-- Set cooldown
	playerCooldowns[userId] = now

	-- Pick a random slot (equal 33% each)
	local slot = SLOTS[math.random(1, #SLOTS)]

	-- Get items for that slot
	local slotItems = AestheticsData.getItemsBySlot(slot)

	-- Roll!
	local item = weightedRandom(slotItems)
	if not item then
		warn("[RollHandler] Failed to roll an item for slot " .. slot)
		return
	end

	-- Add to player's lookbook
	DataManager.AddItemToLookbook(player, slot, item.id, item.rarity)

	-- Fire result to the rolling player
	RollResult:FireClient(player, item)

	-- Server announcements for Epic+ rolls
	if item.rarity == "Epic" then
		ServerAnnouncement:FireAllClients(
			player.DisplayName .. " just pulled an Epic " .. item.name .. "!",
			"Epic"
		)
	elseif item.rarity == "Legendary" then
		ServerAnnouncement:FireAllClients(
			"🔥 " .. player.DisplayName .. " just pulled a LEGENDARY " .. item.name .. "! 🔥",
			"Legendary"
		)
	elseif item.rarity == "Mythic" then
		ServerAnnouncement:FireAllClients(
			"💀 " .. player.DisplayName .. " pulled a MYTHIC " .. item.name .. "!! THE WORLD CHANGES! 💀",
			"Mythic"
		)
	end

	print("[RollHandler] " .. player.Name .. " rolled: " .. item.name .. " (" .. item.rarity .. ") in " .. slot)
end

-- ============================================================
-- PUBLIC API (for RobuxRollHandler to call)
-- ============================================================
local RollHandler = {}

--- Perform a roll for a player, bypassing coin cost (used for Robux purchases)
function RollHandler.PerformFreeRoll(player, guaranteedMinRarity)
	while not _G.DataManager do
		task.wait(0.1)
	end
	local DataManager = _G.DataManager

	local slot = SLOTS[math.random(1, #SLOTS)]
	local slotItems = AestheticsData.getItemsBySlot(slot)

	local item

	if guaranteedMinRarity then
		-- Filter items to the guaranteed minimum rarity or higher
		local rarityOrder = { Common = 1, Uncommon = 2, Rare = 3, Epic = 4, Legendary = 5, Mythic = 6 }
		local minOrder = rarityOrder[guaranteedMinRarity] or 1
		local filteredItems = {}
		for _, it in ipairs(slotItems) do
			if not it.isCapsule and not it.isVaulted then
				local order = rarityOrder[it.rarity] or 1
				if order >= minOrder then
					table.insert(filteredItems, it)
				end
			end
		end
		item = weightedRandom(filteredItems)
	else
		item = weightedRandom(slotItems)
	end

	if not item then return end

	DataManager.AddItemToLookbook(player, slot, item.id, item.rarity)
	RollResult:FireClient(player, item)

	-- Server announcements
	if item.rarity == "Legendary" or item.rarity == "Mythic" then
		local prefix = item.rarity == "Mythic" and "💀" or "🔥"
		ServerAnnouncement:FireAllClients(
			prefix .. " " .. player.DisplayName .. " pulled a " .. item.rarity:upper() .. " " .. item.name .. "! " .. prefix,
			item.rarity
		)
	end

	return item
end

--- Set the active capsule ID (called by HypeDropScheduler)
function RollHandler.SetActiveCapsule(itemId)
	activeCapsuleId = itemId
	print("[RollHandler] Active capsule set to: " .. tostring(itemId))
end

function RollHandler.ClearActiveCapsule()
	activeCapsuleId = nil
	print("[RollHandler] Active capsule cleared")
end

-- ============================================================
-- CONNECTIONS
-- ============================================================
RollRequested.OnServerEvent:Connect(handleRollRequest)

-- Clean up cooldowns when player leaves
Players.PlayerRemoving:Connect(function(player)
	playerCooldowns[player.UserId] = nil
end)

_G.RollHandler = RollHandler

print("[RollHandler] Initialized")

return nil
