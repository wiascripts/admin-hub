-- ================================================================= --
-- WIA HUB v10.0 Ultimate :: whitewia / tordark
-- Soft dark theme (no neon) + Skeleton ESP + Chams + Silent Aim
-- + Dash + Anti-Fling + Anti-Ragdoll + Notifications + Watermark
-- + Loading Screen + Hub Toggle Keybind + Fixed Flight
-- ================================================================= --

local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local Lighting          = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService   = game:GetService("TeleportService")
local HttpService       = game:GetService("HttpService")
local TweenService      = game:GetService("TweenService")
local InsertService     = game:GetService("InsertService")
local Stats             = game:GetService("Stats")
local Debris            = game:GetService("Debris")
local CoreGui           = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera      = workspace.CurrentCamera
local Mouse       = LocalPlayer:GetMouse()

-- ========== COLOR PALETTE (soft, no neon) ==========
local C_BG     = Color3.fromRGB(18, 18, 24)
local C_PANEL  = Color3.fromRGB(26, 26, 34)
local C_ROW    = Color3.fromRGB(32, 32, 42)
local C_ROW_D  = Color3.fromRGB(26, 26, 34)
local C_ACCENT = Color3.fromRGB(124, 92, 255)
local C_TEXT   = Color3.fromRGB(232, 232, 240)
local C_DIM    = Color3.fromRGB(140, 140, 158)
local C_STROKE = Color3.fromRGB(50, 50, 65)
local C_OK     = Color3.fromRGB(90, 200, 130)
local C_ERR    = Color3.fromRGB(210, 90, 90)

local function addCorner(obj, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = obj
    return c
end

-- ========== NOTIFICATIONS SYSTEM ==========
local NotifGui = Instance.new("ScreenGui")
NotifGui.Name = "WiaNotifs_v10"
NotifGui.ResetOnSpawn = false
NotifGui.DisplayOrder = 200
NotifGui.Parent = CoreGui

local NotifHolder = Instance.new("Frame")
NotifHolder.Size = UDim2.new(0, 260, 0, 400)
NotifHolder.Position = UDim2.new(1, -272, 0, 20)
NotifHolder.BackgroundTransparency = 1
NotifHolder.Parent = NotifGui

local NotifLayout = Instance.new("UIListLayout")
NotifLayout.Padding = UDim.new(0, 8)
NotifLayout.SortOrder = Enum.SortOrder.LayoutOrder
NotifLayout.VerticalAlignment = Enum.VerticalAlignment.Top
NotifLayout.Parent = NotifHolder

local notifOrder = 0
local function notify(text, kind)
    notifOrder = notifOrder + 1
    local color = kind == "error" and C_ERR or kind == "success" and C_OK or C_ACCENT
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, 0, 0, 46)
    frame.BackgroundColor3 = C_PANEL
    frame.BorderSizePixel = 0
    frame.LayoutOrder = notifOrder
    frame.ClipsDescendants = true
    frame.Parent = NotifHolder
    addCorner(frame, 10)

    local accent = Instance.new("Frame")
    accent.Size = UDim2.new(0, 3, 1, 0)
    accent.BackgroundColor3 = color
    accent.BorderSizePixel = 0
    accent.Parent = frame
    addCorner(accent, 2)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -22, 1, 0)
    lbl.Position = UDim2.new(0, 14, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = C_TEXT
    lbl.TextSize = 13
    lbl.Font = Enum.Font.Gotham
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.TextWrapped = true
    lbl.Parent = frame

    local scale = Instance.new("UIScale")
    scale.Scale = 0.85
    scale.Parent = frame
    TweenService:Create(scale, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()

    task.delay(2.6, function()
        TweenService:Create(frame, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
        TweenService:Create(lbl, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
        TweenService:Create(accent, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
        task.wait(0.3)
        frame:Destroy()
    end)
end

-- ========== LOADING SCREEN ==========
local LoadingGui = Instance.new("ScreenGui")
LoadingGui.Name = "WiaLoading_v10"
LoadingGui.IgnoreGuiInset = true
LoadingGui.ResetOnSpawn = false
LoadingGui.DisplayOrder = 999
LoadingGui.Parent = CoreGui

local LoadingBg = Instance.new("Frame")
LoadingBg.Size = UDim2.new(1, 0, 1, 0)
LoadingBg.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
LoadingBg.BorderSizePixel = 0
LoadingBg.Parent = LoadingGui

local LoadingTitle = Instance.new("TextLabel")
LoadingTitle.Size = UDim2.new(0, 400, 0, 60)
LoadingTitle.Position = UDim2.new(0.5, -200, 0.5, -85)
LoadingTitle.BackgroundTransparency = 1
LoadingTitle.Text = "WIA HUB"
LoadingTitle.TextColor3 = C_ACCENT
LoadingTitle.TextSize = 46
LoadingTitle.Font = Enum.Font.GothamBold
LoadingTitle.Parent = LoadingBg

local LoadingSub = Instance.new("TextLabel")
LoadingSub.Size = UDim2.new(0, 400, 0, 22)
LoadingSub.Position = UDim2.new(0.5, -200, 0.5, -22)
LoadingSub.BackgroundTransparency = 1
LoadingSub.Text = "v10.0 Ultimate Edition"
LoadingSub.TextColor3 = C_DIM
LoadingSub.TextSize = 13
LoadingSub.Font = Enum.Font.Gotham
LoadingSub.Parent = LoadingBg

local LoadingBarBg = Instance.new("Frame")
LoadingBarBg.Size = UDim2.new(0, 320, 0, 4)
LoadingBarBg.Position = UDim2.new(0.5, -160, 0.5, 30)
LoadingBarBg.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
LoadingBarBg.BorderSizePixel = 0
LoadingBarBg.Parent = LoadingBg
addCorner(LoadingBarBg, 2)

local LoadingBar = Instance.new("Frame")
LoadingBar.Size = UDim2.new(0, 0, 1, 0)
LoadingBar.BackgroundColor3 = C_ACCENT
LoadingBar.BorderSizePixel = 0
LoadingBar.Parent = LoadingBarBg
addCorner(LoadingBar, 2)

local LoadingStatus = Instance.new("TextLabel")
LoadingStatus.Size = UDim2.new(0, 400, 0, 20)
LoadingStatus.Position = UDim2.new(0.5, -200, 0.5, 46)
LoadingStatus.BackgroundTransparency = 1
LoadingStatus.Text = "0%"
LoadingStatus.TextColor3 = C_DIM
LoadingStatus.TextSize = 12
LoadingStatus.Font = Enum.Font.Gotham
LoadingStatus.Parent = LoadingBg

task.spawn(function()
    local steps = {
        { pct = 25, t = 0.35, msg = "инициализация..." },
        { pct = 55, t = 0.35, msg = "загрузка модулей..." },
        { pct = 85, t = 0.35, msg = "сборка интерфейса..." },
        { pct = 100, t = 0.4, msg = "готово" },
    }
    for _, s in ipairs(steps) do
        TweenService:Create(LoadingBar, TweenInfo.new(s.t, Enum.EasingStyle.Quad), {
            Size = UDim2.new(s.pct / 100, 0, 1, 0),
        }):Play()
        LoadingStatus.Text = s.msg .. "  " .. s.pct .. "%"
        task.wait(s.t)
    end
    task.wait(0.25)
    TweenService:Create(LoadingBg, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
    for _, o in ipairs(LoadingBg:GetDescendants()) do
        if o:IsA("TextLabel") then
            TweenService:Create(o, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
        elseif o:IsA("Frame") then
            TweenService:Create(o, TweenInfo.new(0.4), { BackgroundTransparency = 1 }):Play()
        end
    end
    task.wait(0.4)
    LoadingGui:Destroy()
    notify("WIA HUB v10.0 загружен", "success")
end)

-- ========== STATE ==========
local flightEnabled, noclipEnabled           = false, false
local flySpeed                               = 50
local bodyVelocity, bodyGyro                 = nil, nil
local savedGravity                           = workspace.Gravity
local flyUp, flyDown                         = false, false

local cframeSpeedEnabled, cframeSpeedValue   = false, 2
local walkSpeedValue, jumpPowerValue         = 16, 50
local infiniteJumpEnabled, bhopEnabled       = false, false
local spinbotEnabled, spinbotSpeed           = false, 20

local godmodeEnabled                         = false
local tpToolEnabled, tpEnabled               = false, false
local wallhackEnabled, chamsOpacity          = false, 0.35
local antiAFKEnabled, playerListEnabled      = false, false
local antiVoidEnabled, antiFallEnabled       = false, false
local antiFlingEnabled, antiRagdollEnabled   = false, false
local fullBrightEnabled, noFogEnabled        = false, false
local originalBrightness, originalAmbient, originalFog = nil, nil, nil

local aimbotEnabled, aimbotFOV               = false, 90
local aimbotSmoothness                       = 5
local aimbotSelectedTarget                   = nil
local fovCircleVisible                       = true
local silentAimEnabled                       = false

local hitboxEnabled, hitboxSize              = false, 5
local autoClickerEnabled, autoClickerDelay   = false, 100
local triggerbotEnabled                      = false
local chatSpamEnabled, chatSpamDelay         = false, 5
local chatSpamMessage                        = "WIA HUB ON TOP"

local espBoxEnabled, espTracerEnabled        = true, true
local espNamesEnabled, espDistanceEnabled    = true, true
local espHealthEnabled, skeletonEnabled      = true, false
local skeletonColor                          = Color3.fromRGB(124, 92, 255)

local dashEnabled, dashPower                 = false, 90
local dashKey                                = Enum.KeyCode.Q
local dashCooldown, dashLastUsed             = 0.4, 0

local hubToggleKey                           = Enum.KeyCode.RightShift
local guiVisible                             = true
local waitingHubBind                         = false

-- Drawing FOV circle
local fovCircle
if Drawing then
    fovCircle = Drawing.new("Circle")
    fovCircle.Thickness = 1.5
    fovCircle.NumSides = 60
    fovCircle.Radius = aimbotFOV
    fovCircle.Filled = false
    fovCircle.Visible = false
    fovCircle.Color = C_ACCENT
end

-- ========== WATERMARK ==========
local WatermarkGui = Instance.new("ScreenGui")
WatermarkGui.Name = "WiaWm_v10"
WatermarkGui.ResetOnSpawn = false
WatermarkGui.DisplayOrder = 50
WatermarkGui.Parent = CoreGui

local Watermark = Instance.new("Frame")
Watermark.Size = UDim2.new(0, 250, 0, 44)
Watermark.Position = UDim2.new(0, 12, 0, 12)
Watermark.BackgroundColor3 = C_PANEL
Watermark.BackgroundTransparency = 0.15
Watermark.BorderSizePixel = 0
Watermark.Parent = WatermarkGui
addCorner(Watermark, 10)

local wmStroke = Instance.new("UIStroke")
wmStroke.Color = C_STROKE
wmStroke.Thickness = 1
wmStroke.Transparency = 0.3
wmStroke.Parent = Watermark

local wmAccent = Instance.new("Frame")
wmAccent.Size = UDim2.new(0, 3, 1, 0)
wmAccent.BackgroundColor3 = C_ACCENT
wmAccent.BorderSizePixel = 0
wmAccent.Parent = Watermark
addCorner(wmAccent, 2)

local wmTitle = Instance.new("TextLabel")
wmTitle.Size = UDim2.new(1, -20, 0, 20)
wmTitle.Position = UDim2.new(0, 14, 0, 4)
wmTitle.BackgroundTransparency = 1
wmTitle.Text = "WIA HUB v10.0"
wmTitle.TextColor3 = C_TEXT
wmTitle.TextSize = 13
wmTitle.Font = Enum.Font.GothamBold
wmTitle.TextXAlignment = Enum.TextXAlignment.Left
wmTitle.Parent = Watermark

local wmStats = Instance.new("TextLabel")
wmStats.Size = UDim2.new(1, -20, 0, 16)
wmStats.Position = UDim2.new(0, 14, 0, 23)
wmStats.BackgroundTransparency = 1
wmStats.Text = "60 FPS  ·  0 ms  ·  " .. LocalPlayer.Name
wmStats.TextColor3 = C_DIM
wmStats.TextSize = 11
wmStats.Font = Enum.Font.Gotham
wmStats.TextXAlignment = Enum.TextXAlignment.Left
wmStats.Parent = Watermark

local frameCount, fps = 0, 0
task.spawn(function()
    while Watermark.Parent do
        frameCount = 0
        task.wait(1)
        fps = frameCount
    end
end)
RunService.RenderStepped:Connect(function() frameCount = frameCount + 1 end)

task.spawn(function()
    while Watermark.Parent do
        local ok, ping = pcall(function()
            return math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
        end)
        wmStats.Text = string.format("%d FPS  ·  %d ms  ·  %s",
            fps, ok and ping or 0, LocalPlayer.Name)
        task.wait(0.5)
    end
end)

-- ========== PLAYER LIST GUI ==========
local playerListTumbler

local PlayerListGui = Instance.new("ScreenGui")
PlayerListGui.Name = "WiaPlayerList_v10"
PlayerListGui.ResetOnSpawn = false
PlayerListGui.Parent = CoreGui
PlayerListGui.Enabled = false

local plViewport = workspace.CurrentCamera.ViewportSize
local plW = math.clamp(plViewport.X * 0.5, 240, 320)
local plH = math.clamp(plViewport.Y - 80, 200, 400)

local PlayerListMain = Instance.new("Frame")
PlayerListMain.Size = UDim2.new(0, plW, 0, plH)
PlayerListMain.Position = UDim2.new(1, -plW - 70, 0, 70)
PlayerListMain.BackgroundColor3 = C_BG
PlayerListMain.BackgroundTransparency = 0.1
PlayerListMain.BorderSizePixel = 0
PlayerListMain.ClipsDescendants = true
PlayerListMain.Parent = PlayerListGui
addCorner(PlayerListMain, 12)

local plStroke = Instance.new("UIStroke")
plStroke.Color = C_STROKE
plStroke.Thickness = 1
plStroke.Transparency = 0.2
plStroke.Parent = PlayerListMain

local PlayerListTitle = Instance.new("TextLabel")
PlayerListTitle.Size = UDim2.new(1, -56, 0, 36)
PlayerListTitle.Position = UDim2.new(0, 14, 0, 0)
PlayerListTitle.Text = "ИГРОКИ"
PlayerListTitle.TextColor3 = C_ACCENT
PlayerListTitle.TextSize = 14
PlayerListTitle.TextXAlignment = Enum.TextXAlignment.Left
PlayerListTitle.BackgroundTransparency = 1
PlayerListTitle.Font = Enum.Font.GothamBold
PlayerListTitle.Parent = PlayerListMain

local PlayerListClose = Instance.new("TextButton")
PlayerListClose.Size = UDim2.new(0, 30, 0, 26)
PlayerListClose.Position = UDim2.new(1, -38, 0, 5)
PlayerListClose.Text = "✕"
PlayerListClose.TextColor3 = C_DIM
PlayerListClose.TextSize = 14
PlayerListClose.Font = Enum.Font.GothamBold
PlayerListClose.BackgroundColor3 = C_ROW
PlayerListClose.BorderSizePixel = 0
PlayerListClose.Parent = PlayerListMain
addCorner(PlayerListClose, 6)
PlayerListClose.MouseButton1Click:Connect(function()
    if playerListTumbler then playerListTumbler.setState(false) else PlayerListGui.Enabled = false end
end)

local playerListScrollingFrame = Instance.new("ScrollingFrame")
playerListScrollingFrame.Size = UDim2.new(1, -8, 1, -84)
playerListScrollingFrame.Position = UDim2.new(0, 4, 0, 38)
playerListScrollingFrame.BackgroundTransparency = 1
playerListScrollingFrame.BorderSizePixel = 0
playerListScrollingFrame.ScrollBarThickness = 3
playerListScrollingFrame.ScrollBarImageColor3 = C_ACCENT
playerListScrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
playerListScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
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

local PlayerListContainer = playerListScrollingFrame

local TargetStatus = Instance.new("TextLabel")
TargetStatus.Size = UDim2.new(1, -96, 0, 36)
TargetStatus.Position = UDim2.new(0, 14, 1, -42)
TargetStatus.BackgroundTransparency = 1
TargetStatus.Text = "Цель: авто (ближайший)"
TargetStatus.TextColor3 = C_DIM
TargetStatus.TextXAlignment = Enum.TextXAlignment.Left
TargetStatus.TextTruncate = Enum.TextTruncate.AtEnd
TargetStatus.Font = Enum.Font.Gotham
TargetStatus.TextSize = 12
TargetStatus.Parent = PlayerListMain

local ResetTargetBtn = Instance.new("TextButton")
ResetTargetBtn.Size = UDim2.new(0, 66, 0, 30)
ResetTargetBtn.Position = UDim2.new(1, -74, 1, -38)
ResetTargetBtn.Text = "СБРОС"
ResetTargetBtn.TextColor3 = C_TEXT
ResetTargetBtn.TextSize = 11
ResetTargetBtn.Font = Enum.Font.GothamBold
ResetTargetBtn.BackgroundColor3 = C_ROW
ResetTargetBtn.BorderSizePixel = 0
ResetTargetBtn.Parent = PlayerListMain
addCorner(ResetTargetBtn, 8)

-- ========== DRAG ==========
local function makeDraggable(frame, handle)
    handle = handle or frame
    local dragging, dragInput, dragStart, startPos = false, nil, nil, nil
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging, dragStart, startPos = true, input.Position, frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
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
            local d = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + d.X,
                startPos.Y.Scale, startPos.Y.Offset + d.Y
            )
        end
    end)
end

-- ========== MAIN GUI ==========
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "WiaHubGUI_v10"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui
ScreenGui.Enabled = false

local vp0 = Camera.ViewportSize
local menuW = math.clamp(vp0.X - 20, 250, 330)
local menuH = math.clamp(vp0.Y - 40, 240, 470)

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, menuW, 0, menuH)
MainFrame.Position = UDim2.new(0, 12, 0, 12)
MainFrame.BackgroundColor3 = C_BG
MainFrame.BackgroundTransparency = 0.05
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent = ScreenGui
addCorner(MainFrame, 12)

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = C_STROKE
mainStroke.Thickness = 1
mainStroke.Transparency = 0.15
mainStroke.Parent = MainFrame

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, -50, 0, 34)
Title.Position = UDim2.new(0, 14, 0, 0)
Title.Text = "WIA HUB"
Title.TextColor3 = C_TEXT
Title.TextSize = 16
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBold
Title.Parent = MainFrame

local TitleVer = Instance.new("TextLabel")
TitleVer.Size = UDim2.new(0, 40, 0, 34)
TitleVer.Position = UDim2.new(0, 76, 0, 0)
TitleVer.Text = "v10"
TitleVer.TextColor3 = C_DIM
TitleVer.TextSize = 11
TitleVer.TextXAlignment = Enum.TextXAlignment.Left
TitleVer.BackgroundTransparency = 1
TitleVer.Font = Enum.Font.Gotham
TitleVer.Parent = MainFrame

local Underline = Instance.new("Frame")
Underline.Size = UDim2.new(1, -24, 0, 1)
Underline.Position = UDim2.new(0, 12, 0, 34)
Underline.BackgroundColor3 = C_STROKE
Underline.BorderSizePixel = 0
Underline.Parent = MainFrame

local MinBtn = Instance.new("TextButton")
MinBtn.Size = UDim2.new(0, 26, 0, 24)
MinBtn.Position = UDim2.new(1, -32, 0, 5)
MinBtn.Text = "—"
MinBtn.TextColor3 = C_DIM
MinBtn.BackgroundColor3 = C_ROW
MinBtn.BorderSizePixel = 0
MinBtn.Font = Enum.Font.GothamBold
MinBtn.TextSize = 14
MinBtn.ZIndex = 5
MinBtn.Parent = MainFrame
addCorner(MinBtn, 6)

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

local PageHolder = Instance.new("Frame")
PageHolder.Size = UDim2.new(1, 0, 1, -98)
PageHolder.Position = UDim2.new(0, 0, 0, 74)
PageHolder.BackgroundTransparency = 1
PageHolder.ClipsDescendants = true
PageHolder.Parent = MainFrame

local StatusBar = Instance.new("TextLabel")
StatusBar.Size = UDim2.new(1, -20, 0, 20)
StatusBar.Position = UDim2.new(0, 12, 1, -22)
StatusBar.Text = "Ready"
StatusBar.TextColor3 = C_DIM
StatusBar.TextSize = 11
StatusBar.TextXAlignment = Enum.TextXAlignment.Left
StatusBar.BackgroundTransparency = 1
StatusBar.Font = Enum.Font.Gotham
StatusBar.Parent = MainFrame

local function setStatus(text, color)
    StatusBar.Text = text
    StatusBar.TextColor3 = color or C_DIM
end

local tabs, currentPage, tabCount = {}, nil, 0

local function selectTab(name)
    for n, t in pairs(tabs) do
        local on = (n == name)
        TweenService:Create(t.btn, TweenInfo.new(0.15), {
            BackgroundColor3 = on and C_ACCENT or C_ROW,
            TextColor3 = on and C_TEXT or C_DIM,
        }):Play()
        if on then
            t.page.Visible = true
            local s = t.page:FindFirstChildOfClass("UIScale") or Instance.new("UIScale")
            s.Parent = t.page
            s.Scale = 0.96
            TweenService:Create(s, TweenInfo.new(0.15, Enum.EasingStyle.Back), { Scale = 1 }):Play()
        else
            t.page.Visible = false
        end
    end
end

local function createTab(name)
    tabCount = tabCount + 1
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, math.max(58, #name * 8 + 22), 1, 0)
    btn.Text = name
    btn.TextSize = 12
    btn.Font = Enum.Font.GothamBold
    btn.BackgroundColor3 = C_ROW
    btn.TextColor3 = C_DIM
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
    page.ScrollBarImageColor3 = C_ACCENT
    page.AutomaticCanvasSize = Enum.AutomaticSize.Y
    page.CanvasSize = UDim2.new(0, 0, 0, 0)
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

local minimized = false
local fullSize = MainFrame.Size
MinBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    if minimized then
        fullSize = MainFrame.Size
        TabBar.Visible, PageHolder.Visible, StatusBar.Visible, Underline.Visible = false, false, false, false
        MainFrame.Size = UDim2.new(0, fullSize.X.Offset, 0, 34)
        MinBtn.Text = "+"
    else
        MainFrame.Size = fullSize
        TabBar.Visible, PageHolder.Visible, StatusBar.Visible, Underline.Visible = true, true, true, true
        MinBtn.Text = "—"
    end
end)

makeDraggable(MainFrame, Title)
makeDraggable(PlayerListMain, PlayerListTitle)

-- ========== TOGGLE ==========
local ToggleGui = Instance.new("ScreenGui")
ToggleGui.Name = "WiaToggle_v10"
ToggleGui.ResetOnSpawn = false
ToggleGui.Parent = CoreGui

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, 42, 0, 42)
ToggleBtn.Position = UDim2.new(1, -58, 0, 60)
ToggleBtn.Text = "W"
ToggleBtn.TextColor3 = C_TEXT
ToggleBtn.BackgroundColor3 = C_ACCENT
ToggleBtn.BackgroundTransparency = 0.1
ToggleBtn.BorderSizePixel = 0
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 18
ToggleBtn.Parent = ToggleGui
addCorner(ToggleBtn, 21)

local toggleStroke = Instance.new("UIStroke")
toggleStroke.Thickness = 1
toggleStroke.Color = C_STROKE
toggleStroke.Transparency = 0.3
toggleStroke.Parent = ToggleBtn

makeDraggable(ToggleBtn)

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

-- ========== FLY BUTTONS ==========
local FlyGui = Instance.new("ScreenGui")
FlyGui.Name = "WiaFly_v10"
FlyGui.ResetOnSpawn = false
FlyGui.Enabled = false
FlyGui.Parent = CoreGui

local function makeFlyButton(text, position, setHeld)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 52, 0, 52)
    b.Position = position
    b.Text = text
    b.TextColor3 = C_TEXT
    b.TextSize = 20
    b.Font = Enum.Font.GothamBold
    b.BackgroundColor3 = C_ACCENT
    b.BackgroundTransparency = 0.2
    b.BorderSizePixel = 0
    b.Parent = FlyGui
    addCorner(b, 26)
    b.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch
        or input.UserInputType == Enum.UserInputType.MouseButton1 then
            setHeld(true)
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then setHeld(false) end
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

makeFlyButton("▲", UDim2.new(1, -74, 0.5, -66), function(v) flyUp = v end)
makeFlyButton("▼", UDim2.new(1, -74, 0.5, 0), function(v) flyDown = v end)

-- ========== UI FACTORY ==========
local function createSection(text)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 18)
    lbl.Text = string.upper(text)
    lbl.TextColor3 = C_DIM
    lbl.TextSize = 10
    lbl.Font = Enum.Font.GothamBold
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.BackgroundTransparency = 1
    lbl.Parent = currentPage
    return lbl
end

local function createTumbler(labelText, defaultState, opts)
    opts = opts or {}
    local bindable = opts.bindable ~= false
    local row = Instance.new("TextButton")
    row.Size = UDim2.new(1, 0, 0, 40)
    row.BackgroundColor3 = C_ROW
    row.BorderSizePixel = 0
    row.AutoButtonColor = false
    row.Text = ""
    row.Parent = currentPage
    addCorner(row, 8)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -160, 1, 0)
    label.Position = UDim2.new(0, 12, 0, 0)
    label.Text = labelText
    label.TextColor3 = C_TEXT
    label.TextSize = 13
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextTruncate = Enum.TextTruncate.AtEnd
    label.Parent = row

    local pillX = bindable and UDim2.new(1, -118, 0.5, -11) or UDim2.new(1, -52, 0.5, -11)
    local pill = Instance.new("Frame")
    pill.Size = UDim2.new(0, 40, 0, 22)
    pill.Position = pillX
    pill.BackgroundColor3 = C_ROW_D
    pill.BorderSizePixel = 0
    pill.Parent = row
    addCorner(pill, 11)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = UDim2.new(0, 3, 0.5, -8)
    knob.BackgroundColor3 = C_DIM
    knob.BorderSizePixel = 0
    knob.Parent = pill
    addCorner(knob, 8)

    local state = defaultState or false
    local function update(instant)
        local kp = state and UDim2.new(1, -19, 0.5, -8) or UDim2.new(0, 3, 0.5, -8)
        local pc = state and C_ACCENT or C_ROW_D
        local kc = state and C_TEXT or C_DIM
        if instant then
            knob.Position, pill.BackgroundColor3, knob.BackgroundColor3 = kp, pc, kc
        else
            local ti = TweenInfo.new(0.12)
            TweenService:Create(knob, ti, { Position = kp, BackgroundColor3 = kc }):Play()
            TweenService:Create(pill, ti, { BackgroundColor3 = pc }):Play()
        end
    end
    update(true)

    local event = Instance.new("BindableEvent")
    row.MouseButton1Click:Connect(function()
        state = not state
        update()
        event:Fire(state)
    end)

    local bindKey, waitingBind = nil, false
    if bindable then
        local bindBtn = Instance.new("TextButton")
        bindBtn.Size = UDim2.new(0, 32, 0, 22)
        bindBtn.Position = UDim2.new(1, -76, 0.5, -11)
        bindBtn.Text = "⌨"
        bindBtn.TextColor3 = C_DIM
        bindBtn.BackgroundColor3 = C_ROW_D
        bindBtn.TextSize = 12
        bindBtn.Font = Enum.Font.GothamBold
        bindBtn.BorderSizePixel = 0
        bindBtn.Parent = row
        addCorner(bindBtn, 6)

        local resetBtn = Instance.new("TextButton")
        resetBtn.Size = UDim2.new(0, 28, 0, 22)
        resetBtn.Position = UDim2.new(1, -42, 0.5, -11)
        resetBtn.Text = "✕"
        resetBtn.TextColor3 = C_DIM
        resetBtn.BackgroundColor3 = C_ROW_D
        resetBtn.TextSize = 12
        resetBtn.Font = Enum.Font.GothamBold
        resetBtn.BorderSizePixel = 0
        resetBtn.Parent = row
        addCorner(resetBtn, 6)

        bindBtn.MouseButton1Click:Connect(function()
            if waitingBind then
                waitingBind = false
                bindBtn.Text = bindKey and bindKey.Name or "⌨"
                bindBtn.BackgroundColor3 = bindKey and Color3.fromRGB(45, 80, 60) or C_ROW_D
                return
            end
            waitingBind = true
            bindBtn.Text = "..."
            bindBtn.BackgroundColor3 = C_ACCENT
        end)

        resetBtn.MouseButton1Click:Connect(function()
            bindKey = nil
            waitingBind = false
            bindBtn.Text = "⌨"
            bindBtn.BackgroundColor3 = C_ROW_D
            notify("Бинд сброшен: " .. labelText)
        end)

        UserInputService.InputBegan:Connect(function(input, gp)
            if gp then return end
            if waitingBind and input.UserInputType == Enum.UserInputType.Keyboard then
                bindKey = input.KeyCode
                waitingBind = false
                bindBtn.Text = input.KeyCode.Name
                bindBtn.BackgroundColor3 = Color3.fromRGB(45, 80, 60)
                notify("Bind: " .. labelText .. " = " .. input.KeyCode.Name, "success")
            elseif bindKey and input.KeyCode == bindKey then
                state = not state
                update()
                event:Fire(state)
            end
        end)
    end

    return {
        getState = function() return state end,
        setState = function(n) state = n update() event:Fire(n) end,
        onToggle = function(cb) event.Event:Connect(cb) end,
    }
end

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
    row.BackgroundColor3 = C_ROW
    row.BorderSizePixel = 0
    row.Parent = page
    addCorner(row, 8)

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -90, 0, 30)
    label.Position = UDim2.new(0, 12, 0, 2)
    label.Text = labelText
    label.TextColor3 = C_TEXT
    label.TextSize = 13
    label.BackgroundTransparency = 1
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = row

    local textBox = Instance.new("TextBox")
    textBox.Size = UDim2.new(0, 56, 0, 24)
    textBox.Position = UDim2.new(1, -68, 0, 6)
    textBox.Text = tostring(defaultVal)
    textBox.TextColor3 = C_TEXT
    textBox.BackgroundColor3 = C_ROW_D
    textBox.BorderSizePixel = 0
    textBox.Font = Enum.Font.Gotham
    textBox.TextSize = 12
    textBox.ClearTextOnFocus = false
    textBox.Parent = row
    addCorner(textBox, 6)

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -28, 0, 4)
    track.Position = UDim2.new(0, 14, 0, 44)
    track.BackgroundColor3 = C_ROW_D
    track.BorderSizePixel = 0
    track.Parent = row
    addCorner(track, 2)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = C_ACCENT
    fill.BorderSizePixel = 0
    fill.Parent = track
    addCorner(fill, 2)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 14, 0, 14)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new(0, 0, 0.5, 0)
    knob.BackgroundColor3 = C_TEXT
    knob.BorderSizePixel = 0
    knob.ZIndex = 2
    knob.Parent = track
    addCorner(knob, 7)

    local hit = Instance.new("TextButton")
    hit.Size = UDim2.new(1, 0, 0, 26)
    hit.Position = UDim2.new(0, 0, 0, 32)
    hit.BackgroundTransparency = 1
    hit.Text = ""
    hit.Parent = row

    local value = defaultVal
    local function setVisual(v)
        local a = math.clamp((v - minVal) / (maxVal - minVal), 0, 1)
        fill.Size = UDim2.new(a, 0, 1, 0)
        knob.Position = UDim2.new(a, 0, 0.5, 0)
        textBox.Text = tostring(v)
    end
    setVisual(value)

    local function applyFromX(x)
        local a = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
        local v = math.floor(minVal + a * (maxVal - minVal) + 0.5)
        setVisual(v)
        if v ~= value then value = v callback(v) end
    end

    hit.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            activeSlider = { apply = applyFromX, input = input }
            page.ScrollingEnabled = false
            applyFromX(input.Position.X)
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    if activeSlider and activeSlider.input == input then activeSlider = nil end
                    page.ScrollingEnabled = true
                end
            end)
        end
    end)

    textBox.FocusLost:Connect(function()
        local num = tonumber(textBox.Text)
        if num then
            num = math.floor(math.clamp(num, minVal, maxVal) + 0.5)
            value = num setVisual(num) callback(num)
        else
            setVisual(value)
        end
    end)

    return { setValue = function(v) value = v setVisual(v) end }
end

local function createButton(labelText, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 0, 36)
    btn.Text = labelText
    btn.TextColor3 = C_TEXT
    btn.BackgroundColor3 = C_ROW
    btn.BorderSizePixel = 0
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.Parent = currentPage
    addCorner(btn, 8)

    local scale = Instance.new("UIScale")
    scale.Parent = btn
    btn.MouseButton1Down:Connect(function()
        TweenService:Create(scale, TweenInfo.new(0.08), { Scale = 0.96 }):Play()
    end)
    btn.MouseButton1Up:Connect(function()
        TweenService:Create(scale, TweenInfo.new(0.12, Enum.EasingStyle.Back), { Scale = 1 }):Play()
    end)
    btn.MouseButton1Click:Connect(callback)
    return btn
end

-- ========== FLIGHT (stable) ==========
local function stopFlight()
    if bodyVelocity then bodyVelocity:Destroy() bodyVelocity = nil end
    if bodyGyro then bodyGyro:Destroy() bodyGyro = nil end
    workspace.Gravity = savedGravity
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.PlatformStand = false
        pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
    end
end

local function startFlight()
    stopFlight()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not (root and hum) then return end

    savedGravity = workspace.Gravity
    workspace.Gravity = 0
    hum.PlatformStand = true

    bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(1e6, 1e6, 1e6)
    bodyVelocity.Velocity = Vector3.zero
    bodyVelocity.Parent = root

    bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(1e6, 1e6, 1e6)
    bodyGyro.P = 9e4
    bodyGyro.CFrame = root.CFrame
    bodyGyro.Parent = root
end

LocalPlayer.CharacterAdded:Connect(function(char)
    if flightEnabled then
        char:WaitForChild("HumanoidRootPart", 5)
        task.wait(0.2)
        if flightEnabled then startFlight() end
    end
end)

RunService.Heartbeat:Connect(function()
    if not flightEnabled then return end
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not (root and hum) then return end
    if not bodyVelocity or not bodyVelocity.Parent or not bodyGyro or not bodyGyro.Parent then
        startFlight()
        if not bodyVelocity then return end
    end

    local md = hum.MoveDirection
    local camCF = Camera.CFrame
    local look, right = camCF.LookVector, camCF.RightVector

    local move = Vector3.zero
    if md.Magnitude > 0.01 then
        local fl = Vector3.new(look.X, 0, look.Z)
        local fr = Vector3.new(right.X, 0, right.Z)
        if fl.Magnitude > 0.01 and fr.Magnitude > 0.01 then
            move = look * md:Dot(fl.Unit) + right * md:Dot(fr.Unit)
        end
    end
    if flyUp or UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.yAxis end
    if flyDown or UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move = move - Vector3.yAxis end

    if move.Magnitude > 0.01 then
        bodyVelocity.Velocity = move.Unit * flySpeed
        local t = root.Position + move.Unit
        if (t - root.Position).Magnitude > 0.01 then
            bodyGyro.CFrame = CFrame.lookAt(root.Position, t)
        end
    else
        bodyVelocity.Velocity = Vector3.zero
    end
end)

-- ========== TELEPORT TOOL ==========
local function createTPTool()
    local tool = Instance.new("Tool")
    tool.Name = "WIA_TP"
    tool.RequiresHandle = false
    tool.CanBeDropped = false

    tool.Equipped:Connect(function()
        tpEnabled = true
        Mouse.Icon = "rbxasset://SystemCursors/Crosshair"
        setStatus("TP Ready", C_OK)
    end)
    tool.Unequipped:Connect(function()
        tpEnabled = false
        Mouse.Icon = "rbxasset://SystemCursors/Arrow"
    end)
    tool.Activated:Connect(function()
        if not tpEnabled then return end
        local hit = Mouse.Hit
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if root and hit then
            root.CFrame = CFrame.new(hit.Position + Vector3.new(0, 3, 0))
            local p = Instance.new("Part")
            p.Size = Vector3.new(2, 0.5, 2)
            p.Position = hit.Position
            p.Anchored, p.CanCollide = true, false
            p.BrickColor = BrickColor.new("Bright violet")
            p.Material = Enum.Material.Neon
            p.Transparency = 0.5
            p.Parent = workspace
            Debris:AddItem(p, 0.5)
        end
    end)
    return tool
end

local function giveTPTool()
    local char = LocalPlayer.Character
    if not char then return end
    local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
    if not bp then return end
    if bp:FindFirstChild("WIA_TP") or char:FindFirstChild("WIA_TP") then return end
    createTPTool().Parent = bp
end

LocalPlayer.CharacterAdded:Connect(function(char)
    if tpToolEnabled then
        char:WaitForChild("Backpack", 5)
        task.wait(0.3)
        if tpToolEnabled then giveTPTool() end
    end
end)

-- ========== F3X ==========
local function loadF3X()
    local ok = pcall(function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/RegularVynixu/Utilities/main/F3X%20Building%20Tools.lua"))()
    end)
    if ok then return true end
    for _, id in ipairs({153181286, 144133059}) do
        local ok2 = pcall(function()
            local m = InsertService:LoadAsset(id)
            m.Parent = workspace
            local tool = m:FindFirstChildOfClass("Tool")
            if tool then tool.Parent = LocalPlayer.Backpack end
        end)
        if ok2 then return true end
    end
    return false
end

-- ========== SILENT AIM (namecall hook) ==========
if hookmetamethod and getnamecallmethod then
    local ok = pcall(function()
        local old
        old = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            if method == "FireServer" and silentAimEnabled then
                local target = aimbotSelectedTarget
                if not target then
                    local minDist = aimbotFOV
                    for _, p in pairs(Players:GetPlayers()) do
                        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
                            local s, onScreen = Camera:WorldToScreenPoint(p.Character.Head.Position)
                            if onScreen then
                                local d = (Vector2.new(s.X, s.Y) - Vector2.new(Mouse.X, Mouse.Y)).Magnitude
                                if d < minDist then minDist = d target = p end
                            end
                        end
                    end
                end
                if target and target.Character then
                    local tp = target.Character:FindFirstChild("Head")
                        or target.Character:FindFirstChild("HumanoidRootPart")
                    if tp then
                        local args = {...}
                        local mod = false
                        for i = 1, #args do
                            if typeof(args[i]) == "CFrame" then
                                args[i] = CFrame.new(args[i].Position, tp.Position)
                                mod = true
                            end
                        end
                        if mod then return old(self, table.unpack(args)) end
                    end
                end
            end
            return old(self, ...)
        end)
    end)
    if not ok then
        task.spawn(function()
            task.wait(2)
            notify("Silent Aim не поддерживается executor'ом", "error")
        end)
    end
end

-- ========== DASH ==========
local function doDash()
    local now = tick()
    if now - dashLastUsed < dashCooldown then return end
    dashLastUsed = now
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local bv = Instance.new("BodyVelocity")
    bv.Velocity = Camera.CFrame.LookVector * dashPower
    bv.MaxForce = Vector3.new(1e5, 1e5, 1e5)
    bv.Parent = root
    Debris:AddItem(bv, 0.2)
end

-- ========== PLAYER LIST LOGIC ==========
local updatePlayerList
local function setAimTarget(plr)
    aimbotSelectedTarget = plr
    if plr then
        TargetStatus.Text = "Цель: " .. plr.Name
        TargetStatus.TextColor3 = C_OK
    else
        TargetStatus.Text = "Цель: авто (ближайший)"
        TargetStatus.TextColor3 = C_DIM
    end
end

ResetTargetBtn.MouseButton1Click:Connect(function()
    setAimTarget(nil)
    updatePlayerList()
end)

local function makeRowButton(parent, text, xOff, color)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 50, 0, 34)
    b.Position = UDim2.new(1, xOff, 0.5, -17)
    b.Text = text
    b.TextColor3 = C_TEXT
    b.TextSize = 12
    b.Font = Enum.Font.GothamBold
    b.BackgroundColor3 = color
    b.BorderSizePixel = 0
    b.Parent = parent
    addCorner(b, 8)
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
            local sel = (aimbotSelectedTarget == plr)
            local row = Instance.new("Frame")
            row.Size = UDim2.new(1, 0, 0, 46)
            row.BackgroundColor3 = sel and Color3.fromRGB(30, 55, 45) or C_ROW
            row.BorderSizePixel = 0
            row.LayoutOrder = order
            row.Parent = PlayerListContainer
            addCorner(row, 8)

            local nm = Instance.new("TextLabel")
            nm.Size = UDim2.new(1, -124, 1, 0)
            nm.Position = UDim2.new(0, 10, 0, 0)
            nm.BackgroundTransparency = 1
            nm.Text = plr.Name
            nm.TextColor3 = C_TEXT
            nm.TextSize = 13
            nm.Font = Enum.Font.Gotham
            nm.TextXAlignment = Enum.TextXAlignment.Left
            nm.TextTruncate = Enum.TextTruncate.AtEnd
            nm.Parent = row

            local tpBtn = makeRowButton(row, "TP", -112, C_ROW_D)
            local aimBtn = makeRowButton(row, sel and "✓" or "AIM", -58,
                sel and Color3.fromRGB(30, 100, 65) or C_ROW_D)

            tpBtn.MouseButton1Click:Connect(function()
                local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                local theirRoot = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
                if myRoot and theirRoot then
                    myRoot.CFrame = theirRoot.CFrame + Vector3.new(0, 3, 0)
                    notify("TP к " .. plr.Name, "success")
                end
            end)

            aimBtn.MouseButton1Click:Connect(function()
                setAimTarget(aimbotSelectedTarget == plr and nil or plr)
                updatePlayerList()
            end)
        end
    end
end

Players.PlayerAdded:Connect(function()
    if playerListEnabled then updatePlayerList() end
end)
Players.PlayerRemoving:Connect(function(plr)
    if aimbotSelectedTarget == plr then setAimTarget(nil) end
    task.defer(function()
        if playerListEnabled then updatePlayerList() end
    end)
end)

-- ========== AIMBOT ==========
local function getAimbotTarget()
    if aimbotSelectedTarget and aimbotSelectedTarget.Character
    and aimbotSelectedTarget.Character:FindFirstChild("Head") then
        return aimbotSelectedTarget
    end
    local closest, minDist = nil, aimbotFOV
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Head") then
            local s, onScreen = Camera:WorldToScreenPoint(plr.Character.Head.Position)
            if onScreen then
                local d = (Vector2.new(s.X, s.Y) - Vector2.new(Mouse.X, Mouse.Y)).Magnitude
                if d < minDist then minDist = d closest = plr end
            end
        end
    end
    return closest
end

RunService.RenderStepped:Connect(function()
    if fovCircle then
        fovCircle.Position = Vector2.new(Mouse.X, Mouse.Y + 36)
        fovCircle.Radius = aimbotFOV
        fovCircle.Visible = aimbotEnabled and fovCircleVisible
    end
    if aimbotEnabled then
        local t = getAimbotTarget()
        if t and t.Character and t.Character:FindFirstChild("Head") then
            local cur = Camera.CFrame
            local new = CFrame.new(cur.Position, t.Character.Head.Position)
            if aimbotSmoothness > 1 then
                Camera.CFrame = cur:Lerp(new, 1 / aimbotSmoothness)
            else
                Camera.CFrame = new
            end
        end
    end
end)

RunService.RenderStepped:Connect(function()
    if triggerbotEnabled then
        local t = Mouse.Target
        if t and t.Parent then
            local plr = Players:GetPlayerFromCharacter(t.Parent)
            if plr and plr ~= LocalPlayer and mouse1click then pcall(mouse1click) end
        end
    end
end)

-- ========== TAB: COMBAT ==========
createTab("Combat")
createSection("Aimbot")
createTumbler("Aimbot", false).onToggle(function(st)
    aimbotEnabled = st
    notify(st and "Aimbot ON" or "Aimbot OFF", st and "success" or nil)
end)
createTumbler("Silent Aim", false).onToggle(function(st)
    silentAimEnabled = st
    notify(st and "Silent Aim ON" or "Silent Aim OFF", st and "success" or nil)
end)
createTumbler("FOV Circle", true).onToggle(function(st) fovCircleVisible = st end)
createSlider("Aimbot FOV", 10, 400, 90, function(v) aimbotFOV = v end)
createSlider("Aimbot Smooth", 1, 20, 5, function(v) aimbotSmoothness = v end)
createTumbler("Triggerbot", false).onToggle(function(st) triggerbotEnabled = st end)
createSection("Hitbox")
createTumbler("Hitbox Expander", false).onToggle(function(st)
    hitboxEnabled = st
    if not st then
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("HumanoidRootPart") then
                p.Character.HumanoidRootPart.Size = Vector3.new(2, 2, 1)
            end
        end
    end
end)
createSlider("Hitbox Size", 2, 20, 5, function(v) hitboxSize = v end)

-- ========== TAB: VISUALS ==========
createTab("Visuals")
createSection("ESP")
createTumbler("ESP Boxes", true).onToggle(function(st) espBoxEnabled = st end)
createTumbler("ESP Tracers", true).onToggle(function(st) espTracerEnabled = st end)
createTumbler("ESP Names", true).onToggle(function(st) espNamesEnabled = st end)
createTumbler("ESP Distance & HP", true).onToggle(function(st)
    espDistanceEnabled, espHealthEnabled = st, st
end)
createTumbler("Skeleton ESP", false).onToggle(function(st) skeletonEnabled = st end)
createSection("Chams")
createTumbler("Chams (Wallhack)", false).onToggle(function(st)
    wallhackEnabled = st
    if not st then
        for _, p in pairs(Players:GetPlayers()) do
            if p.Character and p.Character:FindFirstChild("WIA_WH") then
                p.Character.WIA_WH:Destroy()
            end
        end
    end
end)
createSlider("Chams Opacity %", 0, 100, 35, function(v) chamsOpacity = v / 100 end)

-- ========== TAB: MOVE ==========
createTab("Move")
createSection("Flight")
createTumbler("Flight", false).onToggle(function(st)
    flightEnabled = st
    flyUp, flyDown = false, false
    FlyGui.Enabled = st
    if st then startFlight() notify("Flight ON", "success") else stopFlight() notify("Flight OFF") end
end)
createSlider("Fly Speed", 10, 300, 50, function(v) flySpeed = v end)
createTumbler("Noclip", false).onToggle(function(st) noclipEnabled = st end)

createSection("Speed")
createTumbler("CFrame Speed", false).onToggle(function(st) cframeSpeedEnabled = st end)
createSlider("Speed Multiplier", 1, 10, 2, function(v) cframeSpeedValue = v end)
createSlider("Walk Speed", 16, 200, 16, function(v)
    walkSpeedValue = v
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.WalkSpeed = v
    end
end)
createSlider("Jump Power", 50, 200, 50, function(v)
    jumpPowerValue = v
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.JumpPower = v
    end
end)
createTumbler("Infinite Jump", false).onToggle(function(st) infiniteJumpEnabled = st end)
createTumbler("Bhop", false).onToggle(function(st) bhopEnabled = st end)

createSection("Dash")
createTumbler("Dash", false).onToggle(function(st) dashEnabled = st end)
createSlider("Dash Power", 30, 300, 90, function(v) dashPower = v end)
local dashBtn
dashBtn = createButton("Dash Key: " .. dashKey.Name, function()
    if waitingHubBind then return end
    local capture = true
    dashBtn.Text = "Нажми клавишу..."
    local c
    c = UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            dashKey = input.KeyCode
            dashBtn.Text = "Dash Key: " .. dashKey.Name
            notify("Dash = " .. dashKey.Name, "success")
            c:Disconnect()
        end
    end)
end)

createSection("Spinbot")
createTumbler("Spinbot", false).onToggle(function(st) spinbotEnabled = st end)
createSlider("Spinbot Speed", 5, 50, 20, function(v) spinbotSpeed = v end)

-- ========== TAB: PLAYER ==========
createTab("Player")
createSection("Protection")
createTumbler("Godmode", false).onToggle(function(st)
    godmodeEnabled = st
    if st and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.Health = LocalPlayer.Character.Humanoid.MaxHealth
    end
end)
createTumbler("Anti-Void", false).onToggle(function(st) antiVoidEnabled = st end)
createTumbler("Anti-Fall", false).onToggle(function(st) antiFallEnabled = st end)
createTumbler("Anti-Fling", false).onToggle(function(st)
    antiFlingEnabled = st
    notify(st and "Anti-Fling ON" or "Anti-Fling OFF", st and "success" or nil)
end)
createTumbler("Anti-Ragdoll", false).onToggle(function(st) antiRagdollEnabled = st end)
createTumbler("Anti-AFK", false).onToggle(function(st) antiAFKEnabled = st end)

createSection("Players & Tools")
playerListTumbler = createTumbler("Player List GUI", false)
playerListTumbler.onToggle(function(st)
    playerListEnabled = st
    PlayerListGui.Enabled = st
    if st then updatePlayerList() end
end)
createTumbler("Teleport Tool", false).onToggle(function(st)
    tpToolEnabled = st
    if st then
        giveTPTool()
        notify("TP Tool выдан (авто-выдача вкл)", "success")
    else
        local bp = LocalPlayer:FindFirstChildOfClass("Backpack")
        local char = LocalPlayer.Character
        if bp and bp:FindFirstChild("WIA_TP") then bp.WIA_TP:Destroy() end
        if char and char:FindFirstChild("WIA_TP") then char.WIA_TP:Destroy() end
        notify("TP Tool выкл")
    end
end)
createButton("Загрузить F3X Tools", function()
    notify("Загрузка F3X...")
    if loadF3X() then notify("F3X загружен", "success") else notify("F3X: не удалось", "error") end
end)

-- ========== TAB: WORLD ==========
createTab("World")
createSection("Lighting")
createTumbler("FullBright", false).onToggle(function(st)
    fullBrightEnabled = st
    if st then
        originalBrightness, originalAmbient = Lighting.Brightness, Lighting.Ambient
        Lighting.Brightness = 2
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
    else
        if originalBrightness then Lighting.Brightness = originalBrightness end
        if originalAmbient then Lighting.Ambient = originalAmbient end
    end
end)
createTumbler("No Fog", false).onToggle(function(st)
    noFogEnabled = st
    if st then
        originalFog = Lighting.FogEnd
        Lighting.FogEnd = 1e6
    else
        if originalFog then Lighting.FogEnd = originalFog end
    end
end)
createSection("Camera")
createSlider("Camera FOV", 50, 120, 70, function(v) Camera.FieldOfView = v end)

-- ========== TAB: MISC ==========
createTab("Misc")
createSection("Automation")
createTumbler("AutoClicker", false).onToggle(function(st) autoClickerEnabled = st end)
createSlider("Click Delay (ms)", 10, 1000, 100, function(v) autoClickerDelay = v end)
createTumbler("Chat Spam", false).onToggle(function(st) chatSpamEnabled = st end)

createSection("Interface")
local hubKeyBtn
hubKeyBtn = createButton("Hub Key: " .. hubToggleKey.Name, function()
    if waitingHubBind then return end
    waitingHubBind = true
    hubKeyBtn.Text = "Нажми клавишу..."
    notify("Нажми клавишу для открытия хаба")
end)
createTumbler("Watermark", true, { bindable = false }).onToggle(function(st)
    WatermarkGui.Enabled = st
end)

createSection("Server")
createButton("Rejoin Server", function()
    TeleportService:Teleport(game.PlaceId, LocalPlayer)
end)
createButton("Server Hop", function()
    local ok, data = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(
            "https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"
        )).data
    end)
    if not ok or not data then notify("Server Hop: ошибка", "error") return end
    for _, s in pairs(data) do
        if s.playing < s.maxPlayers and s.id ~= game.JobId then
            TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id, LocalPlayer)
            return
        end
    end
    notify("Server Hop: свободных нет", "error")
end)

selectTab("Combat")

-- ========== GLOBAL INPUT ==========
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    -- hub bind waiting
    if waitingHubBind and input.UserInputType == Enum.UserInputType.Keyboard then
        hubToggleKey = input.KeyCode
        waitingHubBind = false
        if hubKeyBtn then hubKeyBtn.Text = "Hub Key: " .. input.KeyCode.Name end
        notify("Hub toggle = " .. input.KeyCode.Name, "success")
        return
    end
    if input.KeyCode == hubToggleKey then
        guiVisible = not guiVisible
        ScreenGui.Enabled = guiVisible
        if playerListEnabled then PlayerListGui.Enabled = guiVisible end
    end
    if input.KeyCode == dashKey and dashEnabled then
        doDash()
    end
end)

-- ========== GAME LOOPS ==========
RunService.Heartbeat:Connect(function()
    if cframeSpeedEnabled and LocalPlayer.Character
    and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    and LocalPlayer.Character:FindFirstChild("Humanoid") then
        local hum = LocalPlayer.Character.Humanoid
        local root = LocalPlayer.Character.HumanoidRootPart
        if hum.MoveDirection.Magnitude > 0 then
            root.CFrame = root.CFrame + (hum.MoveDirection * (cframeSpeedValue / 10))
        end
    end
end)

RunService.Heartbeat:Connect(function()
    if bhopEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        local hum = LocalPlayer.Character.Humanoid
        if hum.MoveDirection.Magnitude > 0 and hum.FloorMaterial ~= Enum.Material.Air then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

RunService.RenderStepped:Connect(function()
    if spinbotEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        LocalPlayer.Character.HumanoidRootPart.CFrame =
            LocalPlayer.Character.HumanoidRootPart.CFrame * CFrame.Angles(0, math.rad(spinbotSpeed), 0)
    end
end)

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

RunService.Heartbeat:Connect(function()
    if antiFallEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        local hum = LocalPlayer.Character.Humanoid
        if hum:GetState() == Enum.HumanoidStateType.FallingDown then
            hum:ChangeState(Enum.HumanoidStateType.Landed)
        end
    end
end)

-- Anti-Fling
RunService.Heartbeat:Connect(function()
    if not antiFlingEnabled then return end
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    if root.AssemblyLinearVelocity.Magnitude > 100 then
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end
    for _, c in pairs(root:GetChildren()) do
        if (c:IsA("BodyVelocity") or c:IsA("BodyAngularVelocity")
        or c:IsA("BodyForce") or c:IsA("BodyThrust")) and c ~= bodyVelocity then
            c:Destroy()
        end
    end
end)

-- Anti-Ragdoll
local function bindAntiRagdoll(char)
    local hum = char:WaitForChild("Humanoid", 5)
    if not hum then return end
    hum.StateChanged:Connect(function(_, new)
        if antiRagdollEnabled and (new == Enum.HumanoidStateType.Ragdoll
        or new == Enum.HumanoidStateType.Physics) then
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end)
end
if LocalPlayer.Character then bindAntiRagdoll(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(bindAntiRagdoll)

task.spawn(function()
    while true do
        task.wait(autoClickerDelay / 1000)
        if autoClickerEnabled and mouse1click then pcall(mouse1click) end
    end
end)

task.spawn(function()
    while true do
        task.wait(chatSpamDelay)
        if chatSpamEnabled then
            local chat = ReplicatedStorage:FindFirstChild("DefaultChatSystemChatEvents")
            if chat and chat:FindFirstChild("SayMessageRequest") then
                chat.SayMessageRequest:FireServer(chatSpamMessage, "All")
            end
        end
    end
end)

local vu = game:GetService("VirtualUser")
LocalPlayer.Idled:Connect(function()
    if antiAFKEnabled then
        vu:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        task.wait(1)
        vu:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
    end
end)

UserInputService.JumpRequest:Connect(function()
    if infiniteJumpEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- ========== DRAWING ESP ==========
local espLines, tracerLines, textDrawings, skelLines = {}, {}, {}, {}

RunService.RenderStepped:Connect(function()
    if not Drawing then return end
    for i = #espLines, 1, -1 do espLines[i]:Remove() espLines[i] = nil end
    for i = #tracerLines, 1, -1 do tracerLines[i]:Remove() tracerLines[i] = nil end
    for i = #textDrawings, 1, -1 do textDrawings[i]:Remove() textDrawings[i] = nil end
    for i = #skelLines, 1, -1 do skelLines[i]:Remove() skelLines[i] = nil end

    if not (espBoxEnabled or espTracerEnabled or espNamesEnabled or espDistanceEnabled or skeletonEnabled) then return end

    local camPos = Camera.CFrame.Position
    local vp = Camera.ViewportSize

    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Head")
        and plr.Character:FindFirstChild("Humanoid") then
            local head = plr.Character.Head
            local hum = plr.Character.Humanoid
            local pos, onScreen = Camera:WorldToViewportPoint(head.Position)

            -- Skeleton (не зависит от onScreen, кости могут быть за экраном но связанные)
            if skeletonEnabled then
                for _, joint in pairs(plr.Character:GetDescendants()) do
                    if joint:IsA("Motor6D") and joint.Part0 and joint.Part1 then
                        local p0 = Camera:WorldToViewportPoint(joint.Part0.Position)
                        local p1 = Camera:WorldToViewportPoint(joint.Part1.Position)
                        if p0.Z > 0 and p1.Z > 0 then
                            local line = Drawing.new("Line")
                            line.From = Vector2.new(p0.X, p0.Y)
                            line.To = Vector2.new(p1.X, p1.Y)
                            line.Color = skeletonColor
                            line.Thickness = 1
                            line.Transparency = 0.9
                            line.Visible = true
                            skelLines[#skelLines + 1] = line
                        end
                    end
                end
            end

            if onScreen then
                local dist = math.floor((head.Position - camPos).Magnitude)
                local size = math.clamp(100 / math.max(dist, 1) * 10, 15, 45)

                if espBoxEnabled then
                    local L = {
                        Drawing.new("Line"), Drawing.new("Line"),
                        Drawing.new("Line"), Drawing.new("Line"),
                    }
                    local x, y = pos.X - size / 2, pos.Y - size / 2
                    L[1].From = Vector2.new(x, y) L[1].To = Vector2.new(x + size, y)
                    L[2].From = Vector2.new(x + size, y) L[2].To = Vector2.new(x + size, y + size)
                    L[3].From = Vector2.new(x + size, y + size) L[3].To = Vector2.new(x, y + size)
                    L[4].From = Vector2.new(x, y + size) L[4].To = Vector2.new(x, y)
                    for j = 1, 4 do
                        L[j].Color = C_ACCENT
                        L[j].Thickness = 1.5
                        L[j].Transparency = 1
                        L[j].Visible = true
                        espLines[#espLines + 1] = L[j]
                    end
                end

                if espTracerEnabled then
                    local tr = Drawing.new("Line")
                    tr.From = Vector2.new(vp.X / 2, vp.Y)
                    tr.To = Vector2.new(pos.X, pos.Y)
                    tr.Color = C_ACCENT
                    tr.Thickness = 1
                    tr.Transparency = 0.65
                    tr.Visible = true
                    tracerLines[#tracerLines + 1] = tr
                end

                if espNamesEnabled or espDistanceEnabled then
                    local tx = Drawing.new("Text")
                    tx.Position = Vector2.new(pos.X, pos.Y - size / 2 - 14)
                    tx.Size = 12
                    tx.Center = true
                    tx.Outline = true
                    tx.Color = C_TEXT
                    local content = ""
                    if espNamesEnabled then content = content .. plr.Name .. " " end
                    if espHealthEnabled then content = content .. "[" .. math.floor(hum.Health) .. "HP] " end
                    if espDistanceEnabled then content = content .. "(" .. dist .. "m)" end
                    tx.Text = content
                    tx.Visible = true
                    textDrawings[#textDrawings + 1] = tx
                end
            end
        end
    end
end)

-- Chams
RunService.Heartbeat:Connect(function()
    if wallhackEnabled then
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character and not plr.Character:FindFirstChild("WIA_WH") then
                local hl = Instance.new("Highlight")
                hl.Name = "WIA_WH"
                hl.FillColor = C_ACCENT
                hl.FillTransparency = chamsOpacity
                hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                hl.Parent = plr.Character
            end
        end
    end
    if wallhackEnabled then
        for _, plr in pairs(Players:GetPlayers()) do
            if plr.Character and plr.Character:FindFirstChild("WIA_WH") then
                plr.Character.WIA_WH.FillTransparency = chamsOpacity
            end
        end
    end
end)

-- ========== SHOW GUI AFTER LOADING ==========
ScreenGui.Enabled = true
setStatus("WIA HUB v10.0 загружен", C_OK)