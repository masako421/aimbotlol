-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

-- Player / Camera
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Settings（通常使用向け）
local AIM_ENABLED = true          -- ★ 実行時からON
local MAX_DISTANCE = 120          -- ★ 距離を短めに（自然）
local SMOOTHNESS = 0.12           -- なめらかさ（強すぎない）
local TARGET_PART = "Head"

-- Toggle（FキーでON/OFF）
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.F then
		AIM_ENABLED = not AIM_ENABLED
		warn("AimAssist:", AIM_ENABLED and "ON" or "OFF")
	end
end)

-- 一番近い敵を探す（チームチェック付き）
local function getClosestEnemy()
	local closestHead = nil
	local shortest = MAX_DISTANCE

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Team ~= LocalPlayer.Team then
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
