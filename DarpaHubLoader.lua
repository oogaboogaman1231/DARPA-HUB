-- ============================================================
--   Darpa Hub Loader  v4.1  (Fixed Fetch · HttpGet · Hooks)
--   LocalScript  ·  PlayerGui / StarterPlayerScripts
--   Legit use only.  No undetection / anti‑cheat.
-- ============================================================

if not game:IsLoaded() then
	game.Loaded:Wait()
end

local TweenService  = game:GetService("TweenService")
local Players       = game:GetService("Players")
local player        = Players.LocalPlayer
if not player then return end

-- ================ CONFIG (substitute these) =================
-- Supported games (GameId → URL):
--   Bloxstrike       114234929420007
--   Defuse Division  112757576021097
local BLOXSTRIKE_ID      = 114234929420007
local DEFUSE_DIVISION_ID = 112757576021097

local URL_BLOXSTRIKE  = "https://your-link-here.com/bloxstrike.lua"
local URL_DEFUSE      = "https://your-link-here.com/defusedivision.lua"
local URL_UNSUPPORTED = "https://raw.githubusercontent.com/oogaboogaman1231/DARPA-HUB/refs/heads/main/DarpaHubExample.lua"

local SOUND_ID     = "rbxassetid://124534526449303"  -- set to nil to disable sound
local OPEN_TIME    = 0.65
local INTERMISSION = 2.4          -- loading bar duration
local CLOSE_TIME   = 0.50

-- Name shown on the root ScreenGui in the instance tree.
local GUI_DISPLAY_NAME = "DarpaHubLoader"

-- Optional startup jitter (seconds).
local START_DELAY_MIN = 0
local START_DELAY_MAX = 0

-- ─────────────────────────────────────────────────────────
--  LIFECYCLE HOOKS
-- ─────────────────────────────────────────────────────────
local HOOKS = {
	-- onBeforeGUI    = function() end,
	-- onAfterClose   = function() end,
	-- onBeforeFetch  = function(url, attempt) end,
	-- onBeforeRun    = function(fn) end,
	-- onLoadSuccess  = function(gameName) end,
	-- onLoadFail     = function(err) end,
}
-- ============================================================

-- ──────────────────────────────────────────────────────────
--  GAME DETECT
-- ──────────────────────────────────────────────────────────
local gameName, scriptURL
if game.GameId == BLOXSTRIKE_ID then
	gameName  = "Bloxstrike"
	scriptURL = URL_BLOXSTRIKE
elseif game.GameId == DEFUSE_DIVISION_ID then
	gameName  = "Defuse Division"
	scriptURL = URL_DEFUSE
else
	gameName  = "Unsupported Game"
	scriptURL = URL_UNSUPPORTED
end

-- ──────────────────────────────────────────────────────────
--  UTILITY
-- ──────────────────────────────────────────────────────────
local function randRange(min, max) return min + math.random() * (max - min) end

local function fireHook(name, ...)
	local hook = HOOKS[name]
	if not hook then return true, nil end
	return pcall(hook, ...)
end

-- ──────────────────────────────────────────────────────────
--  SAFE LOADER (PATCHED: Uses game:HttpGet + Robust Error Handling)
-- ──────────────────────────────────────────────────────────
local HTTP_RETRIES  = 2       -- total attempts
local HTTP_DELAY    = 1.0     -- seconds between retry attempts

local function safeLoad(url, fallback)
	if not url or url == "" then return false, "no url provided" end

	-- We wrap the attempt in a loop to handle retries gracefully
	local lastErr
	
	for attempt = 1, HTTP_RETRIES do
		local success, runtimeErr = pcall(function()
			-- 1. Hook: Allow overriding the fetch (e.g., for debug or proxy)
			local hookOk, hookResponse = fireHook("onBeforeFetch", url, attempt)
			local sourceCode

			if hookOk and type(hookResponse) == "string" and hookResponse ~= "" then
				sourceCode = hookResponse
			else
				-- 2. Fetch: Use game:HttpGet (Standard for Executors)
				-- 'true' as 2nd arg often busts cache in some executors
				sourceCode = game:HttpGet(url, true)
			end

			-- Check for empty response
			if not sourceCode or sourceCode == "" then
				error("empty response from server")
			end

			-- 3. Compile: Support both loadstring and load
			local compiler = loadstring or load
			local func, compileErr = compiler(sourceCode)

			if not func then
				error("compilation failed: " .. tostring(compileErr))
			end

			-- 4. Hook: Last chance to modify env or inspect func
			fireHook("onBeforeRun", func)

			-- 5. Execute
			func() 
		end)

		if success then
			return true -- Script loaded and ran successfully!
		else
			lastErr = runtimeErr
			if attempt < HTTP_RETRIES then
				task.wait(HTTP_DELAY)
			end
		end
	end

	-- If we failed after all retries, try fallback
	if fallback and fallback ~= "" and fallback ~= url then
		warn("DarpaHub: Primary URL failed ("..tostring(lastErr).."), attempting fallback...")
		return safeLoad(fallback, nil)
	end

	return false, lastErr
end

-- ──────────────────────────────────────────────────────────
--  PRE‑GUI
-- ──────────────────────────────────────────────────────────
if START_DELAY_MIN > 0 and START_DELAY_MAX > 0 then
	task.wait(randRange(START_DELAY_MIN, START_DELAY_MAX))
end
fireHook("onBeforeGUI")

-- ──────────────────────────────────────────────────────────
--  ROOT GUI
-- ──────────────────────────────────────────────────────────
local gui = Instance.new("ScreenGui")
gui.Name           = GUI_DISPLAY_NAME
gui.IgnoreGuiInset = true
gui.ResetOnSpawn   = false
gui.Parent         = player:WaitForChild("PlayerGui")

-- ──────────────────────────────────────────────────────────
--  VIGNETTE DIM
-- ──────────────────────────────────────────────────────────
local dim = Instance.new("Frame", gui)
dim.Name                  = "Dim"
dim.Size                  = UDim2.new(1, 0, 1, 0)
dim.Position              = UDim2.new(0, 0, 0, 0)
dim.BackgroundColor3      = Color3.new(0, 0, 0)
dim.BackgroundTransparency = 1
dim.ZIndex                = 2

local dimGradH = Instance.new("UIGradient", dim)
dimGradH.Rotation = 0
dimGradH.Color = ColorSequence.new {
	ColorSequenceKeypoint.new(0,   Color3.new(0, 0, 0)),
	ColorSequenceKeypoint.new(0.38, Color3.new(0, 0, 0)),
	ColorSequenceKeypoint.new(0.5, Color3.new(0.08, 0.08, 0.08)),
	ColorSequenceKeypoint.new(0.62, Color3.new(0, 0, 0)),
	ColorSequenceKeypoint.new(1,   Color3.new(0, 0, 0)),
}
dimGradH.Transparency = NumberSequence.new {
	NumberSequenceKeypoint.new(0,    0.20),
	NumberSequenceKeypoint.new(0.38, 0.38),
	NumberSequenceKeypoint.new(0.5,  0.56),
	NumberSequenceKeypoint.new(0.62, 0.38),
	NumberSequenceKeypoint.new(1,    0.20),
}

-- ──────────────────────────────────────────────────────────
--  SOUND
-- ──────────────────────────────────────────────────────────
local sound
if SOUND_ID then
	sound = Instance.new("Sound", gui)
	sound.Name    = "OpenSound"
	sound.SoundId = SOUND_ID
	sound.Volume  = 0.75
	sound.Looped  = false
end

-- ──────────────────────────────────────────────────────────
--  COMET LAYERS
-- ──────────────────────────────────────────────────────────
local cometFar  = Instance.new("Frame", gui)
cometFar.Name   = "CometFar"
cometFar.Size   = UDim2.new(1, 0, 1, 0)
cometFar.BackgroundTransparency = 1
cometFar.ZIndex = 0

local cometNear = Instance.new("Frame", gui)
cometNear.Name  = "CometNear"
cometNear.Size  = UDim2.new(1, 0, 1, 0)
cometNear.BackgroundTransparency = 1
cometNear.ZIndex = 1

-- ──────────────────────────────────────────────────────────
--  PANEL SHADOW / BLOOM
-- ──────────────────────────────────────────────────────────
local function makeShadowRing(parent, scale, transparency, cornerExtra, zIdx)
	local ring = Instance.new("Frame", parent)
	ring.AnchorPoint = Vector2.new(0.5, 0.5)
	ring.Position    = UDim2.new(0.5, 0, 0.5, 0)
	ring.Size        = UDim2.new(0, 0, 0, 0)
	ring.BackgroundColor3      = Color3.new(0, 0, 0)
	ring.BackgroundTransparency = transparency
	ring.BorderSizePixel        = 0
	ring.ZIndex                 = zIdx
	Instance.new("UICorner", ring).CornerRadius = UDim.new(0, 24 + cornerExtra)
	return ring, scale
end

local shadowRings = {}
local shadowScales = { 1.14, 1.08, 1.04 }
local shadowTransparencies = { 0.92, 0.87, 0.82 }
local shadowCornerExtras    = { 8, 4, 2 }

for i = 1, 3 do
	local ring
	ring, shadowScales[i] = makeShadowRing(gui, shadowScales[i], shadowTransparencies[i], shadowCornerExtras[i], 4 + i)
	shadowRings[i] = ring
end

-- ──────────────────────────────────────────────────────────
--  MAIN PANEL
-- ──────────────────────────────────────────────────────────
local panel = Instance.new("Frame", gui)
panel.Name            = "MainPanel"
panel.AnchorPoint     = Vector2.new(0.5, 0.5)
panel.Position        = UDim2.new(0.5, 0, 0.5, 0)
panel.Size            = UDim2.new(0, 0, 0, 0)
panel.BackgroundColor3 = Color3.fromRGB(6, 8, 13)
panel.BorderSizePixel  = 0
panel.ZIndex           = 8
panel.ClipsDescendants = true

Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 22)

local panelStroke = Instance.new("UIStroke", panel)
panelStroke.Thickness   = 1.5
panelStroke.Color       = Color3.fromRGB(30, 70, 140)
panelStroke.Transparency = 0.72

local panelGrad = Instance.new("UIGradient", panel)
panelGrad.Rotation = 180
panelGrad.Color = ColorSequence.new {
	ColorSequenceKeypoint.new(0,   Color3.fromRGB(14, 17, 26)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(8,  10, 16)),
	ColorSequenceKeypoint.new(1,   Color3.fromRGB(5,  6,  10)),
}

local topLine = Instance.new("Frame", panel)
topLine.Name              = "TopAccent"
topLine.AnchorPoint       = Vector2.new(0.5, 0)
topLine.Size              = UDim2.new(0, 0, 0, 1)
topLine.Position          = UDim2.new(0.5, 0, 0, 0)
topLine.BackgroundColor3  = Color3.fromRGB(0, 180, 255)
topLine.BackgroundTransparency = 0.25
topLine.BorderSizePixel   = 0
topLine.ZIndex            = 10
Instance.new("UICorner", topLine).CornerRadius = UDim.new(0, 1)

-- ──────────────────────────────────────────────────────────
--  INNER GLOW
-- ──────────────────────────────────────────────────────────
local innerGlow = Instance.new("Frame", panel)
innerGlow.Name            = "InnerGlow"
innerGlow.AnchorPoint     = Vector2.new(0.5, 0.48)
innerGlow.Position        = UDim2.new(0.5, 0, 0.44, 0)
innerGlow.Size            = UDim2.new(0.88, 0, 0.52, 0)
innerGlow.BackgroundColor3 = Color3.fromRGB(0, 130, 220)
innerGlow.BackgroundTransparency = 0.93
innerGlow.BorderSizePixel  = 0
innerGlow.ZIndex           = 9
Instance.new("UICorner", innerGlow).CornerRadius = UDim.new(1, 0)

-- ──────────────────────────────────────────────────────────
--  TEXT LABELS
-- ──────────────────────────────────────────────────────────
local function makeLabel(parent, name, text, font, color, size, pos, xAlign, zIdx, strokeColor, strokeTrans)
	local lbl = Instance.new("TextLabel", parent)
	lbl.Name                   = name
	lbl.Size                   = size
	lbl.Position               = pos
	lbl.BackgroundTransparency = 1
	lbl.Text                   = text
	lbl.Font                   = font
	lbl.TextColor3             = color
	lbl.TextScaled             = true
	lbl.TextWrapped            = true
	lbl.TextXAlignment         = xAlign or Enum.TextXAlignment.Center
	lbl.TextYAlignment         = Enum.TextYAlignment.Center
	lbl.ZIndex                 = zIdx or 10
	lbl.TextTransparency      = 1

	if strokeColor then
		lbl.TextStrokeColor3      = strokeColor
		lbl.TextStrokeTransparency = strokeTrans or 0.55
	end
	return lbl
end

local title = makeLabel(panel, "Title",
	"Darpa Hub",
	Enum.Font.SourceSansBold,
	Color3.fromRGB(255, 255, 255),
	UDim2.new(1, -44, 0.30, 0),
	UDim2.new(0, 22, 0, 12),
	Enum.TextXAlignment.Center, 10,
	Color3.fromRGB(0, 120, 200), 0.42)

local subtitle = makeLabel(panel, "Subtitle",
	"By Originalityklan",
	Enum.Font.SourceSans,
	Color3.fromRGB(140, 195, 230),
	UDim2.new(1, -44, 0.12, 0),
	UDim2.new(0, 22, 0.36, 0),
	Enum.TextXAlignment.Center, 10,
	Color3.fromRGB(0, 80, 140), 0.60)

local desc1 = makeLabel(panel, "Desc1",
	"Next‑gen script hub  ·  Clean UI  ·  Instant load",
	Enum.Font.SourceSans,
	Color3.fromRGB(130, 142, 158),
	UDim2.new(1, -44, 0.09, 0),
	UDim2.new(0, 22, 0.52, 0))

local desc2 = makeLabel(panel, "Desc2",
	"Built for speed, style and reliability.",
	Enum.Font.SourceSans,
	Color3.fromRGB(100, 108, 122),
	UDim2.new(1, -44, 0.09, 0),
	UDim2.new(0, 22, 0.62, 0))

local gameLabel = makeLabel(panel, "GameLabel",
	gameName,
	Enum.Font.SourceSansBold,
	Color3.fromRGB(220, 228, 240),
	UDim2.new(0.44, 0, 0.13, 0),
	UDim2.new(0.98, 0, 0.98, 0),
	Enum.TextXAlignment.Right, 10)
gameLabel.AnchorPoint = Vector2.new(1, 1)

local textLabels = { title, subtitle, desc1, desc2, gameLabel }

-- ──────────────────────────────────────────────────────────
--  LOADING BAR
-- ──────────────────────────────────────────────────────────
local barBg = Instance.new("Frame", panel)
barBg.Name            = "BarBg"
barBg.Size            = UDim2.new(0.58, 0, 0.038, 0)
barBg.Position        = UDim2.new(0.21, 0, 0.83, 0)
barBg.BackgroundColor3 = Color3.fromRGB(22, 26, 36)
barBg.BorderSizePixel  = 0
barBg.ZIndex           = 10
Instance.new("UICorner", barBg).CornerRadius = UDim.new(0, 7)

local barFill = Instance.new("Frame", barBg)
barFill.Name            = "BarFill"
barFill.Size            = UDim2.new(0, 0, 1, 0)
barFill.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
barFill.BorderSizePixel  = 0
barFill.ZIndex           = 11
Instance.new("UICorner", barFill).CornerRadius = UDim.new(0, 7)

local fillGrad = Instance.new("UIGradient", barFill)
fillGrad.Rotation = 0
fillGrad.Color = ColorSequence.new {
	ColorSequenceKeypoint.new(0,   Color3.fromRGB(60, 200, 255)),
	ColorSequenceKeypoint.new(1,   Color3.fromRGB(0,  150, 230)),
}

local shimmer = Instance.new("Frame", barFill)
shimmer.Name            = "Shimmer"
shimmer.Size            = UDim2.new(0.45, 0, 1, 0)
shimmer.Position        = UDim2.new(-0.45, 0, 0, 0)
shimmer.BackgroundColor3 = Color3.new(1, 1, 1)
shimmer.BackgroundTransparency = 0.55
shimmer.BorderSizePixel  = 0
shimmer.ZIndex           = 12
Instance.new("UICorner", shimmer).CornerRadius = UDim.new(0, 7)

local shimmerGrad = Instance.new("UIGradient", shimmer)
shimmerGrad.Rotation = 0
shimmerGrad.Color = ColorSequence.new {
	ColorSequenceKeypoint.new(0,    Color3.new(1, 1, 1)),
	ColorSequenceKeypoint.new(0.5,  Color3.new(1, 1, 1)),
	ColorSequenceKeypoint.new(1,    Color3.new(1, 1, 1)),
}
shimmerGrad.Transparency = NumberSequence.new {
	NumberSequenceKeypoint.new(0,   1),
	NumberSequenceKeypoint.new(0.35, 0.45),
	NumberSequenceKeypoint.new(0.5, 0.35),
	NumberSequenceKeypoint.new(0.65, 0.45),
	NumberSequenceKeypoint.new(1,   1),
}

local barFlash = Instance.new("Frame", barBg)
barFlash.Name            = "BarFlash"
barFlash.Size            = UDim2.new(1, 0, 1, 0)
barFlash.BackgroundColor3 = Color3.new(1, 1, 1)
barFlash.BackgroundTransparency = 1
barFlash.BorderSizePixel  = 0
barFlash.ZIndex           = 13
Instance.new("UICorner", barFlash).CornerRadius = UDim.new(0, 7)

-- ──────────────────────────────────────────────────────────
--  PARTICLE BURST
-- ──────────────────────────────────────────────────────────
local particleLayer = Instance.new("Frame", gui)
particleLayer.Name   = "ParticleBurst"
particleLayer.Size   = UDim2.new(1, 0, 1, 0)
particleLayer.BackgroundTransparency = 1
particleLayer.ZIndex = 7

local function burstParticles(count)
	for i = 1, count do
		local p = Instance.new("Frame", particleLayer)
		local sz = math.random(2, 6)
		p.Size            = UDim2.new(0, sz, 0, sz)
		p.AnchorPoint     = Vector2.new(0.5, 0.5)
		p.Position        = UDim2.new(0.5, 0, 0.5, 0)

		local palette = {
			Color3.fromRGB(0,   200, 255),
			Color3.fromRGB(0,   240, 200),
			Color3.fromRGB(80,  220, 255),
			Color3.fromRGB(150, 235, 255),
			Color3.fromRGB(0,   180, 180),
			Color3.fromRGB(200, 240, 255),
		}
		p.BackgroundColor3 = palette[math.random(#palette)]
		p.BackgroundTransparency = 0.15
		p.BorderSizePixel  = 0
		p.ZIndex           = 7
		Instance.new("UICorner", p).CornerRadius = UDim.new(1, 0)

		local angle = math.random() * math.pi * 2
		local dist  = randRange(0.07, 0.26)
		local endX  = 0.5 + math.cos(angle) * dist
		local endY  = 0.5 + math.sin(angle) * dist * 1.55

		local life = randRange(0.40, 0.72)
		TweenService:Create(p, TweenInfo.new(life, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position            = UDim2.new(endX, 0, endY, 0),
			BackgroundTransparency = 1,
			Size                = UDim2.new(0, 0, 0, 0),
		}):Play()

		task.delay(life + 0.05, function() if p and p.Parent then p:Destroy() end end)
	end
end

-- ──────────────────────────────────────────────────────────
--  COMET SPAWN
-- ──────────────────────────────────────────────────────────
local function spawnComet(layer)
	local parent  = (layer == "near") and cometNear or cometFar
	local isNear  = (layer == "near")

	local coreSize   = isNear and math.random(18, 40)  or math.random(10, 22)
	local glowSize   = math.floor(coreSize * 2.8)
	local trailW     = math.floor(coreSize * 4.2)
	local trailH     = math.max(3, math.floor(coreSize * 0.45))
	local rotation   = math.random(-38, -10)

	local startX = 1.15
	local startY = randRange(-0.16, 0.34)

	local container = Instance.new("Frame", parent)
	container.Name              = "CometGroup"
	container.Size              = UDim2.new(0, trailW + coreSize, 0, glowSize)
	container.Position          = UDim2.new(startX, 0, startY, 0)
	container.AnchorPoint       = Vector2.new(0.5, 0.5)
	container.BackgroundTransparency = 1
	container.BorderSizePixel   = 0
	container.ZIndex            = isNear and 2 or 1
	container.Rotation          = rotation

	local trail = Instance.new("Frame", container)
	trail.Name            = "Trail"
	trail.Size            = UDim2.new(0, trailW, 0, trailH)
	trail.Position        = UDim2.new(0, 0, 0.5, -math.floor(trailH / 2))
	trail.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
	trail.BackgroundTransparency = 0.35
	trail.BorderSizePixel  = 0
	trail.ZIndex           = 0
	Instance.new("UICorner", trail).CornerRadius = UDim.new(0, 12)

	local trailGrad = Instance.new("UIGradient", trail)
	trailGrad.Rotation = 0
	trailGrad.Color = ColorSequence.new {
		ColorSequenceKeypoint.new(0,   Color3.fromRGB(20, 50, 100)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(100, 180, 240)),
		ColorSequenceKeypoint.new(1,   Color3.fromRGB(200, 235, 255)),
	}
	trailGrad.Transparency = NumberSequence.new {
		NumberSequenceKeypoint.new(0,   0.95),
		NumberSequenceKeypoint.new(0.5, 0.25),
		NumberSequenceKeypoint.new(1,   0.05),
	}

	local glow = Instance.new("Frame", container)
	glow.Name            = "Glow"
	glow.Size            = UDim2.new(0, glowSize, 0, glowSize)
	glow.AnchorPoint     = Vector2.new(0.5, 0.5)
	glow.Position        = UDim2.new(1, -math.floor(glowSize * 0.5) - math.floor(coreSize * 0.2), 0.5, 0)
	glow.BackgroundColor3 = Color3.fromRGB(0, 175, 255)
	glow.BackgroundTransparency = isNear and 0.72 or 0.84
	glow.BorderSizePixel  = 0
	glow.ZIndex           = 1
	Instance.new("UICorner", glow).CornerRadius = UDim.new(0, math.floor(glowSize / 2))

	local glowGrad = Instance.new("UIGradient", glow)
	glowGrad.Rotation = 0
	glowGrad.Color = ColorSequence.new {
		ColorSequenceKeypoint.new(0,   Color3.fromRGB(200, 240, 255)),
		ColorSequenceKeypoint.new(1,   Color3.fromRGB(0,   160, 255)),
	}
	glowGrad.Transparency = NumberSequence.new {
		NumberSequenceKeypoint.new(0, 0.05),
		NumberSequenceKeypoint.new(1, 0.92),
	}

	local core = Instance.new("Frame", container)
	core.Name            = "Core"
	core.Size            = UDim2.new(0, coreSize, 0, coreSize)
	core.AnchorPoint     = Vector2.new(0.5, 0.5)
	core.Position        = UDim2.new(1, -math.floor(coreSize * 0.5) - math.floor(coreSize * 0.2), 0.5, 0)
	core.BackgroundColor3 = Color3.new(1, 1, 1)
	core.BorderSizePixel  = 0
	core.ZIndex           = 2
	Instance.new("UICorner", core).CornerRadius = UDim.new(0, math.ceil(coreSize / 2))

	local endX = -0.30
	local endY = randRange(0.72, 1.28)
	local travelTime = isNear and randRange(0.85, 1.75) or randRange(1.7, 3.4)

	local tween = TweenService:Create(container,
		TweenInfo.new(travelTime, Enum.EasingStyle.Linear), {
			Position = UDim2.new(endX, 0, endY, 0),
		})
	tween:Play()

	task.delay(travelTime * 0.78, function()
		if not container or not container.Parent then return end
		local fadeDur = travelTime * 0.22
		for _, child in ipairs(container:GetDescendants()) do
			if child:IsA("Frame") then
				TweenService:Create(child, TweenInfo.new(fadeDur), {
					BackgroundTransparency = 1
				}):Play()
			end
		end
	end)

	task.delay(travelTime + 0.15, function()
		if container and container.Parent then container:Destroy() end
	end)
end

task.spawn(function()
	while gui and gui.Parent do
		pcall(spawnComet, "far")
		task.wait(randRange(0.07, 0.15))
		pcall(spawnComet, "near")
		task.wait(randRange(0.09, 0.18))
	end
end)

-- ──────────────────────────────────────────────────────────
--  SHIMMER LOOP
-- ──────────────────────────────────────────────────────────
local shimmerRunning = false
task.spawn(function()
	while gui and gui.Parent do
		if shimmerRunning then
			shimmer.Position = UDim2.new(-0.45, 0, 0, 0)
			TweenService:Create(shimmer, TweenInfo.new(0.9, Enum.EasingStyle.Linear), {
				Position = UDim2.new(1.45, 0, 0, 0)
			}):Play()
		end
		task.wait(1.1)
	end
end)

-- ──────────────────────────────────────────────────────────
--  PANEL OPEN / CLOSE ANIMATIONS
-- ──────────────────────────────────────────────────────────
local PANEL_W, PANEL_H = 0.70, 0.52

local function openPanel()
	TweenService:Create(dim,
		TweenInfo.new(OPEN_TIME * 0.85), {
			BackgroundTransparency = 0.52
		}):Play()

	if sound then pcall(function() sound:Play() end) end
	burstParticles(26)

	for i = 1, #shadowRings do
		local ring  = shadowRings[i]
		local scale = shadowScales[i]
		task.delay((i - 1) * 0.04, function()
			TweenService:Create(ring,
				TweenInfo.new(OPEN_TIME + 0.08, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
					Size = UDim2.new(PANEL_W * scale, 0, PANEL_H * scale, 0),
					BackgroundTransparency = shadowTransparencies[i]
				}):Play()
		end)
	end

	local panelTween = TweenService:Create(panel,
		TweenInfo.new(OPEN_TIME, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(PANEL_W, 0, PANEL_H, 0)
		})
	panelTween:Play()
	panelTween.Completed:Wait()

	TweenService:Create(topLine,
		TweenInfo.new(0.38, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
			Size = UDim2.new(0.62, 0, 0, 1)
		}):Play()

	local cascadeDelay = 0.08
	for i, lbl in ipairs(textLabels) do
		task.delay(cascadeDelay * (i - 1), function()
			TweenService:Create(lbl,
				TweenInfo.new(0.40, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
					TextTransparency = 0
				}):Play()
		end)
	end

	shimmerRunning = true
	barFill.Size = UDim2.new(0, 0, 1, 0)
end

local function runLoadingBar(duration)
	local t = TweenService:Create(barFill,
		TweenInfo.new(duration, Enum.EasingStyle.Linear), {
			Size = UDim2.new(1, 0, 1, 0)
		})
	t:Play()
	t.Completed:Wait()
	shimmerRunning = false

	barFlash.BackgroundTransparency = 0.15
	TweenService:Create(barFlash,
		TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			BackgroundTransparency = 1
		}):Play()
end

local function closePanel()
	local accentTween = TweenService:Create(topLine,
		TweenInfo.new(0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Size = UDim2.new(0, 0, 0, 1)
		})
	accentTween:Play()
	accentTween.Completed:Wait()

	local cascadeDelay = 0.055
	for i = #textLabels, 1, -1 do
		local lbl = textLabels[i]
		task.delay(cascadeDelay * (#textLabels - i), function()
			TweenService:Create(lbl,
				TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
					TextTransparency = 1
				}):Play()
		end)
	end
	task.wait(cascadeDelay * (#textLabels - 1) + 0.18)

	local panelTween = TweenService:Create(panel,
		TweenInfo.new(CLOSE_TIME, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Size = UDim2.new(0, 0, 0, 0)
		})

	for i = #shadowRings, 1, -1 do
		local ring = shadowRings[i]
		task.delay((#shadowRings - i) * 0.03, function()
			TweenService:Create(ring,
				TweenInfo.new(CLOSE_TIME + 0.04, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
					Size = UDim2.new(0, 0, 0, 0),
					BackgroundTransparency = 0.96
				}):Play()
		end)
	end

	panelTween:Play()
	panelTween.Completed:Wait()

	TweenService:Create(dim,
		TweenInfo.new(0.32), {
			BackgroundTransparency = 1
		}):Play()
end

-- ──────────────────────────────────────────────────────────
--  MAIN SEQUENCE
-- ──────────────────────────────────────────────────────────
local animOk, animErr = pcall(function()
	openPanel()
	runLoadingBar(INTERMISSION)
	task.wait(0.10)
	closePanel()
	task.wait(0.45)
	fireHook("onAfterClose")
end)

if gui and gui.Parent then
	pcall(function() gui:Destroy() end)
end

if not animOk then
	warn("DarpaHub: animation error —", animErr)
end

-- ──────────────────────────────────────────────────────────
--  EXECUTION
-- ──────────────────────────────────────────────────────────
local loadBlockOk, loadBlockErr = pcall(function()
	local ok, err = safeLoad(scriptURL, URL_UNSUPPORTED)
	if ok then
		print("DarpaHub: loaded successfully →", gameName)
		fireHook("onLoadSuccess", gameName)
	else
		warn("DarpaHub: failed to load —", tostring(err))
		fireHook("onLoadFail", tostring(err))
	end
end)

if not loadBlockOk then
	warn("DarpaHub: load block error —", tostring(loadBlockErr))
	fireHook("onLoadFail", tostring(loadBlockErr))
end