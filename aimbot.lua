--==============================
-- Rayfield Load
--==============================
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

--==============================
-- Services
--==============================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

--==============================
-- Window
--==============================
local Window = Rayfield:CreateWindow({
	Name = "Universal Test UI",
	LoadingTitle = "Loading UI",
	LoadingSubtitle = "Please wait",
	ConfigurationSaving = {Enabled = false}
})

--==============================
-- Tabs（必ず先に全部作る）
--==============================
local MainTab    = Window:CreateTab("Main")
local ESPTab     = Window:CreateTab("ESP")
local ESPR6Tab   = Window:CreateTab("ESP R6")
local AimR6Tab   = Window:CreateTab("aimR6")
local RivalsTab  = Window:CreateTab("ライバル専用")
local SettingsTab= Window:CreateTab("Settings")

--==============================
-- Variables
--==============================
local AimEnabled = false
local TeamCheck = true
local AimDistance = 150
local AimSmooth = 0.12

local FOVEnabled = true
local AimFOV = 80
local CameraFOV = 70

local ESPEnabled = false
local ESPBox = false
local ESPSkeleton = false

--==============================
-- Colors
--==============================
local Colors = {
	ESP = Color3.fromRGB(255,0,0),
	Skeleton = Color3.fromRGB(255,0,0),
	Box = Color3.fromRGB(255,0,0),
	FOV = Color3.fromRGB(255,255,255)
}

--==============================
-- Main Tab（Aim）
--==============================
MainTab:CreateToggle({
	Name = "Aim Assist",
	CurrentValue = false,
	Callback = function(v) AimEnabled = v end
})

MainTab:CreateToggle({
	Name = "Team Check",
	CurrentValue = true,
	Callback = function(v) TeamCheck = v end
})

MainTab:CreateSlider({
	Name = "Aim Distance",
	Range = {20,500},
	Increment = 10,
	CurrentValue = AimDistance,
	Callback = function(v) AimDistance = v end
})

MainTab:CreateSlider({
	Name = "Aim Smooth",
	Range = {0,1},
	Increment = 0.01,
	CurrentValue = AimSmooth,
	Callback = function(v) AimSmooth = v end
})

MainTab:CreateToggle({
	Name = "FOV Circle",
	CurrentValue = true,
	Callback = function(v) FOVEnabled = v end
})

MainTab:CreateSlider({
	Name = "Aim FOV Size",
	Range = {20,120},
	Increment = 1,
	CurrentValue = AimFOV,
	Callback = function(v) AimFOV = v end
})

--==============================
-- ESP Tab
--==============================
ESPTab:CreateToggle({
	Name = "ESP Enable",
	CurrentValue = false,
	Callback = function(v) ESPEnabled = v end
})

ESPTab:CreateToggle({
	Name = "Box ESP",
	CurrentValue = false,
	Callback = function(v) ESPBox = v end
})

ESPTab:CreateToggle({
	Name = "Skeleton ESP",
	CurrentValue = false,
	Callback = function(v) ESPSkeleton = v end
})

--==============================
-- ESP R6 Tab（同UIだけ用意）
--==============================
ESPR6Tab:CreateParagraph({
	Title = "ESP R6",
	Content = "R6対応ESP（内容はESPタブと同等）"
})

--==============================
-- Aim R6 Tab
--==============================
AimR6Tab:CreateToggle({
	Name = "Aim R6 Enable",
	CurrentValue = false,
	Callback = function(v) AimEnabled = v end
})

--==============================
-- Rivals Tab
--==============================
RivalsTab:CreateParagraph({
	Title = "Rivals Mode",
	Content = "HumanoidDescription対応ESP / Aim"
})

RivalsTab:CreateToggle({
	Name = "Rivals ESP",
	CurrentValue = false,
	Callback = function(v) ESPEnabled = v end
})

RivalsTab:CreateToggle({
	Name = "Rivals Aim",
	CurrentValue = false,
	Callback = function(v) AimEnabled = v end
})

--==============================
-- Settings（色変更）
--==============================
for name,color in pairs(Colors) do
	SettingsTab:CreateColorPicker({
		Name = name.." Color",
		Color = color,
		Callback = function(c) Colors[name] = c end
	})
end

SettingsTab:CreateSlider({
	Name = "Camera FOV",
	Range = {20,120},
	Increment = 1,
	CurrentValue = Camera.FieldOfView,
	Callback = function(v) Camera.FieldOfView = v end
})

--==============================
-- FOV Circle（描画）
--==============================
local FOVCircle = Drawing.new("Circle")
FOVCircle.Filled = false
FOVCircle.Thickness = 1

RunService.RenderStepped:Connect(function()
	FOVCircle.Visible = FOVEnabled
	FOVCircle.Radius = AimFOV
	FOVCircle.Color = Colors.FOV
	FOVCircle.Position = Vector2.new(
		Camera.ViewportSize.X/2,
		Camera.ViewportSize.Y/2
	)
end)

--==============================
-- Fキー トグル
--==============================
UIS.InputBegan:Connect(function(i,gp)
	if gp then return end
	if i.KeyCode == Enum.KeyCode.F then
		AimEnabled = not AimEnabled
	end
end)
