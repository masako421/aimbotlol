-- Rayfield
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
	Name = "Aim + ESP",
	LoadingTitle = "Loading...",
	LoadingSubtitle = "Rayfield UI"
})

-- Tabs
local MainTab = Window:CreateTab("Main", 4483362458)
local ESPTab  = Window:CreateTab("ESP", 4483362458)

----------------------------------------------------------------
-- Services
----------------------------------------------------------------
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

----------------------------------------------------------------
-- ===== Main (Aim) States =====
----------------------------------------------------------------
local AIM_ENABLED = false
local PREDICTION_ENABLED = false
local SHOW_FOV = false

local MAX_DISTANCE = 150
local SMOOTHNESS = 0.12
local TARGET_PART = "Head"
local PREDICTION_STRENGTH = 0.3
local FOV_RADIUS = 200

----------------------------------------------------------------
-- ===== ESP States =====
----------------------------------------------------------------
local ESP_HEAD = false
local ESP_BODY = false

----------------------------------------------------------------
-- ===== UI（必ず最初に作る）=====
----------------------------------------------------------------
local AimToggle = MainTab:CreateToggle({
	Name = "Aim Assist",
	CurrentValue = AIM_ENABLED,
	Callback = function(v) AIM_ENABLED = v end
})

MainTab:CreateToggle({
	Name = "Prediction Aim",
	CurrentValue = PREDICTION_ENABLED,
	Callback = function(v) PREDICTION_ENABLED = v end
})

MainTab:CreateToggle({
	Name = "Show FOV",
	CurrentValue = SHOW_FOV,
	Callback = function(v) SHOW_FOV = v end
})

ESPTab:CreateToggle({
	Name = "ESP Head Line",
	CurrentValue = ESP_HEAD,
	Callback = function(v) ESP_HEAD = v end
})

ESPTab:CreateToggle({
	Name = "ESP Body Line",
	CurrentValue = ESP_BODY,
	Callback = function(v) ESP_BODY = v end
})

----------------------------------------------------------------
-- Fキー Aim ON/OFF（UI同期）
----------------------------------------------------------------
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.F then
		AIM_ENABLED = not AIM_ENABLED
		AimToggle:Set(AIM_ENABLED)
	end
end)

----------------------------------------------------------------
-- ===== Drawing（安全初期化）=====
----------------------------------------------------------------
local drawingOk = pcall(function()
	local _ = Drawing.new("Line")
end)

-- FOV Circle
local FOVCircle
if drawingOk then
	FOVCircle = Drawing.new("Circle")
	FOVCircle.Thickness = 1.5
	FOVCircle.Filled = false
	FOVCircle.Radius = FOV_RADIUS
	FOVCircle.Visible = false
end

-- ESP Lines
local lines = {} -- [player] = {Head=Line, Body=Line}
local function getLine(player, key)
	lines[player] = lines[player] or {}
	if not lines[player][key] then
		local l = Drawing.new("Line")
		l.Thickness = 1.5
		l.Transparency = 1
		lines[player][key] = l
	end
	return lines[player][key]
end

----------------------------------------------------------------
-- Utilities
----------------------------------------------------------------
local function teamColor(player)
	if player.Team and player.Team.TeamColor then
		return player.Team.TeamColor.Color
	end
	return Color3.fromRGB(255,255,255)
end

local function isInFOV(worldPos)
	local sp, onScreen = Camera:WorldToViewportPoint(worldPos)
	if not onScreen then return false, math.huge end
	local mouse = UserInputService:GetMouseLocation()
	local d = (Vector2.new(sp.X, sp.Y) - mouse).Magnitude
	return d <= FOV_RADIUS, d
end

----------------------------------------------------------------
-- Target Search（FOV内・距離）
----------------------------------------------------------------
local function getClosestTarget()
	local best, bestD = nil, math.huge
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer then
			local char = plr.Character
			local part = char and char:FindFirstChild(TARGET_PART)
			local hum  = char and char:FindFirstChildOfClass("Humanoid")
			if part and hum and hum.Health > 0 then
				local inFOV, d2 = isInFOV(part.Position)
				if inFOV then
					local d3 = (Camera.CFrame.Position - part.Position).Magnitude
					if d3 < MAX_DISTANCE and d2 < bestD then
						bestD = d2
						best = part
					end
				end
			end
		end
	end
	return best
end

----------------------------------------------------------------
-- ===== Main Loop =====
----------------------------------------------------------------
RunService.RenderStepped:Connect(function()
	-- FOV描画
	if drawingOk and FOVCircle then
		FOVCircle.Visible = SHOW_FOV
		FOVCircle.Position = UserInputService:GetMouseLocation()
	end

	-- ===== Aim =====
	if AIM_ENABLED then
		local target = getClosestTarget()
		if target then
			local aimPos = target.Position
			if PREDICTION_ENABLED then
				local hrp = target.Parent:FindFirstChild("HumanoidRootPart")
				if hrp then
					local v = hrp.Velocity
					aimPos += Vector3.new(v.X, 0, v.Z) * PREDICTION_STRENGTH
				end
			end
			Camera.CFrame = Camera.CFrame:Lerp(
				CFrame.new(Camera.CFrame.Position, aimPos),
				SMOOTHNESS
			)
		end
	end

	-- ===== ESP =====
	if not drawingOk then return end
	local from = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)

	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer then
			local char = plr.Character
			local head = char and char:FindFirstChild("Head")
			local hrp  = char and char:FindFirstChild("HumanoidRootPart")
			local col  = teamColor(plr)

			-- Head line
			local lh = lines[plr] and lines[plr].Head
			if ESP_HEAD and head then
				local sp, on = Camera:WorldToViewportPoint(head.Position)
				if on then
					lh = getLine(plr, "Head")
					lh.From, lh.To, lh.Color, lh.Visible = from, Vector2.new(sp.X, sp.Y), col, true
				elseif lh then lh.Visible = false end
			elseif lh then lh.Visible = false end

			-- Body line
			local lb = lines[plr] and lines[plr].Body
			if ESP_BODY and hrp then
				local sp, on = Camera:WorldToViewportPoint(hrp.Position)
				if on then
					lb = getLine(plr, "Body")
					lb.From, lb.To, lb.Color, lb.Visible = from, Vector2.new(sp.X, sp.Y), col, true
				elseif lb then lb.Visible = false end
			elseif lb then lb.Visible = false end
		end
	end
end)
