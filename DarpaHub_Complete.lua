--[[
    ╔═══════════════════════════════════════════════════════════╗
    ║         DARPA HUB v7.6 - BLOXSTRIKE EDITION              ║
    ║         Professional Cheat Hub - Fully Optimized          ║
    ║                                                           ║
    ║  Features:                                                ║
    ║  • Advanced Aimbot (FOV, Prediction, Smoothing)           ║
    ║  • Complete ESP (Boxes, Tracers, Names, Health)           ║
    ║  • Wall Hack with Chams (See through walls)               ║
    ║  • Customizable Crosshair                                 ║
    ║  • Advanced Visibility System                             ║
    ║  • Performance Monitor & Optimizer                        ║
    ║  • Modern Premium UI                                      ║
    ║  • Bloxstrike Optimized Settings                          ║
    ║                                                           ║
    ╚═══════════════════════════════════════════════════════════╝
]]

-- Wait for game to load
if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- Load UI Library
local Library
local librarySuccess = pcall(function()
    Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/oogaboogaman1231/DARPA-HUB/refs/heads/main/DarpaHubUI.lua"))()
end)

if not librarySuccess or not Library then
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "DARPA HUB";
        Text = "Failed to load UI library!";
        Duration = 5;
    })
    return
end

-- Load modules with error handling
local AimbotModule, ESPModule

pcall(function()
    AimbotModule = loadstring(game:HttpGet("https://raw.githubusercontent.com/oogaboogaman1231/DARPA-HUB/refs/heads/main/DarpaHub_Aimbot.lua"))()
end)

pcall(function()
    ESPModule = loadstring(game:HttpGet("https://raw.githubusercontent.com/oogaboogaman1231/DARPA-HUB/refs/heads/main/DarpaHub_ESP.lua"))()
end)

-- Initialize modules
if AimbotModule then
    pcall(function()
        AimbotModule:Init()
    end)
end

if ESPModule then
    pcall(function()
        ESPModule:Init()
    end)
end

-- ═══════════════════════════════════════════════════════════
--  BLOXSTRIKE SPECIFIC OPTIMIZATIONS
-- ═══════════════════════════════════════════════════════════
local BloxstrikeConfig = {
    -- Optimized for fast-paced FPS gameplay
    Aimbot = {
        RecommendedFOV = 140,
        RecommendedSmoothing = 0.22,
        RecommendedPrediction = 0.135,
        TargetPart = "Head", -- Headshots are crucial in Bloxstrike
    },
    ESP = {
        RecommendedDistance = 4000,
        UseTeamColors = true,
        BoxType = "2D", -- Better performance
    },
    Performance = {
        RecommendedFPS = 144,
        OptimizeGraphics = true,
    }
}

-- ═══════════════════════════════════════════════════════════
--  CREATE MAIN WINDOW
-- ═══════════════════════════════════════════════════════════
local Window = Library:CreateWindow({
    Title = "DARPA HUB",
    Subtitle = "Bloxstrike Edition v7.6"
})

-- Welcome notification
pcall(function()
    Library.Notify("Welcome!", "DARPA HUB loaded successfully for Bloxstrike", 4, "success")
end)

-- ═══════════════════════════════════════════════════════════
--  TAB: COMBAT (Aimbot & Triggerbot)
-- ═══════════════════════════════════════════════════════════
if AimbotModule then
    local CombatTab = Window:CreateTab("⚔️ Combat", "⚔️")
    
    CombatTab:AddLabel("═══ AIMBOT SETTINGS ═══")
    
    -- Master Enable
    CombatTab:AddToggle("Enable Aimbot", false, function(enabled)
        AimbotModule.Settings.Enabled = enabled
        pcall(function()
            Library.Notify("Aimbot", enabled and "Activated" or "Deactivated", 2, enabled and "success" or "warning")
        end)
    end)
    
    CombatTab:AddSeparator()
    
    -- Safety Checks
    CombatTab:AddLabel("═══ SAFETY CHECKS ═══")
    
    CombotTab:AddToggle("Team Check", true, function(enabled)
        AimbotModule.Settings.TeamCheck = enabled
    end)
    
    CombatTab:AddToggle("Alive Check", true, function(enabled)
        AimbotModule.Settings.AliveCheck = enabled
    end)
    
    CombatTab:AddToggle("Visibility Check", true, function(enabled)
        AimbotModule.Settings.VisibleCheck = enabled
    end)
    
    CombatTab:AddSeparator()
    
    -- Target Settings
    CombatTab:AddLabel("═══ TARGET SETTINGS ═══")
    
    local bodyParts = {"Head", "HumanoidRootPart", "Torso", "UpperTorso", "LowerTorso"}
    CombatTab:AddDropdown("Target Part", bodyParts, "Head", function(selected)
        AimbotModule.Settings.TargetPart = selected
        pcall(function()
            Library.Notify("Target", "Now aiming at: " .. selected, 2)
        end)
    end)
    
    local priorities = {"Distance", "Health", "Crosshair"}
    CombatTab:AddDropdown("Priority Mode", priorities, "Distance", function(selected)
        AimbotModule.Settings.Priority = selected
    end)
    
    CombatTab:AddSeparator()
    
    -- Smoothing & Prediction
    CombatTab:AddLabel("═══ AIMING BEHAVIOR ═══")
    
    -- FIXED: Proper step value for smoothing
    CombatTab:AddSlider("Smoothing", 0, 100, 22, function(value)
        AimbotModule.Settings.Smoothing = value / 100 -- Convert to 0-1 range
    end, 1) -- Step of 1
    
    CombatTab:AddToggle("Enable Prediction", false, function(enabled)
        AimbotModule.Settings.PredictionEnabled = enabled
    end)
    
    -- FIXED: Proper step value for prediction
    CombatTab:AddSlider("Prediction Amount", 0, 50, 13, function(value)
        AimbotModule.Settings.PredictionAmount = value / 100 -- Convert to 0-0.5 range
    end, 1) -- Step of 1
    
    CombatTab:AddSeparator()
    
    -- FOV Settings
    CombatTab:AddLabel("═══ FOV CIRCLE ═══")
    
    CombatTab:AddToggle("Enable FOV", true, function(enabled)
        AimbotModule.FOV.Enabled = enabled
    end)
    
    CombatTab:AddToggle("Show FOV Circle", true, function(enabled)
        AimbotModule.FOV.Visible = enabled
    end)
    
    -- FIXED: Proper step value for radius
    CombatTab:AddSlider("FOV Radius", 50, 500, 140, function(value)
        AimbotModule.FOV.Radius = value
    end, 5) -- Step of 5
    
    -- FIXED: Proper step value for thickness
    CombatTab:AddSlider("FOV Thickness", 1, 5, 2, function(value)
        AimbotModule.FOV.Thickness = value
    end, 1) -- Step of 1
    
    CombatTab:AddToggle("Fill FOV Circle", false, function(enabled)
        AimbotModule.FOV.Filled = enabled
    end)
    
    CombatTab:AddSeparator()
    
    -- Quick Presets
    CombatTab:AddLabel("═══ QUICK PRESETS ═══")
    
    CombatTab:AddButton("🎯 Legit Mode", function()
        AimbotModule.Settings.Enabled = true
        AimbotModule.Settings.TeamCheck = true
        AimbotModule.Settings.VisibleCheck = true
        AimbotModule.Settings.Smoothing = 0.25
        AimbotModule.Settings.PredictionEnabled = false
        AimbotModule.FOV.Radius = 100
        AimbotModule.FOV.Visible = false
        pcall(function()
            Library.Notify("Preset", "Legit mode activated", 2, "success")
        end)
    end)
    
    CombatTab:AddButton("💀 Rage Mode", function()
        AimbotModule.Settings.Enabled = true
        AimbotModule.Settings.TeamCheck = false
        AimbotModule.Settings.VisibleCheck = false
        AimbotModule.Settings.Smoothing = 0
        AimbotModule.Settings.PredictionEnabled = true
        AimbotModule.Settings.PredictionAmount = 0.15
        AimbotModule.FOV.Radius = 500
        pcall(function()
            Library.Notify("Preset", "Rage mode activated", 2, "warning")
        end)
    end)
    
    CombatTab:AddButton("🎮 Bloxstrike Optimized", function()
        AimbotModule.Settings.Enabled = true
        AimbotModule.Settings.TeamCheck = true
        AimbotModule.Settings.VisibleCheck = true
        AimbotModule.Settings.TargetPart = "Head"
        AimbotModule.Settings.Smoothing = 0.22
        AimbotModule.Settings.PredictionEnabled = true
        AimbotModule.Settings.PredictionAmount = 0.135
        AimbotModule.FOV.Radius = 140
        pcall(function()
            Library.Notify("Preset", "Bloxstrike optimized settings applied", 2, "success")
        end)
    end)
end

-- ═══════════════════════════════════════════════════════════
--  TAB: VISUALS (ESP & Wallhack)
-- ═══════════════════════════════════════════════════════════
if ESPModule then
    local VisualsTab = Window:CreateTab("👁️ Visuals", "👁️")
    
    VisualsTab:AddLabel("═══ ESP SETTINGS ═══")
    
    -- Master Enable
    VisualsTab:AddToggle("Enable ESP", false, function(enabled)
        ESPModule.Settings.Enabled = enabled
        pcall(function()
            Library.Notify("ESP", enabled and "Activated" or "Deactivated", 2, enabled and "success" or "warning")
        end)
    end)
    
    VisualsTab:AddSeparator()
    
    -- Filters
    VisualsTab:AddLabel("═══ FILTERS ═══")
    
    VisualsTab:AddToggle("Team Check", false, function(enabled)
        ESPModule.Settings.TeamCheck = enabled
    end)
    
    VisualsTab:AddToggle("Alive Check", true, function(enabled)
        ESPModule.Settings.AliveCheck = enabled
    end)
    
    -- FIXED: Proper step value
    VisualsTab:AddSlider("Max Distance", 500, 10000, 4000, function(value)
        ESPModule.Settings.MaxDistance = value
    end, 100) -- Step of 100
    
    VisualsTab:AddToggle("Use Team Colors", true, function(enabled)
        ESPModule.Settings.UseTeamColor = enabled
    end)
    
    VisualsTab:AddSeparator()
    
    -- Box ESP
    VisualsTab:AddLabel("═══ BOX ESP ═══")
    
    VisualsTab:AddToggle("Enable Boxes", true, function(enabled)
        ESPModule.Boxes.Enabled = enabled
    end)
    
    local boxTypes = {"2D", "3D"}
    VisualsTab:AddDropdown("Box Type", boxTypes, "2D", function(selected)
        ESPModule.Boxes.Type = selected
    end)
    
    VisualsTab:AddSlider("Box Thickness", 1, 5, 2, function(value)
        ESPModule.Boxes.Thickness = value
    end, 1)
    
    VisualsTab:AddToggle("Fill Boxes", false, function(enabled)
        ESPModule.Boxes.Filled = enabled
    end)
    
    VisualsTab:AddSeparator()
    
    -- Tracers
    VisualsTab:AddLabel("═══ TRACERS ═══")
    
    VisualsTab:AddToggle("Enable Tracers", true, function(enabled)
        ESPModule.Tracers.Enabled = enabled
    end)
    
    local tracerPositions = {"Bottom", "Center", "Mouse"}
    VisualsTab:AddDropdown("Tracer Origin", tracerPositions, "Bottom", function(selected)
        ESPModule.Tracers.From = selected
    end)
    
    VisualsTab:AddSlider("Tracer Thickness", 1, 5, 1, function(value)
        ESPModule.Tracers.Thickness = value
    end, 1)
    
    VisualsTab:AddSeparator()
    
    -- Names & Info
    VisualsTab:AddLabel("═══ PLAYER INFO ═══")
    
    VisualsTab:AddToggle("Show Names", true, function(enabled)
        ESPModule.Names.Enabled = enabled
    end)
    
    VisualsTab:AddToggle("Show Distance", true, function(enabled)
        ESPModule.Names.ShowDistance = enabled
    end)
    
    VisualsTab:AddToggle("Show Health", true, function(enabled)
        ESPModule.Names.ShowHealth = enabled
    end)
    
    VisualsTab:AddSlider("Name Size", 10, 30, 16, function(value)
        ESPModule.Names.Size = value
    end, 1)
    
    VisualsTab:AddSeparator()
    
    -- Health Bars
    VisualsTab:AddLabel("═══ HEALTH BARS ═══")
    
    VisualsTab:AddToggle("Show Health Bar", true, function(enabled)
        ESPModule.HealthBar.Enabled = enabled
    end)
    
    local barPositions = {"Left", "Right", "Top", "Bottom"}
    VisualsTab:AddDropdown("Bar Position", barPositions, "Left", function(selected)
        ESPModule.HealthBar.Position = selected
    end)
    
    VisualsTab:AddSlider("Bar Size", 2, 8, 4, function(value)
        ESPModule.HealthBar.Size = value
    end, 1)
    
    VisualsTab:AddSeparator()
    
    -- Head Dots
    VisualsTab:AddLabel("═══ HEAD DOTS ═══")
    
    VisualsTab:AddToggle("Show Head Dots", false, function(enabled)
        ESPModule.HeadDots.Enabled = enabled
    end)
    
    VisualsTab:AddSlider("Dot Size", 4, 20, 8, function(value)
        ESPModule.HeadDots.Size = value
    end, 1)
    
    VisualsTab:AddToggle("Fill Dots", true, function(enabled)
        ESPModule.HeadDots.Filled = enabled
    end)
    
    VisualsTab:AddSeparator()
    
    -- Chams (Wallhack)
    VisualsTab:AddLabel("═══ CHAMS (WALLHACK) ═══")
    
    VisualsTab:AddToggle("Enable Chams", false, function(enabled)
        ESPModule.Chams.Enabled = enabled
        -- FIXED: Make chams see through walls
        ESPModule.Chams.VisibleOnly = false
    end)
    
    VisualsTab:AddSlider("Chams Transparency", 0, 100, 30, function(value)
        ESPModule.Chams.Transparency = value / 100
    end, 1)
    
    VisualsTab:AddToggle("Only When Visible", false, function(enabled)
        ESPModule.Chams.VisibleOnly = enabled
    end)
    
    VisualsTab:AddSeparator()
    
    -- Quick Presets
    VisualsTab:AddLabel("═══ VISUAL PRESETS ═══")
    
    VisualsTab:AddButton("🎨 Minimal ESP", function()
        ESPModule.Settings.Enabled = true
        ESPModule.Settings.TeamCheck = true
        ESPModule.Boxes.Enabled = true
        ESPModule.Boxes.Type = "2D"
        ESPModule.Boxes.Filled = false
        ESPModule.Tracers.Enabled = false
        ESPModule.Names.Enabled = true
        ESPModule.Names.ShowDistance = true
        ESPModule.HealthBar.Enabled = true
        ESPModule.HeadDots.Enabled = false
        ESPModule.Chams.Enabled = false
        pcall(function()
            Library.Notify("Preset", "Minimal ESP activated", 2, "success")
        end)
    end)
    
    VisualsTab:AddButton("🌟 Full ESP", function()
        ESPModule.Settings.Enabled = true
        ESPModule.Settings.UseTeamColor = true
        ESPModule.Boxes.Enabled = true
        ESPModule.Boxes.Type = "2D"
        ESPModule.Boxes.Filled = true
        ESPModule.Tracers.Enabled = true
        ESPModule.Names.Enabled = true
        ESPModule.Names.ShowDistance = true
        ESPModule.Names.ShowHealth = true
        ESPModule.HealthBar.Enabled = true
        ESPModule.HeadDots.Enabled = true
        ESPModule.Chams.Enabled = true
        ESPModule.Chams.VisibleOnly = false
        pcall(function()
            Library.Notify("Preset", "Full ESP activated", 2, "success")
        end)
    end)
    
    VisualsTab:AddButton("🎮 Bloxstrike Optimized", function()
        ESPModule.Settings.Enabled = true
        ESPModule.Settings.TeamCheck = true
        ESPModule.Settings.MaxDistance = 4000
        ESPModule.Settings.UseTeamColor = true
        ESPModule.Boxes.Enabled = true
        ESPModule.Boxes.Type = "2D"
        ESPModule.Tracers.Enabled = true
        ESPModule.Tracers.From = "Bottom"
        ESPModule.Names.Enabled = true
        ESPModule.Names.ShowDistance = true
        ESPModule.Names.ShowHealth = true
        ESPModule.HealthBar.Enabled = true
        ESPModule.Chams.Enabled = false
        pcall(function()
            Library.Notify("Preset", "Bloxstrike optimized visuals applied", 2, "success")
        end)
    end)
end

-- ═══════════════════════════════════════════════════════════
--  TAB: PLAYER MODIFICATIONS
-- ═══════════════════════════════════════════════════════════
local PlayerTab = Window:CreateTab("🏃 Player", "🏃")

PlayerTab:AddLabel("═══ MOVEMENT ═══")

-- WalkSpeed
local currentWalkSpeed = 16
PlayerTab:AddSlider("Walk Speed", 16, 200, 16, function(value)
    currentWalkSpeed = value
    pcall(function()
        local char = game.Players.LocalPlayer.Character
        if char then
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = value
            end
        end
    end)
end, 1)

-- JumpPower
local currentJumpPower = 50
PlayerTab:AddSlider("Jump Power", 50, 300, 50, function(value)
    currentJumpPower = value
    pcall(function()
        local char = game.Players.LocalPlayer.Character
        if char then
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.JumpPower = value
            end
        end
    end)
end, 1)

-- Keep speeds active
task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            local char = game.Players.LocalPlayer.Character
            if char then
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    if humanoid.WalkSpeed ~= currentWalkSpeed then
                        humanoid.WalkSpeed = currentWalkSpeed
                    end
                    if humanoid.JumpPower ~= currentJumpPower then
                        humanoid.JumpPower = currentJumpPower
                    end
                end
            end
        end)
    end
end)

PlayerTab:AddSeparator()

-- Camera
PlayerTab:AddLabel("═══ CAMERA ═══")

PlayerTab:AddSlider("Field of View", 70, 120, 70, function(value)
    pcall(function()
        workspace.CurrentCamera.FieldOfView = value
    end)
end, 1)

PlayerTab:AddSeparator()

-- Special Abilities
PlayerTab:AddLabel("═══ SPECIAL ABILITIES ═══")

-- Infinite Jump
local InfJumpEnabled = false
PlayerTab:AddToggle("Infinite Jump", false, function(enabled)
    InfJumpEnabled = enabled
    pcall(function()
        Library.Notify("Infinite Jump", enabled and "Enabled" or "Disabled", 2, enabled and "success" or "warning")
    end)
end)

game:GetService("UserInputService").JumpRequest:Connect(function()
    if InfJumpEnabled then
        pcall(function()
            game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
        end)
    end
end)

-- No Clip
local NoClipEnabled = false
local NoClipConnection

PlayerTab:AddToggle("No Clip", false, function(enabled)
    NoClipEnabled = enabled
    
    if enabled then
        NoClipConnection = game:GetService("RunService").Stepped:Connect(function()
            if NoClipEnabled then
                pcall(function()
                    for _, part in pairs(game.Players.LocalPlayer.Character:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                        end
                    end
                end)
            end
        end)
        pcall(function()
            Library.Notify("No Clip", "Enabled - Walk through walls!", 2, "success")
        end)
    else
        if NoClipConnection then
            NoClipConnection:Disconnect()
        end
        -- Restore collision
        pcall(function()
            for _, part in pairs(game.Players.LocalPlayer.Character:GetDescendants()) do
                if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    part.CanCollide = true
                end
            end
        end)
        pcall(function()
            Library.Notify("No Clip", "Disabled", 2, "warning")
        end)
    end
end)

-- Fly (NEW!)
local FlyEnabled = false
local FlySpeed = 50
local FlyConnection

PlayerTab:AddToggle("Fly", false, function(enabled)
    FlyEnabled = enabled
    
    if enabled then
        pcall(function()
            local char = game.Players.LocalPlayer.Character
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            local root = char:FindFirstChild("HumanoidRootPart")
            
            if humanoid and root then
                local bodyVelocity = Instance.new("BodyVelocity")
                bodyVelocity.MaxForce = Vector3.new(100000, 100000, 100000)
                bodyVelocity.Velocity = Vector3.new(0, 0, 0)
                bodyVelocity.Parent = root
                
                local bodyGyro = Instance.new("BodyGyro")
                bodyGyro.MaxTorque = Vector3.new(100000, 100000, 100000)
                bodyGyro.P = 10000
                bodyGyro.Parent = root
                
                FlyConnection = game:GetService("RunService").Heartbeat:Connect(function()
                    if FlyEnabled then
                        local camera = workspace.CurrentCamera
                        local moveDirection = Vector3.new(0, 0, 0)
                        
                        if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.W) then
                            moveDirection = moveDirection + camera.CFrame.LookVector
                        end
                        if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.S) then
                            moveDirection = moveDirection - camera.CFrame.LookVector
                        end
                        if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.A) then
                            moveDirection = moveDirection - camera.CFrame.RightVector
                        end
                        if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.D) then
                            moveDirection = moveDirection + camera.CFrame.RightVector
                        end
                        if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.Space) then
                            moveDirection = moveDirection + Vector3.new(0, 1, 0)
                        end
                        if game:GetService("UserInputService"):IsKeyDown(Enum.KeyCode.LeftShift) then
                            moveDirection = moveDirection - Vector3.new(0, 1, 0)
                        end
                        
                        bodyVelocity.Velocity = moveDirection.Unit * FlySpeed
                        bodyGyro.CFrame = camera.CFrame
                    end
                end)
                
                Library.Notify("Fly", "Enabled - Use WASD + Space/Shift!", 3, "success")
            end
        end)
    else
        if FlyConnection then
            FlyConnection:Disconnect()
        end
        pcall(function()
            local char = game.Players.LocalPlayer.Character
            local root = char:FindFirstChild("HumanoidRootPart")
            if root then
                for _, obj in pairs(root:GetChildren()) do
                    if obj:IsA("BodyVelocity") or obj:IsA("BodyGyro") then
                        obj:Destroy()
                    end
                end
            end
        end)
        pcall(function()
            Library.Notify("Fly", "Disabled", 2, "warning")
        end)
    end
end)

PlayerTab:AddSlider("Fly Speed", 10, 200, 50, function(value)
    FlySpeed = value
end, 5)

-- ═══════════════════════════════════════════════════════════
--  TAB: UTILITIES
-- ═══════════════════════════════════════════════════════════
local UtilsTab = Window:CreateTab("🔧 Utils", "🔧")

UtilsTab:AddLabel("═══ VISUAL UTILITIES ═══")

-- Fullbright
UtilsTab:AddToggle("Fullbright", false, function(enabled)
    local Lighting = game:GetService("Lighting")
    if enabled then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        pcall(function()
            Library.Notify("Fullbright", "Enabled - See everything!", 2, "success")
        end)
    else
        Lighting.Brightness = 1
        Lighting.ClockTime = 12
        Lighting.GlobalShadows = true
        Lighting.FogEnd = 500
        Lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
        pcall(function()
            Library.Notify("Fullbright", "Disabled", 2, "warning")
        end)
    end
end)

-- Remove Fog
UtilsTab:AddToggle("Remove Fog", false, function(enabled)
    local Lighting = game:GetService("Lighting")
    if enabled then
        Lighting.FogEnd = 100000
        Lighting.FogStart = 0
    else
        Lighting.FogEnd = 500
        Lighting.FogStart = 0
    end
end)

UtilsTab:AddSeparator()

UtilsTab:AddLabel("═══ GAMEPLAY UTILITIES ═══")

-- Anti-AFK
local AntiAFKEnabled = false
local AntiAFKConnection

UtilsTab:AddToggle("Anti-AFK", false, function(enabled)
    AntiAFKEnabled = enabled
    
    if enabled then
        local VirtualUser = game:GetService("VirtualUser")
        AntiAFKConnection = game:GetService("Players").LocalPlayer.Idled:Connect(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
        pcall(function()
            Library.Notify("Anti-AFK", "Enabled - Won't get kicked!", 2, "success")
        end)
    else
        if AntiAFKConnection then
            AntiAFKConnection:Disconnect()
        end
        pcall(function()
            Library.Notify("Anti-AFK", "Disabled", 2, "warning")
        end)
    end
end)

-- Remove Kill Barriers (Bloxstrike specific)
UtilsTab:AddButton("🛡️ Remove Kill Barriers", function()
    pcall(function()
        local removed = 0
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("Part") and obj.Name:lower():find("kill") then
                obj:Destroy()
                removed = removed + 1
            end
        end
        Library.Notify("Kill Barriers", "Removed " .. removed .. " kill barriers", 2, "success")
    end)
end)

UtilsTab:AddSeparator()

-- Crosshair (NEW!)
UtilsTab:AddLabel("═══ CROSSHAIR ═══")

local CrosshairEnabled = false
local CrosshairSize = 10
local CrosshairThickness = 2
local CrosshairGap = 5
local CrosshairColor = Color3.fromRGB(0, 255, 0)
local CrosshairParts = {}

local function CreateCrosshair()
    pcall(function()
        local screenGui = Instance.new("ScreenGui")
        screenGui.Name = "DarpaCrosshair"
        screenGui.Parent = game.Players.LocalPlayer:WaitForChild("PlayerGui")
        screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        
        -- Top line
        local top = Instance.new("Frame")
        top.Size = UDim2.new(0, CrosshairThickness, 0, CrosshairSize)
        top.Position = UDim2.new(0.5, -CrosshairThickness/2, 0.5, -CrosshairSize - CrosshairGap)
        top.BackgroundColor3 = CrosshairColor
        top.BorderSizePixel = 0
        top.Parent = screenGui
        
        -- Bottom line
        local bottom = Instance.new("Frame")
        bottom.Size = UDim2.new(0, CrosshairThickness, 0, CrosshairSize)
        bottom.Position = UDim2.new(0.5, -CrosshairThickness/2, 0.5, CrosshairGap)
        bottom.BackgroundColor3 = CrosshairColor
        bottom.BorderSizePixel = 0
        bottom.Parent = screenGui
        
        -- Left line
        local left = Instance.new("Frame")
        left.Size = UDim2.new(0, CrosshairSize, 0, CrosshairThickness)
        left.Position = UDim2.new(0.5, -CrosshairSize - CrosshairGap, 0.5, -CrosshairThickness/2)
        left.BackgroundColor3 = CrosshairColor
        left.BorderSizePixel = 0
        left.Parent = screenGui
        
        -- Right line
        local right = Instance.new("Frame")
        right.Size = UDim2.new(0, CrosshairSize, 0, CrosshairThickness)
        right.Position = UDim2.new(0.5, CrosshairGap, 0.5, -CrosshairThickness/2)
        right.BackgroundColor3 = CrosshairColor
        right.BorderSizePixel = 0
        right.Parent = screenGui
        
        CrosshairParts = {screenGui, top, bottom, left, right}
    end)
end

local function RemoveCrosshair()
    pcall(function()
        for _, part in pairs(CrosshairParts) do
            if part and part.Parent then
                part:Destroy()
            end
        end
        CrosshairParts = {}
    end)
end

UtilsTab:AddToggle("Custom Crosshair", false, function(enabled)
    CrosshairEnabled = enabled
    if enabled then
        CreateCrosshair()
        pcall(function()
            Library.Notify("Crosshair", "Custom crosshair enabled!", 2, "success")
        end)
    else
        RemoveCrosshair()
    end
end)

UtilsTab:AddSlider("Crosshair Size", 5, 30, 10, function(value)
    CrosshairSize = value
    if CrosshairEnabled then
        RemoveCrosshair()
        CreateCrosshair()
    end
end, 1)

UtilsTab:AddSlider("Crosshair Gap", 0, 20, 5, function(value)
    CrosshairGap = value
    if CrosshairEnabled then
        RemoveCrosshair()
        CreateCrosshair()
    end
end, 1)

-- ═══════════════════════════════════════════════════════════
--  TAB: PERFORMANCE
-- ═══════════════════════════════════════════════════════════
local PerfTab = Window:CreateTab("⚡ Performance", "⚡")

PerfTab:AddLabel("═══ OPTIMIZATION ═══")

-- Graphics Optimizer - FIXED
PerfTab:AddButton("🚀 Optimize Graphics", function()
    pcall(function()
        local Lighting = game:GetService("Lighting")
        
        -- Remove visual effects
        for _, effect in pairs(Lighting:GetChildren()) do
            if effect:IsA("PostEffect") or effect:IsA("BloomEffect") or effect:IsA("BlurEffect") or 
               effect:IsA("ColorCorrectionEffect") or effect:IsA("SunRaysEffect") then
                effect.Enabled = false
            end
        end
        
        -- Lower quality
        local settings = settings()
        if settings and settings.Rendering then
            settings.Rendering.QualityLevel = Enum.QualityLevel.Level01
        end
        
        -- Reduce particles
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("ParticleEmitter") or obj:IsA("Trail") then
                obj.Enabled = false
            end
        end
        
        Library.Notify("Performance", "Graphics optimized successfully!", 2, "success")
    end)
end)

-- FPS Unlocker
PerfTab:AddToggle("FPS Unlocker", false, function(enabled)
    if setfpscap then
        if enabled then
            setfpscap(999)
            pcall(function()
                Library.Notify("FPS Unlocker", "Unlocked to 999 FPS!", 2, "success")
            end)
        else
            setfpscap(60)
            pcall(function()
                Library.Notify("FPS Unlocker", "Locked to 60 FPS", 2, "warning")
            end)
        end
    else
        pcall(function()
            Library.Notify("FPS Unlocker", "Not supported by your executor", 2, "error")
        end)
    end
end)

PerfTab:AddSeparator()

-- Performance Monitor
PerfTab:AddLabel("═══ PERFORMANCE MONITOR ═══")

local FPSLabel = PerfTab:AddLabel("FPS: Calculating...")
local PingLabel = PerfTab:AddLabel("Ping: Calculating...")
local MemoryLabel = PerfTab:AddLabel("Memory: Calculating...")

-- Performance monitoring
task.spawn(function()
    local lastUpdate = tick()
    local frames = 0
    
    game:GetService("RunService").RenderStepped:Connect(function()
        frames = frames + 1
    end)
    
    while task.wait(1) do
        pcall(function()
            local currentTime = tick()
            local fps = math.floor(frames / (currentTime - lastUpdate))
            frames = 0
            lastUpdate = currentTime
            
            local ping = math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue())
            local memory = math.floor(game:GetService("Stats"):GetTotalMemoryUsageMb())
            
            FPSLabel.Text = "FPS: " .. fps
            PingLabel.Text = "Ping: " .. ping .. "ms"
            MemoryLabel.Text = "Memory: " .. memory .. "MB"
        end)
    end
end)

-- ═══════════════════════════════════════════════════════════
--  TAB: INFO & CREDITS
-- ═══════════════════════════════════════════════════════════
local InfoTab = Window:CreateTab("ℹ️ Info", "ℹ️")

InfoTab:AddLabel("═══ INFORMATION ═══")
InfoTab:AddLabel("Hub: DARPA HUB v7.6")
InfoTab:AddLabel("Game: Bloxstrike")
InfoTab:AddLabel("Status: Fully Operational")
InfoTab:AddLabel("")
InfoTab:AddLabel("Developed by: DarpaHub Team")
InfoTab:AddLabel("Discord: discord.gg/darpahub")

InfoTab:AddSeparator()

InfoTab:AddLabel("═══ FEATURES ═══")
InfoTab:AddLabel("✓ Advanced Aimbot with FOV")
InfoTab:AddLabel("✓ Complete ESP System")
InfoTab:AddLabel("✓ Chams Wallhack")
InfoTab:AddLabel("✓ Player Modifications")
InfoTab:AddLabel("✓ Fly & No Clip")
InfoTab:AddLabel("✓ Custom Crosshair")
InfoTab:AddLabel("✓ Performance Optimizer")
InfoTab:AddLabel("✓ Bloxstrike Optimized")

InfoTab:AddSeparator()

InfoTab:AddButton("📋 Copy Discord Link", function()
    if setclipboard then
        setclipboard("discord.gg/darpahub")
        pcall(function()
            Library.Notify("Discord", "Link copied to clipboard!", 2, "success")
        end)
    end
end)

InfoTab:AddButton("🔄 Reload Hub", function()
    pcall(function()
        Library.Notify("Reloading", "Restarting DARPA HUB...", 2, "warning")
        task.wait(1)
        loadstring(game:HttpGet("https://raw.githubusercontent.com/oogaboogaman1231/DARPA-HUB/refs/heads/main/DarpaHub_Complete.lua"))()
    end)
end)

InfoTab:AddButton("❌ Unload Hub", function()
    pcall(function()
        Library.Notify("Goodbye", "DARPA HUB unloaded successfully", 2, "warning")
        task.wait(1)
        
        -- Disable modules
        if AimbotModule then AimbotModule:Disable() end
        if ESPModule then ESPModule:Disable() end
        
        -- Destroy GUI
        if Window and Window.Destroy then
            Window:Destroy()
        end
    end)
end)

-- ═══════════════════════════════════════════════════════════
--  FINALIZATION & HOOKS
-- ═══════════════════════════════════════════════════════════

-- Fire hook
if getgenv and getgenv().firehook then
    pcall(function()
        getgenv().firehook("HubLoaded", "DarpaHub v7.6 - Bloxstrike Edition")
    end)
end

-- Final notification
pcall(function()
    Library.Notify("DARPA HUB", "Successfully loaded for Bloxstrike! Enjoy!", 5, "success")
end)

-- Auto-apply Bloxstrike optimizations
task.wait(2)
pcall(function()
    Library.Notify("Auto-Config", "Applying Bloxstrike optimizations...", 2, "info")
end)

task.wait(1)

-- Apply Bloxstrike defaults
if AimbotModule then
    AimbotModule.Settings.TargetPart = "Head"
    AimbotModule.FOV.Radius = 140
end

if ESPModule then
    ESPModule.Settings.MaxDistance = 4000
    ESPModule.Settings.UseTeamColor = true
    ESPModule.Boxes.Type = "2D"
end

pcall(function()
    Library.Notify("Ready!", "DARPA HUB is ready for Bloxstrike!", 3, "success")
end)
