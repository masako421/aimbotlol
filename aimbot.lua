-- Rayfield
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
	Name = "Aim Assist",
	LoadingTitle = "Loading...",
	LoadingSubtitle = "Rayfield UI"
})

local MainTab = Window:CreateTab("Main", 4483362458)

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
-- Settings
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
-- UI（★必ず最初に全部作る）
----------------------------------------------------------------
local AimToggle = MainTab:CreateToggle({
	Name = "Aim Assist",
	CurrentValue = AIM_ENABLED,
	Callback = function(v)
		AIM_ENABLED = v
	end
})

MainTab:CreateToggle({
	Name = "Team Check",
	CurrentValue = TEAM_CHECK,
	Callback = function(v)
		TEAM_CHECK = v
	end
})

MainTab:CreateToggle({
	Name = "Prediction Aim",
	CurrentValue = PREDICTION_ENABLED,
	Callback = function(v)
		PREDICTION_ENABLED = v
	end
})

MainTab:CreateToggle({
	Name = "Show FOV",
	CurrentValue = SHOW_FOV,
	Callback = function(v)
		SHOW_FOV = v
	end
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
-- FOV Circle（★ Drawing を安全に）
----------------------------------------------------------------
local FOVCircle
local drawingOk = pcall(function()
	FOVCircle = Drawing.new("Circle")
	FOVCircle.Thickness = 1.5
	FOVCircle.Filled = false
	FOVCircle.Radius = FOV_RADIUS
	FOVCircle.Visible = false
end)

----------------------------------------------------------------
-- Utility
----------------------------------------------------------------
local function isInFOV(worldPos)
	local screenPos, onScreen = Camera:WorldToViewportPoint(worldPos)
	if not onScreen then return false end

	local mousePos = UserInputService:GetMouseLocation()
	local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude

	return dist <= FOV_RADIUS, dist
end

----------------------------------------------------------------
-- Target Search
----------------------------------------------------------------
local function getClosestTarget()
	local closest
	local shortest = math.huge

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			if TEAM_CHECK and player.Team == LocalPlayer.Team then
				continue
			end

			local char = player.Character
			local part = char and char:FindFirstChild(TARGET_PART)
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			local hum = char and char:FindFirstChildOfClass("Humanoid")

			if part and hrp and hum and hum.Health > 0 then
				local inFOV, fovDist = isInFOV(part.Position)
				if inFOV and fovDist < shortest then
					shortest = fovDist
					closest = part
				end
			end
		end
	end

	return closest
end

----------------------------------------------------------------
-- Main Loop
----------------------------------------------------------------
RunService.RenderStepped:Connect(function()
	if drawingOk and FOVCircle then
		FOVCircle.Visible = SHOW_FOV
		FOVCircle.Position = UserInputService:GetMouseLocation()
	end

	if not AIM_ENABLED then return end

	local target = getClosestTarget()
	if not target then return end

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
end)
