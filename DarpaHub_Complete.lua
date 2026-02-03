--[[
    ╔═══════════════════════════════════════════════════════════╗
    ║            DARPA HUB v7.5 - COMPLETE EDITION              ║
    ║         Premium Script Hub com todos os módulos           ║
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

-- Carregar biblioteca principal (coloque o código da biblioteca aqui ou carregue de URL)
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/oogaboogaman1231/DARPA-HUB/refs/heads/main/DarpaHubUI.lua"))()

-- Carregar módulos
local AimbotModule = loadstring(game:HttpGet("https://raw.githubusercontent.com/oogaboogaman1231/DARPA-HUB/refs/heads/main/DarpaHub_Aimbot.lua"))()
local ESPModule = loadstring(game:HttpGet("https://raw.githubusercontent.com/oogaboogaman1231/DARPA-HUB/refs/heads/main/DarpaHub_ESP.lua"))()

-- Inicializar módulos
AimbotModule:Init()
ESPModule:Init()

-- ═══════════════════════════════════════════════════════════
--  CRIAR JANELA PRINCIPAL
-- ═══════════════════════════════════════════════════════════
local Window = Library:CreateWindow({
    Title = "DARPA HUB",
    Subtitle = "Premium Script Hub v7.5"
})

-- Notificação de boas-vindas
Library.Notify("Bem-vindo!", "DARPA HUB carregado com sucesso", 3, "success")

-- ═══════════════════════════════════════════════════════════
--  TAB: AIMBOT
-- ═══════════════════════════════════════════════════════════
local AimbotTab = Window:CreateTab("🎯 Aimbot", "🎯")

AimbotTab:AddLabel("═══ CONFIGURAÇÕES DO AIMBOT ═══")

-- Enable Aimbot
AimbotTab:AddToggle("Ativado", false, function(enabled)
    AimbotModule.Settings.Enabled = enabled
    Library.Notify("Aimbot", enabled and "Ativado" or "Desativado", 2, enabled and "success" or "warning")
end)

AimbotTab:AddSeparator()

-- Checks
AimbotTab:AddLabel("═══ VERIFICAÇÕES ═══")

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
AimbotTab:AddLabel("═══ ALVO ═══")

local parts = {"Head", "HumanoidRootPart", "Torso", "UpperTorso", "LowerTorso"}
AimbotTab:AddDropdown("Parte do Corpo", parts, "Head", function(selected)
    AimbotModule.Settings.TargetPart = selected
    Library.Notify("Aimbot", "Mirando em: " .. selected, 2)
end)

local priorities = {"Distance", "Health", "Crosshair"}
AimbotTab:AddDropdown("Prioridade", priorities, "Distance", function(selected)
    AimbotModule.Settings.Priority = selected
end)

AimbotTab:AddSeparator()

-- Smoothing
AimbotTab:AddLabel("═══ SUAVIZAÇÃO ═══")

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

-- ═══════════════════════════════════════════════════════════
--  TAB: ESP / VISUALS
-- ═══════════════════════════════════════════════════════════
local ESPTab = Window:CreateTab("👁️ ESP", "👁️")

ESPTab:AddLabel("═══ CONFIGURAÇÕES ESP ═══")

-- Enable ESP
ESPTab:AddToggle("ESP Ativado", false, function(enabled)
    ESPModule.Settings.Enabled = enabled
    Library.Notify("ESP", enabled and "Ativado" or "Desativado", 2, enabled and "success" or "warning")
end)

ESPTab:AddSeparator()

-- Checks
ESPTab:AddLabel("═══ VERIFICAÇÕES ═══")

ESPTab:AddToggle("Team Check", false, function(enabled)
    ESPModule.Settings.TeamCheck = enabled
end)

ESPTab:AddToggle("Alive Check", true, function(enabled)
    ESPModule.Settings.AliveCheck = enabled
end)

ESPTab:AddSlider("Distância Máxima", 100, 10000, 5000, function(value)
    ESPModule.Settings.MaxDistance = value
end)

ESPTab:AddToggle("Usar Cor de Time", true, function(enabled)
    ESPModule.Settings.UseTeamColor = enabled
end)

ESPTab:AddSeparator()

-- Boxes
ESPTab:AddLabel("═══ BOXES ═══")

ESPTab:AddToggle("Boxes", true, function(enabled)
    ESPModule.Boxes.Enabled = enabled
end)

local boxTypes = {"2D", "3D"}
ESPTab:AddDropdown("Tipo de Box", boxTypes, "2D", function(selected)
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

ESPTab:AddToggle("Mostrar Distância", true, function(enabled)
    ESPModule.Names.ShowDistance = enabled
end)

ESPTab:AddToggle("Mostrar Vida", true, function(enabled)
    ESPModule.Names.ShowHealth = enabled
end)

ESPTab:AddSlider("Tamanho do Nome", 10, 30, 16, function(value)
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

-- ═══════════════════════════════════════════════════════════
--  TAB: PLAYER
-- ═══════════════════════════════════════════════════════════
local PlayerTab = Window:CreateTab("👤 Player", "👤")

PlayerTab:AddLabel("═══ CONFIGURAÇÕES DO JOGADOR ═══")

-- WalkSpeed
PlayerTab:AddSlider("WalkSpeed", 16, 200, 16, function(value)
    Library.Movement:SetWalkSpeed(value)
end)

-- JumpPower
PlayerTab:AddSlider("JumpPower", 50, 300, 50, function(value)
    Library.Movement:SetJumpPower(value)
end)

PlayerTab:AddSeparator()

-- FOV
PlayerTab:AddSlider("Field of View", 70, 120, 70, function(value)
    Library.FOV:Set(value)
end)

PlayerTab:AddSeparator()

-- Anti-AFK
PlayerTab:AddToggle("Anti-AFK", false, function(enabled)
    if enabled then
        Library.AntiAFK:Enable()
        Library.Notify("Anti-AFK", "Ativado", 2, "success")
    else
        Library.AntiAFK:Disable()
        Library.Notify("Anti-AFK", "Desativado", 2, "warning")
    end
end)

-- Infinite Jump
local InfJumpEnabled = false
PlayerTab:AddToggle("Infinite Jump", false, function(enabled)
    InfJumpEnabled = enabled
end)

game:GetService("UserInputService").JumpRequest:Connect(function()
    if InfJumpEnabled then
        game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid"):ChangeState("Jumping")
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
                for _, part in pairs(game.Players.LocalPlayer.Character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end
        end)
        Library.Notify("No Clip", "Ativado", 2, "success")
    else
        if NoClipConnection then
            NoClipConnection:Disconnect()
        end
        Library.Notify("No Clip", "Desativado", 2, "warning")
    end
end)

-- ═══════════════════════════════════════════════════════════
--  TAB: MISC
-- ═══════════════════════════════════════════════════════════
local MiscTab = Window:CreateTab("⚙️ Misc", "⚙️")

MiscTab:AddLabel("═══ UTILIDADES ═══")

-- Fullbright
MiscTab:AddToggle("Fullbright", false, function(enabled)
    local Lighting = game:GetService("Lighting")
    if enabled then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        Library.Notify("Fullbright", "Ativado", 2, "success")
    else
        Lighting.Brightness = 1
        Lighting.ClockTime = 12
        Lighting.GlobalShadows = true
        Library.Notify("Fullbright", "Desativado", 2, "warning")
    end
end)

-- Remove Fog
MiscTab:AddToggle("Remove Fog", false, function(enabled)
    game:GetService("Lighting").FogEnd = enabled and 100000 or 500
end)

MiscTab:AddSeparator()

-- Chat Spammer
local SpamEnabled = false
local SpamMessage = ""
local SpamDelay = 1

MiscTab:AddTextbox("Mensagem do Spam", "Digite a mensagem", function(text)
    SpamMessage = text
end)

MiscTab:AddSlider("Delay do Spam (s)", 0.5, 5, 1, function(value)
    SpamDelay = value
end)

MiscTab:AddToggle("Chat Spam", false, function(enabled)
    SpamEnabled = enabled
    
    if enabled then
        task.spawn(function()
            while SpamEnabled do
                if SpamMessage ~= "" then
                    game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer(SpamMessage, "All")
                end
                task.wait(SpamDelay)
            end
        end)
        Library.Notify("Chat Spam", "Ativado", 2, "success")
    else
        Library.Notify("Chat Spam", "Desativado", 2, "warning")
    end
end)

-- ═══════════════════════════════════════════════════════════
--  TAB: PERFORMANCE
-- ═══════════════════════════════════════════════════════════
local PerfTab = Window:CreateTab("📊 Performance", "📊")

PerfTab:AddLabel("═══ OTIMIZAÇÃO ═══")

-- Performance Monitor
Library.Performance:StartMonitoring()

local FPSLabel = PerfTab:AddLabel("FPS: 0")
local PingLabel = PerfTab:AddLabel("Ping: 0ms")
local MemoryLabel = PerfTab:AddLabel("Memória: 0MB")

task.spawn(function()
    while true do
        FPSLabel.Text = "FPS: " .. Library.Performance.FPS
        PingLabel.Text = "Ping: " .. Library.Performance.Ping .. "ms"
        MemoryLabel.Text = "Memória: " .. Library.Performance.Memory .. "MB"
        task.wait(1)
    end
end)

PerfTab:AddSeparator()

-- Graphics Optimizer
PerfTab:AddButton("🚀 Otimizar Gráficos", function()
    local Lighting = game:GetService("Lighting")
    
    for _, effect in pairs(Lighting:GetChildren()) do
        if effect:IsA("PostEffect") then
            effect.Enabled = false
        end
    end
    
    settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    
    Library.Notify("Performance", "Gráficos otimizados", 2, "success")
end)

-- FPS Unlocker
PerfTab:AddToggle("FPS Unlocker", false, function(enabled)
    if enabled then
        setfpscap(999)
        Library.Notify("FPS Unlocker", "Ativado (999 FPS)", 2, "success")
    else
        setfpscap(60)
        Library.Notify("FPS Unlocker", "Desativado (60 FPS)", 2, "warning")
    end
end)

-- ═══════════════════════════════════════════════════════════
--  TAB: CONFIGS
-- ═══════════════════════════════════════════════════════════
local ConfigTab = Window:CreateTab("💾 Configs", "💾")

ConfigTab:AddLabel("═══ INFORMAÇÕES ═══")
ConfigTab:AddLabel("Desenvolvido por: DarpaHub Team")
ConfigTab:AddLabel("Versão: 7.5 Ultimate")
ConfigTab:AddLabel("Discord: discord.gg/darpahub")

ConfigTab:AddSeparator()

ConfigTab:AddButton("📋 Copiar Discord", function()
    if setclipboard then
        setclipboard("discord.gg/darpahub")
        Library.Notify("Discord", "Copiado para clipboard!", 2, "success")
    end
end)

-- ═══════════════════════════════════════════════════════════
--  HOOKS
-- ═══════════════════════════════════════════════════════════
getgenv().firehook("HubLoaded", function()
    print("Hub carregado!")
end)

getgenv().firehook("HubLoaded", "DarpaHub v7.5")

-- ═══════════════════════════════════════════════════════════
--  FINALIZAÇÃO
-- ═══════════════════════════════════════════════════════════
print("╔═══════════════════════════════════════════════════════════╗")
print("║          DARPA HUB v7.5 CARREGADO COM SUCESSO             ║")
print("║              Aproveite todos os recursos!                 ║")
print("╚═══════════════════════════════════════════════════════════╝")

Library.Notify("DARPA HUB", "Carregado com sucesso! Aproveite!", 5, "success")
