-- ShopUI.client.luau — Robux pack store and Vibe Coin roll interface
-- Source of truth: docs/implementation-plan.md Phase 9, docs/game-design-document.md

local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local LookbookDataEvent = RemoteEvents:WaitForChild("LookbookData")
local RollRequested = RemoteEvents:WaitForChild("RollRequested")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local shopScreen = playerGui:WaitForChild("ShopScreen")

-- ============================================================
-- PRODUCT IDS — Must match RobuxRollHandler on server
-- Replace 0s with actual Developer Product IDs
-- ============================================================
local PRODUCTS = {
	{ name = "Vibe Starter Pack", productId = 0, price = "79 R$",  desc = "10 rolls • First guaranteed Rare+",    icon = "🎁" },
	{ name = "Hype Pack",         productId = 0, price = "199 R$", desc = "30 rolls + 500 Coins + 1 Epic",        icon = "🔥" },
	{ name = "Capsule Key",       productId = 0, price = "399 R$", desc = "Weekend Designer Capsule access",       icon = "🔮" },
	{ name = "Mythic Wish",       productId = 0, price = "999 R$", desc = "1 guaranteed Mythic item",              icon = "💀" },
}

local ROLL_COST = 100 -- Vibe Coins per standard roll

-- ============================================================
-- STATE
-- ============================================================
local localPlayerData = nil

-- ============================================================
-- BUILD UI
-- ============================================================

-- Main container
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.fromOffset(420, 520)
mainFrame.Position = UDim2.fromScale(0.5, 0.5)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
mainFrame.BorderSizePixel = 0
mainFrame.ZIndex = 5
mainFrame.Parent = shopScreen

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 16)
mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(60, 60, 70)
mainStroke.Thickness = 1
mainStroke.Parent = mainFrame

-- Title bar
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 50)
titleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
titleBar.BorderSizePixel = 0
titleBar.ZIndex = 6
titleBar.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 16)
titleCorner.Parent = titleBar

local titleFill = Instance.new("Frame")
titleFill.Size = UDim2.new(1, 0, 0, 16)
titleFill.Position = UDim2.new(0, 0, 1, -16)
titleFill.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
titleFill.BorderSizePixel = 0
titleFill.ZIndex = 6
titleFill.Parent = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(0.7, 0, 1, 0)
titleLabel.Position = UDim2.fromOffset(20, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 22
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Text = "🛍️ VIBE SHOP"
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.ZIndex = 7
titleLabel.Parent = titleBar

-- Close button
local closeButton = Instance.new("TextButton")
closeButton.Size = UDim2.fromOffset(36, 36)
closeButton.Position = UDim2.new(1, -44, 0.5, 0)
closeButton.AnchorPoint = Vector2.new(0, 0.5)
closeButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
closeButton.BorderSizePixel = 0
closeButton.Font = Enum.Font.GothamBold
closeButton.TextSize = 18
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.Text = "✕"
closeButton.ZIndex = 7
closeButton.Parent = titleBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeButton

closeButton.MouseButton1Click:Connect(function()
	shopScreen.Enabled = false
end)

-- Balance display
local balanceFrame = Instance.new("Frame")
balanceFrame.Size = UDim2.new(0.9, 0, 0, 40)
balanceFrame.Position = UDim2.new(0.5, 0, 0, 58)
balanceFrame.AnchorPoint = Vector2.new(0.5, 0)
balanceFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 15)
balanceFrame.BorderSizePixel = 0
balanceFrame.ZIndex = 6
balanceFrame.Parent = mainFrame

local balanceCorner = Instance.new("UICorner")
balanceCorner.CornerRadius = UDim.new(0, 8)
balanceCorner.Parent = balanceFrame

local balanceLabel = Instance.new("TextLabel")
balanceLabel.Name = "Balance"
balanceLabel.Size = UDim2.fromScale(1, 1)
balanceLabel.BackgroundTransparency = 1
balanceLabel.Font = Enum.Font.GothamBold
balanceLabel.TextSize = 18
balanceLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
balanceLabel.Text = "💰 0 Vibe Coins"
balanceLabel.ZIndex = 7
balanceLabel.Parent = balanceFrame

-- "Premium Packs" section header
local premiumLabel = Instance.new("TextLabel")
premiumLabel.Size = UDim2.new(0.9, 0, 0, 25)
premiumLabel.Position = UDim2.new(0.5, 0, 0, 108)
premiumLabel.AnchorPoint = Vector2.new(0.5, 0)
premiumLabel.BackgroundTransparency = 1
premiumLabel.Font = Enum.Font.GothamBold
premiumLabel.TextSize = 14
premiumLabel.TextColor3 = Color3.fromRGB(120, 120, 130)
premiumLabel.Text = "PREMIUM PACKS"
premiumLabel.TextXAlignment = Enum.TextXAlignment.Left
premiumLabel.ZIndex = 6
premiumLabel.Parent = mainFrame

-- Product cards scroll
local productScroll = Instance.new("ScrollingFrame")
productScroll.Size = UDim2.new(0.9, 0, 1, -148)
productScroll.Position = UDim2.new(0.5, 0, 0, 138)
productScroll.AnchorPoint = Vector2.new(0.5, 0)
productScroll.BackgroundTransparency = 1
productScroll.BorderSizePixel = 0
productScroll.ScrollBarThickness = 3
productScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
productScroll.ZIndex = 6
productScroll.Parent = mainFrame

local productLayout = Instance.new("UIListLayout")
productLayout.Padding = UDim.new(0, 8)
productLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
productLayout.Parent = productScroll

-- Create product cards
for _, product in ipairs(PRODUCTS) do
	local card = Instance.new("Frame")
	card.Size = UDim2.new(1, 0, 0, 70)
	card.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
	card.BorderSizePixel = 0
	card.ZIndex = 7
	card.Parent = productScroll

	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 10)
	cardCorner.Parent = card

	local cardStroke = Instance.new("UIStroke")
	cardStroke.Color = Color3.fromRGB(50, 50, 60)
	cardStroke.Thickness = 1
	cardStroke.Parent = card

	-- Icon
	local productIcon = Instance.new("TextLabel")
	productIcon.Size = UDim2.fromOffset(45, 70)
	productIcon.Position = UDim2.fromOffset(10, 0)
	productIcon.BackgroundTransparency = 1
	productIcon.Font = Enum.Font.GothamBold
	productIcon.TextSize = 28
	productIcon.Text = product.icon
	productIcon.ZIndex = 8
	productIcon.Parent = card

	-- Name
	local productName = Instance.new("TextLabel")
	productName.Size = UDim2.new(0.5, 0, 0, 22)
	productName.Position = UDim2.fromOffset(60, 12)
	productName.BackgroundTransparency = 1
	productName.Font = Enum.Font.GothamBold
	productName.TextSize = 14
	productName.TextColor3 = Color3.fromRGB(230, 230, 240)
	productName.Text = product.name
	productName.TextXAlignment = Enum.TextXAlignment.Left
	productName.ZIndex = 8
	productName.Parent = card

	-- Description
	local productDesc = Instance.new("TextLabel")
	productDesc.Size = UDim2.new(0.6, 0, 0, 18)
	productDesc.Position = UDim2.fromOffset(60, 36)
	productDesc.BackgroundTransparency = 1
	productDesc.Font = Enum.Font.Gotham
	productDesc.TextSize = 11
	productDesc.TextColor3 = Color3.fromRGB(140, 140, 150)
	productDesc.Text = product.desc
	productDesc.TextXAlignment = Enum.TextXAlignment.Left
	productDesc.ZIndex = 8
	productDesc.Parent = card

	-- Buy button
	local buyButton = Instance.new("TextButton")
	buyButton.Size = UDim2.fromOffset(80, 32)
	buyButton.Position = UDim2.new(1, -15, 0.5, 0)
	buyButton.AnchorPoint = Vector2.new(1, 0.5)
	buyButton.BackgroundColor3 = Color3.fromRGB(30, 180, 70)
	buyButton.BorderSizePixel = 0
	buyButton.Font = Enum.Font.GothamBold
	buyButton.TextSize = 13
	buyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	buyButton.Text = product.price
	buyButton.ZIndex = 8
	buyButton.Parent = card

	local buyCorner = Instance.new("UICorner")
	buyCorner.CornerRadius = UDim.new(0, 8)
	buyCorner.Parent = buyButton

	buyButton.MouseButton1Click:Connect(function()
		if product.productId > 0 then
			MarketplaceService:PromptProductPurchase(player, product.productId)
		else
			buyButton.Text = "Coming Soon"
			task.delay(2, function()
				buyButton.Text = product.price
			end)
		end
	end)
end

-- ============================================================
-- OPEN SHOP BUTTON (floating, always visible on HUD)
-- ============================================================
local hudScreenRef = playerGui:WaitForChild("HUDScreen")

local shopOpenButton = Instance.new("TextButton")
shopOpenButton.Name = "OpenShop"
shopOpenButton.Size = UDim2.fromOffset(50, 50)
shopOpenButton.Position = UDim2.new(1, -10, 1, -10)
shopOpenButton.AnchorPoint = Vector2.new(1, 1)
shopOpenButton.BackgroundColor3 = Color3.fromRGB(139, 0, 255)
shopOpenButton.BorderSizePixel = 0
shopOpenButton.Font = Enum.Font.GothamBold
shopOpenButton.TextSize = 24
shopOpenButton.TextColor3 = Color3.fromRGB(255, 255, 255)
shopOpenButton.Text = "🛍️"
shopOpenButton.ZIndex = 5
shopOpenButton.Parent = hudScreenRef

local shopOpenCorner = Instance.new("UICorner")
shopOpenCorner.CornerRadius = UDim.new(0, 12)
shopOpenCorner.Parent = shopOpenButton

shopOpenButton.MouseButton1Click:Connect(function()
	shopScreen.Enabled = not shopScreen.Enabled
end)

-- ============================================================
-- DATA LISTENER
-- ============================================================
LookbookDataEvent.OnClientEvent:Connect(function(data)
	localPlayerData = data
	if data then
		balanceLabel.Text = "💰 " .. tostring(data.VibeCoin or 0) .. " Vibe Coins"
	end
end)

shopScreen.Enabled = false
print("[ShopUI] Initialized")
