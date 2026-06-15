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

-- Rarities that ALWAYS show the full popup even when hide mode is on
local ALWAYS_SHOW = { Epic = true, Legendary = true, Mythic = true }

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
resultCard.Size = UDim2.fromOffset(320, 460)
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

-- Equip Now button (appears after animation)
local equipNowButton = Instance.new("TextButton")
equipNowButton.Name = "EquipNowButton"
equipNowButton.Size = UDim2.new(0.75, 0, 0, 34)
equipNowButton.Position = UDim2.new(0.5, 0, 0, 408)
equipNowButton.AnchorPoint = Vector2.new(0.5, 0)
equipNowButton.BackgroundColor3 = Color3.fromRGB(70, 10, 150)
equipNowButton.BorderSizePixel = 0
equipNowButton.Font = Enum.Font.GothamBold
equipNowButton.TextSize = 14
equipNowButton.TextColor3 = Color3.fromRGB(255, 255, 255)
equipNowButton.Text = "🎒 EQUIP NOW"
equipNowButton.Visible = false
equipNowButton.ZIndex = 17
equipNowButton.Parent = resultCard

local equipNowCorner = Instance.new("UICorner")
equipNowCorner.CornerRadius = UDim.new(0, 8)
equipNowCorner.Parent = equipNowButton

local equipNowStroke = Instance.new("UIStroke")
equipNowStroke.Color = Color3.fromRGB(160, 80, 255)
equipNowStroke.Thickness = 2
equipNowStroke.Parent = equipNowButton

-- ============================================================
-- TOAST NOTIFICATION (shown for hidden rolls)
-- ============================================================
local toastFrame = Instance.new("Frame")
toastFrame.Name = "RollToast"
toastFrame.Size = UDim2.fromOffset(260, 44)
toastFrame.Position = UDim2.new(0.5, 0, 0, -60) -- starts off-screen top
toastFrame.AnchorPoint = Vector2.new(0.5, 0)
toastFrame.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
toastFrame.BorderSizePixel = 0
toastFrame.Visible = false
toastFrame.ZIndex = 20
toastFrame.Parent = rollScreen

local toastCorner = Instance.new("UICorner")
toastCorner.CornerRadius = UDim.new(0, 10)
toastCorner.Parent = toastFrame

local toastStroke = Instance.new("UIStroke")
toastStroke.Color = Color3.fromRGB(80, 80, 100)
toastStroke.Thickness = 1.5
toastStroke.Parent = toastFrame

local toastLabel = Instance.new("TextLabel")
toastLabel.Name = "ToastLabel"
toastLabel.Size = UDim2.fromScale(1, 1)
toastLabel.BackgroundTransparency = 1
toastLabel.Font = Enum.Font.GothamBold
toastLabel.TextSize = 14
toastLabel.TextColor3 = Color3.fromRGB(200, 200, 215)
toastLabel.Text = ""
toastLabel.ZIndex = 21
toastLabel.Parent = toastFrame

local toastActive = false
local function showToast(item)
	toastStroke.Color = RARITY_COLORS[item.rarity] or Color3.fromRGB(80, 80, 100)
	toastLabel.Text = "Got: " .. item.name .. " (" .. item.rarity .. ")"
	toastFrame.Visible = true
	toastFrame.BackgroundTransparency = 0
	toastLabel.TextTransparency = 0
	toastStroke.Transparency = 0

	-- Slide in from top
	toastFrame.Position = UDim2.new(0.5, 0, 0, -50)
	TweenService:Create(toastFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0, 16)
	}):Play()

	task.delay(2.2, function()
		-- Fade + slide out
		TweenService:Create(toastFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.new(0.5, 0, 0, -50),
			BackgroundTransparency = 1,
		}):Play()
		TweenService:Create(toastLabel, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
		TweenService:Create(toastStroke, TweenInfo.new(0.3), { Transparency = 1 }):Play()
		task.delay(0.35, function() toastFrame.Visible = false end)
	end)
end

local equipNowGradient = Instance.new("UIGradient")
equipNowGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(130, 30, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(60, 5, 140)),
})
equipNowGradient.Rotation = 90
equipNowGradient.Parent = equipNowButton

-- ============================================================
-- BOTTOM BUTTON BAR (Gen-Z pill layout)
-- ============================================================

-- Frosted glass backdrop
local barBg = Instance.new("Frame")
barBg.Name = "BarBg"
barBg.Size = UDim2.fromOffset(370, 76)
barBg.Position = UDim2.new(0.5, 0, 1, -54)
barBg.AnchorPoint = Vector2.new(0.5, 1)
barBg.BackgroundColor3 = Color3.fromRGB(10, 10, 18)
barBg.BackgroundTransparency = 0.25
barBg.BorderSizePixel = 0
barBg.ZIndex = 4
barBg.Parent = rollScreen

local barBgCorner = Instance.new("UICorner")
barBgCorner.CornerRadius = UDim.new(1, 0)
barBgCorner.Parent = barBg

local barBgStroke = Instance.new("UIStroke")
barBgStroke.Color = Color3.fromRGB(120, 80, 255)
barBgStroke.Transparency = 0.4
barBgStroke.Thickness = 1.5
barBgStroke.Parent = barBg

-- Shimmer the bar border
task.spawn(function()
	while true do
		TweenService:Create(barBgStroke, TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
			Color = Color3.fromRGB(255, 80, 200)
		}):Play()
		task.wait(1.8)
		TweenService:Create(barBgStroke, TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
			Color = Color3.fromRGB(80, 160, 255)
		}):Play()
		task.wait(1.8)
	end
end)

-- Invisible container for button layout (same var name used below)
local rollButtonContainer = Instance.new("Frame")
rollButtonContainer.Name = "RollButtonContainer"
rollButtonContainer.Size = UDim2.fromOffset(356, 60)
rollButtonContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
rollButtonContainer.AnchorPoint = Vector2.new(0.5, 0.5)
rollButtonContainer.BackgroundTransparency = 1
rollButtonContainer.ZIndex = 5
rollButtonContainer.Parent = barBg

-- Faint glow under the ROLL button (kept for compat)
local rollGlow = Instance.new("Frame")
rollGlow.Name = "RollGlow"
rollGlow.Size = UDim2.fromOffset(230, 60)
rollGlow.Position = UDim2.fromOffset(0, 0)
rollGlow.BackgroundColor3 = Color3.fromRGB(200, 60, 255)
rollGlow.BackgroundTransparency = 0.85
rollGlow.BorderSizePixel = 0
rollGlow.ZIndex = 4
rollGlow.Parent = rollButtonContainer
Instance.new("UICorner", rollGlow).CornerRadius = UDim.new(1, 0)

-- Pulse glow
task.spawn(function()
	while true do
		TweenService:Create(rollGlow, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
			Size = UDim2.fromOffset(250, 70),
			Position = UDim2.fromOffset(-10, -5),
			BackgroundTransparency = 0.7,
		}):Play()
		task.wait(1.2)
		TweenService:Create(rollGlow, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
			Size = UDim2.fromOffset(230, 60),
			Position = UDim2.fromOffset(0, 0),
			BackgroundTransparency = 0.85,
		}):Play()
		task.wait(1.2)
	end
end)

-- ✨ MAIN ROLL BUTTON — chunky iridescent pill
local mainRollButton = Instance.new("TextButton")
mainRollButton.Name = "MainRollButton"
mainRollButton.Size = UDim2.fromOffset(230, 60)
mainRollButton.Position = UDim2.fromOffset(0, 0)
mainRollButton.BackgroundColor3 = Color3.fromRGB(180, 40, 255)
mainRollButton.BorderSizePixel = 0
mainRollButton.Font = Enum.Font.GothamBold
mainRollButton.TextSize = 22
mainRollButton.TextColor3 = Color3.fromRGB(255, 255, 255)
mainRollButton.Text = "✨ ROLL IT"
mainRollButton.ZIndex = 5
mainRollButton.Parent = rollButtonContainer

local mainRollCorner = Instance.new("UICorner")
mainRollCorner.CornerRadius = UDim.new(1, 0) -- full pill
mainRollCorner.Parent = mainRollButton

local mainRollStroke = Instance.new("UIStroke")
mainRollStroke.Color = Color3.fromRGB(255, 180, 255)
mainRollStroke.Thickness = 2
mainRollStroke.Parent = mainRollButton

local mainRollGradient = Instance.new("UIGradient")
mainRollGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0,   Color3.fromRGB(255, 60, 180)),  -- hot pink
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(160, 40, 255)),  -- purple
	ColorSequenceKeypoint.new(1,   Color3.fromRGB(80, 180, 255)),  -- cyan
})
mainRollGradient.Rotation = 135
mainRollGradient.Parent = mainRollButton

-- Rainbow shimmer loop on ROLL button
task.spawn(function()
	while true do
		TweenService:Create(mainRollGradient, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
			Rotation = 225
		}):Play()
		task.wait(2)
		TweenService:Create(mainRollGradient, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
			Rotation = 135
		}):Play()
		task.wait(2)
	end
end)

-- 🔁 AUTO button
local autoRollButton = Instance.new("TextButton")
autoRollButton.Name = "AutoRollButton"
autoRollButton.Size = UDim2.fromOffset(56, 60)
autoRollButton.Position = UDim2.fromOffset(238, 0)
autoRollButton.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
autoRollButton.BorderSizePixel = 0
autoRollButton.Font = Enum.Font.GothamBold
autoRollButton.TextSize = 11
autoRollButton.TextColor3 = Color3.fromRGB(140, 140, 160)
autoRollButton.Text = "🔁\nAUTO"
autoRollButton.ZIndex = 5
autoRollButton.Parent = rollButtonContainer

local autoRollCorner = Instance.new("UICorner")
autoRollCorner.CornerRadius = UDim.new(1, 0)
autoRollCorner.Parent = autoRollButton

local autoRollStroke = Instance.new("UIStroke")
autoRollStroke.Color = Color3.fromRGB(70, 70, 90)
autoRollStroke.Thickness = 1.5
autoRollStroke.Parent = autoRollButton

-- 👁️ HIDE/SHOW button
local hideButton = Instance.new("TextButton")
hideButton.Name = "HideResultsButton"
hideButton.Size = UDim2.fromOffset(56, 60)
hideButton.Position = UDim2.fromOffset(300, 0)
hideButton.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
hideButton.BorderSizePixel = 0
hideButton.Font = Enum.Font.GothamBold
hideButton.TextSize = 11
hideButton.TextColor3 = Color3.fromRGB(140, 140, 160)
hideButton.Text = "👁️\nSHOW"
hideButton.ZIndex = 5
hideButton.Parent = rollButtonContainer

local hideButtonCorner = Instance.new("UICorner")
hideButtonCorner.CornerRadius = UDim.new(1, 0)
hideButtonCorner.Parent = hideButton

local hideButtonStroke = Instance.new("UIStroke")
hideButtonStroke.Color = Color3.fromRGB(70, 70, 90)
hideButtonStroke.Thickness = 1.5
hideButtonStroke.Parent = hideButton

-- Shared hover/press tweens for small buttons
local function smallBtnHover(btn)
	TweenService:Create(btn, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.fromOffset(62, 66),
		Position = btn.Position - UDim2.fromOffset(3, 3)
	}):Play()
end
local function smallBtnLeave(btn, origPos)
	TweenService:Create(btn, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.fromOffset(56, 60),
		Position = origPos
	}):Play()
end
local function smallBtnPress(btn, origPos)
	TweenService:Create(btn, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.fromOffset(52, 56),
		Position = origPos + UDim2.fromOffset(2, 2)
	}):Play()
end

local autoOrigPos = autoRollButton.Position
autoRollButton.MouseEnter:Connect(function()  smallBtnHover(autoRollButton) end)
autoRollButton.MouseLeave:Connect(function()  smallBtnLeave(autoRollButton, autoOrigPos) end)
autoRollButton.MouseButton1Down:Connect(function() smallBtnPress(autoRollButton, autoOrigPos) end)
autoRollButton.MouseButton1Up:Connect(function()   smallBtnLeave(autoRollButton, autoOrigPos) end)

local hideOrigPos = hideButton.Position
hideButton.MouseEnter:Connect(function()  smallBtnHover(hideButton) end)
hideButton.MouseLeave:Connect(function()  smallBtnLeave(hideButton, hideOrigPos) end)
hideButton.MouseButton1Down:Connect(function() smallBtnPress(hideButton, hideOrigPos) end)
hideButton.MouseButton1Up:Connect(function()   smallBtnLeave(hideButton, hideOrigPos) end)

local hideResults = false

hideButton.MouseButton1Click:Connect(function()
	hideResults = not hideResults
	if hideResults then
		hideButton.BackgroundColor3 = Color3.fromRGB(40, 5, 30)
		hideButton.TextColor3 = Color3.fromRGB(255, 80, 180)
		hideButton.Text = "🙈\nHIDE"
		hideButtonStroke.Color = Color3.fromRGB(255, 60, 160)
	else
		hideButton.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
		hideButton.TextColor3 = Color3.fromRGB(140, 140, 160)
		hideButton.Text = "👁️\nSHOW"
		hideButtonStroke.Color = Color3.fromRGB(70, 70, 90)
	end
end)

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
		local existing = iconFrame:FindFirstChild("SlotIcon")
		if existing then existing:Destroy() end
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
	resultCard.Position = UDim2.fromScale(0.5, 1.5)
	resultCard.Visible = true
	resultCard.Size = UDim2.fromOffset(320, 460)

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

	-- Screen Shake for Legendary / Mythic
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
					Size = UDim2.fromOffset(330, 470)
				}):Play()
				task.wait(0.2)
				TweenService:Create(resultCard, TweenInfo.new(0.2), {
					Size = UDim2.fromOffset(320, 460)
				}):Play()
				task.wait(0.2)
			end
		end)
	end

	-- Show Equip Now button
	equipNowButton.Visible = true
	equipNowButton.BackgroundTransparency = 1
	equipNowStroke.Transparency = 1
	TweenService:Create(equipNowButton, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		BackgroundTransparency = 0,
	}):Play()
	TweenService:Create(equipNowStroke, TweenInfo.new(0.4), {
		Transparency = 0,
	}):Play()

	-- Wire up Equip Now button
	local equipConn
	equipConn = equipNowButton.MouseButton1Click:Connect(function()
		if equipConn then equipConn:Disconnect() end
		isAnimating = false
		equipNowButton.Visible = false
		TweenService:Create(resultCard, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Position = UDim2.fromScale(0.5, -0.5)
		}):Play()
		TweenService:Create(overlay, TweenInfo.new(0.3), {
			BackgroundTransparency = 1
		}):Play()
		task.delay(0.35, function()
			resultCard.Visible = false
			overlay.Visible = false
			auraImage.Visible = false
			for _, child in ipairs(reelFrame:GetChildren()) do child:Destroy() end
			mainRollButton.Text = "🎲 ROLL"
			mainRollButton.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
			mainRollStroke.Color = Color3.fromRGB(150, 220, 255)
			mainRollGradient.Enabled = true
		end)
		task.delay(0.2, function()
			if _G.InventoryController then
				_G.InventoryController.OpenToSlot(item.slot)
			else
				local lookbookScreen = player.PlayerGui:FindFirstChild("LookbookScreen")
				if lookbookScreen then
					lookbookScreen.Enabled = true
				end
			end
		end)
	end)

	-- 4. Wait then auto-fade out
	task.wait(isEpicPlus and 4.5 or 3.5)

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
	equipNowButton.Visible = false

	for _, child in ipairs(reelFrame:GetChildren()) do
		child:Destroy()
	end

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

-- ============================================================
-- ROLL BUTTON HOVER / PRESS TWEENS
-- ============================================================
mainRollButton.MouseEnter:Connect(function()
	if not isAnimating then
		TweenService:Create(mainRollButton, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.fromOffset(244, 66),
			Position = UDim2.fromOffset(-7, -3)
		}):Play()
	end
end)

mainRollButton.MouseLeave:Connect(function()
	if not isAnimating then
		TweenService:Create(mainRollButton, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.fromOffset(230, 60),
			Position = UDim2.fromOffset(0, 0)
		}):Play()
	end
end)

mainRollButton.MouseButton1Down:Connect(function()
	if not isAnimating then
		TweenService:Create(mainRollButton, TweenInfo.new(0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.fromOffset(220, 55),
			Position = UDim2.fromOffset(5, 2)
		}):Play()
	end
end)

mainRollButton.MouseButton1Up:Connect(function()
	if not isAnimating then
		TweenService:Create(mainRollButton, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.fromOffset(244, 66),
			Position = UDim2.fromOffset(-7, -3)
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
			autoRollButton.BackgroundColor3 = Color3.fromRGB(10, 35, 10)
			autoRollButton.TextColor3 = Color3.fromRGB(100, 255, 120)
			autoRollButton.Text = "🔄\nLIVE"
			autoRollStroke.Color = Color3.fromRGB(60, 255, 100)
			if not isAnimating then
				requestRoll()
			end
		else
			autoRollButton.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
			autoRollButton.TextColor3 = Color3.fromRGB(140, 140, 160)
			autoRollButton.Text = "🔁\nAUTO"
			autoRollStroke.Color = Color3.fromRGB(70, 70, 90)
		end
	else
		MarketplaceService:PromptGamePassPurchase(player, AUTO_ROLL_GAMEPASS_ID)
	end
end)

RollResultEvent.OnClientEvent:Connect(function(item)
	if item and item.name then
		local shouldShow = ALWAYS_SHOW[item.rarity] or not hideResults

		if shouldShow then
			playRollAnimation(item)
		else
			-- Silent roll — just show a small toast
			showToast(item)
			-- Re-enable roll button immediately (no animation lock)
			mainRollButton.Text = "🎲 ROLL"
			mainRollButton.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
			mainRollStroke.Color = Color3.fromRGB(150, 220, 255)
			mainRollGradient.Enabled = true
		end

		-- Loop auto roll if enabled
		if autoRollEnabled then
			if shouldShow then
				-- wait for animation to finish before next roll
				task.wait(0.2)
			end
			requestRoll()
		end
	end
end)

rollScreen.Enabled = true

print("[RollUI] Initialized")
