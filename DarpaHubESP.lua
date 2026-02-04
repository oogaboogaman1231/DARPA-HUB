--[[
    ╔═══════════════════════════════════════════════════════════╗
    ║          DARPA HUB - ESP/WALL HACK MODULE v7.5            ║
    ║     Premium ESP com Boxes, Tracers, Names, Health         ║
    ╚═══════════════════════════════════════════════════════════╝
]]

local ESPModule = {}

-- Services
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Player = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- Variables
local PlayerESPs = {}
local Connections = {}

-- ═══════════════════════════════════════════════════════════
--  ESP SETTINGS
-- ═══════════════════════════════════════════════════════════
ESPModule.Settings = {
    Enabled = false,
    TeamCheck = false,
    AliveCheck = true,
    MaxDistance = 5000,
    
    -- Team Colors
    UseTeamColor = true,
    TeamColor = Color3.fromRGB(0, 255, 0),
    EnemyColor = Color3.fromRGB(255, 0, 0),
}

-- Box Settings
ESPModule.Boxes = {
    Enabled = true,
    Type = "2D", -- 2D ou 3D
    Color = Color3.fromRGB(255, 255, 255),
    Thickness = 2,
    Transparency = 1,
    Filled = false,
    FilledTransparency = 0.1,
}

-- Tracer Settings
ESPModule.Tracers = {
    Enabled = true,
    From = "Bottom", -- Bottom, Center, Mouse
    Color = Color3.fromRGB(255, 255, 255),
    Thickness = 1,
    Transparency = 1,
}

-- Name Settings  
ESPModule.Names = {
    Enabled = true,
    Color = Color3.fromRGB(255, 255, 255),
    Size = 16,
    Font = Drawing.Fonts and Drawing.Fonts.UI or 0,
    Outline = true,
    OutlineColor = Color3.fromRGB(0, 0, 0),
    ShowDistance = true,
    ShowHealth = true,
}

-- Health Bar Settings
ESPModule.HealthBar = {
    Enabled = true,
    Position = "Left", -- Left, Right, Top, Bottom
    Size = 4,
    Offset = 4,
    Background = true,
    BackgroundColor = Color3.fromRGB(0, 0, 0),
    HealthyColor = Color3.fromRGB(0, 255, 0),
    DamagedColor = Color3.fromRGB(255, 255, 0),
    CriticalColor = Color3.fromRGB(255, 0, 0),
}

-- Head Dot Settings
ESPModule.HeadDots = {
    Enabled = false,
    Color = Color3.fromRGB(255, 255, 255),
    Size = 8,
    Filled = true,
    Transparency = 1,
}

-- Chams Settings
ESPModule.Chams = {
    Enabled = false,
    Color = Color3.fromRGB(255, 100, 255),
    Transparency = 0.3,
    VisibleOnly = false,
}

-- ═══════════════════════════════════════════════════════════
--  UTILITY FUNCTIONS
-- ═══════════════════════════════════════════════════════════
local function WorldToScreen(position)
    local vector, onScreen = Camera:WorldToViewportPoint(position)
    return Vector2.new(vector.X, vector.Y), onScreen
end

local function GetDistance(player)
    local char = player.Character
    if not char then return math.huge end
    
    local root = char:FindFirstChild("HumanoidRootPart")
    local myChar = Player.Character
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
    
    if not root or not myRoot then return math.huge end
    
    return (root.Position - myRoot.Position).Magnitude
end

local function IsAlive(player)
    if not player or not player.Character then return false end
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    return humanoid and humanoid.Health > 0
end

local function GetHealth(player)
    local char = player.Character
    if not char then return 0, 100 end
    
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return 0, 100 end
    
    return humanoid.Health, humanoid.MaxHealth
end

local function GetESPColor(player)
    if ESPModule.Settings.UseTeamColor then
        if player.Team == Player.Team then
            return ESPModule.Settings.TeamColor
        else
            return ESPModule.Settings.EnemyColor
        end
    end
    
    return ESPModule.Boxes.Color
end

-- ═══════════════════════════════════════════════════════════
--  ESP OBJECT CLASS
-- ═══════════════════════════════════════════════════════════
local ESP = {}
ESP.__index = ESP

function ESP.new(player)
    local self = setmetatable({}, ESP)
    self.Player = player
    self.Drawings = {}
    
    if not Drawing then
        warn("[DarpaHub ESP] Drawing library não disponível")
        return self
    end
    
    -- Box
    self.Drawings.Box = {
        TopLeft = Drawing.new("Line"),
        TopRight = Drawing.new("Line"),
        BottomLeft = Drawing.new("Line"),
        BottomRight = Drawing.new("Line"),
        Filled = Drawing.new("Square"),
    }
    
    -- Tracer
    self.Drawings.Tracer = Drawing.new("Line")
    
    -- Name
    self.Drawings.Name = Drawing.new("Text")
    
    -- Health Bar
    self.Drawings.HealthBar = {
        Background = Drawing.new("Square"),
        Bar = Drawing.new("Square"),
    }
    
    -- Head Dot
    self.Drawings.HeadDot = Drawing.new("Circle")
    
    -- Chams
    self.Chams = nil
    
    return self
end

function ESP:UpdateBox()
    if not ESPModule.Boxes.Enabled or not self.Player.Character then
        self:HideBox()
        return
    end
    
    local char = self.Player.Character
    local root = char:FindFirstChild("HumanoidRootPart")
    
    if not root then
        self:HideBox()
        return
    end
    
    -- Calcular bounds 2D
    local rootPos = root.Position
    local headPos = rootPos + Vector3.new(0, 2, 0)
    local feetPos = rootPos - Vector3.new(0, 3, 0)
    
    local topPos, topOnScreen = WorldToScreen(headPos)
    local bottomPos, bottomOnScreen = WorldToScreen(feetPos)
    
    if not topOnScreen or not bottomOnScreen then
        self:HideBox()
        return
    end
    
    local height = math.abs(topPos.Y - bottomPos.Y)
    local width = height * 0.5
    
    local x = topPos.X - width / 2
    local y = topPos.Y
    
    local color = GetESPColor(self.Player)
    
    -- Box lines
    for name, line in pairs(self.Drawings.Box) do
        if name ~= "Filled" then
            line.Color = color
            line.Thickness = ESPModule.Boxes.Thickness
            line.Transparency = ESPModule.Boxes.Transparency
            line.Visible = true
        end
    end
    
    self.Drawings.Box.TopLeft.From = Vector2.new(x, y)
    self.Drawings.Box.TopLeft.To = Vector2.new(x + width, y)
    
    self.Drawings.Box.TopRight.From = Vector2.new(x + width, y)
    self.Drawings.Box.TopRight.To = Vector2.new(x + width, y + height)
    
    self.Drawings.Box.BottomRight.From = Vector2.new(x + width, y + height)
    self.Drawings.Box.BottomRight.To = Vector2.new(x, y + height)
    
    self.Drawings.Box.BottomLeft.From = Vector2.new(x, y + height)
    self.Drawings.Box.BottomLeft.To = Vector2.new(x, y)
    
    -- Filled box
    if ESPModule.Boxes.Filled then
        self.Drawings.Box.Filled.Position = Vector2.new(x, y)
        self.Drawings.Box.Filled.Size = Vector2.new(width, height)
        self.Drawings.Box.Filled.Color = color
        self.Drawings.Box.Filled.Transparency = ESPModule.Boxes.FilledTransparency
        self.Drawings.Box.Filled.Filled = true
        self.Drawings.Box.Filled.Visible = true
    else
        self.Drawings.Box.Filled.Visible = false
    end
    
    -- Salvar dimensões para outros elementos
    self.BoxBounds = {
        X = x,
        Y = y,
        Width = width,
        Height = height
    }
end

function ESP:HideBox()
    for _, line in pairs(self.Drawings.Box) do
        line.Visible = false
    end
end

function ESP:UpdateTracer()
    if not ESPModule.Tracers.Enabled or not self.Player.Character then
        self.Drawings.Tracer.Visible = false
        return
    end
    
    local char = self.Player.Character
    local root = char:FindFirstChild("HumanoidRootPart")
    
    if not root then
        self.Drawings.Tracer.Visible = false
        return
    end
    
    local rootPos, onScreen = WorldToScreen(root.Position)
    
    if not onScreen then
        self.Drawings.Tracer.Visible = false
        return
    end
    
    local fromPos
    if ESPModule.Tracers.From == "Bottom" then
        fromPos = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
    elseif ESPModule.Tracers.From == "Center" then
        fromPos = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    elseif ESPModule.Tracers.From == "Mouse" then
        local mouse = game:GetService("UserInputService"):GetMouseLocation()
        fromPos = mouse
    end
    
    self.Drawings.Tracer.From = fromPos
    self.Drawings.Tracer.To = rootPos
    self.Drawings.Tracer.Color = GetESPColor(self.Player)
    self.Drawings.Tracer.Thickness = ESPModule.Tracers.Thickness
    self.Drawings.Tracer.Transparency = ESPModule.Tracers.Transparency
    self.Drawings.Tracer.Visible = true
end

function ESP:UpdateName()
    if not ESPModule.Names.Enabled or not self.Player.Character or not self.BoxBounds then
        self.Drawings.Name.Visible = false
        return
    end
    
    local text = self.Player.Name
    
    if ESPModule.Names.ShowDistance then
        local distance = math.floor(GetDistance(self.Player))
        text = text .. " [" .. distance .. "m]"
    end
    
    if ESPModule.Names.ShowHealth then
        local health, maxHealth = GetHealth(self.Player)
        text = text .. " [" .. math.floor(health) .. "/" .. math.floor(maxHealth) .. "]"
    end
    
    self.Drawings.Name.Text = text
    self.Drawings.Name.Size = ESPModule.Names.Size
    self.Drawings.Name.Color = ESPModule.Names.Color
    self.Drawings.Name.Center = true
    self.Drawings.Name.Outline = ESPModule.Names.Outline
    self.Drawings.Name.OutlineColor = ESPModule.Names.OutlineColor
    self.Drawings.Name.Font = ESPModule.Names.Font
    self.Drawings.Name.Position = Vector2.new(
        self.BoxBounds.X + self.BoxBounds.Width / 2,
        self.BoxBounds.Y - 20
    )
    self.Drawings.Name.Visible = true
end

function ESP:UpdateHealthBar()
    if not ESPModule.HealthBar.Enabled or not self.Player.Character or not self.BoxBounds then
        self.Drawings.HealthBar.Background.Visible = false
        self.Drawings.HealthBar.Bar.Visible = false
        return
    end
    
    local health, maxHealth = GetHealth(self.Player)
    local healthPercent = health / maxHealth
    
    -- Determinar cor baseado na saúde
    local color
    if healthPercent > 0.6 then
        color = ESPModule.HealthBar.HealthyColor
    elseif healthPercent > 0.3 then
        color = ESPModule.HealthBar.DamagedColor
    else
        color = ESPModule.HealthBar.CriticalColor
    end
    
    local x, y, width, height = self.BoxBounds.X, self.BoxBounds.Y, self.BoxBounds.Width, self.BoxBounds.Height
    local barSize = ESPModule.HealthBar.Size
    local offset = ESPModule.HealthBar.Offset
    
    if ESPModule.HealthBar.Position == "Left" then
        -- Background
        self.Drawings.HealthBar.Background.Position = Vector2.new(x - offset - barSize, y)
        self.Drawings.HealthBar.Background.Size = Vector2.new(barSize, height)
        self.Drawings.HealthBar.Background.Color = ESPModule.HealthBar.BackgroundColor
        self.Drawings.HealthBar.Background.Filled = true
        self.Drawings.HealthBar.Background.Visible = ESPModule.HealthBar.Background
        
        -- Health bar
        local barHeight = height * healthPercent
        self.Drawings.HealthBar.Bar.Position = Vector2.new(x - offset - barSize, y + height - barHeight)
        self.Drawings.HealthBar.Bar.Size = Vector2.new(barSize, barHeight)
        self.Drawings.HealthBar.Bar.Color = color
        self.Drawings.HealthBar.Bar.Filled = true
        self.Drawings.HealthBar.Bar.Visible = true
    elseif ESPModule.HealthBar.Position == "Right" then
        -- Background
        self.Drawings.HealthBar.Background.Position = Vector2.new(x + width + offset, y)
        self.Drawings.HealthBar.Background.Size = Vector2.new(barSize, height)
        self.Drawings.HealthBar.Background.Color = ESPModule.HealthBar.BackgroundColor
        self.Drawings.HealthBar.Background.Filled = true
        self.Drawings.HealthBar.Background.Visible = ESPModule.HealthBar.Background
        
        -- Health bar
        local barHeight = height * healthPercent
        self.Drawings.HealthBar.Bar.Position = Vector2.new(x + width + offset, y + height - barHeight)
        self.Drawings.HealthBar.Bar.Size = Vector2.new(barSize, barHeight)
        self.Drawings.HealthBar.Bar.Color = color
        self.Drawings.HealthBar.Bar.Filled = true
        self.Drawings.HealthBar.Bar.Visible = true
    end
end

function ESP:UpdateHeadDot()
    if not ESPModule.HeadDots.Enabled or not self.Player.Character then
        self.Drawings.HeadDot.Visible = false
        return
    end
    
    local char = self.Player.Character
    local head = char:FindFirstChild("Head")
    
    if not head then
        self.Drawings.HeadDot.Visible = false
        return
    end
    
    local headPos, onScreen = WorldToScreen(head.Position)
    
    if not onScreen then
        self.Drawings.HeadDot.Visible = false
        return
    end
    
    self.Drawings.HeadDot.Position = headPos
    self.Drawings.HeadDot.Radius = ESPModule.HeadDots.Size
    self.Drawings.HeadDot.Color = ESPModule.HeadDots.Color
    self.Drawings.HeadDot.Filled = ESPModule.HeadDots.Filled
    self.Drawings.HeadDot.Transparency = ESPModule.HeadDots.Transparency
    self.Drawings.HeadDot.Visible = true
end

function ESP:UpdateChams()
    if not ESPModule.Chams.Enabled then
        if self.Chams then
            self.Chams:Destroy()
            self.Chams = nil
        end
        return
    end
    
    local char = self.Player.Character
    if not char then return end
    
    if not self.Chams then
        self.Chams = Instance.new("Highlight")
        self.Chams.Parent = char
    end
    
    self.Chams.FillColor = ESPModule.Chams.Color
    self.Chams.FillTransparency = ESPModule.Chams.Transparency
    self.Chams.OutlineTransparency = 1
    self.Chams.DepthMode = ESPModule.Chams.VisibleOnly and Enum.HighlightDepthMode.Occluded or Enum.HighlightDepthMode.AlwaysOnTop
end

function ESP:Update()
    if not ESPModule.Settings.Enabled then
        self:Hide()
        return
    end
    
    -- Checks
    if ESPModule.Settings.TeamCheck and self.Player.Team == Player.Team then
        self:Hide()
        return
    end
    
    if ESPModule.Settings.AliveCheck and not IsAlive(self.Player) then
        self:Hide()
        return
    end
    
    local distance = GetDistance(self.Player)
    if distance > ESPModule.Settings.MaxDistance then
        self:Hide()
        return
    end
    
    -- Update all elements
    self:UpdateBox()
    self:UpdateTracer()
    self:UpdateName()
    self:UpdateHealthBar()
    self:UpdateHeadDot()
    self:UpdateChams()
end

function ESP:Hide()
    self:HideBox()
    self.Drawings.Tracer.Visible = false
    self.Drawings.Name.Visible = false
    self.Drawings.HealthBar.Background.Visible = false
    self.Drawings.HealthBar.Bar.Visible = false
    self.Drawings.HeadDot.Visible = false
    
    if self.Chams then
        self.Chams:Destroy()
        self.Chams = nil
    end
end

function ESP:Destroy()
    for _, drawing in pairs(self.Drawings) do
        if type(drawing) == "table" then
            for _, d in pairs(drawing) do
                d:Remove()
            end
        else
            drawing:Remove()
        end
    end
    
    if self.Chams then
        self.Chams:Destroy()
    end
end

-- ═══════════════════════════════════════════════════════════
--  PLAYER MANAGEMENT
-- ═══════════════════════════════════════════════════════════
local function AddPlayer(player)
    if player == Player then return end
    
    PlayerESPs[player] = ESP.new(player)
end

local function RemovePlayer(player)
    if PlayerESPs[player] then
        PlayerESPs[player]:Destroy()
        PlayerESPs[player] = nil
    end
end

-- ═══════════════════════════════════════════════════════════
--  PUBLIC FUNCTIONS
-- ═══════════════════════════════════════════════════════════
function ESPModule:Init()
    -- Add existing players
    for _, player in ipairs(Players:GetPlayers()) do
        AddPlayer(player)
    end
    
    -- Player added/removed
    Connections.PlayerAdded = Players.PlayerAdded:Connect(AddPlayer)
    Connections.PlayerRemoving = Players.PlayerRemoving:Connect(RemovePlayer)
    
    -- Update loop
    Connections.RenderStepped = RunService.RenderStepped:Connect(function()
        for _, esp in pairs(PlayerESPs) do
            esp:Update()
        end
    end)
    
    print("[DarpaHub ESP] Módulo inicializado")
    
    if getgenv().firehook then
        getgenv().firehook("ESPInitialized")
    end
end

function ESPModule:Disable()
    for _, connection in pairs(Connections) do
        connection:Disconnect()
    end
    
    for _, esp in pairs(PlayerESPs) do
        esp:Destroy()
    end
    
    PlayerESPs = {}
    
    print("[DarpaHub ESP] Módulo desativado")
    
    if getgenv().firehook then
        getgenv().firehook("ESPDisabled")
    end
end

-- ═══════════════════════════════════════════════════════════
--  EXPORT
-- ═══════════════════════════════════════════════════════════
return ESPModule
