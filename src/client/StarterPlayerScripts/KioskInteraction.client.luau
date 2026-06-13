-- KioskInteraction.client.luau — Lookbook Kiosk proximity prompt handler
-- Toggles LookbookScreen visibility when player triggers a kiosk ProximityPrompt
-- Source of truth: docs/implementation-plan.md Phase 6

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ============================================================
-- FIND KIOSKS
-- ============================================================
local Map = Workspace:WaitForChild("Map", 10)
if not Map then
	warn("[KioskInteraction] Map not found in Workspace")
	return
end

local LookbookKiosks = Map:FindFirstChild("LookbookKiosks")
if not LookbookKiosks then
	warn("[KioskInteraction] LookbookKiosks folder not found in Map")
	return
end

-- ============================================================
-- CONNECT PROXIMITY PROMPTS
-- ============================================================
local function connectKiosk(kiosk)
	local prompt = kiosk:FindFirstChildWhichIsA("ProximityPrompt")
	if prompt then
		prompt.Triggered:Connect(function(triggerPlayer)
			if triggerPlayer ~= player then return end

			local lookbookScreen = playerGui:FindFirstChild("LookbookScreen")
			if lookbookScreen then
				lookbookScreen.Enabled = not lookbookScreen.Enabled
			end
		end)
		print("[KioskInteraction] Connected to kiosk: " .. kiosk.Name)
	end
end

-- Connect existing kiosks
for _, kiosk in ipairs(LookbookKiosks:GetChildren()) do
	connectKiosk(kiosk)
end

-- Connect kiosks added later
LookbookKiosks.ChildAdded:Connect(function(child)
	task.wait(0.1)
	connectKiosk(child)
end)

print("[KioskInteraction] Initialized")
