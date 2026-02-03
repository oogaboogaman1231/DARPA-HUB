--[[
    ╔═══════════════════════════════════════════════════════════╗
    ║              DARPA HUB UI LIBRARY v7.0                    ║
    ║           Premium Script UI - Production Ready            ║
    ║                                                           ║
    ║  Features:                                                ║
    ║  • Visual moderno e profissional                          ║
    ║  • Sistema de otimização de performance                   ║
    ║  • Suporte completo para hooks (firehook, getgenv)        ║
    ║  • Módulos de utilidades premium                          ║
    ║  • Keybind system                                         ║
    ║  • Notificações customizadas                              ║
    ║  • Drag & Drop fluido                                     ║
    ║                                                           ║
    ╚═══════════════════════════════════════════════════════════╝
]]

local Library = {}
Library.__index = Library

-- ═══════════════════════════════════════════════════════════
--  SERVICES & SETUP
-- ═══════════════════════════════════════════════════════════
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local CoreGui = game:GetService("CoreGui")

local Player = Players.LocalPlayer
local Mouse = Player:GetMouse()

-- ═══════════════════════════════════════════════════════════
--  GLOBAL SETUP (getgenv support)
-- ═══════════════════════════════════════════════════════════
getgenv = getgenv or function() return _G end
getgenv().DarpaHub = getgenv().DarpaHub or {}
getgenv().DarpaHubUI = Library

-- ═══════════════════════════════════════════════════════════
--  PERFORMANCE OPTIMIZER
-- ═══════════════════════════════════════════════════════════
local Optimizer = {
    Enabled = true,
    Cache = {},
    TweenCache = {},
    LastCleanup = tick(),
    CleanupInterval = 30,
    InstancePool = {},
    
    -- Criar instâncias do pool
    GetInstance = function(self, className, parent)
        if not self.Enabled then
            local inst = Instance.new(className)
            if parent then inst.Parent = parent end
            return inst
        end
        
        local poolKey = className
        if not self.InstancePool[poolKey] then
            self.InstancePool[poolKey] = {}
        end
        
        local instance = table.remove(self.InstancePool[poolKey])
        if instance then
            instance.Parent = parent
            return instance
        else
            local inst = Instance.new(className)
            if parent then inst.Parent = parent end
            return inst
        end
    end,
    
    -- Retornar instância ao pool
    ReturnInstance = function(self, instance)
        if not self.Enabled or not instance then return end
        
        local className = instance.ClassName
        if not self.InstancePool[className] then
            self.InstancePool[className] = {}
        end
        
        instance.Parent = nil
        table.insert(self.InstancePool[className], instance)
    end,
    
    -- Cache de tweens
    GetTween = function(self, object, info, props)
        if not self.Enabled then
            return TweenService:Create(object, info, props)
        end
        
        local cacheKey = tostring(object) .. tostring(info) .. tostring(props)
        if self.TweenCache[cacheKey] then
            return self.TweenCache[cacheKey]
        end
        
        local tween = TweenService:Create(object, info, props)
        self.TweenCache[cacheKey] = tween
        return tween
    end,
    
    -- Limpeza automática
    AutoCleanup = function(self)
        if tick() - self.LastCleanup < self.CleanupInterval then return end
        
        -- Limpa cache de tweens antigos
        local cleaned = 0
        for key, tween in pairs(self.TweenCache) do
            if tween.PlaybackState == Enum.PlaybackState.Completed then
                self.TweenCache[key] = nil
                cleaned = cleaned + 1
            end
        end
        
        self.LastCleanup = tick()
        return cleaned
    end
}

-- ═══════════════════════════════════════════════════════════
--  HOOK SYSTEM (firehook support)
-- ═══════════════════════════════════════════════════════════
local HookSystem = {
    Hooks = {},
    
    -- Registrar hook
    Register = function(self, hookName, callback)
        if not self.Hooks[hookName] then
            self.Hooks[hookName] = {}
        end
        table.insert(self.Hooks[hookName], callback)
        return #self.Hooks[hookName]
    end,
    
    -- Executar hook (firehook)
    Fire = function(self, hookName, ...)
        if not self.Hooks[hookName] then return end
        
        for _, callback in ipairs(self.Hooks[hookName]) do
            local success, result = pcall(callback, ...)
            if not success then
                warn("[DarpaHub Hook Error]", hookName, result)
            end
        end
    end,
    
    -- Remover hook
    Remove = function(self, hookName, index)
        if not self.Hooks[hookName] then return end
        table.remove(self.Hooks[hookName], index)
    end,
    
    -- Limpar hooks
    Clear = function(self, hookName)
        if hookName then
            self.Hooks[hookName] = {}
        else
            self.Hooks = {}
        end
    end
}

-- Expor firehook globalmente
getgenv().firehook = function(hookName, ...)
    HookSystem:Fire(hookName, ...)
end

-- ═══════════════════════════════════════════════════════════
--  UTILITY FUNCTIONS
-- ═══════════════════════════════════════════════════════════
local Utils = {
    -- Criar gradiente
    CreateGradient = function(parent, rotation, colorSequence, transparency)
        local gradient = Optimizer:GetInstance("UIGradient", parent)
        gradient.Rotation = rotation or 0
        if colorSequence then gradient.Color = colorSequence end
        if transparency then gradient.Transparency = transparency end
        return gradient
    end,
    
    -- Criar corner
    CreateCorner = function(parent, radius)
        local corner = Optimizer:GetInstance("UICorner", parent)
        corner.CornerRadius = UDim.new(0, radius or 8)
        return corner
    end,
    
    -- Criar stroke
    CreateStroke = function(parent, color, thickness)
        local stroke = Optimizer:GetInstance("UIStroke", parent)
        stroke.Color = color or Color3.fromRGB(255, 255, 255)
        stroke.Thickness = thickness or 1
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        return stroke
    end,
    
    -- Tween suave
    Tween = function(object, duration, properties, style, direction)
        local info = TweenInfo.new(
            duration or 0.3,
            style or Enum.EasingStyle.Quad,
            direction or Enum.EasingDirection.Out
        )
        local tween = Optimizer:GetTween(object, info, properties)
        tween:Play()
        return tween
    end,
    
    -- Criar efeito ripple
    CreateRipple = function(parent, position)
        local ripple = Optimizer:GetInstance("Frame", parent)
        ripple.Size = UDim2.new(0, 0, 0, 0)
        ripple.Position = position or UDim2.new(0.5, 0, 0.5, 0)
        ripple.AnchorPoint = Vector2.new(0.5, 0.5)
        ripple.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        ripple.BackgroundTransparency = 0.5
        ripple.BorderSizePixel = 0
        ripple.ZIndex = 100
        
        Utils.CreateCorner(ripple, 999)
        
        local size = math.max(parent.AbsoluteSize.X, parent.AbsoluteSize.Y) * 2
        Utils.Tween(ripple, 0.5, {
            Size = UDim2.new(0, size, 0, size),
            BackgroundTransparency = 1
        })
        
        task.delay(0.5, function()
            ripple:Destroy()
        end)
    end
}

-- ═══════════════════════════════════════════════════════════
--  TEMA SYSTEM
-- ═══════════════════════════════════════════════════════════
local Theme = {
    Current = {
        -- Background
        Background = Color3.fromRGB(15, 15, 20),
        BackgroundSecondary = Color3.fromRGB(20, 20, 28),
        
        -- Accent
        Accent = Color3.fromRGB(88, 166, 255),
        AccentDark = Color3.fromRGB(65, 140, 230),
        AccentLight = Color3.fromRGB(120, 190, 255),
        
        -- Text
        Text = Color3.fromRGB(240, 240, 245),
        TextMuted = Color3.fromRGB(160, 160, 170),
        TextDark = Color3.fromRGB(100, 100, 110),
        
        -- Elements
        ElementBackground = Color3.fromRGB(25, 25, 35),
        ElementHover = Color3.fromRGB(35, 35, 45),
        ElementActive = Color3.fromRGB(45, 45, 60),
        
        -- Border
        Border = Color3.fromRGB(45, 45, 55),
        BorderAccent = Color3.fromRGB(88, 166, 255),
        
        -- Status
        Success = Color3.fromRGB(80, 200, 120),
        Warning = Color3.fromRGB(255, 180, 60),
        Error = Color3.fromRGB(240, 80, 80),
    }
}

-- ═══════════════════════════════════════════════════════════
--  NOTIFICATION SYSTEM
-- ═══════════════════════════════════════════════════════════
local NotificationContainer

local function CreateNotification(title, description, duration, notifType)
    if not NotificationContainer then
        NotificationContainer = Optimizer:GetInstance("Frame")
        NotificationContainer.Name = "DarpaNotifications"
        NotificationContainer.Size = UDim2.new(0, 300, 1, 0)
        NotificationContainer.Position = UDim2.new(1, -320, 0, 20)
        NotificationContainer.BackgroundTransparency = 1
        NotificationContainer.Parent = CoreGui:FindFirstChild("DarpaHubUI") or Player:WaitForChild("PlayerGui")
        
        local layout = Optimizer:GetInstance("UIListLayout", NotificationContainer)
        layout.Padding = UDim.new(0, 10)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.VerticalAlignment = Enum.VerticalAlignment.Top
    end
    
    local notif = Optimizer:GetInstance("Frame", NotificationContainer)
    notif.Size = UDim2.new(1, 0, 0, 0)
    notif.BackgroundColor3 = Theme.Current.BackgroundSecondary
    notif.BorderSizePixel = 0
    notif.ClipsDescendants = true
    
    Utils.CreateCorner(notif, 8)
    
    -- Cor do tipo
    local typeColor = Theme.Current.Accent
    if notifType == "success" then typeColor = Theme.Current.Success
    elseif notifType == "warning" then typeColor = Theme.Current.Warning
    elseif notifType == "error" then typeColor = Theme.Current.Error
    end
    
    -- Barra lateral
    local sidebar = Optimizer:GetInstance("Frame", notif)
    sidebar.Size = UDim2.new(0, 4, 1, 0)
    sidebar.BackgroundColor3 = typeColor
    sidebar.BorderSizePixel = 0
    
    -- Conteúdo
    local content = Optimizer:GetInstance("Frame", notif)
    content.Size = UDim2.new(1, -14, 1, 0)
    content.Position = UDim2.new(0, 14, 0, 0)
    content.BackgroundTransparency = 1
    
    local titleLabel = Optimizer:GetInstance("TextLabel", content)
    titleLabel.Size = UDim2.new(1, 0, 0, 20)
    titleLabel.Position = UDim2.new(0, 0, 0, 8)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = title
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 14
    titleLabel.TextColor3 = Theme.Current.Text
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    
    local descLabel = Optimizer:GetInstance("TextLabel", content)
    descLabel.Size = UDim2.new(1, 0, 0, 16)
    descLabel.Position = UDim2.new(0, 0, 0, 30)
    descLabel.BackgroundTransparency = 1
    descLabel.Text = description
    descLabel.Font = Enum.Font.Gotham
    descLabel.TextSize = 12
    descLabel.TextColor3 = Theme.Current.TextMuted
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.TextWrapped = true
    
    -- Animar entrada
    local targetHeight = 70
    Utils.Tween(notif, 0.3, {Size = UDim2.new(1, 0, 0, targetHeight)}, Enum.EasingStyle.Back)
    
    -- Remover após duração
    task.delay(duration or 3, function()
        Utils.Tween(notif, 0.3, {
            Size = UDim2.new(1, 0, 0, 0),
            BackgroundTransparency = 1
        })
        task.wait(0.3)
        notif:Destroy()
    end)
    
    -- Fire hook
    HookSystem:Fire("NotificationCreated", title, description, notifType)
end

-- ═══════════════════════════════════════════════════════════
--  KEYBIND SYSTEM
-- ═══════════════════════════════════════════════════════════
local Keybinds = {
    Active = {},
    
    Register = function(self, key, callback, description)
        local keybind = {
            Key = key,
            Callback = callback,
            Description = description or "No description"
        }
        
        self.Active[key.Name] = keybind
        HookSystem:Fire("KeybindRegistered", key.Name, description)
        return keybind
    end,
    
    Remove = function(self, keyName)
        self.Active[keyName] = nil
        HookSystem:Fire("KeybindRemoved", keyName)
    end
}

-- Input handler para keybinds
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    local keybind = Keybinds.Active[input.KeyCode.Name]
    if keybind and keybind.Callback then
        local success, err = pcall(keybind.Callback)
        if not success then
            warn("[DarpaHub Keybind Error]", err)
        end
        HookSystem:Fire("KeybindExecuted", input.KeyCode.Name)
    end
end)

-- ═══════════════════════════════════════════════════════════
--  MAIN WINDOW CLASS
-- ═══════════════════════════════════════════════════════════
function Library:CreateWindow(config)
    local Window = {
        Tabs = {},
        CurrentTab = nil,
        Visible = true,
        Config = config or {}
    }
    
    -- GUI principal
    local ScreenGui = Optimizer:GetInstance("ScreenGui")
    ScreenGui.Name = "DarpaHubUI"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = CoreGui
    
    -- Main container
    local Main = Optimizer:GetInstance("Frame", ScreenGui)
    Main.Name = "Main"
    Main.Size = UDim2.new(0, 650, 0, 450)
    Main.Position = UDim2.new(0.5, -325, 0.5, -225)
    Main.BackgroundColor3 = Theme.Current.Background
    Main.BorderSizePixel = 0
    Main.ClipsDescendants = true
    Main.Active = true
    
    Utils.CreateCorner(Main, 12)
    Utils.CreateStroke(Main, Theme.Current.Border, 1)
    
    -- Shadow effect
    local shadow = Optimizer:GetInstance("ImageLabel", Main)
    shadow.Name = "Shadow"
    shadow.Size = UDim2.new(1, 40, 1, 40)
    shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
    shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://5554236805"
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = 0.7
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(23, 23, 277, 277)
    shadow.ZIndex = -1
    
    -- Top bar
    local TopBar = Optimizer:GetInstance("Frame", Main)
    TopBar.Name = "TopBar"
    TopBar.Size = UDim2.new(1, 0, 0, 50)
    TopBar.BackgroundColor3 = Theme.Current.BackgroundSecondary
    TopBar.BorderSizePixel = 0
    
    Utils.CreateCorner(TopBar, 12)
    
    -- Gradient no top bar
    Utils.CreateGradient(TopBar, 90, ColorSequence.new{
        ColorSequenceKeypoint.new(0, Theme.Current.AccentDark),
        ColorSequenceKeypoint.new(1, Theme.Current.Accent)
    })
    
    -- Logo/Title
    local Title = Optimizer:GetInstance("TextLabel", TopBar)
    Title.Name = "Title"
    Title.Size = UDim2.new(0, 200, 1, 0)
    Title.Position = UDim2.new(0, 20, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = config.Title or "DARPA HUB"
    Title.Font = Enum.Font.GothamBold
    Title.TextSize = 18
    Title.TextColor3 = Theme.Current.Text
    Title.TextXAlignment = Enum.TextXAlignment.Left
    
    -- Subtitle
    local Subtitle = Optimizer:GetInstance("TextLabel", TopBar)
    Subtitle.Name = "Subtitle"
    Subtitle.Size = UDim2.new(0, 200, 0, 15)
    Subtitle.Position = UDim2.new(0, 20, 0, 28)
    Subtitle.BackgroundTransparency = 1
    Subtitle.Text = config.Subtitle or "Premium Script UI v7.0"
    Subtitle.Font = Enum.Font.Gotham
    Subtitle.TextSize = 11
    Subtitle.TextColor3 = Theme.Current.TextMuted
    Subtitle.TextXAlignment = Enum.TextXAlignment.Left
    Subtitle.TextTransparency = 0.3
    
    -- Close button
    local CloseBtn = Optimizer:GetInstance("TextButton", TopBar)
    CloseBtn.Name = "CloseBtn"
    CloseBtn.Size = UDim2.new(0, 35, 0, 35)
    CloseBtn.Position = UDim2.new(1, -45, 0.5, -17.5)
    CloseBtn.BackgroundColor3 = Theme.Current.Error
    CloseBtn.Text = "✕"
    CloseBtn.Font = Enum.Font.GothamBold
    CloseBtn.TextSize = 16
    CloseBtn.TextColor3 = Theme.Current.Text
    CloseBtn.BorderSizePixel = 0
    
    Utils.CreateCorner(CloseBtn, 8)
    
    CloseBtn.MouseButton1Click:Connect(function()
        Utils.CreateRipple(CloseBtn, UDim2.new(0.5, 0, 0.5, 0))
        Utils.Tween(Main, 0.3, {Size = UDim2.new(0, 0, 0, 0)}, Enum.EasingStyle.Back, Enum.EasingDirection.In)
        task.wait(0.3)
        ScreenGui:Destroy()
        HookSystem:Fire("WindowClosed")
    end)
    
    -- Minimize button
    local MinBtn = Optimizer:GetInstance("TextButton", TopBar)
    MinBtn.Name = "MinBtn"
    MinBtn.Size = UDim2.new(0, 35, 0, 35)
    MinBtn.Position = UDim2.new(1, -85, 0.5, -17.5)
    MinBtn.BackgroundColor3 = Theme.Current.Warning
    MinBtn.Text = "−"
    MinBtn.Font = Enum.Font.GothamBold
    MinBtn.TextSize = 20
    MinBtn.TextColor3 = Theme.Current.Text
    MinBtn.BorderSizePixel = 0
    
    Utils.CreateCorner(MinBtn, 8)
    
    MinBtn.MouseButton1Click:Connect(function()
        Window.Visible = not Window.Visible
        Utils.CreateRipple(MinBtn, UDim2.new(0.5, 0, 0.5, 0))
        Utils.Tween(Main, 0.3, {Size = Window.Visible and UDim2.new(0, 650, 0, 450) or UDim2.new(0, 650, 0, 50)})
        HookSystem:Fire("WindowMinimized", Window.Visible)
    end)
    
    -- Tab container
    local TabContainer = Optimizer:GetInstance("Frame", Main)
    TabContainer.Name = "TabContainer"
    TabContainer.Size = UDim2.new(0, 150, 1, -60)
    TabContainer.Position = UDim2.new(0, 10, 0, 60)
    TabContainer.BackgroundTransparency = 1
    
    local TabLayout = Optimizer:GetInstance("UIListLayout", TabContainer)
    TabLayout.Padding = UDim.new(0, 5)
    TabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    
    -- Content container
    local ContentContainer = Optimizer:GetInstance("Frame", Main)
    ContentContainer.Name = "ContentContainer"
    ContentContainer.Size = UDim2.new(1, -170, 1, -60)
    ContentContainer.Position = UDim2.new(0, 160, 0, 60)
    ContentContainer.BackgroundColor3 = Theme.Current.BackgroundSecondary
    ContentContainer.BorderSizePixel = 0
    
    Utils.CreateCorner(ContentContainer, 8)
    
    -- Scroll para conteúdo
    local ContentScroll = Optimizer:GetInstance("ScrollingFrame", ContentContainer)
    ContentScroll.Name = "ContentScroll"
    ContentScroll.Size = UDim2.new(1, -10, 1, -10)
    ContentScroll.Position = UDim2.new(0, 5, 0, 5)
    ContentScroll.BackgroundTransparency = 1
    ContentScroll.BorderSizePixel = 0
    ContentScroll.ScrollBarThickness = 4
    ContentScroll.ScrollBarImageColor3 = Theme.Current.Accent
    ContentScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    
    local ContentLayout = Optimizer:GetInstance("UIListLayout", ContentScroll)
    ContentLayout.Padding = UDim.new(0, 8)
    ContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
    
    -- Auto-resize canvas
    ContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        ContentScroll.CanvasSize = UDim2.new(0, 0, 0, ContentLayout.AbsoluteContentSize.Y + 10)
    end)
    
    -- Drag functionality
    local dragging, dragInput, dragStart, startPos
    
    TopBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = Main.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    
    TopBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            Main.Position = UDim2.new(
                startPos.X.Scale,
                startPos.X.Offset + delta.X,
                startPos.Y.Scale,
                startPos.Y.Offset + delta.Y
            )
        end
    end)
    
    -- Animação de entrada
    Main.Size = UDim2.new(0, 0, 0, 0)
    Utils.Tween(Main, 0.5, {Size = UDim2.new(0, 650, 0, 450)}, Enum.EasingStyle.Back)
    
    HookSystem:Fire("WindowCreated", config.Title)
    
    -- ═══════════════════════════════════════════════════════════
    --  TAB FUNCTIONS
    -- ═══════════════════════════════════════════════════════════
    function Window:CreateTab(name, icon)
        local Tab = {
            Name = name,
            Elements = {},
            Active = false
        }
        
        -- Tab button
        local TabBtn = Optimizer:GetInstance("TextButton", TabContainer)
        TabBtn.Name = name
        TabBtn.Size = UDim2.new(1, 0, 0, 40)
        TabBtn.BackgroundColor3 = Theme.Current.ElementBackground
        TabBtn.BorderSizePixel = 0
        TabBtn.Text = (icon or "•") .. " " .. name
        TabBtn.Font = Enum.Font.GothamBold
        TabBtn.TextSize = 13
        TabBtn.TextColor3 = Theme.Current.TextMuted
        TabBtn.TextXAlignment = Enum.TextXAlignment.Left
        TabBtn.TextTruncate = Enum.TextTruncate.AtEnd
        
        local padding = Optimizer:GetInstance("UIPadding", TabBtn)
        padding.PaddingLeft = UDim.new(0, 15)
        
        Utils.CreateCorner(TabBtn, 6)
        
        -- Tab content container
        local TabContent = Optimizer:GetInstance("Frame", ContentScroll)
        TabContent.Name = name .. "Content"
        TabContent.Size = UDim2.new(1, 0, 0, 0)
        TabContent.BackgroundTransparency = 1
        TabContent.Visible = false
        
        local TabContentLayout = Optimizer:GetInstance("UIListLayout", TabContent)
        TabContentLayout.Padding = UDim.new(0, 8)
        TabContentLayout.SortOrder = Enum.SortOrder.LayoutOrder
        
        -- Auto-resize
        TabContentLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            TabContent.Size = UDim2.new(1, 0, 0, TabContentLayout.AbsoluteContentSize.Y)
        end)
        
        -- Click handler
        TabBtn.MouseButton1Click:Connect(function()
            for _, tab in pairs(Window.Tabs) do
                tab.TabBtn.BackgroundColor3 = Theme.Current.ElementBackground
                tab.TabBtn.TextColor3 = Theme.Current.TextMuted
                tab.TabContent.Visible = false
                tab.Active = false
            end
            
            TabBtn.BackgroundColor3 = Theme.Current.Accent
            TabBtn.TextColor3 = Theme.Current.Text
            TabContent.Visible = true
            Tab.Active = true
            Window.CurrentTab = Tab
            
            Utils.CreateRipple(TabBtn, UDim2.new(0.5, 0, 0.5, 0))
            HookSystem:Fire("TabSelected", name)
        end)
        
        -- Hover effects
        TabBtn.MouseEnter:Connect(function()
            if not Tab.Active then
                Utils.Tween(TabBtn, 0.2, {BackgroundColor3 = Theme.Current.ElementHover})
            end
        end)
        
        TabBtn.MouseLeave:Connect(function()
            if not Tab.Active then
                Utils.Tween(TabBtn, 0.2, {BackgroundColor3 = Theme.Current.ElementBackground})
            end
        end)
        
        Tab.TabBtn = TabBtn
        Tab.TabContent = TabContent
        Tab.TabContentLayout = TabContentLayout
        
        table.insert(Window.Tabs, Tab)
        
        -- Ativar primeira tab
        if #Window.Tabs == 1 then
            TabBtn.BackgroundColor3 = Theme.Current.Accent
            TabBtn.TextColor3 = Theme.Current.Text
            TabContent.Visible = true
            Tab.Active = true
            Window.CurrentTab = Tab
        end
        
        -- ═══════════════════════════════════════════════════════════
        --  ELEMENT FUNCTIONS
        -- ═══════════════════════════════════════════════════════════
        
        function Tab:AddLabel(text)
            local Label = Optimizer:GetInstance("TextLabel", TabContent)
            Label.Name = "Label"
            Label.Size = UDim2.new(1, -10, 0, 25)
            Label.BackgroundTransparency = 1
            Label.Text = text
            Label.Font = Enum.Font.Gotham
            Label.TextSize = 13
            Label.TextColor3 = Theme.Current.Text
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.TextWrapped = true
            
            local padding = Optimizer:GetInstance("UIPadding", Label)
            padding.PaddingLeft = UDim.new(0, 10)
            
            table.insert(Tab.Elements, Label)
            HookSystem:Fire("ElementAdded", "Label", text)
            return Label
        end
        
        function Tab:AddButton(text, callback)
            local Button = Optimizer:GetInstance("TextButton", TabContent)
            Button.Name = "Button"
            Button.Size = UDim2.new(1, -10, 0, 40)
            Button.BackgroundColor3 = Theme.Current.ElementBackground
            Button.BorderSizePixel = 0
            Button.Text = text
            Button.Font = Enum.Font.GothamBold
            Button.TextSize = 13
            Button.TextColor3 = Theme.Current.Text
            Button.AutoButtonColor = false
            
            Utils.CreateCorner(Button, 6)
            Utils.CreateStroke(Button, Theme.Current.Border, 1)
            
            Button.MouseButton1Click:Connect(function()
                Utils.CreateRipple(Button, UDim2.new(0.5, 0, 0.5, 0))
                local success, err = pcall(callback)
                if not success then
                    warn("[DarpaHub Button Error]", err)
                end
                HookSystem:Fire("ButtonClicked", text)
            end)
            
            Button.MouseEnter:Connect(function()
                Utils.Tween(Button, 0.2, {BackgroundColor3 = Theme.Current.ElementHover})
            end)
            
            Button.MouseLeave:Connect(function()
                Utils.Tween(Button, 0.2, {BackgroundColor3 = Theme.Current.ElementBackground})
            end)
            
            table.insert(Tab.Elements, Button)
            HookSystem:Fire("ElementAdded", "Button", text)
            return Button
        end
        
        function Tab:AddToggle(text, default, callback)
            local toggled = default or false
            
            local ToggleContainer = Optimizer:GetInstance("Frame", TabContent)
            ToggleContainer.Name = "Toggle"
            ToggleContainer.Size = UDim2.new(1, -10, 0, 45)
            ToggleContainer.BackgroundColor3 = Theme.Current.ElementBackground
            ToggleContainer.BorderSizePixel = 0
            
            Utils.CreateCorner(ToggleContainer, 6)
            Utils.CreateStroke(ToggleContainer, Theme.Current.Border, 1)
            
            local ToggleLabel = Optimizer:GetInstance("TextLabel", ToggleContainer)
            ToggleLabel.Size = UDim2.new(1, -60, 1, 0)
            ToggleLabel.Position = UDim2.new(0, 15, 0, 0)
            ToggleLabel.BackgroundTransparency = 1
            ToggleLabel.Text = text
            ToggleLabel.Font = Enum.Font.Gotham
            ToggleLabel.TextSize = 13
            ToggleLabel.TextColor3 = Theme.Current.Text
            ToggleLabel.TextXAlignment = Enum.TextXAlignment.Left
            ToggleLabel.TextWrapped = true
            
            local ToggleBtn = Optimizer:GetInstance("TextButton", ToggleContainer)
            ToggleBtn.Size = UDim2.new(0, 45, 0, 25)
            ToggleBtn.Position = UDim2.new(1, -55, 0.5, -12.5)
            ToggleBtn.BackgroundColor3 = toggled and Theme.Current.Accent or Theme.Current.Border
            ToggleBtn.BorderSizePixel = 0
            ToggleBtn.Text = ""
            ToggleBtn.AutoButtonColor = false
            
            Utils.CreateCorner(ToggleBtn, 12)
            
            local ToggleIndicator = Optimizer:GetInstance("Frame", ToggleBtn)
            ToggleIndicator.Size = UDim2.new(0, 19, 0, 19)
            ToggleIndicator.Position = toggled and UDim2.new(1, -22, 0.5, -9.5) or UDim2.new(0, 3, 0.5, -9.5)
            ToggleIndicator.BackgroundColor3 = Theme.Current.Text
            ToggleIndicator.BorderSizePixel = 0
            
            Utils.CreateCorner(ToggleIndicator, 10)
            
            local function Toggle()
                toggled = not toggled
                
                Utils.Tween(ToggleBtn, 0.2, {
                    BackgroundColor3 = toggled and Theme.Current.Accent or Theme.Current.Border
                })
                
                Utils.Tween(ToggleIndicator, 0.2, {
                    Position = toggled and UDim2.new(1, -22, 0.5, -9.5) or UDim2.new(0, 3, 0.5, -9.5)
                })
                
                local success, err = pcall(callback, toggled)
                if not success then
                    warn("[DarpaHub Toggle Error]", err)
                end
                HookSystem:Fire("ToggleChanged", text, toggled)
            end
            
            ToggleBtn.MouseButton1Click:Connect(Toggle)
            
            ToggleContainer.MouseEnter:Connect(function()
                Utils.Tween(ToggleContainer, 0.2, {BackgroundColor3 = Theme.Current.ElementHover})
            end)
            
            ToggleContainer.MouseLeave:Connect(function()
                Utils.Tween(ToggleContainer, 0.2, {BackgroundColor3 = Theme.Current.ElementBackground})
            end)
            
            table.insert(Tab.Elements, ToggleContainer)
            HookSystem:Fire("ElementAdded", "Toggle", text)
            
            return {
                Toggle = Toggle,
                GetState = function() return toggled end,
                SetState = function(state)
                    if state ~= toggled then Toggle() end
                end
            }
        end
        
        function Tab:AddSlider(text, min, max, default, callback)
            local value = default or min
            
            local SliderContainer = Optimizer:GetInstance("Frame", TabContent)
            SliderContainer.Name = "Slider"
            SliderContainer.Size = UDim2.new(1, -10, 0, 60)
            SliderContainer.BackgroundColor3 = Theme.Current.ElementBackground
            SliderContainer.BorderSizePixel = 0
            
            Utils.CreateCorner(SliderContainer, 6)
            Utils.CreateStroke(SliderContainer, Theme.Current.Border, 1)
            
            local SliderLabel = Optimizer:GetInstance("TextLabel", SliderContainer)
            SliderLabel.Size = UDim2.new(1, -20, 0, 20)
            SliderLabel.Position = UDim2.new(0, 10, 0, 8)
            SliderLabel.BackgroundTransparency = 1
            SliderLabel.Text = text
            SliderLabel.Font = Enum.Font.Gotham
            SliderLabel.TextSize = 13
            SliderLabel.TextColor3 = Theme.Current.Text
            SliderLabel.TextXAlignment = Enum.TextXAlignment.Left
            
            local SliderValue = Optimizer:GetInstance("TextLabel", SliderContainer)
            SliderValue.Size = UDim2.new(0, 50, 0, 20)
            SliderValue.Position = UDim2.new(1, -60, 0, 8)
            SliderValue.BackgroundTransparency = 1
            SliderValue.Text = tostring(value)
            SliderValue.Font = Enum.Font.GothamBold
            SliderValue.TextSize = 13
            SliderValue.TextColor3 = Theme.Current.Accent
            SliderValue.TextXAlignment = Enum.TextXAlignment.Right
            
            local SliderBack = Optimizer:GetInstance("Frame", SliderContainer)
            SliderBack.Size = UDim2.new(1, -20, 0, 6)
            SliderBack.Position = UDim2.new(0, 10, 1, -18)
            SliderBack.BackgroundColor3 = Theme.Current.Border
            SliderBack.BorderSizePixel = 0
            
            Utils.CreateCorner(SliderBack, 3)
            
            local SliderFill = Optimizer:GetInstance("Frame", SliderBack)
            SliderFill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
            SliderFill.BackgroundColor3 = Theme.Current.Accent
            SliderFill.BorderSizePixel = 0
            
            Utils.CreateCorner(SliderFill, 3)
            
            local dragging = false
            
            local function UpdateSlider(input)
                local pos = (input.Position.X - SliderBack.AbsolutePosition.X) / SliderBack.AbsoluteSize.X
                pos = math.clamp(pos, 0, 1)
                value = math.floor(min + (max - min) * pos)
                
                SliderValue.Text = tostring(value)
                Utils.Tween(SliderFill, 0.1, {Size = UDim2.new(pos, 0, 1, 0)})
                
                local success, err = pcall(callback, value)
                if not success then
                    warn("[DarpaHub Slider Error]", err)
                end
                HookSystem:Fire("SliderChanged", text, value)
            end
            
            SliderBack.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = true
                    UpdateSlider(input)
                end
            end)
            
            SliderBack.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    dragging = false
                end
            end)
            
            UserInputService.InputChanged:Connect(function(input)
                if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                    UpdateSlider(input)
                end
            end)
            
            table.insert(Tab.Elements, SliderContainer)
            HookSystem:Fire("ElementAdded", "Slider", text)
            
            return {
                GetValue = function() return value end,
                SetValue = function(newValue)
                    value = math.clamp(newValue, min, max)
                    SliderValue.Text = tostring(value)
                    local pos = (value - min) / (max - min)
                    Utils.Tween(SliderFill, 0.2, {Size = UDim2.new(pos, 0, 1, 0)})
                end
            }
        end
        
        function Tab:AddDropdown(text, options, default, callback)
            local selected = default or options[1]
            local open = false
            
            local DropdownContainer = Optimizer:GetInstance("Frame", TabContent)
            DropdownContainer.Name = "Dropdown"
            DropdownContainer.Size = UDim2.new(1, -10, 0, 45)
            DropdownContainer.BackgroundColor3 = Theme.Current.ElementBackground
            DropdownContainer.BorderSizePixel = 0
            DropdownContainer.ClipsDescendants = false
            DropdownContainer.ZIndex = 2
            
            Utils.CreateCorner(DropdownContainer, 6)
            Utils.CreateStroke(DropdownContainer, Theme.Current.Border, 1)
            
            local DropdownLabel = Optimizer:GetInstance("TextLabel", DropdownContainer)
            DropdownLabel.Size = UDim2.new(1, -80, 1, 0)
            DropdownLabel.Position = UDim2.new(0, 15, 0, 0)
            DropdownLabel.BackgroundTransparency = 1
            DropdownLabel.Text = text
            DropdownLabel.Font = Enum.Font.Gotham
            DropdownLabel.TextSize = 13
            DropdownLabel.TextColor3 = Theme.Current.Text
            DropdownLabel.TextXAlignment = Enum.TextXAlignment.Left
            
            local DropdownBtn = Optimizer:GetInstance("TextButton", DropdownContainer)
            DropdownBtn.Size = UDim2.new(0, 120, 0, 30)
            DropdownBtn.Position = UDim2.new(1, -130, 0.5, -15)
            DropdownBtn.BackgroundColor3 = Theme.Current.ElementHover
            DropdownBtn.BorderSizePixel = 0
            DropdownBtn.Text = selected
            DropdownBtn.Font = Enum.Font.Gotham
            DropdownBtn.TextSize = 12
            DropdownBtn.TextColor3 = Theme.Current.Text
            DropdownBtn.AutoButtonColor = false
            DropdownBtn.TextTruncate = Enum.TextTruncate.AtEnd
            
            Utils.CreateCorner(DropdownBtn, 5)
            
            local DropdownIcon = Optimizer:GetInstance("TextLabel", DropdownBtn)
            DropdownIcon.Size = UDim2.new(0, 20, 1, 0)
            DropdownIcon.Position = UDim2.new(1, -20, 0, 0)
            DropdownIcon.BackgroundTransparency = 1
            DropdownIcon.Text = "▼"
            DropdownIcon.Font = Enum.Font.Gotham
            DropdownIcon.TextSize = 10
            DropdownIcon.TextColor3 = Theme.Current.TextMuted
            
            local DropdownList = Optimizer:GetInstance("Frame", DropdownContainer)
            DropdownList.Size = UDim2.new(0, 120, 0, 0)
            DropdownList.Position = UDim2.new(1, -130, 1, 5)
            DropdownList.BackgroundColor3 = Theme.Current.BackgroundSecondary
            DropdownList.BorderSizePixel = 0
            DropdownList.Visible = false
            DropdownList.ClipsDescendants = true
            DropdownList.ZIndex = 3
            
            Utils.CreateCorner(DropdownList, 5)
            Utils.CreateStroke(DropdownList, Theme.Current.Border, 1)
            
            local DropdownListLayout = Optimizer:GetInstance("UIListLayout", DropdownList)
            DropdownListLayout.Padding = UDim.new(0, 2)
            DropdownListLayout.SortOrder = Enum.SortOrder.LayoutOrder
            
            for _, option in ipairs(options) do
                local OptionBtn = Optimizer:GetInstance("TextButton", DropdownList)
                OptionBtn.Size = UDim2.new(1, 0, 0, 30)
                OptionBtn.BackgroundColor3 = Theme.Current.ElementBackground
                OptionBtn.BorderSizePixel = 0
                OptionBtn.Text = option
                OptionBtn.Font = Enum.Font.Gotham
                OptionBtn.TextSize = 12
                OptionBtn.TextColor3 = Theme.Current.Text
                OptionBtn.AutoButtonColor = false
                OptionBtn.ZIndex = 3
                
                OptionBtn.MouseButton1Click:Connect(function()
                    selected = option
                    DropdownBtn.Text = option
                    open = false
                    Utils.Tween(DropdownList, 0.2, {Size = UDim2.new(0, 120, 0, 0)})
                    Utils.Tween(DropdownIcon, 0.2, {Rotation = 0})
                    task.wait(0.2)
                    DropdownList.Visible = false
                    
                    local success, err = pcall(callback, option)
                    if not success then
                        warn("[DarpaHub Dropdown Error]", err)
                    end
                    HookSystem:Fire("DropdownChanged", text, option)
                end)
                
                OptionBtn.MouseEnter:Connect(function()
                    Utils.Tween(OptionBtn, 0.1, {BackgroundColor3 = Theme.Current.ElementHover})
                end)
                
                OptionBtn.MouseLeave:Connect(function()
                    Utils.Tween(OptionBtn, 0.1, {BackgroundColor3 = Theme.Current.ElementBackground})
                end)
            end
            
            DropdownBtn.MouseButton1Click:Connect(function()
                open = not open
                if open then
                    DropdownList.Visible = true
                    local targetHeight = #options * 32
                    Utils.Tween(DropdownList, 0.2, {Size = UDim2.new(0, 120, 0, targetHeight)})
                    Utils.Tween(DropdownIcon, 0.2, {Rotation = 180})
                else
                    Utils.Tween(DropdownList, 0.2, {Size = UDim2.new(0, 120, 0, 0)})
                    Utils.Tween(DropdownIcon, 0.2, {Rotation = 0})
                    task.wait(0.2)
                    DropdownList.Visible = false
                end
            end)
            
            table.insert(Tab.Elements, DropdownContainer)
            HookSystem:Fire("ElementAdded", "Dropdown", text)
            
            return {
                GetValue = function() return selected end,
                SetValue = function(option)
                    if table.find(options, option) then
                        selected = option
                        DropdownBtn.Text = option
                    end
                end
            }
        end
        
        function Tab:AddTextbox(text, placeholder, callback)
            local TextboxContainer = Optimizer:GetInstance("Frame", TabContent)
            TextboxContainer.Name = "Textbox"
            TextboxContainer.Size = UDim2.new(1, -10, 0, 45)
            TextboxContainer.BackgroundColor3 = Theme.Current.ElementBackground
            TextboxContainer.BorderSizePixel = 0
            
            Utils.CreateCorner(TextboxContainer, 6)
            Utils.CreateStroke(TextboxContainer, Theme.Current.Border, 1)
            
            local TextboxLabel = Optimizer:GetInstance("TextLabel", TextboxContainer)
            TextboxLabel.Size = UDim2.new(0.4, 0, 1, 0)
            TextboxLabel.Position = UDim2.new(0, 15, 0, 0)
            TextboxLabel.BackgroundTransparency = 1
            TextboxLabel.Text = text
            TextboxLabel.Font = Enum.Font.Gotham
            TextboxLabel.TextSize = 13
            TextboxLabel.TextColor3 = Theme.Current.Text
            TextboxLabel.TextXAlignment = Enum.TextXAlignment.Left
            
            local Textbox = Optimizer:GetInstance("TextBox", TextboxContainer)
            Textbox.Size = UDim2.new(0.55, 0, 0, 30)
            Textbox.Position = UDim2.new(0.43, 0, 0.5, -15)
            Textbox.BackgroundColor3 = Theme.Current.ElementHover
            Textbox.BorderSizePixel = 0
            Textbox.PlaceholderText = placeholder or ""
            Textbox.Text = ""
            Textbox.Font = Enum.Font.Gotham
            Textbox.TextSize = 12
            Textbox.TextColor3 = Theme.Current.Text
            Textbox.PlaceholderColor3 = Theme.Current.TextDark
            Textbox.ClearTextOnFocus = false
            
            Utils.CreateCorner(Textbox, 5)
            
            local TextboxPadding = Optimizer:GetInstance("UIPadding", Textbox)
            TextboxPadding.PaddingLeft = UDim.new(0, 10)
            TextboxPadding.PaddingRight = UDim.new(0, 10)
            
            Textbox.FocusLost:Connect(function(enterPressed)
                if enterPressed then
                    local success, err = pcall(callback, Textbox.Text)
                    if not success then
                        warn("[DarpaHub Textbox Error]", err)
                    end
                    HookSystem:Fire("TextboxSubmitted", text, Textbox.Text)
                end
            end)
            
            Textbox.Focused:Connect(function()
                Utils.Tween(Textbox, 0.2, {BackgroundColor3 = Theme.Current.ElementActive})
            end)
            
            Textbox:GetPropertyChangedSignal("Text"):Wait()
            Textbox.FocusLost:Connect(function()
                Utils.Tween(Textbox, 0.2, {BackgroundColor3 = Theme.Current.ElementHover})
            end)
            
            table.insert(Tab.Elements, TextboxContainer)
            HookSystem:Fire("ElementAdded", "Textbox", text)
            
            return {
                GetText = function() return Textbox.Text end,
                SetText = function(newText) Textbox.Text = newText end,
                Clear = function() Textbox.Text = "" end
            }
        end
        
        function Tab:AddKeybind(text, defaultKey, callback)
            local currentKey = defaultKey or Enum.KeyCode.E
            local listening = false
            
            local KeybindContainer = Optimizer:GetInstance("Frame", TabContent)
            KeybindContainer.Name = "Keybind"
            KeybindContainer.Size = UDim2.new(1, -10, 0, 45)
            KeybindContainer.BackgroundColor3 = Theme.Current.ElementBackground
            KeybindContainer.BorderSizePixel = 0
            
            Utils.CreateCorner(KeybindContainer, 6)
            Utils.CreateStroke(KeybindContainer, Theme.Current.Border, 1)
            
            local KeybindLabel = Optimizer:GetInstance("TextLabel", KeybindContainer)
            KeybindLabel.Size = UDim2.new(1, -130, 1, 0)
            KeybindLabel.Position = UDim2.new(0, 15, 0, 0)
            KeybindLabel.BackgroundTransparency = 1
            KeybindLabel.Text = text
            KeybindLabel.Font = Enum.Font.Gotham
            KeybindLabel.TextSize = 13
            KeybindLabel.TextColor3 = Theme.Current.Text
            KeybindLabel.TextXAlignment = Enum.TextXAlignment.Left
            
            local KeybindBtn = Optimizer:GetInstance("TextButton", KeybindContainer)
            KeybindBtn.Size = UDim2.new(0, 100, 0, 30)
            KeybindBtn.Position = UDim2.new(1, -110, 0.5, -15)
            KeybindBtn.BackgroundColor3 = Theme.Current.ElementHover
            KeybindBtn.BorderSizePixel = 0
            KeybindBtn.Text = currentKey.Name
            KeybindBtn.Font = Enum.Font.GothamBold
            KeybindBtn.TextSize = 12
            KeybindBtn.TextColor3 = Theme.Current.Accent
            KeybindBtn.AutoButtonColor = false
            
            Utils.CreateCorner(KeybindBtn, 5)
            
            KeybindBtn.MouseButton1Click:Connect(function()
                listening = true
                KeybindBtn.Text = "..."
                KeybindBtn.BackgroundColor3 = Theme.Current.Accent
            end)
            
            local connection
            connection = UserInputService.InputBegan:Connect(function(input, gameProcessed)
                if not listening then return end
                if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
                
                currentKey = input.KeyCode
                KeybindBtn.Text = currentKey.Name
                KeybindBtn.BackgroundColor3 = Theme.Current.ElementHover
                listening = false
                
                -- Registrar keybind
                Keybinds:Register(currentKey, callback, text)
                HookSystem:Fire("KeybindSet", text, currentKey.Name)
            end)
            
            -- Registrar keybind inicial
            Keybinds:Register(currentKey, callback, text)
            
            table.insert(Tab.Elements, KeybindContainer)
            HookSystem:Fire("ElementAdded", "Keybind", text)
            
            return {
                GetKey = function() return currentKey end,
                SetKey = function(newKey)
                    currentKey = newKey
                    KeybindBtn.Text = currentKey.Name
                    Keybinds:Register(currentKey, callback, text)
                end
            }
        end
        
        function Tab:AddSeparator()
            local Separator = Optimizer:GetInstance("Frame", TabContent)
            Separator.Name = "Separator"
            Separator.Size = UDim2.new(1, -20, 0, 1)
            Separator.BackgroundColor3 = Theme.Current.Border
            Separator.BorderSizePixel = 0
            
            table.insert(Tab.Elements, Separator)
            return Separator
        end
        
        return Tab
    end
    
    return Window
end

-- ═══════════════════════════════════════════════════════════
--  UTILITY MODULES
-- ═══════════════════════════════════════════════════════════

-- ESP Module
Library.ESP = {
    Enabled = false,
    Objects = {},
    
    Enable = function(self)
        self.Enabled = true
        HookSystem:Fire("ESPEnabled")
    end,
    
    Disable = function(self)
        self.Enabled = false
        for _, obj in pairs(self.Objects) do
            if obj then obj:Destroy() end
        end
        self.Objects = {}
        HookSystem:Fire("ESPDisabled")
    end,
    
    AddPlayer = function(self, player, color)
        -- ESP implementation placeholder
        HookSystem:Fire("ESPPlayerAdded", player.Name)
    end
}

-- FOV Changer
Library.FOV = {
    Default = 70,
    Current = 70,
    
    Set = function(self, value)
        self.Current = value
        workspace.CurrentCamera.FieldOfView = value
        HookSystem:Fire("FOVChanged", value)
    end,
    
    Reset = function(self)
        self:Set(self.Default)
    end
}

-- WalkSpeed/JumpPower
Library.Movement = {
    DefaultWalkSpeed = 16,
    DefaultJumpPower = 50,
    
    SetWalkSpeed = function(self, value)
        local char = Player.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.WalkSpeed = value
            HookSystem:Fire("WalkSpeedChanged", value)
        end
    end,
    
    SetJumpPower = function(self, value)
        local char = Player.Character
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.JumpPower = value
            HookSystem:Fire("JumpPowerChanged", value)
        end
    end,
    
    Reset = function(self)
        self:SetWalkSpeed(self.DefaultWalkSpeed)
        self:SetJumpPower(self.DefaultJumpPower)
    end
}

-- Anti-AFK
Library.AntiAFK = {
    Enabled = false,
    Connection = nil,
    
    Enable = function(self)
        if self.Enabled then return end
        self.Enabled = true
        
        local VirtualUser = game:GetService("VirtualUser")
        self.Connection = Player.Idled:Connect(function()
            VirtualUser:CaptureController()
            VirtualUser:ClickButton2(Vector2.new())
        end)
        
        HookSystem:Fire("AntiAFKEnabled")
    end,
    
    Disable = function(self)
        if not self.Enabled then return end
        self.Enabled = false
        
        if self.Connection then
            self.Connection:Disconnect()
            self.Connection = nil
        end
        
        HookSystem:Fire("AntiAFKDisabled")
    end
}

-- Performance Monitor
Library.Performance = {
    FPS = 0,
    Ping = 0,
    Memory = 0,
    
    Update = function(self)
        self.FPS = math.floor(1 / RunService.RenderStepped:Wait())
        self.Ping = math.floor(game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue())
        self.Memory = math.floor(game:GetService("Stats"):GetTotalMemoryUsageMb())
    end,
    
    StartMonitoring = function(self)
        RunService.RenderStepped:Connect(function()
            self:Update()
        end)
    end
}

-- ═══════════════════════════════════════════════════════════
--  NOTIFICATION WRAPPER
-- ═══════════════════════════════════════════════════════════
Library.Notify = CreateNotification

-- ═══════════════════════════════════════════════════════════
--  AUTO CLEANUP
-- ═══════════════════════════════════════════════════════════
RunService.Heartbeat:Connect(function()
    Optimizer:AutoCleanup()
end)

-- ═══════════════════════════════════════════════════════════
--  EXPORT
-- ═══════════════════════════════════════════════════════════
print("╔═══════════════════════════════════════════════════════════╗")
print("║            DARPA HUB UI LIBRARY v7.0 LOADED               ║")
print("║                Premium Script UI Ready                    ║")
print("╚═══════════════════════════════════════════════════════════╝")

HookSystem:Fire("LibraryLoaded")

return Library
