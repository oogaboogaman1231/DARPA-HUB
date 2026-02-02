-- ============================================================
--   DARPA HUB UI LIBRARY v2.0 (UPDATED)
--   Fixed Dropdowns + Advanced ESP (Health, Tracers, Dist)
-- ============================================================

local DarpaHub = {}
DarpaHub.__index = DarpaHub

-- ──────────────────────────────────────────────────────────
--  THEME
-- ──────────────────────────────────────────────────────────
DarpaHub.Theme = {
	Background = Color3.fromRGB(10, 10, 15),
	Panel      = Color3.fromRGB(18, 18, 24),
	Accent     = Color3.fromRGB(0, 210, 255),
	Glow       = Color3.fromRGB(0, 255, 255),
	Text       = Color3.fromRGB(255, 255, 255),
	Muted      = Color3.fromRGB(160, 160, 160),
	Red        = Color3.fromRGB(255, 80, 80),
	Green      = Color3.fromRGB(80, 255, 120),
	Outline    = Color3.fromRGB(0, 0, 0)
}

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local Container = (LocalPlayer and LocalPlayer:WaitForChild("PlayerGui", 5)) or game:GetService("CoreGui")

-- ──────────────────────────────────────────────────────────
--  UTILITIES
-- ──────────────────────────────────────────────────────────
function DarpaHub:Ripple(obj)
	task.spawn(function()
		local mousePos = UserInputService:GetMouseLocation()
		local objPos = obj.AbsolutePosition
		
		local circle = Instance.new("ImageLabel")
		circle.Parent = obj
		circle.BackgroundTransparency = 1
		circle.Image = "rbxassetid://266543268"
		circle.ImageColor3 = Color3.fromRGB(255, 255, 255)
		circle.ImageTransparency = 0.8
		circle.Size = UDim2.new(0, 0, 0, 0)
		circle.Position = UDim2.new(0, mousePos.X - objPos.X, 0, mousePos.Y - objPos.Y - 36)
		circle.ZIndex = obj.ZIndex + 1
		
		local tween = TweenService:Create(circle, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, 300, 0, 300),
			Position = UDim2.new(0, mousePos.X - objPos.X - 150, 0, mousePos.Y - objPos.Y - 186),
			ImageTransparency = 1
		})
		tween:Play()
		task.wait(0.4)
		circle:Destroy()
	end)
end

-- ──────────────────────────────────────────────────────────
--  ADVANCED ESP FRAMEWORK
-- ──────────────────────────────────────────────────────────
DarpaHub.ESP = {
	Enabled = false,
	Settings = {
		Box = true,
		Name = true,
		Distance = true,
		HealthBar = true,
		Tracers = false,
		TeamCheck = false,
		BoxColor = Color3.fromRGB(255, 255, 255),
		TracerOrigin = "Bottom" -- Mouse, Bottom, Top
	},
	Cache = {},
	Connections = {}
}

local hasDrawing = pcall(function() return Drawing.new end)

function DarpaHub.ESP:Create(player)
	if not hasDrawing then return end
	if self.Cache[player] then return end

	local objects = {
		Box = Drawing.new("Square"),
		BoxOutline = Drawing.new("Square"),
		HealthBar = Drawing.new("Line"),
		HealthOutline = Drawing.new("Line"),
		Name = Drawing.new("Text"),
		Distance = Drawing.new("Text"),
		Tracer = Drawing.new("Line")
	}

	-- Setup Defaults
	objects.Box.Visible = false
	objects.Box.Color = self.Settings.BoxColor
	objects.Box.Thickness = 1
	objects.Box.Filled = false

	objects.BoxOutline.Visible = false
	objects.BoxOutline.Color = Color3.new(0,0,0)
	objects.BoxOutline.Thickness = 3
	objects.BoxOutline.Filled = false

	objects.HealthBar.Visible = false
	objects.HealthBar.Color = Color3.new(0,1,0)
	objects.HealthBar.Thickness = 2

	objects.HealthOutline.Visible = false
	objects.HealthOutline.Color = Color3.new(0,0,0)
	objects.HealthOutline.Thickness = 4

	objects.Tracer.Visible = false
	objects.Tracer.Color = self.Settings.BoxColor
	objects.Tracer.Thickness = 1

	objects.Name.Visible = false
	objects.Name.Color = Color3.new(1,1,1)
	objects.Name.Size = 13
	objects.Name.Center = true
	objects.Name.Outline = true
	objects.Name.Text = player.Name

	objects.Distance.Visible = false
	objects.Distance.Color = Color3.new(1,1,1)
	objects.Distance.Size = 12
	objects.Distance.Center = true
	objects.Distance.Outline = true

	self.Cache[player] = objects
end

function DarpaHub.ESP:Remove(player)
	if self.Cache[player] then
		for _, obj in pairs(self.Cache[player]) do
			pcall(function() obj:Remove() end)
		end
		self.Cache[player] = nil
	end
end

function DarpaHub.ESP:Update()
	if not self.Enabled then return end
	local Camera = workspace.CurrentCamera
	local ViewportSize = Camera.ViewportSize

	for player, objects in pairs(self.Cache) do
		local character = player.Character
		local root = character and (character:FindFirstChild("HumanoidRootPart") or character:FindFirstChild("Torso"))
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local onTeam = self.Settings.TeamCheck and player.Team == LocalPlayer.Team

		if player ~= LocalPlayer and character and root and humanoid and humanoid.Health > 0 and not onTeam then
			local rootPos, onScreen = Camera:WorldToViewportPoint(root.Position)

			if onScreen then
				-- Calculate Size
				local head = character:FindFirstChild("Head")
				local leg = character:FindFirstChild("Left Leg") or character:FindFirstChild("LeftFoot")
				
				-- Fallback size calc if parts missing
				local boxHeight = head and leg and math.abs(Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0)).Y - Camera:WorldToViewportPoint(leg.Position - Vector3.new(0, 0.5, 0)).Y) or (3000 / rootPos.Z)
				local boxWidth = boxHeight * 0.65
				local boxPos = Vector2.new(rootPos.X - boxWidth / 2, rootPos.Y - boxHeight / 2)

				-- Update Box
				if self.Settings.Box then
					objects.BoxOutline.Size = Vector2.new(boxWidth, boxHeight)
					objects.BoxOutline.Position = boxPos
					objects.BoxOutline.Visible = true
					
					objects.Box.Size = Vector2.new(boxWidth, boxHeight)
					objects.Box.Position = boxPos
					objects.Box.Color = self.Settings.BoxColor
					objects.Box.Visible = true
				else
					objects.Box.Visible = false
					objects.BoxOutline.Visible = false
				end

				-- Update Health
				if self.Settings.HealthBar then
					local healthPercent = humanoid.Health / humanoid.MaxHealth
					local barHeight = boxHeight * healthPercent
					
					objects.HealthOutline.From = Vector2.new(boxPos.X - 5, boxPos.Y)
					objects.HealthOutline.To = Vector2.new(boxPos.X - 5, boxPos.Y + boxHeight)
					objects.HealthOutline.Visible = true

					objects.HealthBar.From = Vector2.new(boxPos.X - 5, boxPos.Y + boxHeight)
					objects.HealthBar.To = Vector2.new(boxPos.X - 5, boxPos.Y + boxHeight - barHeight)
					objects.HealthBar.Color = Color3.fromRGB(255 - (255 * healthPercent), 255 * healthPercent, 0)
					objects.HealthBar.Visible = true
				else
					objects.HealthBar.Visible = false
					objects.HealthOutline.Visible = false
				end

				-- Update Name
				if self.Settings.Name then
					objects.Name.Position = Vector2.new(rootPos.X, boxPos.Y - 16)
					objects.Name.Visible = true
				else
					objects.Name.Visible = false
				end

				-- Update Distance
				if self.Settings.Distance then
					local dist = math.floor((root.Position - Camera.CFrame.Position).Magnitude)
					objects.Distance.Text = "[" .. tostring(dist) .. "m]"
					objects.Distance.Position = Vector2.new(rootPos.X, boxPos.Y + boxHeight + 2)
					objects.Distance.Visible = true
				else
					objects.Distance.Visible = false
				end

				-- Update Tracer
				if self.Settings.Tracers then
					local origin = Vector2.new(ViewportSize.X / 2, ViewportSize.Y) -- Bottom
					objects.Tracer.From = origin
					objects.Tracer.To = Vector2.new(rootPos.X, boxPos.Y + boxHeight)
					objects.Tracer.Color = self.Settings.BoxColor
					objects.Tracer.Visible = true
				else
					objects.Tracer.Visible = false
				end

			else
				-- Off screen
				for _, obj in pairs(objects) do obj.Visible = false end
			end
		else
			-- Invalid player/dead/teammate
			for _, obj in pairs(objects) do obj.Visible = false end
		end
	end
end

function DarpaHub.ESP:Toggle(state)
	self.Enabled = state
	if state then
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= LocalPlayer then self:Create(p) end
		end
		
		self.Connections.Add = Players.PlayerAdded:Connect(function(p) self:Create(p) end)
		self.Connections.Rem = Players.PlayerRemoving:Connect(function(p) self:Remove(p) end)
		self.Connections.Upd = RunService.RenderStepped:Connect(function() self:Update() end)
	else
		if self.Connections.Upd then self.Connections.Upd:Disconnect() end
		if self.Connections.Add then self.Connections.Add:Disconnect() end
		if self.Connections.Rem then self.Connections.Rem:Disconnect() end
		for p, _ in pairs(self.Cache) do self:Remove(p) end
	end
end

-- ──────────────────────────────────────────────────────────
--  WINDOW SYSTEM
-- ──────────────────────────────────────────────────────────
function DarpaHub:CreateWindow(title)
	local Screen = Instance.new("ScreenGui")
	Screen.Name = "DarpaHubUI"
	Screen.ResetOnSpawn = false
	if Container then Screen.Parent = Container else Screen.Parent = LocalPlayer:WaitForChild("PlayerGui") end
	
	local Main = Instance.new("Frame", Screen)
	Main.Size = UDim2.new(0, 550, 0, 380)
	Main.Position = UDim2.new(0.5, -275, 0.5, -190)
	Main.BackgroundColor3 = self.Theme.Background
	Main.BorderSizePixel = 0
	Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)
	
	-- Dragging
	local dragToggle, dragStart, startPos
	Main.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragToggle = true
			dragStart = input.Position
			startPos = Main.Position
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragToggle and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - dragStart
			Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then dragToggle = false end
	end)

	-- Title
	local Title = Instance.new("TextLabel", Main)
	Title.Text = title
	Title.Size = UDim2.new(1, -40, 0, 40)
	Title.Position = UDim2.new(0, 20, 0, 0)
	Title.BackgroundTransparency = 1
	Title.TextColor3 = self.Theme.Accent
	Title.Font = Enum.Font.GothamBold
	Title.TextSize = 18
	Title.TextXAlignment = Enum.TextXAlignment.Left
	
	-- Close Button
	local Close = Instance.new("TextButton", Main)
	Close.Size = UDim2.new(0, 30, 0, 30)
	Close.Position = UDim2.new(1, -35, 0, 5)
	Close.BackgroundTransparency = 1
	Close.Text = "X"
	Close.TextColor3 = self.Theme.Muted
	Close.Font = Enum.Font.GothamBold
	Close.TextSize = 16
	Close.MouseButton1Click:Connect(function() Screen:Destroy() DarpaHub.ESP:Toggle(false) end)

	-- Tabs Container
	local TabArea = Instance.new("Frame", Main)
	TabArea.Size = UDim2.new(0, 130, 1, -50)
	TabArea.Position = UDim2.new(0, 10, 0, 45)
	TabArea.BackgroundColor3 = self.Theme.Panel
	Instance.new("UICorner", TabArea).CornerRadius = UDim.new(0, 8)

	local TabList = Instance.new("UIListLayout", TabArea)
	TabList.Padding = UDim.new(0, 5)
	TabList.HorizontalAlignment = Enum.HorizontalAlignment.Center
	
	-- Padding for Tabs
	local TabPad = Instance.new("UIPadding", TabArea)
	TabPad.PaddingTop = UDim.new(0, 10)

	-- Page Container
	local PageArea = Instance.new("Frame", Main)
	PageArea.Size = UDim2.new(1, -160, 1, -50)
	PageArea.Position = UDim2.new(0, 150, 0, 45)
	PageArea.BackgroundTransparency = 1
	PageArea.ClipsDescendants = true -- Important for sliders, but tricky for dropdowns

	local WindowAPI = { Tabs = {} }

	function WindowAPI:AddTab(name)
		local TabBtn = Instance.new("TextButton", TabArea)
		TabBtn.Size = UDim2.new(0.9, 0, 0, 32)
		TabBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
		TabBtn.Text = name
		TabBtn.TextColor3 = DarpaHub.Theme.Muted
		TabBtn.Font = Enum.Font.GothamSemibold
		TabBtn.TextSize = 14
		Instance.new("UICorner", TabBtn).CornerRadius = UDim.new(0, 6)

		local Page = Instance.new("ScrollingFrame", PageArea)
		Page.Size = UDim2.new(1, 0, 1, 0)
		Page.BackgroundTransparency = 1
		Page.ScrollBarThickness = 2
		Page.Visible = false
		Page.CanvasSize = UDim2.new(0,0,0,0) -- Auto resize later

		local PageLayout = Instance.new("UIListLayout", Page)
		PageLayout.Padding = UDim.new(0, 8)
		PageLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		
		-- Auto Canvas Size
		PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			Page.CanvasSize = UDim2.new(0, 0, 0, PageLayout.AbsoluteContentSize.Y + 20)
		end)

		TabBtn.MouseButton1Click:Connect(function()
			for _, p in pairs(PageArea:GetChildren()) do if p:IsA("ScrollingFrame") then p.Visible = false end end
			for _, t in pairs(TabArea:GetChildren()) do 
				if t:IsA("TextButton") then 
					TweenService:Create(t, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(30,30,40), TextColor3 = DarpaHub.Theme.Muted}):Play()
				end 
			end
			
			Page.Visible = true
			TweenService:Create(TabBtn, TweenInfo.new(0.2), {BackgroundColor3 = DarpaHub.Theme.Accent, TextColor3 = Color3.new(1,1,1)}):Play()
			DarpaHub:Ripple(TabBtn)
		end)

		-- Select first tab
		if #TabArea:GetChildren() == 3 then -- UIPadding + Layout + First Button
			TabBtn.MouseButton1Click:Fire()
		end

		local Elements = {}

		function Elements:AddToggle(text, default, callback)
			local Container = Instance.new("Frame", Page)
			Container.Size = UDim2.new(0.98, 0, 0, 38)
			Container.BackgroundColor3 = DarpaHub.Theme.Panel
			Instance.new("UICorner", Container).CornerRadius = UDim.new(0, 6)

			local Label = Instance.new("TextLabel", Container)
			Label.Text = text
			Label.Size = UDim2.new(1, -60, 1, 0)
			Label.Position = UDim2.new(0, 10, 0, 0)
			Label.BackgroundTransparency = 1
			Label.TextColor3 = DarpaHub.Theme.Text
			Label.Font = Enum.Font.Gotham
			Label.TextSize = 13
			Label.TextXAlignment = Enum.TextXAlignment.Left

			local Button = Instance.new("TextButton", Container)
			Button.Size = UDim2.new(0, 42, 0, 22)
			Button.Position = UDim2.new(1, -52, 0.5, -11)
			Button.BackgroundColor3 = default and DarpaHub.Theme.Accent or Color3.fromRGB(40,40,50)
			Button.Text = ""
			Instance.new("UICorner", Button).CornerRadius = UDim.new(1, 0)

			local Circle = Instance.new("Frame", Button)
			Circle.Size = UDim2.new(0, 16, 0, 16)
			Circle.Position = default and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
			Circle.BackgroundColor3 = Color3.new(1,1,1)
			Instance.new("UICorner", Circle).CornerRadius = UDim.new(1, 0)

			local on = default
			Button.MouseButton1Click:Connect(function()
				on = not on
				TweenService:Create(Button, TweenInfo.new(0.2), {BackgroundColor3 = on and DarpaHub.Theme.Accent or Color3.fromRGB(40,40,50)}):Play()
				TweenService:Create(Circle, TweenInfo.new(0.2), {Position = on and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)}):Play()
				pcall(callback, on)
			end)
			
			return { Set = function(val) if val ~= on then Button.MouseButton1Click:Fire() end end }
		end

		function Elements:AddSlider(text, min, max, default, callback)
			local Container = Instance.new("Frame", Page)
			Container.Size = UDim2.new(0.98, 0, 0, 50)
			Container.BackgroundColor3 = DarpaHub.Theme.Panel
			Instance.new("UICorner", Container).CornerRadius = UDim.new(0, 6)

			local Label = Instance.new("TextLabel", Container)
			Label.Text = text
			Label.Size = UDim2.new(1, 0, 0, 25)
			Label.Position = UDim2.new(0, 10, 0, 0)
			Label.BackgroundTransparency = 1
			Label.TextColor3 = DarpaHub.Theme.Text
			Label.Font = Enum.Font.Gotham
			Label.TextSize = 13
			Label.TextXAlignment = Enum.TextXAlignment.Left

			local Value = Instance.new("TextLabel", Container)
			Value.Text = tostring(default)
			Value.Size = UDim2.new(0, 50, 0, 25)
			Value.Position = UDim2.new(1, -60, 0, 0)
			Value.BackgroundTransparency = 1
			Value.TextColor3 = DarpaHub.Theme.Accent
			Value.Font = Enum.Font.GothamBold
			Value.TextSize = 13

			local Bar = Instance.new("Frame", Container)
			Bar.Size = UDim2.new(0.95, 0, 0, 4)
			Bar.Position = UDim2.new(0.025, 0, 0, 35)
			Bar.BackgroundColor3 = Color3.fromRGB(40,40,50)
			Instance.new("UICorner", Bar).CornerRadius = UDim.new(1, 0)

			local Fill = Instance.new("Frame", Bar)
			Fill.Size = UDim2.new((default-min)/(max-min), 0, 1, 0)
			Fill.BackgroundColor3 = DarpaHub.Theme.Accent
			Instance.new("UICorner", Fill).CornerRadius = UDim.new(1, 0)

			local Trigger = Instance.new("TextButton", Bar)
			Trigger.Size = UDim2.new(1,0,1,0)
			Trigger.BackgroundTransparency = 1
			Trigger.Text = ""

			local dragging = false
			Trigger.MouseButton1Down:Connect(function() dragging = true end)
			UserInputService.InputEnded:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end end)
			
			UserInputService.InputChanged:Connect(function(input)
				if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
					local pos = math.clamp((input.Position.X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
					local val = math.floor(min + (max-min)*pos)
					Fill.Size = UDim2.new(pos, 0, 1, 0)
					Value.Text = tostring(val)
					pcall(callback, val)
				end
			end)
		end

		function Elements:AddDropdown(text, options, default, callback)
			default = default or options[1]
			local Container = Instance.new("Frame", Page)
			Container.Size = UDim2.new(0.98, 0, 0, 40) -- Height increases when open
			Container.BackgroundColor3 = DarpaHub.Theme.Panel
			Container.ClipsDescendants = false -- FIX: Allows list to overflow
			Container.ZIndex = 5
			Instance.new("UICorner", Container).CornerRadius = UDim.new(0, 6)

			local Label = Instance.new("TextLabel", Container)
			Label.Text = text
			Label.Size = UDim2.new(0.5, 0, 0, 40)
			Label.Position = UDim2.new(0, 10, 0, 0)
			Label.BackgroundTransparency = 1
			Label.TextColor3 = DarpaHub.Theme.Text
			Label.Font = Enum.Font.Gotham
			Label.TextSize = 13
			Label.TextXAlignment = Enum.TextXAlignment.Left

			local MainBtn = Instance.new("TextButton", Container)
			MainBtn.Size = UDim2.new(0.45, 0, 0, 30)
			MainBtn.Position = UDim2.new(0.53, 0, 0, 5)
			MainBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
			MainBtn.Text = default
			MainBtn.TextColor3 = DarpaHub.Theme.Accent
			MainBtn.Font = Enum.Font.GothamBold
			MainBtn.TextSize = 12
			Instance.new("UICorner", MainBtn).CornerRadius = UDim.new(0, 6)

			local List = Instance.new("ScrollingFrame", Container)
			List.Size = UDim2.new(0.45, 0, 0, 0) -- Starts closed
			List.Position = UDim2.new(0.53, 0, 1, 2)
			List.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
			List.BorderSizePixel = 0
			List.Visible = false
			List.ZIndex = 100 -- FIX: Show above everything
			Instance.new("UICorner", List).CornerRadius = UDim.new(0, 6)

			local ListLayout = Instance.new("UIListLayout", List)
			ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
			ListLayout.Padding = UDim.new(0, 2)

			-- Refresh List Function
			local function UpdateOptions(newOptions)
				options = newOptions
				for _, c in pairs(List:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
				
				for _, opt in ipairs(options) do
					local Btn = Instance.new("TextButton", List)
					Btn.Size = UDim2.new(0.95, 0, 0, 25)
					Btn.BackgroundColor3 = Color3.fromRGB(35,35,45)
					Btn.Text = opt
					Btn.TextColor3 = Color3.new(1,1,1)
					Btn.Font = Enum.Font.Gotham
					Btn.TextSize = 12
					Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 4)
					
					Btn.MouseButton1Click:Connect(function()
						MainBtn.Text = opt
						List.Visible = false
						Container.ZIndex = 5
						pcall(callback, opt)
					end)
				end
				List.CanvasSize = UDim2.new(0,0,0, #options * 27)
			end

			local open = false
			MainBtn.MouseButton1Click:Connect(function()
				open = not open
				List.Visible = open
				if open then
					UpdateOptions(options) -- Refresh to ensure current table is used
					Container.ZIndex = 10 -- Bring container to front
					TweenService:Create(List, TweenInfo.new(0.2), {Size = UDim2.new(0.45, 0, 0, math.min(#options * 27, 150))}):Play()
				else
					Container.ZIndex = 5
					TweenService:Create(List, TweenInfo.new(0.2), {Size = UDim2.new(0.45, 0, 0, 0)}):Play()
				end
			end)
			
			return { 
				Refresh = function(list) UpdateOptions(list) end,
				Get = function() return MainBtn.Text end
			}
		end
		
		function Elements:AddButton(text, callback)
			local Button = Instance.new("TextButton", Page)
			Button.Size = UDim2.new(0.98, 0, 0, 36)
			Button.BackgroundColor3 = DarpaHub.Theme.Panel
			Button.Text = text
			Button.TextColor3 = DarpaHub.Theme.Text
			Button.Font = Enum.Font.GothamBold
			Button.TextSize = 13
			Instance.new("UICorner", Button).CornerRadius = UDim.new(0, 6)
			Instance.new("UIStroke", Button).Color = DarpaHub.Theme.Accent
			Button.UIStroke.Transparency = 0.8
			
			Button.MouseButton1Click:Connect(function()
				DarpaHub:Ripple(Button)
				pcall(callback)
			end)
		end

		return Elements
	end

	return WindowAPI
end

return DarpaHub