-- ============================================================
--   DARPA HUB v6.0 - ULTIMATE FEATURE SHOWCASE
--   Comprehensive demonstration of ALL library capabilities
--   by Originalityklan
-- ============================================================

print("╔═══════════════════════════════════════════════════════════╗")
print("║         DARPA HUB v6.0 - FEATURE SHOWCASE                 ║")
print("║         Loading comprehensive demo...                     ║")
print("╚═══════════════════════════════════════════════════════════╝")

-- Load DarpaHub Library
local DarpaHub = loadstring(game:HttpGet("https://raw.githubusercontent.com/oogaboogaman1231/DARPA-HUB/refs/heads/main/DarpaHubLib.lua"))()

-- Initialize framework
DarpaHub:Init("showcase_v6")

-- Wait for UI to be ready
task.wait(0.5)

-- ══════════════════════════════════════════════════════════════
--  TAB 1: THEME ENGINE
-- ══════════════════════════════════════════════════════════════

local ThemeTab = DarpaHub:CreateTab("🎨 Themes")

ThemeTab.API:AddLabel("═══════════════════════════════════")
ThemeTab.API:AddLabel("        THEME ENGINE DEMO")
ThemeTab.API:AddLabel("═══════════════════════════════════")
ThemeTab.API:AddLabel("")
ThemeTab.API:AddLabel("Switch between Dark, Midnight & Light themes")
ThemeTab.API:AddLabel("Theme selection persists across sessions!")
ThemeTab.API:AddLabel("")

ThemeTab.API:AddButton("🌙 Set Dark Theme", function()
	DarpaHub.Theme:SetTheme("Dark")
	print("[Theme] Switched to Dark theme")
end)

ThemeTab.API:AddButton("🌃 Set Midnight Theme", function()
	DarpaHub.Theme:SetTheme("Midnight")
	print("[Theme] Switched to Midnight theme")
end)

ThemeTab.API:AddButton("☀️ Set Light Theme", function()
	DarpaHub.Theme:SetTheme("Light")
	print("[Theme] Switched to Light theme")
end)

ThemeTab.API:AddLabel("")
ThemeTab.API:AddButton("🎨 Show Theme Colors", function()
	local theme = DarpaHub._private.ActiveTheme
	print("═══ CURRENT THEME: " .. (theme.Name or "Unknown") .. " ═══")
	print("Background:", theme.Background)
	print("Primary:", theme.Primary)
	print("Accent:", theme.Accent)
	print("Text:", theme.Text)
	print("Muted:", theme.Muted)
end)

-- ══════════════════════════════════════════════════════════════
--  TAB 2: FEATURES SYSTEM
-- ══════════════════════════════════════════════════════════════

local FeaturesTab = DarpaHub:CreateTab("⚡ Features")

FeaturesTab.API:AddLabel("═══════════════════════════════════")
FeaturesTab.API:AddLabel("     FEATURE LIFECYCLE SYSTEM")
FeaturesTab.API:AddLabel("═══════════════════════════════════")
FeaturesTab.API:AddLabel("")
FeaturesTab.API:AddLabel("Features have Enable, Disable & Update methods")
FeaturesTab.API:AddLabel("Update runs every frame when feature is enabled")
FeaturesTab.API:AddLabel("")

-- Register Demo Feature 1: Counter
DarpaHub:RegisterFeature("DemoCounter", {
	Config = {
		Count = 0,
		Target = 100
	},
	Enable = function(self)
		print("[DemoCounter] Enabled! Starting from", self.Config.Count)
		self.Config.StartTime = tick()
	end,
	Disable = function(self)
		local runtime = tick() - (self.Config.StartTime or tick())
		print("[DemoCounter] Disabled! Count reached:", self.Config.Count)
		print("[DemoCounter] Runtime:", string.format("%.2fs", runtime))
	end,
	Update = function(self)
		self.Config.Count = self.Config.Count + 1
		if self.Config.Count >= self.Config.Target then
			print("[DemoCounter] Target reached:", self.Config.Count)
			DarpaHub:DisableFeature("DemoCounter")
		end
	end,
	Priority = 10
})

-- Register Demo Feature 2: Timer
DarpaHub:RegisterFeature("DemoTimer", {
	Config = {
		Interval = 2,
		LastTick = 0
	},
	Enable = function(self)
		print("[DemoTimer] Enabled! Will tick every", self.Config.Interval, "seconds")
		self.Config.LastTick = tick()
	end,
	Disable = function(self)
		print("[DemoTimer] Disabled!")
	end,
	Update = function(self)
		local now = tick()
		if now - self.Config.LastTick >= self.Config.Interval then
			self.Config.LastTick = now
			print("[DemoTimer] Tick! Time:", os.date("%X"))
		end
	end,
	Priority = 20
})

FeaturesTab.API:AddToggle("Enable Demo Counter (counts to 100)", false, function(enabled)
	if enabled then
		DarpaHub:EnableFeature("DemoCounter")
	else
		DarpaHub:DisableFeature("DemoCounter")
	end
end)

FeaturesTab.API:AddToggle("Enable Demo Timer (ticks every 2s)", false, function(enabled)
	if enabled then
		DarpaHub:EnableFeature("DemoTimer")
	else
		DarpaHub:DisableFeature("DemoTimer")
	end
end)

FeaturesTab.API:AddLabel("")
FeaturesTab.API:AddButton("📊 List All Features", function()
	print("═══════════════ REGISTERED FEATURES ═══════════════")
	for name, feature in pairs(DarpaHub.Features) do
		print(string.format("  • %s", name))
		print(string.format("    Enabled: %s", tostring(feature.Enabled)))
		print(string.format("    Priority: %d", feature.Priority or 50))
	end
	print("═══════════════════════════════════════════════════")
end)

-- ══════════════════════════════════════════════════════════════
--  TAB 3: HOOKS SYSTEM
-- ══════════════════════════════════════════════════════════════

local HooksTab = DarpaHub:CreateTab("🔗 Hooks")

HooksTab.API:AddLabel("═══════════════════════════════════")
HooksTab.API:AddLabel("       EVENT HOOK SYSTEM")
HooksTab.API:AddLabel("═══════════════════════════════════")
HooksTab.API:AddLabel("")
HooksTab.API:AddLabel("Create custom events with multiple listeners")
HooksTab.API:AddLabel("Fire synchronously or asynchronously")
HooksTab.API:AddLabel("")

-- Create custom hooks
DarpaHub:CreateHook("CustomEvent")
DarpaHub:CreateHook("DataUpdate")
DarpaHub:CreateHook("UserAction")

-- Connect listeners
local listener1 = DarpaHub:ConnectHook("CustomEvent", function(data)
	print("[Listener 1] CustomEvent fired!")
	print("[Listener 1] Data:", data)
end)

local listener2 = DarpaHub:ConnectHook("CustomEvent", function(data)
	print("[Listener 2] Also received CustomEvent")
	if type(data) == "table" then
		for k, v in pairs(data) do
			print("[Listener 2]", k, "=", v)
		end
	end
end)

local listener3 = DarpaHub:ConnectHook("CustomEvent", function(data)
	print("[Listener 3] CustomEvent count:", (data and data.count) or 0)
end)

local eventCount = 0

HooksTab.API:AddButton("🔥 Fire CustomEvent (Sync)", function()
	eventCount = eventCount + 1
	DarpaHub:FireHook("CustomEvent", {
		timestamp = tick(),
		count = eventCount,
		message = "Hello from sync fire!",
		data = {x = 100, y = 200}
	})
	print("[Hooks] Sync fire complete - all listeners executed")
end)

HooksTab.API:AddButton("🔥 Fire CustomEvent (Async)", function()
	eventCount = eventCount + 1
	DarpaHub:FireHookAsync("CustomEvent", {
		timestamp = tick(),
		count = eventCount,
		message = "Hello from async fire!",
		async = true
	})
	print("[Hooks] Async fire started - listeners run in background")
end)

HooksTab.API:AddLabel("")
HooksTab.API:AddButton("❌ Disconnect Listener 1", function()
	listener1:Disconnect()
	print("[Hooks] Listener 1 disconnected")
end)

HooksTab.API:AddButton("❌ Disconnect Listener 2", function()
	listener2:Disconnect()
	print("[Hooks] Listener 2 disconnected")
end)

HooksTab.API:AddLabel("")
HooksTab.API:AddLabel("Built-in hooks: Inited, UIReady, ThemeChanged,")
HooksTab.API:AddLabel("FeatureEnabled, FeatureDisabled, TabActivated")

-- Monitor built-in hooks
DarpaHub:ConnectHook("ThemeChanged", function(themeName)
	print("[Built-in Hook] Theme changed to:", themeName)
end)

DarpaHub:ConnectHook("FeatureEnabled", function(name, feature)
	print("[Built-in Hook] Feature enabled:", name)
end)

DarpaHub:ConnectHook("FeatureDisabled", function(name, feature)
	print("[Built-in Hook] Feature disabled:", name)
end)

-- ══════════════════════════════════════════════════════════════
--  TAB 4: SCHEDULER
-- ══════════════════════════════════════════════════════════════

local SchedulerTab = DarpaHub:CreateTab("⏰ Scheduler")

SchedulerTab.API:AddLabel("═══════════════════════════════════")
SchedulerTab.API:AddLabel("         JOB SCHEDULER")
SchedulerTab.API:AddLabel("═══════════════════════════════════")
SchedulerTab.API:AddLabel("")
SchedulerTab.API:AddLabel("Schedule recurring or one-time jobs")
SchedulerTab.API:AddLabel("Jobs run based on priority (lower = first)")
SchedulerTab.API:AddLabel("")

local scheduledJobs = {}

SchedulerTab.API:AddButton("➕ Add Job: Print Every 1s", function()
	local id = DarpaHub._private.Scheduler:AddJob(function()
		print("[Scheduler] Recurring job tick:", os.date("%X"))
	end, {
		interval = 1,
		priority = 50,
		persistent = true
	})
	table.insert(scheduledJobs, {id = id, desc = "Print Every 1s"})
	print("[Scheduler] Added recurring job:", id)
end)

SchedulerTab.API:AddButton("➕ Add Job: High Priority (0.5s)", function()
	local id = DarpaHub._private.Scheduler:AddJob(function()
		print("[Scheduler] HIGH PRIORITY job executed")
	end, {
		interval = 0.5,
		priority = 10,  -- Lower priority = runs first
		persistent = true
	})
	table.insert(scheduledJobs, {id = id, desc = "High Priority"})
	print("[Scheduler] Added high-priority job:", id)
end)

SchedulerTab.API:AddButton("➕ Add Job: One-Shot", function()
	local id = DarpaHub._private.Scheduler:AddJob(function()
		print("[Scheduler] ONE-SHOT JOB EXECUTED!")
		print("[Scheduler] This job will auto-remove itself")
	end, {
		persistent = false  -- Runs once then removes
	})
	print("[Scheduler] Added one-shot job:", id)
end)

SchedulerTab.API:AddLabel("")
SchedulerTab.API:AddButton("❌ Remove Last Job", function()
	if #scheduledJobs > 0 then
		local job = table.remove(scheduledJobs)
		DarpaHub._private.Scheduler:RemoveJob(job.id)
		print("[Scheduler] Removed job:", job.desc, "ID:", job.id)
	else
		print("[Scheduler] No jobs to remove")
	end
end)

SchedulerTab.API:AddButton("📋 List All Jobs", function()
	print("═══ SCHEDULED JOBS ═══")
	for i, job in ipairs(scheduledJobs) do
		print(string.format("%d. %s (ID: %s)", i, job.desc, job.id))
	end
	if #scheduledJobs == 0 then
		print("  No jobs scheduled")
	end
end)

-- ══════════════════════════════════════════════════════════════
--  TAB 5: PROFILER
-- ══════════════════════════════════════════════════════════════

local ProfilerTab = DarpaHub:CreateTab("📊 Profiler")

ProfilerTab.API:AddLabel("═══════════════════════════════════")
ProfilerTab.API:AddLabel("      PERFORMANCE PROFILER")
ProfilerTab.API:AddLabel("═══════════════════════════════════")
ProfilerTab.API:AddLabel("")
ProfilerTab.API:AddLabel("Track execution time of functions")
ProfilerTab.API:AddLabel("Get detailed performance statistics")
ProfilerTab.API:AddLabel("")

ProfilerTab.API:AddToggle("Enable Profiler", false, function(enabled)
	if enabled then
		DarpaHub._private.Profiler:Enable()
		print("[Profiler] Enabled - now tracking function calls")
	else
		DarpaHub._private.Profiler:Disable()
		print("[Profiler] Disabled - not tracking")
	end
end)

ProfilerTab.API:AddLabel("")

ProfilerTab.API:AddButton("🧪 Test: Fast Function", function()
	DarpaHub._private.Profiler:Time("FastFunction", function()
		local sum = 0
		for i = 1, 1000 do
			sum = sum + i
		end
		return sum
	end)
	print("[Profiler] FastFunction executed and timed")
end)

ProfilerTab.API:AddButton("🧪 Test: Medium Function", function()
	DarpaHub._private.Profiler:Time("MediumFunction", function()
		local sum = 0
		for i = 1, 100000 do
			sum = sum + i
		end
		task.wait(0.05)
		return sum
	end)
	print("[Profiler] MediumFunction executed and timed")
end)

ProfilerTab.API:AddButton("🧪 Test: Slow Function", function()
	DarpaHub._private.Profiler:Time("SlowFunction", function()
		local sum = 0
		for i = 1, 500000 do
			sum = sum + math.sqrt(i)
		end
		task.wait(0.1)
		return sum
	end)
	print("[Profiler] SlowFunction executed and timed")
end)

ProfilerTab.API:AddLabel("")

ProfilerTab.API:AddButton("📈 Show Profiler Stats", function()
	local stats = DarpaHub._private.Profiler:GetStats()
	print("═══════════════ PROFILER STATISTICS ═══════════════")
	local count = 0
	for key, data in pairs(stats) do
		count = count + 1
		print(string.format("\n%s:", key))
		print(string.format("  Calls:       %d", data.calls))
		print(string.format("  Total Time:  %.4f seconds", data.totalTime))
		print(string.format("  Avg Time:    %.4f seconds", data.totalTime / data.calls))
		print(string.format("  Last Time:   %.4f seconds", data.lastTime))
	end
	if count == 0 then
		print("  No profiling data available")
		print("  Enable profiler and run test functions first")
	end
	print("═══════════════════════════════════════════════════")
end)

ProfilerTab.API:AddButton("🗑️ Reset Statistics", function()
	DarpaHub._private.Profiler:Reset()
	print("[Profiler] All statistics reset")
end)

-- ══════════════════════════════════════════════════════════════
--  TAB 6: PERSISTENCE
-- ══════════════════════════════════════════════════════════════

local PersistTab = DarpaHub:CreateTab("💾 Storage")

PersistTab.API:AddLabel("═══════════════════════════════════")
PersistTab.API:AddLabel("      DATA PERSISTENCE")
PersistTab.API:AddLabel("═══════════════════════════════════")
PersistTab.API:AddLabel("")
PersistTab.API:AddLabel("Save & load data across sessions")
PersistTab.API:AddLabel("Uses writefile if available, getgenv fallback")
PersistTab.API:AddLabel("")

local showcaseData = {
	username = "ShowcaseUser",
	score = 5000,
	level = 25,
	settings = {
		music = true,
		sfx = true,
		volume = 80,
		quality = "High"
	},
	stats = {
		gamesPlayed = 127,
		wins = 89,
		kills = 1523
	},
	timestamp = os.time()
}

PersistTab.API:AddButton("💾 Save Demo Data", function()
	local success = DarpaHub:SaveJSON("showcase_demo", showcaseData)
	if success then
		print("[Persistence] Data saved successfully!")
		print("[Persistence] Username:", showcaseData.username)
		print("[Persistence] Score:", showcaseData.score)
		print("[Persistence] Level:", showcaseData.level)
	else
		print("[Persistence] Save failed")
	end
end)

PersistTab.API:AddButton("📂 Load Demo Data", function()
	local loaded = DarpaHub:LoadJSON("showcase_demo")
	if loaded then
		print("[Persistence] Data loaded successfully!")
		print("[Persistence] Username:", loaded.username)
		print("[Persistence] Score:", loaded.score)
		print("[Persistence] Level:", loaded.level)
		print("[Persistence] Settings:", loaded.settings)
		print("[Persistence] Stats:", loaded.stats)
		print("[Persistence] Saved at:", os.date("%c", loaded.timestamp))
	else
		print("[Persistence] No saved data found")
		print("[Persistence] Save data first using the Save button")
	end
end)

PersistTab.API:AddLabel("")

PersistTab.API:AddButton("🔄 Modify & Re-save", function()
	showcaseData.score = showcaseData.score + 500
	showcaseData.level = showcaseData.level + 1
	showcaseData.stats.gamesPlayed = showcaseData.stats.gamesPlayed + 1
	showcaseData.timestamp = os.time()
	
	DarpaHub:SaveJSON("showcase_demo", showcaseData)
	print("[Persistence] Updated and saved!")
	print("[Persistence] New score:", showcaseData.score)
	print("[Persistence] New level:", showcaseData.level)
end)

PersistTab.API:AddButton("📋 Show Current Data", function()
	print("═══ CURRENT SHOWCASE DATA ═══")
	print("Username:", showcaseData.username)
	print("Score:", showcaseData.score)
	print("Level:", showcaseData.level)
	print("\nSettings:")
	for k, v in pairs(showcaseData.settings) do
		print("  " .. k .. ":", v)
	end
	print("\nStats:")
	for k, v in pairs(showcaseData.stats) do
		print("  " .. k .. ":", v)
	end
end)

-- ══════════════════════════════════════════════════════════════
--  TAB 7: KEYBINDS
-- ══════════════════════════════════════════════════════════════

local KeybindsTab = DarpaHub:CreateTab("⌨️ Keys")

KeybindsTab.API:AddLabel("═══════════════════════════════════")
KeybindsTab.API:AddLabel("       KEYBIND MANAGER")
KeybindsTab.API:AddLabel("═══════════════════════════════════")
KeybindsTab.API:AddLabel("")
KeybindsTab.API:AddLabel("Bind keyboard keys to custom functions")
KeybindsTab.API:AddLabel("")

-- Bind demo keys
DarpaHub:BindKey(Enum.KeyCode.F1, function()
	print("[Keybind] F1 pressed - Help system activated!")
end)

DarpaHub:BindKey(Enum.KeyCode.F2, function()
	print("[Keybind] F2 pressed - Quick toggle!")
	-- You could toggle a feature here
end)

DarpaHub:BindKey(Enum.KeyCode.F3, function()
	print("[Keybind] F3 pressed - Stats display!")
	local stats = DarpaHub._private.Profiler:GetStats()
	print("Current profiler entries:", #stats)
end)

DarpaHub:BindKey(Enum.KeyCode.F5, function()
	print("[Keybind] F5 pressed - Hot reloading UI...")
	DarpaHub:HotReload()
end)

DarpaHub:BindKey(Enum.KeyCode.F12, function()
	print("[Keybind] F12 pressed - Debug info!")
	print("DarpaHub Version:", DarpaHub.VERSION)
	print("Running:", DarpaHub.State.Running)
	print("Booted:", DarpaHub.State.Booted)
end)

KeybindsTab.API:AddLabel("Active Keybinds:")
KeybindsTab.API:AddLabel("  • F1 - Help System")
KeybindsTab.API:AddLabel("  • F2 - Quick Toggle")
KeybindsTab.API:AddLabel("  • F3 - Stats Display")
KeybindsTab.API:AddLabel("  • F5 - Hot Reload UI")
KeybindsTab.API:AddLabel("  • F12 - Debug Info")
KeybindsTab.API:AddLabel("")
KeybindsTab.API:AddLabel("Try pressing the keys now!")
KeybindsTab.API:AddLabel("")

KeybindsTab.API:AddButton("📋 List All Keybinds", function()
	print("═══ REGISTERED KEYBINDS ═══")
	for i, bind in ipairs(DarpaHub.Keybinds) do
		print(string.format("  %d. %s", i, tostring(bind.Key)))
	end
	print("Total keybinds:", #DarpaHub.Keybinds)
end)

-- ══════════════════════════════════════════════════════════════
--  TAB 8: UI PRO
-- ══════════════════════════════════════════════════════════════

local UIProTab = DarpaHub:CreateTab("🎨 UIPro")

UIProTab.API:AddLabel("═══════════════════════════════════")
UIProTab.API:AddLabel("     ADVANCED UI COMPONENTS")
UIProTab.API:AddLabel("═══════════════════════════════════")
UIProTab.API:AddLabel("")
UIProTab.API:AddLabel("Create custom windows with advanced controls")
UIProTab.API:AddLabel("")

local demoWindow = nil

UIProTab.API:AddButton("➕ Create Demo Window", function()
	if demoWindow then
		print("[UIPro] Window already exists!")
		return
	end
	
	-- Create window
	demoWindow = DarpaHub.UIPro:CreateWindow("UIPro Demo Window", UDim2.new(0, 450, 0, 350))
	
	-- Section 1: Toggles
	local section1 = DarpaHub.UIPro:CreateSection(demoWindow.Body, "Toggle Controls")
	
	DarpaHub.UIPro:CreateToggle(section1, "Enable Feature A", false, function(state)
		print("[UIPro Toggle] Feature A:", state)
	end)
	
	DarpaHub.UIPro:CreateToggle(section1, "Enable Feature B", true, function(state)
		print("[UIPro Toggle] Feature B:", state)
	end)
	
	-- Section 2: Sliders
	local section2 = DarpaHub.UIPro:CreateSection(demoWindow.Body, "Slider Controls")
	
	DarpaHub.UIPro:CreateSlider(section2, "Volume", 0, 100, 75, function(val)
		print("[UIPro Slider] Volume:", math.floor(val))
	end)
	
	DarpaHub.UIPro:CreateSlider(section2, "Speed", 1, 200, 50, function(val)
		print("[UIPro Slider] Speed:", math.floor(val))
	end)
	
	-- Section 3: Dropdowns
	local section3 = DarpaHub.UIPro:CreateSection(demoWindow.Body, "Dropdown Controls")
	
	DarpaHub.UIPro:CreateDropdown(section3, "Select Mode", 
		{"Easy", "Normal", "Hard", "Expert"}, 
		function(opt)
			print("[UIPro Dropdown] Selected mode:", opt)
		end)
	
	print("[UIPro] Demo window created successfully!")
	print("[UIPro] Window is draggable by the header")
end)

UIProTab.API:AddButton("❌ Destroy Demo Window", function()
	if demoWindow and demoWindow.Window then
		demoWindow.Window:Destroy()
		demoWindow = nil
		print("[UIPro] Demo window destroyed")
	else
		print("[UIPro] No window to destroy")
	end
end)

UIProTab.API:AddLabel("")
UIProTab.API:AddLabel("UIPro Components:")
UIProTab.API:AddLabel("  • Custom Windows (draggable)")
UIProTab.API:AddLabel("  • Sections (organized groups)")
UIProTab.API:AddLabel("  • Toggles (animated switches)")
UIProTab.API:AddLabel("  • Sliders (value adjusters)")
UIProTab.API:AddLabel("  • Dropdowns (option selectors)")

-- ══════════════════════════════════════════════════════════════
--  TAB 9: PLUGINS
-- ══════════════════════════════════════════════════════════════

local PluginsTab = DarpaHub:CreateTab("🔌 Plugins")

PluginsTab.API:AddLabel("═══════════════════════════════════")
PluginsTab.API:AddLabel("        PLUGIN SYSTEM")
PluginsTab.API:AddLabel("═══════════════════════════════════")
PluginsTab.API:AddLabel("")
PluginsTab.API:AddLabel("Extend functionality with sandboxed plugins")
PluginsTab.API:AddLabel("Plugins have access to DarpaHub API only")
PluginsTab.API:AddLabel("")

-- Register a comprehensive demo plugin
DarpaHub:RegisterPluginManifest({
	name = "ShowcasePlugin",
	version = "1.0.0",
	author = "DarpaHub Team",
	description = "Comprehensive demo plugin",
	code = [[
		print("[ShowcasePlugin] Initializing...")
		
		-- Plugin has access to DarpaHub API
		DarpaHub.Logger.Info("Plugin initialized successfully!")
		
		-- Create a custom tab
		local tab = DarpaHub.UI.CreateTab("🔌 Plugin Tab")
		
		-- Add UI elements
		tab.API:AddLabel("═══ PLUGIN SHOWCASE ═══")
		tab.API:AddLabel("")
		tab.API:AddLabel("This tab was created by a plugin!")
		tab.API:AddLabel("Plugins run in sandboxed environment")
		tab.API:AddLabel("")
		
		tab.API:AddButton("Plugin Action 1", function()
			DarpaHub.Logger.Info("Plugin button 1 clicked!")
		end)
		
		tab.API:AddButton("Plugin Action 2", function()
			DarpaHub.Logger.Info("Plugin button 2 clicked!")
			-- Save plugin data
			DarpaHub.Persistence.Save("plugin_clicks", {
				count = (DarpaHub.Persistence.Load("plugin_clicks") or {}).count or 0 + 1
			})
		end)
		
		tab.API:AddToggle("Plugin Toggle", false, function(state)
			DarpaHub.Logger.Info("Plugin toggle state:", state)
		end)
		
		tab.API:AddLabel("")
		tab.API:AddButton("Show Plugin Data", function()
			local data = DarpaHub.Persistence.Load("plugin_data")
			if data then
				DarpaHub.Logger.Info("Plugin was loaded at:", data.loaded)
			else
				DarpaHub.Logger.Info("No plugin data found")
			end
		end)
		
		-- Save plugin load time
		DarpaHub.Persistence.Save("plugin_data", {
			loaded = os.time(),
			name = DarpaHub.getName(),
			version = DarpaHub.getVersion()
		})
		
		-- Connect to theme changes
		DarpaHub.Hooks.Connect("ThemeChanged", function(theme)
			DarpaHub.Logger.Info("Theme changed to:", theme)
		end)
		
		-- Schedule a job
		local jobId = DarpaHub.Scheduler.Add(function()
			-- This runs periodically
		end, {interval = 5, persistent = true})
		
		-- Cleanup function
		function onUnload()
			DarpaHub.Logger.Info("ShowcasePlugin unloading...")
			DarpaHub.Scheduler.Remove(jobId)
		end
		
		print("[ShowcasePlugin] Loaded successfully!")
	]]
})

PluginsTab.API:AddButton("📦 Load Plugin", function()
	local ok, err = pcall(function()
		DarpaHub:LoadPlugin("ShowcasePlugin")
	end)
	if ok then
		print("[Plugins] ShowcasePlugin loaded successfully!")
		print("[Plugins] Check the new 'Plugin Tab' that appeared")
	else
		warn("[Plugins] Failed to load plugin:", err)
	end
end)

PluginsTab.API:AddButton("🔄 Hot Reload Plugin", function()
	local ok, err = pcall(function()
		DarpaHub:HotReloadPlugin("ShowcasePlugin")
	end)
	if ok then
		print("[Plugins] Plugin hot reloaded successfully!")
	else
		warn("[Plugins] Hot reload failed:", err)
	end
end)

PluginsTab.API:AddButton("❌ Unload Plugin", function()
	local ok = DarpaHub:UnloadPlugin("ShowcasePlugin")
	if ok then
		print("[Plugins] Plugin unloaded successfully")
	else
		print("[Plugins] No plugin to unload or unload failed")
	end
end)

PluginsTab.API:AddLabel("")
PluginsTab.API:AddLabel("Plugin API Access:")
PluginsTab.API:AddLabel("  • DarpaHub.Logger (Info/Warn/Error)")
PluginsTab.API:AddLabel("  • DarpaHub.Scheduler (Add/Remove)")
PluginsTab.API:AddLabel("  • DarpaHub.Hooks (Connect/Fire)")
PluginsTab.API:AddLabel("  • DarpaHub.UI (CreateTab/Theme)")
PluginsTab.API:AddLabel("  • DarpaHub.Persistence (Save/Load)")

-- ══════════════════════════════════════════════════════════════
--  TAB 10: SYSTEM INFO
-- ══════════════════════════════════════════════════════════════

local SystemTab = DarpaHub:CreateTab("ℹ️ System")

SystemTab.API:AddLabel("═══════════════════════════════════")
SystemTab.API:AddLabel("       SYSTEM INFORMATION")
SystemTab.API:AddLabel("═══════════════════════════════════")
SystemTab.API:AddLabel("")

SystemTab.API:AddButton("📊 Show Full Status", function()
	print("╔═══════════════════════════════════════════════════╗")
	print("║          DARPA HUB SYSTEM STATUS                  ║")
	print("╠═══════════════════════════════════════════════════╣")
	print("║ Version:        ", DarpaHub.VERSION)
	print("║ Built At:       ", os.date("%c", DarpaHub.BuiltAt))
	print("║ Booted:         ", DarpaHub.State.Booted)
	print("║ Running:        ", DarpaHub.State.Running)
	print("║ Mode:           ", DarpaHub.State.Mode)
	print("║ Environment:    ", DarpaHub.State.EnvironmentReady)
	print("╠═══════════════════════════════════════════════════╣")
	print("║ Registered Features:", #DarpaHub._private.FeatureOrder)
	print("║ Active Connections: ", #DarpaHub._private.Connections)
	print("║ Registered Keybinds:", #DarpaHub.Keybinds)
	
	local pluginCount = 0
	for _ in pairs(DarpaHub._private.Plugins) do pluginCount = pluginCount + 1 end
	print("║ Loaded Plugins:    ", pluginCount)
	
	local theme = DarpaHub._private.ActiveTheme
	print("║ Active Theme:      ", theme and theme.Name or "Unknown")
	print("╚═══════════════════════════════════════════════════╝")
end)

SystemTab.API:AddButton("🔄 Hot Reload UI", function()
	print("[System] Initiating hot reload...")
	DarpaHub:HotReload()
end)

SystemTab.API:AddLabel("")

SystemTab.API:AddButton("🎯 Test All Systems", function()
	print("╔═══════════════════════════════════════════════════╗")
	print("║          SYSTEM DIAGNOSTICS                       ║")
	print("╠═══════════════════════════════════════════════════╣")
	
	-- Test Hooks
	local ok = pcall(function()
		DarpaHub:CreateHook("TestDiag")
		DarpaHub:ConnectHook("TestDiag", function() end)
		DarpaHub:FireHook("TestDiag")
	end)
	print("║ Hooks System:        ", ok and "✓ PASS" or "✗ FAIL")
	
	-- Test Scheduler
	ok = pcall(function()
		local id = DarpaHub._private.Scheduler:AddJob(function() end, {persistent = false})
		DarpaHub._private.Scheduler:RemoveJob(id)
	end)
	print("║ Scheduler:           ", ok and "✓ PASS" or "✗ FAIL")
	
	-- Test Persistence
	ok = pcall(function()
		DarpaHub:SaveJSON("diag_test", {test = true})
		DarpaHub:LoadJSON("diag_test")
	end)
	print("║ Persistence:         ", ok and "✓ PASS" or "✗ FAIL")
	
	-- Test Theme
	ok = pcall(function()
		DarpaHub.Theme:GetColor("Accent")
	end)
	print("║ Theme Engine:        ", ok and "✓ PASS" or "✗ FAIL")
	
	-- Test Profiler
	ok = pcall(function()
		DarpaHub._private.Profiler:Time("diag_test", function() end)
	end)
	print("║ Profiler:            ", ok and "✓ PASS" or "✗ FAIL")
	
	-- Test Features
	ok = pcall(function()
		return DarpaHub.Features ~= nil
	end)
	print("║ Feature System:      ", ok and "✓ PASS" or "✗ FAIL")
	
	print("╠═══════════════════════════════════════════════════╣")
	print("║ All core systems operational!                     ║")
	print("╚═══════════════════════════════════════════════════╝")
end)

SystemTab.API:AddLabel("")

SystemTab.API:AddButton("🗑️ Cleanup & Exit", function()
	print("[System] Initiating shutdown sequence...")
	
	-- Disable all features
	for name, feature in pairs(DarpaHub.Features) do
		if feature.Enabled then
			DarpaHub:DisableFeature(name)
		end
	end
	
	-- Disconnect all connections
	DarpaHub:DisconnectAll()
	
	-- Destroy UI
	if DarpaHub._private.UI and DarpaHub._private.UI.ScreenGui then
		DarpaHub._private.UI.ScreenGui:Destroy()
	end
	
	print("[System] Shutdown complete - DarpaHub unloaded")
end)

-- ══════════════════════════════════════════════════════════════
--  TAB 11: DOCUMENTATION
-- ══════════════════════════════════════════════════════════════

local DocsTab = DarpaHub:CreateTab("📖 Docs")

DocsTab.API:AddLabel("═══════════════════════════════════")
DocsTab.API:AddLabel("       API QUICK REFERENCE")
DocsTab.API:AddLabel("═══════════════════════════════════")
DocsTab.API:AddLabel("")
DocsTab.API:AddLabel("THEME SYSTEM:")
DocsTab.API:AddLabel("  DarpaHub.Theme:SetTheme(name)")
DocsTab.API:AddLabel("  DarpaHub.Theme:GetColor(key)")
DocsTab.API:AddLabel("")
DocsTab.API:AddLabel("FEATURES:")
DocsTab.API:AddLabel("  DarpaHub:RegisterFeature(name, desc)")
DocsTab.API:AddLabel("  DarpaHub:EnableFeature(name)")
DocsTab.API:AddLabel("  DarpaHub:DisableFeature(name)")
DocsTab.API:AddLabel("")
DocsTab.API:AddLabel("HOOKS:")
DocsTab.API:AddLabel("  DarpaHub:CreateHook(name)")
DocsTab.API:AddLabel("  DarpaHub:ConnectHook(name, fn)")
DocsTab.API:AddLabel("  DarpaHub:FireHook(name, ...)")
DocsTab.API:AddLabel("  DarpaHub:FireHookAsync(name, ...)")
DocsTab.API:AddLabel("")
DocsTab.API:AddLabel("SCHEDULER:")
DocsTab.API:AddLabel("  Scheduler:AddJob(fn, opts)")
DocsTab.API:AddLabel("  Scheduler:RemoveJob(id)")
DocsTab.API:AddLabel("")
DocsTab.API:AddLabel("PERSISTENCE:")
DocsTab.API:AddLabel("  DarpaHub:SaveJSON(name, table)")
DocsTab.API:AddLabel("  DarpaHub:LoadJSON(name)")
DocsTab.API:AddLabel("")
DocsTab.API:AddLabel("UI:")
DocsTab.API:AddLabel("  DarpaHub:CreateTab(name)")
DocsTab.API:AddLabel("  tab.API:AddLabel(text)")
DocsTab.API:AddLabel("  tab.API:AddButton(text, fn)")
DocsTab.API:AddLabel("  tab.API:AddToggle(text, default, fn)")
DocsTab.API:AddLabel("")
DocsTab.API:AddLabel("KEYBINDS:")
DocsTab.API:AddLabel("  DarpaHub:BindKey(keyCode, fn)")
DocsTab.API:AddLabel("")
DocsTab.API:AddLabel("PLUGINS:")
DocsTab.API:AddLabel("  DarpaHub:RegisterPluginManifest(m)")
DocsTab.API:AddLabel("  DarpaHub:LoadPlugin(name)")
DocsTab.API:AddLabel("  DarpaHub:UnloadPlugin(name)")
DocsTab.API:AddLabel("")

DocsTab.API:AddButton("📋 Print Full API", function()
	print("═══════════════ DARPAHUB API REFERENCE ═══════════════")
	print("Access via: getgenv().DarpaHubAPI")
	print("")
	print("Core Methods:")
	print("  • RegisterFeature(name, descriptor)")
	print("  • EnableFeature(name)")
	print("  • DisableFeature(name)")
	print("  • CreateTab(name)")
	print("  • BindKey(keyCode, callback)")
	print("")
	print("Subsystems:")
	print("  • Theme (SetTheme, GetColor)")
	print("  • Scheduler (AddJob, RemoveJob)")
	print("  • Hooks (Connect, Fire)")
	print("  • Persistence (Save, Load)")
	print("  • Profiler (Enable, Disable, GetStats)")
	print("")
	print("See documentation at DarpaHubLib.lua")
	print("═══════════════════════════════════════════════════════")
end)

-- ══════════════════════════════════════════════════════════════
--  MONITOR ALL EVENTS
-- ══════════════════════════════════════════════════════════════

-- Theme changes
DarpaHub:ConnectHook("ThemeChanged", function(themeName)
	print("🎨 [Event] Theme changed to:", themeName)
end)

-- Tab activation
DarpaHub:ConnectHook("TabActivated", function(tabName)
	print("📑 [Event] Tab activated:", tabName)
end)

-- Feature lifecycle
DarpaHub:ConnectHook("FeatureRegistered", function(name)
	print("⚡ [Event] Feature registered:", name)
end)

-- Profiler updates (fires every 5 seconds)
DarpaHub:ConnectHook("ProfilerTick", function(stats)
	-- Uncomment to see periodic profiler stats
	-- print("📊 [Event] Profiler tick - entries:", #stats)
end)

-- ══════════════════════════════════════════════════════════════
--  STARTUP COMPLETE
-- ══════════════════════════════════════════════════════════════

print("\n╔═══════════════════════════════════════════════════════════╗")
print("║                                                           ║")
print("║     ✅ DARPA HUB v6.0 SHOWCASE LOADED SUCCESSFULLY!      ║")
print("║                                                           ║")
print("╠═══════════════════════════════════════════════════════════╣")
print("║                                                           ║")
print("║  📚 FEATURES DEMONSTRATED:                                ║")
print("║    • Theme Engine (Dark/Midnight/Light)                   ║")
print("║    • Feature Lifecycle System                             ║")
print("║    • Event Hook System (Sync/Async)                       ║")
print("║    • Job Scheduler (Priority-based)                       ║")
print("║    • Performance Profiler                                 ║")
print("║    • Data Persistence (JSON)                              ║")
print("║    • Keybind Manager                                      ║")
print("║    • Plugin System (Sandboxed)                            ║")
print("║    • UIPro Components                                     ║")
print("║    • Hot Reload                                           ║")
print("║    • Safe API Export                                      ║")
print("║                                                           ║")
print("╠═══════════════════════════════════════════════════════════╣")
print("║                                                           ║")
print("║  🎮 EXPLORE THE TABS TO SEE EVERYTHING IN ACTION!        ║")
print("║                                                           ║")
print("║  ⌨️  ACTIVE KEYBINDS:                                     ║")
print("║    • F1  - Help System                                    ║")
print("║    • F2  - Quick Toggle                                   ║")
print("║    • F3  - Stats Display                                  ║")
print("║    • F5  - Hot Reload UI                                  ║")
print("║    • F12 - Debug Info                                     ║")
print("║                                                           ║")
print("╠═══════════════════════════════════════════════════════════╣")
print("║                                                           ║")
print("║  📖 Full documentation in the 'Docs' tab                  ║")
print("║  🔧 System diagnostics in the 'System' tab                ║")
print("║                                                           ║")
print("╚═══════════════════════════════════════════════════════════╝\n")
