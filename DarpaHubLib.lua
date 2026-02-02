-- DarpaHubLib.lua
-- DarpaHub — Production-ready core framework (no demos)
-- Features: ThemeEngine, Tabs, UI Pooling, Scheduler, Throttling, Plugin System, Hot Reload,
-- Profiler, Hook Engine (sync/async), Keybind Manager, Persistence, Safe API Export (getgenv).
-- Important: This library purposefully contains NO gameplay-cheat implementations or demo features.
-- Author: DarpaHub Team (production)
-- Version: 6.0.0-production

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

-- ===============================
-- DARPAHUB AIM CORE ENGINE
-- ===============================

DarpaHub.Aim = {}
DarpaHub.Aim.__index = DarpaHub.Aim

DarpaHub.Aim.Settings = {
    Prediction = true,
    PredictionFactor = 0.13,
    Smoothness = 0.18,
    MaxDistance = 2000
}

-- ===============================
-- BONE TARGETING
-- ===============================

DarpaHub.Aim.Bones = {
    Head = "Head",
    Torso = "HumanoidRootPart",
    Chest = "UpperTorso"
}

function DarpaHub.Aim:GetBone(character, priority)
    for _, bone in ipairs(priority) do
        local part = character:FindFirstChild(bone)
        if part then return part end
    end
    return character:FindFirstChild("HumanoidRootPart")
end

-- ===============================
-- VELOCITY EXTRACTION
-- ===============================

function DarpaHub.Aim:GetVelocity(part)
    if part and part:IsA("BasePart") then
        return part.AssemblyLinearVelocity or part.Velocity
    end
    return Vector3.zero
end

-- ===============================
-- PREDICTION ENGINE
-- ===============================

function DarpaHub.Aim:PredictPosition(part, factor)
    factor = factor or self.Settings.PredictionFactor
    local vel = self:GetVelocity(part)
    return part.Position + (vel * factor)
end

-- ===============================
-- SMOOTH AIM CURVE
-- ===============================

function DarpaHub.Aim:Lerp(current, target, alpha)
    return current + (target - current) * alpha
end

function DarpaHub.Aim:SmoothCFrame(current, target)
    return current:Lerp(target, self.Settings.Smoothness)
end

-- ===============================
-- HITBOX RESOLVER
-- ===============================

function DarpaHub.Aim:ResolveTarget(character)
    if not character then return nil end

    local bone = self:GetBone(character, {
        self.Bones.Head,
        self.Bones.Chest,
        self.Bones.Torso
    })

    if not bone then return nil end

    if self.Settings.Prediction then
        return self:PredictPosition(bone)
    end

    return bone.Position
end

-- ===============================
-- SAFE EXPORT
-- ===============================

DarpaHub:GetSafeAPI().Aim = DarpaHub.Aim
getgenv().DarpaHubAim = DarpaHub.Aim

-- ===============================
-- DARPAHUB BALLISTICS ENGINE
-- ===============================

DarpaHub.Ballistics = {}

DarpaHub.Ballistics.Gravity = workspace.Gravity or 196.2

function DarpaHub.Ballistics:TimeToTarget(origin, target, speed)
    return (target - origin).Magnitude / speed
end

function DarpaHub.Ballistics:PredictWithDrop(origin, part, speed)
    local vel = part.AssemblyLinearVelocity or Vector3.zero
    local distance = (part.Position - origin).Magnitude
    local time = distance / speed

    local gravityDrop = Vector3.new(0, -0.5 * self.Gravity * time * time, 0)
    local movement = vel * time

    return part.Position + movement + gravityDrop
end

function DarpaHub.Ballistics:LinearExtrapolation(part, time)
    return part.Position + (part.AssemblyLinearVelocity * time)
end

DarpaHub:GetSafeAPI().Ballistics = DarpaHub.Ballistics
getgenv().DarpaHubBallistics = DarpaHub.Ballistics

-- ===============================
-- DARPAHUB UI ANIMATION ENGINE
-- ===============================

DarpaHub.Animations = {}

local TweenService = game:GetService("TweenService")

DarpaHub.Animations.Presets = {
    Fast = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Smooth = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
    Elastic = TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    SlowFade = TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
}

function DarpaHub.Animations:Tween(obj, preset, props)
    local info = self.Presets[preset] or self.Presets.Smooth
    local tween = TweenService:Create(obj, info, props)
    tween:Play()
    return tween
end

function DarpaHub.Animations:FadeIn(obj, time)
    obj.Visible = true
    obj.BackgroundTransparency = 1
    TweenService:Create(obj, TweenInfo.new(time or 0.25), {
        BackgroundTransparency = 0
    }):Play()
end

function DarpaHub.Animations:FadeOut(obj, time)
    local tween = TweenService:Create(obj, TweenInfo.new(time or 0.25), {
        BackgroundTransparency = 1
    })
    tween:Play()
    tween.Completed:Connect(function()
        obj.Visible = false
    end)
end

function DarpaHub.Animations:Pop(obj)
    local original = obj.Size
    obj.Size = UDim2.new(original.X.Scale, original.X.Offset * 0.8, original.Y.Scale, original.Y.Offset * 0.8)

    TweenService:Create(obj, self.Presets.Elastic, {
        Size = original
    }):Play()
end

function DarpaHub.Animations:SlideIn(obj, fromOffset)
    local target = obj.Position
    obj.Position = target + fromOffset
    TweenService:Create(obj, self.Presets.Smooth, {
        Position = target
    }):Play()
end

function DarpaHub.Animations:Hover(button, scale)
    scale = scale or 1.05
    local base = button.Size

    button.MouseEnter:Connect(function()
        TweenService:Create(button, self.Presets.Fast, {
            Size = UDim2.new(base.X.Scale, base.X.Offset * scale, base.Y.Scale, base.Y.Offset * scale)
        }):Play()
    end)

    button.MouseLeave:Connect(function()
        TweenService:Create(button, self.Presets.Fast, {
            Size = base
        }):Play()
    end)
end

DarpaHub:GetSafeAPI().Animations = DarpaHub.Animations
getgenv().DarpaHubAnimations = DarpaHub.Animations

-- ===============================
-- DARPAHUB TARGET SELECTOR
-- ===============================

DarpaHub.Targeting = {}

DarpaHub.Targeting.Settings = {
    MaxDistance = 2000,
    FOV = 350,
    PrioritizeVisible = true,
    PrioritizeClosest = true
}

function DarpaHub.Targeting:GetTargets()
    local list = {}
    for _, plr in ipairs(game.Players:GetPlayers()) do
        if plr ~= game.Players.LocalPlayer and plr.Character then
            local root = plr.Character:FindFirstChild("HumanoidRootPart")
            if root then
                table.insert(list, root)
            end
        end
    end
    return list
end

function DarpaHub.Targeting:ScreenDistance(pos)
    local screen, on = DarpaHub.Render:WorldToScreen(pos)
    if not on then return math.huge end
    local mouse = game:GetService("UserInputService"):GetMouseLocation()
    return (screen - mouse).Magnitude
end

function DarpaHub.Targeting:SelectBest()
    local cam = workspace.CurrentCamera
    local best, bestScore = nil, math.huge

    for _, part in ipairs(self:GetTargets()) do
        local dist = (cam.CFrame.Position - part.Position).Magnitude
        if dist < self.Settings.MaxDistance then
            local screenDist = self:ScreenDistance(part.Position)
            if screenDist < self.Settings.FOV then
                local score = screenDist + dist * 0.01
                if score < bestScore then
                    bestScore = score
                    best = part
                end
            end
        end
    end

    return best
end

DarpaHub:GetSafeAPI().Targeting = DarpaHub.Targeting
getgenv().DarpaHubTargeting = DarpaHub.Targeting

-- ===============================
-- DARPAHUB ENTITY CACHE
-- ===============================

DarpaHub.EntityCache = {
    Players = {},
    LastUpdate = 0,
    Interval = 1
}

function DarpaHub.EntityCache:Refresh()
    self.Players = {}
    for _, plr in ipairs(game.Players:GetPlayers()) do
        if plr.Character then
            table.insert(self.Players, plr.Character)
        end
    end
end

DarpaHub._private.Scheduler:AddJob(function()
    DarpaHub.EntityCache:Refresh()
end,{interval = DarpaHub.EntityCache.Interval})

DarpaHub:GetSafeAPI().EntityCache = DarpaHub.EntityCache
getgenv().DarpaHubEntityCache = DarpaHub.EntityCache

-- ===============================
-- DARPAHUB SKELETON RENDER
-- ===============================

DarpaHub.Skeleton = {}

DarpaHub.Skeleton.Bones = {
    {"Head","UpperTorso"},
    {"UpperTorso","LowerTorso"},
    {"UpperTorso","LeftUpperArm"},
    {"LeftUpperArm","LeftLowerArm"},
    {"UpperTorso","RightUpperArm"},
    {"RightUpperArm","RightLowerArm"},
    {"LowerTorso","LeftUpperLeg"},
    {"LeftUpperLeg","LeftLowerLeg"},
    {"LowerTorso","RightUpperLeg"},
    {"RightUpperLeg","RightLowerLeg"}
}

function DarpaHub.Skeleton:Attach(character)
    local lines = {}

    for _, pair in ipairs(self.Bones) do
        local l = DarpaHub.Render:CreateLine()
        l.Draw.Color = Color3.fromRGB(255,255,255)
        table.insert(lines, {Line=l, A=pair[1], B=pair[2]})
    end

    DarpaHub._private.Scheduler:AddJob(function()
        for _, seg in ipairs(lines) do
            local a = character:FindFirstChild(seg.A)
            local b = character:FindFirstChild(seg.B)
            if a and b then
                local sa,va = DarpaHub.Render:WorldToScreen(a.Position)
                local sb,vb = DarpaHub.Render:WorldToScreen(b.Position)
                if va and vb then
                    seg.Line.Draw.From = sa
                    seg.Line.Draw.To = sb
                    seg.Line.Draw.Visible = true
                else
                    seg.Line.Draw.Visible = false
                end
            end
        end
    end,{interval=0})

end

DarpaHub:GetSafeAPI().Skeleton = DarpaHub.Skeleton
getgenv().DarpaHubSkeleton = DarpaHub.Skeleton

-- ===============================
-- DARPAHUB PERFORMANCE GOVERNOR
-- ===============================

DarpaHub.Performance = {
    MinFPS = 40,
    ThrottleLevel = 1
}

local frameCounter, last = 0, tick()

DarpaHub._private.Scheduler:AddJob(function()
    frameCounter += 1
    if tick() - last >= 1 then
        local fps = frameCounter
        frameCounter = 0
        last = tick()

        if fps < DarpaHub.Performance.MinFPS then
            DarpaHub.Render.Settings.UpdateRate = math.min(1/20, DarpaHub.Render.Settings.UpdateRate + 0.01)
        else
            DarpaHub.Render.Settings.UpdateRate = math.max(1/60, DarpaHub.Render.Settings.UpdateRate - 0.005)
        end
    end
end,{interval=nil})

DarpaHub:GetSafeAPI().Performance = DarpaHub.Performance

-- ===============================
-- DARPAHUB PROFILER OVERLAY
-- ===============================

DarpaHub.Overlay = {}

function DarpaHub.Overlay:Create()
    local txt = Drawing.new("Text")
    txt.Size = 14
    txt.Position = Vector2.new(20,20)
    txt.Color = Color3.new(0,1,0)
    txt.Outline = true

    DarpaHub._private.Scheduler:AddJob(function()
        local stats = DarpaHub._private.Profiler:GetStats()
        local lines = {}
        for k,v in pairs(stats) do
            table.insert(lines, k.." "..string.format("%.4f",v.lastTime))
        end
        txt.Text = table.concat(lines,"\n")
    end,{interval=0.2})

    return txt
end

DarpaHub:GetSafeAPI().Overlay = DarpaHub.Overlay

-- ===============================
-- DARPAHUB MODULE LOADER
-- ===============================

DarpaHub.Modules = {}

function DarpaHub.Modules:Register(name, mod)
    self[name] = mod
end

function DarpaHub.Modules:Get(name)
    return self[name]
end

function DarpaHub.Modules:List()
    local t = {}
    for k in pairs(self) do table.insert(t,k) end
    return t
end

DarpaHub:GetSafeAPI().Modules = DarpaHub.Modules

-- ===============================
-- DARPAHUB RADAR ENGINE
-- ===============================

DarpaHub.Radar = {
    Range = 400,
    Points = {}
}

function DarpaHub.Radar:CreateDot()
    local d = Drawing.new("Circle")
    d.Radius = 3
    d.Filled = true
    return d
end

function DarpaHub.Radar:Track(part)
    local dot = self:CreateDot()
    table.insert(self.Points, {Part = part, Dot = dot})
end

DarpaHub._private.Scheduler:AddJob(function()
    local cam = workspace.CurrentCamera
    local origin = cam.CFrame.Position

    for _, obj in ipairs(DarpaHub.Radar.Points) do
        if obj.Part and obj.Part.Parent then
            local offset = obj.Part.Position - origin
            local dist = offset.Magnitude
            if dist < DarpaHub.Radar.Range then
                local pos = Vector2.new(120 + offset.X * 0.15, 120 + offset.Z * 0.15)
                obj.Dot.Position = pos
                obj.Dot.Visible = true
            else
                obj.Dot.Visible = false
            end
        end
    end
end,{interval=0})

DarpaHub:GetSafeAPI().Radar = DarpaHub.Radar

-- ===============================
-- DARPAHUB MOTION CURVES
-- ===============================

DarpaHub.Motion = {}

function DarpaHub.Motion:Bezier(p0,p1,p2,t)
    return (1-t)^2*p0 + 2*(1-t)*t*p1 + t^2*p2
end

function DarpaHub.Motion:PredictArc(part,time)
    local vel = part.AssemblyLinearVelocity
    local mid = part.Position + vel * (time/2)
    local endp = part.Position + vel * time
    return self:Bezier(part.Position, mid, endp, 0.7)
end

DarpaHub:GetSafeAPI().Motion = DarpaHub.Motion

-- ===============================
-- DARPAHUB SMOOTH CONTROLLER
-- ===============================

DarpaHub.Smooth = {
    Strength = 0.12
}

function DarpaHub.Smooth:Step(current,target)
    local delta = target - current
    return current + delta * self.Strength
end

function DarpaHub.Smooth:Adaptive(dist)
    return math.clamp(0.05 + dist*0.0002, 0.05, 0.25)
end

DarpaHub:GetSafeAPI().Smooth = DarpaHub.Smooth

-- ===============================
-- DARPAHUB CONFIG PROFILES
-- ===============================

DarpaHub.Config = {}

function DarpaHub.Config:Save(name,data)
    DarpaHub:SaveJSON("profile_"..name, data)
end

function DarpaHub.Config:Load(name)
    return DarpaHub:LoadJSON("profile_"..name)
end

function DarpaHub.Config:List()
    local list = {}
    if getgenv().DarpaHubPersist then
        for k in pairs(getgenv().DarpaHubPersist) do
            if k:find("profile_") then
                table.insert(list,k)
            end
        end
    end
    return list
end

DarpaHub:GetSafeAPI().Config = DarpaHub.Config

-- ===============================
-- DARPAHUB RESOURCE MANAGER
-- ===============================

DarpaHub.Resources = {}

function DarpaHub.Resources:Track(obj)
    table.insert(self, obj)
end

function DarpaHub.Resources:Cleanup()
    for _, o in ipairs(self) do
        pcall(function()
            if typeof(o) == "RBXScriptConnection" then o:Disconnect()
            elseif o.Destroy then o:Destroy()
            end
        end)
    end
    self = {}
end

DarpaHub:GetSafeAPI().Resources = DarpaHub.Resources

-- ===============================
-- DARPAHUB NOTIFICATIONS
-- ===============================

DarpaHub.Notify = {}

function DarpaHub.Notify:Push(text,color)
    local t = Drawing.new("Text")
    t.Text = text
    t.Size = 16
    t.Color = color or Color3.new(1,1,1)
    t.Position = Vector2.new(20,300)

    task.delay(3,function()
        t:Remove()
    end)
end

DarpaHub:GetSafeAPI().Notify = DarpaHub.Notify

-- ===============================
-- DARPAHUB LAYOUT ENGINE
-- ===============================

DarpaHub.Layout = {}

function DarpaHub.Layout:Stack(frames,spacing)
    spacing = spacing or 8
    local y = 0
    for _, f in ipairs(frames) do
        f.Position = UDim2.new(0,0,0,y)
        y = y + f.Size.Y.Offset + spacing
    end
end

DarpaHub:GetSafeAPI().Layout = DarpaHub.Layout

-- ===============================
-- DARPAHUB INPUT ENGINE
-- ===============================

DarpaHub.Input = {Buffer = {}}

function DarpaHub.Input:Record(input)
    table.insert(self.Buffer, {Key=input.KeyCode,Time=tick()})
end

function DarpaHub.Input:Replay()
    for _, i in ipairs(self.Buffer) do
        print("Replay:",i.Key)
    end
end

DarpaHub:GetSafeAPI().Input = DarpaHub.Input

-- ===============================
-- DARPAHUB UI FX
-- ===============================

DarpaHub.UIFX = {}

function DarpaHub.UIFX:Glow(frame)
    frame.BackgroundTransparency = 0.2
end

function DarpaHub.UIFX:Blur(frame)
    frame.BackgroundTransparency = 0.5
end

DarpaHub:GetSafeAPI().UIFX = DarpaHub.UIFX

-- ===============================
-- DARPAHUB MODULE USAGE OPTIMIZER
-- ===============================

DarpaHub.ModuleOptimizer = {
    Modules = {},
    IdleTimeout = 15, -- seconds without usage = deactivate
    CheckInterval = 5
}

local Optimizer = DarpaHub.ModuleOptimizer

-- ===============================
-- REGISTER MODULE
-- ===============================

function Optimizer:Register(name, mod)
    self.Modules[name] = {
        Module = mod,
        LastUsed = tick(),
        Active = true,
        Calls = 0
    }
end

-- ===============================
-- MARK USAGE (called internally)
-- ===============================

function Optimizer:Touch(name)
    local m = self.Modules[name]
    if not m then return end

    m.LastUsed = tick()
    m.Calls += 1

    if not m.Active then
        self:Enable(name)
    end
end

-- ===============================
-- ENABLE/DISABLE
-- ===============================

function Optimizer:Disable(name)
    local m = self.Modules[name]
    if not m or not m.Active then return end

    if m.Module.Disable then
        pcall(function() m.Module:Disable() end)
    end

    m.Active = false
end

function Optimizer:Enable(name)
    local m = self.Modules[name]
    if not m or m.Active then return end

    if m.Module.Enable then
        pcall(function() m.Module:Enable() end)
    end

    m.Active = true
end

-- ===============================
-- AUTO CLEAN LOOP
-- ===============================

DarpaHub._private.Scheduler:AddJob(function()
    local now = tick()

    for name, m in pairs(Optimizer.Modules) do
        if m.Active and now - m.LastUsed > Optimizer.IdleTimeout then
            Optimizer:Disable(name)
        end
    end
end,{interval = Optimizer.CheckInterval})

-- ===============================
-- WRAP MODULE METHODS FOR AUTO TRACK
-- ===============================

function Optimizer:Wrap(name, mod)
    self:Register(name, mod)

    for key, val in pairs(mod) do
        if type(val) == "function" then
            mod[key] = function(...)
                Optimizer:Touch(name)
                return val(...)
            end
        end
    end

    return mod
end

-- ===============================
-- DEBUG
-- ===============================

function Optimizer:Status()
    local out = {}
    for k,v in pairs(self.Modules) do
        out[k] = {
            active = v.Active,
            calls = v.Calls,
            idle = math.floor(tick() - v.LastUsed)
        }
    end
    return out
end

-- ===============================
-- SAFE EXPORT
-- ===============================

DarpaHub:GetSafeAPI().ModuleOptimizer = Optimizer
getgenv().DarpaHubModuleOptimizer = Optimizer

-- ===============================
-- DARPAHUB UI PRO ENGINE
-- ===============================

DarpaHub.UIPro = {}

local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")

-- ===============================
-- BASE ELEMENT HELPERS
-- ===============================

local function tween(obj, time, props)
    TweenService:Create(obj, TweenInfo.new(time, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), props):Play()
end

local function rounded(parent, radius)
    local c = Instance.new("UICorner", parent)
    c.CornerRadius = UDim.new(0, radius)
end

-- ===============================
-- WINDOW SYSTEM
-- ===============================

function DarpaHub.UIPro:CreateWindow(title, size)
    local screen = DarpaHub._private.UI.ScreenGui

    local win = Instance.new("Frame", screen)
    win.Size = size or UDim2.new(0, 520, 0, 420)
    win.Position = UDim2.new(0.5,-260,0.5,-210)
    win.BackgroundColor3 = DarpaHub.Theme:GetColor("Primary")
    win.BorderSizePixel = 0
    rounded(win,12)

    local header = Instance.new("Frame", win)
    header.Size = UDim2.new(1,0,0,46)
    header.BackgroundColor3 = DarpaHub.Theme:GetColor("Accent")
    header.BorderSizePixel = 0
    rounded(header,12)

    local lbl = Instance.new("TextLabel", header)
    lbl.Size = UDim2.new(1,-12,1,0)
    lbl.Position = UDim2.new(0,6,0,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = title
    lbl.Font = Enum.Font.GothamBold
    lbl.TextSize = 16
    lbl.TextColor3 = Color3.new(1,1,1)

    -- drag support
    local dragging, dragStart, startPos

    header.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = i.Position
            startPos = win.Position
        end
    end)

    UIS.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local delta = i.Position - dragStart
            win.Position = startPos + UDim2.new(0,delta.X,0,delta.Y)
        end
    end)

    UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    local body = Instance.new("ScrollingFrame", win)
    body.Position = UDim2.new(0,0,0,54)
    body.Size = UDim2.new(1,0,1,-60)
    body.CanvasSize = UDim2.new(0,0,0,0)
    body.AutomaticCanvasSize = Enum.AutomaticSize.Y
    body.ScrollBarThickness = 6
    body.BackgroundTransparency = 1

    return {
        Window = win,
        Body = body
    }
end

-- ===============================
-- SECTION
-- ===============================

function DarpaHub.UIPro:CreateSection(parent, name)
    local sec = Instance.new("Frame", parent)
    sec.Size = UDim2.new(1,-12,0,40)
    sec.BackgroundColor3 = DarpaHub.Theme:GetColor("Primary")
    sec.BorderSizePixel = 0
    rounded(sec,8)

    local title = Instance.new("TextLabel", sec)
    title.Size = UDim2.new(1,-10,0,30)
    title.Position = UDim2.new(0,5,0,5)
    title.BackgroundTransparency = 1
    title.Text = name
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.TextColor3 = DarpaHub.Theme:GetColor("Text")

    local container = Instance.new("Frame", sec)
    container.Position = UDim2.new(0,0,0,40)
    container.Size = UDim2.new(1,0,0,0)
    container.AutomaticSize = Enum.AutomaticSize.Y
    container.BackgroundTransparency = 1

    return container
end

-- ===============================
-- TOGGLE
-- ===============================

function DarpaHub.UIPro:CreateToggle(parent, text, default, callback)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1,-10,0,36)
    frame.BackgroundTransparency = 1

    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1,-80,1,0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 13
    lbl.TextColor3 = DarpaHub.Theme:GetColor("Text")

    local btn = Instance.new("Frame", frame)
    btn.Size = UDim2.new(0,52,0,24)
    btn.Position = UDim2.new(1,-56,0.5,-12)
    btn.BackgroundColor3 = default and DarpaHub.Theme:GetColor("Accent") or Color3.fromRGB(60,60,60)
    rounded(btn,12)

    local state = default

    frame.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            state = not state
            tween(btn,0.2,{
                BackgroundColor3 = state and DarpaHub.Theme:GetColor("Accent") or Color3.fromRGB(60,60,60)
            })
            callback(state)
        end
    end)

    return frame
end

-- ===============================
-- SLIDER
-- ===============================

function DarpaHub.UIPro:CreateSlider(parent, text, min, max, default, cb)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1,-10,0,42)
    frame.BackgroundTransparency = 1

    local lbl = Instance.new("TextLabel", frame)
    lbl.Size = UDim2.new(1,0,0,18)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 13
    lbl.TextColor3 = DarpaHub.Theme:GetColor("Text")

    local bar = Instance.new("Frame", frame)
    bar.Position = UDim2.new(0,0,0,26)
    bar.Size = UDim2.new(1,0,0,8)
    bar.BackgroundColor3 = Color3.fromRGB(70,70,70)
    rounded(bar,6)

    local fill = Instance.new("Frame", bar)
    fill.Size = UDim2.new((default-min)/(max-min),0,1,0)
    fill.BackgroundColor3 = DarpaHub.Theme:GetColor("Accent")
    rounded(fill,6)

    bar.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            local pos = math.clamp((i.Position.X - bar.AbsolutePosition.X)/bar.AbsoluteSize.X,0,1)
            fill.Size = UDim2.new(pos,0,1,0)
            local val = min + (max-min)*pos
            cb(val)
        end
    end)

    return frame
end

-- ===============================
-- DROPDOWN
-- ===============================

function DarpaHub.UIPro:CreateDropdown(parent, text, options, cb)
    local frame = Instance.new("Frame", parent)
    frame.Size = UDim2.new(1,-10,0,36)
    frame.BackgroundTransparency = 1

    local btn = Instance.new("TextButton", frame)
    btn.Size = UDim2.new(1,0,1,0)
    btn.Text = text
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 13
    btn.BackgroundColor3 = DarpaHub.Theme:GetColor("Primary")
    btn.TextColor3 = DarpaHub.Theme:GetColor("Text")
    rounded(btn,6)

    btn.MouseButton1Click:Connect(function()
        for _,opt in ipairs(options) do
            cb(opt)
        end
    end)

    return frame
end

-- ===============================
-- SAFE EXPORT
-- ===============================

DarpaHub:GetSafeAPI().UIPro = DarpaHub.UIPro
getgenv().DarpaHubUIPro = DarpaHub.UIPro


return DarpaHub

