🚀 DarpaHub Library — Premium Modular Script Framework

DarpaHub is a production-ready modular scripting framework designed to build premium-grade universal script hubs with advanced UI, plugin architecture, runtime scheduler, hooks system, profiling tools, theme engine, and full persistence.

It is built for:

✅ Scalability
✅ Clean architecture
✅ High performance
✅ Visual polish
✅ Safe modular expansion
✅ Production environments

DarpaHub is NOT a single script.
It is a complete scripting framework.

📦 Features Overview
Core Systems

Modular Feature Engine

Hook & Event System (sync + async)

Scheduler with priority & throttling

Runtime lifecycle manager

Safe execution sandbox

getgenv global API export

UI Framework

Premium animated UI

Tab system

Widgets (buttons, toggles, sliders, labels)

Theme engine (dark/light/custom)

UI pooling for performance

Hot reload UI rebuild

Advanced Tooling

Plugin system with sandbox permissions

Hot reload plugins

Built-in profiler

Performance monitor helpers

Config persistence (JSON + fallback)

Developer Utilities

Keybind manager

Safe API exposure

Visual debugging tools

Runtime scheduler jobs

Hook debugging

📁 Architecture Overview
DarpaHub
│
├── Core Engine
│   ├── Feature lifecycle
│   ├── Runtime loop
│   ├── Scheduler
│   └── Hook system
│
├── UI Framework
│   ├── Theme engine
│   ├── Tabs
│   ├── Widgets
│   └── Pooling system
│
├── Plugin Loader
│   ├── Manifest system
│   ├── Sandbox API
│   └── Hot reload
│
├── Persistence
│   └── JSON save/load
│
└── Developer Tools
    ├── Profiler
    ├── Keybinds
    └── Safe API

⚙️ Getting Started
Load the library
local DarpaHub = loadstring(game:HttpGet("YOUR_LIB_URL"))()
DarpaHub:Init("unsupported") -- or "supported"


Your loader can handle animation & routing — DarpaHub only manages runtime.

🧠 Core Concepts
Feature System

Features are modular runtime units.

Registering a feature:
DarpaHub:RegisterFeature("MyFeature", {
    DefaultEnabled = false,

    Enable = function(self)
        print("Enabled")
    end,

    Disable = function(self)
        print("Disabled")
    end,

    Update = function(self)
        -- runs every frame while enabled
    end
})

Enable / Disable:
DarpaHub:EnableFeature("MyFeature")
DarpaHub:DisableFeature("MyFeature")

🔗 Hook System

DarpaHub provides a full event bus.

Create a hook:
DarpaHub:CreateHook("MyEvent")

Listen:
DarpaHub:ConnectHook("MyEvent", function(data)
    print(data)
end)

Fire:
DarpaHub:FireHook("MyEvent", {value = 123})

Fire async:
DarpaHub:FireHookAsync("MyEvent", payload)

⏱ Scheduler System

Used for optimized runtime jobs.

Add job:
local id = DarpaHub._private.Scheduler:AddJob(function(dt)
    print("Running")
end, {
    interval = 2,       -- seconds (nil = every frame)
    priority = 50,
    persistent = true
})

Remove job:
DarpaHub._private.Scheduler:RemoveJob(id)

🎨 UI Framework
Create tab:
local tab = DarpaHub:CreateTab("Main")
local api = tab.API

Add widgets:
api:AddLabel("Hello")

api:AddButton("Click Me", function()
    print("Pressed")
end)

api:AddToggle("Enable Feature", false, function(state)
    if state then
        DarpaHub:EnableFeature("MyFeature")
    else
        DarpaHub:DisableFeature("MyFeature")
    end
end)

api:AddSlider("Speed", 0, 10, 5, function(value)
    print(value)
end)

🎭 Theme Engine
Available by default:

Dark

Light

Midnight

Change theme:
DarpaHub.Theme:SetTheme("Dark")

Get colors:
local accent = DarpaHub.Theme:GetColor("Accent")

💾 Persistence
Save:
DarpaHub:SaveJSON("settings", {
    speed = 5,
    enabled = true
})

Load:
local data = DarpaHub:LoadJSON("settings")


Supports:

writefile/readfile

syn equivalents

fallback to getgenv

🔌 Plugin System

Plugins are sandboxed modules.

Manifest:
DarpaHub:RegisterPluginManifest({
    name = "MyPlugin",
    version = "1.0",
    url = "https://example.com/plugin.lua",
    author = "You",
    description = "Plugin description"
})

Load:
DarpaHub:LoadPlugin("MyPlugin")

Hot reload:
DarpaHub:HotReloadPlugin("MyPlugin")

Unload:
DarpaHub:UnloadPlugin("MyPlugin")

Plugin API (sandboxed):
DarpaHub.Logger
DarpaHub.UI.CreateTab()
DarpaHub.Scheduler.Add()
DarpaHub.Hooks.Fire()
DarpaHub.Persistence.Save()


Plugins never access game directly (by default).

📊 Profiler
Enable:
DarpaHub._private.Profiler:Enable()

Stats:
local stats = DarpaHub._private.Profiler:GetStats()


Tracks:

runtime ticks

feature execution cost

hook timings

⌨ Keybinds
DarpaHub:BindKey(Enum.KeyCode.F1, function()
    print("Pressed")
end)

🔥 Hot Reload

Rebuilds UI + preserves configs:

DarpaHub:HotReload()

🛡 Safe API Export

Accessible globally:

getgenv().DarpaHubAPI


Includes:

Feature registration

UI creation

Scheduler

Hooks

Persistence

Profiler controls

Used for plugins & external modules.

🧪 Runtime Flow
Loader
  ↓
DarpaHub:Init()
  ↓
Environment sync
  ↓
UI build
  ↓
Scheduler start
  ↓
Feature runtime loop

📈 Performance

DarpaHub is optimized via:

UI pooling

scheduler throttling

feature priority batching

minimal RenderStepped work

sandboxed plugins

🧩 Best Practices

✅ Keep heavy logic inside Scheduler jobs
✅ Use Hooks instead of direct calls
✅ Avoid per-frame allocations
✅ Use persistence for configs
✅ Modularize via plugins

⚠ Security Notes

• Plugins execute code — load only trusted sources
• Persistence stores locally — do not store secrets
• Sandbox limits access intentionally

📜 License

You may:

✔ Use commercially
✔ Modify
✔ Extend
✔ Embed in products

You may not:

❌ Claim original authorship of framework core


🌟 Summary

DarpaHub is a:

✔ Script framework
✔ UI engine
✔ Plugin platform
✔ Runtime system
✔ Developer toolkit

Built to power premium-grade universal script hubs.
