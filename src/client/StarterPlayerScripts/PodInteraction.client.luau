-- PodInteraction.client.luau — Designer Pod click detection
-- Fires RollRequested when player clicks a Designer Pod ClickDetector
-- Source of truth: docs/implementation-plan.md Phase 3

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local RollRequested = RemoteEvents:WaitForChild("RollRequested")

-- ============================================================
-- FIND PODS
-- ============================================================
local Map = Workspace:WaitForChild("Map", 10)
if not Map then
	warn("[PodInteraction] Map not found in Workspace")
	return
end

local DesignerPods = Map:FindFirstChild("DesignerPods")
if not DesignerPods then
	warn("[PodInteraction] DesignerPods folder not found in Map")
	return
end

-- ============================================================
-- CONNECT CLICK DETECTORS
-- ============================================================
local function connectPod(pod)
	local clickDetector = pod:FindFirstChildWhichIsA("ClickDetector")
	if clickDetector then
		clickDetector.MouseClick:Connect(function()
			RollRequested:FireServer()
		end)
		print("[PodInteraction] Connected to pod: " .. pod.Name)
	end
end

-- Connect existing pods
for _, pod in ipairs(DesignerPods:GetChildren()) do
	connectPod(pod)
end

-- Connect pods added later (in case of streaming)
DesignerPods.ChildAdded:Connect(function(child)
	task.wait(0.1) -- Brief wait for ClickDetector to replicate
	connectPod(child)
end)

print("[PodInteraction] Initialized")
