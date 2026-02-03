--[[
    ╔═══════════════════════════════════════════════════════════╗
    ║            DARPA HUB - AIMBOT MODULE v7.5                 ║
    ║         Premium Aimbot com FOV e Prediction               ║
    ╚═══════════════════════════════════════════════════════════╝
]]

local AimbotModule = {}

-- Services
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()
local Camera = workspace.CurrentCamera

-- Variables
local Locked = nil
local Running = false
local Typing = false
local FOVCircle = nil
local Connections = {}

-- ═══════════════════════════════════════════════════════════
--  AIMBOT SETTINGS
-- ═══════════════════════════════════════════════════════════
AimbotModule.Settings = {
    Enabled = false,
    TeamCheck = false,
    AliveCheck = true,
    WallCheck = false,
    VisibleCheck = true,
    
    -- Targeting
    TargetPart = "Head", -- Head, HumanoidRootPart, Torso, etc
    Priority = "Distance", -- Distance, Health, Crosshair
    
    -- Smoothing
    Smoothing = 0.15, -- 0 = instant lock, higher = smoother
    PredictionEnabled = false,
    PredictionAmount = 0.12,
    
    -- Third Person
    ThirdPerson = false,
    ThirdPersonSensitivity = 3,
    
    -- Keybind
    TriggerKey = Enum.UserInputType.MouseButton2,
    ToggleMode = false,
    
    -- Sticky Lock
    StickyLock = true, -- Mantém lock mesmo se sair do FOV
    StickyAim = false, -- Sticky aim (segue sem precisar segurar)
}

-- ═══════════════════════════════════════════════════════════
--  FOV SETTINGS
-- ═══════════════════════════════════════════════════════════
AimbotModule.FOV = {
    Enabled = true,
    Visible = true,
    Radius = 150,
    Color = Color3.fromRGB(255, 255, 255),
    LockedColor = Color3.fromRGB(255, 50, 50),
    Transparency = 0.5,
    Filled = false,
    Thickness = 2,
    Sides = 64,
}

-- ═══════════════════════════════════════════════════════════
--  UTILITY FUNCTIONS
-- ═══════════════════════════════════════════════════════════
local function IsAlive(player)
    if not player or not player.Character then return false end
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    return humanoid and humanoid.Health > 0
end

local function GetPart(player, partName)
    if not player or not player.Character then return nil end
    return player.Character:FindFirstChild(partName)
end

local function IsVisible(player, part)
    if not player or not player.Character or not part then return false end
    
    local origin = Camera.CFrame.Position
    local direction = (part.Position - origin).Unit * 500
    local ray = Ray.new(origin, direction)
    
    local hit = workspace:FindPartOnRayWithIgnoreList(ray, {Player.Character, Camera})
    
    if hit then
        return hit:IsDescendantOf(player.Character)
    end
    
    return false
end

local function WorldToScreen(position)
    local vector, onScreen = Camera:WorldToViewportPoint(position)
    return Vector2.new(vector.X, vector.Y), onScreen, vector.Z
end

local function GetMousePosition()
    return UserInputService:GetMouseLocation()
end

local function GetDistanceFromMouse(position)
    local screenPos, onScreen = WorldToScreen(position)
    if not onScreen then return math.huge end
    
    local mousePos = GetMousePosition()
    return (screenPos - mousePos).Magnitude
end

local function GetDistanceFromPlayer(player)
    local myChar = Player.Character
    local targetChar = player.Character
    
    if not myChar or not targetChar then return math.huge end
    
    local myRoot = myChar:FindFirstChild("HumanoidRootPart")
    local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
    
    if not myRoot or not targetRoot then return math.huge end
    
    return (myRoot.Position - targetRoot.Position).Magnitude
end

local function PredictPosition(part, amount)
    if not part or not part:IsA("BasePart") then return part.Position end
    
    local velocity = part.AssemblyLinearVelocity or part.Velocity or Vector3.new()
    return part.Position + (velocity * amount)
end

-- ═══════════════════════════════════════════════════════════
--  FOV CIRCLE
-- ═══════════════════════════════════════════════════════════
local function InitFOVCircle()
    if not Drawing then return end
    
    FOVCircle = Drawing.new("Circle")
    FOVCircle.Visible = false
    FOVCircle.Radius = AimbotModule.FOV.Radius
    FOVCircle.Color = AimbotModule.FOV.Color
    FOVCircle.Transparency = AimbotModule.FOV.Transparency
    FOVCircle.Thickness = AimbotModule.FOV.Thickness
    FOVCircle.NumSides = AimbotModule.FOV.Sides
    FOVCircle.Filled = AimbotModule.FOV.Filled
end

local function UpdateFOVCircle()
    if not FOVCircle then return end
    
    if AimbotModule.FOV.Visible and AimbotModule.Settings.Enabled then
        local mousePos = GetMousePosition()
        
        FOVCircle.Position = mousePos
        FOVCircle.Radius = AimbotModule.FOV.Radius
        FOVCircle.Color = Locked and AimbotModule.FOV.LockedColor or AimbotModule.FOV.Color
        FOVCircle.Transparency = AimbotModule.FOV.Transparency
        FOVCircle.Thickness = AimbotModule.FOV.Thickness
        FOVCircle.NumSides = AimbotModule.FOV.Sides
        FOVCircle.Filled = AimbotModule.FOV.Filled
        FOVCircle.Visible = true
    else
        FOVCircle.Visible = false
    end
end

-- ═══════════════════════════════════════════════════════════
--  TARGET SELECTION
-- ═══════════════════════════════════════════════════════════
local function GetBestTarget()
    local bestTarget = nil
    local bestValue = math.huge
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player == Player then continue end
        
        -- Team Check
        if AimbotModule.Settings.TeamCheck and player.Team == Player.Team then continue end
        
        -- Alive Check
        if AimbotModule.Settings.AliveCheck and not IsAlive(player) then continue end
        
        local targetPart = GetPart(player, AimbotModule.Settings.TargetPart)
        if not targetPart then continue end
        
        -- Visibility Check
        if AimbotModule.Settings.VisibleCheck and not IsVisible(player, targetPart) then continue end
        
        -- FOV Check
        if AimbotModule.FOV.Enabled then
            local distance = GetDistanceFromMouse(targetPart.Position)
            if distance > AimbotModule.FOV.Radius then continue end
        end
        
        -- Priority System
        local value
        if AimbotModule.Settings.Priority == "Distance" then
            value = GetDistanceFromPlayer(player)
        elseif AimbotModule.Settings.Priority == "Health" then
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
            value = humanoid and humanoid.Health or math.huge
        elseif AimbotModule.Settings.Priority == "Crosshair" then
            value = GetDistanceFromMouse(targetPart.Position)
        end
        
        if value < bestValue then
            bestValue = value
            bestTarget = player
        end
    end
    
    return bestTarget
end

-- ═══════════════════════════════════════════════════════════
--  AIMING
-- ═══════════════════════════════════════════════════════════
local function AimAt(targetPart)
    if not targetPart then return end
    
    local targetPos = AimbotModule.Settings.PredictionEnabled and 
                     PredictPosition(targetPart, AimbotModule.Settings.PredictionAmount) or 
                     targetPart.Position
    
    if AimbotModule.Settings.ThirdPerson and mousemoverel then
        -- Third Person Aiming (mouse movement)
        local screenPos, onScreen = WorldToScreen(targetPos)
        if not onScreen then return end
        
        local mousePos = GetMousePosition()
        local delta = (screenPos - mousePos) * AimbotModule.Settings.ThirdPersonSensitivity
        
        mousemoverel(delta.X, delta.Y)
    else
        -- First Person Aiming (camera CFrame)
        local targetCFrame = CFrame.new(Camera.CFrame.Position, targetPos)
        
        if AimbotModule.Settings.Smoothing > 0 then
            local tween = TweenService:Create(
                Camera,
                TweenInfo.new(AimbotModule.Settings.Smoothing, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
                {CFrame = targetCFrame}
            )
            tween:Play()
        else
            Camera.CFrame = targetCFrame
        end
    end
end

-- ═══════════════════════════════════════════════════════════
--  MAIN LOOP
-- ═══════════════════════════════════════════════════════════
local function Update()
    UpdateFOVCircle()
    
    if not AimbotModule.Settings.Enabled or not Running then
        Locked = nil
        return
    end
    
    -- Update target
    if not Locked or not AimbotModule.Settings.StickyLock then
        Locked = GetBestTarget()
    end
    
    -- Check if locked target is still valid
    if Locked then
        if AimbotModule.Settings.AliveCheck and not IsAlive(Locked) then
            Locked = nil
            return
        end
        
        if AimbotModule.Settings.TeamCheck and Locked.Team == Player.Team then
            Locked = nil
            return
        end
        
        local targetPart = GetPart(Locked, AimbotModule.Settings.TargetPart)
        if not targetPart then
            Locked = nil
            return
        end
        
        -- Aim at target
        AimAt(targetPart)
    end
end

-- ═══════════════════════════════════════════════════════════
--  INPUT HANDLING
-- ═══════════════════════════════════════════════════════════
local function OnInputBegan(input, gameProcessed)
    if gameProcessed or Typing then return end
    
    if input.UserInputType == AimbotModule.Settings.TriggerKey or 
       (input.KeyCode and input.KeyCode == AimbotModule.Settings.TriggerKey) then
        if AimbotModule.Settings.ToggleMode then
            Running = not Running
        else
            Running = true
        end
        
        if Running and getgenv().firehook then
            getgenv().firehook("AimbotActivated")
        end
    end
end

local function OnInputEnded(input, gameProcessed)
    if gameProcessed or Typing then return end
    
    if not AimbotModule.Settings.ToggleMode then
        if input.UserInputType == AimbotModule.Settings.TriggerKey or 
           (input.KeyCode and input.KeyCode == AimbotModule.Settings.TriggerKey) then
            Running = false
            Locked = nil
            
            if getgenv().firehook then
                getgenv().firehook("AimbotDeactivated")
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════
--  TYPING DETECTION
-- ═══════════════════════════════════════════════════════════
UserInputService.TextBoxFocused:Connect(function()
    Typing = true
end)

UserInputService.TextBoxFocusReleased:Connect(function()
    Typing = false
end)

-- ═══════════════════════════════════════════════════════════
--  PUBLIC FUNCTIONS
-- ═══════════════════════════════════════════════════════════
function AimbotModule:Init()
    InitFOVCircle()
    
    Connections.RenderStepped = RunService.RenderStepped:Connect(Update)
    Connections.InputBegan = UserInputService.InputBegan:Connect(OnInputBegan)
    Connections.InputEnded = UserInputService.InputEnded:Connect(OnInputEnded)
    
    print("[DarpaHub Aimbot] Módulo inicializado")
    
    if getgenv().firehook then
        getgenv().firehook("AimbotInitialized")
    end
end

function AimbotModule:Disable()
    Running = false
    Locked = nil
    
    for _, connection in pairs(Connections) do
        connection:Disconnect()
    end
    
    if FOVCircle then
        FOVCircle:Remove()
    end
    
    print("[DarpaHub Aimbot] Módulo desativado")
    
    if getgenv().firehook then
        getgenv().firehook("AimbotDisabled")
    end
end

function AimbotModule:GetLockedTarget()
    return Locked
end

function AimbotModule:ForceUnlock()
    Locked = nil
end

function AimbotModule:IsRunning()
    return Running
end

-- ═══════════════════════════════════════════════════════════
--  EXPORT
-- ═══════════════════════════════════════════════════════════
return AimbotModule
