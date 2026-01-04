-- ===== PlaceId Check =====
local ALLOWED_PLACE_ID = 14518422161 -- ← 動かしたいマップの PlaceId

if game.PlaceId ~= ALLOWED_PLACE_ID then
	warn("This script is disabled on this map.")
	return
end
-- ========================

-- Rayfield（ここから下は許可されたマップでのみ実行）
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

local Window = Rayfield:CreateWindow({
	Name = "Aim + ESP (Final Stable)",
	LoadingTitle = "Loading...",
	LoadingSubtitle = "Complete Build"
})

local MainTab = Window:CreateTab("Main", 4483362458)
local ESPTab  = Window:CreateTab("ESP", 4483362458)

--==================================================
-- Services
--==================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

--==================================================
-- States
--==================================================
-- Aim
local AIM_ENABLED = false
local TEAM_CHECK = true
local PREDICTION = false
local SHOW_FOV = false

local MAX_DISTANCE = 150
local FOV_RADIUS = 200
local SMOOTHNESS = 0.12
local PRED_STRENGTH = 0.25

-- ESP
local ESP_HEAD = false
local ESP_BODY = false
local ESP_SKELETON = false
local ESP_BOX = false

local ESP_INTERVAL = 0.03
local TARGET_PART = "Head"

--==================================================
-- UI
--==================================================
local AimToggle = MainTab:CreateToggle({
	Name = "Aim Assist",
	Callback = function(v) AIM_ENABLED = v end
})

MainTab:CreateToggle({
	Name = "Team Check",
	CurrentValue = TEAM_CHECK,
	Callback = function(v) TEAM_CHECK = v end
})

MainTab:CreateToggle({
	Name = "Prediction Aim",
	Callback = function(v) PREDICTION = v end
})

MainTab:CreateToggle({
	Name = "Show FOV",
	Callback = function(v) SHOW_FOV = v end
})

MainTab:CreateSlider({
	Name = "FOV Size",
	Range = {50, 500},
	Increment = 10,
	CurrentValue = FOV_RADIUS,
	Callback = function(v)
		FOV_RADIUS = v
		FOVCircle.Radius = v
	end
})

MainTab:CreateSlider({
	Name = "Aim Distance",
	Range = {50, 500},
	Increment = 10,
	CurrentValue = MAX_DISTANCE,
	Callback = function(v)
		MAX_DISTANCE = v
	end
})

ESPTab:CreateToggle({Name="Head Line ESP", Callback=function(v) ESP_HEAD=v end})
ESPTab:CreateToggle({Name="Body Line ESP", Callback=function(v) ESP_BODY=v end})
ESPTab:CreateToggle({Name="Skeleton ESP", Callback=function(v) ESP_SKELETON=v end})
ESPTab:CreateToggle({Name="2D Box ESP", Callback=function(v) ESP_BOX=v end})

--==================================================
-- F key
--==================================================
UserInputService.InputBegan:Connect(function(i,g)
	if g then return end
	if i.KeyCode == Enum.KeyCode.F then
		AIM_ENABLED = not AIM_ENABLED
		AimToggle:Set(AIM_ENABLED)
	end
end)

--==================================================
-- Drawing Init
--==================================================
pcall(function() Drawing.new("Line") end)

local RED = Color3.fromRGB(255,0,0)
local lines, used = {}, {}

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

--==================================================
-- FOV Circle
--==================================================
local FOVCircle = Drawing.new("Circle")
FOVCircle.Color = RED
FOVCircle.Filled = false
FOVCircle.Thickness = 1.5
FOVCircle.Radius = FOV_RADIUS

--==================================================
-- Utility
--==================================================
local function inFOV(pos)
	local sp,on = Camera:WorldToViewportPoint(pos)
	if not on then return false,1e9 end
	local d = (Vector2.new(sp.X,sp.Y) - UserInputService:GetMouseLocation()).Magnitude
	return d <= FOV_RADIUS, d
end

--==================================================
-- Target Search（安定版）
--==================================================
local function getTarget()
	local best, bestD = nil, math.huge

	for _,p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer and (not TEAM_CHECK or p.Team ~= LocalPlayer.Team) then
			local c = p.Character
			local part = c and c:FindFirstChild(TARGET_PART)
			local hum = c and c:FindFirstChildOfClass("Humanoid")
			if part and hum and hum.Health > 0 then
				local dist = (Camera.CFrame.Position - part.Position).Magnitude
				if dist <= MAX_DISTANCE then
					local inF, d2 = inFOV(part.Position)
					local score = inF and d2 or dist * 2 -- フォールバック
					if score < bestD then
						bestD = score
						best = part
					end
				end
			end
		end
	end
	return best
end

--==================================================
-- Skeleton
--==================================================
local bones = {
	{"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
	{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},
	{"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},
	{"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},
	{"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"}
}

--==================================================
-- ESP Loop (0.03s)
--==================================================
task.spawn(function()
	while true do
		used = {}

		for _,p in ipairs(Players:GetPlayers()) do
			if p ~= LocalPlayer then
				local c = p.Character
				local h = c and c:FindFirstChild("Head")
				local hrp = c and c:FindFirstChild("HumanoidRootPart")

				if ESP_HEAD and h then
					local s,on = Camera:WorldToViewportPoint(h.Position)
					if on then
						local l = getLine(p,"H")
						l.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
						l.To = Vector2.new(s.X,s.Y)
						l.Color = RED
						l.Visible = true
					end
				end

				if ESP_BODY and hrp then
					local s,on = Camera:WorldToViewportPoint(hrp.Position)
					if on then
						local l = getLine(p,"B")
						l.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
						l.To = Vector2.new(s.X,s.Y)
						l.Color = RED
						l.Visible = true
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

				if ESP_BOX and h and hrp then
					local hp,on1=Camera:WorldToViewportPoint(h.Position+Vector3.new(0,0.5,0))
					local fp,on2=Camera:WorldToViewportPoint(hrp.Position-Vector3.new(0,3,0))
					if on1 and on2 then
						local hgt=math.abs(fp.Y-hp.Y)
						local w=hgt/2
						local pts={
							{hp.X-w/2,hp.Y,hp.X+w/2,hp.Y},
							{hp.X+w/2,hp.Y,hp.X+w/2,fp.Y},
							{hp.X+w/2,fp.Y,hp.X-w/2,fp.Y},
							{hp.X-w/2,fp.Y,hp.X-w/2,hp.Y}
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

--==================================================
-- Aim Loop
--==================================================
RunService.RenderStepped:Connect(function()
	FOVCircle.Visible = SHOW_FOV
	FOVCircle.Position = UserInputService:GetMouseLocation()

	if AIM_ENABLED then
		local t = getTarget()
		if t then
			local pos = t.Position
			if PREDICTION then
				local hrp = t.Parent:FindFirstChild("HumanoidRootPart")
				if hrp then
					local v = hrp.AssemblyLinearVelocity
					pos += Vector3.new(v.X,0,v.Z) * PRED_STRENGTH
				end
			end
			Camera.CFrame = Camera.CFrame:Lerp(
				CFrame.new(Camera.CFrame.Position, pos),
				SMOOTHNESS
			)
		end
	end
end)
