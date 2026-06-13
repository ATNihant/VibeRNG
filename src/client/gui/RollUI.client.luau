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

-- Aura Rays (Background for Epic+)
local auraImage = Instance.new("ImageLabel")
auraImage.Name = "AuraRays"
auraImage.Size = UDim2.fromOffset(1200, 1200)
auraImage.Position = UDim2.fromScale(0.5, 0.5)
auraImage.AnchorPoint = Vector2.new(0.5, 0.5)
auraImage.BackgroundTransparency = 1
auraImage.Image = "rbxassetid://136817114" -- Common sunburst light rays
auraImage.ImageTransparency = 0.5
auraImage.Visible = false
auraImage.ZIndex = 10
auraImage.Parent = rollScreen

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
-- MAIN ROLL BUTTON & AUTO-ROLL (Bottom Center)
-- ============================================================
local rollButtonContainer = Instance.new("Frame")
rollButtonContainer.Name = "RollButtonContainer"
rollButtonContainer.Size = UDim2.fromOffset(280, 60)
rollButtonContainer.Position = UDim2.new(0.5, 0, 1, -80)
rollButtonContainer.AnchorPoint = Vector2.new(0.5, 0.5)
rollButtonContainer.BackgroundTransparency = 1
rollButtonContainer.ZIndex = 5
rollButtonContainer.Parent = rollScreen

-- Glowing Pulse Background
local rollGlow = Instance.new("Frame")
rollGlow.Size = UDim2.fromScale(1, 1)
rollGlow.Position = UDim2.fromScale(0.5, 0.5)
rollGlow.AnchorPoint = Vector2.new(0.5, 0.5)
rollGlow.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
rollGlow.BackgroundTransparency = 0.2
rollGlow.ZIndex = 4
rollGlow.Parent = rollButtonContainer

local glowCorner = Instance.new("UICorner")
glowCorner.CornerRadius = UDim.new(0, 12)
glowCorner.Parent = rollGlow

-- Main Roll Button
local mainRollButton = Instance.new("TextButton")
mainRollButton.Name = "MainRollButton"
mainRollButton.Size = UDim2.fromOffset(220, 60)
mainRollButton.Position = UDim2.new(0, 0, 0, 0)
mainRollButton.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
mainRollButton.BorderSizePixel = 0
mainRollButton.Font = Enum.Font.GothamBold
mainRollButton.TextSize = 24
mainRollButton.TextColor3 = Color3.fromRGB(255, 255, 255)
mainRollButton.Text = "🎲 ROLL"
mainRollButton.ZIndex = 5
mainRollButton.Parent = rollButtonContainer

local mainRollCorner = Instance.new("UICorner")
mainRollCorner.CornerRadius = UDim.new(0, 12)
mainRollCorner.Parent = mainRollButton

local mainRollStroke = Instance.new("UIStroke")
mainRollStroke.Color = Color3.fromRGB(150, 220, 255)
mainRollStroke.Thickness = 2
mainRollStroke.Parent = mainRollButton

local mainRollGradient = Instance.new("UIGradient")
mainRollGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 200, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 100, 200)),
})
mainRollGradient.Rotation = 90
mainRollGradient.Parent = mainRollButton

-- Auto-Roll Button
local autoRollButton = Instance.new("TextButton")
autoRollButton.Name = "AutoRollButton"
autoRollButton.Size = UDim2.fromOffset(50, 60)
autoRollButton.Position = UDim2.new(0, 230, 0, 0)
autoRollButton.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
autoRollButton.BorderSizePixel = 0
autoRollButton.Font = Enum.Font.GothamBold
autoRollButton.TextSize = 14
autoRollButton.TextColor3 = Color3.fromRGB(150, 150, 160)
autoRollButton.Text = "AUTO\nOFF"
autoRollButton.ZIndex = 5
autoRollButton.Parent = rollButtonContainer

local autoRollCorner = Instance.new("UICorner")
autoRollCorner.CornerRadius = UDim.new(0, 12)
autoRollCorner.Parent = autoRollButton

local autoRollStroke = Instance.new("UIStroke")
autoRollStroke.Color = Color3.fromRGB(80, 80, 90)
autoRollStroke.Thickness = 2
autoRollStroke.Parent = autoRollButton

local autoRollEnabled = false
local AUTO_ROLL_GAMEPASS_ID = 12345678 -- Placeholder Gamepass ID
local MarketplaceService = game:GetService("MarketplaceService")

-- Pulse Animation Loop
task.spawn(function()
	while true do
		local tweenOut = TweenService:Create(rollGlow, TweenInfo.new(1.5, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
			Size = UDim2.fromScale(1.1, 1.2),
			BackgroundTransparency = 1
		})
		tweenOut:Play()
		tweenOut.Completed:Wait()
		rollGlow.Size = UDim2.fromScale(1, 1)
		rollGlow.BackgroundTransparency = 0.2
		task.wait(0.1)
	end
end)

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

	-- Disable roll button
	mainRollButton.Text = "Rolling..."
	mainRollButton.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
	mainRollStroke.Color = Color3.fromRGB(100, 100, 110)
	mainRollGradient.Enabled = false

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
	nameLabel.TextColor3 = rarityColor
	
	local nameStroke = nameLabel:FindFirstChild("UIStroke") or Instance.new("UIStroke")
	nameStroke.Color = Color3.fromRGB(20, 20, 25)
	nameStroke.Thickness = 2
	nameStroke.Parent = nameLabel

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
	
	if isEpicPlus then
		auraImage.Visible = true
		auraImage.ImageColor3 = rarityColor
		auraImage.Rotation = 0
		TweenService:Create(auraImage, TweenInfo.new(4, Enum.EasingStyle.Linear), {
			Rotation = 180
		}):Play()
	else
		auraImage.Visible = false
	end

	local entranceTween = TweenService:Create(
		resultCard,
		TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{ Position = UDim2.fromScale(0.5, 0.5) }
	)
	entranceTween:Play()
	
	-- Screen Shake
	if item.rarity == "Legendary" or isMythic then
		task.spawn(function()
			local character = player.Character
			local humanoid = character and character:FindFirstChild("Humanoid")
			if humanoid then
				local originalOffset = humanoid.CameraOffset
				local intensity = isMythic and 1.5 or 0.8
				for i = 1, 15 do
					humanoid.CameraOffset = originalOffset + Vector3.new(
						(math.random() - 0.5) * intensity,
						(math.random() - 0.5) * intensity,
						(math.random() - 0.5) * intensity
					)
					task.wait(0.03)
				end
				humanoid.CameraOffset = originalOffset
			end
		end)
	end
	
	-- Wobble floating animation
	task.spawn(function()
		entranceTween.Completed:Wait()
		while isAnimating do
			TweenService:Create(resultCard, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				Position = UDim2.new(0.5, 0, 0.5, -10)
			}):Play()
			task.wait(1)
			if not isAnimating then break end
			TweenService:Create(resultCard, TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				Position = UDim2.new(0.5, 0, 0.5, 10)
			}):Play()
			task.wait(1)
		end
	end)

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
	auraImage.Visible = false

	-- Clean up reel items
	for _, child in ipairs(reelFrame:GetChildren()) do
		child:Destroy()
	end

	-- Re-enable roll button
	mainRollButton.Text = "🎲 ROLL"
	mainRollButton.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
	mainRollStroke.Color = Color3.fromRGB(150, 220, 255)
	mainRollGradient.Enabled = true

	isAnimating = false
end

-- ============================================================
-- CONNECTION
-- ============================================================
local RollRequestedEvent = RemoteEvents:WaitForChild("RollRequested")

local function requestRoll()
	if not isAnimating then
		RollRequestedEvent:FireServer()
		
		-- Provide immediate visual feedback before the server responds
		mainRollButton.Text = "Requesting..."
		mainRollButton.BackgroundColor3 = Color3.fromRGB(80, 80, 90)
		mainRollStroke.Color = Color3.fromRGB(100, 100, 110)
		mainRollGradient.Enabled = false
	end
end

-- Hover Tweens
mainRollButton.MouseEnter:Connect(function()
	if not isAnimating then
		TweenService:Create(mainRollButton, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.fromOffset(230, 65),
			Position = UDim2.fromOffset(-5, -2)
		}):Play()
	end
end)

mainRollButton.MouseLeave:Connect(function()
	if not isAnimating then
		TweenService:Create(mainRollButton, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.fromOffset(220, 60),
			Position = UDim2.fromOffset(0, 0)
		}):Play()
	end
end)

-- Click Tweens & Logic
mainRollButton.MouseButton1Down:Connect(function()
	if not isAnimating then
		TweenService:Create(mainRollButton, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.fromOffset(210, 55),
			Position = UDim2.fromOffset(5, 2)
		}):Play()
	end
end)

mainRollButton.MouseButton1Up:Connect(function()
	if not isAnimating then
		TweenService:Create(mainRollButton, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.fromOffset(230, 65),
			Position = UDim2.fromOffset(-5, -2)
		}):Play()
	end
end)

mainRollButton.MouseButton1Click:Connect(requestRoll)

autoRollButton.MouseButton1Click:Connect(function()
	local success, hasPass = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, AUTO_ROLL_GAMEPASS_ID)
	end)
	
	if success and hasPass then
		autoRollEnabled = not autoRollEnabled
		if autoRollEnabled then
			autoRollButton.BackgroundColor3 = Color3.fromRGB(30, 180, 70)
			autoRollButton.TextColor3 = Color3.fromRGB(255, 255, 255)
			autoRollButton.Text = "AUTO\nON"
			autoRollStroke.Color = Color3.fromRGB(50, 220, 100)
			
			-- Instantly trigger if idle
			if not isAnimating then
				requestRoll()
			end
		else
			autoRollButton.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
			autoRollButton.TextColor3 = Color3.fromRGB(150, 150, 160)
			autoRollButton.Text = "AUTO\nOFF"
			autoRollStroke.Color = Color3.fromRGB(80, 80, 90)
		end
	else
		-- Prompt purchase
		MarketplaceService:PromptGamePassPurchase(player, AUTO_ROLL_GAMEPASS_ID)
	end
end)

RollResultEvent.OnClientEvent:Connect(function(item)
	if item and item.name then
		playRollAnimation(item)
		
		-- Loop auto roll if enabled
		if autoRollEnabled then
			task.wait(0.2)
			requestRoll()
		end
	end
end)

rollScreen.Enabled = true

print("[RollUI] Initialized")
