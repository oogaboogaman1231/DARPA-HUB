-- ============================================================
--   DARPA HUB UI LIBRARY v1.0
--   Production-ready UI framework for Roblox exploiting
--   By Originalityklan
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
	Green      = Color3.fromRGB(80, 255, 120)
}

-- ──────────────────────────────────────────────────────────
--  SERVICES
-- ──────────────────────────────────────────────────────────
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Use PlayerGui instead of CoreGui for better compatibility
local Container = LocalPlayer:WaitForChild("PlayerGui")

-- ──────────────────────────────────────────────────────────
--  UTILITIES
-- ──────────────────────────────────────────────────────────

-- Ripple effect (fixed to use UserInputService)
local function Ripple(obj)
	task.spawn(function()
		local mousePos = UserInputService:GetMouseLocation()
		local objPos = obj.AbsolutePosition
		
		local circle = Instance.new("ImageLabel")
		circle.Parent = obj
		circle.BackgroundTransparency = 1
		circle.Image = "rbxassetid://266543268"
		circle.ImageColor3 = Color3.fromRGB(255, 255, 255)
		circle.ImageTransparency = 0.75
		circle.Size = UDim2.new(0, 0, 0, 0)
		circle.Position = UDim2.new(0, mousePos.X - objPos.X, 0, mousePos.Y - objPos.Y - 36)
		circle.ZIndex = 100
		
		local tween = TweenService:Create(circle, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, 200, 0, 200),
			Position = UDim2.new(0, mousePos.X - objPos.X - 100, 0, mousePos.Y - objPos.Y - 136),
			ImageTransparency = 1
		})
		tween:Play()
		task.wait(0.5)
		if circle and circle.Parent then circle:Destroy() end
	end)
end

-- ──────────────────────────────────────────────────────────
--  PLAYER UTILITIES
-- ──────────────────────────────────────────────────────────
DarpaHub.Utils = {}

function DarpaHub.Utils:GetPlayers()
	local list = {}
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= LocalPlayer then
			table.insert(list, player)
		end
	end
	return list
end

function DarpaHub.Utils:GetCharacter(player)
	player = player or LocalPlayer
	return player.Character
end

function DarpaHub.Utils:GetRoot(player)
	local char = self:GetCharacter(player)
	return char and (char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Torso"))
end

function DarpaHub.Utils:GetHumanoid(player)
	local char = self:GetCharacter(player)
	return char and char:FindFirstChildOfClass("Humanoid")
end

function DarpaHub.Utils:Teleport(position)
	local root = self:GetRoot()
	if root then
		root.CFrame = typeof(position) == "CFrame" and position or CFrame.new(position)
	end
end

function DarpaHub.Utils:SetWalkSpeed(speed)
	local hum = self:GetHumanoid()
	if hum then hum.WalkSpeed = speed end
end

function DarpaHub.Utils:SetJumpPower(power)
	local hum = self:GetHumanoid()
	if hum then hum.JumpPower = power end
end

function DarpaHub.Utils:GetDistance(player)
	local myRoot = self:GetRoot()
	local theirRoot = self:GetRoot(player)
	if myRoot and theirRoot then
		return (myRoot.Position - theirRoot.Position).Magnitude
	end
	return math.huge
end

function DarpaHub.Utils:GetClosestPlayer()
	local closest, minDist = nil, math.huge
	for _, player in ipairs(self:GetPlayers()) do
		local dist = self:GetDistance(player)
		if dist < minDist then
			minDist = dist
			closest = player
		end
	end
	return closest, minDist
end

-- ──────────────────────────────────────────────────────────
--  ESP FRAMEWORK (uses Drawing API if available)
-- ──────────────────────────────────────────────────────────
DarpaHub.ESP = {
	Enabled = false,
	Boxes = {},
	Connections = {}
}

-- Check if Drawing API is available
local hasDrawing = pcall(function() return Drawing.new end)

function DarpaHub.ESP:CreateBox(player)
	if not hasDrawing then return end
	
	local box = Drawing.new("Square")
	box.Visible = false
	box.Color = DarpaHub.Theme.Accent
	box.Thickness = 2
	box.Transparency = 1
	box.Filled = false
	
	local nameTag = Drawing.new("Text")
	nameTag.Visible = false
	nameTag.Color = DarpaHub.Theme.Text
	nameTag.Size = 14
	nameTag.Center = true
	nameTag.Outline = true
	nameTag.Text = player.Name
	
	self.Boxes[player] = { Box = box, Name = nameTag }
end

function DarpaHub.ESP:RemoveBox(player)
	local data = self.Boxes[player]
	if data then
		if data.Box then pcall(function() data.Box:Remove() end) end
		if data.Name then pcall(function() data.Name:Remove() end) end
		self.Boxes[player] = nil
	end
end

function DarpaHub.ESP:UpdateBox(player)
	if not hasDrawing then return end
	
	local data = self.Boxes[player]
	if not data then return end
	
	local char = DarpaHub.Utils:GetCharacter(player)
	local root = char and char:FindFirstChild("HumanoidRootPart")
	
	if not root then
		data.Box.Visible = false
		data.Name.Visible = false
		return
	end
	
	local camera = workspace.CurrentCamera
	local rootPos, onScreen = camera:WorldToViewportPoint(root.Position)
	
	if not onScreen then
		data.Box.Visible = false
		data.Name.Visible = false
		return
	end
	
	local head = char:FindFirstChild("Head")
	local legLeft = char:FindFirstChild("Left Leg") or char:FindFirstChild("LeftFoot")
	
	if not head or not legLeft then
		data.Box.Visible = false
		data.Name.Visible = false
		return
	end
	
	local headPos = camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
	local legPos = camera:WorldToViewportPoint(legLeft.Position - Vector3.new(0, 0.5, 0))
	
	local height = math.abs(headPos.Y - legPos.Y)
	local width = height * 0.5
	
	data.Box.Size = Vector2.new(width, height)
	data.Box.Position = Vector2.new(rootPos.X - width / 2, rootPos.Y - height / 2)
	data.Box.Visible = self.Enabled
	
	data.Name.Position = Vector2.new(rootPos.X, headPos.Y - 20)
	data.Name.Visible = self.Enabled
end

function DarpaHub.ESP:Toggle(state)
	if not hasDrawing then
		warn("[DarpaHub ESP] Drawing API not available in this executor")
		return
	end
	
	self.Enabled = state
	
	if state then
		-- Create boxes for existing players
		for _, player in ipairs(Players:GetPlayers()) do
			if player ~= LocalPlayer and not self.Boxes[player] then
				self:CreateBox(player)
			end
		end
		
		-- Update loop
		if not self.Connections.Update then
			self.Connections.Update = RunService.RenderStepped:Connect(function()
				for player, _ in pairs(self.Boxes) do
					if player.Parent then
						self:UpdateBox(player)
					else
						self:RemoveBox(player)
					end
				end
			end)
		end
		
		-- Player added/removed
		if not self.Connections.PlayerAdded then
			self.Connections.PlayerAdded = Players.PlayerAdded:Connect(function(player)
				if self.Enabled and player ~= LocalPlayer then
					self:CreateBox(player)
				end
			end)
		end
		
		if not self.Connections.PlayerRemoving then
			self.Connections.PlayerRemoving = Players.PlayerRemoving:Connect(function(player)
				self:RemoveBox(player)
			end)
		end
	else
		-- Hide all boxes
		for _, data in pairs(self.Boxes) do
			data.Box.Visible = false
			data.Name.Visible = false
		end
	end
end

function DarpaHub.ESP:Cleanup()
	self:Toggle(false)
	for player, _ in pairs(self.Boxes) do
		self:RemoveBox(player)
	end
	for _, conn in pairs(self.Connections) do
		if conn then conn:Disconnect() end
	end
	self.Connections = {}
end

-- ──────────────────────────────────────────────────────────
--  LOADER SYSTEM
-- ──────────────────────────────────────────────────────────
function DarpaHub:CreateLoader()
	local LoaderGui = Instance.new("ScreenGui")
	LoaderGui.Name = "DarpaHubLoader"
	LoaderGui.ResetOnSpawn = false
	LoaderGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	LoaderGui.Parent = Container
	
	local Main = Instance.new("Frame", LoaderGui)
	Main.Size = UDim2.new(0, 320, 0, 120)
	Main.Position = UDim2.new(0.5, -160, 0.5, -60)
	Main.AnchorPoint = Vector2.new(0.5, 0.5)
	Main.BackgroundColor3 = self.Theme.Background
	Main.BorderSizePixel = 0
	
	local corner = Instance.new("UICorner", Main)
	corner.CornerRadius = UDim.new(0, 15)
	
	local stroke = Instance.new("UIStroke", Main)
	stroke.Color = self.Theme.Accent
	stroke.Thickness = 2
	stroke.Transparency = 0.5
	
	local Title = Instance.new("TextLabel", Main)
	Title.Size = UDim2.new(1, 0, 0, 40)
	Title.Position = UDim2.new(0, 0, 0, 10)
	Title.BackgroundTransparency = 1
	Title.Text = "DARPA HUB"
	Title.TextColor3 = self.Theme.Glow
	Title.Font = Enum.Font.GothamBold
	Title.TextSize = 20
	
	local Status = Instance.new("TextLabel", Main)
	Status.Size = UDim2.new(1, 0, 0, 20)
	Status.Position = UDim2.new(0, 0, 0, 50)
	Status.BackgroundTransparency = 1
	Status.Text = "Initializing..."
	Status.TextColor3 = self.Theme.Muted
	Status.Font = Enum.Font.Gotham
	Status.TextSize = 12
	
	local BarBG = Instance.new("Frame", Main)
	BarBG.Size = UDim2.new(0.8, 0, 0, 8)
	BarBG.Position = UDim2.new(0.1, 0, 0, 85)
	BarBG.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	BarBG.BorderSizePixel = 0
	Instance.new("UICorner", BarBG).CornerRadius = UDim.new(0, 4)
	
	local Fill = Instance.new("Frame", BarBG)
	Fill.Size = UDim2.new(0, 0, 1, 0)
	Fill.BackgroundColor3 = self.Theme.Accent
	Fill.BorderSizePixel = 0
	Instance.new("UICorner", Fill).CornerRadius = UDim.new(0, 4)
	
	self.Loader = { Gui = LoaderGui, Fill = Fill, Status = Status }
	return self.Loader
end

function DarpaHub:UpdateLoader(value, statusText)
	if self.Loader then
		TweenService:Create(self.Loader.Fill, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
			Size = UDim2.new(math.clamp(value / 100, 0, 1), 0, 1, 0)
		}):Play()
		
		if statusText and self.Loader.Status then
			self.Loader.Status.Text = statusText
		end
	end
end

function DarpaHub:DestroyLoader()
	if self.Loader and self.Loader.Gui then
		self.Loader.Gui:Destroy()
		self.Loader = nil
	end
end

-- ──────────────────────────────────────────────────────────
--  WINDOW SYSTEM
-- ──────────────────────────────────────────────────────────
function DarpaHub:CreateWindow(title)
	local Screen = Instance.new("ScreenGui")
	Screen.Name = "DarpaHubUI"
	Screen.ResetOnSpawn = false
	Screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	Screen.Parent = Container
	
	local Main = Instance.new("Frame", Screen)
	Main.Name = "MainWindow"
	Main.Size = UDim2.new(0, 600, 0, 400)
	Main.Position = UDim2.new(0.5, -300, 0.5, -200)
	Main.AnchorPoint = Vector2.new(0.5, 0.5)
	Main.BackgroundColor3 = self.Theme.Background
	Main.BorderSizePixel = 0
	Main.ClipsDescendants = false
	
	Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 12)
	
	local Topbar = Instance.new("Frame", Main)
	Topbar.Name = "Topbar"
	Topbar.Size = UDim2.new(1, 0, 0, 35)
	Topbar.BackgroundColor3 = self.Theme.Panel
	Topbar.BorderSizePixel = 0
	Instance.new("UICorner", Topbar).CornerRadius = UDim.new(0, 12)
	
	local TopbarTitle = Instance.new("TextLabel", Topbar)
	TopbarTitle.Size = UDim2.new(1, -80, 1, 0)
	TopbarTitle.Position = UDim2.new(0, 15, 0, 0)
	TopbarTitle.BackgroundTransparency = 1
	TopbarTitle.Text = title or "DARPA HUB"
	TopbarTitle.TextColor3 = self.Theme.Glow
	TopbarTitle.Font = Enum.Font.GothamBold
	TopbarTitle.TextSize = 16
	TopbarTitle.TextXAlignment = Enum.TextXAlignment.Left
	
	local CloseBtn = Instance.new("TextButton", Topbar)
	CloseBtn.Size = UDim2.new(0, 30, 0, 30)
	CloseBtn.Position = UDim2.new(1, -35, 0.5, -15)
	CloseBtn.BackgroundColor3 = self.Theme.Red
	CloseBtn.BorderSizePixel = 0
	CloseBtn.Text = "X"
	CloseBtn.TextColor3 = self.Theme.Text
	CloseBtn.Font = Enum.Font.GothamBold
	CloseBtn.TextSize = 14
	Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)
	
	CloseBtn.MouseButton1Click:Connect(function()
		Screen:Destroy()
	end)
	
	local Sidebar = Instance.new("Frame", Main)
	Sidebar.Name = "Sidebar"
	Sidebar.Size = UDim2.new(0, 170, 1, -40)
	Sidebar.Position = UDim2.new(0, 0, 0, 35)
	Sidebar.BackgroundColor3 = self.Theme.Panel
	Sidebar.BorderSizePixel = 0
	
	local Container = Instance.new("Frame", Main)
	Container.Name = "Container"
	Container.Size = UDim2.new(1, -180, 1, -50)
	Container.Position = UDim2.new(0, 175, 0, 40)
	Container.BackgroundTransparency = 1
	Container.BorderSizePixel = 0
	
	local TabHolder = Instance.new("ScrollingFrame", Sidebar)
	TabHolder.Name = "TabHolder"
	TabHolder.Size = UDim2.new(1, -10, 1, -10)
	TabHolder.Position = UDim2.new(0, 5, 0, 5)
	TabHolder.BackgroundTransparency = 1
	TabHolder.BorderSizePixel = 0
	TabHolder.ScrollBarThickness = 4
	TabHolder.ScrollBarImageColor3 = self.Theme.Accent
	
	local TabLayout = Instance.new("UIListLayout", TabHolder)
	TabLayout.Padding = UDim.new(0, 6)
	TabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	
	-- Dragging
	local dragging, dragStart, startPos
	Topbar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true
			dragStart = input.Position
			startPos = Main.Position
		end
	end)
	
	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			local delta = input.Position - dragStart
			Main.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end
	end)
	
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end)
	
	-- WindowAPI
	local WindowAPI = {
		Screen = Screen,
		Tabs = {},
		CurrentTab = nil
	}
	
	function WindowAPI:AddTab(name)
		local TabBtn = Instance.new("TextButton", TabHolder)
		TabBtn.Name = name
		TabBtn.Size = UDim2.new(1, -4, 0, 38)
		TabBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
		TabBtn.BorderSizePixel = 0
		TabBtn.Text = name
		TabBtn.TextColor3 = DarpaHub.Theme.Muted
		TabBtn.Font = Enum.Font.GothamSemibold
		TabBtn.TextSize = 14
		Instance.new("UICorner", TabBtn).CornerRadius = UDim.new(0, 8)
		
		local Page = Instance.new("ScrollingFrame", Container)
		Page.Name = name .. "Page"
		Page.Size = UDim2.new(1, 0, 1, 0)
		Page.BackgroundTransparency = 1
		Page.BorderSizePixel = 0
		Page.ScrollBarThickness = 4
		Page.ScrollBarImageColor3 = DarpaHub.Theme.Accent
		Page.Visible = false
		
		local PageLayout = Instance.new("UIListLayout", Page)
		PageLayout.Padding = UDim.new(0, 10)
		PageLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		
		TabBtn.MouseButton1Click:Connect(function()
			-- Hide all pages
			for _, v in pairs(Container:GetChildren()) do
				if v:IsA("ScrollingFrame") then v.Visible = false end
			end
			
			-- Reset all tab colors
			for _, v in pairs(TabHolder:GetChildren()) do
				if v:IsA("TextButton") then
					TweenService:Create(v, TweenInfo.new(0.2), {
						TextColor3 = DarpaHub.Theme.Muted,
						BackgroundColor3 = Color3.fromRGB(30, 30, 40)
					}):Play()
				end
			end
			
			-- Show this page
			Page.Visible = true
			WindowAPI.CurrentTab = name
			
			-- Highlight this tab
			TweenService:Create(TabBtn, TweenInfo.new(0.2), {
				TextColor3 = DarpaHub.Theme.Glow,
				BackgroundColor3 = Color3.fromRGB(40, 40, 50)
			}):Play()
			
			Ripple(TabBtn)
		end)
		
		-- Select first tab by default
		if not WindowAPI.CurrentTab then
			task.defer(function()
				TabBtn.MouseButton1Click:Fire()
			end)
		end
		
		-- ElementsAPI
		local ElementsAPI = { Page = Page }
		
		function ElementsAPI:AddToggle(text, default, callback)
			callback = callback or function() end
			
			local ToggleFrame = Instance.new("TextButton", self.Page)
			ToggleFrame.Name = text
			ToggleFrame.Size = UDim2.new(0.96, 0, 0, 48)
			ToggleFrame.BackgroundColor3 = DarpaHub.Theme.Panel
			ToggleFrame.BorderSizePixel = 0
			ToggleFrame.AutoButtonColor = false
			ToggleFrame.Text = ""
			Instance.new("UICorner", ToggleFrame).CornerRadius = UDim.new(0, 8)
			
			local Label = Instance.new("TextLabel", ToggleFrame)
			Label.Size = UDim2.new(1, -60, 1, 0)
			Label.Position = UDim2.new(0, 12, 0, 0)
			Label.BackgroundTransparency = 1
			Label.Text = text
			Label.TextColor3 = DarpaHub.Theme.Text
			Label.TextXAlignment = Enum.TextXAlignment.Left
			Label.Font = Enum.Font.Gotham
			Label.TextSize = 14
			
			local ToggleBox = Instance.new("Frame", ToggleFrame)
			ToggleBox.Size = UDim2.new(0, 40, 0, 20)
			ToggleBox.Position = UDim2.new(1, -50, 0.5, -10)
			ToggleBox.BackgroundColor3 = default and DarpaHub.Theme.Accent or Color3.fromRGB(50, 50, 60)
			ToggleBox.BorderSizePixel = 0
			Instance.new("UICorner", ToggleBox).CornerRadius = UDim.new(1, 0)
			
			local ToggleCircle = Instance.new("Frame", ToggleBox)
			ToggleCircle.Size = UDim2.new(0, 16, 0, 16)
			ToggleCircle.Position = default and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
			ToggleCircle.BackgroundColor3 = Color3.new(1, 1, 1)
			ToggleCircle.BorderSizePixel = 0
			Instance.new("UICorner", ToggleCircle).CornerRadius = UDim.new(1, 0)
			
			local state = default
			ToggleFrame.MouseButton1Click:Connect(function()
				state = not state
				
				TweenService:Create(ToggleBox, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
					BackgroundColor3 = state and DarpaHub.Theme.Accent or Color3.fromRGB(50, 50, 60)
				}):Play()
				
				TweenService:Create(ToggleCircle, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
					Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
				}):Play()
				
				Ripple(ToggleFrame)
				pcall(callback, state)
			end)
			
			return {
				Set = function(val)
					if val ~= state then
						ToggleFrame.MouseButton1Click:Fire()
					end
				end,
				Get = function() return state end
			}
		end
		
		function ElementsAPI:AddSlider(text, min, max, default, callback)
			callback = callback or function() end
			default = math.clamp(default or min, min, max)
			
			local SliderFrame = Instance.new("Frame", self.Page)
			SliderFrame.Name = text
			SliderFrame.Size = UDim2.new(0.96, 0, 0, 68)
			SliderFrame.BackgroundColor3 = DarpaHub.Theme.Panel
			SliderFrame.BorderSizePixel = 0
			Instance.new("UICorner", SliderFrame).CornerRadius = UDim.new(0, 8)
			
			local Label = Instance.new("TextLabel", SliderFrame)
			Label.Size = UDim2.new(1, -60, 0, 30)
			Label.Position = UDim2.new(0, 12, 0, 5)
			Label.BackgroundTransparency = 1
			Label.Text = text
			Label.TextColor3 = DarpaHub.Theme.Text
			Label.TextXAlignment = Enum.TextXAlignment.Left
			Label.Font = Enum.Font.Gotham
			Label.TextSize = 14
			
			local ValueLabel = Instance.new("TextLabel", SliderFrame)
			ValueLabel.Size = UDim2.new(0, 50, 0, 30)
			ValueLabel.Position = UDim2.new(1, -55, 0, 5)
			ValueLabel.BackgroundTransparency = 1
			ValueLabel.Text = tostring(default)
			ValueLabel.TextColor3 = DarpaHub.Theme.Accent
			ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
			ValueLabel.Font = Enum.Font.GothamBold
			ValueLabel.TextSize = 14
			
			local SliderBar = Instance.new("Frame", SliderFrame)
			SliderBar.Size = UDim2.new(0.92, 0, 0, 6)
			SliderBar.Position = UDim2.new(0.04, 0, 0, 45)
			SliderBar.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
			SliderBar.BorderSizePixel = 0
			Instance.new("UICorner", SliderBar).CornerRadius = UDim.new(1, 0)
			
			local SliderFill = Instance.new("Frame", SliderBar)
			SliderFill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
			SliderFill.BackgroundColor3 = DarpaHub.Theme.Accent
			SliderFill.BorderSizePixel = 0
			Instance.new("UICorner", SliderFill).CornerRadius = UDim.new(1, 0)
			
			local SliderButton = Instance.new("TextButton", SliderBar)
			SliderButton.Size = UDim2.new(1, 0, 1, 0)
			SliderButton.BackgroundTransparency = 1
			SliderButton.Text = ""
			
			local currentValue = default
			
			local function UpdateSlider()
				local mousePos = UserInputService:GetMouseLocation()
				local barPos = SliderBar.AbsolutePosition
				local barSize = SliderBar.AbsoluteSize
				
				local relativeX = math.clamp((mousePos.X - barPos.X) / barSize.X, 0, 1)
				currentValue = math.floor(min + (max - min) * relativeX)
				
				ValueLabel.Text = tostring(currentValue)
				SliderFill.Size = UDim2.new(relativeX, 0, 1, 0)
				
				pcall(callback, currentValue)
			end
			
			local dragging = false
			
			SliderButton.MouseButton1Down:Connect(function()
				dragging = true
				UpdateSlider()
			end)
			
			UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					dragging = false
				end
			end)
			
			UserInputService.InputChanged:Connect(function(input)
				if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
					UpdateSlider()
				end
			end)
			
			-- Initial callback
			task.defer(callback, currentValue)
			
			return {
				Set = function(val)
					currentValue = math.clamp(val, min, max)
					ValueLabel.Text = tostring(currentValue)
					SliderFill.Size = UDim2.new((currentValue - min) / (max - min), 0, 1, 0)
				end,
				Get = function() return currentValue end
			}
		end
		
		function ElementsAPI:AddButton(text, callback)
			callback = callback or function() end
			
			local Button = Instance.new("TextButton", self.Page)
			Button.Name = text
			Button.Size = UDim2.new(0.96, 0, 0, 42)
			Button.BackgroundColor3 = DarpaHub.Theme.Panel
			Button.BorderSizePixel = 0
			Button.Text = text
			Button.TextColor3 = DarpaHub.Theme.Text
			Button.Font = Enum.Font.GothamBold
			Button.TextSize = 14
			Button.AutoButtonColor = false
			Instance.new("UICorner", Button).CornerRadius = UDim.new(0, 8)
			
			local Stroke = Instance.new("UIStroke", Button)
			Stroke.Color = DarpaHub.Theme.Accent
			Stroke.Thickness = 1
			Stroke.Transparency = 0.7
			Stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
			
			Button.MouseButton1Click:Connect(function()
				Ripple(Button)
				TweenService:Create(Stroke, TweenInfo.new(0.15), { Transparency = 0.3 }):Play()
				task.wait(0.15)
				TweenService:Create(Stroke, TweenInfo.new(0.15), { Transparency = 0.7 }):Play()
				pcall(callback)
			end)
		end
		
		function ElementsAPI:AddLabel(text)
			local Label = Instance.new("TextLabel", self.Page)
			Label.Name = text
			Label.Size = UDim2.new(0.96, 0, 0, 32)
			Label.BackgroundTransparency = 1
			Label.Text = text
			Label.TextColor3 = DarpaHub.Theme.Muted
			Label.Font = Enum.Font.Gotham
			Label.TextSize = 13
			Label.TextXAlignment = Enum.TextXAlignment.Left
			Label.TextWrapped = true
			
			return {
				Set = function(newText)
					Label.Text = newText
				end
			}
		end
		
		function ElementsAPI:AddDropdown(text, options, default, callback)
			callback = callback or function() end
			options = options or {}
			default = default or (options[1] or "None")
			
			local DropdownFrame = Instance.new("Frame", self.Page)
			DropdownFrame.Name = text
			DropdownFrame.Size = UDim2.new(0.96, 0, 0, 48)
			DropdownFrame.BackgroundColor3 = DarpaHub.Theme.Panel
			DropdownFrame.BorderSizePixel = 0
			Instance.new("UICorner", DropdownFrame).CornerRadius = UDim.new(0, 8)
			
			local Label = Instance.new("TextLabel", DropdownFrame)
			Label.Size = UDim2.new(1, -120, 1, 0)
			Label.Position = UDim2.new(0, 12, 0, 0)
			Label.BackgroundTransparency = 1
			Label.Text = text
			Label.TextColor3 = DarpaHub.Theme.Text
			Label.TextXAlignment = Enum.TextXAlignment.Left
			Label.Font = Enum.Font.Gotham
			Label.TextSize = 14
			
			local SelectedButton = Instance.new("TextButton", DropdownFrame)
			SelectedButton.Size = UDim2.new(0, 110, 0, 32)
			SelectedButton.Position = UDim2.new(1, -118, 0.5, -16)
			SelectedButton.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
			SelectedButton.BorderSizePixel = 0
			SelectedButton.Text = default
			SelectedButton.TextColor3 = DarpaHub.Theme.Accent
			SelectedButton.Font = Enum.Font.Gotham
			SelectedButton.TextSize = 12
			SelectedButton.AutoButtonColor = false
			Instance.new("UICorner", SelectedButton).CornerRadius = UDim.new(0, 6)
			
			local DropdownList = Instance.new("Frame", DropdownFrame)
			DropdownList.Size = UDim2.new(0, 110, 0, 0)  -- starts collapsed
			DropdownList.Position = UDim2.new(1, -118, 1, 4)
			DropdownList.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
			DropdownList.BorderSizePixel = 0
			DropdownList.ClipsDescendants = true
			DropdownList.Visible = false
			DropdownList.ZIndex = 200
			Instance.new("UICorner", DropdownList).CornerRadius = UDim.new(0, 6)
			
			local ListLayout = Instance.new("UIListLayout", DropdownList)
			ListLayout.Padding = UDim.new(0, 2)
			
			local currentValue = default
			local expanded = false
			
			for _, option in ipairs(options) do
				local OptionButton = Instance.new("TextButton", DropdownList)
				OptionButton.Size = UDim2.new(1, 0, 0, 28)
				OptionButton.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
				OptionButton.BorderSizePixel = 0
				OptionButton.Text = option
				OptionButton.TextColor3 = DarpaHub.Theme.Text
				OptionButton.Font = Enum.Font.Gotham
				OptionButton.TextSize = 12
				OptionButton.AutoButtonColor = false
				
				OptionButton.MouseButton1Click:Connect(function()
					currentValue = option
					SelectedButton.Text = option
					
					-- Collapse dropdown
					expanded = false
					DropdownList.Visible = false
					TweenService:Create(DropdownList, TweenInfo.new(0.2), {
						Size = UDim2.new(0, 110, 0, 0)
					}):Play()
					
					pcall(callback, option)
				end)
			end
			
			SelectedButton.MouseButton1Click:Connect(function()
				expanded = not expanded
				DropdownList.Visible = expanded
				
				if expanded then
					local totalHeight = #options * 30
					TweenService:Create(DropdownList, TweenInfo.new(0.2), {
						Size = UDim2.new(0, 110, 0, math.min(totalHeight, 150))
					}):Play()
				else
					TweenService:Create(DropdownList, TweenInfo.new(0.2), {
						Size = UDim2.new(0, 110, 0, 0)
					}):Play()
					task.wait(0.2)
					DropdownList.Visible = false
				end
			end)
			
			-- Initial callback
			task.defer(callback, currentValue)
			
			return {
				Set = function(val)
					currentValue = val
					SelectedButton.Text = val
				end,
				Get = function() return currentValue end
			}
		end
		
		WindowAPI.Tabs[name] = ElementsAPI
		return ElementsAPI
	end
	
	function WindowAPI:Destroy()
		if self.Screen then
			self.Screen:Destroy()
		end
	end
	
	return WindowAPI
end

-- ──────────────────────────────────────────────────────────
--  RETURN LIBRARY
-- ──────────────────────────────────────────────────────────
return DarpaHub
