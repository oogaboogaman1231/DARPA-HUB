-- DarpaHubLib.lua
-- DarpaHub — "Perfeita" Edition (production-ready framework)
-- Features: ThemeEngine, Tabs, UI Pooling, Scheduler, Throttling, Plugin System, Hot Reload,
-- Profiler, Hook Engine (sync/async), FireHook, Keybind Manager, Persistence, Safe API Export (getgenv).
-- Important: This library purposefully contains NO gameplay-cheat implementations.
-- Author: DarpaHub Team (upgraded)
-- Version: 2.0.0-perfect

-- ===============
-- ENVIRONMENT SETUP
-- ===============
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local StarterGui = game:GetService("StarterGui")
local Workspace = game:GetService("Workspace")
local HttpEnabled = pcall(function() return game:GetService("HttpService") end)

-- main table
local DarpaHub = {}
DarpaHub.__index = DarpaHub

-- export global
getgenv().DarpaHub = getgenv().DarpaHub or {}
-- allow reusing existing instance across reloads
if type(getgenv().DarpaHub) == "table" and getgenv().DarpaHub._isDarpaHub then
    -- reuse existing if present (hot-reload friendly)
    DarpaHub = getgenv().DarpaHub
else
    DarpaHub = setmetatable({}, DarpaHub)
    getgenv().DarpaHub = DarpaHub
end
DarpaHub._isDarpaHub = true

-- ===============
-- BASIC STATE
-- ===============
DarpaHub.VERSION = "2.0.0-perfect"
DarpaHub.BuiltAt = os.time()
DarpaHub.State = {
    Booted = false,
    EnvironmentReady = false,
    Running = false,
    Mode = "unsupported", -- default; loader can pass mode string
    LastError = nil
}

-- private internals
DarpaHub._private = {
    Connections = {},
    UI = {},
    Pools = {},
    FeatureOrder = {},
    Plugins = {},         -- name -> plugin meta
    PluginManifests = {}, -- manifest storage
    Scheduler = nil,
    Profiler = nil,
    Theme = nil
}

-- registries
DarpaHub.Features = {}   -- featureName -> feature
DarpaHub.Hooks = {}      -- hookName -> {listeners}
DarpaHub.Keybinds = {}   -- list of keybinds

-- safe pcall wrapper
local function safecall(fn, ...)
    local ok, ret = pcall(fn, ...)
    if not ok then
        warn("[DarpaHub safecall] ", ret)
        DarpaHub.State.LastError = tostring(ret)
    end
    return ok, ret
end

-- protected connect; tracks connections for cleanup
local function protectedConnect(signal, cb)
    local conn = signal:Connect(function(...)
        safecall(cb, ...)
    end)
    table.insert(DarpaHub._private.Connections, conn)
    return conn
end

-- disconnect all stored connections
function DarpaHub:DisconnectAll()
    for _, c in ipairs(self._private.Connections) do
        pcall(function() c:Disconnect() end)
    end
    self._private.Connections = {}
end

-- small utility: deep copy
local function deepCopy(orig)
    local orig_type = type(orig)
    if orig_type ~= 'table' then return orig end
    local copy = {}
    for orig_key, orig_value in next, orig, nil do
        copy[deepCopy(orig_key)] = deepCopy(orig_value)
    end
    setmetatable(copy, deepCopy(getmetatable(orig)))
    return copy
end

-- ===============
-- PERSISTENCE (writefile/readfile safe wrappers)
-- ===============
function DarpaHub:_writeFileSafe(path, content)
    local ok = pcall(function()
        if writefile then
            writefile(path, content)
            return true
        elseif syn and syn.write_file then
            syn.write_file(path, content)
            return true
        elseif write_file then
            write_file(path, content)
            return true
        else
            error("no writefile available")
        end
    end)
    return ok
end

function DarpaHub:_readFileSafe(path)
    local ok, content = pcall(function()
        if readfile then
            return readfile(path)
        elseif syn and syn.read_file then
            return syn.read_file(path)
        elseif read_file then
            return read_file(path)
        else
            error("no readfile available")
        end
    end)
    if ok then return content end
    return nil
end

function DarpaHub:SaveJSON(name, tbl)
    local ok, enc = pcall(function() return HttpService:JSONEncode(tbl) end)
    if not ok then
        warn("SaveJSON encode failed")
        return false
    end
    local path = "DarpaHub_" .. tostring(name) .. ".json"
    local wrote = self:_writeFileSafe(path, enc)
    if not wrote then
        -- fallback to getgenv
        getgenv().DarpaHubPersist = getgenv().DarpaHubPersist or {}
        getgenv().DarpaHubPersist[name] = tbl
        return true
    end
    return true
end

function DarpaHub:LoadJSON(name)
    local path = "DarpaHub_" .. tostring(name) .. ".json"
    local raw = self:_readFileSafe(path)
    if raw then
        local ok, dec = pcall(function() return HttpService:JSONDecode(raw) end)
        if ok then return dec end
    end
    if getgenv().DarpaHubPersist and getgenv().DarpaHubPersist[name] then
        return getgenv().DarpaHubPersist[name]
    end
    return nil
end

-- ===============
-- HOOKS ENGINE (sync / async + connect/disconnect)
-- ===============
function DarpaHub:CreateHook(name)
    if not name or type(name) ~= "string" then return false end
    if not self.Hooks[name] then self.Hooks[name] = {} end
    return true
end

function DarpaHub:ConnectHook(name, listener)
    if not self.Hooks[name] then self:CreateHook(name) end
    table.insert(self.Hooks[name], listener)
    local listeners = self.Hooks[name]
    -- return disconnect handle
    return {
        Disconnect = function()
            for i, v in ipairs(listeners) do
                if v == listener then
                    table.remove(listeners, i)
                    break
                end
            end
        end
    }
end

function DarpaHub:FireHook(name, ...)
    local list = self.Hooks[name]
    if not list then return end
    for _, listener in ipairs(list) do
        safecall(listener, ...)
    end
end

function DarpaHub:FireHookAsync(name, ...)
    local list = self.Hooks[name]
    if not list then return end
    for _, listener in ipairs(list) do
        task.spawn(function() safecall(listener, ...) end)
    end
end

-- create some core hooks
DarpaHub:CreateHook("Inited")
DarpaHub:CreateHook("UIReady")
DarpaHub:CreateHook("PluginLoaded")
DarpaHub:CreateHook("PluginUnloaded")
DarpaHub:CreateHook("ThemeChanged")
DarpaHub:CreateHook("FeatureRegistered")
DarpaHub:CreateHook("FeatureEnabled")
DarpaHub:CreateHook("FeatureDisabled")
DarpaHub:CreateHook("RuntimeStarted")
DarpaHub:CreateHook("RuntimeStopped")
DarpaHub:CreateHook("ProfilerTick")

-- ===============
-- SCHEDULER & THROTTLING
-- Advanced: supports priorities, every-frame / interval, and throttled jobs
-- ===============
local Scheduler = {}
Scheduler.__index = Scheduler

function Scheduler.new()
    local s = setmetatable({
        jobs = {}, -- list of {id, fn, interval, lastRun, priority, persistent}
        running = false,
        nextId = 0
    }, Scheduler)
    return s
end

function Scheduler:_genId()
    self.nextId = self.nextId + 1
    return tostring(self.nextId)
end

-- add job:
-- fn: function
-- opts: {interval (seconds, nil for every frame), priority (lower number runs earlier), persistent (bool)}
function Scheduler:AddJob(fn, opts)
    opts = opts or {}
    local id = self:_genId()
    table.insert(self.jobs, {
        id = id,
        fn = fn,
        interval = opts.interval,
        lastRun = 0,
        priority = opts.priority or 50,
        persistent = opts.persistent == nil and true or opts.persistent
    })
    -- keep jobs sorted by priority
    table.sort(self.jobs, function(a,b) return a.priority < b.priority end)
    return id
end

function Scheduler:RemoveJob(id)
    for i = #self.jobs, 1, -1 do
        if self.jobs[i].id == id then
            table.remove(self.jobs, i)
            return true
        end
    end
    return false
end

function Scheduler:Tick(dt)
    local now = tick()
    for i = 1, #self.jobs do
        local j = self.jobs[i]
        if not j then break end
        local canRun = false
        if not j.interval then
            canRun = true -- every frame
        else
            if now - j.lastRun >= j.interval then canRun = true end
        end
        if canRun then
            j.lastRun = now
            safecall(j.fn, dt)
            if not j.persistent then
                -- remove non-persistent job after run
                self:RemoveJob(j.id)
            end
        end
    end
end

-- create and attach scheduler into DarpaHub
DarpaHub._private.Scheduler = Scheduler.new()

-- attach to RenderStepped for precise timing (pausable)
protectedConnect(RunService.RenderStepped, function(dt)
    if DarpaHub.State.Running then
        DarpaHub._private.Scheduler:Tick(dt)
    end
end)

-- ===============
-- PROFILER (lightweight)
-- collects timings per hook / feature
-- ===============
local Profiler = {}
Profiler.__index = Profiler

function Profiler.new()
    return setmetatable({
        stats = {}, -- key -> {calls, totalTime, lastTime}
        enabled = false,
        sampleRate = 1 -- seconds
    }, Profiler)
end

function Profiler:Enable()
    self.enabled = true
end
function Profiler:Disable()
    self.enabled = false
end

function Profiler:Time(key, fn, ...)
    if not self.enabled then return safecall(fn, ...) end
    local start = tick()
    local ok, ret = safecall(fn, ...)
    local elapsed = tick() - start
    local s = self.stats[key] or {calls=0, totalTime=0, lastTime=0}
    s.calls = s.calls + 1
    s.totalTime = s.totalTime + elapsed
    s.lastTime = elapsed
    self.stats[key] = s
    return ok, ret
end

function Profiler:GetStats()
    return deepCopy(self.stats)
end

function Profiler:Reset()
    self.stats = {}
end

DarpaHub._private.Profiler = Profiler.new()

-- fire a periodic profiler tick hook
DarpaHub._private.Scheduler:AddJob(function() DarpaHub:FireHook("ProfilerTick", DarpaHub._private.Profiler:GetStats()) end, {interval=5, priority=100})

-- ===============
-- UI CORE: pooling + helpers + theme engine + tabs + widgets
-- Pooling helps performance for repeated UI creation/destroy
-- ===============

-- UI Pool utilities
function DarpaHub._private.Pools:CreatePool(name, className)
    self[name] = self[name] or {class = className, free = {}, used = {}}
    return self[name]
end

function DarpaHub._private.Pools:Get(name)
    return self[name]
end

function DarpaHub._private.Pools:Acquire(name)
    local pool = self[name]
    if not pool then return nil end
    if #pool.free > 0 then
        local inst = table.remove(pool.free)
        table.insert(pool.used, inst)
        return inst
    else
        local inst = Instance.new(pool.class)
        table.insert(pool.used, inst)
        return inst
    end
end

function DarpaHub._private.Pools:Release(name, inst)
    local pool = self[name]
    if not pool then
        if inst then pcall(function() inst:Destroy() end) end
        return
    end
    for i,v in ipairs(pool.used) do
        if v == inst then
            table.remove(pool.used, i)
            table.insert(pool.free, inst)
            -- reset basic properties (safe)
            pcall(function()
                inst.Parent = nil
                if inst:IsA("Frame") or inst:IsA("TextLabel") or inst:IsA("TextButton") then
                    inst.Size = UDim2.new(0, 100, 0, 30)
                    inst.Position = UDim2.new(0,0,0,0)
                    inst.BackgroundTransparency = 1
                    inst.Text = ""
                end
            end)
            return true
        end
    end
    return false
end

-- create some default pools
DarpaHub._private.Pools:CreatePool("FramePool", "Frame")
DarpaHub._private.Pools:CreatePool("TextLabelPool", "TextLabel")
DarpaHub._private.Pools:CreatePool("TextButtonPool", "TextButton")
DarpaHub._private.Pools:CreatePool("ImageLabelPool", "ImageLabel")

-- Theme Engine
DarpaHub.Theme = DarpaHub.Theme or {}
function DarpaHub.Theme:Init()
    self.Presets = {
        Dark = {
            Name = "Dark",
            Background = Color3.fromRGB(18,18,20),
            Primary = Color3.fromRGB(36,36,45),
            Accent = Color3.fromRGB(0,170,255),
            Text = Color3.fromRGB(235,235,240),
            Muted = Color3.fromRGB(160,160,170)
        },
        Midnight = {
            Name = "Midnight",
            Background = Color3.fromRGB(8,8,14),
            Primary = Color3.fromRGB(20,20,28),
            Accent = Color3.fromRGB(255,90,120),
            Text = Color3.fromRGB(240,240,245),
            Muted = Color3.fromRGB(150,150,160)
        },
        Light = {
            Name = "Light",
            Background = Color3.fromRGB(245,245,248),
            Primary = Color3.fromRGB(255,255,255),
            Accent = Color3.fromRGB(0, 120, 255),
            Text = Color3.fromRGB(18,18,20),
            Muted = Color3.fromRGB(100,100,110)
        }
    }
    local saved = DarpaHub:LoadJSON("theme")
    if saved and saved.name and self.Presets[saved.name] then
        DarpaHub._private.ActiveTheme = self.Presets[saved.name]
    else
        DarpaHub._private.ActiveTheme = self.Presets.Dark
    end
end

function DarpaHub.Theme:GetColor(key)
    local t = DarpaHub._private.ActiveTheme
    if not t then return Color3.fromRGB(255,255,255) end
    return t[key] or t.Text
end

function DarpaHub.Theme:SetTheme(name)
    if not self.Presets[name] then return false end
    DarpaHub._private.ActiveTheme = self.Presets[name]
    DarpaHub:SaveJSON("theme", {name=name})
    DarpaHub:FireHook("ThemeChanged", name)
    return true
end

-- Create base ScreenGui and container (but do not force a single visible state)
function DarpaHub:BuildBaseUI()
    if self._private.UI.ScreenGui and self._private.UI.ScreenGui.Parent then return self._private.UI end

    local screen = Instance.new("ScreenGui")
    screen.Name = "DarpaHubUI"
    screen.ResetOnSpawn = false
    screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    -- try to parent to CoreGui (preferred)
    local ok = pcall(function() screen.Parent = CoreGui end)
    if not ok or not screen.Parent then
        -- fallback to PlayerGui
        local plr = Players.LocalPlayer
        if plr then
            screen.Parent = plr:WaitForChild("PlayerGui")
        else
            screen.Parent = game:GetService("StarterGui")
        end
    end

    self._private.UI.ScreenGui = screen

    -- main frame container
    local main = Instance.new("Frame")
    main.Name = "DarpaHubMain"
    main.Parent = screen
    main.AnchorPoint = Vector2.new(0.5, 0.5)
    main.Position = UDim2.new(0.5, 0.5, 0.5, 0.5)
    main.Size = UDim2.new(0, 920, 0, 560)
    main.BackgroundColor3 = self.Theme:GetColor("Primary")
    main.BackgroundTransparency = 0.02
    main.BorderSizePixel = 0
    local corner = Instance.new("UICorner", main)
    corner.CornerRadius = UDim.new(0, 12)

    -- internal left tabs and right content
    local left = Instance.new("Frame")
    left.Name = "LeftPanel"
    left.Parent = main
    left.Position = UDim2.new(0,18,0,92)
    left.Size = UDim2.new(0, 238, 0, 438)
    left.BackgroundTransparency = 1

    local right = Instance.new("Frame")
    right.Name = "RightPanel"
    right.Parent = main
    right.Position = UDim2.new(0, 266, 0, 92)
    right.Size = UDim2.new(1, -286, 0, 438)
    right.BackgroundTransparency = 1

    -- header
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Parent = main
    header.Size = UDim2.new(1,0,0,84)
    header.Position = UDim2.new(0,0,0,0)
    header.BackgroundTransparency = 1

    local title = Instance.new("TextLabel")
    title.Parent = header
    title.Text = "DarpaHub — Premium"
    title.TextSize = 26
    title.Font = Enum.Font.GothamBold
    title.TextColor3 = self.Theme:GetColor("Text")
    title.BackgroundTransparency = 1
    title.Position = UDim2.new(0, 18, 0, 18)
    title.Size = UDim2.new(0, 400, 0, 36)

    -- store references
    self._private.UI.Main = main
    self._private.UI.Left = left
    self._private.UI.Right = right
    self._private.UI.Header = header
    self._private.UI.Title = title

    -- call hook
    self:FireHook("UIReady", self._private.UI)

    return self._private.UI
end

-- Tab system: create tabs and page APIs
function DarpaHub:CreateTab(name)
    local ui = self._private.UI
    if not ui or not ui.Left or not ui.Right then
        safecall(function() self:BuildBaseUI() end)
        ui = self._private.UI
    end

    local left = ui.Left
    local right = ui.Right

    -- tab button container
    local list = left:FindFirstChild("TabsList")
    if not list then
        list = Instance.new("ScrollingFrame")
        list.Name = "TabsList"
        list.Parent = left
        list.Size = UDim2.new(1, -12, 1, -12)
        list.Position = UDim2.new(0, 6, 0, 6)
        list.BackgroundTransparency = 1
        list.CanvasSize = UDim2.new(0,0,0,0)
        list.ScrollBarThickness = 8
        list.AutomaticCanvasSize = Enum.AutomaticSize.Y
    end

    local btn = Instance.new("TextButton")
    btn.Name = "Tab_"..name
    btn.Size = UDim2.new(1, -12, 0, 48)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.Parent = list

    local frame = Instance.new("Frame", btn)
    frame.Size = UDim2.new(1,0,1,0)
    frame.BackgroundColor3 = self.Theme:GetColor("Primary")
    frame.BorderSizePixel = 0
    local corner = Instance.new("UICorner", frame); corner.CornerRadius = UDim.new(0,8)

    local label = Instance.new("TextLabel", frame)
    label.Size = UDim2.new(1, -18, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.TextColor3 = self.Theme:GetColor("Text")
    label.TextSize = 15
    label.Text = name

    -- page in right content
    local pages = right:FindFirstChild("Pages")
    if not pages then
        pages = Instance.new("Folder", right); pages.Name = "Pages"
    end
    local page = Instance.new("Frame")
    page.Name = "Page_" .. name
    page.Size = UDim2.new(1, -24, 1, -24)
    page.Position = UDim2.new(0, 12, 0, 12)
    page.BackgroundTransparency = 1
    page.Parent = pages
    page.Visible = false

    -- activation
    btn.MouseButton1Click:Connect(function()
        for _,p in ipairs(pages:GetChildren()) do
            if p:IsA("Frame") then p.Visible = false end
        end
        page.Visible = true
        self:FireHook("TabActivated", name, page)
    end)

    -- return an API for adding widgets
    local tabAPI = {}

    function tabAPI:AddLabel(text)
        local lbl = DarpaHub._private.Pools:Acquire("TextLabelPool")
        -- initialize properties for safety
        pcall(function()
            lbl.Parent = page
            lbl.Size = UDim2.new(1, -24, 0, 22)
            lbl.Position = UDim2.new(0, 12, 0, (#page:GetChildren() * 26))
            lbl.BackgroundTransparency = 1
            lbl.Font = Enum.Font.Gotham
            lbl.TextSize = 14
            lbl.TextColor3 = DarpaHub.Theme:GetColor("Muted")
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.Text = text or ""
        end)
        return lbl
    end

    function tabAPI:AddButton(text, cb)
        local btn = DarpaHub._private.Pools:Acquire("TextButtonPool")
        pcall(function()
            btn.Parent = page
            btn.Size = UDim2.new(1, -24, 0, 36)
            btn.Position = UDim2.new(0, 12, 0, (#page:GetChildren() * 42))
            btn.BackgroundColor3 = DarpaHub.Theme:GetColor("Accent")
            btn.BorderSizePixel = 0
            btn.Text = text or ""
            btn.Font = Enum.Font.GothamBold
            btn.TextSize = 14
            btn.TextColor3 = Color3.fromRGB(255,255,255)
            btn.AutoButtonColor = false
            btn.MouseButton1Click:Connect(function()
                safecall(cb)
            end)
        end)
        return btn
    end

    function tabAPI:AddToggle(text, default, cb)
        local frame = DarpaHub._private.Pools:Acquire("FramePool")
        pcall(function()
            frame.Parent = page
            frame.Size = UDim2.new(1, -24, 0, 36)
            frame.Position = UDim2.new(0, 12, 0, (#page:GetChildren() * 42))
            frame.BackgroundTransparency = 1
            -- label
            local lab = Instance.new("TextLabel", frame)
            lab.Text = text or "Toggle"
            lab.Size = UDim2.new(1, -80, 1, 0)
            lab.Position = UDim2.new(0,0,0,0)
            lab.BackgroundTransparency = 1
            lab.TextColor3 = DarpaHub.Theme:GetColor("Text")
            lab.Font = Enum.Font.Gotham
            lab.TextSize = 14
            -- toggle
            local tbtn = Instance.new("TextButton", frame)
            tbtn.Size = UDim2.new(0, 64, 0, 28)
            tbtn.Position = UDim2.new(1, -74, 0.5, -14)
            tbtn.Text = default and "On" or "Off"
            tbtn.BackgroundColor3 = default and DarpaHub.Theme:GetColor("Accent") or DarpaHub.Theme:GetColor("Primary")
            tbtn.Font = Enum.Font.GothamBold
            tbtn.TextSize = 13
            tbtn.TextColor3 = Color3.fromRGB(255,255,255)
            local state = default and true or false
            tbtn.MouseButton1Click:Connect(function()
                state = not state
                tbtn.BackgroundColor3 = state and DarpaHub.Theme:GetColor("Accent") or DarpaHub.Theme:GetColor("Primary")
                tbtn.Text = state and "On" or "Off"
                safecall(cb, state)
            end)
        end)
        return frame
    end

    -- return page and api
    return {Page = page, API = tabAPI, Button = btn}
end

-- ===============
-- FEATURE LIFECYCLE
-- register features, enable/disable, update (hook into scheduler)
-- ===============
function DarpaHub:RegisterFeature(name, descriptor)
    if not name or type(name) ~= "string" then error("Invalid feature name") end
    if self.Features[name] then warn("Feature already registered", name); return end
    descriptor = descriptor or {}
    local feature = {
        Name = name,
        Enabled = false,
        DefaultEnabled = descriptor.DefaultEnabled or false,
        Config = descriptor.Config or {},
        Enable = descriptor.Enable or function() end,
        Disable = descriptor.Disable or function() end,
        Update = descriptor.Update or function() end,
        Priority = descriptor.Priority or 50,
        UI = descriptor.UI
    }
    self.Features[name] = feature
    table.insert(self._private.FeatureOrder, name)
    -- auto-enable default features after init
    if feature.DefaultEnabled then
        task.spawn(function() self:EnableFeature(name) end)
    end
    self:FireHook("FeatureRegistered", name, feature)
    return feature
end

function DarpaHub:EnableFeature(name)
    local f = self.Features[name]
    if not f then warn("EnableFeature not found", name); return end
    if f.Enabled then return end
    safecall(function()
        f.Enabled = true
        if f.Enable then f.Enable(f) end
        self:FireHook("FeatureEnabled", name, f)
    end)
end

function DarpaHub:DisableFeature(name)
    local f = self.Features[name]
    if not f then warn("DisableFeature not found", name); return end
    if not f.Enabled then return end
    safecall(function()
        f.Enabled = false
        if f.Disable then f.Disable(f) end
        self:FireHook("FeatureDisabled", name, f)
    end)
end

-- runtime driver: calls Update on enabled features (batched via scheduler)
local function __darpa_runtime_tick()
    if not DarpaHub.State.Running then return end
    DarpaHub._private.Profiler:Time("features_tick", function()
        for _, name in ipairs(DarpaHub._private.FeatureOrder) do
            local f = DarpaHub.Features[name]
            if f and f.Enabled and type(f.Update) == "function" then
                safecall(f.Update, f)
            end
        end
    end)
end
-- register runtime tick with scheduler at every frame
DarpaHub._private.Scheduler:AddJob(__darpa_runtime_tick, {interval=nil, priority=10})

-- ===============
-- KEYBIND MANAGER
-- allows binding keys to callbacks (safe and tracked)
-- ===============
function DarpaHub:BindKey(keyCode, callback)
    if not keyCode or not callback then return end
    table.insert(self.Keybinds, {Key = keyCode, Callback = callback})
end

protectedConnect(UserInputService.InputBegan, function(input, gp)
    if gp then return end
    for _, b in ipairs(DarpaHub.Keybinds) do
        if input.KeyCode == b.Key then
            safecall(b.Callback, input)
        end
    end
end)

-- ===============
-- PLUGIN SYSTEM
-- plugin manifest structure:
-- {
--    name = "pluginName",
--    version = "1.0",
--    url = "https://.../module.lua" or "local" (if using local file),
--    author = "name",
--    description = "desc",
--    allowedAPIs = {"UI","Scheduler","Hooks"} -- permission model
-- }
-- Plugins are sandboxed: they receive a safe API object, not full DarpaHub internals.
-- Hot reload supported: reload from same URL/identifier.
-- ===============
function DarpaHub:RegisterPluginManifest(manifest)
    if not manifest or not manifest.name then error("Invalid manifest") end
    self._private.PluginManifests[manifest.name] = manifest
    return true
end

-- internal: create plugin sandbox API according to manifest.allowedAPIs
local function _build_plugin_api(manifest)
    local api = {}
    api.getName = function() return manifest.name end
    api.getVersion = function() return manifest.version end
    api.Logger = {
        Info = function(...) print("[DarpaHub.Plugin]["..manifest.name.."]", ...) end,
        Warn = function(...) warn("[DarpaHub.Plugin]["..manifest.name.."]", ...) end,
        Error = function(...) error("[DarpaHub.Plugin]["..manifest.name.."]", ...) end
    }
    -- safe exposures
    api.Scheduler = {
        Add = function(fn, opts) return DarpaHub._private.Scheduler:AddJob(fn, opts) end,
        Remove = function(id) return DarpaHub._private.Scheduler:RemoveJob(id) end
    }
    api.Hooks = {
        Connect = function(hookName, listener) return DarpaHub:ConnectHook(hookName, listener) end,
        Fire = function(hookName, ...) return DarpaHub:FireHook(hookName, ...) end
    }
    api.UI = {
        CreateTab = function(...) return DarpaHub:CreateTab(...) end,
        Theme = DarpaHub.Theme
    }
    api.Persistence = {
        Save = function(k,v) return DarpaHub:SaveJSON(k,v) end,
        Load = function(k) return DarpaHub:LoadJSON(k) end
    }
    -- any additional allowed APIs can be gated later
    return api
end

-- load plugin from manifest
function DarpaHub:LoadPlugin(name)
    local manifest = self._private.PluginManifests[name]
    if not manifest then error("Plugin manifest not found: "..tostring(name)) end
    if not manifest.url then error("Plugin manifest has no url") end

    local code = nil
    if manifest.url:lower():sub(1,4) == "http" and HttpEnabled then
        local ok, res = pcall(function() return game:HttpGet(manifest.url) end)
        if not ok then error("Failed to download plugin: "..tostring(res)) end
        code = res
    else
        -- treat as inline code or module name; support readfile
        code = manifest.code or self:_readFileSafe(manifest.url) or error("Cannot load plugin code from "..tostring(manifest.url))
    end

    -- load plugin in sandbox
    local pluginEnv = {}
    local api = _build_plugin_api(manifest)
    pluginEnv.DarpaHub = api -- expose only the api
    pluginEnv.print = function(...) print("[Plugin]["..manifest.name.."]", ...) end
    pluginEnv.pcall = pcall
    pluginEnv.require = nil -- disable require by default (prevent access)
    pluginEnv.game = nil -- do not expose game by default
    -- safe load
    local chunk, loadErr = loadstring(code)
    if not chunk then error("Plugin compilation failed: "..tostring(loadErr)) end
    setfenv(chunk, pluginEnv)
    local ok, res = pcall(chunk)
    if not ok then error("Plugin runtime error: "..tostring(res)) end

    -- register plugin meta
    self._private.Plugins[name] = {
        manifest = manifest,
        env = pluginEnv,
        active = true,
        loadedAt = os.time()
    }
    self:FireHook("PluginLoaded", name, manifest)
    return true
end

function DarpaHub:UnloadPlugin(name)
    local p = self._private.Plugins[name]
    if not p then return false end
    -- best-effort cleanup: call onUnload if defined
    if p.env and p.env.onUnload and type(p.env.onUnload) == "function" then
        safecall(p.env.onUnload)
    end
    self._private.Plugins[name] = nil
    self:FireHook("PluginUnloaded", name)
    return true
end

function DarpaHub:HotReloadPlugin(name)
    -- unload then load again from manifest
    self:UnloadPlugin(name)
    return self:LoadPlugin(name)
end

-- ===============
-- HOT-RELOAD / DEVELOPER UTILITIES
-- - reload library in memory
-- - re-init UI
-- ===============
function DarpaHub:HotReload()
    -- This function purposely reloads stateful modules but preserves certain configs
    local savedTheme = DarpaHub:LoadJSON("theme")
    -- disconnect and cleanup UI
    pcall(function()
        if DarpaHub._private.UI and DarpaHub._private.UI.ScreenGui then
            DarpaHub._private.UI.ScreenGui:Destroy()
        end
    end)
    DarpaHub._private.UI = {}
    -- reset pools but keep them
    DarpaHub._private.Pools.free = DarpaHub._private.Pools.free or {}
    -- re-init theme and UI
    safecall(function()
        DarpaHub.Theme:Init()
        DarpaHub:BuildBaseUI()
    end)
    if savedTheme and savedTheme.name then DarpaHub.Theme:SetTheme(savedTheme.name) end
    DarpaHub:FireHook("HotReload")
    return true
end

-- ===============
-- SAFETY: Safe API for external modules to manipulate UI / scheduler / hooks
-- Expose a restricted API, not internals
-- ===============
function DarpaHub:GetSafeAPI()
    return {
        RegisterFeature = function(...) return DarpaHub:RegisterFeature(...) end,
        EnableFeature = function(...) return DarpaHub:EnableFeature(...) end,
        DisableFeature = function(...) return DarpaHub:DisableFeature(...) end,
        CreateTab = function(...) return DarpaHub:CreateTab(...) end,
        BindKey = function(...) return DarpaHub:BindKey(...) end,
        Theme = DarpaHub.Theme,
        Scheduler = DarpaHub._private.Scheduler,
        Hooks = {
            Connect = function(h, cb) return DarpaHub:ConnectHook(h, cb) end,
            Fire = function(h, ...) return DarpaHub:FireHook(h, ...) end
        },
        Persistence = {
            Save = function(k,v) return DarpaHub:SaveJSON(k,v) end,
            Load = function(k) return DarpaHub:LoadJSON(k) end
        },
        Profiler = {
            Enable = function() DarpaHub._private.Profiler:Enable() end,
            Disable = function() DarpaHub._private.Profiler:Disable() end,
            GetStats = function() return DarpaHub._private.Profiler:GetStats() end
        }
    }
end

-- attach API to getgenv for plugin authors & external modules (explicit)
getgenv().DarpaHubAPI = getgenv().DarpaHubAPI or DarpaHub:GetSafeAPI()

-- ===============
-- BOOT / INIT
-- Wait for environment then build UI and start runtime
-- ===============
function DarpaHub:_waitForEnvironment()
    if self.State.EnvironmentReady then return end
    local plr = Players.LocalPlayer
    repeat task.wait() until plr
    repeat task.wait() until Workspace and Workspace.CurrentCamera
    self.State.EnvironmentReady = true
end

function DarpaHub:Init(mode)
    if self.State.Booted then
        warn("DarpaHub:Init called but already booted")
        return
    end
    self.State.Booted = true
    self.State.Mode = mode or "unsupported"
    -- init subsystems
    safecall(function() DarpaHub.Theme:Init() end)
    safecall(function() DarpaHub._private.Profiler = DarpaHub._private.Profiler or Profiler.new() end) -- ensure profiler exists
    -- wait environment and then build UI
    task.spawn(function()
        self:_waitForEnvironment()
        safecall(function()
            self:BuildBaseUI()
            -- build default tabs for plugins and settings
            local settings = self:CreateTab("Settings")
            local pluginsTab = self:CreateTab("Plugins")
            -- simple toggles in settings
            settings.API:AddLabel("Theme")
            settings.API:AddButton("Toggle Dark/Light", function()
                local cur = DarpaHub._private.ActiveTheme and DarpaHub._private.ActiveTheme.Name or "Dark"
                if cur == "Dark" then
                    DarpaHub.Theme:SetTheme("Light")
                else
                    DarpaHub.Theme:SetTheme("Dark")
                end
            end)
            -- plugin loader UI
            pluginsTab.API:AddLabel("Installed Plugins")
            pluginsTab.API:AddButton("List Plugins in Console", function()
                print("Plugins:", DarpaHub._private.Plugins)
            end)
        end)
        -- start runtime
        self.State.Running = true
        self:FireHook("Inited", self.State.Mode)
        self:FireHook("RuntimeStarted")
    end)
    return true
end

-- ===============
-- UTILITIES: Logging, Debug Console, Nice prints
-- ===============
function DarpaHub:Log(...)
    print("[DarpaHub LOG]", ...)
end

function DarpaHub:Warn(...)
    warn("[DarpaHub WARN]", ...)
end

function DarpaHub:Error(...)
    error("[DarpaHub ERROR] " .. table.concat({...}, " "))
end

-- ===============
-- CLEANUP: graceful shutdown
-- ===============
function DarpaHub:Shutdown()
    self:FireHook("RuntimeStopped")
    self.State.Running = false
    -- Unload plugins
    for pname, _ in pairs(self._private.Plugins) do
        pcall(function() self:UnloadPlugin(pname) end)
    end
    -- Destroy UI
    pcall(function()
        if self._private.UI and self._private.UI.ScreenGui then
            self._private.UI.ScreenGui:Destroy()
        end
    end)
    self._private.UI = {}
    -- Disconnect events
    self:DisconnectAll()
    return true
end

-- ===============
-- EXAMPLES: register a couple of safe visual/demo features
-- These are intentionally non-gameplay-affecting and serve as templates.
-- ===============
-- Visual Indicator feature: shows a blinking UI label when enabled
DarpaHub:RegisterFeature("VisualIndicator", {
    DefaultEnabled = false,
    Priority = 80,
    Enable = function(selfFeature)
        local ui = DarpaHub._private.UI
        if ui and ui.Right then
            local box = Instance.new("Frame")
            box.Name = "VisualIndicatorBox"
            box.Size = UDim2.new(0, 200, 0, 40)
            box.Position = UDim2.new(1, -220, 0, 12)
            box.AnchorPoint = Vector2.new(0,0)
            box.BackgroundColor3 = DarpaHub.Theme:GetColor("Primary")
            box.Parent = ui.Right
            local lbl = Instance.new("TextLabel", box)
            lbl.Size = UDim2.new(1, -12, 1, 0)
            lbl.Position = UDim2.new(0,6,0,0)
            lbl.BackgroundTransparency = 1
            lbl.TextColor3 = DarpaHub.Theme:GetColor("Accent")
            lbl.Font = Enum.Font.GothamBold
            lbl.TextSize = 14
            lbl.Text = "Visual Indicator: ON"
            selfFeature._ui = box
            -- animate
            DarpaHub._private.Scheduler:AddJob(function()
                pcall(function()
                    local t = tick()
                    lbl.TextTransparency = 0.2 + (math.abs(math.sin(t / 0.6)) * 0.6)
                end)
            end, {interval = nil, priority = 120}) -- every frame
        end
    end,
    Disable = function(selfFeature)
        if selfFeature._ui then
            pcall(function() selfFeature._ui:Destroy() end)
            selfFeature._ui = nil
        end
    end,
    Update = function(selfFeature)
        -- non-critical update; left intentionally light
    end
})

-- Theme-ready demo feature: cycles accent color temporarily
DarpaHub:RegisterFeature("AccentPulse", {
    DefaultEnabled = false,
    Priority = 120,
    Enable = function(selfFeature)
        selfFeature._running = true
    end,
    Disable = function(selfFeature)
        selfFeature._running = false
    end,
    Update = function(selfFeature)
        if not selfFeature._running then return end
        -- compute accent pulse value
        local t = (math.sin(tick() / 1.2) + 1) / 2
        -- interpolate between two colors
        local orig = DarpaHub._private.ActiveTheme and DarpaHub._private.ActiveTheme.Accent or Color3.fromRGB(0,170,255)
        local alt = Color3.fromRGB(255, 120, 160)
        local function lerp(a,b,alpha)
            return Color3.new(a.R + (b.R - a.R) * alpha, a.G + (b.G - a.G) * alpha, a.B + (b.B - a.B) * alpha)
        end
        local col = lerp(orig, alt, t)
        -- apply to main background highlight if exists
        pcall(function()
            if DarpaHub._private.UI and DarpaHub._private.UI.Main then
                DarpaHub._private.UI.Main.BackgroundColor3 = col
            end
        end)
    end
})

-- ===============
-- FINALIZE: ensure profiler object exists and export API
-- ===============
if not DarpaHub._private.Profiler then
    -- minimal profiler wrapper if hot-reloading version lost reference
    DarpaHub._private.Profiler = Profiler.new()
end

-- Ensure theme init default
safecall(function() DarpaHub.Theme:Init() end)

-- export safe API to getgenv (overwrite only if not present)
getgenv().DarpaHubAPI = getgenv().DarpaHubAPI or DarpaHub:GetSafeAPI()
getgenv().DarpaHub = DarpaHub -- export full hub if desired

-- mark boot complete
DarpaHub.State.Booted = true

-- Provide friendly return for loadstring()
return DarpaHub
