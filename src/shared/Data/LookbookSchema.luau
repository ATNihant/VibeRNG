-- LookbookSchema.luau — Default structure for a brand new player
-- Source of truth: docs/architecture.md Section 1

local LookbookSchema = {}

function LookbookSchema.getDefault()
	return {
		-- INVENTORY: Items the player has rolled
		-- Each slot is a dictionary keyed by item ID
		-- Value is always `true` (owned) or nil (not owned)
		Lookbook = {
			Head = {},   -- e.g. { H001 = true, H003 = true }
			Body = {},   -- e.g. { B002 = true }
			Legs = {},   -- e.g. {}
		},

		-- EQUIPPED: The currently active items per slot (only one per slot at a time)
		-- Value is item ID string or nil if nothing equipped
		Equipped = {
			Head = nil,   -- e.g. "H001"
			Body = nil,   -- e.g. "B002"
			Legs = nil,   -- e.g. nil
		},

		-- CURRENCY
		VibeCoin = 0,           -- integer, max 50000
		TotalRolls = 0,         -- integer, lifetime counter (never resets)

		-- VAULTED: Items from past Designer Capsule drops
		-- Permanent — never cleared even after capsule expires
		VaultedItems = {},      -- e.g. { "B001" = true }

		-- RUNWAY STATS
		RunwayWins = 0,
		RunwayParticipations = 0,

		-- META
		FirstJoin = 0,          -- os.time() at first ever join
		LastSave = 0,           -- os.time() at last successful save
		LastDailyReward = 0,    -- os.time() of last daily login reward
		Version = 1,            -- schema version for future migrations
	}
end

--- Deep-clone the default data to avoid shared-table mutation
function LookbookSchema.clone(data)
	local function deepCopy(original)
		local copy = {}
		for key, value in pairs(original) do
			if type(value) == "table" then
				copy[key] = deepCopy(value)
			else
				copy[key] = value
			end
		end
		return copy
	end
	return deepCopy(data)
end

return LookbookSchema
