-- ================================================================= --
-- WIA HUB v8.0 Ultimate Edition :: whitewia / tordark
-- FULL GUI + AIMBOT (WITH VISUAL FOV) + PLAYER LIST + EXTENDED ESP + CFRAME SPEED
-- FIXED: BHOP + TELEPORT TOOL ADDED
-- + MOBILE: touch dragging, minimize button, floating toggle button
-- v8.1: FIXED mobile flight (joystick + UP/DOWN buttons) + new tabbed touch-friendly menu
-- v8.2: mobile-friendly player list (TP / AIM buttons, close, reset, auto-refresh)
-- ================================================================= --

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- Safe CoreGui Parent
local CoreGui = game:GetService("CoreGui")

-- ========== VARIABLE DECLARATIONS ==========
local flightEnabled, noclipEnabled, noclipForceMode = false, false, false
local flySpeed = 50
local bodyVelocity, bodyGyro, noclipConnection, noclipForceConnection = nil, nil, nil, nil
local originalCollisions = {}

local walkSpeedEnabled, jumpPowerEnabled, cframeSpeedEnabled = false, false, false
local walkSpeedValue, jumpPowerValue, cframeSpeedValue = 16, 50, 2
local infiniteJumpEnabled, bhopEnabled, spinbotEnabled = false, false, false
local spinbotSpeed = 20

local godmodeEnabled, godmodeConnection, godmodeHealthConnection = false, false, false
local tpTool = nil
local tpEnabled = false

local wallhackEnabled, highlightConnections, whHighlights = false, {}, {}
local antiAFKEnabled, antiAFKConnection = false, nil
local playerListEnabled = false
local antiVoidEnabled, antiVoidConnection = false, nil
local fullBrightEnabled, noFogEnabled = false, false
local originalBrightness, originalAmbient, originalFog = nil, nil, nil

local fovEnabled, fovValue, originalFOV = false, 90, 70
local hitboxEnabled, hitboxConnection, hitboxSize = false, nil, 5
local autoClickerEnabled, autoClickerDelay, autoClickerConnection = false, 100, nil
local triggerbotEnabled, triggerbotConnection = false, nil

local chatSpamEnabled, chatSpamMessage, chatSpamDelay, chatSpamConnection = false, "WIA HUB ON TOP", 5, nil
local antiFallEnabled, antiFallConnection = false, nil

-- Aimbot Variables
local aimbotEnabled = false
local aimbotFOV = 90
local aimbotSmoothness = 5
local aimbotSelectedTarget = nil
local fovCircleVisible = true

-- ESP Extras
local espBoxEnabled = true
local espTracerEnabled = true
local espNamesEnabled = true
local espDistanceEnabled = true
local espHealthEnabled = true
local espLines, tracerLines, textDrawings = {}, {}, {}

-- Drawing API FOV Circle
local fovCircle = nil
if Drawing then
    fovCircle = Drawing.new("Circle")
    fovCircle.Thickness = 1.5
    fovCircle.NumSides = 60
    fovCircle.Radius = aimbotFOV
    fovCircle.Filled = false
    fovCircle.Visible = false
    fovCircle.Color = Color3.fromRGB(180, 0, 255)
end

-- ========== PLAYER LIST GUI (v8.2: mobile-friendly) ==========
local playerListTumbler -- assigned later in the PLAYER tab

local PlayerListGui = Instance.new("ScreenGui")
PlayerListGui.Name = "WiaPlayerList_v8"
PlayerListGui.ResetOnSpawn = false
PlayerListGui.Parent = CoreGui
PlayerListGui.Enabled = false

-- panel size adapts to the screen
local plViewport = workspace.CurrentCamera.ViewportSize
local plW = math.clamp(plViewport.X * 0.5, 240, 320)
local plH = math.clamp(plViewport.Y - 80, 200, 400)

local PlayerListMain = Instance.new("Frame")
PlayerListMain.Size = UDim2.new(0, plW, 0, plH)
PlayerListMain.Position = UDim2.new(1, -plW - 70, 0, 10)
PlayerListMain.BackgroundColor3 = Color3.fromRGB(12, 12, 22)
PlayerListMain.BackgroundTransparency = 0.1
PlayerListMain.BorderSizePixel = 0
PlayerListMain.ClipsDescendants = true
PlayerListMain.Parent = PlayerListGui

do
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 12)
    c.Parent = PlayerListMain
    local s = Instance.new("UIStroke")
    s.Color = Color3.fromRGB(180, 0, 255)
    s.Thickness = 1.5
    s.Transparency = 0.3
    s.Parent = PlayerListMain
end

-- title (drag the panel by it)
local PlayerListTitle = Instance.new("TextLabel")
PlayerListTitle.Size = UDim2.new(1, -56, 0, 36)
PlayerListTitle.Position = UDim2.new(0, 12, 0, 0)
PlayerListTitle.Text = "ИГРОКИ"
PlayerListTitle.TextColor3 = Color3.fromRGB(180, 0, 255)
PlayerListTitle.TextSize = 16
PlayerListTitle.TextXAlignment = Enum.TextXAlignment.Left
PlayerListTitle.BackgroundTransparency = 1
PlayerListTitle.Font = Enum.Font.GothamBold
PlayerListTitle.Parent = PlayerListMain

-- close button
local PlayerListClose = Instance.new("TextButton")
PlayerListClose.Size = UDim2.new(0, 36, 0, 28)
PlayerListClose.Position = UDim2.new(1, -44, 0, 4)
PlayerListClose.Text = "✕"
PlayerListClose.TextColor3 = Color3.fromRGB(255, 255, 255)
PlayerListClose.TextSize = 16
PlayerListClose.Font = Enum.Font.GothamBold
PlayerListClose.BackgroundColor3 = Color3.fromRGB(110, 30, 50)
PlayerListClose.BorderSizePixel = 0
PlayerListClose.Parent = PlayerListMain
do
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = PlayerListClose
end
PlayerListClose.MouseButton1Click:Connect(function()
    if playerListTumbler then
        playerListTumbler.setState(false) -- keeps the menu switch in sync
    else
        PlayerListGui.Enabled = false
    end
end)

-- scrolling list
local playerListScrollingFrame = Instance.new("ScrollingFrame")
playerListScrollingFrame.Size = UDim2.new(1, -8, 1, -84)
playerListScrollingFrame.Position = UDim2.new(0, 4, 0, 38)
playerListScrollingFrame.BackgroundTransparency = 1
playerListScrollingFrame.BorderSizePixel = 0
playerListScrollingFrame.ScrollBarThickness = 3
playerListScrollingFrame.ScrollBarImageColor3 = Color3.fromRGB(180, 0, 255)
playerListScrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
playerListScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
playerListScrollingFrame.ScrollingDirection = Enum.ScrollingDirection.Y
playerListScrollingFrame.Parent = PlayerListMain

local plLayout = Instance.new("UIListLayout")
plLayout.Padding = UDim.new(0, 6)
plLayout.SortOrder = Enum.SortOrder.LayoutOrder
plLayout.Parent = playerListScrollingFrame

local plPad = Instance.new("UIPadding")
plPad.PaddingLeft = UDim.new(0, 4)
plPad.PaddingRight = UDim.new(0, 6)
plPad.PaddingTop = UDim.new(0, 2)
plPad.PaddingBottom = UDim.new(0, 6)
plPad.Parent = playerListScrollingFrame

-- rows are created directly inside the ScrollingFrame
local PlayerListContainer = playerListScrollingFrame

-- bottom bar: current target + reset
local TargetStatus = Instance.new("TextLabel")
TargetStatus.Size = UDim2.new(1, -96, 0, 36)
TargetStatus.Position = UDim2.new(0, 12, 1, -42)
TargetStatus.BackgroundTransparency = 1
TargetStatus.Text = "Цель: авто (ближайший)"
TargetStatus.TextColor3 = Color3.fromRGB(200, 200, 200)
TargetStatus.TextXAlignment = Enum.TextXAlignment.Left
TargetStatus.TextTruncate = Enum.TextTruncate.AtEnd
TargetStatus.Font = Enum.Font.Gotham
TargetStatus.TextSize = 13
TargetStatus.Parent = PlayerListMain

local ResetTargetBtn = Instance.new("TextButton")
ResetTargetBtn.Size = UDim2.new(0, 72, 0, 32)
ResetTargetBtn.Position = UDim2.new(1, -80, 1, -40)
ResetTargetBtn.Text = "СБРОС"
ResetTargetBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ResetTargetBtn.TextSize = 12
ResetTargetBtn.Font = Enum.Font.GothamBold
ResetTargetBtn.BackgroundColor3 = Color3.fromRGB(70, 35, 115)
ResetTargetBtn.BorderSizePixel = 0
ResetTargetBtn.Parent = PlayerListMain
do
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent = ResetTargetBtn
end

-- DRAGGABLE ENGINE (mouse + touch)
local function makeDraggable(frame, handle)
    handle = handle or frame
    local dragging, dragInput, dragStart, startPos = false, nil, nil, nil

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
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

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input == dragInput then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- ========== GUI CREATION (v8.1: tabbed, touch-friendly menu) ==========
local TweenService = game:GetService("TweenService")

local UI_ACCENT = Color3.fromRGB(180, 0, 255)
local UI_BG     = Color3.fromRGB(12, 12, 22)
local UI_ROW    = Color3.fromRGB(26, 26, 42)
local UI_DIM    = Color3.fromRGB(150, 150, 180)
local UI_WHITE  = Color3.fromRGB(255, 255, 255)

local function addCorner(obj, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = obj
    return c
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "WiaHubGUI_v8"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui

-- menu size adapts to the screen (phones have very little height)
local viewport0 = Camera.ViewportSize
local menuW = math.clamp(viewport0.X - 20, 250, 330)
local menuH = math.clamp(viewport0.Y - 40, 240, 470)

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, menuW, 0, menuH)
MainFrame.Position = UDim2.new(0, 10, 0, 10)
MainFrame.BackgroundColor3 = UI_BG
MainFrame.BackgroundTransparency = 0.1
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui
addCorner(MainFrame, 12)

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = UI_ACCENT
mainStroke.Thickness = 1.5
mainStroke.Transparency = 0.3
mainStroke.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -50, 0, 34)
Title.Position = UDim2.new(0, 12, 0, 0)
Title.Text = "WIA HUB v8.0"
Title.TextColor3 = UI_ACCENT
Title.TextSize = 17
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.Parent = MainFrame

local Underline = Instance.new("Frame")
Underline.Size = UDim2.new(1, -20, 0, 1)
Underline.Position = UDim2.new(0, 10, 0, 34)
Underline.BackgroundColor3 = UI_ACCENT
Underline.BackgroundTransparency = 0.4
Underline.BorderSizePixel = 0
Underline.Parent = MainFrame

-- MINIMIZE BUTTON
local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 28, 0, 24)
MinBtn.Position = UDim2.new(1, -36, 0, 5)
MinBtn.Text = "—"
MinBtn.TextColor3 = UI_WHITE
MinBtn.BackgroundColor3 = Color3.fromRGB(60, 35, 95)
MinBtn.BorderSizePixel = 0
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 16
MinBtn.ZIndex = 5
MinBtn.Parent = MainFrame
addCorner(MinBtn, 6)

-- TAB BAR (horizontal, swipeable)
local TabBar = Instance.new("ScrollingFrame")
TabBar.Size = UDim2.new(1, -12, 0, 30)
TabBar.Position = UDim2.new(0, 6, 0, 39)
TabBar.BackgroundTransparency = 1
TabBar.BorderSizePixel = 0
TabBar.ScrollBarThickness = 0
TabBar.ScrollingDirection = Enum.ScrollingDirection.X
TabBar.AutomaticCanvasSize = Enum.AutomaticSize.X
TabBar.CanvasSize = UDim2.new(0, 0, 0, 0)
TabBar.Parent = MainFrame

local tabLayout = Instance.new("UIListLayout")
tabLayout.FillDirection = Enum.FillDirection.Horizontal
tabLayout.Padding = UDim.new(0, 6)
tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
tabLayout.Parent = TabBar

-- PAGE AREA
local PageHolder = Instance.new("Frame")
PageHolder.Size = UDim2.new(1, 0, 1, -98)
PageHolder.Position = UDim2.new(0, 0, 0, 74)
PageHolder.BackgroundTransparency = 1
PageHolder.ClipsDescendants = true
PageHolder.Parent = MainFrame

-- STATUS BAR
local StatusBar = Instance.new("TextLabel")
StatusBar.Size = UDim2.new(1, -20, 0, 20)
StatusBar.Position = UDim2.new(0, 10, 1, -22)
StatusBar.Text = "Ready"
StatusBar.TextColor3 = UI_DIM
StatusBar.TextSize = 12
StatusBar.TextXAlignment = Enum.TextXAlignment.Left
StatusBar.BackgroundTransparency = 1
StatusBar.Font = Enum.Font.Gotham
StatusBar.Parent = MainFrame

local function setStatus(text, color)
    StatusBar.Text = text
    StatusBar.TextColor3 = color or UI_DIM
end

-- TABS
local tabs, currentPage, tabCount = {}, nil, 0

local function selectTab(name)
    for n, t in pairs(tabs) do
        local on = (n == name)
        t.page.Visible = on
        t.btn.BackgroundColor3 = on and UI_ACCENT or UI_ROW
        t.btn.TextColor3 = on and UI_WHITE or UI_DIM
    end
end

local function createTab(name)
    tabCount = tabCount + 1

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, math.max(64, #name * 9 + 22), 1, 0)
    btn.Text = name
    btn.TextSize = 13
    btn.Font = Enum.Font.GothamBold
    btn.BackgroundColor3 = UI_ROW
    btn.TextColor3 = UI_DIM
    btn.BorderSizePixel = 0
    btn.AutoButtonColor = false
    btn.LayoutOrder = tabCount
    btn.Parent = TabBar
    addCorner(btn, 8)

    local page = Instance.new("ScrollingFrame")
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.BorderSizePixel = 0
    page.ScrollBarThickness = 3
    page.ScrollBarImageColor3 = UI_ACCENT
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
    page.ScrollingDirection = Enum.ScrollingDirection.Y
    page.Visible = false
    page.Parent = PageHolder

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 6)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = page

    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 8)
    pad.PaddingRight = UDim.new(0, 10)
    pad.PaddingTop = UDim.new(0, 4)
    pad.PaddingBottom = UDim.new(0, 8)
    pad.Parent = page

    tabs[name] = { btn = btn, page = page }
    btn.MouseButton1Click:Connect(function() selectTab(name) end)

    currentPage = page
    if tabCount == 1 then selectTab(name) end
    return page
end

-- MINIMIZE LOGIC
local minimized = false
local fullSize = MainFrame.Size

MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        fullSize = MainFrame.Size
        TabBar.Visible = false
        PageHolder.Visible = false
        StatusBar.Visible = false
        Underline.Visible = false
        MainFrame.Size = UDim2.new(0, fullSize.X.Offset, 0, 34)
        MinBtn.Text = "+"
    else
        MainFrame.Size = fullSize
        TabBar.Visible = true
        PageHolder.Visible = true
        StatusBar.Visible = true
        Underline.Visible = true
        MinBtn.Text = "—"
    end
end)

makeDraggable(MainFrame, Title)
makeDraggable(PlayerListMain, PlayerListTitle)

-- HIDE UI ON LCTRL
local guiVisible = true
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.LeftControl then
        guiVisible = not guiVisible
        ScreenGui.Enabled = guiVisible
        if playerListEnabled then PlayerListGui.Enabled = guiVisible end
    end
end)

-- ========== MOBILE TOGGLE BUTTON ==========
local ToggleGui = Instance.new("ScreenGui")
ToggleGui.Name = "WiaToggle_v8"
ToggleGui.ResetOnSpawn = false
ToggleGui.Parent = CoreGui

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, 44, 0, 44)
ToggleBtn.Position = UDim2.new(1, -60, 0, 60)
ToggleBtn.Text = "W"
ToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(80, 0, 140)
ToggleBtn.BackgroundTransparency = 0.15
ToggleBtn.BorderSizePixel = 0
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 20
ToggleBtn.Parent = ToggleGui

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(1, 0)
toggleCorner.Parent = ToggleBtn

makeDraggable(ToggleBtn)

-- tap vs drag
local pressPos
ToggleBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Touch
    or input.UserInputType == Enum.UserInputType.MouseButton1 then
        pressPos = input.Position
    end
end)
ToggleBtn.InputEnded:Connect(function(input)
    if pressPos and (input.UserInputType == Enum.UserInputType.Touch
    or input.UserInputType == Enum.UserInputType.MouseButton1) then
        if (input.Position - pressPos).Magnitude < 8 then
            guiVisible = not guiVisible
            ScreenGui.Enabled = guiVisible
            if playerListEnabled then PlayerListGui.Enabled = guiVisible end
        end
        pressPos = nil
    end
end)


-- ========== MOBILE FLIGHT CONTROLS (UP / DOWN buttons) ==========
local flyUp, flyDown = false, false

local FlyGui = Instance.new("ScreenGui")
FlyGui.Name = "WiaFly_v8"
FlyGui.ResetOnSpawn = false
FlyGui.Enabled = false
FlyGui.Parent = CoreGui

local function makeFlyButton(text, position, setHeld)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 58, 0, 58)
    b.Position = position
    b.Text = text
    b.TextColor3 = UI_WHITE
    b.TextSize = 24
    b.Font = Enum.Font.GothamBold
    b.BackgroundColor3 = Color3.fromRGB(80, 0, 140)
    b.BackgroundTransparency = 0.25
    b.BorderSizePixel = 0
    b.AutoButtonColor = true
    b.Parent = FlyGui
    addCorner(b, 29)

    b.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
            setHeld(true)
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    setHeld(false)
                end
            end)
        end
    end)
    b.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
            setHeld(false)
        end
    end)
    return b
end

makeFlyButton("▲", UDim2.new(1, -80, 0.5, -70), function(v) flyUp = v end)
makeFlyButton("▼", UDim2.new(1, -80, 0.5, 0), function(v) flyDown = v end)

-- ========== FLIGHT (FIXED: touch joystick + respawn support) ==========
local function stopFlight()
    if bodyVelocity then bodyVelocity:Destroy() bodyVelocity = nil end
    if bodyGyro then bodyGyro:Destroy() bodyGyro = nil end
end

local function startFlight()
    stopFlight()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(1e6, 1e6, 1e6)
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.Parent = root

    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
    bodyGyro.P = 9e4
    bodyGyro.CFrame = root.CFrame
    bodyGyro.Parent = root
end

-- re-create flight objects after respawn
LocalPlayer.CharacterAdded:Connect(function(char)
    if flightEnabled then
        char:WaitForChild("HumanoidRootPart", 5)
        task.wait(0.2)
        if flightEnabled then startFlight() end
    end
end)

-- ========== UI FACTORY FUNCTIONS ==========
local function createSection(text)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 18)
    lbl.Text = string.upper(text)
    lbl.TextColor3 = UI_ACCENT
    lbl.TextSize = 11
    lbl.Font = Enum.Font.GothamBold
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.BackgroundTransparency = 1
    lbl.Parent = currentPage
    return lbl
end

local function createTumbler(labelText, defaultState)
    local row = Instance.new("TextButton")
    row.Size = UDim2.new(1, 0, 0, 40)
    row.BackgroundColor3 = UI_ROW
    row.BorderSizePixel = 0
    row.AutoButtonColor = false
    row.Text = ""
    row.Parent = currentPage
    addCorner(row, 8)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -70, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.Text = labelText
    label.TextColor3 = UI_WHITE
    label.TextSize = 14
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row

    local pill = Instance.new("Frame")
    pill.Size = UDim2.new(0, 44, 0, 24)
    pill.Position = UDim2.new(1, -56, 0.5, -12)
    pill.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
    pill.BorderSizePixel = 0
    pill.Parent = row
    addCorner(pill, 12)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 18, 0, 18)
    knob.Position = UDim2.new(0, 3, 0.5, -9)
    knob.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
    knob.BorderSizePixel = 0
    knob.Parent = pill
    addCorner(knob, 9)

    local state = defaultState or false

    local function updateTumbler(instant)
        local knobPos = state and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
        local pillCol = state and UI_ACCENT or Color3.fromRGB(60, 60, 75)
        local knobCol = state and UI_WHITE or Color3.fromRGB(200, 200, 200)
        if instant then
            knob.Position = knobPos
            pill.BackgroundColor3 = pillCol
            knob.BackgroundColor3 = knobCol
        else
            local info = TweenInfo.new(0.12, Enum.EasingStyle.Quad)
            TweenService:Create(knob, info, { Position = knobPos, BackgroundColor3 = knobCol }):Play()
            TweenService:Create(pill, info, { BackgroundColor3 = pillCol }):Play()
        end
    end
    updateTumbler(true)

    local toggleEvent = Instance.new("BindableEvent")
    row.MouseButton1Click:Connect(function()
        state = not state
        updateTumbler()
        toggleEvent:Fire(state)
    end)

    return {
        getState = function() return state end,
        setState = function(newState)
            state = newState
            updateTumbler()
            toggleEvent:Fire(state)
        end,
        onToggle = function(callback) toggleEvent.Event:Connect(callback) end
    }
end

-- slider drag handling (one global listener for all sliders)
local activeSlider = nil
UserInputService.InputChanged:Connect(function(input)
    if activeSlider and (input == activeSlider.input
    or input.UserInputType == Enum.UserInputType.MouseMovement) then
        activeSlider.apply(input.Position.X)
    end
end)

local function createSlider(labelText, minVal, maxVal, defaultVal, callback)
    local page = currentPage

    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 56)
    row.BackgroundColor3 = UI_ROW
    row.BorderSizePixel = 0
    row.Parent = page
    addCorner(row, 8)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -90, 0, 30)
    label.Position = UDim2.new(0, 12, 0, 2)
    label.Text = labelText
    label.TextColor3 = UI_WHITE
    label.TextSize = 14
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row

    local textBox = Instance.new("TextBox")
    textBox.Size = UDim2.new(0, 56, 0, 24)
    textBox.Position = UDim2.new(1, -68, 0, 6)
    textBox.Text = tostring(defaultVal)
    textBox.TextColor3 = UI_WHITE
    textBox.BackgroundColor3 = Color3.fromRGB(40, 40, 58)
    textBox.BorderSizePixel = 0
    textBox.Font = Enum.Font.Gotham
    textBox.TextSize = 13
    textBox.ClearTextOnFocus = false
    textBox.Parent = row
    addCorner(textBox, 6)

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -28, 0, 6)
    track.Position = UDim2.new(0, 14, 0, 42)
    track.BackgroundColor3 = Color3.fromRGB(50, 50, 72)
    track.BorderSizePixel = 0
    track.Parent = row
    addCorner(track, 3)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = UI_ACCENT
    fill.BorderSizePixel = 0
    fill.Parent = track
    addCorner(fill, 3)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new(0, 0, 0.5, 0)
    knob.BackgroundColor3 = UI_WHITE
    knob.BorderSizePixel = 0
    knob.ZIndex = 2
    knob.Parent = track
    addCorner(knob, 8)

    -- big invisible touch area over the track
    local hit = Instance.new("TextButton")
    hit.Size = UDim2.new(1, 0, 0, 26)
    hit.Position = UDim2.new(0, 0, 0, 30)
    hit.BackgroundTransparency = 1
    hit.Text = ""
    hit.Parent = row

    local value = defaultVal

    local function setVisual(v)
        local a = (v - minVal) / (maxVal - minVal)
        a = math.clamp(a, 0, 1)
        fill.Size = UDim2.new(a, 0, 1, 0)
        knob.Position = UDim2.new(a, 0, 0.5, 0)
        textBox.Text = tostring(v)
    end
    setVisual(value)

    local function applyFromX(x)
        local a = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
        local v = math.floor(minVal + a * (maxVal - minVal) + 0.5)
        setVisual(v)
        if v ~= value then
            value = v
            callback(v)
        end
    end

    hit.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            activeSlider = { apply = applyFromX, input = input }
            page.ScrollingEnabled = false -- don't scroll the page while dragging
            applyFromX(input.Position.X)
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    if activeSlider and activeSlider.input == input then
                        activeSlider = nil
                    end
                    page.ScrollingEnabled = true
                end
            end)
        end
    end)

    textBox.FocusLost:Connect(function()
        local num = tonumber(textBox.Text)
        if num then
            num = math.floor(math.clamp(num, minVal, maxVal) + 0.5)
            value = num
            setVisual(num)
            callback(num)
        else
            setVisual(value)
        end
    end)

    return { setValue = function(val) value = val setVisual(val) end }
end

local function createButton(labelText, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 38)
    btn.Text = labelText
    btn.TextColor3 = UI_WHITE
    btn.BackgroundColor3 = Color3.fromRGB(70, 35, 115)
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.Parent = currentPage
    addCorner(btn, 8)

    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- ========== TELEPORT TOOL FUNCTIONS ==========
local function createTPTool()
    local tool = Instance.new("Tool")
    tool.Name = "WIA_TP"
    tool.RequiresHandle = false
    tool.CanBeDropped = false

    local function teleport(mousePos)
        if not tpEnabled then return end
        local targetPos = mousePos.Hit.Position
        local char = LocalPlayer.Character
        if char and char:FindFirstChild("HumanoidRootPart") then
            local root = char.HumanoidRootPart
            root.CFrame = CFrame.new(targetPos + Vector3.new(0, 3, 0))

            local part = Instance.new("Part")
            part.Size = Vector3.new(2, 0.5, 2)
            part.Position = targetPos
            part.Anchored = true
            part.CanCollide = false
            part.BrickColor = BrickColor.new("Bright violet")
            part.Material = Enum.Material.Neon
            part.Transparency = 0.5
            part.Parent = workspace
            game:GetService("Debris"):AddItem(part, 0.5)
        end
    end

    tool.Equipped:Connect(function()
        tpEnabled = true
        Mouse.Icon = "rbxasset://SystemCursors/Crosshair"
        setStatus("TP Ready - Click to teleport", Color3.fromRGB(0,255,150))
    end)

    tool.Unequipped:Connect(function()
        tpEnabled = false
        Mouse.Icon = "rbxasset://SystemCursors/Arrow"
        setStatus("TP Off")
    end)

    tool.Activated:Connect(function()
        if tpEnabled then
            teleport(Mouse)
        end
    end)

    return tool
end

-- ========== PLAYER LIST FUNCTIONS (v8.2: mobile-friendly) ==========
local updatePlayerList

local function setAimTarget(plr)
    aimbotSelectedTarget = plr
    if plr then
        TargetStatus.Text = "Цель: " .. plr.Name
        TargetStatus.TextColor3 = Color3.fromRGB(0, 255, 100)
    else
        TargetStatus.Text = "Цель: авто (ближайший)"
        TargetStatus.TextColor3 = Color3.fromRGB(200, 200, 200)
    end
end

ResetTargetBtn.MouseButton1Click:Connect(function()
    setAimTarget(nil)
    updatePlayerList()
end)

local function makeRowButton(parent, text, xOffset, color)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 50, 0, 34)
    b.Position = UDim2.new(1, xOffset, 0.5, -17)
    b.Text = text
    b.TextColor3 = Color3.fromRGB(255, 255, 255)
    b.TextSize = 13
    b.Font = Enum.Font.GothamBold
    b.BackgroundColor3 = color
    b.BorderSizePixel = 0
    b.Parent = parent
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent = b
    return b
end

updatePlayerList = function()
    for _, child in ipairs(PlayerListContainer:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    local order = 0
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            order = order + 1
            local selected = (aimbotSelectedTarget == plr)

            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, 46)
            row.BackgroundColor3 = selected and Color3.fromRGB(20, 70, 45) or Color3.fromRGB(26, 26, 42)
            row.BorderSizePixel = 0
            row.LayoutOrder = order
            row.Parent = PlayerListContainer
            local rc = Instance.new("UICorner")
            rc.CornerRadius = UDim.new(0, 8)
            rc.Parent = row

            local name = Instance.new("TextLabel")
            name.Size = UDim2.new(1, -124, 1, 0)
            name.Position = UDim2.new(0, 10, 0, 0)
            name.BackgroundTransparency = 1
            name.Text = plr.Name
            name.TextColor3 = Color3.fromRGB(255, 255, 255)
            name.TextSize = 14
            name.Font = Enum.Font.Gotham
            name.TextXAlignment = Enum.TextXAlignment.Left
            name.TextTruncate = Enum.TextTruncate.AtEnd
            name.Parent = row

            local tpBtn = makeRowButton(row, "TP", -112, Color3.fromRGB(70, 35, 115))
            local aimBtn = makeRowButton(row, selected and "✓ AIM" or "AIM", -58,
                selected and Color3.fromRGB(0, 140, 70) or Color3.fromRGB(45, 45, 65))

            tpBtn.MouseButton1Click:Connect(function()
                local myChar, theirChar = LocalPlayer.Character, plr.Character
                local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
                local theirRoot = theirChar and theirChar:FindFirstChild("HumanoidRootPart")
                if myRoot and theirRoot then
                    myRoot.CFrame = theirRoot.CFrame + Vector3.new(0, 3, 0)
                    setStatus("Телепорт к " .. plr.Name, Color3.fromRGB(0, 255, 150))
                end
            end)

            -- tap AIM: select / unselect target (no right click needed)
            aimBtn.MouseButton1Click:Connect(function()
                setAimTarget(aimbotSelectedTarget == plr and nil or plr)
                updatePlayerList()
            end)
        end
    end
end

-- list refreshes itself when players join / leave
Players.PlayerAdded:Connect(function()
    if playerListEnabled then updatePlayerList() end
end)
Players.PlayerRemoving:Connect(function(plr)
    if aimbotSelectedTarget == plr then setAimTarget(nil) end
    task.defer(function()
        if playerListEnabled then updatePlayerList() end
    end)
end)

-- ========== AIMBOT ENGINE ==========
local function getAimbotTarget()
    if aimbotSelectedTarget and aimbotSelectedTarget.Character and aimbotSelectedTarget.Character:FindFirstChild("Head") then
        return aimbotSelectedTarget
    end

    local closest = nil
    local minDist = aimbotFOV
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Head") then
            local head = plr.Character.Head
            local pos, onScreen = Camera:WorldToScreenPoint(head.Position)
            if onScreen then
                local dist = (Vector2.new(pos.X, pos.Y) - Vector2.new(Mouse.X, Mouse.Y)).Magnitude
                if dist < minDist then
                    minDist = dist
                    closest = plr
                end
            end
        end
    end
    return closest
end

RunService.RenderStepped:Connect(function()
    -- FOV Circle Position Update
    if fovCircle then
        fovCircle.Position = Vector2.new(Mouse.X, Mouse.Y + 36)
        fovCircle.Radius = aimbotFOV
        fovCircle.Visible = aimbotEnabled and fovCircleVisible
    end

    -- Aimbot Loop
    if aimbotEnabled then
        local target = getAimbotTarget()
        if target and target.Character and target.Character:FindFirstChild("Head") then
            local head = target.Character.Head
            local targetPos = head.Position
            local currentCFrame = Camera.CFrame
            local newCFrame = CFrame.new(currentCFrame.Position, targetPos)

            if aimbotSmoothness > 1 then
                Camera.CFrame = currentCFrame:Lerp(newCFrame, 1 / aimbotSmoothness)
            else
                Camera.CFrame = newCFrame
            end
        end
    end
end)

-- ========== TRIGGERBOT ENGINE ==========
RunService.RenderStepped:Connect(function()
    if triggerbotEnabled then
        local target = Mouse.Target
        if target and target.Parent then
            local plr = Players:GetPlayerFromCharacter(target.Parent)
            if plr and plr ~= LocalPlayer then
                mouse1click()
            end
        end
    end
end)

-- ========== CREATING ALL TOGGLES & SLIDERS (grouped by tabs) ==========

-- ===== TAB: COMBAT =====
createTab("Combat")
createSection("Aimbot")
createTumbler("Aimbot", false).onToggle(function(st) aimbotEnabled = st setStatus(st and "Aimbot ON" or "Aimbot OFF") end)
createTumbler("Aimbot FOV Circle", true).onToggle(function(st) fovCircleVisible = st end)
createSlider("Aimbot FOV", 10, 400, 90, function(val) aimbotFOV = val end)
createSlider("Aimbot Smooth", 1, 20, 5, function(val) aimbotSmoothness = val end)
createTumbler("Triggerbot (AutoShot)", false).onToggle(function(st) triggerbotEnabled = st end)
createSection("Hitbox")
createTumbler("Hitbox Expander", false).onToggle(function(st)
    hitboxEnabled = st
    if not st then
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                plr.Character.HumanoidRootPart.Size = Vector3.new(2, 2, 1)
            end
        end
    end
end)
createSlider("Hitbox Size", 2, 20, 5, function(val) hitboxSize = val end)

-- ===== TAB: VISUALS =====
createTab("Visuals")
createSection("ESP")
createTumbler("ESP Boxes", true).onToggle(function(st) espBoxEnabled = st end)
createTumbler("ESP Tracers", true).onToggle(function(st) espTracerEnabled = st end)
createTumbler("ESP Names", true).onToggle(function(st) espNamesEnabled = st end)
createTumbler("ESP Distance & HP", true).onToggle(function(st) espDistanceEnabled = st espHealthEnabled = st end)
createTumbler("Wallhack (Highlight)", false).onToggle(function(st)
    wallhackEnabled = st
    if not st then
        for _, plr in pairs(Players:GetPlayers()) do
            if plr.Character and plr.Character:FindFirstChild("WIA_WH") then
                plr.Character.WIA_WH:Destroy()
            end
        end
    end
end)

-- ===== TAB: MOVE =====
createTab("Move")
createSection("Flight")
createTumbler("Flight", false).onToggle(function(st)
    flightEnabled = st
    flyUp, flyDown = false, false
    FlyGui.Enabled = st
    if st then
        startFlight()
        setStatus("Flight ON - joystick + ▲/▼ buttons", Color3.fromRGB(0, 255, 150))
    else
        stopFlight()
        setStatus("Flight OFF")
    end
end)
createSlider("Fly Speed", 10, 300, 50, function(val) flySpeed = val end)
createTumbler("Noclip", false).onToggle(function(st) noclipEnabled = st end)

createSection("Speed & Jump")
createTumbler("CFrame Speed (Bypass)", false).onToggle(function(st) cframeSpeedEnabled = st end)
createSlider("CFrame Speed Multiplier", 1, 10, 2, function(val) cframeSpeedValue = val end)

createSlider("Walk Speed", 16, 200, 16, function(val)
    walkSpeedValue = val
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = val
    end
end)

createSlider("Jump Power", 50, 200, 50, function(val)
    jumpPowerValue = val
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.JumpPower = val
    end
end)

createTumbler("Infinite Jump", false).onToggle(function(st) infiniteJumpEnabled = st end)
createTumbler("Bhop (FIXED)", false).onToggle(function(st) bhopEnabled = st end)
createSection("Spinbot")
createTumbler("Spinbot", false).onToggle(function(st) spinbotEnabled = st end)
createSlider("Spinbot Speed", 5, 50, 20, function(val) spinbotSpeed = val end)

-- ===== TAB: PLAYER =====
createTab("Player")
createSection("Protection")
createTumbler("Godmode", false).onToggle(function(st)
    godmodeEnabled = st
    if st and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.Health = LocalPlayer.Character.Humanoid.MaxHealth
    end
end)
createTumbler("Anti-Void", false).onToggle(function(st) antiVoidEnabled = st end)
createTumbler("Anti-Fall Damage", false).onToggle(function(st) antiFallEnabled = st end)
createTumbler("Anti-AFK", false).onToggle(function(st) antiAFKEnabled = st end)
createSection("Players & Teleport")
playerListTumbler = createTumbler("Player List GUI", false)
playerListTumbler.onToggle(function(st)
    playerListEnabled = st
    PlayerListGui.Enabled = st
    if st then updatePlayerList() end
end)

-- TELEPORT TOOL
createTumbler("Teleport Tool", false).onToggle(function(st)
    if st then
        if not tpTool then
            tpTool = createTPTool()
            tpTool.Parent = LocalPlayer.Backpack
            setStatus("Teleport Tool added to backpack!", Color3.fromRGB(0,255,150))
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("Humanoid") then
                char.Humanoid:EquipTool(tpTool)
            end
        end
    else
        if tpTool then
            tpTool:Destroy()
            tpTool = nil
        end
        setStatus("Teleport Tool removed", Color3.fromRGB(255,150,0))
    end
end)

-- ===== TAB: WORLD =====
createTab("World")
createSection("Lighting")
createTumbler("FullBright", false).onToggle(function(st)
    fullBrightEnabled = st
    if st then
        originalBrightness = Lighting.Brightness
        originalAmbient = Lighting.Ambient
        Lighting.Brightness = 2
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
    else
        if originalBrightness then Lighting.Brightness = originalBrightness end
        if originalAmbient then Lighting.Ambient = originalAmbient end
    end
end)

createTumbler("No Fog (FPS Boost)", false).onToggle(function(st)
    noFogEnabled = st
    if st then
        originalFog = Lighting.FogEnd
        Lighting.FogEnd = 1e6
    else
        if originalFog then Lighting.FogEnd = originalFog end
    end
end)

createSection("Camera")
createSlider("Camera FOV", 50, 120, 70, function(val) Camera.FieldOfView = val end)

-- ===== TAB: MISC =====
createTab("Misc")
createSection("Automation")
createTumbler("AutoClicker", false).onToggle(function(st) autoClickerEnabled = st end)
createSlider("Click Delay (ms)", 10, 1000, 100, function(val) autoClickerDelay = val end)
createTumbler("Chat Spam", false).onToggle(function(st) chatSpamEnabled = st end)

-- REJOIN & SERVER HOP BUTTONS
createSection("Server")
createButton("Rejoin Server", function()
    TeleportService:Teleport(game.PlaceId, LocalPlayer)
end)

createButton("Server Hop", function()
    local servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100")).data
    for _, s in pairs(servers) do
        if s.playing < s.maxPlayers and s.id ~= game.JobId then
            TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LocalPlayer)
            break
        end
    end
end)

-- open first tab
selectTab("Combat")

-- ========== GAME LOOPS & HEARTBEAT ==========

-- Flight Loop (FIXED: works with the mobile joystick and on-screen ▲/▼ buttons)
RunService.Heartbeat:Connect(function()
    if not flightEnabled then return end

    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not (root and hum) then return end

    -- flight objects were destroyed (respawn etc.) -> recreate
    if not bodyVelocity or not bodyVelocity.Parent or not bodyGyro or not bodyGyro.Parent then
        startFlight()
        if not bodyVelocity then return end
    end

    local moveDir = Vector3.new(0, 0, 0)

    -- Joystick (mobile) and WASD (PC): Humanoid.MoveDirection works for both
    local md = hum.MoveDirection
    if md.Magnitude > 0.01 then
        local camCF = Camera.CFrame
        local look = camCF.LookVector
        local right = camCF.RightVector
        local flatLook = Vector3.new(look.X, 0, look.Z)
        if flatLook.Magnitude < 0.01 then
            -- camera looks straight up/down: use the camera's up vector instead
            flatLook = Vector3.new(camCF.UpVector.X, 0, camCF.UpVector.Z)
        end
        local flatRight = Vector3.new(right.X, 0, right.Z)
        if flatLook.Magnitude > 0.01 and flatRight.Magnitude > 0.01 then
            local fwd = md:Dot(flatLook.Unit)
            local side = md:Dot(flatRight.Unit)
            -- forward follows the camera pitch, so you fly up/down where you look
            moveDir = look * fwd + right * side
        end
    end

    -- Up / Down: on-screen buttons (mobile) or Space / LeftShift (PC)
    if flyUp or UserInputService:IsKeyDown(Enum.KeyCode.Space) then
        moveDir = moveDir + Vector3.new(0, 1, 0)
    end
    if flyDown or UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
        moveDir = moveDir - Vector3.new(0, 1, 0)
    end

    if moveDir.Magnitude > 0.01 then
        bodyVelocity.Velocity = moveDir.Unit * flySpeed
        bodyGyro.CFrame = CFrame.new(root.Position, root.Position + moveDir)
    else
        bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    end
end)

-- CFrame Speed Loop
RunService.Heartbeat:Connect(function()
    if cframeSpeedEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and LocalPlayer.Character:FindFirstChild("Humanoid") then
        local hum = LocalPlayer.Character.Humanoid
        local root = LocalPlayer.Character.HumanoidRootPart
        if hum.MoveDirection.Magnitude > 0 then
            root.CFrame = root.CFrame + (hum.MoveDirection * (cframeSpeedValue / 10))
        end
    end
end)

-- BHOP (FIXED)
RunService.Heartbeat:Connect(function()
    if bhopEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        local hum = LocalPlayer.Character.Humanoid
        if hum.MoveDirection.Magnitude > 0 and hum.FloorMaterial ~= Enum.Material.Air then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

-- Spinbot Loop
RunService.RenderStepped:Connect(function()
    if spinbotEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame = LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(spinbotSpeed), 0)
    end
end)

-- Noclip & Hitbox Expander & Godmode Loop
RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    if char then
        if noclipEnabled then
            for _, p in pairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end
        if godmodeEnabled and char:FindFirstChild("Humanoid") then
            char.Humanoid.Health = char.Humanoid.MaxHealth
        end
    end

    if hitboxEnabled then
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                plr.Character.HumanoidRootPart.Size = Vector3.new(hitboxSize, hitboxSize, hitboxSize)
                plr.Character.HumanoidRootPart.Transparency = 0.7
            end
        end
    end
end)

-- Anti-Void Loop
RunService.Heartbeat:Connect(function()
    if antiVoidEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        if LocalPlayer.Character.HumanoidRootPart.Position.Y < -50 then
            local spawn = workspace:FindFirstChild("SpawnLocation")
            if spawn then
                LocalPlayer.Character.HumanoidRootPart.CFrame = spawn.CFrame + Vector3.new(0, 3, 0)
            end
        end
    end
end)

-- Anti-Fall
RunService.Heartbeat:Connect(function()
    if antiFallEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        local hum = LocalPlayer.Character.Humanoid
        if hum:GetState() == Enum.HumanoidStateType.FallingDown then
            hum:ChangeState(Enum.HumanoidStateType.Landed)
        end
    end
end)

-- AutoClicker Loop
task.spawn(function()
    while true do
        task.wait(autoClickerDelay / 1000)
        if autoClickerEnabled then
            mouse1click()
        end
    end
end)

-- Chat Spam Loop
task.spawn(function()
    while true do
        task.wait(chatSpamDelay)
        if chatSpamEnabled then
            local chatEvents = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
            if chatEvents and chatEvents:FindFirstChild("SayMessageRequest") then
                chatEvents.SayMessageRequest:FireServer(chatSpamMessage, "All")
            end
        end
    end
end)

-- Anti-AFK Loop
local vu = game:GetService("VirtualUser")
LocalPlayer.Idled:Connect(function()
    if antiAFKEnabled then
        vu:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        vu:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    end
end)

-- Infinite Jump
UserInputService.JumpRequest:Connect(function()
    if infiniteJumpEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- ========== ADVANCED DRAWING ESP ENGINE ==========
local PURPLE = Color3.fromRGB(180, 0, 255)

RunService.RenderStepped:Connect(function()
    -- Clear drawings
    for i = #espLines, 1, -1 do espLines[i]:Remove() espLines[i] = nil end
    for i = #tracerLines, 1, -1 do tracerLines[i]:Remove() tracerLines[i] = nil end
    for i = #textDrawings, 1, -1 do textDrawings[i]:Remove() textDrawings[i] = nil end

    if not (espBoxEnabled or espTracerEnabled or espNamesEnabled or espDistanceEnabled) then return end

    local camPos = Camera.CFrame.Position
    local viewport = Camera.ViewportSize

    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Head") and plr.Character:FindFirstChild("Humanoid") then
            local head = plr.Character.Head
            local hum = plr.Character.Humanoid
            local pos, onScreen = Camera:WorldToScreenPoint(head.Position)

            if onScreen then
                local dist = math.floor((head.Position - camPos).Magnitude)
                local size = math.clamp(100 / dist * 10, 15, 45)

                -- ESP Box
                if espBoxEnabled then
                    local lines = { Drawing.new("Line"), Drawing.new("Line"), Drawing.new("Line"), Drawing.new("Line") }
                    local x, y = pos.X - size/2, pos.Y - size/2
                    lines[1].From = Vector2.new(x, y) lines[1].To = Vector2.new(x + size, y)
                    lines[2].From = Vector2.new(x + size, y) lines[2].To = Vector2.new(x + size, y + size)
                    lines[3].From = Vector2.new(x + size, y + size) lines[3].To = Vector2.new(x, y + size)
                    lines[4].From = Vector2.new(x, y + size) lines[4].To = Vector2.new(x, y)

                    for j = 1, 4 do
                        lines[j].Color = PURPLE
                        lines[j].Thickness = 2
                        lines[j].Transparency = 1
                        lines[j].Visible = true
                        espLines[#espLines + 1] = lines[j]
                    end
                end

                -- ESP Tracers
                if espTracerEnabled then
                    local tracer = Drawing.new("Line")
                    tracer.From = Vector2.new(viewport.X / 2, viewport.Y)
                    tracer.To = Vector2.new(pos.X, pos.Y)
                    tracer.Color = PURPLE
                    tracer.Thickness = 1.5
                    tracer.Transparency = 0.7
                    tracer.Visible = true
                    tracerLines[#tracerLines + 1] = tracer
                end

                -- ESP Text Info (Names, HP, Distance)
                if espNamesEnabled or espDistanceEnabled then
                    local text = Drawing.new("Text")
                    text.Position = Vector2.new(pos.X, pos.Y - size/2 - 15)
                    text.Size = 13
                    text.Center = true
                    text.Outline = true
                    text.Color = Color3.fromRGB(255, 255, 255)

                    local content = ""
                    if espNamesEnabled then content = content .. plr.Name .. " " end
                    if espHealthEnabled then content = content .. "[" .. math.floor(hum.Health) .. "HP] " end
                    if espDistanceEnabled then content = content .. "(" .. dist .. "m)" end

                    text.Text = content
                    text.Visible = true
                    textDrawings[#textDrawings + 1] = text
                end
            end
        end
    end
end)

-- Wallhack Auto-Apply
RunService.Heartbeat:Connect(function()
    if wallhackEnabled then
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character and not plr.Character:FindFirstChild("WIA_WH") then
                local hl = Instance.new("Highlight")
                hl.Name = "WIA_WH"
                hl.FillColor = Color3.fromRGB(180, 0, 255)
                hl.FillTransparency = 0.3
                hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                hl.Parent = plr.Character
            end
        end
    end
end)

setStatus("WIA HUB v8.2 Loaded! | Mobile player list", Color3.fromRGB(0, 255, 150))