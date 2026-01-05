--================================
-- Rayfield
--================================
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
	Name = "Aim + ESP | R15 & R6 FINAL",
	LoadingTitle = "Loading",
	LoadingSubtitle = "Optimized + FOV Control"
})

local MainTab   = Window:CreateTab("Main", 4483362458)
local ESPTab    = Window:CreateTab("ESP (R15)", 4483362458)
local ESPR6Tab  = Window:CreateTab("ESP (R6)", 4483362458)
local AimR6Tab  = Window:CreateTab("AimR6", 4483362458)

--================================
-- Services
--================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

--================================
-- States
--================================
local AIM_ENABLED = false
local AIM_R6 = false
local PREDICTION = false
local SHOW_FOV = false
local TEAM_CHECK = false

local MAX_DISTANCE = 150
local FOV_RADIUS = 200
local SMOOTHNESS = 0.12
local PRED_STRENGTH = 0.25
local R6_TARGET_PART = "Torso"

-- Camera FOV
local CAMERA_FOV = math.clamp(Camera.FieldOfView, 20, 120)

-- ESP
local ESP_HEAD, ESP_BODY, ESP_SKELETON, ESP_BOX = false,false,false,false
local R6_HEAD, R6_BODY, R6_SKELETON, R6_BOX = false,false,false,false
local ESP_INTERVAL = 0.03

--================================
-- Colors
--================================
local COLORS = {
	Head = Color3.fromRGB(255,0,0),
	Body = Color3.fromRGB(255,80,80),
	Skeleton = Color3.fromRGB(0,255,255),
	Box = Color3.fromRGB(255,255,0),
	FOV = Color3.fromRGB(255,0,0)
}

--================================
-- UI Main
--================================
local AimToggle = MainTab:CreateToggle({
	Name = "Aim Assist (R15)",
	Callback = function(v) AIM_ENABLED = v end
})

MainTab:CreateToggle({Name="Prediction Aim", Callback=function(v) PREDICTION=v end})
MainTab:CreateToggle({Name="Team Check", Callback=function(v) TEAM_CHECK=v end})
MainTab:CreateToggle({Name="Show Aim FOV Circle", Callback=function(v) SHOW_FOV=v end})

MainTab:CreateSlider({
	Name="Aim FOV Radius",
	Range={50,500},
	Increment=10,
	CurrentValue=FOV_RADIUS,
	Callback=function(v)
		FOV_RADIUS=v
		FOVCircle.Radius=v
	end
})

MainTab:CreateSlider({
	Name="Aim Distance",
	Range={50,500},
	Increment=10,
	CurrentValue=MAX_DISTANCE,
	Callback=function(v) MAX_DISTANCE=v end
})

-- 🎥 Camera FOV Slider（今回の追加）
MainTab:CreateSlider({
	Name = "Camera FOV (視点)",
	Range = {20, 120},
	Increment = 1,
	CurrentValue = CAMERA_FOV,
	Callback = function(v)
		CAMERA_FOV = v
		Camera.FieldOfView = v
	end
})

MainTab:CreateColorPicker({
	Name="Aim FOV Color",
	Color=COLORS.FOV,
	Callback=function(c)
		COLORS.FOV=c
		FOVCircle.Color=c
	end
})

--================================
-- UI ESP R15
--================================
ESPTab:CreateToggle({Name="Head Line ESP", Callback=function(v) ESP_HEAD=v end})
ESPTab:CreateToggle({Name="Body Line ESP", Callback=function(v) ESP_BODY=v end})
ESPTab:CreateToggle({Name="Skeleton ESP", Callback=function(v) ESP_SKELETON=v end})
ESPTab:CreateToggle({Name="2D Box ESP", Callback=function(v) ESP_BOX=v end})

--================================
-- UI ESP R6
--================================
ESPR6Tab:CreateToggle({Name="Head Line ESP (R6)", Callback=function(v) R6_HEAD=v end})
ESPR6Tab:CreateToggle({Name="Body Line ESP (R6)", Callback=function(v) R6_BODY=v end})
ESPR6Tab:CreateToggle({Name="Skeleton ESP (R6)", Callback=function(v) R6_SKELETON=v end})
ESPR6Tab:CreateToggle({Name="2D Box ESP (R6)", Callback=function(v) R6_BOX=v end})

--================================
-- UI Aim R6
--================================
AimR6Tab:CreateToggle({
	Name="Enable Aim R6",
	Callback=function(v) AIM_R6=v end
})

AimR6Tab:CreateDropdown({
	Name="R6 Target Part",
	Options={"Head","Torso"},
	CurrentOption="Torso",
	Callback=function(v) R6_TARGET_PART=v end
})

--================================
-- Shared Color Pickers
--================================
for _,k in ipairs({"Head","Body","Skeleton","Box"}) do
	ESPTab:CreateColorPicker({
		Name=k.." Color",
		Color=COLORS[k],
		Callback=function(c) COLORS[k]=c end
	})
end

--================================
-- F Key Toggle
--================================
UserInputService.InputBegan:Connect(function(i,g)
	if g then return end
	if i.KeyCode == Enum.KeyCode.F then
		AIM_ENABLED = not AIM_ENABLED
		AimToggle:Set(AIM_ENABLED)
	end
end)

--================================
-- Team Check
--================================
local function isEnemy(p)
	if not TEAM_CHECK then return true end
	return p.Team ~= LocalPlayer.Team
end

--================================
-- Drawing Cache
--================================
local drawings, used = {}, {}

local function getDraw(p,k)
	drawings[p] = drawings[p] or {}
	if not drawings[p][k] then
		local l = Drawing.new("Line")
		l.Thickness = 1.5
		l.Transparency = 1
		drawings[p][k] = l
	end
	used[p] = used[p] or {}
	used[p][k] = true
	return drawings[p][k]
end

--================================
-- FOV Circle (Aim)
--================================
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1.5
FOVCircle.Filled = false
FOVCircle.Radius = FOV_RADIUS
FOVCircle.Color = COLORS.FOV

--================================
-- Target Functions
--================================
local function getTargetR15()
	local best,score=nil,math.huge
	for _,p in ipairs(Players:GetPlayers()) do
		if p~=LocalPlayer and isEnemy(p) then
			local c=p.Character
			local h=c and c:FindFirstChild("Head")
			local hum=c and c:FindFirstChildOfClass("Humanoid")
			if h and hum and hum.Health>0 and hum.RigType==Enum.HumanoidRigType.R15 then
				local dist=(Camera.CFrame.Position-h.Position).Magnitude
				if dist<=MAX_DISTANCE then
					local sp,on=Camera:WorldToViewportPoint(h.Position)
					if on then
						local d=(Vector2.new(sp.X,sp.Y)-UserInputService:GetMouseLocation()).Magnitude
						if d<=FOV_RADIUS and d<score then
							score=d
							best=h
						end
					end
				end
			end
		end
	end
	return best
end

local function getTargetR6()
	local best,score=nil,math.huge
	for _,p in ipairs(Players:GetPlayers()) do
		if p~=LocalPlayer and isEnemy(p) then
			local c=p.Character
			local hum=c and c:FindFirstChildOfClass("Humanoid")
			if hum and hum.Health>0 and hum.RigType==Enum.HumanoidRigType.R6 then
				local part=c:FindFirstChild(R6_TARGET_PART)
				if part then
					local dist=(Camera.CFrame.Position-part.Position).Magnitude
					if dist<=MAX_DISTANCE then
						local sp,on=Camera:WorldToViewportPoint(part.Position)
						if on then
							local d=(Vector2.new(sp.X,sp.Y)-UserInputService:GetMouseLocation()).Magnitude
							if d<=FOV_RADIUS and d<score then
								score=d
								best=part
							end
						end
					end
				end
			end
		end
	end
	return best
end

--================================
-- Aim Loop
--================================
RunService.RenderStepped:Connect(function()
	-- Camera FOV常時反映
	if Camera.FieldOfView ~= CAMERA_FOV then
		Camera.FieldOfView = CAMERA_FOV
	end

	-- Aim FOV Circle
	FOVCircle.Visible = SHOW_FOV
	FOVCircle.Position = UserInputService:GetMouseLocation()
	FOVCircle.Color = COLORS.FOV

	if not AIM_ENABLED then return end

	-- R15優先
	local t = getTargetR15()
	if t then
		local pos=t.Position
		if PREDICTION then
			local hrp=t.Parent:FindFirstChild("HumanoidRootPart")
			if hrp then
				local v=hrp.AssemblyLinearVelocity
				pos+=Vector3.new(v.X,0,v.Z)*PRED_STRENGTH
			end
		end
		Camera.CFrame = Camera.CFrame:Lerp(
			CFrame.new(Camera.CFrame.Position,pos),
			SMOOTHNESS
		)
		return
	end

	-- R6 Aim
	if AIM_R6 then
		local r6t=getTargetR6()
		if r6t then
			Camera.CFrame = Camera.CFrame:Lerp(
				CFrame.new(Camera.CFrame.Position,r6t.Position),
				SMOOTHNESS
			)
		end
	end
end)
