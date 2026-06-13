-- LookbookUI.client.luau — Lookbook collection viewer and equip interface
-- 3 tabs (Head/Body/Legs), scrolling grid, equip/unequip buttons
-- Source of truth: docs/implementation-plan.md Phase 6

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Data = ReplicatedStorage:WaitForChild("Data")
local AestheticsData = require(Data:WaitForChild("AestheticsData"))

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local LookbookDataEvent = RemoteEvents:WaitForChild("LookbookData")
local EquipItemEvent = RemoteEvents:WaitForChild("EquipItem")
local UnequipItemEvent = RemoteEvents:WaitForChild("UnequipItem")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local lookbookScreen = playerGui:WaitForChild("LookbookScreen")

-- ============================================================
-- RARITY COLORS
-- ============================================================
local RARITY_COLORS = {
	Common    = Color3.fromRGB(180, 180, 180),
	Uncommon  = Color3.fromRGB(30, 200, 80),
	Rare      = Color3.fromRGB(50, 120, 255),
	Epic      = Color3.fromRGB(160, 50, 255),
	Legendary = Color3.fromRGB(255, 150, 0),
	Mythic    = Color3.fromRGB(255, 40, 80),
}

-- ============================================================
-- STATE
-- ============================================================
local localPlayerData = nil
local currentTab = "Head"

-- ============================================================
-- BUILD UI FRAMEWORK
-- ============================================================

-- Main container
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.fromOffset(520, 580)
mainFrame.Position = UDim2.fromScale(0.5, 0.5)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
mainFrame.BorderSizePixel = 0
mainFrame.ZIndex = 5
mainFrame.Parent = lookbookScreen

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 16)
mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(60, 60, 70)
mainStroke.Thickness = 1
mainStroke.Parent = mainFrame

-- Title bar
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 50)
titleBar.BackgroundColor3 = Color3.fromRGB(25, 25, 32)
titleBar.BorderSizePixel = 0
titleBar.ZIndex = 6
titleBar.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 16)
titleCorner.Parent = titleBar

-- Bottom of title bar should be square
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
titleLabel.Text = "📖 LOOKBOOK"
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.ZIndex = 7
titleLabel.Parent = titleBar

-- Close button
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
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
	lookbookScreen.Enabled = false
end)

-- Tab bar
local tabBar = Instance.new("Frame")
tabBar.Name = "TabBar"
tabBar.Size = UDim2.new(1, -20, 0, 40)
tabBar.Position = UDim2.fromOffset(10, 55)
tabBar.BackgroundTransparency = 1
tabBar.ZIndex = 6
tabBar.Parent = mainFrame

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
tabLayout.Padding = UDim.new(0, 8)
tabLayout.Parent = tabBar

local tabButtons = {}

local function createTab(name, icon)
	local tab = Instance.new("TextButton")
	tab.Name = "Tab_" .. name
	tab.Size = UDim2.fromOffset(140, 36)
	tab.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
	tab.BorderSizePixel = 0
	tab.Font = Enum.Font.GothamBold
	tab.TextSize = 14
	tab.TextColor3 = Color3.fromRGB(150, 150, 160)
	tab.Text = icon .. " " .. name:upper()
	tab.ZIndex = 7
	tab.Parent = tabBar

	local tabCornerInst = Instance.new("UICorner")
	tabCornerInst.CornerRadius = UDim.new(0, 8)
	tabCornerInst.Parent = tab

	tabButtons[name] = tab
	return tab
end

createTab("Head", "👑")
createTab("Body", "👔")
createTab("Legs", "👟")

-- Content area (scrolling grid)
local contentFrame = Instance.new("ScrollingFrame")
contentFrame.Name = "ContentFrame"
contentFrame.Size = UDim2.new(1, -20, 1, -110)
contentFrame.Position = UDim2.fromOffset(10, 100)
contentFrame.BackgroundTransparency = 1
contentFrame.BorderSizePixel = 0
contentFrame.ScrollBarThickness = 4
contentFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 110)
contentFrame.ZIndex = 6
contentFrame.CanvasSize = UDim2.fromOffset(0, 0)
contentFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
contentFrame.Parent = mainFrame

local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellSize = UDim2.fromOffset(115, 160)
gridLayout.CellPadding = UDim2.fromOffset(8, 8)
gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
gridLayout.Parent = contentFrame

local gridPadding = Instance.new("UIPadding")
gridPadding.PaddingTop = UDim.new(0, 5)
gridPadding.Parent = contentFrame

-- ============================================================
-- ITEM CARD CREATION
-- ============================================================
local function createItemCard(item, isOwned, isEquipped)
	local card = Instance.new("Frame")
	card.Name = "Card_" .. item.id
	card.BackgroundColor3 = isOwned and Color3.fromRGB(30, 30, 38) or Color3.fromRGB(20, 20, 22)
	card.BorderSizePixel = 0
	card.ZIndex = 7

	local cardCornerInst = Instance.new("UICorner")
	cardCornerInst.CornerRadius = UDim.new(0, 10)
	cardCornerInst.Parent = card

	-- Equipped highlight border
	if isEquipped then
		local equippedStroke = Instance.new("UIStroke")
		equippedStroke.Color = RARITY_COLORS[item.rarity] or Color3.fromRGB(139, 0, 255)
		equippedStroke.Thickness = 2
		equippedStroke.Parent = card
	end

	-- Icon area
	local iconArea = Instance.new("Frame")
	iconArea.Size = UDim2.new(0.85, 0, 0, 70)
	iconArea.Position = UDim2.new(0.5, 0, 0, 8)
	iconArea.AnchorPoint = Vector2.new(0.5, 0)
	iconArea.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
	iconArea.BorderSizePixel = 0
	iconArea.ZIndex = 8
	iconArea.Parent = card

	local iconAreaCorner = Instance.new("UICorner")
	iconAreaCorner.CornerRadius = UDim.new(0, 8)
	iconAreaCorner.Parent = iconArea

	-- Placeholder slot icon
	local slotIcons = { Head = "👑", Body = "👔", Legs = "👟" }
	local slotIcon = Instance.new("TextLabel")
	slotIcon.Size = UDim2.fromScale(1, 1)
	slotIcon.BackgroundTransparency = 1
	slotIcon.Font = Enum.Font.GothamBold
	slotIcon.TextSize = 28
	slotIcon.TextColor3 = isOwned and (RARITY_COLORS[item.rarity] or Color3.fromRGB(150, 150, 150)) or Color3.fromRGB(60, 60, 65)
	slotIcon.Text = slotIcons[item.slot] or "?"
	slotIcon.ZIndex = 9
	slotIcon.TextTransparency = isOwned and 0 or 0.6
	slotIcon.Parent = iconArea

	-- Item name
	local cardName = Instance.new("TextLabel")
	cardName.Size = UDim2.new(0.9, 0, 0, 28)
	cardName.Position = UDim2.new(0.5, 0, 0, 82)
	cardName.AnchorPoint = Vector2.new(0.5, 0)
	cardName.BackgroundTransparency = 1
	cardName.Font = Enum.Font.GothamBold
	cardName.TextSize = 11
	cardName.TextColor3 = isOwned and Color3.fromRGB(220, 220, 230) or Color3.fromRGB(80, 80, 85)
	cardName.Text = item.name
	cardName.TextWrapped = true
	cardName.ZIndex = 8
	cardName.Parent = card

	-- Rarity badge
	local rarityBadge = Instance.new("TextLabel")
	rarityBadge.Size = UDim2.new(0.8, 0, 0, 18)
	rarityBadge.Position = UDim2.new(0.5, 0, 0, 112)
	rarityBadge.AnchorPoint = Vector2.new(0.5, 0)
	rarityBadge.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
	rarityBadge.BorderSizePixel = 0
	rarityBadge.Font = Enum.Font.GothamBold
	rarityBadge.TextSize = 9
	rarityBadge.TextColor3 = RARITY_COLORS[item.rarity] or Color3.fromRGB(150, 150, 150)
	rarityBadge.Text = item.rarity:upper()
	rarityBadge.ZIndex = 8
	rarityBadge.Parent = card

	local rarityBadgeCorner = Instance.new("UICorner")
	rarityBadgeCorner.CornerRadius = UDim.new(0, 4)
	rarityBadgeCorner.Parent = rarityBadge

	-- Equip / Unequip button (only for owned items)
	if isOwned then
		local actionBtn = Instance.new("TextButton")
		actionBtn.Size = UDim2.new(0.8, 0, 0, 22)
		actionBtn.Position = UDim2.new(0.5, 0, 1, -8)
		actionBtn.AnchorPoint = Vector2.new(0.5, 1)
		actionBtn.BorderSizePixel = 0
		actionBtn.Font = Enum.Font.GothamBold
		actionBtn.TextSize = 11
		actionBtn.ZIndex = 8
		actionBtn.Parent = card

		local actionBtnCorner = Instance.new("UICorner")
		actionBtnCorner.CornerRadius = UDim.new(0, 6)
		actionBtnCorner.Parent = actionBtn

		if isEquipped then
			actionBtn.Text = "UNEQUIP"
			actionBtn.BackgroundColor3 = Color3.fromRGB(60, 30, 30)
			actionBtn.TextColor3 = Color3.fromRGB(255, 120, 120)
			actionBtn.MouseButton1Click:Connect(function()
				UnequipItemEvent:FireServer(item.slot)
			end)
		else
			actionBtn.Text = "EQUIP"
			actionBtn.BackgroundColor3 = Color3.fromRGB(30, 60, 30)
			actionBtn.TextColor3 = Color3.fromRGB(120, 255, 120)
			actionBtn.MouseButton1Click:Connect(function()
				EquipItemEvent:FireServer(item.slot, item.id)
			end)
		end
	else
		-- "LOCKED" label for unowned items
		local lockedLabel = Instance.new("TextLabel")
		lockedLabel.Size = UDim2.new(0.8, 0, 0, 20)
		lockedLabel.Position = UDim2.new(0.5, 0, 1, -8)
		lockedLabel.AnchorPoint = Vector2.new(0.5, 1)
		lockedLabel.BackgroundTransparency = 1
		lockedLabel.Font = Enum.Font.Gotham
		lockedLabel.TextSize = 10
		lockedLabel.TextColor3 = Color3.fromRGB(60, 60, 65)
		lockedLabel.Text = "🔒 Not Owned"
		lockedLabel.ZIndex = 8
		lockedLabel.Parent = card
	end

	-- Vaulted badge
	if item.isVaulted then
		local vaultBadge = Instance.new("TextLabel")
		vaultBadge.Size = UDim2.fromOffset(50, 16)
		vaultBadge.Position = UDim2.fromOffset(4, 4)
		vaultBadge.BackgroundColor3 = Color3.fromRGB(180, 140, 0)
		vaultBadge.BorderSizePixel = 0
		vaultBadge.Font = Enum.Font.GothamBold
		vaultBadge.TextSize = 8
		vaultBadge.TextColor3 = Color3.fromRGB(255, 255, 255)
		vaultBadge.Text = "VAULTED"
		vaultBadge.ZIndex = 10
		vaultBadge.Parent = card

		local vaultCorner = Instance.new("UICorner")
		vaultCorner.CornerRadius = UDim.new(0, 4)
		vaultCorner.Parent = vaultBadge
	end

	return card
end

-- ============================================================
-- REFRESH / POPULATE
-- ============================================================
local function refreshGrid()
	-- Clear existing cards
	for _, child in ipairs(contentFrame:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	if not localPlayerData then return end

	local items = AestheticsData.getItemsBySlot(currentTab)
	local ownedSlot = localPlayerData.Lookbook[currentTab] or {}
	local equippedId = localPlayerData.Equipped[currentTab]

	-- Sort: owned first, then by rarity (rare first)
	local rarityOrder = { Mythic = 1, Legendary = 2, Epic = 3, Rare = 4, Uncommon = 5, Common = 6 }

	local sortedItems = {}
	for _, item in ipairs(items) do
		table.insert(sortedItems, item)
	end

	table.sort(sortedItems, function(a, b)
		local aOwned = ownedSlot[a.id] and 1 or 0
		local bOwned = ownedSlot[b.id] and 1 or 0
		if aOwned ~= bOwned then return aOwned > bOwned end
		local aOrder = rarityOrder[a.rarity] or 99
		local bOrder = rarityOrder[b.rarity] or 99
		return aOrder < bOrder
	end)

	for i, item in ipairs(sortedItems) do
		local isOwned = ownedSlot[item.id] == true
		local isEquipped = equippedId == item.id
		local card = createItemCard(item, isOwned, isEquipped)
		card.LayoutOrder = i
		card.Parent = contentFrame
	end
end

-- ============================================================
-- TAB SWITCHING
-- ============================================================
local function setTab(tabName)
	currentTab = tabName

	for name, btn in pairs(tabButtons) do
		if name == tabName then
			btn.BackgroundColor3 = Color3.fromRGB(139, 0, 255)
			btn.TextColor3 = Color3.fromRGB(255, 255, 255)
		else
			btn.BackgroundColor3 = Color3.fromRGB(35, 35, 42)
			btn.TextColor3 = Color3.fromRGB(150, 150, 160)
		end
	end

	refreshGrid()
end

for name, btn in pairs(tabButtons) do
	btn.MouseButton1Click:Connect(function()
		setTab(name)
	end)
end

-- ============================================================
-- DATA LISTENER
-- ============================================================
LookbookDataEvent.OnClientEvent:Connect(function(data)
	localPlayerData = data
	if lookbookScreen.Enabled then
		refreshGrid()
	end
end)

-- Refresh when screen becomes visible
lookbookScreen:GetPropertyChangedSignal("Enabled"):Connect(function()
	if lookbookScreen.Enabled then
		refreshGrid()
	end
end)

-- Initialize with Head tab
setTab("Head")
lookbookScreen.Enabled = false

print("[LookbookUI] Initialized")
