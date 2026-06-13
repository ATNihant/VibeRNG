-- RunwayManager.server.luau — 15-minute recurring Runway fashion event
-- Source of truth: docs/game-design-document.md (Runway section), architecture.md Section 5

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Data = ReplicatedStorage:WaitForChild("Data")
local AestheticsData = require(Data:WaitForChild("AestheticsData"))

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local RunwayStart = RemoteEvents:WaitForChild("RunwayStart")
local RunwayCountdown = RemoteEvents:WaitForChild("RunwayCountdown")
local RunwayYourTurn = RemoteEvents:WaitForChild("RunwayYourTurn")
local RunwayWalkerUpdate = RemoteEvents:WaitForChild("RunwayWalkerUpdate")
local RunwayResults = RemoteEvents:WaitForChild("RunwayResults")
local JoinRunway = RemoteEvents:WaitForChild("JoinRunway")
local SubmitRunwayLook = RemoteEvents:WaitForChild("SubmitRunwayLook")
local CastVote = RemoteEvents:WaitForChild("CastVote")
local ServerAnnouncement = RemoteEvents:WaitForChild("ServerAnnouncement")

-- ============================================================
-- CONFIGURATION
-- ============================================================
local RUNWAY_INTERVAL = 900 -- 15 minutes in seconds
local JOIN_WINDOW = 30 -- seconds to join
local BACKSTAGE_TIME = 60 -- seconds to pick a look
local WALK_TIME = 10 -- seconds per walker
local MIN_PARTICIPANTS = 1 -- minimum players to run (1 for testing, 2 for production)

-- Runway theme pool from game-design-document.md
local THEMES = {
	"90s Cyberpunk", "Y2K Beach Club", "Midnight Gorpcore",
	"Indie Sleaze After-Party", "Frutiger Forest", "Digital Coquette",
	"Vaporwave Mall", "Dark Academia Library", "Barbiecore Dreamhouse",
	"Cyber-Goth Rave", "Tokyo Streetwear", "Retro Futurist",
	"Lo-Fi Study Session", "Neon Noir",
}

-- Coin rewards
local REWARDS = {
	winner = 2000,
	top3 = 750,
	participation = 150,
}

-- ============================================================
-- STATE (runtime only, not persisted)
-- ============================================================
local runwayState = {
	isActive = false,
	theme = "",
	participants = {},        -- array of { userId, look = { Head, Body, Legs } }
	currentWalkerIndex = 1,
	votes = {},               -- votes[targetUserId] = { total = 0, count = 0 }
	phase = "idle",           -- "idle" | "joining" | "backstage" | "walking" | "results"
}

-- ============================================================
-- UTILITY
-- ============================================================
local function resetState()
	runwayState.isActive = false
	runwayState.theme = ""
	runwayState.participants = {}
	runwayState.currentWalkerIndex = 1
	runwayState.votes = {}
	runwayState.phase = "idle"
end

local function getRandomTheme()
	return THEMES[math.random(1, #THEMES)]
end

local function findParticipant(userId)
	for i, p in ipairs(runwayState.participants) do
		if p.userId == userId then
			return i, p
		end
	end
	return nil, nil
end

-- ============================================================
-- RUNWAY EVENT FLOW
-- ============================================================
local function runRunwayEvent()
	-- Wait for DataManager to be available
	while not _G.DataManager do
		task.wait(0.1)
	end
	local DataManager = _G.DataManager

	resetState()
	runwayState.isActive = true
	runwayState.theme = getRandomTheme()
	runwayState.phase = "joining"

	print("[RunwayManager] Runway starting! Theme: " .. runwayState.theme)

	-- 1. Announce to all clients
	RunwayStart:FireAllClients(runwayState.theme)
	ServerAnnouncement:FireAllClients(
		"✨ RUNWAY STARTING — THEME: " .. runwayState.theme:upper() .. " ✨",
		"Runway"
	)

	-- 2. Join window (30 seconds)
	task.wait(JOIN_WINDOW)

	-- Check minimum participants
	if #runwayState.participants < MIN_PARTICIPANTS then
		ServerAnnouncement:FireAllClients(
			"Runway cancelled — not enough participants.",
			"Info"
		)
		resetState()
		return
	end

	-- 3. Backstage phase (60 seconds)
	runwayState.phase = "backstage"
	for seconds = BACKSTAGE_TIME, 1, -1 do
		for _, p in ipairs(runwayState.participants) do
			local player = Players:GetPlayerByUserId(p.userId)
			if player then
				RunwayCountdown:FireClient(player, runwayState.theme, seconds)
			end
		end
		task.wait(1)
	end

	-- 4. Walking phase
	runwayState.phase = "walking"

	for i, participant in ipairs(runwayState.participants) do
		runwayState.currentWalkerIndex = i
		local player = Players:GetPlayerByUserId(participant.userId)
		if not player then continue end

		-- Initialize votes for this walker
		runwayState.votes[participant.userId] = { total = 0, count = 0 }

		-- Tell the walker it's their turn
		RunwayYourTurn:FireClient(player)

		-- Tell all clients who is walking
		RunwayWalkerUpdate:FireAllClients(participant.userId, participant.look)

		-- Wait for walk duration
		task.wait(WALK_TIME)
	end

	-- 5. Tally scores and announce results
	runwayState.phase = "results"

	local results = {}
	for _, participant in ipairs(runwayState.participants) do
		local voteData = runwayState.votes[participant.userId]
		local avgScore = 0
		if voteData and voteData.count > 0 then
			avgScore = voteData.total / voteData.count
		end
		table.insert(results, {
			userId = participant.userId,
			score = math.floor(avgScore * 100) / 100, -- 2 decimal places
		})
	end

	-- Sort by score descending
	table.sort(results, function(a, b) return a.score > b.score end)

	-- Award prizes
	for rank, entry in ipairs(results) do
		local player = Players:GetPlayerByUserId(entry.userId)
		if not player then continue end

		DataManager.RecordRunwayParticipation(player)
		DataManager.AddCoins(player, REWARDS.participation)

		if rank == 1 then
			DataManager.RecordRunwayWin(player)
			DataManager.AddCoins(player, REWARDS.winner)
		elseif rank <= 3 then
			DataManager.AddCoins(player, REWARDS.top3)
		end
	end

	-- Broadcast results to all clients
	RunwayResults:FireAllClients(results)

	if #results > 0 then
		local winner = Players:GetPlayerByUserId(results[1].userId)
		if winner then
			ServerAnnouncement:FireAllClients(
				"👑 " .. winner.DisplayName .. " won the Runway! 👑",
				"Runway"
			)
		end
	end

	print("[RunwayManager] Runway complete! " .. #results .. " participants.")

	-- Wait a moment before resetting
	task.wait(10)
	resetState()
end

-- ============================================================
-- CLIENT EVENT HANDLERS
-- ============================================================

-- Player wants to join the runway
JoinRunway.OnServerEvent:Connect(function(player)
	if runwayState.phase ~= "joining" then return end

	-- Check if already joined
	local _, existing = findParticipant(player.UserId)
	if existing then return end

	table.insert(runwayState.participants, {
		userId = player.UserId,
		look = { Head = nil, Body = nil, Legs = nil },
	})

	print("[RunwayManager] " .. player.Name .. " joined the runway.")
end)

-- Player submits their look
SubmitRunwayLook.OnServerEvent:Connect(function(player, head, body, legs)
	if runwayState.phase ~= "backstage" then return end

	while not _G.DataManager do
		task.wait(0.1)
	end
	local DataManager = _G.DataManager

	local _, participant = findParticipant(player.UserId)
	if not participant then return end

	-- Validate ownership
	local data = DataManager.GetData(player)
	if not data then return end

	local function validateItem(slot, itemId)
		if itemId == nil then return true end -- nil is valid (no item in slot)
		return data.Lookbook[slot] and data.Lookbook[slot][itemId] == true
	end

	if not validateItem("Head", head) then return end
	if not validateItem("Body", body) then return end
	if not validateItem("Legs", legs) then return end

	participant.look = {
		Head = head,
		Body = body,
		Legs = legs,
	}

	print("[RunwayManager] " .. player.Name .. " submitted their look.")
end)

-- Player casts a vote
CastVote.OnServerEvent:Connect(function(player, targetUserId, stars)
	if runwayState.phase ~= "walking" then return end

	-- Validate stars
	if type(stars) ~= "number" then return end
	stars = math.clamp(math.floor(stars), 1, 5)

	-- Can't vote for yourself
	if player.UserId == targetUserId then return end

	-- Must be voting for the current walker
	local currentParticipant = runwayState.participants[runwayState.currentWalkerIndex]
	if not currentParticipant or currentParticipant.userId ~= targetUserId then return end

	-- Record vote
	if not runwayState.votes[targetUserId] then
		runwayState.votes[targetUserId] = { total = 0, count = 0 }
	end

	runwayState.votes[targetUserId].total = runwayState.votes[targetUserId].total + stars
	runwayState.votes[targetUserId].count = runwayState.votes[targetUserId].count + 1
end)

-- ============================================================
-- MAIN LOOP — 15-minute interval
-- ============================================================
task.spawn(function()
	-- Wait a bit for the server to initialize
	task.wait(10)
	print("[RunwayManager] Initialized. First runway in " .. RUNWAY_INTERVAL .. " seconds.")

	while true do
		task.wait(RUNWAY_INTERVAL)
		local success, err = pcall(runRunwayEvent)
		if not success then
			warn("[RunwayManager] Runway event error: " .. tostring(err))
			resetState()
		end
	end
end)

return nil
