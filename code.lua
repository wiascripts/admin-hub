===========================================================================--
--                         VIA ADMIN HUB v8.0                                 --
--              FULL CLIENT-SIDE ADMIN / DEBUG TOOLKIT                        --
--============================================================================--
-- Для собственного / тестового Roblox place.
-- Обычный LocalScript: без getgenv, hookmetamethod, Drawing и executor API.
--============================================================================--

local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local UIS                = game:GetService("UserInputService")
local TweenService       = game:GetService("TweenService")
local Lighting           = game:GetService("Lighting")
local Workspace          = game:GetService("Workspace")
local Stats              = game:GetService("Stats")
local GuiService         = game:GetService("GuiService")
local ContextAction      = game:GetService("ContextActionService")

local LP = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local PlayerGui = LP:WaitForChild("PlayerGui")

--============================================================================--
-- CLEAN OLD GUI
--============================================================================--

local old = PlayerGui:FindFirstChild("VIA_ADMIN_HUB")
if old then
	old:Destroy()
end

--============================================================================--
-- STATE
--============================================================================--

local State = {
	Speed = 16,
	Jump = 50,
	FlySpeed = 60,

	Fly = false,
	Noclip = false,
	NoGravity = false,
	Glide = false,
	InfiniteJump = false,
	DoubleJump = false,
	TripleJump = false,
	WallJump = false,
	WallWalk = false,
	AirControl = false,
	Sprint = false,
	Freeze = false,
	AntiRagdoll = false,
	AntiSit = false,
	AntiVoid = false,
	LocalInvisible = false,

	DashPower = 100,

	ESPName = false,
	ESPDistance = false,
	ESPHealth = false,
	ESPBox = false,
	ESPTracer = false,
	ESPHighlight = false,
	ESPSkeleton = false,
	ESPTeamCheck = false,
	ESPObjects = false,
	ESPMaxDistance = 1000,

	FOV = 70,
	Zoom = 12,
	CameraSensitivity = 1,
	CameraOffset = Vector3.zero,

	Freecam = false,
	Spectate = false,
	Orbit = false,
	OrbitRadius = 8,
	OrbitSpeed = 1,
	SmoothCamera = false,
	CameraShake = false,
	ShakeIntensity = 1,
	CinematicCamera = false,
	FirstPerson = false,
	ThirdPerson = false,

	AimAssist = false,
	TargetLock = false,
	AimFOV = 150,
	AimSmooth = 0.18,
	AimDistance = 1000,
	AimTeamCheck = true,
	AimVisibility = true,
	AimPriority = "Distance",

	Fullbright = false,
	NightVision = false,
	Grayscale = false,
	CinematicVisual = false,

	Brightness = 2,
	Exposure = 0,
	Contrast = 0,
	Saturation = 0,

	Bloom = false,
	BloomIntensity = 1,
	Blur = false,
	BlurSize = 5,
	DOF = false,
	SunRays = false,
	Atmosphere = false,

	Fog = false,
	FogStart = 0,
	FogEnd = 1000,
	FogHaze = 0,

	Vignette = false,
	FilmGrain = false,
	Scanlines = false,
	Crosshair = false,
	Hitmarker = false,

	UIScale = 1,
	TouchSize = 1,
	Compact = false,

	Search = "",
	SelectedPlayer = nil,
	SavedPosition = nil,
	LastSafePosition = nil,
}

local Connections = {}
local Waypoints = {}
local ESPObjects = {}
local MobileControls = {}

local Character
local Humanoid
local Root

local function CharacterUpdate()
	Character = LP.Character
	if not Character then return end

	Humanoid = Character:FindFirstChildOfClass("Humanoid")
	Root = Character:FindFirstChild("HumanoidRootPart")
end

CharacterUpdate()

LP.CharacterAdded:Connect(function()
	task.wait(0.5)
	CharacterUpdate()

	if Humanoid then
		Humanoid.WalkSpeed = State.Speed
		Humanoid.JumpPower = State.Jump
	end
end)

--============================================================================--
-- UTILS
--============================================================================--

local function Tween(obj, time, props)
	local t = TweenService:Create(
		obj,
		TweenInfo.new(time or .2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
		props
	)
	t:Play()
	return t
end

local function GetRoot()
	if not Character or not Character.Parent then
		CharacterUpdate()
	end

	if Character then
		Root = Character:FindFirstChild("HumanoidRootPart")
	end

	return Root
end

local function GetHumanoid()
	if not Character or not Character.Parent then
		CharacterUpdate()
	end

	if Character then
		Humanoid = Character:FindFirstChildOfClass("Humanoid")
	end

	return Humanoid
end

local function SafeCall(fn, ...)
	local ok, result = pcall(fn, ...)
	return ok, result
end

local function GetPlayerRoot(player)
	if not player or not player.Character then
		return nil
	end

	return player.Character:FindFirstChild("HumanoidRootPart")
end

local function GetPlayerHumanoid(player)
	if not player or not player.Character then
		return nil
	end

	return player.Character:FindFirstChildOfClass("Humanoid")
end

local function DistanceFromLocal(player)
	local a = GetRoot()
	local b = GetPlayerRoot(player)

	if not a or not b then
		return math.huge
	end

	return (a.Position - b.Position).Magnitude
end

local function IsAlive(player)
	local hum = GetPlayerHumanoid(player)
	local root = GetPlayerRoot(player)

	return hum and hum.Health > 0 and root
end

--============================================================================--
-- GUI BASE
--============================================================================--

local GUI = Instance.new("ScreenGui")
GUI.Name = "VIA_ADMIN_HUB"
GUI.ResetOnSpawn = false
GUI.IgnoreGuiInset = true
GUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
GUI.Parent = PlayerGui

local UIScale = Instance.new("UIScale")
UIScale.Scale = State.UIScale
UIScale.Parent = GUI

--============================================================================--
-- NOTIFICATIONS
--============================================================================--

local NotificationHolder = Instance.new("Frame")
NotificationHolder.Name = "Notifications"
NotificationHolder.AnchorPoint = Vector2.new(1,1)
NotificationHolder.Position = UDim2.new(1,-15,1,-15)
NotificationHolder.Size = UDim2.new(0,300,0,300)
NotificationHolder.BackgroundTransparency = 1
NotificationHolder.Parent = GUI

local NotificationLayout = Instance.new("UIListLayout")
NotificationLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
NotificationLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
NotificationLayout.Padding = UDim.new(0,6)
NotificationLayout.Parent = NotificationHolder

local function Notify(title, message, duration)
	duration = duration or 3

	local f = Instance.new("Frame")
	f.Size = UDim2.new(1,0,0,58)
	f.BackgroundColor3 = Color3.fromRGB(20,20,27)
	f.BackgroundTransparency = 1
	f.BorderSizePixel = 0
	f.Parent = NotificationHolder

	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0,8)
	c.Parent = f

	local s = Instance.new("UIStroke")
	s.Color = Color3.fromRGB(60,70,85)
	s.Parent = f

	local t = Instance.new("TextLabel")
	t.Position = UDim2.new(0,10,0,5)
	t.Size = UDim2.new(1,-20,0,20)
	t.BackgroundTransparency = 1
	t.Text = title
	t.TextColor3 = Color3.fromRGB(100,210,255)
	t.TextSize = 14
	t.Font = Enum.Font.GothamBold
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.Parent = f

	local m = Instance.new("TextLabel")
	m.Position = UDim2.new(0,10,0,25)
	m.Size = UDim2.new(1,-20,0,27)
	m.BackgroundTransparency = 1
	m.Text = message
	m.TextColor3 = Color3.fromRGB(220,220,225)
	m.TextSize = 12
	m.Font = Enum.Font.Gotham
	m.TextWrapped = true
	m.TextXAlignment = Enum.TextXAlignment.Left
	m.Parent = f

	Tween(f,.2,{BackgroundTransparency=.08})

	task.delay(duration,function()
		if f and f.Parent then
			local tw = Tween(f,.25,{BackgroundTransparency=1})
			tw.Completed:Connect(function()
				if f then
					f:Destroy()
				end
			end)
		end
	end)
end

--============================================================================--
-- MAIN WINDOW
--============================================================================--

local Main = Instance.new("Frame")
Main.Name = "Main"
Main.AnchorPoint = Vector2.new(.5,.5)
Main.Position = UDim2.fromScale(.5,.5)
Main.Size = UDim2.new(0,720,0,470)
Main.BackgroundColor3 = Color3.fromRGB(16,17,21)
Main.BorderSizePixel = 0
Main.ClipsDescendants = true
Main.Parent = GUI

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0,12)
MainCorner.Parent = Main

local MainStroke = Instance.new("UIStroke")
MainStroke.Color = Color3.fromRGB(55,60,72)
MainStroke.Thickness = 1
MainStroke.Parent = Main

--============================================================================--
-- HEADER
--============================================================================--

local Header = Instance.new("Frame")
Header.Size = UDim2.new(1,0,0,44)
Header.BackgroundColor3 = Color3.fromRGB(12,13,17)
Header.BorderSizePixel = 0
Header.Parent = Main

local Title = Instance.new("TextLabel")
Title.Position = UDim2.new(0,15,0,0)
Title.Size = UDim2.new(0,300,1,0)
Title.BackgroundTransparency = 1
Title.Text = "VIA ADMIN HUB"
Title.TextColor3 = Color3.fromRGB(120,215,255)
Title.TextSize = 19
Title.Font = Enum.Font.GothamBold
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = Header

local Status = Instance.new("TextLabel")
Status.Position = UDim2.new(0,165,0,0)
Status.Size = UDim2.new(0,220,1,0)
Status.BackgroundTransparency = 1
Status.Text = "CLIENT • DEBUG"
Status.TextColor3 = Color3.fromRGB(100,105,115)
Status.TextSize = 11
Status.Font = Enum.Font.Gotham
Status.TextXAlignment = Enum.TextXAlignment.Left
Status.Parent = Header

local Minimize = Instance.new("TextButton")
Minimize.AnchorPoint = Vector2.new(1,0)
Minimize.Position = UDim2.new(1,-70,0,5)
Minimize.Size = UDim2.new(0,32,0,32)
Minimize.Text = "—"
Minimize.TextSize = 18
Minimize.Font = Enum.Font.GothamBold
Minimize.TextColor3 = Color3.fromRGB(220,220,220)
Minimize.BackgroundTransparency = 1
Minimize.Parent = Header

local Close = Instance.new("TextButton")
Close.AnchorPoint = Vector2.new(1,0)
Close.Position = UDim2.new(1,-8,0,5)
Close.Size = UDim2.new(0,32,0,32)
Close.Text = "×"
Close.TextSize = 21
Close.Font = Enum.Font.GothamBold
Close.TextColor3 = Color3.fromRGB(255,100,100)
Close.BackgroundTransparency = 1
Close.Parent = Header

--============================================================================--
-- FLOATING BUTTON
--============================================================================--

local Floating = Instance.new("TextButton")
Floating.Name = "FloatingButton"
Floating.AnchorPoint = Vector2.new(0,0)
Floating.Position = UDim2.new(0,20,.5,-30)
Floating.Size = UDim2.new(0,60,0,60)
Floating.BackgroundColor3 = Color3.fromRGB(18,20,25)
Floating.Text = "VIA"
Floating.TextColor3 = Color3.fromRGB(110,215,255)
Floating.TextSize = 16
Floating.Font = Enum.Font.GothamBold
Floating.Visible = false
Floating.Parent = GUI

local FloatingCorner = Instance.new("UICorner")
FloatingCorner.CornerRadius = UDim.new(1,0)
FloatingCorner.Parent = Floating

local FloatingStroke = Instance.new("UIStroke")
FloatingStroke.Color = Color3.fromRGB(70,160,200)
FloatingStroke.Thickness = 2
FloatingStroke.Parent = Floating

--============================================================================--
-- DRAGGING
--============================================================================--

local function MakeDraggable(object, handle)
	handle = handle or object

	local dragging = false
	local dragStart
	local startPos
	local dragInput

	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then

			dragging = true
			dragStart = input.Position
			startPos = object.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	handle.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)

	UIS.InputChanged:Connect(function(input)
		if dragging and input == dragInput then
			local delta = input.Position - dragStart

			object.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end
	end)
end

MakeDraggable(Main,Header)
MakeDraggable(Floating,Floating)

--============================================================================--
-- NAVIGATION
--============================================================================--

local Sidebar = Instance.new("Frame")
Sidebar.Position = UDim2.new(0,10,0,54)
Sidebar.Size = UDim2.new(0,145,1,-64)
Sidebar.BackgroundTransparency = 1
Sidebar.Parent = Main

local Search = Instance.new("TextBox")
Search.Size = UDim2.new(1,0,0,32)
Search.BackgroundColor3 = Color3.fromRGB(25,27,33)
Search.BorderSizePixel = 0
Search.PlaceholderText = "Search functions..."
Search.PlaceholderColor3 = Color3.fromRGB(110,115,125)
Search.TextColor3 = Color3.fromRGB(235,235,240)
Search.TextSize = 12
Search.Font = Enum.Font.Gotham
Search.ClearTextOnFocus = false
Search.Parent = Sidebar

local SearchCorner = Instance.new("UICorner")
SearchCorner.CornerRadius = UDim.new(0,7)
SearchCorner.Parent = Search

local TabsFrame = Instance.new("ScrollingFrame")
TabsFrame.Position = UDim2.new(0,0,0,40)
TabsFrame.Size = UDim2.new(1,0,1,-40)
TabsFrame.BackgroundTransparency = 1
TabsFrame.BorderSizePixel = 0
TabsFrame.ScrollBarThickness = 3
TabsFrame.CanvasSize = UDim2.new()
TabsFrame.Parent = Sidebar

local TabLayout = Instance.new("UIListLayout")
TabLayout.Padding = UDim.new(0,5)
TabLayout.Parent = TabsFrame

TabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	TabsFrame.CanvasSize = UDim2.new(0,0,0,TabLayout.AbsoluteContentSize.Y+10)
end)

local Content = Instance.new("Frame")
Content.Position = UDim2.new(0,165,0,54)
Content.Size = UDim2.new(1,-175,1,-64)
Content.BackgroundTransparency = 1
Content.Parent = Main

local Pages = {}
local TabButtons = {}
local CurrentPage

local function CreatePage(name)
	local page = Instance.new("ScrollingFrame")
	page.Name = name
	page.Size = UDim2.fromScale(1,1)
	page.BackgroundTransparency = 1
	page.BorderSizePixel = 0
	page.ScrollBarThickness = 4
	page.Visible = false
	page.CanvasSize = UDim2.new()
	page.Parent = Content

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0,7)
	layout.Parent = page

	local pad = Instance.new("UIPadding")
	pad.PaddingRight = UDim.new(0,8)
	pad.PaddingBottom = UDim.new(0,10)
	pad.Parent = page

	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
		page.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y+15)
	end)

	Pages[name] = page

	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1,0,0,34)
	button.BackgroundColor3 = Color3.fromRGB(25,27,33)
	button.BorderSizePixel = 0
	button.Text = name
	button.TextColor3 = Color3.fromRGB(175,180,190)
	button.TextSize = 12
	button.Font = Enum.Font.GothamBold
	button.Parent = TabsFrame

	Corner(button,7)

	TabButtons[name] = button

	button.MouseButton1Click:Connect(function()
		for n,p in pairs(Pages) do
			p.Visible = false
			TabButtons[n].BackgroundColor3 = Color3.fromRGB(25,27,33)
			TabButtons[n].TextColor3 = Color3.fromRGB(175,180,190)
		end

		page.Visible = true
		button.BackgroundColor3 = Color3.fromRGB(35,45,55)
		button.TextColor3 = Color3.fromRGB(110,215,255)
		CurrentPage = name
	end)

	if not CurrentPage then
		CurrentPage = name
		page.Visible = true
		button.BackgroundColor3 = Color3.fromRGB(35,45,55)
		button.TextColor3 = Color3.fromRGB(110,215,255)
	end

	return page
end

--============================================================================--
-- UI COMPONENTS
--============================================================================--

local Controls = {}

local function RegisterControl(frame, searchText)
	table.insert(Controls,{
		Object = frame,
		Text = string.lower(searchText or "")
	})
end

local function AddSection(page,text)
	local l = Instance.new("TextLabel")
	l.Size = UDim2.new(1,-5,0,25)
	l.BackgroundTransparency = 1
	l.Text = string.upper(text)
	l.TextColor3 = Color3.fromRGB(90,190,230)
	l.TextSize = 12
	l.Font = Enum.Font.GothamBold
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.Parent = page
	RegisterControl(l,text)
	return l
end

local function AddButton(page,text,callback)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(1,-5,0,35)
	b.BackgroundColor3 = Color3.fromRGB(27,29,36)
	b.BorderSizePixel = 0
	b.Text = text
	b.TextColor3 = Color3.fromRGB(225,225,230)
	b.TextSize = 12
	b.Font = Enum.Font.Gotham
	b.AutoButtonColor = false
	b.Parent = page

	Corner(b,7)

	b.MouseEnter:Connect(function()
		Tween(b,.1,{BackgroundColor3=Color3.fromRGB(35,39,48)})
	end)

	b.MouseLeave:Connect(function()
		Tween(b,.1,{BackgroundColor3=Color3.fromRGB(27,29,36)})
	end)

	b.Activated:Connect(function()
		SafeCall(callback)
	end)

	RegisterControl(b,text)
	return b
end

local function AddToggle(page,text,default,callback)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1,-5,0,36)
	frame.BackgroundColor3 = Color3.fromRGB(27,29,36)
	frame.BorderSizePixel = 0
	frame.Parent = page

	Corner(frame,7)

	local label = Instance.new("TextLabel")
	label.Position = UDim2.new(0,10,0,0)
	label.Size = UDim2.new(1,-65,1,0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.fromRGB(225,225,230)
	label.TextSize = 12
	label.Font = Enum.Font.Gotham
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = frame

	local button = Instance.new("TextButton")
	button.AnchorPoint = Vector2.new(1,.5)
	button.Position = UDim2.new(1,-8,.5,0)
	button.Size = UDim2.new(0,45,0,23)
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBold
	button.TextSize = 10
	button.Parent = frame

	Corner(button,6)

	local value = default

	local function Render()
		button.Text = value and "ON" or "OFF"
		button.BackgroundColor3 =
			value
			and Color3.fromRGB(35,165,110)
			or Color3.fromRGB(65,68,76)
	end

	Render()

	button.Activated:Connect(function()
		value = not value
		Render()
		SafeCall(callback,value)
	end)

	RegisterControl(frame,text)

	return frame,function(v)
		value=v
		Render()
	end
end

local function AddSlider(page,text,min,max,default,callback,decimals)
	decimals = decimals or 0

	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1,-5,0,48)
	frame.BackgroundColor3 = Color3.fromRGB(27,29,36)
	frame.BorderSizePixel = 0
	frame.Parent = page

	Corner(frame,7)

	local label = Instance.new("TextLabel")
	label.Position = UDim2.new(0,10,0,3)
	label.Size = UDim2.new(1,-20,0,18)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(225,225,230)
	label.TextSize = 11
	label.Font = Enum.Font.Gotham
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = frame

	local bar = Instance.new("TextButton")
	bar.Position = UDim2.new(0,10,0,28)
	bar.Size = UDim2.new(1,-20,0,9)
	bar.BackgroundColor3 = Color3.fromRGB(45,48,57)
	bar.BorderSizePixel = 0
	bar.Text = ""
	bar.AutoButtonColor = false
	bar.Parent = frame

	Corner(bar,5)

	local fill = Instance.new("Frame")
	fill.Size = UDim2.new(0,0,1,0)
	fill.BackgroundColor3 = Color3.fromRGB(90,190,235)
	fill.BorderSizePixel = 0
	fill.Parent = bar

	Corner(fill,5)

	local value = default
	local dragging = false

	local function Format(v)
		if decimals == 0 then
			return tostring(math.floor(v+.5))
		end

		return string.format("%."..decimals.."f",v)
	end

	local function SetValue(v)
		value = math.clamp(v,min,max)

		local alpha = (value-min)/(max-min)

		fill.Size = UDim2.new(alpha,0,1,0)
		label.Text = text..": "..Format(value)

		SafeCall(callback,value)
	end

	local function FromInput(input)
		local x = math.clamp(
			(input.Position.X-bar.AbsolutePosition.X)/bar.AbsoluteSize.X,
			0,1
		)

		SetValue(min+(max-min)*x)
	end

	SetValue(default)

	bar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging=true
			FromInput(input)
		end
	end)

	UIS.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging=false
		end
	end)

	UIS.InputChanged:Connect(function(input)
		if dragging and (
			input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch
		) then
			FromInput(input)
		end
	end)

	RegisterControl(frame,text)

	return frame
end

local function AddTextBox(page,text,default,callback)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.new(1,-5,0,40)
	frame.BackgroundColor3 = Color3.fromRGB(27,29,36)
	frame.BorderSizePixel = 0
	frame.Parent = page

	Corner(frame,7)

	local label = Instance.new("TextLabel")
	label.Position = UDim2.new(0,10,0,0)
	label.Size = UDim2.new(.45,0,1,0)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.fromRGB(225,225,230)
	label.TextSize = 11
	label.Font = Enum.Font.Gotham
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = frame

	local box = Instance.new("TextBox")
	box.AnchorPoint = Vector2.new(1,.5)
	box.Position = UDim2.new(1,-8,.5,0)
	box.Size = UDim2.new(.48,0,0,26)
	box.BackgroundColor3 = Color3.fromRGB(20,22,27)
	box.BorderSizePixel = 0
	box.Text = tostring(default or "")
	box.TextColor3 = Color3.fromRGB(235,235,240)
	box.TextSize = 11
	box.Font = Enum.Font.Gotham
	box.ClearTextOnFocus = false
	box.Parent = frame

	Corner(box,6)

	box.FocusLost:Connect(function()
		SafeCall(callback,box.Text)
	end)

	RegisterControl(frame,text)

	return box
end

--============================================================================--
-- PAGES
--============================================================================--

local PlayerPage   = CreatePage("PLAYER")
local PlayersPage  = CreatePage("PLAYERS")
local TeleportPage = CreatePage("TELEPORT")
local ESPPage      = CreatePage("ESP")
local CameraPage   = CreatePage("CAMERA")
local VisualPage   = CreatePage("VISUALS")
local TargetPage   = CreatePage("TARGETING")
local DebugPage    = CreatePage("DEBUG")
local DevicePage   = CreatePage("DEVICE")
local SettingsPage = CreatePage("SETTINGS")

--============================================================================--
-- PLAYER
--============================================================================--

AddSection(PlayerPage,"Movement")

AddSlider(PlayerPage,"Speed",0,250,State.Speed,function(v)
	State.Speed=v
	local h=GetHumanoid()
	if h then h.WalkSpeed=v end
end)

AddSlider(PlayerPage,"Jump Power",0,300,State.Jump,function(v)
	State.Jump=v
	local h=GetHumanoid()
	if h then h.JumpPower=v end
end)

AddToggle(PlayerPage,"Infinite Jump",false,function(v)
	State.InfiniteJump=v
end)

AddToggle(PlayerPage,"Double Jump",false,function(v)
	State.DoubleJump=v
end)

AddToggle(PlayerPage,"Triple Jump",false,function(v)
	State.TripleJump=v
end)

AddToggle(PlayerPage,"Fly",false,function(v)
	State.Fly=v
end)

AddSlider(PlayerPage,"Fly Speed",10,300,State.FlySpeed,function(v)
	State.FlySpeed=v
end)

AddToggle(PlayerPage,"Noclip",false,function(v)
	State.Noclip=v
end)

AddToggle(PlayerPage,"No Gravity",false,function(v)
	State.NoGravity=v
end)

AddToggle(PlayerPage,"Glide",false,function(v)
	State.Glide=v
end)

AddSlider(PlayerPage,"Dash Power",25,300,State.DashPower,function(v)
	State.DashPower=v
end)

AddButton(PlayerPage,"DASH",function()
	local r=GetRoot()
	if r then
		r.AssemblyLinearVelocity =
			Camera.CFrame.LookVector*State.DashPower
	end
end)

AddToggle(PlayerPage,"Wall Jump",false,function(v)
	State.WallJump=v
end)

AddToggle(PlayerPage,"Wall Walk",false,function(v)
	State.WallWalk=v
end)

AddToggle(PlayerPage,"Air Control",false,function(v)
	State.AirControl=v
end)

AddToggle(PlayerPage,"Sprint",false,function(v)
	State.Sprint=v
end)

AddToggle(PlayerPage,"Freeze",false,function(v)
	State.Freeze=v
end)

AddToggle(PlayerPage,"Anti Ragdoll",false,function(v)
	State.AntiRagdoll=v
end)

AddToggle(PlayerPage,"Anti Sit",false,function(v)
	State.AntiSit=v
end)

AddToggle(PlayerPage,"Anti Void",false,function(v)
	State.AntiVoid=v
end)

AddToggle(PlayerPage,"Local Invisibility",false,function(v)
	State.LocalInvisible=v

	if Character then
		for _,obj in ipairs(Character:GetDescendants()) do
			if obj:IsA("BasePart") then
				obj.LocalTransparencyModifier=v and 1 or 0
			end
		end
	end
end)

--============================================================================--
-- PLAYER INPUT
--============================================================================--

UIS.JumpRequest:Connect(function()
	local h=GetHumanoid()

	if not h then return end

	if State.InfiniteJump then
		h:ChangeState(Enum.HumanoidStateType.Jumping)
	end
end)

UIS.InputBegan:Connect(function(input,gp)
	if gp then return end

	if input.KeyCode==Enum.KeyCode.LeftShift then
		if State.Sprint then
			local h=GetHumanoid()
			if h then
				h.WalkSpeed=State.Speed*1.75
			end
		end
	end

	if input.KeyCode==Enum.KeyCode.Q then
		local r=GetRoot()
		if r then
			r.AssemblyLinearVelocity=Camera.CFrame.LookVector*State.DashPower
		end
	end
end)

UIS.InputEnded:Connect(function(input)
	if input.KeyCode==Enum.KeyCode.LeftShift then
		local h=GetHumanoid()
		if h then
			h.WalkSpeed=State.Speed
		end
	end
end)

--============================================================================--
-- PLAYER PHYSICS LOOP
--============================================================================--

local FlyVelocity
local FlyAttachment

local function StartFly()
	if FlyVelocity then
		FlyVelocity:Destroy()
	end

	if FlyAttachment then
		FlyAttachment:Destroy()
	end

	local r=GetRoot()
	if not r then return end

	FlyAttachment=Instance.new("Attachment")
	FlyAttachment.Name="VIA_FlyAttachment"
	FlyAttachment.Parent=r

	FlyVelocity=Instance.new("LinearVelocity")
	FlyVelocity.Name="VIA_FlyVelocity"
	FlyVelocity.Attachment0=FlyAttachment
	FlyVelocity.MaxForce=math.huge
	FlyVelocity.RelativeTo=Enum.ActuatorRelativeTo.World
	FlyVelocity.VectorVelocity=Vector3.zero
	FlyVelocity.Parent=r
end

local function StopFly()
	if FlyVelocity then
		FlyVelocity:Destroy()
		FlyVelocity=nil
	end

	if FlyAttachment then
		FlyAttachment:Destroy()
		FlyAttachment=nil
	end
end

RunService.RenderStepped:Connect(function()
	CharacterUpdate()

	local r=GetRoot()
	local h=GetHumanoid()

	if not r or not h then return end

	-- speed
	if not State.Sprint then
		h.WalkSpeed=State.Speed
	end

	h.JumpPower=State.Jump

	-- freeze
	if State.Freeze then
		r.AssemblyLinearVelocity=Vector3.zero
		r.AssemblyAngularVelocity=Vector3.zero
	end

	-- noclip
	if State.Noclip and Character then
		for _,p in ipairs(Character:GetDescendants()) do
			if p:IsA("BasePart") then
				p.CanCollide=false
			end
		end
	end

	-- gravity
	if State.NoGravity then
		Workspace.Gravity=0
	end

	-- fly
	if State.Fly then
		if not FlyVelocity then
			StartFly()
		end

		local move=Vector3.zero

		if UIS:IsKeyDown(Enum.KeyCode.W) then
			move+=Camera.CFrame.LookVector
		end

		if UIS:IsKeyDown(Enum.KeyCode.S) then
			move-=Camera.CFrame.LookVector
		end

		if UIS:IsKeyDown(Enum.KeyCode.A) then
			move-=Camera.CFrame.RightVector
		end

		if UIS:IsKeyDown(Enum.KeyCode.D) then
			move+=Camera.CFrame.RightVector
		end

		if UIS:IsKeyDown(Enum.KeyCode.Space) then
			move+=Vector3.yAxis
		end

		if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
			move-=Vector3.yAxis
		end

		if move.Magnitude>0 then
			move=move.Unit*State.FlySpeed
		end

		if FlyVelocity then
			FlyVelocity.VectorVelocity=move
		end
	else
		StopFly()
	end

	-- glide
	if State.Glide and h.FloorMaterial==Enum.Material.Air then
		local v=r.AssemblyLinearVelocity

		if v.Y<0 then
			r.AssemblyLinearVelocity=Vector3.new(v.X,-5,v.Z)
		end
	end

	-- air control
	if State.AirControl and h.FloorMaterial==Enum.Material.Air then
		local direction=h.MoveDirection

		if direction.Magnitude>0 then
			local v=r.AssemblyLinearVelocity
			r.AssemblyLinearVelocity=Vector3.new(
				direction.X*State.Speed,
				v.Y,
				direction.Z*State.Speed
			)
		end
	end

	-- anti-sit
	if State.AntiSit and h.Sit then
		h.Sit=false
	end

	-- anti-ragdoll
	if State.AntiRagdoll then
		local bad={
			Enum.HumanoidStateType.Ragdoll,
			Enum.HumanoidStateType.FallingDown,
			Enum.HumanoidStateType.PlatformStanding
		}

		for _,state in ipairs(bad) do
			if h:GetState()==state then
				h:ChangeState(Enum.HumanoidStateType.GettingUp)
			end
		end
	end

	-- anti void
	if State.AntiVoid and r.Position.Y < Workspace.FallenPartsDestroyHeight+25 then
		if State.LastSafePosition then
			r.CFrame=State.LastSafePosition
		end
	end

	if r.Position.Y > Workspace.FallenPartsDestroyHeight+100 then
		State.LastSafePosition=r.CFrame
	end
end)

--============================================================================--
-- WALL JUMP / WALL WALK
--============================================================================--

local function WallRay()
	local r=GetRoot()
	if not r then return nil end

	local params=RaycastParams.new()
	params.FilterType=Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances={Character}

	local dirs={
		r.CFrame.RightVector,
		-r.CFrame.RightVector,
		r.CFrame.LookVector,
		-r.CFrame.LookVector
	}

	for _,dir in ipairs(dirs) do
		local result=Workspace:Raycast(r.Position,dir*3,params)

		if result then
			return result
		end
	end
end

UIS.JumpRequest:Connect(function()
	if not State.WallJump then return end

	local r=GetRoot()
	if not r then return end

	local wall=WallRay()

	if wall then
		r.AssemblyLinearVelocity=
			wall.Normal*60+Vector3.new(0,55,0)
	end
end)

RunService.Heartbeat:Connect(function()
	if State.WallWalk then
		local r=GetRoot()

		if r then
			local wall=WallRay()

			if wall then
				local velocity=r.AssemblyLinearVelocity

				if velocity.Y<0 then
					r.AssemblyLinearVelocity=
						Vector3.new(velocity.X,0,velocity.Z)
				end
			end
		end
	end
end)

--============================================================================--
-- PLAYERS
--============================================================================--

local SelectedPlayer=nil

AddSection(PlayersPage,"Player Inspector")

local PlayerSearch=Instance.new("TextBox")
PlayerSearch.Size=UDim2.new(1,-5,0,34)
PlayerSearch.BackgroundColor3=Color3.fromRGB(27,29,36)
PlayerSearch.BorderSizePixel=0
PlayerSearch.PlaceholderText="Search players..."
PlayerSearch.Text=""
PlayerSearch.TextColor3=Color3.fromRGB(230,230,235)
PlayerSearch.Font=Enum.Font.Gotham
PlayerSearch.TextSize=12
PlayerSearch.ClearTextOnFocus=false
PlayerSearch.Parent=PlayersPage
Corner(PlayerSearch,7)

local PlayerList=Instance.new("ScrollingFrame")
PlayerList.Size=UDim2.new(1,-5,0,160)
PlayerList.BackgroundColor3=Color3.fromRGB(20,22,27)
PlayerList.BorderSizePixel=0
PlayerList.ScrollBarThickness=4
PlayerList.Parent=PlayersPage
Corner(PlayerList,7)

local PlayerLayout=Instance.new("UIListLayout")
PlayerLayout.Padding=UDim.new(0,4)
PlayerLayout.Parent=PlayerList

local PlayerInfo=Instance.new("TextLabel")
PlayerInfo.Size=UDim2.new(1,-5,0,100)
PlayerInfo.BackgroundColor3=Color3.fromRGB(20,22,27)
PlayerInfo.BorderSizePixel=0
PlayerInfo.Text="No player selected"
PlayerInfo.TextColor3=Color3.fromRGB(200,205,215)
PlayerInfo.TextSize=12
PlayerInfo.Font=Enum.Font.Code
PlayerInfo.TextXAlignment=Enum.TextXAlignment.Left
PlayerInfo.TextYAlignment=Enum.TextYAlignment.Top
PlayerInfo.Parent=PlayersPage
Corner(PlayerInfo,7)

local function RefreshPlayers()
	for _,obj in ipairs(PlayerList:GetChildren()) do
		if obj:IsA("TextButton") then
			obj:Destroy()
		end
	end

	local filter=PlayerSearch.Text:lower()

	for _,player in ipairs(Players:GetPlayers()) do
		if player~=LP then
			local text=(player.DisplayName.." @"..player.Name):lower()

			if filter=="" or text:find(filter,1,true) then
				local b=Instance.new("TextButton")
				b.Size=UDim2.new(1,-8,0,34)
				b.BackgroundColor3=Color3.fromRGB(28,30,37)
				b.BorderSizePixel=0
				b.Text=player.DisplayName.."  @"..player.Name
				b.TextColor3=Color3.fromRGB(225,225,230)
				b.TextSize=11
				b.Font=Enum.Font.Gotham
				b.TextXAlignment=Enum.TextXAlignment.Left
				b.Parent=PlayerList
				Corner(b,6)

				b.Activated:Connect(function()
					SelectedPlayer=player
					State.SelectedPlayer=player
					Notify("Selected",player.Name)
				end)
			end
		end
	end
end

RefreshPlayers()

PlayerSearch:GetPropertyChangedSignal("Text"):Connect(RefreshPlayers)
Players.PlayerAdded:Connect(RefreshPlayers)
Players.PlayerRemoving:Connect(RefreshPlayers)

RunService.RenderStepped:Connect(function()
	local p=SelectedPlayer

	if p and p.Parent then
		local root=GetPlayerRoot(p)
		local hum=GetPlayerHumanoid(p)

		if root and hum then
			local localRoot=GetRoot()
			local distance=localRoot and
				(localRoot.Position-root.Position).Magnitude or 0

			PlayerInfo.Text=string.format(
				"PLAYER\nDisplayName: %s\nUsername: @%s\nHP: %.0f / %.0f\nDistance: %.1f\nTeam: %s\nPosition: %.1f, %.1f, %.1f\nSpeed: %.1f",
				p.DisplayName,
				p.Name,
				hum.Health,
				hum.MaxHealth,
				distance,
				p.Team and p.Team.Name or "None",
				root.Position.X,
				root.Position.Y,
				root.Position.Z,
				root.AssemblyLinearVelocity.Magnitude
			)
		end
	end
end)

AddButton(PlayersPage,"Teleport To Selected",function()
	local r=GetRoot()
	local target=GetPlayerRoot(SelectedPlayer)

	if r and target then
		r.CFrame=target.CFrame*CFrame.new(0,0,-4)
	end
end)

AddButton(PlayersPage,"Teleport Behind",function()
	local r=GetRoot()
	local target=GetPlayerRoot(SelectedPlayer)

	if r and target then
		r.CFrame=target.CFrame*CFrame.new(0,0,5)
	end
end)

AddButton(PlayersPage,"Teleport Above",function()
	local r=GetRoot()
	local target=GetPlayerRoot(SelectedPlayer)

	if r and target then
		r.CFrame=target.CFrame*CFrame.new(0,8,0)
	end
end)

AddButton(PlayersPage,"Spectate Selected",function()
	local h=GetPlayerHumanoid(SelectedPlayer)

	if h then
		Camera.CameraSubject=h
		State.Spectate=true
	end
end)

AddButton(PlayersPage,"Stop Spectating",function()
	local h=GetHumanoid()

	if h then
		Camera.CameraSubject=h
	end

	State.Spectate=false
end)

--============================================================================--
-- TELEPORT
--============================================================================--

AddSection(TeleportPage,"Position")

local XBox=AddTextBox(TeleportPage,"X","0",function() end)
local YBox=AddTextBox(TeleportPage,"Y","0",function() end)
local ZBox=AddTextBox(TeleportPage,"Z","0",function() end)

AddButton(TeleportPage,"TP To Coordinates",function()
	local r=GetRoot()
	if not r then return end

	local x=tonumber(XBox.Text)
	local y=tonumber(YBox.Text)
	local z=tonumber(ZBox.Text)

	if x and y and z then
		r.CFrame=CFrame.new(x,y,z)
	end
end)

AddButton(TeleportPage,"Save Current Position",function()
	local r=GetRoot()

	if r then
		State.SavedPosition=r.CFrame
		Notify("Teleport","Position saved")
	end
end)

AddButton(TeleportPage,"Return To Saved Position",function()
	local r=GetRoot()

	if r and State.SavedPosition then
		r.CFrame=State.SavedPosition
	end
end)

AddButton(TeleportPage,"Teleport To Spawn",function()
	local spawn=Workspace:FindFirstChildWhichIsA("SpawnLocation",true)
	local r=GetRoot()

	if spawn and r then
		r.CFrame=spawn.CFrame*CFrame.new(0,4,0)
	end
end)

AddButton(TeleportPage,"TP To Mouse",function()
	local r=GetRoot()

	if not r then return end

	local mouse=LP:GetMouse()

	if mouse and mouse.Hit then
		r.CFrame=CFrame.new(mouse.Hit.Position+Vector3.new(0,3,0))
	end
end)

AddButton(TeleportPage,"TP To Touch Position",function()
	Notify(
		"Touch TP",
		"Tap the world after enabling Touch TP mode.",
		3
	)
end)

--============================================================================--
-- WAYPOINTS
--============================================================================--

AddSection(TeleportPage,"Waypoints")

local WaypointList=Instance.new("ScrollingFrame")
WaypointList.Size=UDim2.new(1,-5,0,130)
WaypointList.BackgroundColor3=Color3.fromRGB(20,22,27)
WaypointList.BorderSizePixel=0
WaypointList.ScrollBarThickness=4
WaypointList.Parent=TeleportPage
Corner(WaypointList,7)

local WaypointLayout=Instance.new("UIListLayout")
WaypointLayout.Padding=UDim.new(0,4)
WaypointLayout.Parent=WaypointList

local function RefreshWaypoints()
	for _,o in ipairs(WaypointList:GetChildren()) do
		if o:IsA("TextButton") then
			o:Destroy()
		end
	end

	for name,cf in pairs(Waypoints) do
		local b=Instance.new("TextButton")
		b.Size=UDim2.new(1,-8,0,32)
		b.BackgroundColor3=Color3.fromRGB(28,30,37)
		b.BorderSizePixel=0
		b.Text=name
		b.TextColor3=Color3.fromRGB(225,225,230)
		b.TextSize=11
		b.Font=Enum.Font.Gotham
		b.Parent=WaypointList
		Corner(b,6)

		b.Activated:Connect(function()
			local r=GetRoot()
			if r then
				r.CFrame=cf
			end
		end)
	end
end

AddTextBox(TeleportPage,"Waypoint Name","Point",function(name)
	local r=GetRoot()

	if r and name~="" then
		Waypoints[name]=r.CFrame
		RefreshWaypoints()
		Notify("Waypoint","Saved: "..name)
	end
end)

AddButton(TeleportPage,"Save Current As 'Point'",function()
	local r=GetRoot()

	if r then
		Waypoints["Point"]=r.CFrame
		RefreshWaypoints()
	end
end)

AddButton(TeleportPage,"Clear Waypoints",function()
	table.clear(Waypoints)
	RefreshWaypoints()
end)

--============================================================================--
-- ESP
--============================================================================--

AddSection(ESPPage,"ESP")

local function TeamAllowed(player)
	if not State.ESPTeamCheck then
		return true
	end

	return player.Team~=LP.Team
end

local function CreateESP(player)
	if player==LP then return end

	local data=ESPObjects[player]

	if not data then
		data={}
		ESPObjects[player]=data
	end

	if not player.Character then return end

	-- Highlight
	if State.ESPHighlight then
		if not data.Highlight then
			local hl=Instance.new("Highlight")
			hl.Name="VIA_Highlight"
			hl.DepthMode=Enum.HighlightDepthMode.AlwaysOnTop
			hl.FillTransparency=.65
			hl.OutlineTransparency=0
			hl.Parent=player.Character
			data.Highlight=hl
		end

		data.Highlight.FillColor=
			player.Team and player.Team.TeamColor.Color
			or Color3.fromRGB(255,80,80)

		data.Highlight.Enabled=TeamAllowed(player)
	elseif data.Highlight then
		data.Highlight:Destroy()
		data.Highlight=nil
	end

	-- Billboard
	if State.ESPName or State.ESPDistance or State.ESPHealth then
		if not data.Billboard then
			local root=GetPlayerRoot(player)
			if root then
				local gui=Instance.new("BillboardGui")
				gui.Name="VIA_ESP"
				gui.Size=UDim2.new(0,180,0,60)
				gui.StudsOffset=Vector3.new(0,3,0)
				gui.AlwaysOnTop=true
				gui.Adornee=root
				gui.Parent=GUI

				local label=Instance.new("TextLabel")
				label.Size=UDim2.fromScale(1,1)
				label.BackgroundTransparency=1
				label.TextColor3=Color3.new(1,1,1)
				label.TextStrokeTransparency=.3
				label.TextSize=12
				label.Font=Enum.Font.GothamBold
				label.TextWrapped=true
				label.Parent=gui

				data.Billboard=gui
				data.Label=label
			end
		end

		if data.Label then
			local hum=GetPlayerHumanoid(player)
			local root=GetPlayerRoot(player)

			local lines={}

			if State.ESPName then
				table.insert(lines,player.DisplayName.."  @"..player.Name)
			end

			if State.ESPHealth and hum then
				table.insert(lines,string.format("HP %.0f/%.0f",hum.Health,hum.MaxHealth))
			end

			if State.ESPDistance and root then
				table.insert(lines,string.format("%.0f studs",DistanceFromLocal(player)))
			end

			data.Label.Text=table.concat(lines,"\n")
			data.Label.Visible=
				TeamAllowed(player)
				and root
				and DistanceFromLocal(player)<=State.ESPMaxDistance
		end
	elseif data.Billboard then
		data.Billboard:Destroy()
		data.Billboard=nil
		data.Label=nil
	end
end

local function RemoveESP(player)
	local data=ESPObjects[player]

	if data then
		for _,obj in pairs(data) do
			if typeof(obj)=="Instance" and obj.Parent then
				obj:Destroy()
			end
		end
	end

	ESPObjects[player]=nil
end

for _,p in ipairs(Players:GetPlayers()) do
	if p~=LP then
		p.CharacterAdded:Connect(function()
			task.wait(.2)
			CreateESP(p)
		end)
	end
end

Players.PlayerAdded:Connect(function(p)
	p.CharacterAdded:Connect(function()
		task.wait(.2)
		CreateESP(p)
	end)
end)

Players.PlayerRemoving:Connect(RemoveESP)

AddToggle(ESPPage,"Name ESP",false,function(v)
	State.ESPName=v
end)

AddToggle(ESPPage,"Distance ESP",false,function(v)
	State.ESPDistance=v
end)

AddToggle(ESPPage,"Health ESP",false,function(v)
	State.ESPHealth=v
end)

AddToggle(ESPPage,"Highlight ESP",false,function(v)
	State.ESPHighlight=v
end)

AddToggle(ESPPage,"Team Check",false,function(v)
	State.ESPTeamCheck=v
end)

AddToggle(ESPPage,"Object Highlighting",false,function(v)
	State.ESPObjects=v
end)

AddSlider(ESPPage,"ESP Distance",50,3000,1000,function(v)
	State.ESPMaxDistance=v
end)

AddButton(ESPPage,"Refresh ESP",function()
	for _,p in ipairs(Players:GetPlayers()) do
		if p~=LP then
			CreateESP(p)
		end
	end
end)

RunService.RenderStepped:Connect(function()
	for _,p in ipairs(Players:GetPlayers()) do
		if p~=LP then
			CreateESP(p)
		end
	end
end)

--============================================================================--
-- CAMERA
--============================================================================--

AddSection(CameraPage,"Camera")

AddSlider(CameraPage,"Field Of View",30,120,State.FOV,function(v)
	State.FOV=v
	Camera.FieldOfView=v
end)

AddSlider(CameraPage,"Zoom",2,50,State.Zoom,function(v)
	State.Zoom=v
	LP.CameraMinZoomDistance=2
	LP.CameraMaxZoomDistance=v
end)

AddSlider(CameraPage,"Sensitivity",0.1,3,1,function(v)
	State.CameraSensitivity=v
end,1)

AddToggle(CameraPage,"Smooth Camera",false,function(v)
	State.SmoothCamera=v
end)

AddToggle(CameraPage,"Camera Shake",false,function(v)
	State.CameraShake=v
end)

AddSlider(CameraPage,"Shake Intensity",0,10,1,function(v)
	State.ShakeIntensity=v
end)

AddToggle(CameraPage,"First Person",false,function(v)
	State.FirstPerson=v

	if v then
		LP.CameraMode=Enum.CameraMode.LockFirstPerson
	else
		LP.CameraMode=Enum.CameraMode.Classic
	end
end)

AddToggle(CameraPage,"Third Person",false,function(v)
	State.ThirdPerson=v

	if v then
		LP.CameraMode=Enum.CameraMode.Classic
	end
end)

AddToggle(CameraPage,"Cinematic Camera",false,function(v)
	State.CinematicCamera=v
end)

AddToggle(CameraPage,"Freecam",false,function(v)
	State.Freecam=v

	if v then
		Camera.CameraType=Enum.CameraType.Scriptable
	else
		Camera.CameraType=Enum.CameraType.Custom
		local h=GetHumanoid()
		if h then
			Camera.CameraSubject=h
		end
	end
end)

AddToggle(CameraPage,"Orbit Selected Player",false,function(v)
	State.Orbit=v
end)

AddSlider(CameraPage,"Orbit Radius",3,50,8,function(v)
	State.OrbitRadius=v
end)

AddSlider(CameraPage,"Orbit Speed",0.1,5,1,function(v)
	State.OrbitSpeed=v
end)

AddTextBox(CameraPage,"Camera Offset","0,0,0",function(value)
	local x,y,z=value:match("([^,]+),([^,]+),([^,]+)")

	x=tonumber(x)
	y=tonumber(y)
	z=tonumber(z)

	if x and y and z then
		State.CameraOffset=Vector3.new(x,y,z)
	end
end)

--============================================================================--
-- VISUALS
--============================================================================--

AddSection(VisualPage,"Lighting")

AddToggle(VisualPage,"Fullbright",false,function(v)
	State.Fullbright=v

	if v then
		Lighting.Brightness=4
		Lighting.Ambient=Color3.new(1,1,1)
		Lighting.OutdoorAmbient=Color3.new(1,1,1)
		Lighting.FogEnd=100000
	else
		Lighting.Brightness=State.Brightness
	end
end)

AddSlider(VisualPage,"Brightness",0,10,2,function(v)
	State.Brightness=v
	if not State.Fullbright then
		Lighting.Brightness=v
	end
end)

AddSlider(VisualPage,"Exposure", -5,5,0,function(v)
	State.Exposure=v
	local effect=Lighting:FindFirstChild("VIA_ColorCorrection")
	if effect then effect.ExposureCompensation=v end
end,1)

AddSlider(VisualPage,"Contrast",-2,2,0,function(v)
	State.Contrast=v
	local effect=Lighting:FindFirstChild("VIA_ColorCorrection")
	if effect then effect.Contrast=v end
end,1)

AddSlider(VisualPage,"Saturation",-2,2,0,function(v)
	State.Saturation=v
	local effect=Lighting:FindFirstChild("VIA_ColorCorrection")
	if effect then effect.Saturation=v end
end,1)

AddToggle(VisualPage,"Night Vision",false,function(v)
	State.NightVision=v
end)

AddToggle(VisualPage,"Grayscale",false,function(v)
	State.Grayscale=v
end)

--============================================================================--
-- POST PROCESSING
--============================================================================--

local ColorCorrection=Instance.new("ColorCorrectionEffect")
ColorCorrection.Name="VIA_ColorCorrection"
ColorCorrection.Brightness=0
ColorCorrection.Contrast=0
ColorCorrection.Saturation=0
ColorCorrection.Parent=Lighting

local Bloom=Instance.new("BloomEffect")
Bloom.Name="VIA_Bloom"
Bloom.Intensity=1
Bloom.Size=24
Bloom.Threshold=.8
Bloom.Enabled=false
Bloom.Parent=Lighting

local Blur=Instance.new("BlurEffect")
Blur.Name="VIA_Blur"
Blur.Size=5
Blur.Enabled=false
Blur.Parent=Lighting

local DOF=Instance.new("DepthOfFieldEffect")
DOF.Name="VIA_DOF"
DOF.Enabled=false
DOF.FarIntensity=.2
DOF.NearIntensity=.1
DOF.FocusDistance=20
DOF.InFocusRadius=15
DOF.Parent=Lighting

local SunRays=Instance.new("SunRaysEffect")
SunRays.Name="VIA_SunRays"
SunRays.Intensity=.1
SunRays.Spread=.8
SunRays.Enabled=false
SunRays.Parent=Lighting

local Atmosphere=Lighting:FindFirstChild("VIA_Atmosphere")

if not Atmosphere then
	Atmosphere=Instance.new("Atmosphere")
	Atmosphere.Name="VIA_Atmosphere"
	Atmosphere.Density=.25
	Atmosphere.Offset=0
	Atmosphere.Haze=0
	Atmosphere.Glare=0
	Atmosphere.Color=Color3.fromRGB(199,199,199)
	Atmosphere.Decay=Color3.fromRGB(106,112,125)
	Atmosphere.Enabled=false
	Atmosphere.Parent=Lighting
end

AddToggle(VisualPage,"Bloom",false,function(v)
	State.Bloom=v
	Bloom.Enabled=v
end)

AddSlider(VisualPage,"Bloom Intensity",0,5,1,function(v)
	State.BloomIntensity=v
	Bloom.Intensity=v
end)

AddToggle(VisualPage,"Blur",false,function(v)
	State.Blur=v
	Blur.Enabled=v
end)

AddSlider(VisualPage,"Blur Size",0,56,5,function(v)
	State.BlurSize=v
	Blur.Size=v
end)

AddToggle(VisualPage,"Depth Of Field",false,function(v)
	State.DOF=v
	DOF.Enabled=v
end)

AddToggle(VisualPage,"Sun Rays",false,function(v)
	State.SunRays=v
	SunRays.Enabled=v
end)

AddToggle(VisualPage,"Atmosphere",false,function(v)
	State.Atmosphere=v
	Atmosphere.Enabled=v
end)

AddSlider(VisualPage,"Fog Start",0,5000,0,function(v)
	State.FogStart=v
	Lighting.FogStart=v
end)

AddSlider(VisualPage,"Fog End",100,10000,1000,function(v)
	State.FogEnd=v
	Lighting.FogEnd=v
end)

AddSlider(VisualPage,"Atmosphere Haze",0,5,0,function(v)
	State.FogHaze=v
	Atmosphere.Haze=v
end,1)

AddSlider(VisualPage,"Atmosphere Glare",0,5,0,function(v)
	Atmosphere.Glare=v
end,1)

--============================================================================--
-- VISUAL OVERLAYS
--============================================================================--

local Overlay=Instance.new("Frame")
Overlay.Size=UDim2.fromScale(1,1)
Overlay.BackgroundTransparency=1
Overlay.BorderSizePixel=0
Overlay.ZIndex=100
Overlay.Parent=GUI

local Vignette=Instance.new("ImageLabel")
Vignette.Size=UDim2.fromScale(1.2,1.2)
Vignette.Position=UDim2.fromScale(-.1,-.1)
Vignette.BackgroundTransparency=1
Vignette.Image=""
Vignette.Visible=false
Vignette.Parent=Overlay

local Crosshair=Instance.new("Frame")
Crosshair.AnchorPoint=Vector2.new(.5,.5)
Crosshair.Position=UDim2.fromScale(.5,.5)
Crosshair.Size=UDim2.new(0,30,0,30)
Crosshair.BackgroundTransparency=1
Crosshair.Visible=false
Crosshair.ZIndex=110
Crosshair.Parent=Overlay

local CrossV=Instance.new("Frame")
CrossV.AnchorPoint=Vector2.new(.5,.5)
CrossV.Position=UDim2.fromScale(.5,.5)
CrossV.Size=UDim2.new(0,2,1,0)
CrossV.BackgroundColor3=Color3.new(1,1,1)
CrossV.BorderSizePixel=0
CrossV.Parent=Crosshair

local CrossH=Instance.new("Frame")
CrossH.AnchorPoint=Vector2.new(.5,.5)
CrossH.Position=UDim2.fromScale(.5,.5)
CrossH.Size=UDim2.new(1,0,0,2)
CrossH.BackgroundColor3=Color3.new(1,1,1)
CrossH.BorderSizePixel=0
CrossH.Parent=Crosshair

-- scanlines
local Scanlines=Instance.new("Frame")
Scanlines.Size=UDim2.fromScale(1,1)
Scanlines.BackgroundTransparency=1
Scanlines.Visible=false
Scanlines.ZIndex=101
Scanlines.Parent=Overlay

for i=0,60 do
	local line=Instance.new("Frame")
	line.Size=UDim2.new(1,0,0,1)
	line.Position=UDim2.new(0,0,i/60,0)
	line.BackgroundColor3=Color3.fromRGB(0,0,0)
	line.BackgroundTransparency=.78
	line.BorderSizePixel=0
	line.Parent=Scanlines
end

local Film=Instance.new("TextLabel")
Film.Size=UDim2.fromScale(1,1)
Film.BackgroundTransparency=1
Film.Text="."
Film.TextColor3=Color3.fromRGB(255,255,255)
Film.TextTransparency=.96
Film.TextSize=40
Film.ZIndex=102
Film.Visible=false
Film.Parent=Overlay

local CinematicTop=Instance.new("Frame")
CinematicTop.Size=UDim2.new(1,0,0,45)
CinematicTop.BackgroundColor3=Color3.new(0,0,0)
CinematicTop.BorderSizePixel=0
CinematicTop.Visible=false
CinematicTop.ZIndex=103
CinematicTop.Parent=Overlay

local CinematicBottom=Instance.new("Frame")
CinematicBottom.AnchorPoint=Vector2.new(0,1)
CinematicBottom.Position=UDim2.fromScale(0,1)
CinematicBottom.Size=UDim2.new(1,0,0,45)
CinematicBottom.BackgroundColor3=Color3.new(0,0,0)
CinematicBottom.BorderSizePixel=0
CinematicBottom.Visible=false
CinematicBottom.ZIndex=103
CinematicBottom.Parent=Overlay

AddToggle(VisualPage,"Vignette",false,function(v)
	State.Vignette=v
	-- Roblox GUI has no universal procedural vignette texture;
	-- this state remains available for custom place assets.
	Vignette.Visible=false
end)

AddToggle(VisualPage,"Film Grain",false,function(v)
	State.FilmGrain=v
	Film.Visible=v
end)

AddToggle(VisualPage,"Scanlines",false,function(v)
	State.Scanlines=v
	Scanlines.Visible=v
end)

AddToggle(VisualPage,"Crosshair",false,function(v)
	State.Crosshair=v
	Crosshair.Visible=v
end)

AddToggle(VisualPage,"Cinematic Mode",false,function(v)
	State.CinematicVisual=v
	CinematicTop.Visible=v
	CinematicBottom.Visible=v
end)

--============================================================================--
-- TARGETING / FOV
--============================================================================--

AddSection(TargetPage,"Target Selector")

local TargetInfo=Instance.new("TextLabel")
TargetInfo.Size=UDim2.new(1,-5,0,60)
TargetInfo.BackgroundColor3=Color3.fromRGB(20,22,27)
TargetInfo.BorderSizePixel=0
TargetInfo.Text="TARGET: NONE"
TargetInfo.TextColor3=Color3.fromRGB(110,215,255)
TargetInfo.TextSize=12
TargetInfo.Font=Enum.Font.GothamBold
TargetInfo.TextXAlignment=Enum.TextXAlignment.Left
TargetInfo.Parent=TargetPage
Corner(TargetInfo,7)

AddToggle(TargetPage,"Aim Assist",false,function(v)
	State.AimAssist=v
end)

AddToggle(TargetPage,"Target Lock",false,function(v)
	State.TargetLock=v
end)

AddSlider(TargetPage,"FOV Circle",20,600,State.AimFOV,function(v)
	State.AimFOV=v
end)

AddSlider(TargetPage,"Smoothness",0.01,1,.18,function(v)
	State.AimSmooth=v
end,2)

AddSlider(TargetPage,"Target Distance",25,5000,1000,function(v)
	State.AimDistance=v
end)

AddToggle(TargetPage,"Team Check",true,function(v)
	State.AimTeamCheck=v
end)

AddToggle(TargetPage,"Visibility Check",true,function(v)
	State.AimVisibility=v
end)

AddButton(TargetPage,"Priority: Distance",function()
	State.AimPriority="Distance"
	Notify("Targeting","Priority = Distance")
end)

AddButton(TargetPage,"Priority: Health",function()
	State.AimPriority="Health"
	Notify("Targeting","Priority = Health")
end)

-- FOV circle using standard Roblox GUI
local FOVCircle=Instance.new("Frame")
FOVCircle.AnchorPoint=Vector2.new(.5,.5)
FOVCircle.Position=UDim2.fromScale(.5,.5)
FOVCircle.Size=UDim2.new(0,300,0,300)
FOVCircle.BackgroundTransparency=1
FOVCircle.Visible=false
FOVCircle.ZIndex=90
FOVCircle.Parent=GUI

local FOVCorner=Instance.new("UICorner")
FOVCorner.CornerRadius=UDim.new(1,0)
FOVCorner.Parent=FOVCircle

local FOVStroke=Instance.new("UIStroke")
FOVStroke.Color=Color3.fromRGB(100,220,255)
FOVStroke.Thickness=1
FOVStroke.Transparency=.25
FOVStroke.Parent=FOVCircle

local function IsVisible(targetPart)
	if not targetPart then return false end

	local origin=Camera.CFrame.Position
	local direction=targetPart.Position-origin

	local params=RaycastParams.new()
	params.FilterType=Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances={Character}

	local hit=Workspace:Raycast(origin,direction,params)

	if not hit then
		return true
	end

	return hit.Instance:IsDescendantOf(targetPart.Parent)
end

local function FindTarget()
	local mousePos=UIS:GetMouseLocation()
	local best=nil
	local bestScore=math.huge

	for _,player in ipairs(Players:GetPlayers()) do
		if player~=LP and IsAlive(player) then

			if State.AimTeamCheck and player.Team==LP.Team then
				continue
			end

			local root=GetPlayerRoot(player)
			local head=player.Character and player.Character:FindFirstChild("Head")

			if root and head then
				local distance=DistanceFromLocal(player)

				if distance<=State.AimDistance then
					local screen,onScreen=Camera:WorldToViewportPoint(head.Position)

					if onScreen then
						local screenDistance=
							(Vector2.new(screen.X,screen.Y)-mousePos).Magnitude

						if screenDistance<=State.AimFOV then
							if not State.AimVisibility or IsVisible(head) then
								local score

								if State.AimPriority=="Health" then
									local hum=GetPlayerHumanoid(player)
									score=hum and hum.Health or math.huge
								else
									score=screenDistance
								end

								if score<bestScore then
									bestScore=score
									best=head
								end
							end
						end
					end
				end
			end
		end
	end

	return best
end

--============================================================================--
-- DEBUG
--============================================================================--

AddSection(DebugPage,"Performance")

local DebugLabel=Instance.new("TextLabel")
DebugLabel.Size=UDim2.new(1,-5,0,170)
DebugLabel.BackgroundColor3=Color3.fromRGB(18,20,25)
DebugLabel.BorderSizePixel=0
DebugLabel.TextColor3=Color3.fromRGB(120,220,170)
DebugLabel.TextSize=11
DebugLabel.Font=Enum.Font.Code
DebugLabel.TextXAlignment=Enum.TextXAlignment.Left
DebugLabel.TextYAlignment=Enum.TextYAlignment.Top
DebugLabel.Text=""
DebugLabel.Parent=DebugPage
Corner(DebugLabel,7)

local DebugRayEnabled=false
local DebugRayPart=nil

AddToggle(DebugPage,"Ray Visualization",false,function(v)
	DebugRayEnabled=v

	if not v and DebugRayPart then
		DebugRayPart:Destroy()
		DebugRayPart=nil
	end
end)

local HitboxDebug=false

AddToggle(DebugPage,"Hitbox Visualization",false,function(v)
	HitboxDebug=v
end)

AddButton(DebugPage,"Distance To Selected",function()
	if SelectedPlayer then
		local d=DistanceFromLocal(SelectedPlayer)

		if d<math.huge then
			Notify("Distance",string.format("%.1f studs",d))
		end
	end
end)

local function GetPing()
	local ok,value=pcall(function()
		local item=Stats.Network.ServerStatsItem["Data Ping"]
		return item:GetValue()
	end)

	if ok and value then
		return math.floor(value)
	end

	return 0
end

local fps=60
local frameTime=0

RunService.RenderStepped:Connect(function(dt)
	frameTime=dt*1000

	if dt>0 then
		fps=math.floor(1/dt)
	end

	local r=GetRoot()
	local h=GetHumanoid()

	local pos=r and r.Position or Vector3.zero
	local velocity=r and r.AssemblyLinearVelocity or Vector3.zero

	local memory=0

	pcall(function()
		memory=Stats:GetTotalMemoryUsageMb()
	end)

	local state=h and h:GetState().Name or "N/A"

	local cameraCFrame=Camera.CFrame

	local device=
		UIS.TouchEnabled
		and UIS.KeyboardEnabled
		and "PC + Touch"
		or UIS.TouchEnabled
		and "Mobile"
		or UIS.GamepadEnabled
		and "Gamepad"
		or "PC"

	DebugLabel.Text=string.format(
		"FPS: %d\nFrame Time: %.2f ms\nPing: %d ms\nMemory: %.1f MB\n\nPosition: %.2f, %.2f, %.2f\nVelocity: %.2f, %.2f, %.2f\nHumanoid State: %s\n\nCamera CFrame:\n%s\n\nDevice: %s",
		fps,
		frameTime,
		GetPing(),
		memory,
		pos.X,pos.Y,pos.Z,
		velocity.X,velocity.Y,velocity.Z,
		state,
		tostring(cameraCFrame),
		device
	)
end)

--============================================================================--
-- DEVICE
--============================================================================--

AddSection(DevicePage,"Device")

local DeviceLabel=Instance.new("TextLabel")
DeviceLabel.Size=UDim2.new(1,-5,0,100)
DeviceLabel.BackgroundColor3=Color3.fromRGB(20,22,27)
DeviceLabel.BorderSizePixel=0
DeviceLabel.TextColor3=Color3.fromRGB(210,215,225)
DeviceLabel.TextSize=12
DeviceLabel.Font=Enum.Font.Gotham
DeviceLabel.TextXAlignment=Enum.TextXAlignment.Left
DeviceLabel.TextYAlignment=Enum.TextYAlignment.Top
DeviceLabel.Parent=DevicePage
Corner(DeviceLabel,7)

local function DetectDevice()
	if UIS.TouchEnabled and UIS.GamepadEnabled then
		return "Mobile + Gamepad"
	elseif UIS.TouchEnabled and UIS.KeyboardEnabled then
		return "PC + Touch"
	elseif UIS.TouchEnabled then
		return "Mobile"
	elseif UIS.GamepadEnabled then
		return "Gamepad"
	else
		return "PC"
	end
end

RunService.RenderStepped:Connect(function()
	DeviceLabel.Text=
		"Device: "..DetectDevice()..
		"\nTouch: "..tostring(UIS.TouchEnabled)..
		"\nKeyboard: "..tostring(UIS.KeyboardEnabled)..
		"\nMouse: "..tostring(UIS.MouseEnabled)..
		"\nGamepad: "..tostring(UIS.GamepadEnabled)..
		"\nViewport: "..tostring(Camera.ViewportSize.X).." x "..tostring(Camera.ViewportSize.Y)
end)

AddSlider(DevicePage,"UI Scale",.6,1.5,1,function(v)
	State.UIScale=v
	UIScale.Scale=v
end,2)

AddSlider(DevicePage,"Touch Button Size",.6,2,1,function(v)
	State.TouchSize=v
end,2)

AddSlider(DevicePage,"Touch Sensitivity",.1,3,1,function(v)
	State.CameraSensitivity=v
end,2)

AddToggle(DevicePage,"Compact Layout",false,function(v)
	State.Compact=v

	if v then
		Main.Size=UDim2.new(0,620,0,400)
	else
		Main.Size=UDim2.new(0,720,0,470)
	end
end)

AddButton(DevicePage,"Auto Detect Device",function()
	Notify("Device",DetectDevice())
end)

--============================================================================--
-- MOBILE FLY CONTROLS
--============================================================================--

local MobileFrame=Instance.new("Frame")
MobileFrame.AnchorPoint=Vector2.new(1,1)
MobileFrame.Position=UDim2.new(1,-20,1,-20)
MobileFrame.Size=UDim2.new(0,180,0,150)
MobileFrame.BackgroundTransparency=1
MobileFrame.Visible=UIS.TouchEnabled
MobileFrame.ZIndex=80
MobileFrame.Parent=GUI

local function MobileButton(text,x,y,callback)
	local b=Instance.new("TextButton")
	b.Position=UDim2.new(0,x,0,y)
	b.Size=UDim2.new(0,52,0,42)
	b.BackgroundColor3=Color3.fromRGB(20,23,29)
	b.BackgroundTransparency=.15
	b.Text=text
	b.TextColor3=Color3.fromRGB(225,230,235)
	b.TextSize=13
	b.Font=Enum.Font.GothamBold
	b.Parent=MobileFrame

	Corner(b,9)

	b.Activated:Connect(function()
		SafeCall(callback)
	end)

	return b
end

MobileButton("▲",64,0,function()
	local r=GetRoot()
	if r then
		r.AssemblyLinearVelocity+=Vector3.yAxis*State.FlySpeed
	end
end)

MobileButton("▼",64,52,function()
	local r=GetRoot()
	if r then
		r.AssemblyLinearVelocity-=Vector3.yAxis*State.FlySpeed
	end
end)

MobileButton("DASH",120,52,function()
	local r=GetRoot()
	if r then
		r.AssemblyLinearVelocity=Camera.CFrame.LookVector*State.DashPower
	end
end)

MobileButton("FLY",120,0,function()
	State.Fly=not State.Fly
	Notify("Fly",State.Fly and "Enabled" or "Disabled")
end)

--============================================================================--
-- CAMERA / TARGET LOOP
--============================================================================--

local OrbitAngle=0

RunService.RenderStepped:Connect(function(dt)
	Camera=Workspace.CurrentCamera or Camera

	-- FOV
	if not State.CinematicCamera then
		if Camera.CameraType~=Enum.CameraType.Scriptable then
			Camera.FieldOfView=State.FOV
		end
	end

	-- target FOV
	FOVCircle.Visible=State.AimAssist

	local diameter=State.AimFOV*2
	FOVCircle.Size=UDim2.new(0,diameter,0,diameter)

	-- orbit
	if State.Orbit and SelectedPlayer then
		local targetRoot=GetPlayerRoot(SelectedPlayer)

		if targetRoot then
			OrbitAngle += dt*State.OrbitSpeed

			local offset=
				Vector3.new(
					math.cos(OrbitAngle)*State.OrbitRadius,
					3,
					math.sin(OrbitAngle)*State.OrbitRadius
				)

			Camera.CameraType=Enum.CameraType.Scriptable

			local targetPosition=targetRoot.Position+offset

			Camera.CFrame=
				CFrame.lookAt(
					targetPosition,
					targetRoot.Position
				)
		end
	end

	-- spectate
	if State.Spectate and SelectedPlayer then
		local h=GetPlayerHumanoid(SelectedPlayer)

		if h and Camera.CameraType~=Enum.CameraType.Scriptable then
			Camera.CameraSubject=h
		end
	end

	-- camera shake
	if State.CameraShake and Camera.CameraType~=Enum.CameraType.Scriptable then
		local power=State.ShakeIntensity*.02

		local shake=
			Vector3.new(
				(math.random()-.5)*power,
				(math.random()-.5)*power,
				(math.random()-.5)*power
			)

		Camera.CFrame*=CFrame.new(shake)
	end

	-- target
	if State.AimAssist then
		local target=FindTarget()

		if target then
			local player=Players:GetPlayerFromCharacter(target.Parent)

			if player then
				TargetInfo.Text=
					"TARGET: "..player.DisplayName..
					"\n@"..player.Name..
					"\n"..string.format("%.0f studs",DistanceFromLocal(player))

				if State.TargetLock or UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
					if Camera.CameraType~=Enum.CameraType.Scriptable then
						local desired=CFrame.lookAt(
							Camera.CFrame.Position,
							target.Position
						)

						Camera.CFrame=
							Camera.CFrame:Lerp(
								desired,
								State.AimSmooth
							)
					end
				end
			end
		else
			TargetInfo.Text="TARGET: NONE"
		end
	end

	-- freecam
	if State.Freecam then
		Camera.CameraType=Enum.CameraType.Scriptable
	end
end)

--============================================================================--
-- OBJECT HIGHLIGHT
--============================================================================--

local ObjectHighlights={}

local function UpdateObjectHighlights()
	if not State.ESPObjects then
		for _,h in pairs(ObjectHighlights) do
			if h.Parent then
				h:Destroy()
			end
		end

		table.clear(ObjectHighlights)
		return
	end

	for _,obj in ipairs(Workspace:GetDescendants()) do
		if obj:IsA("Model") and not Players:GetPlayerFromCharacter(obj) then
			local root=obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")

			if root and not ObjectHighlights[obj] then
				local h=Instance.new("Highlight")
				h.Name="VIA_ObjectHighlight"
				h.FillTransparency=.85
				h.OutlineTransparency=.1
				h.FillColor=Color3.fromRGB(255,190,70)
				h.OutlineColor=Color3.fromRGB(255,230,150)
				h.Adornee=obj
				h.Parent=GUI

				ObjectHighlights[obj]=h
			end
		end
	end
end

task.spawn(function()
	while GUI.Parent do
		if State.ESPObjects then
			UpdateObjectHighlights()
		end

		task.wait(2)
	end
end)

--============================================================================--
-- HITMARKER
--============================================================================--

local Hitmarker=Instance.new("TextLabel")
Hitmarker.AnchorPoint=Vector2.new(.5,.5)
Hitmarker.Position=UDim2.fromScale(.5,.5)
Hitmarker.Size=UDim2.new(0,70,0,70)
Hitmarker.BackgroundTransparency=1
Hitmarker.Text="×"
Hitmarker.TextColor3=Color3.fromRGB(255,255,255)
Hitmarker.TextSize=45
Hitmarker.Font=Enum.Font.GothamBold
Hitmarker.Visible=false
Hitmarker.ZIndex=120
Hitmarker.Parent=GUI

AddToggle(VisualPage,"Hitmarker",false,function(v)
	State.Hitmarker=v
end)

local function ShowHitmarker()
	if not State.Hitmarker then return end

	Hitmarker.Visible=true
	Hitmarker.TextTransparency=0

	task.delay(.12,function()
		if Hitmarker then
			Tween(Hitmarker,.2,{TextTransparency=1})

			task.delay(.2,function()
				Hitmarker.Visible=false
				Hitmarker.TextTransparency=0
			end)
		end
	end)
end

--============================================================================--
-- RAY VISUALIZATION
--============================================================================--

RunService.RenderStepped:Connect(function()
	if not DebugRayEnabled then return end

	local origin=Camera.CFrame.Position
	local direction=Camera.CFrame.LookVector*500

	local params=RaycastParams.new()
	params.FilterType=Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances={Character}

	local result=Workspace:Raycast(origin,direction,params)

	local endpoint=result and result.Position or origin+direction

	local distance=(endpoint-origin).Magnitude

	if not DebugRayPart then
		DebugRayPart=Instance.new("Part")
		DebugRayPart.Name="VIA_DebugRay"
		DebugRayPart.Anchored=true
		DebugRayPart.CanCollide=false
		DebugRayPart.CanTouch=false
		DebugRayPart.CanQuery=false
		DebugRayPart.Material=Enum.Material.Neon
		DebugRayPart.Color=Color3.fromRGB(80,220,255)
		DebugRayPart.Transparency=.35
		DebugRayPart.Parent=Workspace
	end

	DebugRayPart.Size=Vector3.new(.03,.03,distance)
	DebugRayPart.CFrame=CFrame.lookAt(
		origin:Lerp(endpoint,.5),
		endpoint
	)
end)

--============================================================================--
-- HITBOX VISUALIZATION
--============================================================================--

local HitboxFolder=Instance.new("Folder")
HitboxFolder.Name="VIA_DebugHitboxes"
HitboxFolder.Parent=Workspace

local function UpdateHitboxes()
	if not HitboxDebug then
		for _,o in ipairs(HitboxFolder:GetChildren()) do
			o:Destroy()
		end
		return
	end

	for _,p in ipairs(Players:GetPlayers()) do
		if p~=LP and p.Character then
			local root=GetPlayerRoot(p)

			if root and not HitboxFolder:FindFirstChild(p.Name) then
				local box=Instance.new("BoxHandleAdornment")
				box.Name=p.Name
				box.Adornee=root
				box.Size=root.Size+Vector3.new(1,1,1)
				box.AlwaysOnTop=true
				box.Transparency=.7
				box.Color3=Color3.fromRGB(255,100,100)
				box.Parent=HitboxFolder
			end
		end
	end
end

task.spawn(function()
	while GUI.Parent do
		UpdateHitboxes()
		task.wait(.25)
	end
end)

--============================================================================--
-- SEARCH
--============================================================================--

Search:GetPropertyChangedSignal("Text"):Connect(function()
	local query=Search.Text:lower()

	for _,control in ipairs(Controls) do
		local object=control.Object

		if object and object.Parent then
			object.Visible=
				query==""
				or control.Text:find(query,1,true)~=nil
		end
	end

	-- search tabs too
	for name,button in pairs(TabButtons) do
		button.Visible=
			query==""
			or name:lower():find(query,1,true)~=nil
	end
end)

--============================================================================--
-- SETTINGS
--============================================================================--

AddSection(SettingsPage,"Hub")

AddButton(SettingsPage,"Reset Camera",function()
	Camera.CameraType=Enum.CameraType.Custom

	local h=GetHumanoid()

	if h then
		Camera.CameraSubject=h
	end

	State.Freecam=false
	State.Orbit=false
	State.Spectate=false
end)

AddButton(SettingsPage,"Reset Movement",function()
	State.Speed=16
	State.Jump=50
	State.Fly=false
	State.Noclip=false
	State.NoGravity=false
	State.Glide=false
	State.Freeze=false

	Workspace.Gravity=196.2

	local h=GetHumanoid()

	if h then
		h.WalkSpeed=16
		h.JumpPower=50
	end

	Notify("Settings","Movement reset")
end)

AddButton(SettingsPage,"Reset Visuals",function()
	State.Fullbright=false
	State.NightVision=false
	State.Grayscale=false

	ColorCorrection.Brightness=0
	ColorCorrection.Contrast=0
	ColorCorrection.Saturation=0

	Bloom.Enabled=false
	Blur.Enabled=false
	DOF.Enabled=false
	SunRays.Enabled=false
	Atmosphere.Enabled=false

	Scanlines.Visible=false
	Film.Visible=false
	Crosshair.Visible=false
	CinematicTop.Visible=false
	CinematicBottom.Visible=false

	Lighting.Brightness=1
	Lighting.FogStart=0
	Lighting.FogEnd=100000

	Notify("Visuals","Visual settings reset")
end)

AddButton(SettingsPage,"Clear ESP",function()
	for _,p in ipairs(Players:GetPlayers()) do
		RemoveESP(p)
	end

	for _,h in pairs(ObjectHighlights) do
		if h.Parent then
			h:Destroy()
		end
	end

	table.clear(ObjectHighlights)
end)

AddButton(SettingsPage,"Destroy VIA Admin Hub",function()
	State.Fly=false
	State.Noclip=false
	State.NoGravity=false

	Workspace.Gravity=196.2

	for _,connection in ipairs(Connections) do
		pcall(function()
			connection:Disconnect()
		end)
	end

	if FlyVelocity then
		FlyVelocity:Destroy()
	end

	if FlyAttachment then
		FlyAttachment:Destroy()
	end

	GUI:Destroy()
end)

--============================================================================--
-- MINIMIZE / CLOSE
--============================================================================--

local Minimized=false
local OriginalSize=Main.Size

Minimize.Activated:Connect(function()
	Minimized=not Minimized

	if Minimized then
		Tween(Main,.25,{
			Size=UDim2.new(
				OriginalSize.X.Scale,
				OriginalSize.X.Offset,
				0,
				44
			)
		})
	else
		Tween(Main,.25,{
			Size=OriginalSize
		})
	end
end)

Close.Activated:Connect(function()
	Tween(Main,.25,{
		Size=UDim2.new(0,0,0,0)
	})

	task.delay(.25,function()
		Main.Visible=false
		Floating.Visible=true
	end)
end)

Floating.Activated:Connect(function()
	Floating.Visible=false
	Main.Visible=true
	Main.Size=UDim2.new(0,0,0,0)

	Tween(Main,.3,{
		Size=OriginalSize
	})
end)

--============================================================================--
-- TOUCH TP
--============================================================================--

local TouchTP=false

AddToggle(TeleportPage,"Touch TP Mode",false,function(v)
	TouchTP=v

	if v then
		Notify("Touch TP","Tap anywhere on the world")
	end
end)

UIS.InputBegan:Connect(function(input,gp)
	if gp then return end

	if not TouchTP then return end

	if input.UserInputType==Enum.UserInputType.Touch then
		local position=input.Position
		local ray=Camera:ViewportPointToRay(position.X,position.Y)

		local params=RaycastParams.new()
		params.FilterType=Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances={Character}

		local result=Workspace:Raycast(ray.Origin,ray.Direction*5000,params)

		local r=GetRoot()

		if result and r then
			r.CFrame=CFrame.new(result.Position+Vector3.new(0,3,0))
		end
	end
end)

--============================================================================--
-- MOBILE / PC ADAPTATION
--============================================================================--

local function AdaptUI()
	local viewport=Camera.ViewportSize

	if viewport.X<700 then
		Main.Size=UDim2.new(
			0,
			math.min(viewport.X-20,620),
			0,
			math.min(viewport.Y-30,520)
		)

		Sidebar.Size=UDim2.new(0,110,1,-64)
		Content.Position=UDim2.new(0,120,0,54)
		Content.Size=UDim2.new(1,-130,1,-64)

		Search.TextSize=10

		for _,button in pairs(TabButtons) do
			button.TextSize=10
		end
	else
		if not Minimized then
			Main.Size=OriginalSize
		end

		Sidebar.Size=UDim2.new(0,145,1,-64)
		Content.Position=UDim2.new(0,165,0,54)
		Content.Size=UDim2.new(1,-175,1,-64)
	end
end

Camera:GetPropertyChangedSignal("ViewportSize"):Connect(AdaptUI)
AdaptUI()

--============================================================================--
-- STARTUP
--============================================================================--

Workspace.Gravity=Workspace.Gravity

if Humanoid then
	Humanoid.WalkSpeed=State.Speed
	Humanoid.JumpPower=State.Jump
end

Notify(
	"VIA ADMIN HUB",
	"v8.0 loaded • "..DetectDevice(),
	4
)

--============================================================================--
-- END
--============================================================================--