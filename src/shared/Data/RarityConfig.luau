-- RarityConfig.luau — Rarity weights, coin drops, and display colors
-- Source of truth: docs/architecture.md Section 3
-- WARNING: DO NOT require this from any LocalScript — weights must stay server-side
-- The `colors` table is safe to duplicate in a client-side UI module

local WEIGHTS = {
	Common = 500,
	Uncommon = 200,
	Rare = 50,
	Epic = 10,
	Legendary = 2,
	Mythic = 1,
}

local COIN_DROPS = {
	Common = 5,
	Uncommon = 15,
	Rare = 50,
	Epic = 150,
	Legendary = 500,
	Mythic = 2000,
}

local COLORS = {
	Common = Color3.fromRGB(180, 180, 180),
	Uncommon = Color3.fromRGB(30, 200, 80),
	Rare = Color3.fromRGB(50, 120, 255),
	Epic = Color3.fromRGB(160, 50, 255),
	Legendary = Color3.fromRGB(255, 150, 0),
	Mythic = Color3.fromRGB(255, 40, 80),
}

local DISPLAY_ORDER = { "Mythic", "Legendary", "Epic", "Rare", "Uncommon", "Common" }

local RarityConfig = {
	WEIGHTS = WEIGHTS,
	COIN_DROPS = COIN_DROPS,
	COLORS = COLORS,
	DISPLAY_ORDER = DISPLAY_ORDER,

	-- Backward-compatible aliases for existing consumers.
	weights = WEIGHTS,
	coinDrops = COIN_DROPS,
	colors = COLORS,
	order = DISPLAY_ORDER,
}

return RarityConfig
