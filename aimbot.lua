--==============================
-- Rayfield
--==============================
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
	Name = "Aim + ESP (Final)",
	LoadingTitle = "Loading...",
	LoadingSubtitle = "Stable Build"
})

local MainTab = Window:CreateTab("Main", 4483362458)
local ESPTab  = Window:CreateTab("ESP", 4483362458)

--==============================
-- Services
--==============================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

--==============================
-- States
--==============================
-- Aim
local AIM_ENABLED = false
local TEAM_CHECK = true
local PREDICTION = false
local SHOW_FOV = false
local FOV_RADIUS = 200

-- ESP
local ESP_HEAD = false
local ESP_BODY = false
local ESP_SKELETON = false
local ESP_BOX = false

-- Config
local SMOOTHNESS = 0.12
local MAX_DISTANCE = 150
local TARGET_PART = "Head"
local PRED_STRENGTH = 0.3
local ESP_INTERVAL = 0.03

--==============================
-- UI
--==============================
local AimToggle = MainTab:CreateToggle({
	Name = "Aim Assist",
	CurrentValue = false,
	Callback = function(v) AIM_ENABLED = v end
})

MainTab:CreateToggle({
	Name = "Team Check",
	CurrentValue = TEAM_CHECK,
	Callback = function(v) TEAM_CHECK = v end
})

MainTab:CreateToggle({
	Name = "Prediction Aim",
	CurrentValue = false,
	Callback = function(v) PREDICTION = v end
})

MainTab:CreateToggle({
	Name = "Show FOV",
	CurrentValue = false,
	Callback = function(v) SHOW_FOV = v end
})

MainTab:CreateSlider({
	Name = "FOV Size",
	Range = {50, 500},
	Increment = 10,
	Suffix = "px",
	CurrentValue = FOV_RADIUS,
	Callback = function(v)
		FOV_RADIUS = v
		if FOVCircle then
			FOVCircle.Radius = v
		end
	end
})

ESPTab:CreateToggle({ Name="Head Line ESP", Callback=function(v) ESP_HEAD=v end })
ESPTab:CreateToggle({ Name="Body Line ESP", Callback=function(v) ESP_BODY=v end })
ESPTab:CreateToggle({ Name="Skeleton ESP", Callback=function(v) ESP_SKELETON=v end })
ESPTab:CreateToggle({ Name="2D Box ESP", Callback=function(v) ESP_BOX=v end })

--==============================
-- F Key
--==============================
UserInputService.InputBegan:Connect(function(i,g)
	if g then return end
	if i.KeyCode == Enum.KeyCode.F then
		AIM_ENABLED = not AIM_ENABLED
		AimToggle:Set(AIM_ENABLED)
	end
end)

--==============================
-- Drawing Init
--==============================
local ok = pcall(function() Drawing.new("Line") end)
if not ok then return end

local RED = Color3.fromRGB(255,0,0)
local lines = {}
local used = {}

local function mark(p,k)
	used[p] = used[p] or {}
	used[p][k] = true
end

local function getLine(p,k)
	lines[p] = lines[p] or {}
	if not lines[p][k] then
		local l = Drawing.new("Line")
		l.Thickness = 1.5
		l.Transparency = 1
		lines[p][k] = l
	end
	mark(p,k)
	return lines[p][k]
end

--==============================
-- FOV Circle
--==============================
local FOVCircle = Drawing.new("Circle")
FOVCircle.Filled = false
FOVCircle.Thickness = 1.5
FOVCircle.Color = RED
FOVCircle.Radius = FOV_RADIUS

--==============================
-- Skeleton Pairs
--==============================
local bones = {
	{"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
	{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},
	{"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},
	{"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},
	{"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"}
}

--==============================
-- Utility
--==============================
local function inFOV(pos)
	local s,on = Camera:WorldToViewportPoint(pos)
	if not on then return false,1e9 end
	local d = (Vector2.new(s.X,s.Y)-UserInputService:GetMouseLocation()).Magnitude
	return d<=FOV_RADIUS,d
end

--==============================
-- Aim Target
--==============================
local function getTarget()
	local best,bestD=nil,1e9
	for _,p in ipairs(Players:GetPlayers()) do
		if p~=LocalPlayer and (not TEAM_CHECK or p.Team~=LocalPlayer.Team) then
			local c=p.Character
			local part=c and c:FindFirstChild(TARGET_PART)
			local hum=c and c:FindFirstChildOfClass("Humanoid")
			if part and hum and hum.Health>0 then
				local ok,d=inFOV(part.Position)
				if ok and d<bestD then
					bestD=d
					best=part
				end
			end
		end
	end
	return best
end

--==============================
-- ESP Update (0.03s)
--==============================
task.spawn(function()
	while true do
		used={}
		for _,p in ipairs(Players:GetPlayers()) do
			if p~=LocalPlayer then
				local c=p.Character
				local head=c and c:FindFirstChild("Head")
				local hrp=c and c:FindFirstChild("HumanoidRootPart")

				if ESP_HEAD and head then
					local s,on=Camera:WorldToViewportPoint(head.Position)
					if on then
						local l=getLine(p,"H")
						l.From=Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y)
						l.To=Vector2.new(s.X,s.Y)
						l.Color=RED
						l.Visible=true
					end
				end

				if ESP_BODY and hrp then
					local s,on=Camera:WorldToViewportPoint(hrp.Position)
					if on then
						local l=getLine(p,"B")
						l.From=Vector2.new(Camera.ViewportSize.X/2,Camera.ViewportSize.Y)
						l.To=Vector2.new(s.X,s.Y)
						l.Color=RED
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
								local l=getLine(p,"S"..b[1]..b[2])
								l.From=Vector2.new(sa.X,sa.Y)
								l.To=Vector2.new(sb.X,sb.Y)
								l.Color=RED
								l.Visible=true
							end
						end
					end
				end

				if ESP_BOX and head and hrp then
					local h,on1=Camera:WorldToViewportPoint(head.Position+Vector3.new(0,0.5,0))
					local f,on2=Camera:WorldToViewportPoint(hrp.Position-Vector3.new(0,3,0))
					if on1 and on2 then
						local hgt=math.abs(f.Y-h.Y)
						local w=hgt/2
						local pts={
							{h.X-w/2,h.Y,h.X+w/2,h.Y},
							{h.X+w/2,h.Y,h.X+w/2,f.Y},
							{h.X+w/2,f.Y,h.X-w/2,f.Y},
							{h.X-w/2,f.Y,h.X-w/2,h.Y}
						}
						for i,v in ipairs(pts) do
							local l=getLine(p,"BX"..i)
							l.From=Vector2.new(v[1],v[2])
							l.To=Vector2.new(v[3],v[4])
							l.Color=RED
							l.Visible=true
						end
					end
				end
			end
		end

		for p,t in pairs(lines) do
			for k,l in pairs(t) do
				if not (used[p] and used[p][k]) then
					l.Visible=false
				end
			end
		end
		task.wait(ESP_INTERVAL)
	end
end)

--==============================
-- Aim Loop
--==============================
RunService.RenderStepped:Connect(function()
	FOVCircle.Visible = SHOW_FOV
	FOVCircle.Position = UserInputService:GetMouseLocation()

	if AIM_ENABLED then
		local t=getTarget()
		if t then
			local pos=t.Position
			if PREDICTION then
				local hrp=t.Parent:FindFirstChild("HumanoidRootPart")
				if hrp then
					pos+=Vector3.new(hrp.Velocity.X,0,hrp.Velocity.Z)*PRED_STRENGTH
				end
			end
			Camera.CFrame=Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position,pos),SMOOTHNESS)
		end
	end
end)
