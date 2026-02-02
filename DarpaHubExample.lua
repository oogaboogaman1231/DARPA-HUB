local Hub = loadstring(game:HttpGet("https://raw.githubusercontent.com/SEUUSUARIO/DarpaHub/main/DarpaHubLib.lua"))()

local UIS = game:GetService("UserInputService")
local LocalPlayer = game.Players.LocalPlayer
local Camera = workspace.CurrentCamera

-- ======================================
-- AIMBOT ENGINE
-- ======================================

Hub:RegisterFeature("Aimbot", {
    Config = {
        FOV = 220,
        Smooth = 0.12,
        Rage = false
    },

    Update = function(cfg)
        local target = Hub:GetClosestTarget(cfg.FOV)
        if not target then return end

        local cf = CFrame.new(Camera.CFrame.Position, target.Position)

        if cfg.Rage then
            Camera.CFrame = cf
        else
            Camera.CFrame = Camera.CFrame:Lerp(cf, cfg.Smooth)
        end
    end
})

-- ======================================
-- SILENT AIM VIA HOOK
-- ======================================

Hub:CreateHook("BulletDirection")

Hub:RegisterFeature("SilentAim", {
    Start = function()
        Hub:HookMain("BulletDirection", function(dir)
            local t = Hub:GetClosestTarget(250)
            if t then
                return (t.Position - Camera.CFrame.Position).Unit
            end
            return dir
        end)
    end
})

-- ======================================
-- FULL ESP SYSTEM
-- ======================================

local ESP = {}

Hub:RegisterFeature("ESP", {
    Start = function()
        for _,e in ipairs(Hub:GetEnemies()) do
            ESP[e] = {
                Box = Hub.Drawing:Box(),
                Name = Hub.Drawing:Text()
            }
        end
    end,

    Stop = function()
        for _,v in pairs(ESP) do
            v.Box:Remove()
            v.Name:Remove()
        end
        ESP = {}
    end,

    Update = function()
        for plr,data in pairs(ESP) do
            if not plr.Character then continue end
            local hrp = plr.Character.HumanoidRootPart

            local pos,vis,depth = Hub:WorldToScreen(hrp.Position)

            if vis then
                local size = math.clamp(2200/depth,25,160)

                data.Box.Size = Vector2.new(size,size*1.6)
                data.Box.Position = pos - data.Box.Size/2
                data.Box.Visible = true

                data.Name.Text = plr.Name
                data.Name.Position = pos - Vector2.new(0,size)
                data.Name.Visible = true
            else
                data.Box.Visible = false
                data.Name.Visible = false
            end
        end
    end
})

-- ======================================
-- TRIGGERBOT
-- ======================================

Hub:RegisterFeature("Triggerbot", {
    Update = function()
        local t = Hub:GetClosestTarget(35)
        if t then
            mouse1press()
            task.wait(0.01)
            mouse1release()
        end
    end
})

-- ======================================
-- HITBOX EXPANDER
-- ======================================

Hub:RegisterFeature("Hitbox", {
    Config = { Size = 7 },

    Update = function(cfg)
        for _,e in ipairs(Hub:GetEnemies()) do
            local hrp = e.Character.HumanoidRootPart
            hrp.Size = Vector3.new(cfg.Size,cfg.Size,cfg.Size)
            hrp.Transparency = 0.5
            hrp.CanCollide = false
        end
    end
})

-- ======================================
-- MOVEMENT ENGINE
-- ======================================

Hub:RegisterFeature("Speed", {
    Config = { Value = 40 },
    Update = function(cfg)
        local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
        if h then h.WalkSpeed = cfg.Value end
    end
})

Hub:RegisterFeature("Bhop", {
    Update = function()
        local h = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid")
        if h and h.FloorMaterial ~= Enum.Material.Air then
            h:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
})

-- ======================================
-- HOTKEY SYSTEM
-- ======================================

UIS.InputBegan:Connect(function(i,gp)
    if gp then return end

    if i.KeyCode == Enum.KeyCode.F then Hub:Set("Aimbot") end
    if i.KeyCode == Enum.KeyCode.G then Hub:Set("ESP") end
    if i.KeyCode == Enum.KeyCode.H then Hub:Set("SilentAim") end
    if i.KeyCode == Enum.KeyCode.J then Hub:Set("Triggerbot") end
    if i.KeyCode == Enum.KeyCode.K then Hub:Set("Hitbox") end
    if i.KeyCode == Enum.KeyCode.L then Hub:Set("Speed") end
    if i.KeyCode == Enum.KeyCode.B then Hub:Set("Bhop") end
end)

print("🔥 DarpaHub BloxStrike paid-tier loaded.")
