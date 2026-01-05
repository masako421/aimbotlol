--==============================
-- PlaceId Check（必要なら）
--==============================
-- local ALLOWED_PLACE_ID = 0
-- if ALLOWED_PLACE_ID ~= 0 and game.PlaceId ~= ALLOWED_PLACE_ID then return end

--==============================
-- Rayfield
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
	LoadingTitle = "Loading",
	LoadingSubtitle = "ESP / AIM",
	ConfigurationSaving = {Enabled = false}
})

--==============================
-- Tabs
--==============================
local MainTab = Window:CreateTab("Main")
local ESPTab = Window:CreateTab("ESP")
local ESPR6Tab = Window:CreateTab("ESP R6")
local AimR6Tab = Window:CreateTab("aimR6")
local RivalsTab = Window:CreateTab("ライバル専用")
local SettingsTab = Window:CreateTab("Settings")

--==============================
-- Settings
--==============================
local AIM = false
local TEAM_CHECK = true
local AIM_DISTANCE = 150
local SMOOTH = 0.12
local PREDICT = false

local FOV_ENABLED = true
local FOV_RADIUS = 80

local ESP_ENABLED = false
local ESP_BOX = false
local ESP_SKELETON = false
local UPDATE_RATE = 0.03

--==============================
-- Colors
--==============================
local COLORS = {
	Head = Color3.fromRGB(255,0,0),
	Body = Color3.fromRGB(255,0,0),
	Box = Color3.fromRGB(255,0,0),
	Skeleton = Color3.fromRGB(255,0,0),
	FOV = Color3.fromRGB(255,255,255)
}

--==============================
-- UI Main
--==============================
MainTab:CreateToggle({Name="Aim Assist",Callback=function(v) AIM=v end})
MainTab:CreateToggle({Name="Team Check",CurrentValue=true,Callback=function(v) TEAM_CHECK=v end})
MainTab:CreateToggle({Name="Prediction",Callback=function(v) PREDICT=v end})

MainTab:CreateSlider({
	Name="Aim Distance",
	Range={20,500},
	Increment=5,
	CurrentValue=AIM_DISTANCE,
	Callback=function(v) AIM_DISTANCE=v end
})

--==============================
-- FOV
--==============================
MainTab:CreateToggle({Name="FOV Circle",CurrentValue=true,Callback=function(v) FOV_ENABLED=v end})

MainTab:CreateSlider({
	Name="Camera FOV",
	Range={20,120},
	Increment=1,
	CurrentValue=Camera.FieldOfView,
	Callback=function(v) Camera.FieldOfView=v end
})

MainTab:CreateSlider({
	Name="Aim FOV Size",
	Range={20,120},
	Increment=1,
	CurrentValue=FOV_RADIUS,
	Callback=function(v) FOV_RADIUS=v end
})

--==============================
-- ESP UI
--==============================
ESPTab:CreateToggle({Name="ESP Enable",Callback=function(v) ESP_ENABLED=v end})
ESPTab:CreateToggle({Name="Box ESP",Callback=function(v) ESP_BOX=v end})
ESPTab:CreateToggle({Name="Skeleton ESP",Callback=function(v) ESP_SKELETON=v end})

--==============================
-- Color Pickers
--==============================
for k,_ in pairs(COLORS) do
	SettingsTab:CreateColorPicker({
		Name=k.." Color",
		Color=COLORS[k],
		Callback=function(c) COLORS[k]=c end
	})
end

--==============================
-- Drawing
--==============================
local drawings = {}

local function NewLine()
	local l = Drawing.new("Line")
	l.Thickness = 1
	l.Visible = false
	return l
end

local function NewBox()
	local s = Drawing.new("Square")
	s.Filled = false
	s.Visible = false
	s.Thickness = 1
	return s
end

--==============================
-- FOV Circle
--==============================
local FOV = Drawing.new("Circle")
FOV.Filled = false
FOV.Thickness = 1

--==============================
-- Target Finder
--==============================
local function GetClosest()
	local closest,dist=nil,AIM_DISTANCE
	for _,p in ipairs(Players:GetPlayers()) do
		if p~=LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
			if TEAM_CHECK and p.Team==LocalPlayer.Team then continue end
			local h=p.Character:FindFirstChild("Head")
			local hrp=p.Character.HumanoidRootPart
			local pos=h and h.Position or hrp.Position
			local d=(Camera.CFrame.Position-pos).Magnitude
			if d<dist then
				dist=d
				closest=pos
			end
		end
	end
	return closest
end

--==============================
-- Main Loop
--==============================
local acc=0
RunService.RenderStepped:Connect(function(dt)
	acc+=dt
	if acc<UPDATE_RATE then return end
	acc=0

	-- FOV
	FOV.Visible=FOV_ENABLED
	FOV.Radius=FOV_RADIUS
	FOV.Color=COLORS.FOV
	FOV.Position=Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y/2)

	-- Aim
	if AIM then
		local t=GetClosest()
		if t then
			local cf=CFrame.new(Camera.CFrame.Position,t)
			Camera.CFrame=Camera.CFrame:Lerp(cf,SMOOTH)
		end
	end
end)

--==============================
-- F Toggle
--==============================
UIS.InputBegan:Connect(function(i,gp)
	if gp then return end
	if i.KeyCode==Enum.KeyCode.F then
		AIM=not AIM
	end
end)
