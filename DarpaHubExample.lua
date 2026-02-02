-- ============================================================
--   DARPA HUB FOR BLOXSTRIKE (FIXED & IMPROVED)
--   Aimbot Avançado, ESP Completo e Fixes de Interface
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Load Library
local DarpaHub = loadstring(game:HttpGet("https://raw.githubusercontent.com/oogaboogaman1231/DARPA-HUB/refs/heads/main/DarpaHubLib.lua"))()

-- ──────────────────────────────────────────────────────────
--  AIMBOT SETTINGS
-- ──────────────────────────────────────────────────────────
local Aimbot = {
	Enabled = false,
	WallCheck = true,
	ShowFOV = false,
	FOV = 100,
	Smoothness = 5,
	Key = Enum.UserInputType.MouseButton2, -- Padrão (Right Click)
	TargetPart = "Head",
	CurrentTarget = nil
}

-- FOV Circle Drawing
local FOVCircle = Drawing.new("Circle")
FOVCircle.Color = Color3.fromRGB(0, 210, 255)
FOVCircle.Thickness = 1
FOVCircle.NumSides = 60
FOVCircle.Radius = Aimbot.FOV
FOVCircle.Visible = false
FOVCircle.Filled = false
FOVCircle.Transparency = 1

-- ──────────────────────────────────────────────────────────
--  UI SETUP
-- ──────────────────────────────────────────────────────────
local Window = DarpaHub:CreateWindow("Bloxstrike Hub v2.0")

local CombatTab = Window:AddTab("Combat")
local VisualTab = Window:AddTab("Visuals")
local PlayerTab = Window:AddTab("Players")
local MiscTab = Window:AddTab("Misc")

-- ──────────────────────────────────────────────────────────
--  COMBAT TAB
-- ──────────────────────────────────────────────────────────

CombatTab:AddToggle("Enable Aimbot", false, function(v)
	Aimbot.Enabled = v
end)

CombatTab:AddDropdown("Aim Key", {"Right Mouse", "Left Mouse", "E", "Q", "Left Alt"}, "Right Mouse", function(selected)
	if selected == "Right Mouse" then Aimbot.Key = Enum.UserInputType.MouseButton2
	elseif selected == "Left Mouse" then Aimbot.Key = Enum.UserInputType.MouseButton1
	elseif selected == "E" then Aimbot.Key = Enum.KeyCode.E
	elseif selected == "Q" then Aimbot.Key = Enum.KeyCode.Q
	elseif selected == "Left Alt" then Aimbot.Key = Enum.KeyCode.LeftAlt
	end
end)

CombatTab:AddToggle("Wall Check", true, function(v)
	Aimbot.WallCheck = v
end)

CombatTab:AddSlider("Aimbot FOV", 10, 400, 100, function(v)
	Aimbot.FOV = v
	FOVCircle.Radius = v
end)

CombatTab:AddToggle("Show FOV Circle", false, function(v)
	Aimbot.ShowFOV = v
	FOVCircle.Visible = v
end)

CombatTab:AddSlider("Smoothness", 1, 20, 5, function(v)
	Aimbot.Smoothness = v
end)

CombatTab:AddDropdown("Target Part", {"Head", "Torso"}, "Head", function(v)
	Aimbot.TargetPart = v
end)

-- ──────────────────────────────────────────────────────────
--  VISUALS TAB
-- ──────────────────────────────────────────────────────────

VisualTab:AddToggle("Master ESP", false, function(v)
	DarpaHub.ESP:Toggle(v)
end)

VisualTab:AddToggle("Boxes", true, function(v)
	DarpaHub.ESP.Settings.Box = v
end)

VisualTab:AddToggle("Health Bar", true, function(v)
	DarpaHub.ESP.Settings.HealthBar = v
end)

VisualTab:AddToggle("Tracers", false, function(v)
	DarpaHub.ESP.Settings.Tracers = v
end)

VisualTab:AddToggle("Names", true, function(v)
	DarpaHub.ESP.Settings.Name = v
end)

VisualTab:AddToggle("Distance", true, function(v)
	DarpaHub.ESP.Settings.Distance = v
end)

VisualTab:AddToggle("Team Check", true, function(v)
	DarpaHub.ESP.Settings.TeamCheck = v
end)

VisualTab:AddSlider("Camera FOV", 70, 120, 70, function(v)
	Camera.FieldOfView = v
end)

-- ──────────────────────────────────────────────────────────
--  PLAYER TAB (Fixed Dropdown)
-- ──────────────────────────────────────────────────────────

local playerList = {}
local selectedPlayerName = nil

local function RefreshPlayerList()
	playerList = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= LocalPlayer then
			table.insert(playerList, p.Name)
		end
	end
	if #playerList == 0 then table.insert(playerList, "No Players") end
	return playerList
end

local PlayerDropdown = PlayerTab:AddDropdown("Select Player", RefreshPlayerList(), "None", function(name)
	selectedPlayerName = name
end)

PlayerTab:AddButton("Refresh List", function()
	PlayerDropdown.Refresh(RefreshPlayerList())
end)

PlayerTab:AddButton("Teleport to Player", function()
	if selectedPlayerName and selectedPlayerName ~= "No Players" then
		local target = Players:FindFirstChild(selectedPlayerName)
		if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
			LocalPlayer.Character.HumanoidRootPart.CFrame = target.Character.HumanoidRootPart.CFrame
		end
	end
end)

-- ──────────────────────────────────────────────────────────
--  MISC TAB
-- ──────────────────────────────────────────────────────────

MiscTab:AddButton("Reset Character", function()
	if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
		LocalPlayer.Character.Humanoid.Health = 0
	end
end)

MiscTab:AddButton("Fullbright", function()
	game.Lighting.Brightness = 2
	game.Lighting.ClockTime = 14
	game.Lighting.FogEnd = 100000
	game.Lighting.GlobalShadows = false
end)

MiscTab:AddButton("Unload UI", function()
	FOVCircle:Remove()
	DarpaHub.ESP:Toggle(false)
	Window.Screen:Destroy()
end)

-- ──────────────────────────────────────────────────────────
--  AIMBOT LOGIC
-- ──────────────────────────────────────────────────────────

local function IsVisible(targetPart)
	if not Aimbot.WallCheck then return true end
	local origin = Camera.CFrame.Position
	local direction = (targetPart.Position - origin).Unit * (targetPart.Position - origin).Magnitude
	
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
	params.FilterType = Enum.RaycastFilterType.Exclude
	
	local result = Workspace:Raycast(origin, direction, params)
	return result == nil or result.Instance:IsDescendantOf(targetPart.Parent)
end

local function GetClosestPlayer()
	local closest = nil
	local shortestDist = Aimbot.FOV
	local mousePos = UserInputService:GetMouseLocation()

	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
			-- Team Check
			if player.Team == LocalPlayer.Team and #Players:GetTeams() > 1 then
				continue 
			end

			local part = player.Character:FindFirstChild(Aimbot.TargetPart)
			if part then
				local pos, onScreen = Camera:WorldToViewportPoint(part.Position)
				if onScreen then
					local dist = (Vector2.new(pos.X, pos.Y) - mousePos).Magnitude
					if dist < shortestDist then
						if IsVisible(part) then
							shortestDist = dist
							closest = part
						end
					end
				end
			end
		end
	end
	return closest
end

-- Render Loop for FOV Circle
RunService.RenderStepped:Connect(function()
	FOVCircle.Position = UserInputService:GetMouseLocation()
	
	if Aimbot.Enabled and Aimbot.CurrentTarget then
		-- Aim Logic
		local currentPos = Camera.CFrame.Position
		local targetPos = Aimbot.CurrentTarget.Position
		
		-- Smoothness calculation
		local targetCFrame = CFrame.new(currentPos, targetPos)
		Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, 1 / Aimbot.Smoothness)
	end
end)

-- Input Handling
UserInputService.InputBegan:Connect(function(input)
	if not Aimbot.Enabled then return end
	if input.UserInputType == Aimbot.Key or input.KeyCode == Aimbot.Key then
		local target = GetClosestPlayer()
		if target then
			Aimbot.CurrentTarget = target
		end
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Aimbot.Key or input.KeyCode == Aimbot.Key then
		Aimbot.CurrentTarget = nil
	end
end)

print("DarpaHub Bloxstrike Loaded!")