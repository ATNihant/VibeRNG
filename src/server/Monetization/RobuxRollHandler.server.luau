-- RobuxRollHandler.server.luau — Robux purchase processing
-- Handles MarketplaceService ProcessReceipt callback with receipt deduplication
-- Source of truth: docs/game-design-document.md (Monetization section)

local MarketplaceService = game:GetService("MarketplaceService")
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

-- ============================================================
-- PRODUCT IDS — Set these after creating Developer Products in Creator Dashboard
-- ============================================================
local PRODUCTS = {
	-- Vibe Starter Pack: 79 R$ → 10 rolls, first guaranteed Rare+
	STARTER_PACK = 0, -- Replace with actual Product ID

	-- Hype Pack: 199 R$ → 30 rolls + 500 Vibe Coins + 1 guaranteed Epic
	HYPE_PACK = 0, -- Replace with actual Product ID

	-- Capsule Key: 399 R$ → Weekend-only access to active Designer Capsule
	CAPSULE_KEY = 0, -- Replace with actual Product ID

	-- Mythic Wish: 999 R$ → 1 guaranteed Mythic (random Mythic item)
	MYTHIC_WISH = 0, -- Replace with actual Product ID
}

-- Reverse lookup: productId → product name
local productLookup = {}
for name, id in pairs(PRODUCTS) do
	if id > 0 then
		productLookup[id] = name
	end
end

-- Receipt deduplication DataStore
local receiptStore = DataStoreService:GetDataStore("VibeCheckRNG_Receipts")

-- ============================================================
-- RECEIPT DEDUPLICATION
-- ============================================================
local function isReceiptProcessed(purchaseId)
	local success, result = pcall(function()
		return receiptStore:GetAsync("receipt_" .. tostring(purchaseId))
	end)
	return success and result == true
end

local function markReceiptProcessed(purchaseId)
	local success, err = pcall(function()
		receiptStore:SetAsync("receipt_" .. tostring(purchaseId), true)
	end)
	if not success then
		warn("[RobuxRollHandler] Failed to mark receipt: " .. tostring(err))
	end
end

-- ============================================================
-- PROCESS RECEIPT
-- ============================================================
MarketplaceService.ProcessReceipt = function(receiptInfo)
	-- Check for duplicate receipt
	if isReceiptProcessed(receiptInfo.PurchaseId) then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then
		-- Player left before we could grant — DON'T mark as processed
		-- Roblox will retry on next join
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	-- Wait for dependencies
	while not _G.RollHandler or not _G.DataManager do
		task.wait(0.1)
	end
	local RollHandler = _G.RollHandler
	local DataManager = _G.DataManager

	local productName = productLookup[receiptInfo.ProductId]
	local granted = false

	if productName == "STARTER_PACK" then
		-- 10 rolls, first guaranteed Rare+
		local firstItem = RollHandler.PerformFreeRoll(player, "Rare")
		if firstItem then
			for i = 2, 10 do
				RollHandler.PerformFreeRoll(player, nil)
			end
			granted = true
		end

	elseif productName == "HYPE_PACK" then
		-- 30 rolls + 500 Vibe Coins + 1 guaranteed Epic
		DataManager.AddCoins(player, 500)
		local epicItem = RollHandler.PerformFreeRoll(player, "Epic")
		if epicItem then
			for i = 2, 30 do
				RollHandler.PerformFreeRoll(player, nil)
			end
			granted = true
		end

	elseif productName == "CAPSULE_KEY" then
		-- Access to active capsule — just grant it (capsule access is handled by RollHandler)
		-- TODO: Add a flag to player data for capsule key access
		granted = true

	elseif productName == "MYTHIC_WISH" then
		-- 1 guaranteed Mythic
		local mythicItem = RollHandler.PerformFreeRoll(player, "Mythic")
		granted = (mythicItem ~= nil)

	else
		warn("[RobuxRollHandler] Unknown product ID: " .. tostring(receiptInfo.ProductId))
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	if granted then
		markReceiptProcessed(receiptInfo.PurchaseId)
		print("[RobuxRollHandler] Granted product " .. tostring(productName) .. " to " .. player.Name)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	else
		warn("[RobuxRollHandler] Failed to grant product to " .. player.Name)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
end

print("[RobuxRollHandler] Initialized (Product IDs need to be set in Creator Dashboard)")

return nil
