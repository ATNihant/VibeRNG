-- RunwayUI.client.luau — Runway event UI (banner, join, backstage, walk view, voting, results)
-- Source of truth: docs/implementation-plan.md Phase 8

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local RunwayStart = RemoteEvents:WaitForChild("RunwayStart")
local RunwayCountdown = RemoteEvents:WaitForChild("RunwayCountdown")
local RunwayYourTurn = RemoteEvents:WaitForChild("RunwayYourTurn")
local RunwayWalkerUpdate = RemoteEvents:WaitForChild("RunwayWalkerUpdate")
local RunwayResults = RemoteEvents:WaitForChild("RunwayResults")
local JoinRunway = RemoteEvents:WaitForChild("JoinRunway")
local CastVote = RemoteEvents:WaitForChild("CastVote")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local runwayScreen = playerGui:WaitForChild("RunwayScreen")

-- ============================================================
-- BUILD UI ELEMENTS
-- ============================================================

-- Runway announcement banner (top of screen)
local banner = Instance.new("Frame")
banner.Name = "Banner"
banner.Size = UDim2.new(0.6, 0, 0, 60)
banner.Position = UDim2.new(0.5, 0, -0.1, 0) -- start off-screen
banner.AnchorPoint = Vector2.new(0.5, 0)
banner.BackgroundColor3 = Color3.fromRGB(139, 0, 255)
banner.BorderSizePixel = 0
banner.ZIndex = 20
banner.Parent = runwayScreen

local bannerCorner = Instance.new("UICorner")
bannerCorner.CornerRadius = UDim.new(0, 12)
bannerCorner.Parent = banner

local bannerGradient = Instance.new("UIGradient")
bannerGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(139, 0, 255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 50, 200)),
})
bannerGradient.Parent = banner

local bannerText = Instance.new("TextLabel")
bannerText.Size = UDim2.fromScale(0.9, 1)
bannerText.Position = UDim2.fromScale(0.5, 0.5)
bannerText.AnchorPoint = Vector2.new(0.5, 0.5)
bannerText.BackgroundTransparency = 1
bannerText.Font = Enum.Font.GothamBold
bannerText.TextSize = 20
bannerText.TextColor3 = Color3.fromRGB(255, 255, 255)
bannerText.Text = ""
bannerText.ZIndex = 21
bannerText.Parent = banner

-- Join button
local joinButton = Instance.new("TextButton")
joinButton.Name = "JoinButton"
joinButton.Size = UDim2.fromOffset(200, 50)
joinButton.Position = UDim2.new(0.5, 0, 0, 75)
joinButton.AnchorPoint = Vector2.new(0.5, 0)
joinButton.BackgroundColor3 = Color3.fromRGB(30, 200, 80)
joinButton.BorderSizePixel = 0
joinButton.Font = Enum.Font.GothamBold
joinButton.TextSize = 18
joinButton.TextColor3 = Color3.fromRGB(255, 255, 255)
joinButton.Text = "✨ JOIN RUNWAY"
joinButton.Visible = false
joinButton.ZIndex = 21
joinButton.Parent = runwayScreen

local joinCorner = Instance.new("UICorner")
joinCorner.CornerRadius = UDim.new(0, 10)
joinCorner.Parent = joinButton

-- Backstage countdown
local countdownFrame = Instance.new("Frame")
countdownFrame.Name = "Countdown"
countdownFrame.Size = UDim2.fromOffset(300, 120)
countdownFrame.Position = UDim2.fromScale(0.5, 0.5)
countdownFrame.AnchorPoint = Vector2.new(0.5, 0.5)
countdownFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
countdownFrame.BorderSizePixel = 0
countdownFrame.Visible = false
countdownFrame.ZIndex = 20
countdownFrame.Parent = runwayScreen

local countdownCornerInst = Instance.new("UICorner")
countdownCornerInst.CornerRadius = UDim.new(0, 12)
countdownCornerInst.Parent = countdownFrame

local countdownStroke = Instance.new("UIStroke")
countdownStroke.Color = Color3.fromRGB(139, 0, 255)
countdownStroke.Thickness = 2
countdownStroke.Parent = countdownFrame

local countdownTitle = Instance.new("TextLabel")
countdownTitle.Size = UDim2.new(0.9, 0, 0, 30)
countdownTitle.Position = UDim2.new(0.5, 0, 0, 10)
countdownTitle.AnchorPoint = Vector2.new(0.5, 0)
countdownTitle.BackgroundTransparency = 1
countdownTitle.Font = Enum.Font.GothamBold
countdownTitle.TextSize = 14
countdownTitle.TextColor3 = Color3.fromRGB(200, 200, 210)
countdownTitle.Text = "BACKSTAGE — PICK YOUR LOOK"
countdownTitle.ZIndex = 21
countdownTitle.Parent = countdownFrame

local countdownTimer = Instance.new("TextLabel")
countdownTimer.Name = "Timer"
countdownTimer.Size = UDim2.new(0.9, 0, 0, 50)
countdownTimer.Position = UDim2.new(0.5, 0, 0, 45)
countdownTimer.AnchorPoint = Vector2.new(0.5, 0)
countdownTimer.BackgroundTransparency = 1
countdownTimer.Font = Enum.Font.GothamBold
countdownTimer.TextSize = 36
countdownTimer.TextColor3 = Color3.fromRGB(255, 255, 255)
countdownTimer.Text = "60"
countdownTimer.ZIndex = 21
countdownTimer.Parent = countdownFrame

local themeLabel = Instance.new("TextLabel")
themeLabel.Size = UDim2.new(0.9, 0, 0, 20)
themeLabel.Position = UDim2.new(0.5, 0, 1, -25)
themeLabel.AnchorPoint = Vector2.new(0.5, 0)
themeLabel.BackgroundTransparency = 1
themeLabel.Font = Enum.Font.Gotham
themeLabel.TextSize = 12
themeLabel.TextColor3 = Color3.fromRGB(139, 0, 255)
themeLabel.Text = ""
themeLabel.ZIndex = 21
themeLabel.Parent = countdownFrame

-- Walker display
local walkerFrame = Instance.new("Frame")
walkerFrame.Name = "WalkerDisplay"
walkerFrame.Size = UDim2.new(0.5, 0, 0, 50)
walkerFrame.Position = UDim2.new(0.5, 0, 0.85, 0)
walkerFrame.AnchorPoint = Vector2.new(0.5, 0)
walkerFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
walkerFrame.BorderSizePixel = 0
walkerFrame.Visible = false
walkerFrame.ZIndex = 20
walkerFrame.Parent = runwayScreen

local walkerCornerInst = Instance.new("UICorner")
walkerCornerInst.CornerRadius = UDim.new(0, 10)
walkerCornerInst.Parent = walkerFrame

local walkerName = Instance.new("TextLabel")
walkerName.Size = UDim2.new(0.6, 0, 1, 0)
walkerName.Position = UDim2.fromOffset(15, 0)
walkerName.BackgroundTransparency = 1
walkerName.Font = Enum.Font.GothamBold
walkerName.TextSize = 16
walkerName.TextColor3 = Color3.fromRGB(255, 255, 255)
walkerName.Text = ""
walkerName.TextXAlignment = Enum.TextXAlignment.Left
walkerName.ZIndex = 21
walkerName.Parent = walkerFrame

-- Voting stars
local starsFrame = Instance.new("Frame")
starsFrame.Name = "Stars"
starsFrame.Size = UDim2.fromOffset(200, 40)
starsFrame.Position = UDim2.new(1, -10, 0.5, 0)
starsFrame.AnchorPoint = Vector2.new(1, 0.5)
starsFrame.BackgroundTransparency = 1
starsFrame.ZIndex = 21
starsFrame.Parent = walkerFrame

local starsLayout = Instance.new("UIListLayout")
starsLayout.FillDirection = Enum.FillDirection.Horizontal
starsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
starsLayout.Padding = UDim.new(0, 4)
starsLayout.Parent = starsFrame

local currentWalkerUserId = nil

local function createStarButtons()
	for _, child in ipairs(starsFrame:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	for i = 1, 5 do
		local star = Instance.new("TextButton")
		star.Size = UDim2.fromOffset(32, 32)
		star.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
		star.BorderSizePixel = 0
		star.Font = Enum.Font.GothamBold
		star.TextSize = 20
		star.Text = "⭐"
		star.TextColor3 = Color3.fromRGB(255, 200, 50)
		star.ZIndex = 22
		star.Parent = starsFrame

		local starCornerInst = Instance.new("UICorner")
		starCornerInst.CornerRadius = UDim.new(0, 6)
		starCornerInst.Parent = star

		star.MouseButton1Click:Connect(function()
			if currentWalkerUserId and currentWalkerUserId ~= player.UserId then
				CastVote:FireServer(currentWalkerUserId, i)
				-- Visual feedback: highlight all stars up to this one
				for _, child in ipairs(starsFrame:GetChildren()) do
					if child:IsA("TextButton") then
						child.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
					end
				end
				-- Highlight selected
				for j = 1, i do
					local starBtn = starsFrame:FindFirstChild("") -- We need to index them
				end
				star.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
			end
		end)
	end
end

-- Results screen
local resultsFrame = Instance.new("Frame")
resultsFrame.Name = "Results"
resultsFrame.Size = UDim2.fromOffset(350, 400)
resultsFrame.Position = UDim2.fromScale(0.5, 0.5)
resultsFrame.AnchorPoint = Vector2.new(0.5, 0.5)
resultsFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
resultsFrame.BorderSizePixel = 0
resultsFrame.Visible = false
resultsFrame.ZIndex = 25
resultsFrame.Parent = runwayScreen

local resultsCornerInst = Instance.new("UICorner")
resultsCornerInst.CornerRadius = UDim.new(0, 16)
resultsCornerInst.Parent = resultsFrame

local resultsStroke = Instance.new("UIStroke")
resultsStroke.Color = Color3.fromRGB(255, 200, 50)
resultsStroke.Thickness = 2
resultsStroke.Parent = resultsFrame

local resultsTitle = Instance.new("TextLabel")
resultsTitle.Size = UDim2.new(0.9, 0, 0, 40)
resultsTitle.Position = UDim2.new(0.5, 0, 0, 10)
resultsTitle.AnchorPoint = Vector2.new(0.5, 0)
resultsTitle.BackgroundTransparency = 1
resultsTitle.Font = Enum.Font.GothamBold
resultsTitle.TextSize = 22
resultsTitle.TextColor3 = Color3.fromRGB(255, 200, 50)
resultsTitle.Text = "👑 RUNWAY RESULTS"
resultsTitle.ZIndex = 26
resultsTitle.Parent = resultsFrame

local resultsContainer = Instance.new("ScrollingFrame")
resultsContainer.Size = UDim2.new(0.9, 0, 1, -70)
resultsContainer.Position = UDim2.new(0.5, 0, 0, 55)
resultsContainer.AnchorPoint = Vector2.new(0.5, 0)
resultsContainer.BackgroundTransparency = 1
resultsContainer.BorderSizePixel = 0
resultsContainer.ScrollBarThickness = 3
resultsContainer.AutomaticCanvasSize = Enum.AutomaticSize.Y
resultsContainer.ZIndex = 26
resultsContainer.Parent = resultsFrame

local resultsListLayout = Instance.new("UIListLayout")
resultsListLayout.Padding = UDim.new(0, 6)
resultsListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
resultsListLayout.Parent = resultsContainer

-- ============================================================
-- EVENT HANDLERS
-- ============================================================

-- Runway starts — show banner and join button
RunwayStart.OnClientEvent:Connect(function(theme)
	-- Animate banner in
	bannerText.Text = "✨ RUNWAY — THEME: " .. theme:upper() .. " ✨"
	banner.Position = UDim2.new(0.5, 0, -0.1, 0)

	TweenService:Create(banner, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, 0, 0, 10)
	}):Play()

	joinButton.Visible = true

	-- Auto-hide join button after 30 seconds
	task.delay(30, function()
		joinButton.Visible = false
	end)
end)

-- Join button
joinButton.MouseButton1Click:Connect(function()
	JoinRunway:FireServer()
	joinButton.Visible = false
	joinButton.Text = "✅ JOINED!"
	task.delay(2, function()
		joinButton.Text = "✨ JOIN RUNWAY"
	end)
end)

-- Backstage countdown
RunwayCountdown.OnClientEvent:Connect(function(theme, secondsLeft)
	countdownFrame.Visible = true
	countdownTimer.Text = tostring(secondsLeft)
	themeLabel.Text = "Theme: " .. theme

	-- Urgency color at low seconds
	if secondsLeft <= 10 then
		countdownTimer.TextColor3 = Color3.fromRGB(255, 80, 80)
	elseif secondsLeft <= 30 then
		countdownTimer.TextColor3 = Color3.fromRGB(255, 200, 50)
	else
		countdownTimer.TextColor3 = Color3.fromRGB(255, 255, 255)
	end

	if secondsLeft <= 0 then
		countdownFrame.Visible = false
	end
end)

-- Walker update (someone is walking the catwalk)
RunwayWalkerUpdate.OnClientEvent:Connect(function(userId, look)
	-- Hide other UI elements
	countdownFrame.Visible = false
	banner.Position = UDim2.new(0.5, 0, -0.1, 0) -- hide banner

	-- Show walker display
	walkerFrame.Visible = true
	currentWalkerUserId = userId

	local walkerPlayer = Players:GetPlayerByUserId(userId)
	walkerName.Text = walkerPlayer and walkerPlayer.DisplayName or "Unknown"

	-- Create star buttons for voting
	createStarButtons()

	-- Auto-hide after walk time
	task.delay(10, function()
		if currentWalkerUserId == userId then
			walkerFrame.Visible = false
			currentWalkerUserId = nil
		end
	end)
end)

-- It's your turn to walk!
RunwayYourTurn.OnClientEvent:Connect(function()
	-- Show a prominent "YOUR TURN" indicator
	local yourTurnLabel = Instance.new("TextLabel")
	yourTurnLabel.Size = UDim2.fromOffset(300, 60)
	yourTurnLabel.Position = UDim2.fromScale(0.5, 0.3)
	yourTurnLabel.AnchorPoint = Vector2.new(0.5, 0.5)
	yourTurnLabel.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
	yourTurnLabel.BorderSizePixel = 0
	yourTurnLabel.Font = Enum.Font.GothamBold
	yourTurnLabel.TextSize = 28
	yourTurnLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
	yourTurnLabel.Text = "👟 YOUR TURN! WALK!"
	yourTurnLabel.ZIndex = 30
	yourTurnLabel.Parent = runwayScreen

	local yourTurnCorner = Instance.new("UICorner")
	yourTurnCorner.CornerRadius = UDim.new(0, 12)
	yourTurnCorner.Parent = yourTurnLabel

	-- Animate pulse
	task.spawn(function()
		for _ = 1, 5 do
			TweenService:Create(yourTurnLabel, TweenInfo.new(0.3), {
				Size = UDim2.fromOffset(320, 65)
			}):Play()
			task.wait(0.3)
			TweenService:Create(yourTurnLabel, TweenInfo.new(0.3), {
				Size = UDim2.fromOffset(300, 60)
			}):Play()
			task.wait(0.3)
		end
	end)

	-- Auto-remove after walk time
	task.delay(10, function()
		if yourTurnLabel.Parent then
			yourTurnLabel:Destroy()
		end
	end)
end)

-- Results
RunwayResults.OnClientEvent:Connect(function(results)
	-- Hide walking UI
	walkerFrame.Visible = false
	currentWalkerUserId = nil

	-- Clear previous results
	for _, child in ipairs(resultsContainer:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	-- Populate results
	local medals = { "🥇", "🥈", "🥉" }
	for rank, entry in ipairs(results) do
		local resultPlayer = Players:GetPlayerByUserId(entry.userId)
		local displayName = resultPlayer and resultPlayer.DisplayName or ("Player " .. entry.userId)

		local row = Instance.new("Frame")
		row.Size = UDim2.new(1, 0, 0, 45)
		row.BackgroundColor3 = rank <= 3 and Color3.fromRGB(30, 30, 38) or Color3.fromRGB(22, 22, 28)
		row.BorderSizePixel = 0
		row.ZIndex = 27
		row.LayoutOrder = rank
		row.Parent = resultsContainer

		local rowCorner = Instance.new("UICorner")
		rowCorner.CornerRadius = UDim.new(0, 8)
		rowCorner.Parent = row

		local rankLabel = Instance.new("TextLabel")
		rankLabel.Size = UDim2.fromOffset(40, 45)
		rankLabel.Position = UDim2.fromOffset(5, 0)
		rankLabel.BackgroundTransparency = 1
		rankLabel.Font = Enum.Font.GothamBold
		rankLabel.TextSize = rank <= 3 and 22 or 14
		rankLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		rankLabel.Text = medals[rank] or ("#" .. rank)
		rankLabel.ZIndex = 28
		rankLabel.Parent = row

		local nameLabel = Instance.new("TextLabel")
		nameLabel.Size = UDim2.new(0.5, 0, 1, 0)
		nameLabel.Position = UDim2.fromOffset(50, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.TextSize = 14
		nameLabel.TextColor3 = Color3.fromRGB(220, 220, 230)
		nameLabel.Text = displayName
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.ZIndex = 28
		nameLabel.Parent = row

		local scoreLabel = Instance.new("TextLabel")
		scoreLabel.Size = UDim2.fromOffset(80, 45)
		scoreLabel.Position = UDim2.new(1, -85, 0, 0)
		scoreLabel.BackgroundTransparency = 1
		scoreLabel.Font = Enum.Font.GothamBold
		scoreLabel.TextSize = 16
		scoreLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
		scoreLabel.Text = "⭐ " .. tostring(entry.score)
		scoreLabel.ZIndex = 28
		scoreLabel.Parent = row
	end

	resultsFrame.Visible = true

	-- Auto-hide after 10 seconds
	task.delay(10, function()
		TweenService:Create(resultsFrame, TweenInfo.new(0.5), {
			Position = UDim2.fromScale(0.5, 1.5)
		}):Play()
		task.wait(0.5)
		resultsFrame.Visible = false
		resultsFrame.Position = UDim2.fromScale(0.5, 0.5)
	end)
end)

runwayScreen.Enabled = true
print("[RunwayUI] Initialized")
