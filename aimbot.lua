-- ========================

-- Rayfield（ここから下は許可されたマップでのみ実行）
--==============================
-- PlaceId 制限（必要なら）
--==============================
-- local ALLOWED_PLACE_ID = 1234567890
-- if game.PlaceId ~= ALLOWED_PLACE_ID then return end

--==============================
-- Rayfield
--==============================
--================================
-- Rayfield
--================================
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
	Name = "Aim + ESP | Final",
	LoadingTitle = "Loading",
	LoadingSubtitle = "Optimized Build"
})

local MainTab = Window:CreateTab("Main", 4483362458)
local ESPTab  = Window:CreateTab("ESP", 4483362458)

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
local PREDICTION = false
local SHOW_FOV = false
local TEAM_CHECK = false

local MAX_DISTANCE = 150
local FOV_RADIUS = 200
local SMOOTHNESS = 0.12
local PRED_STRENGTH = 0.25

local ESP_HEAD, ESP_BODY, ESP_SKELETON, ESP_BOX = false,false,false,false
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
-- UI (Main)
--================================
local AimToggle = MainTab:CreateToggle({
	Name = "Aim Assist",
	Callback = function(v) AIM_ENABLED = v end
})

MainTab:CreateToggle({
	Name = "Prediction Aim",
	Callback = function(v) PREDICTION = v end
})

MainTab:CreateToggle({
	Name = "Team Check",
	Callback = function(v) TEAM_CHECK = v end
})

MainTab:CreateToggle({
	Name = "Show FOV",
	Callback = function(v) SHOW_FOV = v end
})

MainTab:CreateSlider({
	Name = "FOV Size",
	Range = {50,500},
	Increment = 10,
	CurrentValue = FOV_RADIUS,
	Callback = function(v)
		FOV_RADIUS = v
		FOVCircle.Radius = v
	end
})

MainTab:CreateSlider({
	Name = "Aim Distance",
	Range = {50,500},
	Increment = 10,
	CurrentValue = MAX_DISTANCE,
	Callback = function(v)
		MAX_DISTANCE = v
	end
})

MainTab:CreateColorPicker({
	Name = "FOV Color",
	Color = COLORS.FOV,
	Callback = function(c)
		COLORS.FOV = c
		FOVCircle.Color = c
	end
})

--================================
-- UI (ESP)
--================================
ESPTab:CreateToggle({Name="Head Line ESP", Callback=function(v) ESP_HEAD=v end})
ESPTab:CreateToggle({Name="Body Line ESP", Callback=function(v) ESP_BODY=v end})
ESPTab:CreateToggle({Name="Skeleton ESP", Callback=function(v) ESP_SKELETON=v end})
ESPTab:CreateToggle({Name="2D Box ESP", Callback=function(v) ESP_BOX=v end})

for name,key in pairs({Head="Head",Body="Body",Skeleton="Skeleton",Box="Box"}) do
	ESPTab:CreateColorPicker({
		Name = key.." Color",
		Color = COLORS[key],
		Callback = function(c) COLORS[key] = c end
	})
end

--================================
-- F Key
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
-- Drawing Utils
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
-- FOV Circle
--================================
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1.5
FOVCircle.Filled = false
FOVCircle.Radius = FOV_RADIUS
FOVCircle.Color = COLORS.FOV

--================================
-- Aim Target
--================================
local function getTarget()
	local best,score=nil,math.huge
	for _,p in ipairs(Players:GetPlayers()) do
		if p~=LocalPlayer and isEnemy(p) then
			local c=p.Character
			local h=c and c:FindFirstChild("Head")
			local hum=c and c:FindFirstChildOfClass("Humanoid")
			if h and hum and hum.Health>0 then
				local dist=(Camera.CFrame.Position-h.Position).Magnitude
				if dist<=MAX_DISTANCE then
					local sp,on=Camera:WorldToViewportPoint(h.Position)
					if on then
						local d=(Vector2.new(sp.X,sp.Y)-UserInputService:GetMouseLocation()).Magnitude
						if d<FOV_RADIUS and d<score then
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

--================================
-- Skeleton Bones
--================================
local bones={
	{"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
	{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},
	{"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},
	{"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},
	{"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"}
}

--================================
-- ESP Loop (0.03)
--================================
task.spawn(function()
	while true do
		used={}
		for _,p in ipairs(Players:GetPlayers()) do
			if p~=LocalPlayer and isEnemy(p) then
				local c=p.Character
				local h=c and c:FindFirstChild("Head")
				local hrp=c and c:FindFirstChild("HumanoidRootPart")
				if ESP_HEAD and h then
					local s,on=Camera:WorldToViewportPoint(h.Position)
					if on then
						local l=getDraw(p,"H")
						l.From=Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y)
						l.To=Vector2.new(s.X,s.Y)
						l.Color=COLORS.Head
						l.Visible=true
					end
				end
				if ESP_BODY and hrp then
					local s,on=Camera:WorldToViewportPoint(hrp.Position)
					if on then
						local l=getDraw(p,"B")
						l.From=Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y)
						l.To=Vector2.new(s.X,s.Y)
						l.Color=COLORS.Body
						l.Visible=true
					end
				end
				if ESP_SKELETON and c then
					for _,b in ipairs(bones) do
						local a=c:FindFirstChild(b[1])
						local d=c:FindFirstChild(b[2])
						if a and d then
							local sa,oa=Camera:WorldToViewportPoint(a.Position)
							local sb,ob=Camera:WorldToViewportPoint(d.Position)
							if oa and ob then
								local l=getDraw(p,"S"..b[1]..b[2])
								l.From=Vector2.new(sa.X,sa.Y)
								l.To=Vector2.new(sb.X,sb.Y)
								l.Color=COLORS.Skeleton
								l.Visible=true
							end
						end
					end
				end
				if ESP_BOX and h and hrp then
					local top,on1=Camera:WorldToViewportPoint(h.Position+Vector3.new(0,0.5,0))
					local bot,on2=Camera:WorldToViewportPoint(hrp.Position-Vector3.new(0,3,0))
					if on1 and on2 then
						local hgt=math.abs(bot.Y-top.Y)
						local w=hgt/2
						local pts={
							{top.X-w/2,top.Y,top.X+w/2,top.Y},
							{top.X+w/2,top.Y,top.X+w/2,bot.Y},
							{top.X+w/2,bot.Y,top.X-w/2,bot.Y},
							{top.X-w/2,bot.Y,top.X-w/2,top.Y}
						}
						for i,v in ipairs(pts) do
							local l=getDraw(p,"BX"..i)
							l.From=Vector2.new(v[1],v[2])
							l.To=Vector2.new(v[3],v[4])
							l.Color=COLORS.Box
							l.Visible=true
						end
					end
				end
			end
		end
		for p,t in pairs(drawings) do
			for k,l in pairs(t) do
				if not (used[p] and used[p][k]) then
					l.Visible=false
				end
			end
		end
		task.wait(ESP_INTERVAL)
	end
end)

--================================
-- Aim Loop
--================================
RunService.RenderStepped:Connect(function()
	FOVCircle.Visible=SHOW_FOV
	FOVCircle.Position=UserInputService:GetMouseLocation()
	FOVCircle.Color=COLORS.FOV

	if AIM_ENABLED then
		local t=getTarget()
		if t then
			local pos=t.Position
			if PREDICTION then
				local hrp=t.Parent:FindFirstChild("HumanoidRootPart")
				if hrp then
					local v=hrp.AssemblyLinearVelocity
					pos+=Vector3.new(v.X,0,v.Z)*PRED_STRENGTH
				end
			end
			Camera.CFrame=Camera.CFrame:Lerp(
				CFrame.new(Camera.CFrame.Position,pos),
				SMOOTHNESS
			)
		end
	end
end)
