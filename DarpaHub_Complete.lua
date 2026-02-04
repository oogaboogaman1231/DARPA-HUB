--[[
    ╔═══════════════════════════════════════════════════════════╗
    ║         DARPA HUB v7.5 - BLOXSTRIKE EDITION              ║
    ║         Premium Script Hub - Optimized for Bloxstrike     ║
    ║                                                           ║
    ║  Features:                                                ║
    ║  • Aimbot com FOV, Prediction, Smoothing                  ║
    ║  • ESP completo (Boxes, Tracers, Names, Health Bars)      ║
    ║  • Wall Hack com Chams                                    ║
    ║  • Crosshair customizável                                 ║
    ║  • Visibility Check                                       ║
    ║  • Performance Monitor                                    ║
    ║  • UI Premium moderna                                     ║
    ║                                                           ║
    ╚═══════════════════════════════════════════════════════════╝
]]

-- Check if game is loaded
if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- Load UI Library
local Library
pcall(function()
    Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/oogaboogaman1231/DARPA-HUB/refs/heads/main/DarpaHubUI.lua"))()
end)

if not Library then
    warn("Failed to load UI library")
    return
end

-- Load modules
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
--  CREATE MAIN WINDOW
-- ═══════════════════════════════════════════════════════════
local Window = Library:CreateWindow({
    Title = "DARPA HUB - Bloxstrike",
    Subtitle = "Premium Script Hub v7.5"
})

-- Welcome notification
pcall(function()
    Library.Notify("Welcome!", "DARPA HUB loaded successfully for Bloxstrike", 3, "success")
end)

-- ═══════════════════════════════════════════════════════════
--  TAB: AIMBOT
-- ═══════════════════════════════════════════════════════════
if AimbotModule then
    local AimbotTab = Window:CreateTab("🎯 Aimbot", "🎯")
    
    AimbotTab:AddLabel("═══ AIMBOT SETTINGS ═══")
    
    -- Enable Aimbot
    AimbotTab:AddToggle("Enable Aimbot", false, function(enabled)
        AimbotModule.Settings.Enabled = enabled
        pcall(function()
            Library.Notify("Aimbot", enabled and "Enabled" or "Disabled", 2, enabled and "success" or "warning")
        end)
    end)
    
    AimbotTab:AddSeparator()
    
    -- Checks
    AimbotTab:AddLabel("═══ CHECKS ═══")
    
    AimbotTab:AddToggle("Team Check", false, function(enabled)
        AimbotModule.Settings.TeamCheck = enabled
    end)
    
    AimbotTab:AddToggle("Alive Check", true, function(enabled)
        AimbotModule.Settings.AliveCheck = enabled
    end)
    
    AimbotTab:AddToggle("Visibility Check", true, function(enabled)
        AimbotModule.Settings.VisibleCheck = enabled
    end)
    
    AimbotTab:AddSeparator()
    
    -- Target Part
    AimbotTab:AddLabel("═══ TARGET ═══")
    
    local parts = {"Head", "HumanoidRootPart", "Torso", "UpperTorso"}
    AimbotTab:AddDropdown("Body Part", parts, "Head", function(selected)
        AimbotModule.Settings.TargetPart = selected
        pcall(function()
            Library.Notify("Aimbot", "Targeting: " .. selected, 2)
        end)
    end)
    
    local priorities = {"Distance", "Health", "Crosshair"}
    AimbotTab:AddDropdown("Priority", priorities, "Distance", function(selected)
        AimbotModule.Settings.Priority = selected
    end)
    
    AimbotTab:AddSeparator()
    
    -- Smoothing
    AimbotTab:AddLabel("═══ SMOOTHING ═══")
    
    AimbotTab:AddSlider("Smoothing", 0, 1, 0.15, function(value)
        AimbotModule.Settings.Smoothing = value
    end)
    
    AimbotTab:AddToggle("Prediction", false, function(enabled)
        AimbotModule.Settings.PredictionEnabled = enabled
    end)
    
    AimbotTab:AddSlider("Prediction Amount", 0, 0.5, 0.12, function(value)
        AimbotModule.Settings.PredictionAmount = value
    end)
    
    AimbotTab:AddSeparator()
    
    -- FOV
    AimbotTab:AddLabel("═══ FOV CIRCLE ═══")
    
    AimbotTab:AddToggle("FOV Enabled", true, function(enabled)
        AimbotModule.FOV.Enabled = enabled
    end)
    
    AimbotTab:AddToggle("FOV Visible", true, function(enabled)
        AimbotModule.FOV.Visible = enabled
    end)
    
    AimbotTab:AddSlider("FOV Radius", 50, 500, 150, function(value)
        AimbotModule.FOV.Radius = value
    end)
    
    AimbotTab:AddSlider("FOV Thickness", 1, 5, 2, function(value)
        AimbotModule.FOV.Thickness = value
    end)
    
    AimbotTab:AddToggle("FOV Filled", false, function(enabled)
        AimbotModule.FOV.Filled = enabled
    end)
end

-- ═══════════════════════════════════════════════════════════
--  TAB: ESP / VISUALS
-- ═══════════════════════════════════════════════════════════
if ESPModule then
    local ESPTab = Window:CreateTab("👁️ ESP", "👁️")
    
    ESPTab:AddLabel("═══ ESP SETTINGS ═══")
    
    -- Enable ESP
    ESPTab:AddToggle("Enable ESP", false, function(enabled)
        ESPModule.Settings.Enabled = enabled
        pcall(function()
            Library.Notify("ESP", enabled and "Enabled" or "Disabled", 2, enabled and "success" or "warning")
        end)
    end)
    
    ESPTab:AddSeparator()
    
    -- Checks
    ESPTab:AddLabel("═══ CHECKS ═══")
    
    ESPTab:AddToggle("Team Check", false, function(enabled)
        ESPModule.Settings.TeamCheck = enabled
    end)
    
    ESPTab:AddToggle("Alive Check", true, function(enabled)
        ESPModule.Settings.AliveCheck = enabled
    end)
    
    ESPTab:AddSlider("Max Distance", 100, 10000, 5000, function(value)
        ESPModule.Settings.MaxDistance = value
    end)
    
    ESPTab:AddToggle("Use Team Color", true, function(enabled)
        ESPModule.Settings.UseTeamColor = enabled
    end)
    
    ESPTab:AddSeparator()
    
    -- Boxes
    ESPTab:AddLabel("═══ BOXES ═══")
    
    ESPTab:AddToggle("Boxes", true, function(enabled)
        ESPModule.Boxes.Enabled = enabled
    end)
    
    local boxTypes = {"2D", "3D"}
    ESPTab:AddDropdown("Box Type", boxTypes, "2D", function(selected)
        ESPModule.Boxes.Type = selected
    end)
    
    ESPTab:AddSlider("Box Thickness", 1, 5, 2, function(value)
        ESPModule.Boxes.Thickness = value
    end)
    
    ESPTab:AddToggle("Box Filled", false, function(enabled)
        ESPModule.Boxes.Filled = enabled
    end)
    
    ESPTab:AddSeparator()
    
    -- Tracers
    ESPTab:AddLabel("═══ TRACERS ═══")
    
    ESPTab:AddToggle("Tracers", true, function(enabled)
        ESPModule.Tracers.Enabled = enabled
    end)
    
    local tracerPos = {"Bottom", "Center", "Mouse"}
    ESPTab:AddDropdown("Tracer From", tracerPos, "Bottom", function(selected)
        ESPModule.Tracers.From = selected
    end)
    
    ESPTab:AddSlider("Tracer Thickness", 1, 5, 1, function(value)
        ESPModule.Tracers.Thickness = value
    end)
    
    ESPTab:AddSeparator()
    
    -- Names
    ESPTab:AddLabel("═══ NAMES ═══")
    
    ESPTab:AddToggle("Names", true, function(enabled)
        ESPModule.Names.Enabled = enabled
    end)
    
    ESPTab:AddToggle("Show Distance", true, function(enabled)
        ESPModule.Names.ShowDistance = enabled
    end)
    
    ESPTab:AddToggle("Show Health", true, function(enabled)
        ESPModule.Names.ShowHealth = enabled
    end)
    
    ESPTab:AddSlider("Name Size", 10, 30, 16, function(value)
        ESPModule.Names.Size = value
    end)
    
    ESPTab:AddSeparator()
    
    -- Health Bars
    ESPTab:AddLabel("═══ HEALTH BARS ═══")
    
    ESPTab:AddToggle("Health Bar", true, function(enabled)
        ESPModule.HealthBar.Enabled = enabled
    end)
    
    local healthBarPos = {"Left", "Right", "Top", "Bottom"}
    ESPTab:AddDropdown("Health Bar Position", healthBarPos, "Left", function(selected)
        ESPModule.HealthBar.Position = selected
    end)
    
    ESPTab:AddSlider("Health Bar Size", 2, 8, 4, function(value)
        ESPModule.HealthBar.Size = value
    end)
    
    ESPTab:AddSeparator()
    
    -- Head Dots
    ESPTab:AddLabel("═══ HEAD DOTS ═══")
    
    ESPTab:AddToggle("Head Dots", false, function(enabled)
        ESPModule.HeadDots.Enabled = enabled
    end)
    
    ESPTab:AddSlider("Head Dot Size", 4, 20, 8, function(value)
        ESPModule.HeadDots.Size = value
    end)
    
    ESPTab:AddToggle("Head Dot Filled", true, function(enabled)
        ESPModule.HeadDots.Filled = enabled
    end)
    
    ESPTab:AddSeparator()
    
    -- Chams
    ESPTab:AddLabel("═══ CHAMS ═══")
    
    ESPTab:AddToggle("Chams", false, function(enabled)
        ESPModule.Chams.Enabled = enabled
    end)
    
    ESPTab:AddSlider("Chams Transparency", 0, 1, 0.3, function(value)
        ESPModule.Chams.Transparency = value
    end)
    
    ESPTab:AddToggle("Visible Only", false, function(enabled)
        ESPModule.Chams.VisibleOnly = enabled
    end)
end

-- ═══════════════════════════════════════════════════════════
--  TAB: PLAYER
-- ═══════════════════════════════════════════════════════════
local PlayerTab = Window:CreateTab("👤 Player", "👤")

PlayerTab:AddLabel("═══ PLAYER SETTINGS ═══")

-- WalkSpeed
PlayerTab:AddSlider("WalkSpeed", 16, 200, 16, function(value)
    pcall(function()
        local char = game.Players.LocalPlayer.Character
        if char then
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = value
            end
        end
    end)
end)

-- JumpPower
PlayerTab:AddSlider("JumpPower", 50, 300, 50, function(value)
    pcall(function()
        local char = game.Players.LocalPlayer.Character
        if char then
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.JumpPower = value
            end
        end
    end)
end)

PlayerTab:AddSeparator()

-- FOV
PlayerTab:AddSlider("Field of View", 70, 120, 70, function(value)
    pcall(function()
        workspace.CurrentCamera.FieldOfView = value
    end)
end)

PlayerTab:AddSeparator()

-- Infinite Jump
local InfJumpEnabled = false
PlayerTab:AddToggle("Infinite Jump", false, function(enabled)
    InfJumpEnabled = enabled
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
            Library.Notify("No Clip", "Enabled", 2, "success")
        end)
    else
        if NoClipConnection then
            NoClipConnection:Disconnect()
        end
        pcall(function()
            Library.Notify("No Clip", "Disabled", 2, "warning")
        end)
    end
end)

-- ═══════════════════════════════════════════════════════════
--  TAB: MISC
-- ═══════════════════════════════════════════════════════════
local MiscTab = Window:CreateTab("⚙️ Misc", "⚙️")

MiscTab:AddLabel("═══ UTILITIES ═══")

-- Fullbright
MiscTab:AddToggle("Fullbright", false, function(enabled)
    local Lighting = game:GetService("Lighting")
    if enabled then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        pcall(function()
            Library.Notify("Fullbright", "Enabled", 2, "success")
        end)
    else
        Lighting.Brightness = 1
        Lighting.ClockTime = 12
        Lighting.GlobalShadows = true
        pcall(function()
            Library.Notify("Fullbright", "Disabled", 2, "warning")
        end)
    end
end)

-- Remove Fog
MiscTab:AddToggle("Remove Fog", false, function(enabled)
    game:GetService("Lighting").FogEnd = enabled and 100000 or 500
end)

MiscTab:AddSeparator()

-- Anti-AFK
local AntiAFKEnabled = false
local AntiAFKConnection

MiscTab:AddToggle("Anti-AFK", false, function(enabled)
    AntiAFKEnabled = enabled
    
    if enabled then
        local VirtualUser = game:GetService("VirtualUser")
        AntiAFKConnection = game:GetService("Players").LocalPlayer.Idled:Connect(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
        pcall(function()
            Library.Notify("Anti-AFK", "Enabled", 2, "success")
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

-- ═══════════════════════════════════════════════════════════
--  TAB: PERFORMANCE
-- ═══════════════════════════════════════════════════════════
local PerfTab = Window:CreateTab("📊 Performance", "📊")

PerfTab:AddLabel("═══ OPTIMIZATION ═══")

-- Graphics Optimizer
PerfTab:AddButton("🚀 Optimize Graphics", function()
    pcall(function()
        local Lighting = game:GetService("Lighting")
        
        for _, effect in pairs(Lighting:GetChildren()) do
            if effect:IsA("PostEffect") then
                effect.Enabled = false
            end
        end
        
        settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
        
        Library.Notify("Performance", "Graphics optimized", 2, "success")
    end)
end)

-- FPS Unlocker
PerfTab:AddToggle("FPS Unlocker", false, function(enabled)
    if setfpscap then
        if enabled then
            setfpscap(999)
            pcall(function()
                Library.Notify("FPS Unlocker", "Enabled (999 FPS)", 2, "success")
            end)
        else
            setfpscap(60)
            pcall(function()
                Library.Notify("FPS Unlocker", "Disabled (60 FPS)", 2, "warning")
            end)
        end
    end
end)

PerfTab:AddSeparator()

-- Performance stats
local FPSLabel = PerfTab:AddLabel("FPS: Calculating...")
local PingLabel = PerfTab:AddLabel("Ping: Calculating...")

task.spawn(function()
    local lastUpdate = tick()
    local frames = 0
    
    game:GetService("RunService").RenderStepped:Connect(function()
        frames = frames + 1
    end)
    
    while true do
        task.wait(1)
        
        local currentTime = tick()
        local fps = math.floor(frames / (currentTime - lastUpdate))
        frames = 0
        lastUpdate = currentTime
        
        local ping = math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue())
        
        pcall(function()
            FPSLabel.Text = "FPS: " .. fps
            PingLabel.Text = "Ping: " .. ping .. "ms"
        end)
    end
end)

-- ═══════════════════════════════════════════════════════════
--  TAB: INFO
-- ═══════════════════════════════════════════════════════════
local InfoTab = Window:CreateTab("ℹ️ Info", "ℹ️")

InfoTab:AddLabel("═══ INFORMATION ═══")
InfoTab:AddLabel("Game: Bloxstrike")
InfoTab:AddLabel("Version: 7.5 Ultimate")
InfoTab:AddLabel("Developer: DarpaHub Team")

InfoTab:AddSeparator()

InfoTab:AddButton("📋 Copy Discord", function()
    if setclipboard then
        setclipboard("discord.gg/darpahub")
        pcall(function()
            Library.Notify("Discord", "Copied to clipboard!", 2, "success")
        end)
    end
end)

-- ═══════════════════════════════════════════════════════════
--  HOOKS
-- ═══════════════════════════════════════════════════════════
if getgenv and getgenv().firehook then
    pcall(function()
        getgenv().firehook("HubLoaded", "DarpaHub v7.5 - Bloxstrike")
    end)
end

-- ═══════════════════════════════════════════════════════════
--  FINALIZATION
-- ═══════════════════════════════════════════════════════════
pcall(function()
    Library.Notify("DARPA HUB", "Successfully loaded for Bloxstrike!", 5, "success")
end)
