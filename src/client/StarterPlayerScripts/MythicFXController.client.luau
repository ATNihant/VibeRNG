-- MythicFXController.client.luau — World-breaking Mythic item effects
-- Handles activation/deactivation of server-wide visual effects for Mythic items
-- Source of truth: docs/game-design-document.md (Mythic Effects section)

local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local MythicFXActivated = RemoteEvents:WaitForChild("MythicFXActivated")
local MythicFXDeactivated = RemoteEvents:WaitForChild("MythicFXDeactivated")

local player = Players.LocalPlayer

-- ============================================================
-- STATE — track active effects for clean teardown
-- ============================================================
local activeEffects = {} -- [itemId] = { instances = {}, connections = {}, loops = {} }

-- ============================================================
-- UTILITY
-- ============================================================
local function getPlayerCharacter(userId)
	local targetPlayer = Players:GetPlayerByUserId(userId)
	if targetPlayer then
		return targetPlayer.Character
	end
	return nil
end

local function fadeOut(instance, property, duration)
	if instance and instance.Parent then
		local tween = TweenService:Create(instance, TweenInfo.new(duration), { [property] = 0 })
		tween:Play()
		tween.Completed:Connect(function()
			instance:Destroy()
		end)
	end
end

-- ============================================================
-- EFFECT: Indie Sleaze (B016 — Body Mythic)
-- Grainy film, paparazzi flashes, muffled club music
-- ============================================================
local function activateIndieSleaze(userId)
	local effects = { instances = {}, connections = {}, loops = {} }

	-- 1. Film grain ColorCorrectionEffect
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Name = "IndieSleaze_CC"
	cc.Saturation = -0.3
	cc.Contrast = 0.2
	cc.Brightness = -0.05
	cc.TintColor = Color3.fromRGB(255, 230, 200) -- warm tint
	cc.Parent = Lighting
	table.insert(effects.instances, cc)

	-- 2. Paparazzi flash effect on the player character
	local character = getPlayerCharacter(userId)
	if character then
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if hrp then
			local flashLight = Instance.new("PointLight")
			flashLight.Name = "IndieSleaze_Flash"
			flashLight.Color = Color3.fromRGB(255, 255, 255)
			flashLight.Brightness = 0
			flashLight.Range = 30
			flashLight.Parent = hrp
			table.insert(effects.instances, flashLight)

			-- Flash loop every 3-5 seconds
			local flashLoop = task.spawn(function()
				while flashLight.Parent do
					task.wait(math.random(30, 50) / 10)
					if flashLight.Parent then
						flashLight.Brightness = 8
						task.wait(0.1)
						if flashLight.Parent then
							flashLight.Brightness = 0
						end
					end
				end
			end)
			table.insert(effects.loops, flashLoop)

			-- Paparazzi particle burst
			local attachment = Instance.new("Attachment")
			attachment.Parent = hrp
			table.insert(effects.instances, attachment)

			local particles = Instance.new("ParticleEmitter")
			particles.Parent = attachment
			particles.Rate = 3
			particles.Lifetime = NumberRange.new(0.5, 1)
			particles.Speed = NumberRange.new(5, 10)
			particles.SpreadAngle = Vector2.new(180, 180)
			particles.Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.5),
				NumberSequenceKeypoint.new(1, 0),
			})
			particles.Color = ColorSequence.new(Color3.fromRGB(255, 255, 200))
			particles.LightEmission = 1
			table.insert(effects.instances, particles)
		end
	end

	return effects
end

-- ============================================================
-- EFFECT: Frutiger Aero (B017 — Body Mythic)
-- Water ripples, holographic butterflies, cyan tint
-- ============================================================
local function activateFrutigerAero(userId)
	local effects = { instances = {}, connections = {}, loops = {} }

	-- 1. Soft cyan ColorCorrectionEffect
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Name = "FrutigerAero_CC"
	cc.Saturation = 0.2
	cc.Contrast = 0.1
	cc.TintColor = Color3.fromRGB(200, 240, 255) -- cyan tint
	cc.Parent = Lighting
	table.insert(effects.instances, cc)

	-- 2. Water ripple particles around the player
	local character = getPlayerCharacter(userId)
	if character then
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if hrp then
			local attachment = Instance.new("Attachment")
			attachment.Position = Vector3.new(0, -2.5, 0) -- floor level
			attachment.Parent = hrp
			table.insert(effects.instances, attachment)

			local ripples = Instance.new("ParticleEmitter")
			ripples.Parent = attachment
			ripples.Rate = 8
			ripples.Lifetime = NumberRange.new(2, 3)
			ripples.Speed = NumberRange.new(2, 5)
			ripples.SpreadAngle = Vector2.new(180, 0)
			ripples.Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(0.5, 3),
				NumberSequenceKeypoint.new(1, 0),
			})
			ripples.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.5),
				NumberSequenceKeypoint.new(1, 1),
			})
			ripples.Color = ColorSequence.new(
				Color3.fromRGB(100, 200, 255),
				Color3.fromRGB(50, 150, 200)
			)
			ripples.LightEmission = 0.5
			table.insert(effects.instances, ripples)

			-- Butterfly orbit particles
			local butterflyAttachment = Instance.new("Attachment")
			butterflyAttachment.Position = Vector3.new(0, 3, 0)
			butterflyAttachment.Parent = hrp
			table.insert(effects.instances, butterflyAttachment)

			local butterflies = Instance.new("ParticleEmitter")
			butterflies.Parent = butterflyAttachment
			butterflies.Rate = 2
			butterflies.Lifetime = NumberRange.new(3, 5)
			butterflies.Speed = NumberRange.new(1, 3)
			butterflies.SpreadAngle = Vector2.new(360, 30)
			butterflies.Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.3),
				NumberSequenceKeypoint.new(0.5, 0.5),
				NumberSequenceKeypoint.new(1, 0.3),
			})
			butterflies.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(100, 255, 200)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(150, 200, 255)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 100, 255)),
			})
			butterflies.LightEmission = 0.8
			butterflies.RotSpeed = NumberRange.new(-180, 180)
			table.insert(effects.instances, butterflies)
		end
	end

	return effects
end

-- ============================================================
-- EFFECT: Vaporwave (H016 — Head Mythic)
-- Slow particles, magenta tint, pulsing grid
-- ============================================================
local function activateVaporwave(userId)
	local effects = { instances = {}, connections = {}, loops = {} }

	-- 1. Magenta CC with increased saturation
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Name = "Vaporwave_CC"
	cc.Saturation = 0.4
	cc.Contrast = 0.15
	cc.TintColor = Color3.fromRGB(255, 180, 220) -- magenta tint
	cc.Parent = Lighting
	table.insert(effects.instances, cc)

	-- 2. Roman bust orbit and grid effects on the player
	local character = getPlayerCharacter(userId)
	if character then
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if hrp then
			-- Pink and teal particles from feet
			local footAttachment = Instance.new("Attachment")
			footAttachment.Position = Vector3.new(0, -2.5, 0)
			footAttachment.Parent = hrp
			table.insert(effects.instances, footAttachment)

			local gridParticles = Instance.new("ParticleEmitter")
			gridParticles.Parent = footAttachment
			gridParticles.Rate = 15
			gridParticles.Lifetime = NumberRange.new(1, 2)
			gridParticles.Speed = NumberRange.new(3, 8)
			gridParticles.SpreadAngle = Vector2.new(180, 10)
			gridParticles.Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.1),
				NumberSequenceKeypoint.new(0.5, 0.3),
				NumberSequenceKeypoint.new(1, 0),
			})
			gridParticles.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 100, 200)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 200, 200)),
			})
			gridParticles.LightEmission = 1
			table.insert(effects.instances, gridParticles)

			-- Head orbit particles
			local headAttachment = Instance.new("Attachment")
			headAttachment.Position = Vector3.new(0, 3, 0)
			headAttachment.Parent = hrp
			table.insert(effects.instances, headAttachment)

			local orbitParticles = Instance.new("ParticleEmitter")
			orbitParticles.Parent = headAttachment
			orbitParticles.Rate = 4
			orbitParticles.Lifetime = NumberRange.new(2, 4)
			orbitParticles.Speed = NumberRange.new(1, 2)
			orbitParticles.SpreadAngle = Vector2.new(360, 30)
			orbitParticles.Size = NumberSequence.new(0.8)
			orbitParticles.Color = ColorSequence.new(Color3.fromRGB(220, 180, 200))
			orbitParticles.LightEmission = 0.6
			orbitParticles.RotSpeed = NumberRange.new(-90, 90)
			table.insert(effects.instances, orbitParticles)
		end
	end

	return effects
end

-- ============================================================
-- EFFECT: Cyber-Goth (L016 — Legs Mythic)
-- Strobing lights, acid-green footprints, industrial vibe
-- ============================================================
local function activateCyberGoth(userId)
	local effects = { instances = {}, connections = {}, loops = {} }

	-- 1. Desaturated + green tint CC
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Name = "CyberGoth_CC"
	cc.Saturation = -0.4
	cc.Contrast = 0.3
	cc.TintColor = Color3.fromRGB(180, 255, 180) -- green tint
	cc.Parent = Lighting
	table.insert(effects.instances, cc)

	-- 2. Strobing light effect
	local strobeLight = Instance.new("PointLight")
	strobeLight.Name = "CyberGoth_Strobe"
	strobeLight.Color = Color3.fromRGB(0, 255, 50)
	strobeLight.Brightness = 0
	strobeLight.Range = 60
	strobeLight.Parent = Workspace
	table.insert(effects.instances, strobeLight)

	local strobeLoop = task.spawn(function()
		while strobeLight.Parent do
			strobeLight.Brightness = 5
			task.wait(0.1)
			if strobeLight.Parent then
				strobeLight.Brightness = 0
			end
			task.wait(1.9)
		end
	end)
	table.insert(effects.loops, strobeLoop)

	-- 3. Acid-green footprint particles
	local character = getPlayerCharacter(userId)
	if character then
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if hrp then
			local footAttachment = Instance.new("Attachment")
			footAttachment.Position = Vector3.new(0, -2.5, 0)
			footAttachment.Parent = hrp
			table.insert(effects.instances, footAttachment)

			local footprints = Instance.new("ParticleEmitter")
			footprints.Parent = footAttachment
			footprints.Rate = 6
			footprints.Lifetime = NumberRange.new(3, 5)
			footprints.Speed = NumberRange.new(0, 0.5)
			footprints.Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.8, 1),
				NumberSequenceKeypoint.new(1, 0),
			})
			footprints.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.3),
				NumberSequenceKeypoint.new(0.7, 0.5),
				NumberSequenceKeypoint.new(1, 1),
			})
			footprints.Color = ColorSequence.new(Color3.fromRGB(0, 255, 50))
			footprints.LightEmission = 1
			table.insert(effects.instances, footprints)
		end
	end

	return effects
end

-- ============================================================
-- EFFECT: Gorpcore (H017 — Head Mythic)
-- Mountain geometry, wind sounds, natural atmosphere
-- ============================================================
local function activateGorpcore(userId)
	local effects = { instances = {}, connections = {}, loops = {} }

	-- No ColorCorrectionEffect — intentionally grounded/natural

	-- Nature particles around the player
	local character = getPlayerCharacter(userId)
	if character then
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if hrp then
			-- Leaf/nature particles
			local leafAttachment = Instance.new("Attachment")
			leafAttachment.Position = Vector3.new(0, 4, 0)
			leafAttachment.Parent = hrp
			table.insert(effects.instances, leafAttachment)

			local leaves = Instance.new("ParticleEmitter")
			leaves.Parent = leafAttachment
			leaves.Rate = 5
			leaves.Lifetime = NumberRange.new(3, 6)
			leaves.Speed = NumberRange.new(1, 4)
			leaves.SpreadAngle = Vector2.new(360, 90)
			leaves.Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.3),
				NumberSequenceKeypoint.new(0.5, 0.5),
				NumberSequenceKeypoint.new(1, 0.2),
			})
			leaves.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 140, 60)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(120, 100, 50)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(60, 120, 80)),
			})
			leaves.RotSpeed = NumberRange.new(-180, 180)
			leaves.Acceleration = Vector3.new(0, -2, 0) -- gravity
			table.insert(effects.instances, leaves)

			-- Dust/earth particles at feet
			local dustAttachment = Instance.new("Attachment")
			dustAttachment.Position = Vector3.new(0, -2.5, 0)
			dustAttachment.Parent = hrp
			table.insert(effects.instances, dustAttachment)

			local dust = Instance.new("ParticleEmitter")
			dust.Parent = dustAttachment
			dust.Rate = 8
			dust.Lifetime = NumberRange.new(2, 4)
			dust.Speed = NumberRange.new(1, 3)
			dust.SpreadAngle = Vector2.new(180, 20)
			dust.Size = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.5),
				NumberSequenceKeypoint.new(1, 2),
			})
			dust.Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0.5),
				NumberSequenceKeypoint.new(1, 1),
			})
			dust.Color = ColorSequence.new(Color3.fromRGB(160, 140, 100))
			table.insert(effects.instances, dust)
		end
	end

	return effects
end

-- ============================================================
-- EFFECT DISPATCH TABLE
-- Maps item IDs to their activation functions
-- ============================================================
local effectFunctions = {
	-- Indie Sleaze (Body Mythic)
	B016 = activateIndieSleaze,
	-- Frutiger Aero (Body Mythic)
	B017 = activateFrutigerAero,
	-- Vaporwave (Head Mythic)
	H016 = activateVaporwave,
	-- Gorpcore (Head Mythic)
	H017 = activateGorpcore,
	-- Cyber-Goth (Legs Mythic)
	L016 = activateCyberGoth,
}

-- ============================================================
-- ACTIVATION / DEACTIVATION
-- ============================================================
local function activateEffect(userId, itemId)
	-- If this item already has active effects, deactivate first
	if activeEffects[itemId] then
		-- Already active, skip
		return
	end

	local activateFn = effectFunctions[itemId]
	if not activateFn then
		warn("[MythicFXController] No effect function for item: " .. tostring(itemId))
		return
	end

	local effects = activateFn(userId)
	activeEffects[itemId] = effects

	print("[MythicFXController] Activated effect for " .. itemId)
end

local function deactivateEffect(userId, itemId)
	local effects = activeEffects[itemId]
	if not effects then return end

	-- Fade out and destroy all instances
	for _, instance in ipairs(effects.instances) do
		if instance and instance.Parent then
			-- Try to fade out gracefully
			if instance:IsA("ColorCorrectionEffect") then
				fadeOut(instance, "Brightness", 2)
			elseif instance:IsA("PointLight") or instance:IsA("SpotLight") then
				fadeOut(instance, "Brightness", 2)
			else
				instance:Destroy()
			end
		end
	end

	-- Disconnect connections
	for _, connection in ipairs(effects.connections) do
		if connection then
			connection:Disconnect()
		end
	end

	-- Cancel loops (they'll stop on their own when instances are destroyed)
	-- task.cancel would be ideal but coroutines stop when their referenced instances are destroyed

	activeEffects[itemId] = nil
	print("[MythicFXController] Deactivated effect for " .. itemId)
end

-- ============================================================
-- CONNECTIONS
-- ============================================================
MythicFXActivated.OnClientEvent:Connect(activateEffect)
MythicFXDeactivated.OnClientEvent:Connect(deactivateEffect)

print("[MythicFXController] Initialized")
