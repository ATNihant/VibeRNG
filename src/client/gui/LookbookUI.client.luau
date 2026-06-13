-- LookbookUI.client.luau — Inventory viewer and equip interface
-- 3 tabs (Head/Body/Legs), scrolling grid, equip/unequip buttons
-- Exposes _G.InventoryController for cross-script access
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
mainFrame.Size = UDim2.fromOffset(540, 640)
mainFrame.Position = UDim2.fromScale(0.5, 0.5)
mainFrame.AnchorPoint = Vector2.new(0.5, 0.5)
mainFrame.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
mainFrame.BorderSizePixel = 0
mainFrame.ZIndex = 5
mainFrame.Parent = lookbookScreen

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 18)
mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(70, 40, 120)
mainStroke.Thickness = 2
mainStroke.Parent = mainFrame

-- Gradient background
local bgGradient = Instance.new("UIGradient")
bgGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(20, 16, 30)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(10, 10, 16)),
})
bgGradient.Rotation = 135
bgGradient.Parent = mainFrame

-- ============================================================
-- TITLE BAR
-- ============================================================
local titleBar = Instance.new("Frame")
titleBar.Name = "TitleBar"
titleBar.Size = UDim2.new(1, 0, 0, 54)
titleBar.BackgroundColor3 = Color3.fromRGB(22, 16, 36)
titleBar.BorderSizePixel = 0
titleBar.ZIndex = 6
titleBar.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 18)
titleCorner.Parent = titleBar

local titleFill = Instance.new("Frame")
titleFill.Size = UDim2.new(1, 0, 0, 18)
titleFill.Position = UDim2.new(0, 0, 1, -18)
titleFill.BackgroundColor3 = Color3.fromRGB(22, 16, 36)
titleFill.BorderSizePixel = 0
titleFill.ZIndex = 6
titleFill.Parent = titleBar

local titleGradient = Instance.new("UIGradient")
titleGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(139, 0, 255)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(80, 0, 180)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(22, 16, 36)),
})
titleGradient.Rotation = 90
titleGradient.Parent = titleBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(0.7, 0, 1, 0)
titleLabel.Position = UDim2.fromOffset(18, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 22
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Text = "🎒 INVENTORY"
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.ZIndex = 7
titleLabel.Parent = titleBar

local titleStroke = Instance.new("UIStroke")
titleStroke.Color = Color3.fromRGB(0, 0, 0)
titleStroke.Thickness = 1.5
titleStroke.Parent = titleLabel

-- Close button
local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.fromOffset(36, 36)
closeButton.Position = UDim2.new(1, -46, 0.5, 0)
closeButton.AnchorPoint = Vector2.new(0, 0.5)
closeButton.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
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

closeButton.MouseEnter:Connect(function()
	TweenService:Create(closeButton, TweenInfo.new(0.15), {
		BackgroundColor3 = Color3.fromRGB(220, 60, 60),
		Size = UDim2.fromOffset(38, 38),
	}):Play()
end)
closeButton.MouseLeave:Connect(function()
	TweenService:Create(closeButton, TweenInfo.new(0.15), {
		BackgroundColor3 = Color3.fromRGB(180, 40, 40),
		Size = UDim2.fromOffset(36, 36),
	}):Play()
end)
closeButton.MouseButton1Click:Connect(function()
	lookbookScreen.Enabled = false
end)

-- ============================================================
-- EQUIPPED SUMMARY BAR
-- ============================================================
local equippedBar = Instance.new("Frame")
equippedBar.Name = "EquippedBar"
equippedBar.Size = UDim2.new(1, -24, 0, 72)
equippedBar.Position = UDim2.fromOffset(12, 60)
equippedBar.BackgroundColor3 = Color3.fromRGB(18, 14, 28)
equippedBar.BorderSizePixel = 0
equippedBar.ZIndex = 6
equippedBar.Parent = mainFrame

local equippedBarCorner = Instance.new("UICorner")
equippedBarCorner.CornerRadius = UDim.new(0, 10)
equippedBarCorner.Parent = equippedBar

local equippedBarStroke = Instance.new("UIStroke")
equippedBarStroke.Color = Color3.fromRGB(60, 40, 90)
equippedBarStroke.Thickness = 1
equippedBarStroke.Parent = equippedBar

local equippedTitle = Instance.new("TextLabel")
equippedTitle.Size = UDim2.new(0, 90, 1, 0)
equippedTitle.Position = UDim2.fromOffset(12, 0)
equippedTitle.BackgroundTransparency = 1
equippedTitle.Font = Enum.Font.GothamBold
equippedTitle.TextSize = 11
equippedTitle.TextColor3 = Color3.fromRGB(130, 100, 180)
equippedTitle.Text = "EQUIPPED"
equippedTitle.TextXAlignment = Enum.TextXAlignment.Left
equippedTitle.TextYAlignment = Enum.TextYAlignment.Center
equippedTitle.ZIndex = 7
equippedTitle.Parent = equippedBar

-- 3 slot cells in the equipped bar
local SLOT_DEFS = {
	{ name = "Head", icon = "👑", xOffset = 95 },
	{ name = "Body", icon = "👔", xOffset = 230 },
	{ name = "Legs", icon = "👟", xOffset = 365 },
}

local equippedSlotLabels = {}  -- slot name -> TextLabel for updating

for _, slotDef in ipairs(SLOT_DEFS) do
	local cell = Instance.new("Frame")
	cell.Name = "EquippedSlot_" .. slotDef.name
	cell.Size = UDim2.fromOffset(128, 56)
	cell.Position = UDim2.fromOffset(slotDef.xOffset, 8)
	cell.BackgroundColor3 = Color3.fromRGB(26, 20, 42)
	cell.BorderSizePixel = 0
	cell.ZIndex = 7
	cell.Parent = equippedBar

	local cellCorner = Instance.new("UICorner")
	cellCorner.CornerRadius = UDim.new(0, 8)
	cellCorner.Parent = cell

	local cellStroke = Instance.new("UIStroke")
	cellStroke.Color = Color3.fromRGB(70, 50, 110)
	cellStroke.Thickness = 1
	cellStroke.Parent = cell

	local slotIcon = Instance.new("TextLabel")
	slotIcon.Size = UDim2.fromOffset(28, 56)
	slotIcon.Position = UDim2.fromOffset(6, 0)
	slotIcon.BackgroundTransparency = 1
	slotIcon.Font = Enum.Font.GothamBold
	slotIcon.TextSize = 18
	slotIcon.TextColor3 = Color3.fromRGB(180, 150, 220)
	slotIcon.Text = slotDef.icon
	slotIcon.ZIndex = 8
	slotIcon.Parent = cell

	local itemLabel = Instance.new("TextLabel")
	itemLabel.Name = "ItemLabel"
	itemLabel.Size = UDim2.new(1, -38, 0.5, 0)
	itemLabel.Position = UDim2.fromOffset(36, 6)
	itemLabel.BackgroundTransparency = 1
	itemLabel.Font = Enum.Font.GothamBold
	itemLabel.TextSize = 10
	itemLabel.TextColor3 = Color3.fromRGB(220, 210, 240)
	itemLabel.Text = "None"
	itemLabel.TextXAlignment = Enum.TextXAlignment.Left
	itemLabel.TextTruncate = Enum.TextTruncate.AtEnd
	itemLabel.ZIndex = 8
	itemLabel.Parent = cell

	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Name = "RarityLabel"
	rarityLabel.Size = UDim2.new(1, -38, 0.5, 0)
	rarityLabel.Position = UDim2.fromOffset(36, 28)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Font = Enum.Font.Gotham
	rarityLabel.TextSize = 9
	rarityLabel.TextColor3 = Color3.fromRGB(100, 80, 140)
	rarityLabel.Text = "Empty"
	rarityLabel.TextXAlignment = Enum.TextXAlignment.Left
	rarityLabel.ZIndex = 8
	rarityLabel.Parent = cell

	equippedSlotLabels[slotDef.name] = { cell = cell, itemLabel = itemLabel, rarityLabel = rarityLabel, stroke = cellStroke }
end

-- ============================================================
-- TAB BAR
-- ============================================================
local tabBar = Instance.new("Frame")
tabBar.Name = "TabBar"
tabBar.Size = UDim2.new(1, -20, 0, 40)
tabBar.Position = UDim2.fromOffset(10, 138)
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
	tab.Size = UDim2.fromOffset(148, 36)
	tab.BackgroundColor3 = Color3.fromRGB(28, 22, 44)
	tab.BorderSizePixel = 0
	tab.Font = Enum.Font.GothamBold
	tab.TextSize = 14
	tab.TextColor3 = Color3.fromRGB(140, 120, 180)
	tab.Text = icon .. "  " .. name:upper()
	tab.ZIndex = 7
	tab.Parent = tabBar

	local tabCornerInst = Instance.new("UICorner")
	tabCornerInst.CornerRadius = UDim.new(0, 9)
	tabCornerInst.Parent = tab

	local tabStroke = Instance.new("UIStroke")
	tabStroke.Color = Color3.fromRGB(60, 40, 100)
	tabStroke.Thickness = 1
	tabStroke.Parent = tab

	tabButtons[name] = { btn = tab, stroke = tabStroke }
	return tab
end

createTab("Head", "👑")
createTab("Body", "👔")
createTab("Legs", "👟")

-- ============================================================
-- CONTENT SCROLLING GRID
-- ============================================================
local contentFrame = Instance.new("ScrollingFrame")
contentFrame.Name = "ContentFrame"
contentFrame.Size = UDim2.new(1, -20, 1, -186)
contentFrame.Position = UDim2.fromOffset(10, 184)
contentFrame.BackgroundTransparency = 1
contentFrame.BorderSizePixel = 0
contentFrame.ScrollBarThickness = 4
contentFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 70, 160)
contentFrame.ZIndex = 6
contentFrame.CanvasSize = UDim2.fromOffset(0, 0)
contentFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
contentFrame.Parent = mainFrame

local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellSize = UDim2.fromOffset(118, 168)
gridLayout.CellPadding = UDim2.fromOffset(8, 8)
gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
gridLayout.Parent = contentFrame

local gridPadding = Instance.new("UIPadding")
gridPadding.PaddingTop = UDim.new(0, 6)
gridPadding.PaddingBottom = UDim.new(0, 10)
gridPadding.Parent = contentFrame

-- ============================================================
-- ITEM CARD CREATION
-- ============================================================
local function createItemCard(item, isOwned, isEquipped)
	local card = Instance.new("Frame")
	card.Name = "Card_" .. item.id
	card.BackgroundColor3 = isOwned
		and (isEquipped and Color3.fromRGB(30, 20, 50) or Color3.fromRGB(24, 20, 36))
		or Color3.fromRGB(16, 14, 22)
	card.BorderSizePixel = 0
	card.ZIndex = 7

	local cardCornerInst = Instance.new("UICorner")
	cardCornerInst.CornerRadius = UDim.new(0, 10)
	cardCornerInst.Parent = card

	-- Border stroke
	local borderStroke = Instance.new("UIStroke")
	if isEquipped then
		borderStroke.Color = RARITY_COLORS[item.rarity] or Color3.fromRGB(139, 0, 255)
		borderStroke.Thickness = 2
	else
		borderStroke.Color = Color3.fromRGB(45, 35, 70)
		borderStroke.Thickness = 1
	end
	borderStroke.Parent = card

	-- Equipped crown badge
	if isEquipped then
		local equippedBadge = Instance.new("Frame")
		equippedBadge.Size = UDim2.fromOffset(60, 16)
		equippedBadge.Position = UDim2.new(0.5, 0, 0, 4)
		equippedBadge.AnchorPoint = Vector2.new(0.5, 0)
		equippedBadge.BackgroundColor3 = RARITY_COLORS[item.rarity] or Color3.fromRGB(139, 0, 255)
		equippedBadge.BorderSizePixel = 0
		equippedBadge.ZIndex = 10
		equippedBadge.Parent = card

		local badgeCorner = Instance.new("UICorner")
		badgeCorner.CornerRadius = UDim.new(0, 4)
		badgeCorner.Parent = equippedBadge

		local badgeLabel = Instance.new("TextLabel")
		badgeLabel.Size = UDim2.fromScale(1, 1)
		badgeLabel.BackgroundTransparency = 1
		badgeLabel.Font = Enum.Font.GothamBold
		badgeLabel.TextSize = 8
		badgeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		badgeLabel.Text = "✦ EQUIPPED"
		badgeLabel.ZIndex = 11
		badgeLabel.Parent = equippedBadge
	end

	-- Icon area
	local iconArea = Instance.new("Frame")
	iconArea.Size = UDim2.new(0.85, 0, 0, 72)
	iconArea.Position = UDim2.new(0.5, 0, 0, isEquipped and 26 or 10)
	iconArea.AnchorPoint = Vector2.new(0.5, 0)
	iconArea.BackgroundColor3 = Color3.fromRGB(20, 16, 30)
	iconArea.BorderSizePixel = 0
	iconArea.ZIndex = 8
	iconArea.Parent = card

	local iconAreaCorner = Instance.new("UICorner")
	iconAreaCorner.CornerRadius = UDim.new(0, 8)
	iconAreaCorner.Parent = iconArea

	-- Slot icon
	local slotIcons = { Head = "👑", Body = "👔", Legs = "👟" }
	local slotIcon = Instance.new("TextLabel")
	slotIcon.Size = UDim2.fromScale(1, 1)
	slotIcon.BackgroundTransparency = 1
	slotIcon.Font = Enum.Font.GothamBold
	slotIcon.TextSize = 30
	slotIcon.TextColor3 = isOwned
		and (RARITY_COLORS[item.rarity] or Color3.fromRGB(150, 150, 150))
		or Color3.fromRGB(45, 40, 60)
	slotIcon.Text = slotIcons[item.slot] or "?"
	slotIcon.ZIndex = 9
	slotIcon.TextTransparency = isOwned and 0 or 0.5
	slotIcon.Parent = iconArea

	-- Item name
	local nameYOffset = isEquipped and 104 or 88
	local cardName = Instance.new("TextLabel")
	cardName.Size = UDim2.new(0.9, 0, 0, 30)
	cardName.Position = UDim2.new(0.5, 0, 0, nameYOffset)
	cardName.AnchorPoint = Vector2.new(0.5, 0)
	cardName.BackgroundTransparency = 1
	cardName.Font = Enum.Font.GothamBold
	cardName.TextSize = 11
	cardName.TextColor3 = isOwned and Color3.fromRGB(220, 215, 235) or Color3.fromRGB(70, 65, 85)
	cardName.Text = item.name
	cardName.TextWrapped = true
	cardName.ZIndex = 8
	cardName.Parent = card

	-- Rarity badge
	local rarityBadge = Instance.new("TextLabel")
	rarityBadge.Size = UDim2.new(0.82, 0, 0, 18)
	rarityBadge.Position = UDim2.new(0.5, 0, 0, nameYOffset + 32)
	rarityBadge.AnchorPoint = Vector2.new(0.5, 0)
	rarityBadge.BackgroundColor3 = Color3.fromRGB(28, 22, 42)
	rarityBadge.BorderSizePixel = 0
	rarityBadge.Font = Enum.Font.GothamBold
	rarityBadge.TextSize = 9
	rarityBadge.TextColor3 = RARITY_COLORS[item.rarity] or Color3.fromRGB(140, 130, 160)
	rarityBadge.Text = item.rarity:upper()
	rarityBadge.ZIndex = 8
	rarityBadge.Parent = card

	local rarityBadgeCorner = Instance.new("UICorner")
	rarityBadgeCorner.CornerRadius = UDim.new(0, 4)
	rarityBadgeCorner.Parent = rarityBadge

	-- Equip / Unequip button (only for owned items)
	if isOwned then
		local actionBtn = Instance.new("TextButton")
		actionBtn.Size = UDim2.new(0.82, 0, 0, 24)
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
			actionBtn.Text = "✕  UNEQUIP"
			actionBtn.BackgroundColor3 = Color3.fromRGB(55, 20, 20)
			actionBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
			actionBtn.MouseButton1Click:Connect(function()
				UnequipItemEvent:FireServer(item.slot)
			end)
		else
			actionBtn.Text = "✦  EQUIP"
			actionBtn.BackgroundColor3 = Color3.fromRGB(20, 50, 20)
			actionBtn.TextColor3 = Color3.fromRGB(100, 230, 130)
			actionBtn.MouseButton1Click:Connect(function()
				EquipItemEvent:FireServer(item.slot, item.id)
			end)
		end

		-- Hover feedback
		actionBtn.MouseEnter:Connect(function()
			TweenService:Create(actionBtn, TweenInfo.new(0.1), {
				Size = UDim2.new(0.88, 0, 0, 26)
			}):Play()
		end)
		actionBtn.MouseLeave:Connect(function()
			TweenService:Create(actionBtn, TweenInfo.new(0.1), {
				Size = UDim2.new(0.82, 0, 0, 24)
			}):Play()
		end)
	else
		-- "LOCKED" label for unowned items
		local lockedLabel = Instance.new("TextLabel")
		lockedLabel.Size = UDim2.new(0.82, 0, 0, 22)
		lockedLabel.Position = UDim2.new(0.5, 0, 1, -8)
		lockedLabel.AnchorPoint = Vector2.new(0.5, 1)
		lockedLabel.BackgroundTransparency = 1
		lockedLabel.Font = Enum.Font.Gotham
		lockedLabel.TextSize = 10
		lockedLabel.TextColor3 = Color3.fromRGB(60, 55, 75)
		lockedLabel.Text = "🔒 Not Owned"
		lockedLabel.ZIndex = 8
		lockedLabel.Parent = card
	end

	-- Vaulted badge
	if item.isVaulted then
		local vaultBadge = Instance.new("TextLabel")
		vaultBadge.Size = UDim2.fromOffset(50, 16)
		vaultBadge.Position = UDim2.fromOffset(4, 4)
		vaultBadge.BackgroundColor3 = Color3.fromRGB(160, 120, 0)
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
-- EQUIPPED SUMMARY BAR UPDATE
-- ============================================================
local function updateEquippedBar()
	if not localPlayerData then return end

	for _, slotDef in ipairs(SLOT_DEFS) do
		local slot = slotDef.name
		local equippedId = localPlayerData.Equipped and localPlayerData.Equipped[slot]
		local labels = equippedSlotLabels[slot]
		if not labels then continue end

		if equippedId then
			local item = AestheticsData.getItemById(equippedId)
			if item then
				labels.itemLabel.Text = item.name
				labels.rarityLabel.Text = item.rarity
				labels.rarityLabel.TextColor3 = RARITY_COLORS[item.rarity] or Color3.fromRGB(130, 100, 180)
				labels.stroke.Color = RARITY_COLORS[item.rarity] or Color3.fromRGB(80, 60, 120)
				labels.cell.BackgroundColor3 = Color3.fromRGB(30, 22, 50)
			end
		else
			labels.itemLabel.Text = "None"
			labels.rarityLabel.Text = "Empty"
			labels.rarityLabel.TextColor3 = Color3.fromRGB(80, 65, 110)
			labels.stroke.Color = Color3.fromRGB(60, 40, 90)
			labels.cell.BackgroundColor3 = Color3.fromRGB(22, 16, 36)
		end
	end
end

-- ============================================================
-- REFRESH / POPULATE GRID
-- ============================================================
local function refreshGrid()
	-- Clear existing cards
	for _, child in ipairs(contentFrame:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	updateEquippedBar()

	if not localPlayerData then return end

	local items = AestheticsData.getItemsBySlot(currentTab)
	local ownedSlot = localPlayerData.Lookbook[currentTab] or {}
	local equippedId = localPlayerData.Equipped[currentTab]

	-- Sort: equipped first, then owned by rarity, then unowned
	local rarityOrder = { Mythic = 1, Legendary = 2, Epic = 3, Rare = 4, Uncommon = 5, Common = 6 }

	local sortedItems = {}
	for _, item in ipairs(items) do
		table.insert(sortedItems, item)
	end

	table.sort(sortedItems, function(a, b)
		local aEquipped = (equippedId == a.id) and 2 or 0
		local bEquipped = (equippedId == b.id) and 2 or 0
		local aOwned = ownedSlot[a.id] and 1 or 0
		local bOwned = ownedSlot[b.id] and 1 or 0
		local aScore = aEquipped + aOwned
		local bScore = bEquipped + bOwned
		if aScore ~= bScore then return aScore > bScore end
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

	for name, tabData in pairs(tabButtons) do
		if name == tabName then
			tabData.btn.BackgroundColor3 = Color3.fromRGB(100, 20, 200)
			tabData.btn.TextColor3 = Color3.fromRGB(255, 255, 255)
			tabData.stroke.Color = Color3.fromRGB(160, 80, 255)
			tabData.stroke.Thickness = 2
		else
			tabData.btn.BackgroundColor3 = Color3.fromRGB(28, 22, 44)
			tabData.btn.TextColor3 = Color3.fromRGB(140, 120, 180)
			tabData.stroke.Color = Color3.fromRGB(60, 40, 100)
			tabData.stroke.Thickness = 1
		end
	end

	refreshGrid()
end

for name, tabData in pairs(tabButtons) do
	tabData.btn.MouseButton1Click:Connect(function()
		setTab(name)
	end)
	-- Hover effect
	tabData.btn.MouseEnter:Connect(function()
		if currentTab ~= name then
			TweenService:Create(tabData.btn, TweenInfo.new(0.15), {
				BackgroundColor3 = Color3.fromRGB(50, 35, 80),
				TextColor3 = Color3.fromRGB(190, 170, 220),
			}):Play()
		end
	end)
	tabData.btn.MouseLeave:Connect(function()
		if currentTab ~= name then
			TweenService:Create(tabData.btn, TweenInfo.new(0.15), {
				BackgroundColor3 = Color3.fromRGB(28, 22, 44),
				TextColor3 = Color3.fromRGB(140, 120, 180),
			}):Play()
		end
	end)
end

-- ============================================================
-- OPEN / CLOSE ANIMATION
-- ============================================================
local function animateOpen()
	mainFrame.Size = UDim2.fromOffset(540 * 0.85, 640 * 0.85)
	mainFrame.BackgroundTransparency = 0.8
	TweenService:Create(mainFrame, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.fromOffset(540, 640),
		BackgroundTransparency = 0,
	}):Play()
end

lookbookScreen:GetPropertyChangedSignal("Enabled"):Connect(function()
	if lookbookScreen.Enabled then
		animateOpen()
		refreshGrid()
	end
end)

-- ============================================================
-- DATA LISTENER
-- ============================================================
LookbookDataEvent.OnClientEvent:Connect(function(data)
	localPlayerData = data
	if lookbookScreen.Enabled then
		refreshGrid()
	else
		updateEquippedBar()
	end
end)

-- ============================================================
-- GLOBAL CONTROLLER — for cross-script access
-- ============================================================
_G.InventoryController = {
	Open = function()
		lookbookScreen.Enabled = true
	end,
	OpenToSlot = function(slot)
		lookbookScreen.Enabled = true
		setTab(slot)
		-- Scroll to top
		contentFrame.CanvasPosition = Vector2.new(0, 0)
	end,
	Close = function()
		lookbookScreen.Enabled = false
	end,
}

-- Initialize with Head tab
setTab("Head")
lookbookScreen.Enabled = false

print("[LookbookUI / Inventory] Initialized")
