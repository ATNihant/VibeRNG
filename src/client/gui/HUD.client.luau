-- HUD.client.luau — Persistent heads-up display
-- Shows Vibe Coin counter, total rolls, server announcements, and inventory button
-- Source of truth: docs/implementation-plan.md Phase 5, 9

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local LookbookDataEvent = RemoteEvents:WaitForChild("LookbookData")
local ServerAnnouncement = RemoteEvents:WaitForChild("ServerAnnouncement")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local hudScreen = playerGui:WaitForChild("HUDScreen")

-- ============================================================
-- RARITY COLORS (for announcement tiers)
-- ============================================================
local TIER_COLORS = {
	Epic      = Color3.fromRGB(160, 50, 255),
	Legendary = Color3.fromRGB(255, 150, 0),
	Mythic    = Color3.fromRGB(255, 40, 80),
	Runway    = Color3.fromRGB(139, 0, 255),
	Capsule   = Color3.fromRGB(255, 200, 50),
	Info      = Color3.fromRGB(100, 100, 110),
}

-- ============================================================
-- COIN COUNTER (top-right)
-- ============================================================
local coinFrame = Instance.new("Frame")
coinFrame.Name = "CoinCounter"
coinFrame.Size = UDim2.new(0.15, 0, 0, 44) -- Responsive width
coinFrame.Position = UDim2.new(1, -10, 0, 10)
coinFrame.AnchorPoint = Vector2.new(1, 0)
coinFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
coinFrame.BorderSizePixel = 0
coinFrame.ZIndex = 5
coinFrame.Parent = hudScreen

local coinSizeConst = Instance.new("UISizeConstraint")
coinSizeConst.MinSize = Vector2.new(0, 0)
coinSizeConst.MaxSize = Vector2.new(250, 44)
coinSizeConst.Parent = coinFrame

local coinCorner = Instance.new("UICorner")
coinCorner.CornerRadius = UDim.new(0, 10)
coinCorner.Parent = coinFrame

local coinStroke = Instance.new("UIStroke")
coinStroke.Color = Color3.fromRGB(50, 50, 60)
coinStroke.Thickness = 1
coinStroke.Parent = coinFrame

local coinIcon = Instance.new("TextLabel")
coinIcon.Size = UDim2.fromOffset(36, 44)
coinIcon.Position = UDim2.fromOffset(8, 0)
coinIcon.BackgroundTransparency = 1
coinIcon.Font = Enum.Font.GothamBlack
coinIcon.TextSize = 22
coinIcon.TextColor3 = Color3.fromRGB(255, 215, 0)
coinIcon.Text = "V"
coinIcon.ZIndex = 6
coinIcon.Parent = coinFrame

local coinAmount = Instance.new("TextLabel")
coinAmount.Name = "Amount"
coinAmount.Size = UDim2.new(1, -50, 1, 0)
coinAmount.Position = UDim2.fromOffset(44, 0)
coinAmount.BackgroundTransparency = 1
coinAmount.Font = Enum.Font.GothamBold
coinAmount.TextSize = 18
coinAmount.TextColor3 = Color3.fromRGB(255, 215, 0)
coinAmount.Text = "0"
coinAmount.TextXAlignment = Enum.TextXAlignment.Left
coinAmount.ZIndex = 6
coinAmount.Parent = coinFrame

-- ============================================================
-- ROLL COUNTER (below coins)
-- ============================================================
local rollFrame = Instance.new("Frame")
rollFrame.Name = "RollCounter"
rollFrame.Size = UDim2.new(0.15, 0, 0, 32) -- Responsive width
rollFrame.Position = UDim2.new(1, -10, 0, 60)
rollFrame.AnchorPoint = Vector2.new(1, 0)
rollFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
rollFrame.BorderSizePixel = 0
rollFrame.ZIndex = 5
rollFrame.Parent = hudScreen

local rollSizeConst = Instance.new("UISizeConstraint")
rollSizeConst.MinSize = Vector2.new(0, 0)
rollSizeConst.MaxSize = Vector2.new(250, 32)
rollSizeConst.Parent = rollFrame

local rollCorner = Instance.new("UICorner")
rollCorner.CornerRadius = UDim.new(0, 8)
rollCorner.Parent = rollFrame

local rollStroke = Instance.new("UIStroke")
rollStroke.Color = Color3.fromRGB(50, 50, 60)
rollStroke.Thickness = 1
rollStroke.Parent = rollFrame

local rollIcon = Instance.new("TextLabel")
rollIcon.Size = UDim2.fromOffset(30, 32)
rollIcon.Position = UDim2.fromOffset(8, 0)
rollIcon.BackgroundTransparency = 1
rollIcon.Font = Enum.Font.GothamBlack
rollIcon.TextSize = 20
rollIcon.TextColor3 = Color3.fromRGB(180, 180, 220)
rollIcon.Text = "R"
rollIcon.ZIndex = 6
rollIcon.Parent = rollFrame

local rollAmount = Instance.new("TextLabel")
rollAmount.Name = "RollAmount"
rollAmount.Size = UDim2.new(1, -44, 1, 0)
rollAmount.Position = UDim2.fromOffset(38, 0)
rollAmount.BackgroundTransparency = 1
rollAmount.Font = Enum.Font.Gotham
rollAmount.TextSize = 13
rollAmount.TextColor3 = Color3.fromRGB(150, 150, 160)
rollAmount.Text = "0 rolls"
rollAmount.TextXAlignment = Enum.TextXAlignment.Left
rollAmount.ZIndex = 6
rollAmount.Parent = rollFrame

-- ============================================================
-- ANNOUNCEMENT FEED (top-center)
-- ============================================================
local announcementContainer = Instance.new("Frame")
announcementContainer.Name = "Announcements"
announcementContainer.Size = UDim2.new(0.5, 0, 0, 200)
announcementContainer.Position = UDim2.new(0.5, 0, 0, 5)
announcementContainer.AnchorPoint = Vector2.new(0.5, 0)
announcementContainer.BackgroundTransparency = 1
announcementContainer.ZIndex = 15
announcementContainer.ClipsDescendants = true
announcementContainer.Parent = hudScreen

local announcementLayout = Instance.new("UIListLayout")
announcementLayout.Padding = UDim.new(0, 4)
announcementLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
announcementLayout.VerticalAlignment = Enum.VerticalAlignment.Top
announcementLayout.SortOrder = Enum.SortOrder.LayoutOrder
announcementLayout.Parent = announcementContainer

-- Announcement queue state
local announcementOrder = 0

local function showAnnouncement(message, tier)
	announcementOrder = announcementOrder + 1
	local order = announcementOrder

	local color = TIER_COLORS[tier] or Color3.fromRGB(100, 100, 110)

	local annFrame = Instance.new("Frame")
	annFrame.Size = UDim2.new(1, 0, 0, 36)
	annFrame.BackgroundColor3 = Color3.new(color.R * 0.3, color.G * 0.3, color.B * 0.3)
	annFrame.BackgroundTransparency = 0.3
	annFrame.BorderSizePixel = 0
	annFrame.LayoutOrder = order
	annFrame.ZIndex = 16
	annFrame.Parent = announcementContainer

	local annCorner = Instance.new("UICorner")
	annCorner.CornerRadius = UDim.new(0, 8)
	annCorner.Parent = annFrame

	local annStroke = Instance.new("UIStroke")
	annStroke.Color = color
	annStroke.Thickness = 1
	annStroke.Transparency = 0.5
	annStroke.Parent = annFrame

	local annText = Instance.new("TextLabel")
	annText.Size = UDim2.new(0.95, 0, 1, 0)
	annText.Position = UDim2.fromScale(0.5, 0.5)
	annText.AnchorPoint = Vector2.new(0.5, 0.5)
	annText.BackgroundTransparency = 1
	annText.Font = Enum.Font.GothamBold
	annText.TextSize = 13
	annText.TextColor3 = color
	annText.Text = message
	annText.TextWrapped = true
	annText.ZIndex = 17
	annText.Parent = annFrame

	-- Slide in from right
	annFrame.Position = UDim2.new(1, 0, 0, 0)
	TweenService:Create(annFrame, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.new(0, 0, 0, 0)
	}):Play()

	-- Auto-remove after 5 seconds
	task.delay(5, function()
		if annFrame.Parent then
			TweenService:Create(annFrame, TweenInfo.new(0.3), {
				BackgroundTransparency = 1
			}):Play()
			TweenService:Create(annText, TweenInfo.new(0.3), {
				TextTransparency = 1
			}):Play()
			TweenService:Create(annStroke, TweenInfo.new(0.3), {
				Transparency = 1
			}):Play()
			task.wait(0.3)
			if annFrame.Parent then
				annFrame:Destroy()
			end
		end
	end)
end

-- ============================================================
-- DATA LISTENER
-- ============================================================
LookbookDataEvent.OnClientEvent:Connect(function(data)
	if not data then return end

	-- Animate coin count change
	local newCoins = data.VibeCoin or 0
	local currentText = tonumber(coinAmount.Text) or 0

	if newCoins ~= currentText then
		coinAmount.Text = tostring(newCoins)
		-- Flash effect
		coinAmount.TextColor3 = Color3.fromRGB(255, 255, 150)
		TweenService:Create(coinAmount, TweenInfo.new(0.5), {
			TextColor3 = Color3.fromRGB(255, 215, 0)
		}):Play()

		-- Scale pop
		coinFrame.Size = UDim2.fromOffset(190, 48)
		TweenService:Create(coinFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
			Size = UDim2.fromOffset(180, 44)
		}):Play()
	end

	-- Update roll count
	rollAmount.Text = tostring(data.TotalRolls or 0) .. " rolls"
end)

-- ============================================================
-- SERVER ANNOUNCEMENT LISTENER
-- ============================================================
ServerAnnouncement.OnClientEvent:Connect(function(message, tier)
	showAnnouncement(message, tier)
end)

-- ============================================================
-- INVENTORY BUTTON (bottom-left)
-- ============================================================
local inventoryBtnFrame = Instance.new("Frame")
inventoryBtnFrame.Name = "InventoryButtonFrame"
inventoryBtnFrame.Size = UDim2.new(0.38, 0, 0, 44) -- left half of center row
inventoryBtnFrame.Position = UDim2.new(0.5, -4, 1, -6) -- bottom center, slightly left
inventoryBtnFrame.AnchorPoint = Vector2.new(1, 1) -- anchored to bottom-right of itself
inventoryBtnFrame.BackgroundTransparency = 1
inventoryBtnFrame.ZIndex = 5
inventoryBtnFrame.Parent = hudScreen

local invBtnConst = Instance.new("UISizeConstraint")
invBtnConst.MinSize = Vector2.new(0, 0)
invBtnConst.MaxSize = Vector2.new(200, 50)
invBtnConst.Parent = inventoryBtnFrame

-- Glow pulse background
local invGlow = Instance.new("Frame")
invGlow.Size = UDim2.fromScale(1, 1)
invGlow.Position = UDim2.fromScale(0.5, 0.5)
invGlow.AnchorPoint = Vector2.new(0.5, 0.5)
invGlow.BackgroundColor3 = Color3.fromRGB(100, 20, 200)
invGlow.BackgroundTransparency = 0.3
invGlow.ZIndex = 4
invGlow.Parent = inventoryBtnFrame

local invGlowCorner = Instance.new("UICorner")
invGlowCorner.CornerRadius = UDim.new(0, 14)
invGlowCorner.Parent = invGlow

-- Inventory button
local inventoryButton = Instance.new("TextButton")
inventoryButton.Name = "InventoryButton"
inventoryButton.Size = UDim2.fromScale(1, 1) -- Fill parent frame
inventoryButton.Position = UDim2.fromScale(0.5, 0.5)
inventoryButton.AnchorPoint = Vector2.new(0.5, 0.5)
inventoryButton.BackgroundColor3 = Color3.fromRGB(70, 10, 150)
inventoryButton.BorderSizePixel = 0
inventoryButton.Font = Enum.Font.GothamBlack
inventoryButton.TextSize = 16
inventoryButton.TextColor3 = Color3.fromRGB(255, 255, 255)
inventoryButton.RichText = true
inventoryButton.Text = '<font tracking="2">INVENTORY</font>'
inventoryButton.ZIndex = 5
inventoryButton.Parent = inventoryBtnFrame

local invBtnCorner = Instance.new("UICorner")
invBtnCorner.CornerRadius = UDim.new(0, 12)
invBtnCorner.Parent = inventoryButton

local invBtnStroke = Instance.new("UIStroke")
invBtnStroke.Color = Color3.fromRGB(160, 80, 255)
invBtnStroke.Thickness = 2
invBtnStroke.Parent = inventoryButton

local invBtnGradient = Instance.new("UIGradient")
invBtnGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(130, 30, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(70, 10, 160)),
})
invBtnGradient.Rotation = 90
invBtnGradient.Parent = inventoryButton

-- Pulse animation loop
task.spawn(function()
	while true do
		local tweenOut = TweenService:Create(invGlow, TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
			Size = UDim2.fromScale(1.12, 1.3),
			BackgroundTransparency = 1,
		})
		tweenOut:Play()
		tweenOut.Completed:Wait()
		invGlow.Size = UDim2.fromScale(1, 1)
		invGlow.BackgroundTransparency = 0.3
		task.wait(0.2)
	end
end)

-- Hover / click animations
inventoryButton.MouseEnter:Connect(function()
	TweenService:Create(inventoryButton, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.fromScale(1.05, 1.08),
	}):Play()
end)
inventoryButton.MouseLeave:Connect(function()
	TweenService:Create(inventoryButton, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.fromScale(1, 1),
	}):Play()
end)
inventoryButton.MouseButton1Down:Connect(function()
	TweenService:Create(inventoryButton, TweenInfo.new(0.1), {
		Size = UDim2.fromScale(0.95, 0.95),
	}):Play()
end)
inventoryButton.MouseButton1Up:Connect(function()
	TweenService:Create(inventoryButton, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.fromScale(1.05, 1.08),
	}):Play()
end)

inventoryButton.MouseButton1Click:Connect(function()
	if _G.InventoryController then
		local lookbookScreen = playerGui:FindFirstChild("LookbookScreen")
		if lookbookScreen and lookbookScreen.Enabled then
			_G.InventoryController.Close()
		else
			_G.InventoryController.Open()
		end
	else
		-- Fallback: toggle directly
		local lookbookScreen = playerGui:FindFirstChild("LookbookScreen")
		if lookbookScreen then
			lookbookScreen.Enabled = not lookbookScreen.Enabled
		end
	end
end)

hudScreen.Enabled = true
print("[HUD] Initialized")
