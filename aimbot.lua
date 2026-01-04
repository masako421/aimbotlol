-- Rayfield
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
	Name = "Aim Assist",
	LoadingTitle = "Loading...",
	LoadingSubtitle = "Rayfield UI"
})

local MainTab = Window:CreateTab("Main", 4483362458)

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

-- Player / Camera
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Settings
local AIM_ENABLED = false          -- 起動時OFF
local TEAM_CHECK = true           -- ★ チームチェック初期ON
local MAX_DISTANCE = 120
local SMOOTHNESS = 0.12
local TARGET_PART = "Head"

-- Aim Toggle
local AimToggle
AimToggle = MainTab:CreateToggle({
	Name = "Aim Assist",
	CurrentValue = AIM_ENABLED,
	Flag = "AimAssistToggle",
	Callback = function(Value)
		AIM_ENABLED = Value
	end,
})

-- Team Check Toggle
local TeamToggle
TeamToggle = MainTab:CreateToggle({
	Name = "Team Check",
	CurrentValue = TEAM_CHECK,
	Flag = "TeamCheckToggle",
	Callback = function(Value)
		TEAM_CHECK = Value
	end,
})

-- Fキーで Aim ON / OFF（UI同期）
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.F then
		AIM_ENABLED = not AIM_ENABLED
		AimToggle:Set(AIM_ENABLED)
	end
end)

-- 一番近いターゲット取得
local function getClosestEnemy()
	local closestHead = nil
	local shortest = MAX_DISTANCE

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			if TEAM_CHECK and player.Team == LocalPlayer.Team then
				continue
			end

			local char = player.Character
			local head = char and char:FindFirstChild(TARGET_PART)
			local hum = char and char:FindFirstChildOfClass("Humanoid")

			if head and hum and hum.Health > 0 then
				local dist = (Camera.CFrame.Position - head.Position).Magnitude
				if dist < shortest then
					shortest = dist
					closestHead = head
				end
			end
		end
	end

	return closestHead
end

-- メイン処理
RunService.RenderStepped:Connect(function()
	if not AIM_ENABLED then return end

	local target = getClosestEnemy()
	if not target then return end

	local camPos = Camera.CFrame.Position
	local targetCF = CFrame.new(camPos, target.Position)

	Camera.CFrame = Camera.CFrame:Lerp(targetCF, SMOOTHNESS)
end)
