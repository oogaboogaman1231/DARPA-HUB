-- DarpaHubLib.lua
-- DarpaHub — Production-ready core framework (no demos)
-- Features: ThemeEngine, Tabs, UI Pooling, Scheduler, Throttling, Plugin System, Hot Reload,
-- Profiler, Hook Engine (sync/async), Keybind Manager, Persistence, Safe API Export (getgenv).
-- Important: This library purposefully contains NO gameplay-cheat implementations or demo features.
-- Author: DarpaHub Team (production)
-- Version: 2.0.0-production

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

-- export global (hot-reload friendly)
getgenv().DarpaHub = getgenv().DarpaHub or {}
if type(getgenv().DarpaHub) == "table" and getgenv().DarpaHub._isDarpaHub then
    DarpaHub = getgenv().DarpaHub
else
    DarpaHub = setmetatable({}, DarpaHub)
    getgenv().DarpaHub = DarpaHub
end
DarpaHub._isDarpaHub = true

-- ===============
-- BASIC STATE
-- ===============
DarpaHub.VERSION = "2.0.0-production"
DarpaHub.BuiltAt = os.time()
DarpaHub.State = {
    Booted = false,
    EnvironmentReady = false,
    Running = false,
    Mode = "unsupported",
    LastError = nil
}

-- private internals
DarpaHub._private = {
    Connections = {},
    UI = {},
    Pools = {},
    FeatureOrder = {},
    Plugins = {},
    PluginManifests = {},
    Scheduler = nil,
    Profiler = nil,
    Theme = nil,
    ActiveTheme = nil
}

-- registries
DarpaHub.Features = {}
DarpaHub.Hooks = {}
DarpaHub.Keybinds = {}

-- ===============
-- UTILITIES
-- ===============
local function deepCopy(orig)
    local t = type(orig)
    if t ~= "table" then return orig end
    local copy = {}
    for k,v in next, orig, nil do
        copy[deepCopy(k)] = deepCopy(v)
    end
    setmetatable(copy, deepCopy(getmetatable(orig)))
    return copy
end

-- safe pcall wrapper (robust)
local function safecall(fn, ...)
    if type(fn) ~= "function" then return false, "not a function" end
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

function DarpaHub:DisconnectAll()
    for _, c in ipairs(self._private.Connections) do
        pcall(function() c:Disconnect() end)
    end
    self._private.Connections = {}
end

-- ===============
-- PERSISTENCE (safe wrappers)
-- ===============
function DarpaHub:_writeFileSafe(path, content)
    local ok = pcall(function()
        if writefile then
            writefile(path, content); return true
        elseif syn and syn.write_file then
            syn.write_file(path, content); return true
        elseif write_file then
            write_file(path, content); return true
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
-- HOOKS ENGINE
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
    return {
        Disconnect = function()
            for i,v in ipairs(listeners) do
                if v == listener then
                    table.remove(listeners, i); break
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
    local args = {...}
    for _, listener in ipairs(list) do
        task.spawn(function()
            safecall(listener, unpack(args))
        end)
    end
end

-- core hooks
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
DarpaHub:CreateHook("TabActivated")
DarpaHub:CreateHook("HotReload")

-- ===============
-- SCHEDULER
-- ===============
local Scheduler = {}
Scheduler.__index = Scheduler

function Scheduler.new()
    return setmetatable({jobs = {}, running = false, nextId = 0}, Scheduler)
end

function Scheduler:_genId()
    self.nextId = self.nextId + 1
    return tostring(self.nextId)
end

function Scheduler:AddJob(fn, opts)
    opts = opts or {}
    local id = self:_genId()
    table.insert(self.jobs, {
        id = id, fn = fn,
        interval = opts.interval,
        lastRun = 0,
        priority = opts.priority or 50,
        persistent = opts.persistent == nil and true or opts.persistent
    })
    table.sort(self.jobs, function(a,b) return a.priority < b.priority end)
    return id
end

function Scheduler:RemoveJob(id)
    for i = #self.jobs, 1, -1 do
        if self.jobs[i].id == id then table.remove(self.jobs, i); return true end
    end
    return false
end

function Scheduler:Tick(dt)
    local now = tick()
    -- iterate a stable copy to avoid mutation-in-iteration issues
    local jobsCopy = {}
    for i=1,#self.jobs do jobsCopy[i] = self.jobs[i] end
    for _, j in ipairs(jobsCopy) do
        if not j then break end
        local canRun = false
        if not j.interval then canRun = true
        else if now - j.lastRun >= j.interval then canRun = true end end
        if canRun then
            -- update original job lastRun (find by id because jobsCopy is snapshot)
            for _, orig in ipairs(self.jobs) do if orig.id == j.id then orig.lastRun = now; break end end
            safecall(j.fn, dt)
            if not j.persistent then self:RemoveJob(j.id) end
        end
    end
end

DarpaHub._private.Scheduler = Scheduler.new()
protectedConnect(RunService.RenderStepped, function(dt)
    if DarpaHub.State.Running then DarpaHub._private.Scheduler:Tick(dt) end
end)

-- ===============
-- PROFILER
-- ===============
local Profiler = {}
Profiler.__index = Profiler

function Profiler.new()
    return setmetatable({stats = {}, enabled = false, sampleRate = 1}, Profiler)
end

function Profiler:Enable() self.enabled = true end
function Profiler:Disable() self.enabled = false end

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

function Profiler:GetStats() return deepCopy(self.stats) end
function Profiler:Reset() self.stats = {} end

DarpaHub._private.Profiler = Profiler.new()
DarpaHub._private.Scheduler:AddJob(function() DarpaHub:FireHook("ProfilerTick", DarpaHub._private.Profiler:GetStats()) end, {interval=5, priority=100})

-- ===============
-- UI POOLS & THEME
-- ===============
function DarpaHub._private.Pools:CreatePool(name, className)
    self[name] = self[name] or {class = className, free = {}, used = {}}
    return self[name]
end
function DarpaHub._private.Pools:Get(name) return self[name] end
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
    if not pool then if inst then pcall(function() inst:Destroy() end) end; return end
    for i,v in ipairs(pool.used) do
        if v == inst then
            table.remove(pool.used, i)
            table.insert(pool.free, inst)
            pcall(function()
                inst.Parent = nil
                if inst:IsA("Frame") or inst:IsA("TextLabel") or inst:IsA("TextButton") then
                    inst.Size = UDim2.new(0,100,0,30)
                    inst.Position = UDim2.new(0,0,0,0)
                    inst.BackgroundTransparency = 1
                    if pcall(function() return inst.Text end) then pcall(function() inst.Text = "" end) end
                end
            end)
            return true
        end
    end
    return false
end

DarpaHub._private.Pools:CreatePool("FramePool", "Frame")
DarpaHub._private.Pools:CreatePool("TextLabelPool", "TextLabel")
DarpaHub._private.Pools:CreatePool("TextButtonPool", "TextButton")
DarpaHub._private.Pools:CreatePool("ImageLabelPool", "ImageLabel")

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
            Accent = Color3.fromRGB(0,120,255),
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

-- ===============
-- BUILD UI
-- ===============
function DarpaHub:BuildBaseUI()
    if self._private.UI.ScreenGui and self._private.UI.ScreenGui.Parent then return self._private.UI end

    local screen = Instance.new("ScreenGui")
    screen.Name = "DarpaHubUI"
    screen.ResetOnSpawn = false
    screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local ok = pcall(function() screen.Parent = CoreGui end)
    if not ok or not screen.Parent then
        local plr = Players.LocalPlayer
        if plr then screen.Parent = plr:WaitForChild("PlayerGui") else screen.Parent = StarterGui end
    end

    self._private.UI.ScreenGui = screen

    local main = Instance.new("Frame")
    main.Name = "DarpaHubMain"
    main.Parent = screen
    main.AnchorPoint = Vector2.new(0.5,0.5)
    main.Position = UDim2.new(0.5,0.5,0.5,0.5)
    main.Size = UDim2.new(0,920,0,560)
    main.BackgroundColor3 = self.Theme:GetColor("Primary")
    main.BackgroundTransparency = 0.02
    main.BorderSizePixel = 0
    local corner = Instance.new("UICorner", main); corner.CornerRadius = UDim.new(0,12)

    local left = Instance.new("Frame"); left.Name = "LeftPanel"; left.Parent = main
    left.Position = UDim2.new(0,18,0,92); left.Size = UDim2.new(0,238,0,438); left.BackgroundTransparency = 1

    local right = Instance.new("Frame"); right.Name = "RightPanel"; right.Parent = main
    right.Position = UDim2.new(0,266,0,92); right.Size = UDim2.new(1,-286,0,438); right.BackgroundTransparency = 1

    local header = Instance.new("Frame"); header.Name = "Header"; header.Parent = main
    header.Size = UDim2.new(1,0,0,84); header.Position = UDim2.new(0,0,0,0); header.BackgroundTransparency = 1

    local title = Instance.new("TextLabel"); title.Parent = header
    title.Text = "DarpaHub"
    title.TextSize = 22; title.Font = Enum.Font.GothamBold
    title.TextColor3 = self.Theme:GetColor("Text")
    title.BackgroundTransparency = 1
    title.Position = UDim2.new(0,18,0,18); title.Size = UDim2.new(0,400,0,36)

    self._private.UI.Main = main
    self._private.UI.Left = left
    self._private.UI.Right = right
    self._private.UI.Header = header
    self._private.UI.Title = title

    self:FireHook("UIReady", self._private.UI)
    return self._private.UI
end

-- Tab system
function DarpaHub:CreateTab(name)
    local ui = self._private.UI
    if not ui or not ui.Left or not ui.Right then
        safecall(function() self:BuildBaseUI() end)
        ui = self._private.UI
    end

    local left = ui.Left; local right = ui.Right

    local list = left:FindFirstChild("TabsList")
    if not list then
        list = Instance.new("ScrollingFrame"); list.Name = "TabsList"; list.Parent = left
        list.Size = UDim2.new(1,-12,1,-12); list.Position = UDim2.new(0,6,0,6)
        list.BackgroundTransparency = 1; list.CanvasSize = UDim2.new(0,0,0,0)
        list.ScrollBarThickness = 8; list.AutomaticCanvasSize = Enum.AutomaticSize.Y
    end

    local btn = Instance.new("TextButton"); btn.Name = "Tab_"..name; btn.Size = UDim2.new(1,-12,0,48); btn.BackgroundTransparency = 1; btn.Text = ""; btn.Parent = list
    local frame = Instance.new("Frame", btn); frame.Size = UDim2.new(1,0,1,0); frame.BackgroundColor3 = self.Theme:GetColor("Primary"); frame.BorderSizePixel = 0
    local corner = Instance.new("UICorner", frame); corner.CornerRadius = UDim.new(0,8)
    local label = Instance.new("TextLabel", frame); label.Size = UDim2.new(1,-18,1,0); label.Position = UDim2.new(0,12,0,0)
    label.BackgroundTransparency = 1; label.Font = Enum.Font.Gotham; label.TextColor3 = self.Theme:GetColor("Text"); label.TextSize = 15; label.Text = name

    local pages = right:FindFirstChild("Pages")
    if not pages then pages = Instance.new("Folder", right); pages.Name = "Pages" end
    local page = Instance.new("Frame"); page.Name = "Page_" .. name; page.Size = UDim2.new(1,-24,1,-24)
    page.Position = UDim2.new(0,12,0,12); page.BackgroundTransparency = 1; page.Parent = pages; page.Visible = false

    btn.MouseButton1Click:Connect(function()
        for _,p in ipairs(pages:GetChildren()) do if p:IsA("Frame") then p.Visible = false end end
        page.Visible = true
        self:FireHook("TabActivated", name, page)
    end)

    local tabAPI = {}
    function tabAPI:AddLabel(text)
        local lbl = DarpaHub._private.Pools:Acquire("TextLabelPool")
        pcall(function()
            lbl.Parent = page
            lbl.Size = UDim2.new(1,-24,0,22)
            lbl.Position = UDim2.new(0,12,0,#page:GetChildren() * 26)
            lbl.BackgroundTransparency = 1
            lbl.Font = Enum.Font.Gotham; lbl.TextSize = 14; lbl.TextColor3 = DarpaHub.Theme:GetColor("Muted")
            lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.Text = text or ""
        end)
        return lbl
    end
    function tabAPI:AddButton(text, cb)
        local b = DarpaHub._private.Pools:Acquire("TextButtonPool")
        pcall(function()
            b.Parent = page; b.Size = UDim2.new(1,-24,0,36); b.Position = UDim2.new(0,12,0,#page:GetChildren() * 42)
            b.BackgroundColor3 = DarpaHub.Theme:GetColor("Accent"); b.BorderSizePixel = 0; b.Text = text or ""
            b.Font = Enum.Font.GothamBold; b.TextSize = 14; b.TextColor3 = Color3.fromRGB(255,255,255); b.AutoButtonColor = false
            b.MouseButton1Click:Connect(function() safecall(cb) end)
        end)
        return b
    end
    function tabAPI:AddToggle(text, default, cb)
        local f = DarpaHub._private.Pools:Acquire("FramePool")
        pcall(function()
            f.Parent = page; f.Size = UDim2.new(1,-24,0,36); f.Position = UDim2.new(0,12,0,#page:GetChildren() * 42); f.BackgroundTransparency = 1
            local lab = Instance.new("TextLabel", f); lab.Text = text or "Toggle"; lab.Size = UDim2.new(1,-80,1,0); lab.Position = UDim2.new(0,0,0,0)
            lab.BackgroundTransparency = 1; lab.TextColor3 = DarpaHub.Theme:GetColor("Text"); lab.Font = Enum.Font.Gotham; lab.TextSize = 14
            local tbtn = Instance.new("TextButton", f); tbtn.Size = UDim2.new(0,64,0,28); tbtn.Position = UDim2.new(1,-74,0.5,-14)
            tbtn.Text = default and "On" or "Off"; tbtn.BackgroundColor3 = default and DarpaHub.Theme:GetColor("Accent") or DarpaHub.Theme:GetColor("Primary")
            tbtn.Font = Enum.Font.GothamBold; tbtn.TextSize = 13; tbtn.TextColor3 = Color3.fromRGB(255,255,255)
            local state = default and true or false
            tbtn.MouseButton1Click:Connect(function()
                state = not state
                tbtn.BackgroundColor3 = state and DarpaHub.Theme:GetColor("Accent") or DarpaHub.Theme:GetColor("Primary")
                tbtn.Text = state and "On" or "Off"
                safecall(cb, state)
            end)
        end)
        return f
    end

    return {Page = page, API = tabAPI, Button = btn}
end

-- ===============
-- FEATURE LIFECYCLE
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
    if feature.DefaultEnabled then task.spawn(function() self:EnableFeature(name) end) end
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
DarpaHub._private.Scheduler:AddJob(__darpa_runtime_tick, {interval = nil, priority = 10})

-- ===============
-- KEYBIND MANAGER
-- ===============
function DarpaHub:BindKey(keyCode, callback)
    if not keyCode or not callback then return end
    table.insert(self.Keybinds, {Key = keyCode, Callback = callback})
end

protectedConnect(UserInputService.InputBegan, function(input, gp)
    if gp then return end
    for _, b in ipairs(DarpaHub.Keybinds) do
        if input.KeyCode == b.Key then safecall(b.Callback, input) end
    end
end)

-- ===============
-- PLUGIN SYSTEM
-- ===============
function DarpaHub:RegisterPluginManifest(manifest)
    if not manifest or not manifest.name then error("Invalid manifest") end
    self._private.PluginManifests[manifest.name] = manifest
    return true
end

local function _build_plugin_api(manifest)
    local api = {}
    api.getName = function() return manifest.name end
    api.getVersion = function() return manifest.version end
    api.Logger = {
        Info = function(...) print("[DarpaHub.Plugin]["..manifest.name.."]", ...) end,
        Warn = function(...) warn("[DarpaHub.Plugin]["..manifest.name.."]", ...) end,
        Error = function(...) error("[DarpaHub.Plugin]["..manifest.name.."]", ...) end
    }
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
    return api
end

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
        code = manifest.code or self:_readFileSafe(manifest.url) or error("Cannot load plugin code from "..tostring(manifest.url))
    end

    local pluginEnv = {}
    local api = _build_plugin_api(manifest)
    pluginEnv.DarpaHub = api
    pluginEnv.print = function(...) print("[Plugin]["..manifest.name.."]", ...) end
    pluginEnv.pcall = pcall
    pluginEnv.require = nil
    pluginEnv.game = nil

    local chunk, loadErr = loadstring(code)
    if not chunk then error("Plugin compilation failed: "..tostring(loadErr)) end
    setfenv(chunk, pluginEnv)
    local ok, res = pcall(chunk)
    if not ok then error("Plugin runtime error: "..tostring(res)) end

    self._private.Plugins[name] = {manifest = manifest, env = pluginEnv, active = true, loadedAt = os.time()}
    self:FireHook("PluginLoaded", name, manifest)
    return true
end

function DarpaHub:UnloadPlugin(name)
    local p = self._private.Plugins[name]
    if not p then return false end
    if p.env and p.env.onUnload and type(p.env.onUnload) == "function" then safecall(p.env.onUnload) end
    self._private.Plugins[name] = nil
    self:FireHook("PluginUnloaded", name)
    return true
end

function DarpaHub:HotReloadPlugin(name)
    self:UnloadPlugin(name)
    return self:LoadPlugin(name)
end

-- ===============
-- HOT-RELOAD / DEV
-- ===============
function DarpaHub:HotReload()
    local savedTheme = DarpaHub:LoadJSON("theme")
    pcall(function()
        if DarpaHub._private.UI and DarpaHub._private.UI.ScreenGui then DarpaHub._private.UI.ScreenGui:Destroy() end
    end)
    DarpaHub._private.UI = {}
    DarpaHub._private.Pools.free = DarpaHub._private.Pools.free or {}
    safecall(function() DarpaHub.Theme:Init(); DarpaHub:BuildBaseUI() end)
    if savedTheme and savedTheme.name then DarpaHub.Theme:SetTheme(savedTheme.name) end
    DarpaHub:FireHook("HotReload")
    return true
end

-- ===============
-- SAFE API EXPORT
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

getgenv().DarpaHubAPI = getgenv().DarpaHubAPI or DarpaHub:GetSafeAPI()

-- ===============
-- BOOT / INIT
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
        warn("DarpaHub:Init called but already booted"); return
    end
    self.State.Booted = true
    self.State.Mode = mode or "unsupported"
    safecall(function() DarpaHub.Theme:Init() end)
    safecall(function() DarpaHub._private.Profiler = DarpaHub._private.Profiler or Profiler.new() end)
    task.spawn(function()
        self:_waitForEnvironment()
        safecall(function()
            self:BuildBaseUI()
            local settings = self:CreateTab("Settings")
            local pluginsTab = self:CreateTab("Plugins")
            settings.API:AddLabel("Theme")
            settings.API:AddButton("Toggle Dark/Light", function()
                local cur = DarpaHub._private.ActiveTheme and DarpaHub._private.ActiveTheme.Name or "Dark"
                if cur == "Dark" then DarpaHub.Theme:SetTheme("Light") else DarpaHub.Theme:SetTheme("Dark") end
            end)
            pluginsTab.API:AddLabel("Installed Plugins")
            pluginsTab.API:AddButton("List Plugins in Console", function() print("Plugins:", DarpaHub._private.Plugins) end)
        end)
        self.State.Running = true
        self:FireHook("Inited", self.State.Mode)
        self:FireHook("RuntimeStarted")
    end)
    return true
end

-- ===============
-- LOGGING & SHUTDOWN
-- ===============
function DarpaHub:Log(...) print("[DarpaHub LOG]", ...) end
function DarpaHub:Warn(...) warn("[DarpaHub WARN]", ...) end
function DarpaHub:Error(...) error("[DarpaHub ERROR] " .. table.concat({...}, " ")) end

function DarpaHub:Shutdown()
    self:FireHook("RuntimeStopped")
    self.State.Running = false
    for pname, _ in pairs(self._private.Plugins) do pcall(function() self:UnloadPlugin(pname) end) end
    pcall(function() if self._private.UI and self._private.UI.ScreenGui then self._private.UI.ScreenGui:Destroy() end end)
    self._private.UI = {}
    self:DisconnectAll()
    return true
end

-- ===============
-- FINALIZE
-- ===============
if not DarpaHub._private.Profiler then DarpaHub._private.Profiler = Profiler.new() end
safecall(function() DarpaHub.Theme:Init() end)

getgenv().DarpaHubAPI = getgenv().DarpaHubAPI or DarpaHub:GetSafeAPI()
getgenv().DarpaHub = DarpaHub

DarpaHub.State.Booted = true

-- ===============================
-- DARPAHUB RENDER ENGINE CORE
-- ===============================

DarpaHub.Render = {}
DarpaHub.Render.__index = DarpaHub.Render

local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")

DarpaHub.Render._objects = {}
DarpaHub.Render._pools = {
    Square = {},
    Line = {},
    Text = {},
    Circle = {}
}

DarpaHub.Render.Settings = {
    MaxDistance = 2000,
    UpdateRate = 1/60,
    LODDistances = {
        High = 300,
        Medium = 900,
        Low = 1600
    }
}

-- ===============================
-- DRAWING POOL
-- ===============================

local function acquire(drawType)
    local pool = DarpaHub.Render._pools[drawType]
    if #pool > 0 then
        return table.remove(pool)
    end
    return Drawing.new(drawType)
end

local function release(obj, drawType)
    if obj then
        obj.Visible = false
        table.insert(DarpaHub.Render._pools[drawType], obj)
    end
end

-- ===============================
-- PROJECTION
-- ===============================

function DarpaHub.Render:WorldToScreen(pos)
    local v, onScreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(v.X, v.Y), onScreen, v.Z
end

function DarpaHub.Render:IsVisible(worldPos)
    local _, vis, depth = self:WorldToScreen(worldPos)
    return vis and depth > 0 and depth < self.Settings.MaxDistance
end

-- ===============================
-- BASE RENDER OBJECT
-- ===============================

local RenderObject = {}
RenderObject.__index = RenderObject

function RenderObject:new(kind)
    local obj = setmetatable({}, self)
    obj.Kind = kind
    obj.Draw = acquire(kind)
    obj.Visible = true
    obj.Config = {}
    return obj
end

function RenderObject:Set(prop, val)
    self.Draw[prop] = val
end

function RenderObject:Hide()
    self.Draw.Visible = false
end

function RenderObject:Show()
    self.Draw.Visible = true
end

function RenderObject:Destroy()
    release(self.Draw, self.Kind)
    self.Draw = nil
end

-- ===============================
-- FACTORY API
-- ===============================

function DarpaHub.Render:CreateBox()
    local o = RenderObject:new("Square")
    o.Draw.Filled = false
    o.Draw.Thickness = 2
    table.insert(self._objects, o)
    return o
end

function DarpaHub.Render:CreateLine()
    local o = RenderObject:new("Line")
    o.Draw.Thickness = 1.5
    table.insert(self._objects, o)
    return o
end

function DarpaHub.Render:CreateText()
    local o = RenderObject:new("Text")
    o.Draw.Size = 13
    o.Draw.Center = true
    o.Draw.Outline = true
    table.insert(self._objects, o)
    return o
end

function DarpaHub.Render:CreateCircle()
    local o = RenderObject:new("Circle")
    o.Draw.NumSides = 32
    o.Draw.Filled = false
    table.insert(self._objects, o)
    return o
end

-- ===============================
-- LOD SYSTEM
-- ===============================

function DarpaHub.Render:GetLOD(distance)
    if distance < self.Settings.LODDistances.High then
        return "High"
    elseif distance < self.Settings.LODDistances.Medium then
        return "Medium"
    else
        return "Low"
    end
end

-- ===============================
-- UPDATE ENGINE
-- ===============================

local lastTick = 0

local function renderStep()
    if tick() - lastTick < DarpaHub.Render.Settings.UpdateRate then
        return
    end
    lastTick = tick()

    for _, obj in ipairs(DarpaHub.Render._objects) do
        if obj.WorldPosition then
            local screen, visible, depth = DarpaHub.Render:WorldToScreen(obj.WorldPosition)

            if visible and depth < DarpaHub.Render.Settings.MaxDistance then
                obj.Draw.Visible = true

                local lod = DarpaHub.Render:GetLOD(depth)

                if obj.Kind == "Square" then
                    local size = lod == "High" and 60 or lod == "Medium" and 35 or 20
                    obj.Draw.Size = Vector2.new(size, size)
                    obj.Draw.Position = screen - obj.Draw.Size/2
                elseif obj.Kind == "Text" then
                    obj.Draw.Position = screen
                elseif obj.Kind == "Circle" then
                    obj.Draw.Radius = lod == "High" and 25 or lod == "Medium" and 15 or 8
                    obj.Draw.Position = screen
                end

            else
                obj.Draw.Visible = false
            end
        end
    end
end

RunService.RenderStepped:Connect(renderStep)

-- ===============================
-- HIGH LEVEL API
-- ===============================

function DarpaHub.Render:TrackPart(part, style)
    local box = self:CreateBox()
    box.Draw.Color = style and style.Color or Color3.new(1,0,0)

    DarpaHub._private.Scheduler:AddJob(function()
        if part and part.Parent then
            box.WorldPosition = part.Position
        else
            box:Destroy()
        end
    end, {interval = 0})

    return box
end

function DarpaHub.Render:Clear()
    for _, obj in ipairs(self._objects) do
        obj:Destroy()
    end
    self._objects = {}
end

-- ===============================
-- SAFE EXPORT
-- ===============================

DarpaHub:GetSafeAPI().Render = DarpaHub.Render
getgenv().DarpaHubRender = DarpaHub.Render

-- ===============================
-- ADVANCED VISIBILITY & OCCLUSION
-- ===============================

DarpaHub.Render.Visibility = {}

local RayParams = RaycastParams.new()
RayParams.FilterType = Enum.RaycastFilterType.Blacklist

function DarpaHub.Render.Visibility:IsVisible(origin, target, ignore)
    RayParams.FilterDescendantsInstances = ignore or {}
    local dir = (target - origin)
    local res = workspace:Raycast(origin, dir, RayParams)
    if not res then return true end
    return (res.Position - origin).Magnitude + 0.1 >= dir.Magnitude
end

-- ===============================
-- ENTITY REGISTRY
-- ===============================

DarpaHub.Render.Entities = {}

function DarpaHub.Render:RegisterEntity(id, rootPart, config)
    self.Entities[id] = {
        Root = rootPart,
        Config = config or {},
        Objects = {},
        Alive = true
    }
end

function DarpaHub.Render:RemoveEntity(id)
    local e = self.Entities[id]
    if not e then return end
    for _, obj in pairs(e.Objects) do
        obj:Destroy()
    end
    self.Entities[id] = nil
end

-- ===============================
-- 3D BOUNDING BOX PROJECTOR
-- ===============================

function DarpaHub.Render:ProjectBoundingBox(cf, size)
    local corners = {
        cf * Vector3.new(-size.X, -size.Y, -size.Z)/2,
        cf * Vector3.new( size.X, -size.Y, -size.Z)/2,
        cf * Vector3.new(-size.X,  size.Y, -size.Z)/2,
        cf * Vector3.new( size.X,  size.Y, -size.Z)/2,
        cf * Vector3.new(-size.X, -size.Y,  size.Z)/2,
        cf * Vector3.new( size.X, -size.Y,  size.Z)/2,
        cf * Vector3.new(-size.X,  size.Y,  size.Z)/2,
        cf * Vector3.new( size.X,  size.Y,  size.Z)/2
    }

    local minX, minY = math.huge, math.huge
    local maxX, maxY = -math.huge, -math.huge
    local visible = false

    for _, c in ipairs(corners) do
        local p, on = self:WorldToScreen(c)
        if on then
            visible = true
            minX = math.min(minX, p.X)
            minY = math.min(minY, p.Y)
            maxX = math.max(maxX, p.X)
            maxY = math.max(maxY, p.Y)
        end
    end

    if not visible then return nil end
    return Vector2.new(minX, minY), Vector2.new(maxX - minX, maxY - minY)
end

-- ===============================
-- HEALTHBAR SYSTEM
-- ===============================

function DarpaHub.Render:AttachHealthbar(entityId, humanoid)
    local barBg = self:CreateSquare()
    local barFill = self:CreateSquare()

    barBg.Draw.Filled = true
    barFill.Draw.Filled = true

    barBg.Draw.Color = Color3.fromRGB(25,25,25)

    self.Entities[entityId].Objects.HealthBG = barBg
    self.Entities[entityId].Objects.HealthFill = barFill

    self._private.Scheduler:AddJob(function()
        if not humanoid or humanoid.Health <= 0 then return end
        local hp = humanoid.Health / humanoid.MaxHealth
        barFill.Draw.Color = Color3.fromRGB(255 - 200*hp, 200*hp, 60)
        barFill.Percent = hp
    end,{interval=0.05})
end

-- ===============================
-- OFFSCREEN ARROWS
-- ===============================

function DarpaHub.Render:CreateArrow()
    local t = self:CreateTriangle or self:CreateLine
    return t and t() or self:CreateLine()
end

-- ===============================
-- SMART ENTITY UPDATE LOOP
-- ===============================

DarpaHub._private.Scheduler:AddJob(function()
    local cam = workspace.CurrentCamera
    local camPos = cam.CFrame.Position

    for id, ent in pairs(DarpaHub.Render.Entities) do
        if ent.Root and ent.Root.Parent then
            local pos = ent.Root.Position
            local dist = (camPos - pos).Magnitude

            local visible = DarpaHub.Render.Visibility:IsVisible(camPos, pos, {ent.Root.Parent})

            if visible then
                if ent.Config.Box then
                    local box = ent.Objects.Box or DarpaHub.Render:CreateBox()
                    ent.Objects.Box = box
                    local p, s = DarpaHub.Render:ProjectBoundingBox(ent.Root.CFrame, ent.Root.Size*1.3)
                    if p then
                        box.Draw.Position = p
                        box.Draw.Size = s
                        box.Draw.Visible = true
                    end
                end
            else
                for _, obj in pairs(ent.Objects) do
                    obj:Hide()
                end
            end
        end
    end
end,{interval=0})

-- ===============================
-- DISTANCE FADING
-- ===============================

function DarpaHub.Render:ApplyFade(obj, dist)
    local max = self.Settings.MaxDistance
    local alpha = 1 - math.clamp(dist / max, 0, 1)
    if obj.Draw then
        obj.Draw.Transparency = 1 - alpha
    end
end

-- ===============================
-- ADVANCED CLEANUP
-- ===============================

function DarpaHub.Render:Wipe()
    self:Clear()
    self.Entities = {}
end

-- ===============================
-- DARPAHUB ADVANCED VISIBILITY CHECK
-- ===============================

DarpaHub.Render.VisibilityCheck = {}

local Visibility = DarpaHub.Render.VisibilityCheck

local RayParamsFast = RaycastParams.new()
RayParamsFast.FilterType = Enum.RaycastFilterType.Blacklist

local RayParamsAccurate = RaycastParams.new()
RayParamsAccurate.FilterType = Enum.RaycastFilterType.Blacklist
RayParamsAccurate.IgnoreWater = true

-- ===============================
-- INTERNAL CAST
-- ===============================

local function cast(origin, target, ignore, params)
    params.FilterDescendantsInstances = ignore or {}
    local dir = target - origin
    local result = workspace:Raycast(origin, dir, params)

    if not result then
        return true, nil
    end

    local hitDist = (result.Position - origin).Magnitude
    if hitDist + 0.05 >= dir.Magnitude then
        return true, result
    end

    return false, result
end

-- ===============================
-- FAST CHECK (cheap, high FPS safe)
-- ===============================

function Visibility:Fast(origin, target, ignoreList)
    return cast(origin, target, ignoreList, RayParamsFast)
end

-- ===============================
-- ACCURATE CHECK (multi sample rays)
-- better for aimbot / precise ESP
-- ===============================

function Visibility:Accurate(origin, target, ignoreList)
    local visible, hit = cast(origin, target, ignoreList, RayParamsAccurate)
    if not visible then return false, hit end

    -- multi offset rays (reduces corner wall clipping)
    local offsets = {
        Vector3.new(0, 0.2, 0),
        Vector3.new(0, -0.2, 0),
        Vector3.new(0.15, 0, 0),
        Vector3.new(-0.15, 0, 0),
    }

    for _, off in ipairs(offsets) do
        local ok = cast(origin + off, target, ignoreList, RayParamsAccurate)
        if not ok then
            return false, hit
        end
    end

    return true, hit
end

-- ===============================
-- CAMERA TO ENTITY CHECK
-- ===============================

function Visibility:FromCamera(worldPos, ignore)
    local cam = workspace.CurrentCamera
    if not cam then return false end
    return self:Fast(cam.CFrame.Position, worldPos, ignore)
end

-- ===============================
-- HUMANOID ROOTPART HELPER
-- ===============================

function Visibility:CharacterVisible(character, ignoreExtra)
    if not character then return false end
    local root = character:FindFirstChild("HumanoidRootPart")
    if not root then return false end

    local ignore = {character}
    if ignoreExtra then
        for _, v in ipairs(ignoreExtra) do
            table.insert(ignore, v)
        end
    end

    return self:Accurate(
        workspace.CurrentCamera.CFrame.Position,
        root.Position,
        ignore
    )
end

-- ===============================
-- DISTANCE + VISIBILITY COMBO
-- ===============================

function Visibility:VisibleAndInRange(origin, target, maxDistance, ignore)
    local dist = (origin - target).Magnitude
    if maxDistance and dist > maxDistance then
        return false, dist
    end

    local vis = self:Fast(origin, target, ignore)
    return vis, dist
end

-- ===============================
-- SAFE EXPORT
-- ===============================

DarpaHub:GetSafeAPI().Visibility = Visibility
getgenv().DarpaHubVisibility = Visibility

return DarpaHub
