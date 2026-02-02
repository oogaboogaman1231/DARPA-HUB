-- DarpaHubExample.lua (Corrected & Fixed)
-- Universal premium example script for DarpaHubLib (v2.0.0-perfect)
-- Demonstrates full use of DarpaHub API: tabs, theme, plugins, scheduler, profiler, hooks, getgenv, FireHook, RenderStepped, CFrame, animated UI, notifications, safe visual tools and production-ready features.
-- IMPORTANT: This example intentionally avoids any gameplay-cheating features. All features are UI/visual/utility oriented and safe.
-- Author: DarpaHub Example Team
-- Date: Corrected version (fixed HttpGet logic & other Lua issues)

-- CONFIG: change LIB_URL to your hosted DarpaHubLib.lua location if needed.
local LIB_URL = "https://example.com/DarpaHubLib.lua" -- replace with your actual URL or let loader provide the lib

-- Attempt to obtain DarpaHub library safely.
local DarpaHub = nil

-- Helper: safe http-get wrapper (works across executors)
local function safeHttpGet(url)
    if not url or type(url) ~= "string" then return nil end
    if type(game.HttpGet) ~= "function" then return nil end
    local ok, res = pcall(function() return game:HttpGet(url) end)
    if ok and type(res) == "string" and #res > 8 then
        return res
    end
    return nil
end

-- Try to reuse already loaded getgenv DarpaHub, otherwise try to download and load it.
if getgenv().DarpaHub and type(getgenv().DarpaHub) == "table" and getgenv().DarpaHub._isDarpaHub then
    DarpaHub = getgenv().DarpaHub
else
    -- try to download
    local code = safeHttpGet(LIB_URL)
    if code then
        local chunk, loadErr = loadstring(code)
        if chunk then
            local ok, ret = pcall(chunk)
            if ok and type(ret) == "table" then
                DarpaHub = ret
                getgenv().DarpaHub = DarpaHub
            else
                warn("[DarpaHubExample] lib chunk executed but returned invalid value:", ret, loadErr)
            end
        else
            warn("[DarpaHubExample] loadstring failed:", loadErr)
        end
    else
        -- fallback: maybe loader already injected it later; try to wait a bit
        local maxWait = 2 -- seconds
        local waited = 0
        while (not getgenv().DarpaHub) and waited < maxWait do
            task.wait(0.1)
            waited = waited + 0.1
        end
        if getgenv().DarpaHub and type(getgenv().DarpaHub) == "table" then
            DarpaHub = getgenv().DarpaHub
        end
    end
end

if not DarpaHub then
    warn("[DarpaHubExample] Failed to obtain DarpaHub library. Ensure LIB_URL is correct or loader already injected the lib.")
    return
end

-- Ensure hub is initialized (defensive)
if not DarpaHub.State or not DarpaHub.State.Booted then
    pcall(function() DarpaHub:Init("unsupported") end)
end

-- Wait for UI system ready (defensive, small timeout)
local function waitUIReady(timeout)
    timeout = timeout or 5
    local elapsed = 0
    while (not DarpaHub._private or not DarpaHub._private.UI or not DarpaHub._private.UI.ScreenGui) and elapsed < timeout do
        task.wait(0.05)
        elapsed = elapsed + 0.05
    end
    return DarpaHub._private and DarpaHub._private.UI and DarpaHub._private.UI.ScreenGui
end

waitUIReady(4)

-- Short aliases
local api = DarpaHub:GetSafeAPI()
local Theme = api.Theme
local Scheduler = api.Scheduler
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Ensure example global container
getgenv().DarpaHubExample = getgenv().DarpaHubExample or {}
local EX = getgenv().DarpaHubExample

-- Utility: nice info print
local function info(...)
    print("[DarpaHubExample]", ...)
end

-- ------------------------
-- Build Tabs
-- ------------------------
local Tabs = {}
Tabs.Main = DarpaHub:CreateTab("Main")
Tabs.Visuals = DarpaHub:CreateTab("Visuals")
Tabs.Performance = DarpaHub:CreateTab("Performance")
Tabs.Plugins = DarpaHub:CreateTab("Plugins")
Tabs.Tools = DarpaHub:CreateTab("Tools")
Tabs.Settings = DarpaHub:CreateTab("Settings")

-- Activate Main tab if possible
pcall(function()
    if Tabs.Main and Tabs.Main.Button then
        Tabs.Main.Button:MouseButton1Click()
    end
end)

-- ------------------------
-- Notifications system (safe GUI-only notifications)
-- ------------------------
local Notifications = {}
Notifications.container = nil
Notifications.counter = 0

local function ensureNotificationContainer()
    if Notifications.container and Notifications.container.Parent then return end
    local screen = DarpaHub._private and DarpaHub._private.UI and (DarpaHub._private.UI.Screen or DarpaHub._private.UI.ScreenGui)
    if not screen then return end
    local cont = Instance.new("Frame")
    cont.Name = "DH_Notifications"
    cont.Size = UDim2.new(0, 320, 0, 240)
    cont.Position = UDim2.new(1, -340, 0, 20)
    cont.BackgroundTransparency = 1
    cont.Parent = screen
    Notifications.container = cont
end

local function notify(title, text, ttl)
    ttl = ttl or 4
    ensureNotificationContainer()
    if not Notifications.container then return end
    Notifications.counter = Notifications.counter + 1
    local id = Notifications.counter

    local card = Instance.new("Frame")
    card.Name = "Notif_" .. id
    card.Size = UDim2.new(1, 0, 0, 64)
    card.Position = UDim2.new(0, 0, 0, ((id-1) * 72))
    card.BackgroundColor3 = Theme:GetColor("Primary")
    card.BorderSizePixel = 0
    card.Parent = Notifications.container
    local corner = Instance.new("UICorner", card); corner.CornerRadius = UDim.new(0,8)

    local titleLabel = Instance.new("TextLabel", card)
    titleLabel.Size = UDim2.new(1, -12, 0, 22)
    titleLabel.Position = UDim2.new(0, 8, 0, 6)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 14
    titleLabel.TextColor3 = Theme:GetColor("Text")
    titleLabel.Text = tostring(title)

    local bodyLabel = Instance.new("TextLabel", card)
    bodyLabel.Size = UDim2.new(1, -12, 0, 32)
    bodyLabel.Position = UDim2.new(0, 8, 0, 28)
    bodyLabel.BackgroundTransparency = 1
    bodyLabel.Font = Enum.Font.Gotham
    bodyLabel.TextSize = 12
    bodyLabel.TextColor3 = Theme:GetColor("Muted")
    bodyLabel.Text = tostring(text)
    bodyLabel.TextWrapped = true

    -- schedule removal
    task.spawn(function()
        task.wait(ttl)
        pcall(function() card:Destroy() end)
    end)

    return id
end

EX.notify = notify

-- ------------------------
-- Hooks demo: create a custom hook and a listener
-- ------------------------
DarpaHub:CreateHook("Example.CustomEvent")
DarpaHub:ConnectHook("Example.CustomEvent", function(infoTbl)
    pcall(function()
        info("CustomEvent fired:", infoTbl and infoTbl.msg)
        notify("Hook event", tostring(infoTbl and infoTbl.msg or "event fired"), 3)
    end)
end)

local function fire_demo_hook()
    DarpaHub:FireHook("Example.CustomEvent", {msg = "Manual demo hook at " .. os.date("%X")})
end

-- ------------------------
-- Performance tab widgets and profiler toggle
-- ------------------------
local perfAPI = Tabs.Performance.API
local fpsLabel = perfAPI:AddLabel("FPS: calculating...")
local memLabel = perfAPI:AddLabel("Memory: calculating...")
local pingLabel = perfAPI:AddLabel("Ping: calculating...")

perfAPI:AddButton("Toggle Profiler (5s samples)", function()
    local prof = DarpaHub._private and DarpaHub._private.Profiler
    if not prof then notify("Profiler", "Profiler not available", 3); return end
    if prof.enabled then
        prof:Disable(); notify("Profiler", "Profiler disabled", 2)
    else
        prof:Enable(); notify("Profiler", "Profiler enabled", 2)
    end
end)

-- Lightweight FPS/ping sampler using scheduler (runs every frame)
do
    local lastTick = tick()
    local frameCount = 0
    local fps = 0

    Scheduler:AddJob(function(dt)
        frameCount = frameCount + 1
        if tick() - lastTick >= 1 then
            fps = math.floor(frameCount / (tick() - lastTick) + 0.5)
            frameCount = 0
            lastTick = tick()
            pcall(function()
                fpsLabel.Text = "FPS: " .. tostring(fps)
                memLabel.Text = "Memory: " .. string.format("%.2f MB", collectgarbage("count") / 1024)
                if LocalPlayer and LocalPlayer.GetNetworkPing then
                    local ping = math.floor(LocalPlayer:GetNetworkPing() * 1000)
                    pingLabel.Text = "Ping: " .. tostring(ping) .. " ms"
                else
                    pingLabel.Text = "Ping: N/A"
                end
            end)
        end
    end, {interval = nil, priority = 5})
end

-- ------------------------
-- Visuals: Camera Orbit & Cinematic Camera features (safe)
-- ------------------------
local visAPI = Tabs.Visuals.API
visAPI:AddLabel("Camera & Visual Tools — safe, non-gameplay-affecting")

-- CameraOrbit feature
DarpaHub:RegisterFeature("CameraOrbit", {
    DefaultEnabled = false,
    Priority = 40,
    Config = { Radius = 10, Speed = 0.6, Height = 2 },
    Enable = function(selfFeature)
        selfFeature._active = true
        notify("CameraOrbit", "Orbit enabled — press G to toggle", 3)
        DarpaHub:BindKey(Enum.KeyCode.G, function()
            DarpaHub:ToggleFeature("CameraOrbit")
        end)
    end,
    Disable = function(selfFeature)
        selfFeature._active = false
    end,
    Update = function(selfFeature)
        if not selfFeature._active then return end
        local cam = workspace and workspace.CurrentCamera
        local plr = Players.LocalPlayer
        if not cam or not plr or not plr.Character or not plr.Character:FindFirstChild("HumanoidRootPart") then return end
        local hrp = plr.Character.HumanoidRootPart
        local t = tick()
        local radius = selfFeature.Config.Radius or 6
        local height = selfFeature.Config.Height or 2
        local speed = selfFeature.Config.Speed or 0.5
        local targetPos = hrp.Position + Vector3.new(math.cos(t * speed) * radius, height, math.sin(t * speed) * radius)
        cam.CFrame = CFrame.new(cam.CFrame.Position:Lerp(targetPos, 0.12), hrp.Position)
    end
})

-- UI controls for CameraOrbit
local orbitToggle = visAPI:AddToggle("Enable Camera Orbit (G)", false, function(state)
    if state then DarpaHub:EnableFeature("CameraOrbit") else DarpaHub:DisableFeature("CameraOrbit") end
end)
visAPI:AddSlider("Orbit Speed", 0.05, 3, 0.6, function(v)
    local f = DarpaHub.Features["CameraOrbit"]
    if f then f.Config.Speed = v end
end)
visAPI:AddSlider("Orbit Radius", 2, 50, 10, function(v)
    local f = DarpaHub.Features["CameraOrbit"]
    if f then f.Config.Radius = v end
end)

-- CinematicCamera feature
DarpaHub:RegisterFeature("CinematicCamera", {
    DefaultEnabled = false,
    Priority = 30,
    Config = { Distance = 8, Height = 2, Smooth = 0.14 },
    Enable = function(selfFeature)
        selfFeature._active = true
        notify("CinematicCamera", "Cinematic camera enabled", 2)
    end,
    Disable = function(selfFeature)
        selfFeature._active = false
    end,
    Update = function(selfFeature)
        if not selfFeature._active then return end
        local cam = workspace.CurrentCamera
        local plr = Players.LocalPlayer
        if not cam or not plr or not plr.Character then return end
        local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local desiredPos = hrp.Position - (hrp.CFrame.lookVector * (selfFeature.Config.Distance or 8)) + Vector3.new(0, (selfFeature.Config.Height or 2), 0)
        cam.CFrame = cam.CFrame:Lerp(CFrame.new(desiredPos, hrp.Position), selfFeature.Config.Smooth or 0.12)
    end
})

local cineToggle = visAPI:AddToggle("Enable Cinematic Camera", false, function(state)
    if state then DarpaHub:EnableFeature("CinematicCamera") else DarpaHub:DisableFeature("CinematicCamera") end
end)
visAPI:AddSlider("Cine Distance", 2, 40, 8, function(v) local f = DarpaHub.Features["CinematicCamera"]; if f then f.Config.Distance = v end end)
visAPI:AddSlider("Cine Height", -2, 10, 2, function(v) local f = DarpaHub.Features["CinematicCamera"]; if f then f.Config.Height = v end end)

-- VignettePulse (visual overlay)
DarpaHub:RegisterFeature("VignettePulse", {
    DefaultEnabled = false,
    Priority = 110,
    Enable = function(selfFeature)
        local screen = DarpaHub._private and DarpaHub._private.UI and DarpaHub._private.UI.Screen
        if not screen then return end
        local img = Instance.new("ImageLabel")
        img.Name = "DH_Vignette"
        img.Size = UDim2.new(1, 0, 1, 0)
        img.Position = UDim2.new(0, 0, 0, 0)
        img.BackgroundTransparency = 1
        img.Image = "" -- left blank for safety
        img.ZIndex = 9999
        img.Parent = screen
        pcall(function() img.ImageColor3 = Theme:GetColor("Accent") end)
        img.ImageTransparency = 1
        selfFeature._ui = img
    end,
    Disable = function(selfFeature)
        if selfFeature._ui then pcall(function() selfFeature._ui:Destroy() end) end
        selfFeature._ui = nil
    end,
    Update = function(selfFeature)
        if not selfFeature._ui then return end
        local t = (math.sin(tick() / 1.2) + 1) / 2
        selfFeature._ui.ImageTransparency = 0.6 - (t * 0.25)
        local base = Theme:GetColor("Accent")
        local alt = Color3.new(1, 0.5, 0.6)
        local col = Color3.new(base.R + (alt.R - base.R) * t, base.G + (alt.G - base.G) * t, base.B + (alt.B - base.B) * t)
        pcall(function() selfFeature._ui.ImageColor3 = col end)
    end
})

visAPI:AddToggle("Enable Vignette Pulse", false, function(s)
    if s then DarpaHub:EnableFeature("VignettePulse") else DarpaHub:DisableFeature("VignettePulse") end
end)

-- ------------------------
-- Tools Tab: Safe utilities
-- ------------------------
local toolsAPI = Tabs.Tools.API
toolsAPI:AddLabel("Utility tools — safe helpers")

toolsAPI:AddButton("Take UI Snapshot (placeholder)", function()
    notify("Snapshot", "This is a placeholder. Use executor API for real screenshots.", 3)
end)

DarpaHub:RegisterFeature("AutoRespawnHelper", {
    DefaultEnabled = false,
    Priority = 90,
    Enable = function(selfFeature) selfFeature._active = true; notify("AutoRespawn", "Enabled", 2) end,
    Disable = function(selfFeature) selfFeature._active = false end,
    Update = function(selfFeature)
        if not selfFeature._active then return end
        local plr = Players.LocalPlayer
        if not plr then return end
        local char = plr.Character
        if not char or (char and not char.Parent) then
            pcall(function() plr:LoadCharacter() end)
        else
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health <= 0 then
                pcall(function() plr:LoadCharacter() end)
            end
        end
    end
})
toolsAPI:AddToggle("Enable Auto-Respawn Helper", false, function(s)
    if s then DarpaHub:EnableFeature("AutoRespawnHelper") else DarpaHub:DisableFeature("AutoRespawnHelper") end
end)

-- ------------------------
-- Plugins Tab (demo plugin manifest UI)
-- ------------------------
local pluginsAPI = Tabs.Plugins.API
pluginsAPI:AddLabel("Plugin manager (demo)")

local demoPluginManifest = {
    name = "Demo.Visuals.Plugin",
    version = "0.0.1",
    url = "local",
    author = "DarpaHubExample",
    description = "Demo plugin for visuals",
    allowedAPIs = {"UI","Scheduler","Hooks","Persistence"},
    code = [[
        -- plugin code runs in a sandbox where DarpaHub is a restricted API object
        local API = DarpaHub
        API.Logger.Info("Demo plugin started")
        local tab = API.UI.CreateTab("DemoPlugin")
        local api = tab.API
        api:AddLabel("Demo plugin loaded")
        api:AddButton("Plugin Action", function()
            API.Logger.Info("Plugin action triggered")
        end)
        -- heartbeat
        local id = API.Scheduler.Add(function() API.Logger.Info("Plugin heartbeat") end, {interval=2, persistent=true})
        function onUnload()
            API.Logger.Info("Demo plugin unloading")
            API.Scheduler.Remove(id)
        end
    ]]
}

DarpaHub:RegisterPluginManifest(demoPluginManifest)
pluginsAPI:AddButton("Load Demo Plugin", function()
    local ok, err = pcall(function()
        DarpaHub:LoadPlugin("Demo.Visuals.Plugin")
    end)
    if ok then notify("Plugin", "Demo plugin loaded", 2) else notify("Plugin", "Failed to load plugin: " .. tostring(err), 4) end
end)
pluginsAPI:AddButton("Unload Demo Plugin", function()
    local ok, err = pcall(function() DarpaHub:UnloadPlugin("Demo.Visuals.Plugin") end)
    notify("Plugin", "Unload attempted", 2)
end)
pluginsAPI:AddButton("HotReload Library", function()
    local ok, err = pcall(function() DarpaHub:HotReload() end)
    if ok then notify("HotReload", "Library hot-reloaded", 2) else notify("HotReload", "HotReload failed: " .. tostring(err), 4) end
end)

-- ------------------------
-- Settings Tab (appearance & utilities)
-- ------------------------
local settingsAPI = Tabs.Settings.API
settingsAPI:AddLabel("Appearance & Settings")
settingsAPI:AddButton("Toggle Dark/Light Theme", function()
    local cur = DarpaHub._private and DarpaHub._private.ActiveTheme and DarpaHub._private.ActiveTheme.Name or "Dark"
    if cur == "Dark" then DarpaHub.Theme:SetTheme("Light") else DarpaHub.Theme:SetTheme("Dark") end
    notify("Theme", "Switched theme to " .. (DarpaHub._private and DarpaHub._private.ActiveTheme and DarpaHub._private.ActiveTheme.Name or "Unknown"), 2)
end)
settingsAPI:AddButton("Export Settings to Console", function()
    print("[DarpaHubExample Export] Theme:", DarpaHub._private and DarpaHub._private.ActiveTheme and DarpaHub._private.ActiveTheme.Name or "None")
    notify("Export", "Exported settings to console", 2)
end)

-- ------------------------
-- Profiler snapshot button in Main tab
-- ------------------------
local mainAPI = Tabs.Main.API
mainAPI:AddLabel("DarpaHub Example — Main Dashboard")
mainAPI:AddButton("Fire demo hook", function() fire_demo_hook() end)
mainAPI:AddLabel("Profiler snapshot (check Output):")
mainAPI:AddButton("Print Profiler Stats", function()
    local prof = DarpaHub._private and DarpaHub._private.Profiler
    if not prof then notify("Profiler", "Profiler not found", 3); return end
    local stats = prof:GetStats()
    for k,v in pairs(stats) do
        print(string.format("Profiler: %s -> calls=%d total=%.6f last=%.6f", k, v.calls, v.totalTime, v.lastTime))
    end
    notify("Profiler", "Profiler stats printed to console", 3)
end)

-- ------------------------
-- Scheduled example: fire hook every 10 seconds (demonstrates scheduler & FireHook)
-- ------------------------
local demoHookJob = Scheduler:AddJob(function()
    DarpaHub:FireHook("Example.CustomEvent", {msg = "Scheduled hook tick at " .. os.date("%X")})
end, {interval = 10, priority = 90, persistent = true})

EX.demoHookJob = demoHookJob

-- ------------------------
-- Decorative RenderStepped-driven effect (safe): sparkle parts near camera (non-gameplay)
-- ------------------------
do
    local sparkle = {}
    sparkle.Enabled = false
    sparkle.Parts = {}
    sparkle.Radius = 4
    sparkle.Speed = 1.1
    sparkle.Count = 6

    function sparkle:Enable()
        if self.Enabled then return end
        self.Enabled = true
        local cam = workspace.CurrentCamera
        if not cam then return end
        for i = 1, self.Count do
            local p = Instance.new("Part")
            p.Name = "DH_Spark_" .. i
            p.Anchored = true
            p.CanCollide = false
            p.Size = Vector3.new(0.2,0.2,0.2)
            p.Transparency = 0.25
            p.Material = Enum.Material.Neon
            p.Color = Theme:GetColor("Accent")
            p.Parent = workspace
            table.insert(self.Parts, p)
        end
    end

    function sparkle:Disable()
        self.Enabled = false
        for _, p in ipairs(self.Parts) do
            p:Destroy()
        end
        self.Parts = {}
    end

    function sparkle:Update(dt)
        if not self.Enabled then return end
        local cam = workspace.CurrentCamera
        if not cam then return end
        local t = tick() * self.Speed
        for i,p in ipairs(self.Parts) do
            local angle = (i / #self.Parts) * math.pi * 2 + t
            local localPos = cam.CFrame.Position + (cam.CFrame.LookVector * 2) + Vector3.new(math.cos(angle) * self.Radius, math.sin(angle) * (self.Radius * 0.35), 0)
            p.CFrame = CFrame.new(localPos)
            local alpha = (math.sin(t + i) + 1) / 2
            local accent = Theme:GetColor("Accent")
            p.Color = Color3.new(accent.R * (0.6 + 0.4 * alpha), accent.G * (0.6 + 0.4 * alpha), accent.B * (0.6 + 0.4 * alpha))
        end
    end

    DarpaHub:RegisterFeature("SparkleDecor", {
        DefaultEnabled = false,
        Priority = 70,
        Enable = function(selfFeature)
            selfFeature._spark = sparkle
            selfFeature._spark:Enable()
        end,
        Disable = function(selfFeature)
            if selfFeature._spark then selfFeature._spark:Disable() end
        end,
        Update = function(selfFeature)
            if selfFeature._spark then
                -- pass dt safely (scheduler tick uses dt param)
                pcall(function() sparkle:Update(task.wait()) end)
            end
        end
    })

    toolsAPI:AddToggle("Toggle Sparkle Decor", false, function(s)
        if s then DarpaHub:EnableFeature("SparkleDecor") else DarpaHub:DisableFeature("SparkleDecor") end
    end)
end

-- ------------------------
-- Developer helper keybind (F1)
-- ------------------------
DarpaHub:BindKey(Enum.KeyCode.F1, function()
    notify("Dev", "F1 pressed - printing hub state", 3)
    print("DarpaHub State Dump:")
    print("Version:", DarpaHub.VERSION)
    print("Booted:", tostring(DarpaHub.State.Booted))
    print("Mode:", tostring(DarpaHub.State.Mode))
    local names = {}
    for k,_ in pairs(DarpaHub.Features) do table.insert(names, k) end
    print("Features Registered:", table.concat(names, ", "))
end)

-- ------------------------
-- Cosmetic startup notification
-- ------------------------
notify("DarpaHub Example", "Example loaded — use tabs to toggle features. Press RightControl to show/hide UI.", 4)
info("DarpaHub Example initialized. Version:", DarpaHub.VERSION)

-- Expose helpers to getgenv for dev convenience
EX.DarpaHub = DarpaHub
EX.Notify = notify
EX.Tabs = Tabs

-- End of corrected Example file
