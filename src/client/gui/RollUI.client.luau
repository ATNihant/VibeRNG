-- RollUI.client.luau — Roll animation and result card display
-- Shows a dramatic pull animation when the player receives a RollResult
-- Source of truth: docs/implementation-plan.md Phase 5

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local RollResultEvent = RemoteEvents:WaitForChild("RollResult")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local rollScreen = playerGui:WaitForChild("RollScreen")

-- ============================================================
-- RARITY COLORS (duplicated from RarityConfig for client use)
-- ============================================================
local RARITY_COLORS = {
	Common    = Color3.fromRGB(180, 180, 180),
	Uncommon  = Color3.fromRGB(30, 200, 80),
	Rare      = Color3.fromRGB(50, 120, 255),
	Epic      = Color3.fromRGB(160, 50, 255),
	Legendary = Color3.fromRGB(255, 150, 0),
	Mythic    = Color3.fromRGB(255, 40, 80),
}

local RARITY_BG_COLORS = {
	Common    = Color3.fromRGB(40, 40, 45),
	Uncommon  = Color3.fromRGB(15, 45, 25),
	Rare      = Color3.fromRGB(15, 30, 60),
	Epic      = Color3.fromRGB(35, 15, 55),
	Legendary = Color3.fromRGB(55, 35, 10),
	Mythic    = Color3.fromRGB(55, 10, 20),
}

-- ============================================================
-- BUILD UI ELEMENTS (programmatic)
-- ============================================================

-- Dark overlay
local overlay = Instance.new("Frame")
overlay.Name = "Overlay"
overlay.Size = UDim2.fromScale(1, 1)
overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
overlay.BackgroundTransparency = 1
overlay.BorderSizePixel = 0
overlay.ZIndex = 10
overlay.Parent = rollScreen

-- Spinning reel container
local reelContainer = Instance.new("Frame")
reelContainer.Name = "ReelContainer"
reelContainer.Size = UDim2.fromOffset(300, 80)
reelContainer.Position = UDim2.fromScale(0.5, 0.4)
reelContainer.AnchorPoint = Vector2.new(0.5, 0.5)
reelContainer.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
reelContainer.BorderSizePixel = 0
reelContainer.Visible = false
reelContainer.ZIndex = 11
reelContainer.ClipsDescendants = true
reelContainer.Parent = rollScreen

local reelCorner = Instance.new("UICorner")
reelCorner.CornerRadius = UDim.new(0, 12)
reelCorner.Parent = reelContainer

local reelStroke = Instance.new("UIStroke")
reelStroke.Color = Color3.fromRGB(139, 0, 255) -- purple neon
reelStroke.Thickness = 2
reelStroke.Parent = reelContainer

-- Reel items (will be animated)
local reelFrame = Instance.new("Frame")
reelFrame.Name = "ReelFrame"
reelFrame.Size = UDim2.fromOffset(300, 2000) -- tall to hold many items
reelFrame.Position = UDim2.fromOffset(0, 0)
reelFrame.BackgroundTransparency = 1
reelFrame.ZIndex = 12
reelFrame.Parent = reelContainer

-- Result card
local resultCard = Instance.new("Frame")
resultCard.Name = "ResultCard"
resultCard.Size = UDim2.fromOffset(320, 420)
resultCard.Position = UDim2.fromScale(0.5, 0.5)
resultCard.AnchorPoint = Vector2.new(0.5, 0.5)
resultCard.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
resultCard.BorderSizePixel = 0
resultCard.Visible = false
resultCard.ZIndex = 15
resultCard.Parent = rollScreen

local resultCorner = Instance.new("UICorner")
resultCorner.CornerRadius = UDim.new(0, 16)
resultCorner.Parent = resultCard

local resultStroke = Instance.new("UIStroke")
resultStroke.Color = Color3.fromRGB(139, 0, 255)
resultStroke.Thickness = 3
resultStroke.Parent = resultCard

-- Gradient glow at top of card
local glowFrame = Instance.new("Frame")
glowFrame.Name = "Glow"
glowFrame.Size = UDim2.new(1, 0, 0, 120)
glowFrame.Position = UDim2.fromScale(0, 0)
glowFrame.BackgroundColor3 = Color3.fromRGB(139, 0, 255)
glowFrame.BorderSizePixel = 0
glowFrame.ZIndex = 16
glowFrame.Parent = resultCard

local glowCorner = Instance.new("UICorner")
glowCorner.CornerRadius = UDim.new(0, 16)
glowCorner.Parent = glowFrame

local glowGradient = Instance.new("UIGradient")
glowGradient.Transparency = NumberSequence.new({
	NumberSequenceKeypoint.new(0, 0.3),
	NumberSequenceKeypoint.new(1, 1),
})
glowGradient.Rotation = 90
glowGradient.Parent = glowFrame

-- Item icon placeholder
local iconFrame = Instance.new("Frame")
iconFrame.Name = "IconFrame"
iconFrame.Size = UDim2.fromOffset(150, 150)
iconFrame.Position = UDim2.new(0.5, 0, 0, 40)
iconFrame.AnchorPoint = Vector2.new(0.5, 0)
iconFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
iconFrame.BorderSizePixel = 0
iconFrame.ZIndex = 17
iconFrame.Parent = resultCard

local iconCorner = Instance.new("UICorner")
iconCorner.CornerRadius = UDim.new(0, 12)
iconCorner.Parent = iconFrame

local iconImage = Instance.new("ImageLabel")
iconImage.Name = "Icon"
iconImage.Size = UDim2.fromScale(0.8, 0.8)
iconImage.Position = UDim2.fromScale(0.5, 0.5)
iconImage.AnchorPoint = Vector2.new(0.5, 0.5)
iconImage.BackgroundTransparency = 1
iconImage.ZIndex = 18
iconImage.Parent = iconFrame

-- Item name label
local nameLabel = Instance.new("TextLabel")
nameLabel.Name = "ItemName"
nameLabel.Size = UDim2.new(0.9, 0, 0, 36)
nameLabel.Position = UDim2.new(0.5, 0, 0, 210)
nameLabel.AnchorPoint = Vector2.new(0.5, 0)
nameLabel.BackgroundTransparency = 1
nameLabel.Font = Enum.Font.GothamBold
nameLabel.TextSize = 24
nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
nameLabel.Text = ""
nameLabel.ZIndex = 17
nameLabel.Parent = resultCard

-- Rarity label
local rarityLabel = Instance.new("TextLabel")
rarityLabel.Name = "RarityLabel"
rarityLabel.Size = UDim2.new(0.5, 0, 0, 30)
rarityLabel.Position = UDim2.new(0.5, 0, 0, 252)
rarityLabel.AnchorPoint = Vector2.new(0.5, 0)
rarityLabel.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
rarityLabel.BorderSizePixel = 0
rarityLabel.Font = Enum.Font.GothamBold
rarityLabel.TextSize = 16
rarityLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
rarityLabel.Text = ""
rarityLabel.ZIndex = 17
rarityLabel.Parent = resultCard

local rarityCorner = Instance.new("UICorner")
rarityCorner.CornerRadius = UDim.new(0, 8)
rarityCorner.Parent = rarityLabel

-- Aesthetic family label
local aestheticLabel = Instance.new("TextLabel")
aestheticLabel.Name = "AestheticLabel"
aestheticLabel.Size = UDim2.new(0.8, 0, 0, 24)
aestheticLabel.Position = UDim2.new(0.5, 0, 0, 295)
aestheticLabel.AnchorPoint = Vector2.new(0.5, 0)
aestheticLabel.BackgroundTransparency = 1
aestheticLabel.Font = Enum.Font.Gotham
aestheticLabel.TextSize = 14
aestheticLabel.TextColor3 = Color3.fromRGB(160, 160, 170)
aestheticLabel.Text = ""
aestheticLabel.ZIndex = 17
aestheticLabel.Parent = resultCard

-- Slot label
local slotLabel = Instance.new("TextLabel")
slotLabel.Name = "SlotLabel"
slotLabel.Size = UDim2.new(0.8, 0, 0, 24)
slotLabel.Position = UDim2.new(0.5, 0, 0, 325)
slotLabel.AnchorPoint = Vector2.new(0.5, 0)
slotLabel.BackgroundTransparency = 1
slotLabel.Font = Enum.Font.Gotham
slotLabel.TextSize = 14
slotLabel.TextColor3 = Color3.fromRGB(120, 120, 130)
slotLabel.Text = ""
slotLabel.ZIndex = 17
slotLabel.Parent = resultCard

-- Coin drop label
local coinLabel = Instance.new("TextLabel")
coinLabel.Name = "CoinLabel"
coinLabel.Size = UDim2.new(0.6, 0, 0, 30)
coinLabel.Position = UDim2.new(0.5, 0, 0, 365)
coinLabel.AnchorPoint = Vector2.new(0.5, 0)
coinLabel.BackgroundColor3 = Color3.fromRGB(35, 35, 15)
coinLabel.BorderSizePixel = 0
coinLabel.Font = Enum.Font.GothamBold
coinLabel.TextSize = 14
coinLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
coinLabel.Text = ""
coinLabel.ZIndex = 17
coinLabel.Parent = resultCard

local coinCorner = Instance.new("UICorner")
coinCorner.CornerRadius = UDim.new(0, 8)
coinCorner.Parent = coinLabel

-- ============================================================
-- COIN DROPS (duplicate from RarityConfig for display)
-- ============================================================
local COIN_DROPS = {
	Common    = 5,
	Uncommon  = 15,
	Rare      = 50,
	Epic      = 150,
	Legendary = 500,
	Mythic    = 2000,
}

-- ============================================================
-- ANIMATION FUNCTIONS
-- ============================================================
local isAnimating = false

local function playRollAnimation(item)
	if isAnimating then return end
	isAnimating = true

	local rarityColor = RARITY_COLORS[item.rarity] or Color3.fromRGB(255, 255, 255)
	local bgColor = RARITY_BG_COLORS[item.rarity] or Color3.fromRGB(25, 25, 30)
	local isEpicPlus = (item.rarity == "Epic" or item.rarity == "Legendary" or item.rarity == "Mythic")
	local isMythic = (item.rarity == "Mythic")

	-- 1. Fade in overlay
	overlay.BackgroundTransparency = 1
	overlay.Visible = true
	TweenService:Create(overlay, TweenInfo.new(0.3), {
		BackgroundTransparency = 0.6
	}):Play()

	-- 2. Show reel and spin
	reelContainer.Visible = true
	reelContainer.Size = UDim2.fromOffset(300, 80)
	reelContainer.Position = UDim2.fromScale(0.5, 0.4)

	-- Create reel items
	for _, child in ipairs(reelFrame:GetChildren()) do
		child:Destroy()
	end

	local ITEM_HEIGHT = 80
	local ITEM_COUNT = 30 -- number of dummy items in the reel
	local allItems = {}

	-- Get all items for visual variety in the reel
	local Data = ReplicatedStorage:WaitForChild("Data")
	local AestheticsData = require(Data:WaitForChild("AestheticsData"))
	local allItemsList = AestheticsData.getAllItems()

	for i = 1, ITEM_COUNT do
		local reelItem
		if i == ITEM_COUNT then
			-- Last item is the actual result
			reelItem = item
		else
			-- Random filler
			reelItem = allItemsList[math.random(1, #allItemsList)]
		end

		local itemFrame = Instance.new("Frame")
		itemFrame.Size = UDim2.new(1, 0, 0, ITEM_HEIGHT)
		itemFrame.Position = UDim2.fromOffset(0, (i - 1) * ITEM_HEIGHT)
		itemFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
		itemFrame.BorderSizePixel = 0
		itemFrame.ZIndex = 12
		itemFrame.Parent = reelFrame

		local itemName = Instance.new("TextLabel")
		itemName.Size = UDim2.new(0.7, 0, 0.5, 0)
		itemName.Position = UDim2.fromOffset(15, 10)
		itemName.BackgroundTransparency = 1
		itemName.Font = Enum.Font.GothamBold
		itemName.TextSize = 16
		itemName.TextColor3 = RARITY_COLORS[reelItem.rarity] or Color3.fromRGB(200, 200, 200)
		itemName.Text = reelItem.name
		itemName.TextXAlignment = Enum.TextXAlignment.Left
		itemName.ZIndex = 13
		itemName.Parent = itemFrame

		local itemRarity = Instance.new("TextLabel")
		itemRarity.Size = UDim2.new(0.5, 0, 0.3, 0)
		itemRarity.Position = UDim2.new(0, 15, 0.55, 0)
		itemRarity.BackgroundTransparency = 1
		itemRarity.Font = Enum.Font.Gotham
		itemRarity.TextSize = 12
		itemRarity.TextColor3 = Color3.fromRGB(120, 120, 130)
		itemRarity.Text = reelItem.rarity .. " • " .. reelItem.aesthetic
		itemRarity.TextXAlignment = Enum.TextXAlignment.Left
		itemRarity.ZIndex = 13
		itemRarity.Parent = itemFrame

		local divider = Instance.new("Frame")
		divider.Size = UDim2.new(0.9, 0, 0, 1)
		divider.Position = UDim2.new(0.05, 0, 1, -1)
		divider.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
		divider.BorderSizePixel = 0
		divider.ZIndex = 13
		divider.Parent = itemFrame
	end

	-- Animate the reel scroll
	reelFrame.Position = UDim2.fromOffset(0, 0)

	local targetY = -((ITEM_COUNT - 1) * ITEM_HEIGHT)
	local spinDuration = isEpicPlus and 3.5 or 2.0 -- Epic+ spins slower for drama
	local easingStyle = isEpicPlus and Enum.EasingStyle.Quint or Enum.EasingStyle.Quad

	local spinTween = TweenService:Create(
		reelFrame,
		TweenInfo.new(spinDuration, easingStyle, Enum.EasingDirection.Out),
		{ Position = UDim2.fromOffset(0, targetY) }
	)
	spinTween:Play()

	-- Change reel border color to match rarity as it slows down
	task.delay(spinDuration * 0.6, function()
		TweenService:Create(reelStroke, TweenInfo.new(0.5), {
			Color = rarityColor
		}):Play()
	end)

	spinTween.Completed:Wait()

	-- Small pause for anticipation on Epic+
	if isEpicPlus then
		task.wait(0.5)
	end

	-- 3. Hide reel, show result card
	reelContainer.Visible = false
	reelStroke.Color = Color3.fromRGB(139, 0, 255) -- reset

	-- Set result card content
	resultCard.BackgroundColor3 = bgColor
	resultStroke.Color = rarityColor
	glowFrame.BackgroundColor3 = rarityColor

	if item.icon and item.icon ~= "rbxassetid://0" then
		iconImage.Image = item.icon
	else
		iconImage.Image = ""
	end

	-- Show slot icon text as placeholder
	local slotIcons = { Head = "👑", Body = "👔", Legs = "👟" }
	if iconImage.Image == "" then
		local slotIcon = Instance.new("TextLabel")
		slotIcon.Name = "SlotIcon"
		slotIcon.Size = UDim2.fromScale(1, 1)
		slotIcon.BackgroundTransparency = 1
		slotIcon.Font = Enum.Font.GothamBold
		slotIcon.TextSize = 48
		slotIcon.TextColor3 = rarityColor
		slotIcon.Text = slotIcons[item.slot] or "?"
		slotIcon.ZIndex = 18
		slotIcon.Parent = iconFrame

		-- Clean up later
		task.delay(4, function()
			if slotIcon.Parent then slotIcon:Destroy() end
		end)
	end

	nameLabel.Text = item.name
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)

	rarityLabel.Text = "  " .. item.rarity:upper() .. "  "
	rarityLabel.TextColor3 = rarityColor
	rarityLabel.BackgroundColor3 = Color3.new(
		rarityColor.R * 0.2,
		rarityColor.G * 0.2,
		rarityColor.B * 0.2
	)

	aestheticLabel.Text = "✦ " .. item.aesthetic
	slotLabel.Text = item.slot:upper() .. " SLOT"

	local coinDrop = COIN_DROPS[item.rarity] or 0
	coinLabel.Text = "💰 +" .. tostring(coinDrop) .. " Vibe Coins"

	-- Animate card entrance
	resultCard.Position = UDim2.fromScale(0.5, 1.5) -- start below screen
	resultCard.Visible = true
	resultCard.Size = UDim2.fromOffset(320, 420)

	local entranceTween = TweenService:Create(
		resultCard,
		TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Position = UDim2.fromScale(0.5, 0.5) }
	)
	entranceTween:Play()

	-- Mythic: pulse the card
	if isMythic then
		task.spawn(function()
			for _ = 1, 3 do
				TweenService:Create(resultCard, TweenInfo.new(0.2), {
					Size = UDim2.fromOffset(330, 430)
				}):Play()
				task.wait(0.2)
				TweenService:Create(resultCard, TweenInfo.new(0.2), {
					Size = UDim2.fromOffset(320, 420)
				}):Play()
				task.wait(0.2)
			end
		end)
	end

	-- 4. Wait then fade out
	task.wait(isEpicPlus and 4 or 3)

	-- Fade out
	TweenService:Create(overlay, TweenInfo.new(0.5), {
		BackgroundTransparency = 1
	}):Play()

	TweenService:Create(resultCard, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Position = UDim2.fromScale(0.5, -0.5)
	}):Play()

	task.wait(0.5)

	resultCard.Visible = false
	overlay.Visible = false

	-- Clean up reel items
	for _, child in ipairs(reelFrame:GetChildren()) do
		child:Destroy()
	end

	isAnimating = false
end

-- ============================================================
-- CONNECTION
-- ============================================================
RollResultEvent.OnClientEvent:Connect(function(item)
	if item and item.name then
		playRollAnimation(item)
	end
end)

rollScreen.Enabled = true

print("[RollUI] Initialized")
