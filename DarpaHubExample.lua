-- ============================================================
--   DARPA HUB EXAMPLE USAGE
--   Shows how to use the DarpaHub library in your scripts
-- ============================================================

-- Load the library (in production, load from your URL)
local DarpaHub = loadstring(game:HttpGet("https://raw.githubusercontent.com/oogaboogaman1231/DARPA-HUB/refs/heads/main/DarpaHubLib.lua"))()

-- ──────────────────────────────────────────────────────────
--  OPTIONAL: SHOW LOADER
-- ──────────────────────────────────────────────────────────
DarpaHub:CreateLoader()
DarpaHub:UpdateLoader(20, "Loading library...")
task.wait(0.5)
DarpaHub:UpdateLoader(50, "Initializing UI...")
task.wait(0.5)
DarpaHub:UpdateLoader(80, "Almost ready...")
task.wait(0.5)
DarpaHub:UpdateLoader(100, "Done!")
task.wait(0.3)
DarpaHub:DestroyLoader()

-- ──────────────────────────────────────────────────────────
--  CREATE WINDOW
-- ──────────────────────────────────────────────────────────
local Window = DarpaHub:CreateWindow("My Hub v1.0")

-- ──────────────────────────────────────────────────────────
--  CREATE TABS
-- ──────────────────────────────────────────────────────────
local CombatTab = Window:AddTab("Combat")
local PlayerTab = Window:AddTab("Player")
local VisualTab = Window:AddTab("Visual")
local MiscTab = Window:AddTab("Misc")

-- ──────────────────────────────────────────────────────────
--  COMBAT TAB ELEMENTS
-- ──────────────────────────────────────────────────────────

-- Simple toggle
CombatTab:AddToggle("Auto Farm", false, function(enabled)
	print("Auto Farm:", enabled)
	-- Add your auto-farm logic here
	if enabled then
		-- Start farming
	else
		-- Stop farming
	end
end)

-- Toggle with reference to control it later
local AimbotToggle = CombatTab:AddToggle("Aimbot", false, function(enabled)
	print("Aimbot:", enabled)
	-- Add your aimbot logic here
end)

-- Slider for FOV
CombatTab:AddSlider("Aimbot FOV", 10, 500, 100, function(value)
	print("FOV:", value)
	-- Update your FOV circle size
end)

-- Dropdown for target part
CombatTab:AddDropdown("Target Part", {"Head", "Torso", "HumanoidRootPart"}, "Head", function(selected)
	print("Target part:", selected)
	-- Update your aim target
end)

-- ──────────────────────────────────────────────────────────
--  PLAYER TAB ELEMENTS
-- ──────────────────────────────────────────────────────────

-- Walkspeed slider
PlayerTab:AddSlider("WalkSpeed", 16, 200, 16, function(speed)
	DarpaHub.Utils:SetWalkSpeed(speed)
end)

-- JumpPower slider
PlayerTab:AddSlider("JumpPower", 50, 300, 50, function(power)
	DarpaHub.Utils:SetJumpPower(power)
end)

-- Teleport buttons using dropdown
local playerList = {}
for _, player in ipairs(DarpaHub.Utils:GetPlayers()) do
	table.insert(playerList, player.Name)
end

if #playerList > 0 then
	local selectedPlayer = playerList[1]
	
	PlayerTab:AddDropdown("Select Player", playerList, selectedPlayer, function(name)
		selectedPlayer = name
	end)
	
	PlayerTab:AddButton("Teleport to Player", function()
		local targetPlayer = game.Players:FindFirstChild(selectedPlayer)
		if targetPlayer then
			local root = DarpaHub.Utils:GetRoot(targetPlayer)
			if root then
				DarpaHub.Utils:Teleport(root.CFrame)
				print("Teleported to", selectedPlayer)
			end
		end
	end)
else
	PlayerTab:AddLabel("No other players in game")
end

-- Get closest player button
PlayerTab:AddButton("Show Closest Player", function()
	local closest, distance = DarpaHub.Utils:GetClosestPlayer()
	if closest then
		print("Closest player:", closest.Name, "at", math.floor(distance), "studs")
	else
		print("No players found")
	end
end)

-- ──────────────────────────────────────────────────────────
--  VISUAL TAB ELEMENTS
-- ──────────────────────────────────────────────────────────

-- ESP Toggle (only works if executor supports Drawing API)
VisualTab:AddToggle("ESP Boxes", false, function(enabled)
	DarpaHub.ESP:Toggle(enabled)
end)

VisualTab:AddLabel("Note: ESP requires Drawing API support")

-- Fullbright
VisualTab:AddToggle("Fullbright", false, function(enabled)
	if enabled then
		game.Lighting.Brightness = 2
		game.Lighting.ClockTime = 14
		game.Lighting.FogEnd = 100000
		game.Lighting.GlobalShadows = false
		game.Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
	else
		game.Lighting.Brightness = 1
		game.Lighting.ClockTime = 12
		game.Lighting.FogEnd = 100000
		game.Lighting.GlobalShadows = true
		game.Lighting.OutdoorAmbient = Color3.fromRGB(70, 70, 70)
	end
end)

-- FOV Changer
VisualTab:AddSlider("Field of View", 70, 120, 70, function(fov)
	workspace.CurrentCamera.FieldOfView = fov
end)

-- ──────────────────────────────────────────────────────────
--  MISC TAB ELEMENTS
-- ──────────────────────────────────────────────────────────

-- Reset button
MiscTab:AddButton("Reset Character", function()
	if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
		LocalPlayer.Character:FindFirstChildOfClass("Humanoid").Health = 0
	end
end)

-- Rejoin button
MiscTab:AddButton("Rejoin Server", function()
	game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
end)

-- Server hop button
MiscTab:AddButton("Server Hop", function()
	local HttpService = game:GetService("HttpService")
	local TeleportService = game:GetService("TeleportService")
	
	local servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
	
	for _, server in ipairs(servers.data) do
		if server.id ~= game.JobId and server.playing < server.maxPlayers then
			TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer)
			break
		end
	end
end)

-- Destroy UI button
MiscTab:AddButton("Destroy UI", function()
	Window:Destroy()
	-- Clean up ESP if it was enabled
	DarpaHub.ESP:Cleanup()
	print("UI destroyed")
end)

-- Info label
MiscTab:AddLabel("Hub loaded successfully!")
MiscTab:AddLabel("Created with DarpaHub Library")

-- ──────────────────────────────────────────────────────────
--  PROGRAMMATIC CONTROL EXAMPLES
-- ──────────────────────────────────────────────────────────

-- You can control elements programmatically:
-- AimbotToggle:Set(true)   -- Enable aimbot from code
-- AimbotToggle:Get()       -- Get current state

-- Example: Auto-enable aimbot after 5 seconds
task.spawn(function()
	task.wait(5)
	print("Auto-enabling aimbot...")
	-- AimbotToggle:Set(true)  -- Uncomment to actually enable it
end)

print("[DARPA HUB] Example script loaded successfully!")
