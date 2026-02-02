-- DarpaHubLib.lua
-- DarpaHub Paid Framework Core

-- ======================================
-- SERVICES
-- ======================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- ======================================
-- CORE OBJECT
-- ======================================

local DarpaHub = {}
DarpaHub.__index = DarpaHub

DarpaHub.State = {
    Loaded = false,
    PlaceId = game.PlaceId,
    Delta = 0,
    Time = 0
}

DarpaHub.Config = {}
DarpaHub.Hooks = {}
DarpaHub.Events = {}
DarpaHub.Features = {}
DarpaHub.Tasks = {}
DarpaHub.Adapters = {}
DarpaHub.Profiles = {}

-- ======================================
-- HOOK ENGINE (ADVANCED)
-- ======================================

function DarpaHub:CreateHook(name)
    self.Hooks[name] = {
        Pre = {},
        Main = {},
        Post = {}
    }
end

function DarpaHub:HookPre(name, fn)
    if not self.Hooks[name] then self:CreateHook(name) end
    table.insert(self.Hooks[name].Pre, fn)
end

function DarpaHub:HookMain(name, fn)
    if not self.Hooks[name] then self:CreateHook(name) end
    table.insert(self.Hooks[name].Main, fn)
end

function DarpaHub:HookPost(name, fn)
    if not self.Hooks[name] then self:CreateHook(name) end
    table.insert(self.Hooks[name].Post, fn)
end

function DarpaHub:FireHook(name, ...)
    local h = self.Hooks[name]
    if not h then return ... end

    local args = {...}

    for _,cb in ipairs(h.Pre) do
        cb(unpack(args))
    end

    for _,cb in ipairs(h.Main) do
        local r = cb(unpack(args))
        if r ~= nil then args[1] = r end
    end

    for _,cb in ipairs(h.Post) do
        cb(unpack(args))
    end

    return unpack(args)
end

-- ======================================
-- EVENT BUS
-- ======================================

function DarpaHub:On(event, fn)
    self.Events[event] = self.Events[event] or {}
    table.insert(self.Events[event], fn)
end

function DarpaHub:Emit(event, ...)
    if not self.Events[event] then return end
    for _,cb in ipairs(self.Events[event]) do
        task.spawn(cb, ...)
    end
end

-- ======================================
-- TASK SCHEDULER
-- ======================================

function DarpaHub:CreateTask(name, interval, fn)
    self.Tasks[name] = {
        Interval = interval,
        Last = 0,
        Callback = fn
    }
end

-- ======================================
-- FEATURE SYSTEM (FULL LIFECYCLE)
-- ======================================

function DarpaHub:RegisterFeature(name, data)
    self.Features[name] = {
        Enabled = false,
        Config = data.Config or {},
        Init = data.Init,
        Start = data.Start,
        Stop = data.Stop,
        Update = data.Update
    }

    if data.Init then
        data.Init(self.Features[name].Config)
    end
end

function DarpaHub:Set(name, state)
    local f = self.Features[name]
    if not f then return end

    if state == nil then
        f.Enabled = not f.Enabled
    else
        f.Enabled = state
    end

    if f.Enabled and f.Start then
        f.Start(f.Config)
    end

    if not f.Enabled and f.Stop then
        f.Stop()
    end

    self:Emit("FeatureChanged", name, f.Enabled)
end

-- ======================================
-- PROFILE SYSTEM
-- ======================================

function DarpaHub:SaveProfile(name)
    local pack = {}
    for k,v in pairs(self.Features) do
        pack[k] = {
            Enabled = v.Enabled,
            Config = v.Config
        }
    end
    self.Profiles[name] = HttpService:JSONEncode(pack)
end

function DarpaHub:LoadProfile(name)
    if not self.Profiles[name] then return end

    local decoded = HttpService:JSONDecode(self.Profiles[name])

    for fname,data in pairs(decoded) do
        if self.Features[fname] then
            self.Features[fname].Config = data.Config
            self:Set(fname, data.Enabled)
        end
    end
end

-- ======================================
-- ADAPTER SYSTEM (BLOXSTRIKE READY)
-- ======================================

function DarpaHub:RegisterAdapter(placeId, fn)
    self.Adapters[placeId] = fn
end

function DarpaHub:ApplyAdapter()
    local ad = self.Adapters[self.State.PlaceId]
    if ad then ad(self) end
end

-- ======================================
-- PLAYER UTILS
-- ======================================

function DarpaHub:GetEnemies()
    local list = {}
    for _,plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                table.insert(list, plr)
            end
        end
    end
    return list
end

function DarpaHub:GetCharacter()
    return LocalPlayer.Character
end

-- ======================================
-- CAMERA UTILS
-- ======================================

function DarpaHub:WorldToScreen(pos)
    local v,vis = Camera:WorldToViewportPoint(pos)
    return Vector2.new(v.X,v.Y), vis, v.Z
end

function DarpaHub:GetClosestTarget(fov)
    local best,dist = nil,math.huge
    local mouse = UserInputService:GetMouseLocation()

    for _,enemy in ipairs(self:GetEnemies()) do
        local hrp = enemy.Character.HumanoidRootPart
        local pos,vis,depth = self:WorldToScreen(hrp.Position)

        if vis then
            local d = (pos - mouse).Magnitude
            if d < dist and d < fov then
                dist = d
                best = hrp
            end
        end
    end

    return best
end

-- ======================================
-- DRAWING ENGINE
-- ======================================

DarpaHub.Drawing = {}

function DarpaHub.Drawing:Box(color)
    local s = Drawing.new("Square")
    s.Thickness = 2
    s.Filled = false
    s.Color = color or Color3.fromRGB(0,255,150)
    return s
end

function DarpaHub.Drawing:Text()
    local t = Drawing.new("Text")
    t.Size = 14
    t.Center = true
    t.Outline = true
    return t
end

function DarpaHub.Drawing:Line()
    local l = Drawing.new("Line")
    l.Thickness = 1.5
    return l
end

-- ======================================
-- CORE LOOP
-- ======================================

RunService.RenderStepped:Connect(function(dt)

    DarpaHub.State.Delta = dt
    DarpaHub.State.Time += dt

    for _,taskData in pairs(DarpaHub.Tasks) do
        if os.clock() - taskData.Last >= taskData.Interval then
            taskData.Last = os.clock()
            task.spawn(taskData.Callback)
        end
    end

    for _,f in pairs(DarpaHub.Features) do
        if f.Enabled and f.Update then
            f.Update(f.Config, dt)
        end
    end
end)

DarpaHub.State.Loaded = true
DarpaHub:ApplyAdapter()

return DarpaHub
