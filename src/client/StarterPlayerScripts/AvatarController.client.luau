-- AvatarController.client.luau — Applies equipped items to the player's avatar
-- Listens for LookbookData updates and applies model assets to the character
-- Source of truth: docs/implementation-plan.md Phase 6

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Data = ReplicatedStorage:WaitForChild("Data")
local AestheticsData = require(Data:WaitForChild("AestheticsData"))

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local LookbookDataEvent = RemoteEvents:WaitForChild("LookbookData")

local player = Players.LocalPlayer

-- ============================================================
-- STATE
-- ============================================================
local currentEquipped = {
	Head = nil,
	Body = nil,
	Legs = nil,
}

-- References to applied accessories/effects
local appliedVisuals = {
	Head = nil,
	Body = nil,
	Legs = nil,
}

-- ============================================================
-- VISUAL APPLICATION
-- ============================================================
local function clearSlotVisual(slot)
	if appliedVisuals[slot] then
		appliedVisuals[slot]:Destroy()
		appliedVisuals[slot] = nil
	end
end

local function applyItemVisual(slot, item)
	local character = player.Character
	if not character then return end

	clearSlotVisual(slot)

	-- Skip placeholder assets
	if item.model == "rbxassetid://0" then
		-- Create a visual indicator instead (colored BillboardGui)
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		if not humanoidRootPart then return end

		-- Create a simple particle effect to indicate equipped item
		local attachment = Instance.new("Attachment")
		attachment.Name = "VibeRNG_" .. slot
		attachment.Parent = humanoidRootPart

		local particles = Instance.new("ParticleEmitter")
		particles.Parent = attachment
		particles.Rate = 5
		particles.Lifetime = NumberRange.new(1, 2)
		particles.Speed = NumberRange.new(1, 3)
		particles.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.2),
			NumberSequenceKeypoint.new(1, 0),
		})

		-- Color based on rarity
		local rarityColors = {
			Common    = Color3.fromRGB(180, 180, 180),
			Uncommon  = Color3.fromRGB(30, 200, 80),
			Rare      = Color3.fromRGB(50, 120, 255),
			Epic      = Color3.fromRGB(160, 50, 255),
			Legendary = Color3.fromRGB(255, 150, 0),
			Mythic    = Color3.fromRGB(255, 40, 80),
		}

		local color = rarityColors[item.rarity] or Color3.fromRGB(255, 255, 255)
		particles.Color = ColorSequence.new(color)

		-- Position based on slot
		if slot == "Head" then
			attachment.Position = Vector3.new(0, 2, 0)
		elseif slot == "Body" then
			attachment.Position = Vector3.new(0, 0.5, 0)
		else -- Legs
			attachment.Position = Vector3.new(0, -1, 0)
		end

		appliedVisuals[slot] = attachment
		return
	end

	-- For custom local accessories (like test ones)
	if type(item.model) == "string" and ReplicatedStorage:FindFirstChild(item.model) then
		local acc = ReplicatedStorage[item.model]:Clone()
		character.Humanoid:AddAccessory(acc)
		appliedVisuals[slot] = acc
		return
	end

	-- TODO: When real model asset IDs are available, use InsertService or
	-- HumanoidDescription to apply actual accessories/clothing
	-- For now, placeholder models get the particle effect above
end

-- ============================================================
-- DATA UPDATE HANDLER
-- ============================================================
LookbookDataEvent.OnClientEvent:Connect(function(data)
	if not data or not data.Equipped then return end

	for _, slot in ipairs({"Head", "Body", "Legs"}) do
		local newItemId = data.Equipped[slot]

		if newItemId ~= currentEquipped[slot] then
			currentEquipped[slot] = newItemId

			if newItemId then
				local item = AestheticsData.getItemById(newItemId)
				if item then
					applyItemVisual(slot, item)
				end
			else
				clearSlotVisual(slot)
			end
		end
	end
end)

-- Handle character respawning
player.CharacterAdded:Connect(function(character)
	-- Re-apply visuals after respawn
	task.wait(1) -- Wait for character to fully load
	for _, slot in ipairs({"Head", "Body", "Legs"}) do
		appliedVisuals[slot] = nil -- Old references are invalid
		if currentEquipped[slot] then
			local item = AestheticsData.getItemById(currentEquipped[slot])
			if item then
				applyItemVisual(slot, item)
			end
		end
	end
end)

print("[AvatarController] Initialized")
