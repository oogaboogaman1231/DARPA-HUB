# DARPA HUB v7.5 - QUICK REFERENCE GUIDE

## 🚀 Quick Start

### Load Complete Hub (Recommended)
```lua
loadstring(game:HttpGet("YOUR_URL/DarpaHub_Complete_Fixed.lua"))()
```

---

## 🎯 Aimbot Quick Settings

### Enable Aimbot
```lua
-- Through UI: Toggle "Enable Aimbot" in Aimbot tab
-- Or in code:
AimbotModule.Settings.Enabled = true
```

### Common Configurations

**Legit Mode (Recommended for Bloxstrike)**
```lua
AimbotModule.Settings.Enabled = true
AimbotModule.Settings.TeamCheck = true
AimbotModule.Settings.VisibleCheck = true
AimbotModule.Settings.TargetPart = "Head"
AimbotModule.Settings.Smoothing = 0.25
AimbotModule.Settings.PredictionEnabled = false
AimbotModule.FOV.Radius = 100
AimbotModule.FOV.Visible = false
```

**Rage Mode**
```lua
AimbotModule.Settings.Enabled = true
AimbotModule.Settings.TeamCheck = false
AimbotModule.Settings.VisibleCheck = false
AimbotModule.Settings.Smoothing = 0
AimbotModule.Settings.PredictionEnabled = true
AimbotModule.Settings.PredictionAmount = 0.15
AimbotModule.FOV.Radius = 500
```

### Controls
- **Right Mouse Button** - Hold to aim (default)
- Change in UI: Aimbot Tab > Keybind settings

---

## 👁️ ESP Quick Settings

### Enable ESP
```lua
-- Through UI: Toggle "Enable ESP" in ESP tab
-- Or in code:
ESPModule.Settings.Enabled = true
```

### Common Configurations

**Minimal ESP**
```lua
ESPModule.Settings.Enabled = true
ESPModule.Settings.TeamCheck = true
ESPModule.Boxes.Enabled = true
ESPModule.Boxes.Type = "2D"
ESPModule.Boxes.Filled = false
ESPModule.Tracers.Enabled = false
ESPModule.Names.Enabled = true
ESPModule.Names.ShowDistance = true
ESPModule.HealthBar.Enabled = true
ESPModule.HeadDots.Enabled = false
ESPModule.Chams.Enabled = false
```

**Full ESP**
```lua
ESPModule.Settings.Enabled = true
ESPModule.Settings.UseTeamColor = true
ESPModule.Boxes.Enabled = true
ESPModule.Boxes.Type = "2D"
ESPModule.Boxes.Filled = true
ESPModule.Tracers.Enabled = true
ESPModule.Names.Enabled = true
ESPModule.Names.ShowDistance = true
ESPModule.Names.ShowHealth = true
ESPModule.HealthBar.Enabled = true
ESPModule.HealthBar.Position = "Left"
ESPModule.HeadDots.Enabled = true
ESPModule.Chams.Enabled = true
```

---

## 👤 Player Enhancements

### Speed & Movement
```lua
-- WalkSpeed (Default: 16)
-- Set through UI: Player tab > WalkSpeed slider

-- JumpPower (Default: 50)  
-- Set through UI: Player tab > JumpPower slider

-- Infinite Jump
-- Toggle through UI: Player tab > Infinite Jump

-- No Clip
-- Toggle through UI: Player tab > No Clip
```

### Camera
```lua
-- FOV (Default: 70)
-- Set through UI: Player tab > Field of View slider
```

---

## ⚙️ Utilities

### Fullbright
```lua
-- Toggle through UI: Misc tab > Fullbright
```

### Remove Fog
```lua
-- Toggle through UI: Misc tab > Remove Fog
```

### Anti-AFK
```lua
-- Toggle through UI: Player tab > Anti-AFK
```

---

## 📊 Performance

### Optimize Graphics
```lua
-- Click button in UI: Performance tab > Optimize Graphics
```

### FPS Unlocker
```lua
-- Toggle through UI: Performance tab > FPS Unlocker
-- Sets FPS cap to 999 when enabled
```

---

## 🔧 Troubleshooting Commands

### Check if Aimbot is Running
```lua
if AimbotModule:IsRunning() then
    print("Aimbot is active")
end
```

### Get Current Target
```lua
local target = AimbotModule:GetLockedTarget()
if target then
    print("Locked on:", target.Name)
end
```

### Force Unlock Aimbot
```lua
AimbotModule:ForceUnlock()
```

### Disable All
```lua
AimbotModule:Disable()
ESPModule:Disable()
```

---

## ⌨️ Keybinds

| Action | Default Key | Changeable |
|--------|------------|------------|
| Aimbot Toggle | Right Mouse Button | Yes (in UI) |
| Open/Close UI | Right Ctrl | Yes (UI library) |

---

## 🎨 Color Customization

### Change FOV Color
```lua
AimbotModule.FOV.Color = Color3.fromRGB(255, 255, 255)  -- White
AimbotModule.FOV.LockedColor = Color3.fromRGB(255, 0, 0)  -- Red when locked
```

### Change ESP Colors
```lua
ESPModule.Settings.UseTeamColor = true
ESPModule.Settings.TeamColor = Color3.fromRGB(0, 255, 0)   -- Green for team
ESPModule.Settings.EnemyColor = Color3.fromRGB(255, 0, 0)  -- Red for enemies
```

### Change Health Bar Colors
```lua
ESPModule.HealthBar.HealthyColor = Color3.fromRGB(0, 255, 0)    -- Green (>60%)
ESPModule.HealthBar.DamagedColor = Color3.fromRGB(255, 255, 0)  -- Yellow (30-60%)
ESPModule.HealthBar.CriticalColor = Color3.fromRGB(255, 0, 0)   -- Red (<30%)
```

---

## 🎯 Target Priority

### Change Priority Mode
```lua
AimbotModule.Settings.Priority = "Distance"   -- Closest player
-- OR
AimbotModule.Settings.Priority = "Health"     -- Lowest health
-- OR
AimbotModule.Settings.Priority = "Crosshair"  -- Closest to crosshair
```

### Change Target Body Part
```lua
AimbotModule.Settings.TargetPart = "Head"              -- Headshots
-- OR
AimbotModule.Settings.TargetPart = "HumanoidRootPart" -- Body center
-- OR
AimbotModule.Settings.TargetPart = "Torso"            -- Upper body
```

---

## 📏 Distance Settings

### Aimbot FOV Radius
```lua
AimbotModule.FOV.Radius = 150  -- Small: 50-150, Medium: 150-300, Large: 300-500
```

### ESP Max Distance
```lua
ESPModule.Settings.MaxDistance = 5000  -- Show players up to 5000 studs away
```

---

## 🔄 Check Settings

### Quick Check All Checks
```lua
-- Aimbot
AimbotModule.Settings.TeamCheck = true     -- Don't aim at teammates
AimbotModule.Settings.AliveCheck = true    -- Only aim at alive players
AimbotModule.Settings.VisibleCheck = true  -- Only aim at visible players

-- ESP
ESPModule.Settings.TeamCheck = true        -- Don't show teammates
ESPModule.Settings.AliveCheck = true       -- Only show alive players
```

---

## 🎮 Game-Specific Tips for Bloxstrike

### Recommended Aimbot Settings
- **FOV Radius:** 120-180 (Bloxstrike has fast movement)
- **Smoothing:** 0.2-0.3 (Looks more legit)
- **Target Part:** "Head" (Headshots matter)
- **Prediction:** Enable with 0.12-0.15 amount
- **Team Check:** Enable (avoid team damage)

### Recommended ESP Settings
- **Boxes:** 2D (Better performance)
- **Tracers:** Bottom (Less obstructive)
- **Names:** Show distance and health
- **Max Distance:** 3000-5000 studs
- **Chams:** Disable (Can cause lag)

### Performance Settings
- **Graphics:** Optimize (Use button in Performance tab)
- **FPS Cap:** 120-240 (Balance between smooth and stable)
- **No Clip:** Use carefully (Can be detected)

---

## ⚠️ Important Notes

1. **Always check Team Check** to avoid aiming at teammates
2. **Start with low FOV** and increase if needed
3. **Use legit settings** for longer playtime
4. **Disable Chams** if experiencing lag
5. **Save your preferred config** by taking screenshots of settings

---

## 🔗 Quick Links

- **Full Documentation:** FIXES_README.md
- **Discord:** discord.gg/darpahub
- **Report Issues:** Use thumbs down in UI

---

## 📱 UI Navigation

```
Main Tabs:
├── 🎯 Aimbot      - All aimbot settings
├── 👁️ ESP         - Visual ESP settings
├── 👤 Player      - Movement & camera settings
├── ⚙️ Misc        - Utilities like fullbright
├── 📊 Performance - FPS & optimization
└── ℹ️ Info        - About & support info
```

---

**Need help?** Check FIXES_README.md for detailed explanations!
