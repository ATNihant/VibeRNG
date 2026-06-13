-- DataManager.server.luau — Player data persistence via DataStoreService
-- Handles load, save, migration, and item/equip operations
-- Source of truth: docs/architecture.md Section 1, 5

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Data = ReplicatedStorage:WaitForChild("Data")
local LookbookSchema = require(Data:WaitForChild("LookbookSchema"))
local RarityConfig = require(Data:WaitForChild("RarityConfig"))
local AestheticsData = require(Data:WaitForChild("AestheticsData"))

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local LookbookDataEvent = RemoteEvents:WaitForChild("LookbookData")
local EquipItemEvent = RemoteEvents:WaitForChild("EquipItem")
local UnequipItemEvent = RemoteEvents:WaitForChild("UnequipItem")
local MythicFXActivated = RemoteEvents:WaitForChild("MythicFXActivated")
local MythicFXDeactivated = RemoteEvents:WaitForChild("MythicFXDeactivated")

local DATASTORE_NAME = "VibeCheckRNG_v1"
local KEY_PREFIX = "player_"
local MAX_VIBE_COIN = 50000
local SAVE_RETRY_ATTEMPTS = 3
local SAVE_RETRY_DELAY = 1

local dataStore = DataStoreService:GetDataStore(DATASTORE_NAME)

-- ============================================================
-- Runtime cache: playerDataCache[userId] = { ...full data table... }
-- ============================================================
local playerDataCache = {}

local DataManager = {}

-- ============================================================
-- DATA MIGRATION
-- ============================================================
local function migrateData(data)
	if data.Version == nil or data.Version < 1 then
		-- Initial version, ensure all fields exist
		data.RunwayWins = data.RunwayWins or 0
		data.RunwayParticipations = data.RunwayParticipations or 0
		data.VaultedItems = data.VaultedItems or {}
		data.Version = 1
	end
	return data
end

-- ============================================================
-- DEEP COPY utility
-- ============================================================
local function deepCopy(original)
	local copy = {}
	for key, value in pairs(original) do
		if type(value) == "table" then
			copy[key] = deepCopy(value)
		else
			copy[key] = value
		end
	end
	return copy
end

-- ============================================================
-- SAVE PLAYER — with retry logic
-- ============================================================
function DataManager.SavePlayer(player)
	local userId = player.UserId
	local data = playerDataCache[userId]
	if not data then
		warn("[DataManager] No cached data for player " .. userId .. ", skipping save.")
		return false
	end

	data.LastSave = os.time()

	for attempt = 1, SAVE_RETRY_ATTEMPTS do
		local success, err = pcall(function()
			dataStore:SetAsync(KEY_PREFIX .. tostring(userId), data)
		end)

		if success then
			return true
		else
			warn("[DataManager] Save attempt " .. attempt .. " failed for " .. userId .. ": " .. tostring(err))
			if attempt < SAVE_RETRY_ATTEMPTS then
				task.wait(SAVE_RETRY_DELAY)
			end
		end
	end

	warn("[DataManager] All save attempts failed for " .. userId)
	return false
end

-- ============================================================
-- LOAD PLAYER — on PlayerAdded
-- ============================================================
local function loadPlayer(player)
	local userId = player.UserId
	local key = KEY_PREFIX .. tostring(userId)

	local success, result = pcall(function()
		return dataStore:GetAsync(key)
	end)

	local data
	if success and result then
		data = migrateData(result)
	else
		if not success then
			warn("[DataManager] Failed to load data for " .. userId .. ": " .. tostring(result))
		end
		-- New player or load failure — use defaults
		data = LookbookSchema.getDefault()
		data.FirstJoin = os.time()
	end

	playerDataCache[userId] = data

	-- Send initial data to client
	LookbookDataEvent:FireClient(player, data)
end

-- ============================================================
-- REMOVE PLAYER — on PlayerRemoving
-- ============================================================
local function removePlayer(player)
	local userId = player.UserId
	DataManager.SavePlayer(player)
	playerDataCache[userId] = nil
end

-- ============================================================
-- PUBLIC API
-- ============================================================

--- Get cached data for a player (returns nil if not loaded)
function DataManager.GetData(player)
	return playerDataCache[player.UserId]
end

--- Add an item to the player's lookbook after a roll
function DataManager.AddItemToLookbook(player, slot, itemId, rarity)
	local data = playerDataCache[player.UserId]
	if not data then return false end

	-- Add item to the correct slot
	if not data.Lookbook[slot] then
		data.Lookbook[slot] = {}
	end
	data.Lookbook[slot][itemId] = true

	-- Increment total rolls
	data.TotalRolls = data.TotalRolls + 1

	-- Award Vibe Coins for the rarity
	local coinDrop = RarityConfig.coinDrops[rarity] or 0
	data.VibeCoin = math.min(data.VibeCoin + coinDrop, MAX_VIBE_COIN)

	-- Save and sync to client
	DataManager.SavePlayer(player)
	LookbookDataEvent:FireClient(player, data)

	return true
end

--- Add coins to a player's balance
function DataManager.AddCoins(player, amount)
	local data = playerDataCache[player.UserId]
	if not data then return false end

	data.VibeCoin = math.min(data.VibeCoin + amount, MAX_VIBE_COIN)
	LookbookDataEvent:FireClient(player, data)
	return true
end

--- Spend coins from a player's balance. Returns false if insufficient.
function DataManager.SpendCoins(player, amount)
	local data = playerDataCache[player.UserId]
	if not data then return false end
	if data.VibeCoin < amount then return false end

	data.VibeCoin = data.VibeCoin - amount
	LookbookDataEvent:FireClient(player, data)
	return true
end

--- Record a runway participation
function DataManager.RecordRunwayParticipation(player)
	local data = playerDataCache[player.UserId]
	if not data then return end
	data.RunwayParticipations = data.RunwayParticipations + 1
end

--- Record a runway win
function DataManager.RecordRunwayWin(player)
	local data = playerDataCache[player.UserId]
	if not data then return end
	data.RunwayWins = data.RunwayWins + 1
end

--- Add a vaulted item
function DataManager.AddVaultedItem(player, itemId)
	local data = playerDataCache[player.UserId]
	if not data then return end
	data.VaultedItems[itemId] = true
end

-- ============================================================
-- EQUIP / UNEQUIP HANDLERS
-- ============================================================
local function handleEquip(player, slot, itemId)
	local data = playerDataCache[player.UserId]
	if not data then return end

	-- Validate slot
	if slot ~= "Head" and slot ~= "Body" and slot ~= "Legs" then
		warn("[DataManager] Invalid slot: " .. tostring(slot))
		return
	end

	-- Validate ownership
	if not data.Lookbook[slot] or not data.Lookbook[slot][itemId] then
		warn("[DataManager] Player " .. player.UserId .. " does not own " .. itemId)
		return
	end

	-- Check if we're unequipping a Mythic first
	local previousItemId = data.Equipped[slot]
	if previousItemId then
		local previousItem = AestheticsData.getItemById(previousItemId)
		if previousItem and previousItem.rarity == "Mythic" then
			MythicFXDeactivated:FireAllClients(player.UserId, previousItemId)
		end
	end

	-- Equip the item
	data.Equipped[slot] = itemId

	-- Check if the new item is Mythic
	local newItem = AestheticsData.getItemById(itemId)
	if newItem and newItem.rarity == "Mythic" then
		MythicFXActivated:FireAllClients(player.UserId, itemId)
	end

	-- Save and sync
	DataManager.SavePlayer(player)
	LookbookDataEvent:FireClient(player, data)
end

local function handleUnequip(player, slot)
	local data = playerDataCache[player.UserId]
	if not data then return end

	-- Validate slot
	if slot ~= "Head" and slot ~= "Body" and slot ~= "Legs" then
		warn("[DataManager] Invalid slot: " .. tostring(slot))
		return
	end

	-- Check if we're unequipping a Mythic
	local previousItemId = data.Equipped[slot]
	if previousItemId then
		local previousItem = AestheticsData.getItemById(previousItemId)
		if previousItem and previousItem.rarity == "Mythic" then
			MythicFXDeactivated:FireAllClients(player.UserId, previousItemId)
		end
	end

	data.Equipped[slot] = nil

	DataManager.SavePlayer(player)
	LookbookDataEvent:FireClient(player, data)
end

-- ============================================================
-- CONNECTIONS
-- ============================================================
Players.PlayerAdded:Connect(loadPlayer)
Players.PlayerRemoving:Connect(removePlayer)
EquipItemEvent.OnServerEvent:Connect(handleEquip)
UnequipItemEvent.OnServerEvent:Connect(handleUnequip)

-- BindToClose: save all cached players on server shutdown
game:BindToClose(function()
	for userId, _ in pairs(playerDataCache) do
		local player = Players:GetPlayerByUserId(userId)
		if player then
			DataManager.SavePlayer(player)
		end
	end
end)

-- Make DataManager accessible to other server scripts via a BindableEvent
-- Other scripts can require this module via a shared ModuleScript pattern
-- For now, we store it globally for cross-script access
_G.DataManager = DataManager

print("[DataManager] Initialized")

return nil
