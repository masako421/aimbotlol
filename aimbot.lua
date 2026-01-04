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
local TEAM_CHECK = true
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
local ESP_SKELETON = false

----------------------------------------------------------------
-- ===== UI（最初に全部作る）=====
----------------------------------------------------------------
local AimToggle = MainTab:CreateToggle({
	Name = "Aim Assist",
	CurrentValue = AIM_ENABLED,
	Callback = function(v) AIM_ENABLED = v end
})

MainTab:CreateToggle({
	Name = "Team Check (Aim)",
	CurrentValue = TEAM_CHECK,
	Callback = function(v) TEAM_CHECK = v end
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

ESPTab:CreateToggle({
	Name = "ESP Skeleton",
	CurrentValue = ESP_SKELETON,
	Callback = function(v) ESP_SKELETON = v end
})

----------------------------------------------------------------
-- Fキー Aim ON/OFF
----------------------------------------------------------------
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.F then
		AIM_ENABLED = not AIM_ENABLED
		AimToggle:Set(AIM_ENABLED)
	end
end)

----------------------------------------------------------------
-- ===== Drawing 安全初期化 =====
----------------------------------------------------------------
local drawingOk = pcall(function()
	local _ = Drawing.new("Line")
end)

local RED = Color3.fromRGB(255, 0, 0)

-- FOV Circle
local FOVCircle
if drawingOk then
	FOVCircle = Drawing.new("Circle")
	FOVCircle.Thickness = 1.5
	FOVCircle.Filled = false
	FOVCircle.Radius = FOV_RADIUS
	FOVCircle.Visible = false
end

-- Line管理
local lines = {} -- [player] = { key = Line }

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
-- Utility
----------------------------------------------------------------
local function isInFOV(worldPos)
	local sp, onScreen = Camera:WorldToViewportPoint(worldPos)
	if not onScreen then return false, math.huge end
	local mouse = UserInputService:GetMouseLocation()
	local d = (Vector2.new(sp.X, sp.Y) - mouse).Magnitude
	return d <= FOV_RADIUS, d
end

----------------------------------------------------------------
-- Target Search（Aim）
----------------------------------------------------------------
local function getClosestTarget()
	local best, bestD = nil, math.huge
	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer then
			if TEAM_CHECK and plr.Team == LocalPlayer.Team then
				continue
			end
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
-- Skeleton定義（接続）
----------------------------------------------------------------
local skeletonPairs = {
	{"Head","UpperTorso"},
	{"UpperTorso","LowerTorso"},
	{"UpperTorso","LeftUpperArm"},
	{"LeftUpperArm","LeftLowerArm"},
	{"UpperTorso","RightUpperArm"},
	{"RightUpperArm","RightLowerArm"},
	{"LowerTorso","LeftUpperLeg"},
	{"LeftUpperLeg","LeftLowerLeg"},
	{"LowerTorso","RightUpperLeg"},
	{"RightUpperLeg","RightLowerLeg"},
}

----------------------------------------------------------------
-- ===== Main Loop =====
----------------------------------------------------------------
RunService.RenderStepped:Connect(function()
	-- FOV
	if drawingOk and FOVCircle then
		FOVCircle.Visible = SHOW_FOV
		FOVCircle.Position = UserInputService:GetMouseLocation()
	end

	-- Aim
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

	-- ESP
	if not drawingOk then return end
	local from = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)

	for _, plr in ipairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer then
			local char = plr.Character

			-- Head Line
			local head = char and char:FindFirstChild("Head")
			local lh = lines[plr] and lines[plr].Head
			if ESP_HEAD and head then
				local sp, on = Camera:WorldToViewportPoint(head.Position)
				if on then
					lh = getLine(plr, "Head")
					lh.From, lh.To, lh.Color, lh.Visible = from, Vector2.new(sp.X, sp.Y), RED, true
				elseif lh then lh.Visible = false end
			elseif lh then lh.Visible = false end

			-- Body Line
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			local lb = lines[plr] and lines[plr].Body
			if ESP_BODY and hrp then
				local sp, on = Camera:WorldToViewportPoint(hrp.Position)
				if on then
					lb = getLine(plr, "Body")
					lb.From, lb.To, lb.Color, lb.Visible = from, Vector2.new(sp.X, sp.Y), RED, true
				elseif lb then lb.Visible = false end
			elseif lb then lb.Visible = false end

			-- Skeleton
			for _, pair in ipairs(skeletonPairs) do
				local a = char and char:FindFirstChild(pair[1])
				local b = char and char:FindFirstChild(pair[2])
				local key = "SK_"..pair[1]..pair[2]
				local ls = lines[plr] and lines[plr][key]
				if ESP_SKELETON and a and b then
					local sa, oa = Camera:WorldToViewportPoint(a.Position)
					local sb, ob = Camera:WorldToViewportPoint(b.Position)
					if oa and ob then
						ls = getLine(plr, key)
						ls.From = Vector2.new(sa.X, sa.Y)
						ls.To   = Vector2.new(sb.X, sb.Y)
						ls.Color = RED
						ls.Visible = true
					elseif ls then ls.Visible = false end
				elseif ls then ls.Visible = false end
			end
		end
	end
end)
