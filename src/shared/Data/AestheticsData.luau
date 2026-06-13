-- AestheticsData.luau — Full item catalogue
-- Source of truth: docs/architecture.md Section 2, docs/game-design-document.md
-- Item ID format: [H/B/L][3 digits]
-- All icons and models are rbxassetid://0 placeholders until real art is uploaded

local AestheticsData = {}

-- ============================================================
-- HEAD ITEMS
-- ============================================================
AestheticsData.Head = {
	-- COMMON (5)
	{ id = "H001", name = "Basic Beanie",          aesthetic = "Gorpcore",       slot = "Head", rarity = "Common",    icon = "rbxassetid://0", model = "rbxassetid://0", isCapsule = false, isVaulted = false },
	{ id = "H002", name = "Lo-Fi Headphones",       aesthetic = "Vaporwave",      slot = "Head", rarity = "Common",    icon = "rbxassetid://0", model = "rbxassetid://0", isCapsule = false, isVaulted = false },
	{ id = "H003", name = "Plaid Beret",            aesthetic = "Dark Academia",  slot = "Head", rarity = "Common",    icon = "rbxassetid://0", model = "rbxassetid://0", isCapsule = false, isVaulted = false },
	{ id = "H004", name = "Satin Bow Clip",         aesthetic = "Coquette",       slot = "Head", rarity = "Common",    icon = "rbxassetid://0", model = "rbxassetid://0", isCapsule = false, isVaulted = false },
	{ id = "H005", name = "Pink Visor",             aesthetic = "Barbiecore",     slot = "Head", rarity = "Common",    icon = "rbxassetid://0", model = "rbxassetid://0", isCapsule = false, isVaulted = false },

	-- UNCOMMON (4)
	{ id = "H006", name = "Butterfly Clips",        aesthetic = "Y2K",            slot = "Head", rarity = "Uncommon",  icon = "rbxassetid://0", model = "rbxassetid://0", isCapsule = false, isVaulted = false },
	{ id = "H007", name = "Bucket Hat",             aesthetic = "Indie Sleaze",   slot = "Head", rarity = "Uncommon",  icon = "rbxassetid://0", model = "rbxassetid://0", isCapsule = false, isVaulted = false },
	{ id = "H008", name = "Trail Runner Cap",       aesthetic = "Gorpcore",       slot = "Head", rarity = "Uncommon",  icon = "rbxassetid://0", model = "rbxassetid://0", isCapsule = false, isVaulted = false },
	{ id = "H009", name = "Pearl Headband",         aesthetic = "Coquette",       slot = "Head", rarity = "Uncommon",  icon = "rbxassetid://0", model = "rbxassetid://0", isCapsule = false, isVaulted = false },

	-- RARE (3)
	{ id = "H010", name = "Glass Halo",             aesthetic = "Frutiger Aero",  slot = "Head", rarity = "Rare",      icon = "rbxassetid://0", model = "rbxassetid://0", isCapsule = false, isVaulted = false },
	{ id = "H011", name = "Chrome Crown",           aesthetic = "Y2K",            slot = "Head", rarity = "Rare",      icon = "rbxassetid://0", model = "rbxassetid://0", isCapsule = false, isVaulted = false },
	{ id = "H012", name = "Tactical Balaclava",     aesthetic = "Techwear",       slot = "Head", rarity = "Rare",      icon = "rbxassetid://0", model = "rbxassetid://0", isCapsule = false, isVaulted = false },

	-- EPIC (2)
	{ id = "H013", name = "Neon Gas Mask",          aesthetic = "Cyber-Goth",     slot = "Head", rarity = "Epic",      icon = "rbxassetid://0", model = "rbxassetid://0", isCapsule = false, isVaulted = false },
	{ id = "H014", name = "Holographic Visor",      aesthetic = "Frutiger Aero",  slot = "Head", rarity = "Epic",      icon = "rbxassetid://0", model = "rbxassetid://0", isCapsule = false, isVaulted = false },

	-- LEGENDARY (1)
	{ id = "H015", name = "Roman Laurel Wreath",    aesthetic = "Vaporwave",      slot = "Head", rarity = "Legendary", icon = "rbxassetid://0", model = "rbxassetid://0", isCapsule = false, isVaulted = false },

	-- MYTHIC (1)
	{ id = "H016", name = "Vapor Bust Crown",       aesthetic = "Vaporwave",      slot = "Head", rarity = "Mythic",    icon = "rbxassetid://0", model = "rbxassetid://0", isCapsule = false, isVaulted = false },

	-- MYTHIC (1) — Gorpcore
	{ id = "H017", name = "Summit Aura Hood",       aesthetic = "Gorpcore",       slot = "Head", rarity = "Mythic",    icon = "rbxassetid://0", model = "rbxassetid://0", isCapsule = false, isVaulted = false },
}

-- ============================================================
-- BODY ITEMS
-- ============================================================
AestheticsData.Body = {
	-- COMMON (5)
	{ id = "B001", name = "Oversized Tee",          aesthetic = "Indie Sleaze",   slot = "Body", rarity = "Common",    icon = "rbxassetid://0", model = "rbxassetid://0", isCapsule = false, isVaulted = false },
	{ id = "B002", name = "Fleece Zip-Up",          aesthetic = "Gorpcore",       slot = "Body", rarity = "Common",    icon = "rbxassetid://0", model = "rbxassetid://0", isCapsule = false, isVaulted = false },
	{ id = "B003", name = "Tweed Blazer",           aesthetic = "Dark Academia",  slot = "Body", rarity = "Common",    icon = "rbxassetid://0", model = "rbxassetid://0", isCapsule = false, isVaulted = false },
	{ id = "B004", name = "Lace Camisole",          aesthetic = "Coquette",       slot = "Body", rarity = "Common",    icon = "rbxassetid://0", model = "rbxassetid://0", isCapsule = false, isVaulted = false },
	{ id = "B005", name = "Hot Pink Crop Top",      aesthetic = "Barbiecore",     slot = "Body", rarity = "Common",    icon = "rbxassetid://0", model = "rbxassetid://0", isCapsule = false, isVaulted = false },

	-- UNCOMMON (4)
	{ id = "B006", name = "Chrome Tube Top",        aesthetic = "Y2K",            slot = "Body", rarity = "Uncommon",  icon = "rbxassetid://0", model = "rbxassetid://0", isCapsule = false, isVaulted = false },
	{ id = "B007", name = "Cargo Vest",             aesthetic = "Techwear",       slot = "Body", rarity = "Uncommon",  icon = "rbxassetid://0", model = "rbxassetid://0", isCapsule = false, isVaulted = false },
	{ id = "B008", name = "Ribbon Corset",          aesthetic = "Coquette",       slot = "Body", rarity = "Uncommon",  icon = "rbxassetid://0", model = "rbxassetid://0", isCapsule = false, isVaulted = false },
	{ id = "B009", name = "Vintage Band Tee",       aesthetic = "Indie Sleaze",   slot = "Body", rarity = "Uncommon",  icon = "rbxassetid://0", model = "rbxassetid://0", isCapsule = false, isVaulted = false },

	-- RARE (3)
	{ id = "B010", name = "Translucent Puffer",     aesthetic = "Frutiger Aero",  slot = "Body", rarity = "Rare",      icon = "rbxassetid://0", model = "rbxassetid://0", isCapsule = false, isVaulted = false },
	{ id = "B011", name = "Modular Harness",        aesthetic = "Techwear",       slot = "Body", rarity = "Rare",      icon = "rbxassetid://0", model = "rbxassetid://0", isCapsule = false, isVaulted = false },
	{ id = "B012", name = "UV Reactive Vest",       aesthetic = "Cyber-Goth",     slot = "Body", rarity = "Rare",      icon = "rbxassetid://0", model = "rbxassetid://0", isCapsule = false, isVaulted = false },

	-- EPIC (2)
	{ id = "B013", name = "Holographic Windbreaker", aesthetic = "Frutiger Aero", slot = "Body", rarity = "Epic",      icon = "rbxassetid://0", model = "rbxassetid://0", isCapsule = false, isVaulted = false },
	{ id = "B014", name = "Gothic Lolita Dress",    aesthetic = "Dark Academia",  slot = "Body", rarity = "Epic",      icon = "rbxassetid://0", model = "rbxassetid://0", isCapsule = false, isVaulted = false },

	-- LEGENDARY (1)
	{ id = "B015", name = "Neon Drip Cape",         aesthetic = "Cyber-Goth",     slot = "Body", rarity = "Legendary", icon = "rbxassetid://0", model = "rbxassetid://0", isCapsule = false, isVaulted = false },

	-- MYTHIC (1) — Indie Sleaze
	{ id = "B016", name = "Paparazzi Flash Jacket", aesthetic = "Indie Sleaze",   slot = "Body", rarity = "Mythic",    icon = "rbxassetid://0", model = "rbxassetid://0", isCapsule = false, isVaulted = false },

	-- MYTHIC (1) — Frutiger Aero
	{ id = "B017", name = "Butterfly Aero Suit",    aesthetic = "Frutiger Aero",  slot = "Body", rarity = "Mythic",    icon = "rbxassetid://0", model = "rbxassetid://0", isCapsule = false, isVaulted = false },

	-- DESIGNER CAPSULE
	{ id = "CAP001", name = "Neon Dreamcoat",       aesthetic = "Cyber-Goth",     slot = "Body", rarity = "Legendary", icon = "rbxassetid://0", model = "rbxassetid://0", isCapsule = true,  isVaulted = false },
}

-- ============================================================
-- LEGS ITEMS
-- ============================================================
AestheticsData.Legs = {
	-- COMMON (5)
	{ id = "L001", name = "Basic Cargo Pants",      aesthetic = "Gorpcore",       slot = "Legs", rarity = "Common",    icon = "rbxassetid://0", model = "rbxassetid://0", isCapsule = false, isVaulted = false },
	{ id = "L002", name = "Plaid Trousers",         aesthetic = "Dark Academia",  slot = "Legs", rarity = "Common",    icon = "rbxassetid://0", model = "rbxassetid://0", isCapsule = false, isVaulted = false },
	{ id = "L003", name = "Denim Mini Skirt",       aesthetic = "Indie Sleaze",   slot = "Legs", rarity = "Common",    icon = "rbxassetid://0", model = "rbxassetid://0", isCapsule = false, isVaulted = false },
	{ id = "L004", name = "Ballet Flats",           aesthetic = "Coquette",       slot = "Legs", rarity = "Common",    icon = "rbxassetid://0", model = "rbxassetid://0", isCapsule = false, isVaulted = false },
	{ id = "L005", name = "Platform Heels",         aesthetic = "Barbiecore",     slot = "Legs", rarity = "Common",    icon = "rbxassetid://0", model = "rbxassetid://0", isCapsule = false, isVaulted = false },

	-- UNCOMMON (4)
	{ id = "L006", name = "Frosted Boots",          aesthetic = "Y2K",            slot = "Legs", rarity = "Uncommon",  icon = "rbxassetid://0", model = "rbxassetid://0", isCapsule = false, isVaulted = false },
	{ id = "L007", name = "Trail Runners",          aesthetic = "Gorpcore",       slot = "Legs", rarity = "Uncommon",  icon = "rbxassetid://0", model = "rbxassetid://0", isCapsule = false, isVaulted = false },
	{ id = "L008", name = "Lace Knee-Highs",        aesthetic = "Coquette",       slot = "Legs", rarity = "Uncommon",  icon = "rbxassetid://0", model = "rbxassetid://0", isCapsule = false, isVaulted = false },
	{ id = "L009", name = "Tactical Boots",         aesthetic = "Techwear",       slot = "Legs", rarity = "Uncommon",  icon = "rbxassetid://0", model = "rbxassetid://0", isCapsule = false, isVaulted = false },

	-- RARE (3)
	{ id = "L010", name = "Holographic Legwarmers", aesthetic = "Frutiger Aero",  slot = "Legs", rarity = "Rare",      icon = "rbxassetid://0", model = "rbxassetid://0", isCapsule = false, isVaulted = false },
	{ id = "L011", name = "Chrome Platform Boots",  aesthetic = "Y2K",            slot = "Legs", rarity = "Rare",      icon = "rbxassetid://0", model = "rbxassetid://0", isCapsule = false, isVaulted = false },
	{ id = "L012", name = "Strappy Utility Pants",  aesthetic = "Techwear",       slot = "Legs", rarity = "Rare",      icon = "rbxassetid://0", model = "rbxassetid://0", isCapsule = false, isVaulted = false },

	-- EPIC (2)
	{ id = "L013", name = "Acid-Green Stompers",    aesthetic = "Cyber-Goth",     slot = "Legs", rarity = "Epic",      icon = "rbxassetid://0", model = "rbxassetid://0", isCapsule = false, isVaulted = false },
	{ id = "L014", name = "Glass Slipper Platforms", aesthetic = "Barbiecore",    slot = "Legs", rarity = "Epic",      icon = "rbxassetid://0", model = "rbxassetid://0", isCapsule = false, isVaulted = false },

	-- LEGENDARY (1)
	{ id = "L015", name = "Golden Gore-Tex Boots",  aesthetic = "Gorpcore",       slot = "Legs", rarity = "Legendary", icon = "rbxassetid://0", model = "rbxassetid://0", isCapsule = false, isVaulted = false },

	-- MYTHIC (1) — Cyber-Goth
	{ id = "L016", name = "Acid Trail Stompers",    aesthetic = "Cyber-Goth",     slot = "Legs", rarity = "Mythic",    icon = "rbxassetid://0", model = "rbxassetid://0", isCapsule = false, isVaulted = false },
}

-- ============================================================
-- UTILITY: Lookup helpers
-- ============================================================

local function buildAllItems()
	local all = {}
	for _, item in ipairs(AestheticsData.Head) do
		table.insert(all, item)
	end
	for _, item in ipairs(AestheticsData.Body) do
		table.insert(all, item)
	end
	for _, item in ipairs(AestheticsData.Legs) do
		table.insert(all, item)
	end
	return all
end

AestheticsData.ALL_ITEMS = buildAllItems()

local itemById = {}
for _, item in ipairs(AestheticsData.ALL_ITEMS) do
	itemById[item.id] = item
end

--- Get all items across all slots as a flat list
function AestheticsData.getAllItems()
	return AestheticsData.ALL_ITEMS
end

--- Find an item by its ID across all slots
function AestheticsData.getItemById(itemId: string)
	return itemById[itemId]
end

--- Get items for a specific slot
function AestheticsData.getItemsBySlot(slot: string)
	if slot == "Head" then
		return AestheticsData.Head
	elseif slot == "Body" then
		return AestheticsData.Body
	elseif slot == "Legs" then
		return AestheticsData.Legs
	end
	return {}
end

return AestheticsData
