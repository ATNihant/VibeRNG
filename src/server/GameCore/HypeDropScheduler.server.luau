-- HypeDropScheduler.server.luau — Designer Capsule (Friday-Sunday limited drops)
-- Source of truth: docs/game-design-document.md (Designer Capsule section)
-- Checks hourly whether a capsule should be active based on UTC day of week

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerAnnouncement = ReplicatedStorage:WaitForChild("RemoteEvents"):WaitForChild("ServerAnnouncement")

-- ============================================================
-- CONFIGURATION
-- ============================================================
local CHECK_INTERVAL = 3600 -- Check every hour (seconds)

-- Capsule is active Friday 12:00 PM UTC through Sunday 11:59 PM UTC
-- os.date("*t") wday: 1=Sunday, 2=Monday, ..., 6=Friday, 7=Saturday
local CAPSULE_START_WDAY = 6  -- Friday
local CAPSULE_START_HOUR = 12 -- 12:00 PM UTC
local CAPSULE_END_WDAY = 1    -- Sunday (end of day = Monday 0:00)
local CAPSULE_END_HOUR = 0    -- Midnight (technically Monday 0:00 = Sunday 24:00)

-- ============================================================
-- STATE
-- ============================================================
local activeCapsuleId = nil
local wasActive = false

-- ============================================================
-- CAPSULE ITEMS — Define capsule items here
-- These IDs should match items in AestheticsData with isCapsule = true
-- ============================================================
local CAPSULE_SCHEDULE = {
	-- Week 1 capsule (for testing, this will always be the active one)
	-- In production, you'd rotate based on week number
	{ id = "CAP001", name = "Neon Dreamcoat" },
}

local function getCurrentCapsuleItem()
	-- For now, return the first capsule item
	-- In production, rotate based on week number:
	-- local weekNum = math.floor(os.time() / (7 * 86400))
	-- return CAPSULE_SCHEDULE[(weekNum % #CAPSULE_SCHEDULE) + 1]
	return CAPSULE_SCHEDULE[1]
end

-- ============================================================
-- TIME CHECK
-- ============================================================
local function isCapsuleWindow()
	local t = os.date("!*t") -- UTC time

	-- Friday after 12PM
	if t.wday == 6 and t.hour >= CAPSULE_START_HOUR then
		return true
	end

	-- Saturday (all day)
	if t.wday == 7 then
		return true
	end

	-- Sunday (until midnight = before Monday)
	if t.wday == 1 and t.hour < 24 then
		return true
	end

	return false
end

-- ============================================================
-- MAIN LOOP
-- ============================================================
task.spawn(function()
	-- Wait for RollHandler to initialize
	task.wait(5)

	print("[HypeDropScheduler] Initialized. Checking capsule status...")

	while true do
		local shouldBeActive = isCapsuleWindow()

		if shouldBeActive and not wasActive then
			-- ACTIVATE capsule
			local capsuleItem = getCurrentCapsuleItem()
			if capsuleItem then
				activeCapsuleId = capsuleItem.id

				-- Tell RollHandler to add capsule to pool
				while not _G.RollHandler do
					task.wait(0.1)
				end
				_G.RollHandler.SetActiveCapsule(activeCapsuleId)

				ServerAnnouncement:FireAllClients(
					"🔮 DESIGNER CAPSULE DROP: " .. capsuleItem.name .. " is now in the roll pool! Limited time only! 🔮",
					"Capsule"
				)

				print("[HypeDropScheduler] Capsule ACTIVATED: " .. capsuleItem.name)
				wasActive = true
			end

		elseif not shouldBeActive and wasActive then
			-- DEACTIVATE capsule
			while not _G.RollHandler do
				task.wait(0.1)
			end
			_G.RollHandler.ClearActiveCapsule()

			-- Mark owners as having vaulted items
			while not _G.DataManager do
				task.wait(0.1)
			end
			local DataManager = _G.DataManager

			-- Note: In a real implementation, we'd scan all player data
			-- For now, active players who own the capsule get vaulted status
			local Players = game:GetService("Players")
			for _, player in ipairs(Players:GetPlayers()) do
				local data = DataManager.GetData(player)
				if data then
					-- Check all slots for the capsule item
					for _, slot in ipairs({"Head", "Body", "Legs"}) do
						if data.Lookbook[slot] and data.Lookbook[slot][activeCapsuleId] then
							DataManager.AddVaultedItem(player, activeCapsuleId)
							break
						end
					end
				end
			end

			ServerAnnouncement:FireAllClients(
				"🔒 The Designer Capsule has been VAULTED. It will never return. 🔒",
				"Capsule"
			)

			print("[HypeDropScheduler] Capsule DEACTIVATED and VAULTED")
			activeCapsuleId = nil
			wasActive = false
		end

		task.wait(CHECK_INTERVAL)
	end
end)

print("[HypeDropScheduler] Initialized")

return nil
