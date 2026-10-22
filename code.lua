-- ================================================================= --
-- WIA HUB v11.0 Ultimate :: whitewia / tordark
-- Search + Silent Aim (fixed) + Wallcheck + AutoShoot + Hitbox Priority
-- + Item ESP + Team Check + Skeleton (fixed) + Color Picker
-- + Low Gravity + Wall Run + Freecam + Spectate + Cosmetics + Animations
-- ================================================================= --

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local InsertService = game:GetService("InsertService")
local Stats = game:GetService("Stats")
local Debris = game:GetService("Debris")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

-- ========== COLORS (soft, no neon) ==========
local C_BG = Color3.fromRGB(18, 18, 24)
local C_PANEL = Color3.fromRGB(26, 26, 34)
local C_ROW = Color3.fromRGB(32, 32, 42)
local C_ROW_D = Color3.fromRGB(26, 26, 34)
local C_ACCENT = Color3.fromRGB(124, 92, 255)
local C_TEXT = Color3.fromRGB(232, 232, 240)
local C_DIM = Color3.fromRGB(140, 140, 158)
local C_STROKE = Color3.fromRGB(50, 50, 65)
local C_OK = Color3.fromRGB(90, 200, 130)
local C_ERR = Color3.fromRGB(210, 90, 90)

local function addCorner(obj, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = obj
    return c
end

-- ========== NOTIFICATIONS ==========
local NotifGui = Instance.new("ScreenGui")
NotifGui.Name = "WiaNotifs"
NotifGui.ResetOnSpawn = false
NotifGui.DisplayOrder = 200
NotifGui.Parent = CoreGui

local NotifHolder = Instance.new("Frame")
NotifHolder.Size = UDim2.new(0, 260, 0, 400)
NotifHolder.Position = UDim2.new(1, -272, 0, 20)
NotifHolder.BackgroundTransparency = 1
NotifHolder.Parent = NotifGui

local NL = Instance.new("UIListLayout")
NL.Padding = UDim.new(0, 8)
NL.SortOrder = Enum.SortOrder.LayoutOrder
NL.Parent = NotifHolder

local nOrder = 0
local function notify(text, kind)
    nOrder = nOrder + 1
    local col = kind == "error" and C_ERR or kind == "success" and C_OK or C_ACCENT
    local f = Instance.new("Frame")
    f.Size = UDim2.new(1, 0, 0, 46)
    f.BackgroundColor3 = C_PANEL
    f.BorderSizePixel = 0
    f.LayoutOrder = nOrder
    f.ClipsDescendants = true
    f.Parent = NotifHolder
    addCorner(f, 10)
    local a = Instance.new("Frame")
    a.Size = UDim2.new(0, 3, 1, 0)
    a.BackgroundColor3 = col
    a.BorderSizePixel = 0
    a.Parent = f
    addCorner(a, 2)
    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, -22, 1, 0)
    l.Position = UDim2.new(0, 14, 0, 0)
    l.BackgroundTransparency = 1
    l.Text = text
    l.TextColor3 = C_TEXT
    l.TextSize = 13
    l.Font = Enum.Font.Gotham
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextWrapped = true
    l.Parent = f
    local s = Instance.new("UIScale")
    s.Scale = 0.85
    s.Parent = f
    TweenService:Create(s, TweenInfo.new(0.2, Enum.EasingStyle.Back), { Scale = 1 }):Play()
    task.delay(2.6, function()
        TweenService:Create(f, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
        TweenService:Create(l, TweenInfo.new(0.3), { TextTransparency = 1 }):Play()
        TweenService:Create(a, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
        task.wait(0.3)
        f:Destroy()
    end)
end

-- ========== STATE ==========
local flightEnabled, noclipEnabled = false, false
local flySpeed = 50
local bodyVelocity, bodyGyro = nil, nil
local savedGravity = workspace.Gravity
local flyUp, flyDown = false, false

local cframeSpeedEnabled, cframeSpeedValue = false, 2
local walkSpeedValue, jumpPowerValue = 16, 50
local infiniteJumpEnabled, bhopEnabled = false, false
local spinbotEnabled, spinbotSpeed = false, 20

local godmodeEnabled = false
local tpToolEnabled, tpEnabled = false, false
local wallhackEnabled, chamsOpacity = false, 0.35
local antiAFKEnabled, playerListEnabled = false, false
local antiVoidEnabled, antiFallEnabled = false, false
local antiFlingEnabled, antiRagdollEnabled = false, false
local lowGravityEnabled = false
local wallRunEnabled = false
local freecamEnabled = false
local spectateTarget = nil
local fullBrightEnabled, noFogEnabled = false, false
local origBright, origAmbient, origFog = nil, nil, nil

local aimbotEnabled, aimbotFOV = false, 90
local aimbotSmoothness = 5
local aimbotSelectedTarget = nil
local fovCircleVisible = true
local silentAimEnabled = false
local autoShootEnabled = false
local silentAimWallcheck = true
local aimPart = "Head" -- Head / HumanoidRootPart / UpperTorso / Random

local hitboxEnabled, hitboxSize = false, 5
local autoClickerEnabled, autoClickerDelay = false, 100
local triggerbotEnabled = false
local chatSpamEnabled, chatSpamDelay = false, 5
local chatSpamMessage = "WIA HUB ON TOP"

local espBoxEnabled, espTracerEnabled = true, true
local espNamesEnabled, espDistanceEnabled = true, true
local espHealthEnabled, skeletonEnabled = true, false
local skeletonColor = C_ACCENT
local espColor = C_ACCENT
local itemEspEnabled = false
local teamCheckEnabled = true
local espItems = {}

local dashEnabled, dashPower = false, 90
local dashKey = Enum.KeyCode.Q
local dashCooldown, dashLastUsed = 0.4, 0

local hubToggleKey = Enum.KeyCode.RightShift
local guiVisible = true
local waitingHubBind = false

local headlessEnabled, korbloxEnabled = false, false
local currentAnimPack = "Default"

-- ========== ANIMATION LIBRARY ==========
-- Bundle ID / Asset ID подход. Для простоты используем прямые ID анимаций (R15).
-- Если анимация не грузится — игра может её блокировать, это нормально.
local ANIM_PACKS = {
    Default = {
        idle = "rbxassetid://507766666",
        walk = "rbxassetid://507777826",
        run = "rbxassetid://507767714",
        jump = "rbxassetid://507765000",
        fall = "rbxassetid://507767968",
        climb = "rbxassetid://507765644",
        swim = "rbxassetid://507784897",
        swimidle = "rbxassetid://507785072",
    },
    Zombie = {
        idle = "rbxassetid://616158929", -- были данные 616158929/616157476
        walk = "rbxassetid://616158929",
        run = "rbxassetid://616158929",
        jump = "rbxassetid://616158929",
        fall = "rbxassetid://616158929",
        climb = "rbxassetid://616158929",
        swim = "rbxassetid://616158929",
        swimidle = "rbxassetid://616158929",
    },
    Vampire = {
        idle = "rbxassetid://1083462077",
        walk = "rbxassetid://1083462077",
        run = "rbxassetid://1083462077",
        jump = "rbxassetid://1083462077",
        fall = "rbxassetid://1083462077",
        climb = "rbxassetid://1083462077",
        swim = "rbxassetid://1083462077",
        swimidle = "rbxassetid://1083462077",
    },
    Werewolf = {
        idle = "rbxassetid://616158929",
        walk = "rbxassetid://616158929",
        run = "rbxassetid://616158929",
        jump = "rbxassetid://616158929",
        fall = "rbxassetid://616158929",
        climb = "rbxassetid://616158929",
        swim = "rbxassetid://616158929",
        swimidle = "rbxassetid://616158929",
    },
    Adidas = {
        idle = "rbxassetid://616163532",
        walk = "rbxassetid://616165536",
        run = "rbxassetid://616161920",
        jump = "rbxassetid://616161920",
        fall = "rbxassetid://616161920",
        climb = "rbxassetid://616161920",
        swim = "rbxassetid://616161920",
        swimidle = "rbxassetid://616161920",
    },
    ["Adidas Aura"] = {
        idle = "rbxassetid://616163532",
        walk = "rbxassetid://616165536",
        run = "rbxassetid://616161920",
        jump = "rbxassetid://616161920",
        fall = "rbxassetid://616161920",
        climb = "rbxassetid://616161920",
        swim = "rbxassetid://616161920",
        swimidle = "rbxassetid://616161920",
    },
    Ninja = {
        idle = "rbxassetid://507766666",
        walk = "rbxassetid://507777826",
        run = "rbxassetid://507767714",
        jump = "rbxassetid://507765000",
        fall = "rbxassetid://507767968",
        climb = "rbxassetid://507765644",
        swim = "rbxassetid://507784897",
        swimidle = "rbxassetid://507785072",
    },
    Robot = {
        idle = "rbxassetid://507766666",
        walk = "rbxassetid://507777826",
        run = "rbxassetid://507767714",
        jump = "rbxassetid://507765000",
        fall = "rbxassetid://507767968",
        climb = "rbxassetid://507765644",
        swim = "rbxassetid://507784897",
        swimidle = "rbxassetid://507785072",
    },
    Levitate = {
        idle = "rbxassetid://313762630",
        walk = "rbxassetid://313762630",
        run = "rbxassetid://313762630",
        jump = "rbxassetid://313762630",
        fall = "rbxassetid://313762630",
        climb = "rbxassetid://313762630",
        swim = "rbxassetid://313762630",
        swimidle = "rbxassetid://313762630",
    },
    Mage = {
        idle = "rbxassetid://507766666",
        walk = "rbxassetid://507777826",
        run = "rbxassetid://507767714",
        jump = "rbxassetid://507765000",
        fall = "rbxassetid://507767968",
        climb = "rbxassetid://507765644",
        swim = "rbxassetid://507784897",
        swimidle = "rbxassetid://507785072",
    },
    Stylish = {
        idle = "rbxassetid://507766666",
        walk = "rbxassetid://507777826",
        run = "rbxassetid://507767714",
        jump = "rbxassetid://507765000",
        fall = "rbxassetid://507767968",
        climb = "rbxassetid://507765644",
        swim = "rbxassetid://507784897",
        swimidle = "rbxassetid://507785072",
    },
    Ghost = {
        idle = "rbxassetid://507766666",
        walk = "rbxassetid://507777826",
        run = "rbxassetid://507767714",
        jump = "rbxassetid://507765000",
        fall = "rbxassetid://507767968",
        climb = "rbxassetid://507765644",
        swim = "rbxassetid://507784897",
        swimidle = "rbxassetid://507785072",
    },
    Knight = {
        idle = "rbxassetid://507766666",
        walk = "rbxassetid://507777826",
        run = "rbxassetid://507767714",
        jump = "rbxassetid://507765000",
        fall = "rbxassetid://507767968",
        climb = "rbxassetid://507765644",
        swim = "rbxassetid://507784897",
        swimidle = "rbxassetid://507785072",
    },
    Cartoony = {
        idle = "rbxassetid://507766666",
        walk = "rbxassetid://507777826",
        run = "rbxassetid://507767714",
        jump = "rbxassetid://507765000",
        fall = "rbxassetid://507767968",
        climb = "rbxassetid://507765644",
        swim = "rbxassetid://507784897",
        swimidle = "rbxassetid://507785072",
    },
}

local function applyAnimPack(packName)
    local pack = ANIM_PACKS[packName]
    if not pack then return end
    local char = LocalPlayer.Character
    if not char then return end
    local animate = char:FindFirstChild("Animate")
    if not animate then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    -- Останавливаем все текущие анимации
    for _, track in pairs(humanoid:GetPlayingAnimationTracks()) do
        track:Stop()
    end
    -- Подменяем AnimationId
    local function setAnim(name, id)
        local obj = animate:FindFirstChild(name)
        if obj and obj:IsA("Animation") then
            obj.AnimationId = id
        end
    end
    -- R15 структура
    local idle = animate:FindFirstChild("idle")
    if idle then
        setAnim("idle", pack.idle)
        local idle2 = idle:FindFirstChild("Animation2")
        if idle2 then idle2.AnimationId = pack.idle end
    end
    setAnim("walk", pack.walk)
    setAnim("run", pack.run)
    setAnim("jump", pack.jump)
    setAnim("fall", pack.fall)
    setAnim("climb", pack.climb)
    setAnim("swim", pack.swim)
    setAnim("swimidle", pack.swimidle)
    -- Перезапускаем
    humanoid:ChangeState(Enum.HumanoidStateType.Landed)
    notify("Анимация: " .. packName, "success")
end

-- ========== COSMETICS (Headless / Korblox) ==========
local HEADLESS_MESH = "rbxassetid://1095708"
local KORBLOX_MESH = "rbxassetid://101851696"
local KORBLOX_TEXTURE = "rbxassetid://101851254"
local KORBLOX_DARK = Color3.fromRGB(64, 64, 64)

local function applyHeadless()
    local char = LocalPlayer.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    if not head then return end
    head.Transparency = 1
    head.CanCollide = false
    for _, v in pairs(head:GetChildren()) do
        if v:IsA("Decal") then v:Destroy() end
    end
    local mesh = head:FindFirstChildOfClass("SpecialMesh") or Instance.new("SpecialMesh", head)
    mesh.MeshType = Enum.MeshType.FileMesh
    mesh.MeshId = HEADLESS_MESH
    mesh.Scale = Vector3.new(0.001, 0.001, 0.001)
end

local function applyKorblox()
    local char = LocalPlayer.Character
    if not char then return end
    -- R15
    local upper = char:FindFirstChild("RightUpperLeg")
    local lower = char:FindFirstChild("RightLowerLeg")
    local foot = char:FindFirstChild("RightFoot")
    if upper and lower and foot then
        for _, p in ipairs({upper, lower, foot}) do
            for _, c in ipairs(p:GetChildren()) do
                if c:IsA("SpecialMesh") or c:IsA("CharacterMesh") then c:Destroy() end
            end
        end
        upper.MeshId = KORBLOX_MESH
        upper.TextureID = KORBLOX_TEXTURE
        lower.Transparency = 1
        foot.Transparency = 1
        upper.Color = KORBLOX_DARK
        return
    end
    -- R6
    local rightLeg = char:FindFirstChild("Right Leg")
    if rightLeg then
        for _, c in ipairs(rightLeg:GetChildren()) do
            if c:IsA("SpecialMesh") or c:IsA("CharacterMesh") then c:Destroy() end
        end
        local mesh = Instance.new("SpecialMesh")
        mesh.MeshType = Enum.MeshType.FileMesh
        mesh.MeshId = KORBLOX_MESH
        mesh.TextureId = KORBLOX_TEXTURE
        mesh.Parent = rightLeg
        rightLeg.Color = KORBLOX_DARK
    end
end

local function removeCosmetics()
    local char = LocalPlayer.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    if head then
        head.Transparency = 0
        local m = head:FindFirstChildOfClass("SpecialMesh")
        if m and m.MeshId == HEADLESS_MESH then m:Destroy() end
    end
    for _, name in ipairs({"RightUpperLeg", "RightLowerLeg", "RightFoot", "Right Leg"}) do
        local p = char:FindFirstChild(name)
        if p then
            for _, c in ipairs(p:GetChildren()) do
                if c:IsA("SpecialMesh") and c.MeshId == KORBLOX_MESH then c:Destroy() end
            end
        end
    end
end

-- ========== WATERMARK ==========
local WmGui = Instance.new("ScreenGui")
WmGui.Name = "WiaWm"
WmGui.ResetOnSpawn = false
WmGui.DisplayOrder = 50
WmGui.Parent = CoreGui

local Wm = Instance.new("Frame")
Wm.Size = UDim2.new(0, 250, 0, 44)
Wm.Position = UDim2.new(0, 12, 0, 12)
Wm.BackgroundColor3 = C_PANEL
Wm.BackgroundTransparency = 0.15
Wm.BorderSizePixel = 0
Wm.Parent = WmGui
addCorner(Wm, 10)

local WmStroke = Instance.new("UIStroke")
WmStroke.Color = C_STROKE
WmStroke.Thickness = 1
WmStroke.Transparency = 0.3
WmStroke.Parent = Wm

local WmAccent = Instance.new("Frame")
WmAccent.Size = UDim2.new(0, 3, 1, 0)
WmAccent.BackgroundColor3 = C_ACCENT
WmAccent.BorderSizePixel = 0
WmAccent.Parent = Wm
addCorner(WmAccent, 2)

local WmTitle = Instance.new("TextLabel")
WmTitle.Size = UDim2.new(1, -20, 0, 20)
WmTitle.Position = UDim2.new(0, 14, 0, 4)
WmTitle.BackgroundTransparency = 1
WmTitle.Text = "WIA HUB v11.0"
WmTitle.TextColor3 = C_TEXT
WmTitle.TextSize = 13
WmTitle.Font = Enum.Font.GothamBold
WmTitle.TextXAlignment = Enum.TextXAlignment.Left
WmTitle.Parent = Wm

local WmStats = Instance.new("TextLabel")
WmStats.Size = UDim2.new(1, -20, 0, 16)
WmStats.Position = UDim2.new(0, 14, 0, 23)
WmStats.BackgroundTransparency = 1
WmStats.Text = "60 FPS  ·  0 ms  ·  " .. LocalPlayer.Name
WmStats.TextColor3 = C_DIM
WmStats.TextSize = 11
WmStats.Font = Enum.Font.Gotham
WmStats.TextXAlignment = Enum.TextXAlignment.Left
WmStats.Parent = Wm

local frameCount, fps = 0, 0
task.spawn(function()
    while Wm.Parent do
        frameCount = 0
        task.wait(1)
        fps = frameCount
    end
end)
RunService.RenderStepped:Connect(function() frameCount = frameCount + 1 end)

task.spawn(function()
    while Wm.Parent do
        local ok, ping = pcall(function()
            return math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
        end)
        WmStats.Text = string.format("%d FPS  ·  %d ms  ·  %s", fps, ok and ping or 0, LocalPlayer.Name)
        task.wait(0.5)
    end
end)

-- ========== PLAYER LIST ==========
local playerListTumbler
local PlayerListGui = Instance.new("ScreenGui")
PlayerListGui.Name = "WiaPlayerList"
PlayerListGui.ResetOnSpawn = false
PlayerListGui.Parent = CoreGui
PlayerListGui.Enabled = false

local plV = workspace.CurrentCamera.ViewportSize
local plW = math.clamp(plV.X * 0.5, 240, 320)
local plH = math.clamp(plV.Y - 80, 200, 400)

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

local plScroll = Instance.new("ScrollingFrame")
plScroll.Size = UDim2.new(1, -8, 1, -84)
plScroll.Position = UDim2.new(0, 4, 0, 38)
plScroll.BackgroundTransparency = 1
plScroll.BorderSizePixel = 0
plScroll.ScrollBarThickness = 3
plScroll.ScrollBarImageColor3 = C_ACCENT
plScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
plScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
plScroll.Parent = PlayerListMain

local plLayout = Instance.new("UIListLayout")
plLayout.Padding = UDim.new(0, 6)
plLayout.SortOrder = Enum.SortOrder.LayoutOrder
plLayout.Parent = plScroll

local plPad = Instance.new("UIPadding")
plPad.PaddingLeft = UDim.new(0, 4)
plPad.PaddingRight = UDim.new(0, 6)
plPad.PaddingTop = UDim.new(0, 2)
plPad.PaddingBottom = UDim.new(0, 6)
plPad.Parent = plScroll

local PlayerListContainer = plScroll

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

-- ========== DRAGGABLE ==========
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
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
end

-- ========== MAIN GUI ==========
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "WiaHubGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui
ScreenGui.Enabled = true

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
TitleVer.Text = "v11"
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

-- ========== TOGGLE BUTTON ==========
local ToggleGui = Instance.new("ScreenGui")
ToggleGui.Name = "WiaToggle"
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
    if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
        pressPos = input.Position
    end
end)
ToggleBtn.InputEnded:Connect(function(input)
    if pressPos and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1) then
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
FlyGui.Name = "WiaFly"
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
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            setHeld(true)
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then setHeld(false) end
            end)
        end
    end)
    b.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            setHeld(false)
        end
    end)
    return b
end

makeFlyButton("▲", UDim2.new(1, -74, 0.5, -66), function(v) flyUp = v end)
makeFlyButton("▼", UDim2.new(1, -74, 0.5, 0), function(v) flyDown = v end)

-- ========== UI FACTORY ==========
local allElements = {}
local searchBarRef = nil

local function registerElement(el)
    table.insert(allElements, el)
end

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
    registerElement({ obj = lbl, name = text, type = "section" })
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

    local obj = {
        getState = function() return state end,
        setState = function(n) state = n update() event:Fire(n) end,
        onToggle = function(cb) event.Event:Connect(cb) end,
    }
    registerElement({ obj = row, name = labelText, type = "tumbler" })
    return obj
end

local activeSlider = nil
UserInputService.InputChanged:Connect(function(input)
    if activeSlider and (input == activeSlider.input or input.UserInputType == Enum.UserInputType.MouseMovement) then
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
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
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

    registerElement({ obj = row, name = labelText, type = "slider" })
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
    registerElement({ obj = btn, name = labelText, type = "button" })
    return btn
end

-- ========== SEARCH BAR ==========
local function createSearchBar()
    local searchFrame = Instance.new("Frame")
    searchFrame.Size = UDim2.new(1, -24, 0, 32)
    searchFrame.Position = UDim2.new(0, 12, 0, 74)
    searchFrame.BackgroundColor3 = C_ROW
    searchFrame.BorderSizePixel = 0
    searchFrame.ZIndex = 10
    searchFrame.Parent = MainFrame
    addCorner(searchFrame, 8)

    local searchBox = Instance.new("TextBox")
    searchBox.Size = UDim2.new(1, -44, 1, 0)
    searchBox.Position = UDim2.new(0, 12, 0, 0)
    searchBox.BackgroundTransparency = 1
    searchBox.Text = ""
    searchBox.PlaceholderText = "Поиск функций..."
    searchBox.TextColor3 = C_TEXT
    searchBox.PlaceholderColor3 = C_DIM
    searchBox.TextSize = 12
    searchBox.Font = Enum.Font.Gotham
    searchBox.TextXAlignment = Enum.TextXAlignment.Left
    searchBox.ClearTextOnFocus = false
    searchBox.Parent = searchFrame

    local clearBtn = Instance.new("TextButton")
    clearBtn.Size = UDim2.new(0, 24, 0, 24)
    clearBtn.Position = UDim2.new(1, -32, 0, 4)
    clearBtn.Text = "✕"
    clearBtn.TextColor3 = C_DIM
    clearBtn.BackgroundColor3 = C_ROW_D
    clearBtn.TextSize = 12
    clearBtn.Font = Enum.Font.GothamBold
    clearBtn.BorderSizePixel = 0
    clearBtn.Parent = searchFrame
    addCorner(clearBtn, 6)

    clearBtn.MouseButton1Click:Connect(function()
        searchBox.Text = ""
        for _, el in ipairs(allElements) do
            if el.obj and el.obj.Parent then
                el.obj.Visible = true
            end
        end
    end)

    searchBox:GetPropertyChangedSignal("Text"):Connect(function()
        local query = searchBox.Text:lower()
        if query == "" then
            for _, el in ipairs(allElements) do
                if el.obj and el.obj.Parent then el.obj.Visible = true end
            end
            return
        end
        for _, el in ipairs(allElements) do
            if el.obj and el.obj.Parent and el.name then
                local match = el.name:lower():find(query, 1, true)
                el.obj.Visible = match ~= nil
            end
        end
    end)

    PageHolder.Position = UDim2.new(0, 0, 0, 112)
    PageHolder.Size = UDim2.new(1, 0, 1, -136)
    searchBarRef = searchBox
end

createSearchBar()

-- ========== FLIGHT ==========
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

-- ========== SILENT AIM (fixed) ==========
local silentAimHook = nil
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
                            local s, onScreen = Camera:WorldToViewportPoint(p.Character.Head.Position)
                            if onScreen then
                                local d = (Vector2.new(s.X, s.Y) - Vector2.new(Mouse.X, Mouse.Y)).Magnitude
                                if d < minDist then minDist = d target = p end
                            end
                        end
                    end
                end
                if target and target.Character then
                    local aimPartObj = target.Character:FindFirstChild(aimPart) or target.Character:FindFirstChild("Head")
                    if aimPartObj then
                        -- Wallcheck
                        if silentAimWallcheck then
                            local origin = Camera.CFrame.Position
                            local dir = (aimPartObj.Position - origin)
                            local params = RaycastParams.new()
                            params.FilterDescendantsInstances = {LocalPlayer.Character, target.Character}
                            params.FilterType = Enum.RaycastFilterType.Exclude
                            local result = workspace:Raycast(origin, dir, params)
                            if result then return old(self, ...) end
                        end
                        local args = {...}
                        local mod = false
                        for i = 1, #args do
                            if typeof(args[i]) == "CFrame" then
                                args[i] = CFrame.new(args[i].Position, aimPartObj.Position)
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
            local aimBtn = makeRowButton(row, sel and "✓" or "AIM", -58, sel and Color3.fromRGB(30, 100, 65) or C_ROW_D)
            local specBtn = makeRowButton(row, "SP", -166, C_ROW_D)

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
            specBtn.MouseButton1Click:Connect(function()
                spectateTarget = plr
                notify("Спектатор: " .. plr.Name, "success")
            end)
        end
    end
end

Players.PlayerAdded:Connect(function()
    if playerListEnabled then updatePlayerList() end
end)
Players.PlayerRemoving:Connect(function(plr)
    if aimbotSelectedTarget == plr then setAimTarget(nil) end
    if spectateTarget == plr then spectateTarget = nil end
    task.defer(function()
        if playerListEnabled then updatePlayerList() end
    end)
end)

-- ========== AIMBOT / AUTO-SHOOT ==========
local function getAimbotTarget()
    if aimbotSelectedTarget and aimbotSelectedTarget.Character and aimbotSelectedTarget.Character:FindFirstChild("Head") then
        return aimbotSelectedTarget
    end
    local closest, minDist = nil, aimbotFOV
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("Head") then
            if teamCheckEnabled and plr.Team == LocalPlayer.Team then continue end
            local s, onScreen = Camera:WorldToViewportPoint(plr.Character.Head.Position)
            if onScreen then
                local d = (Vector2.new(s.X, s.Y) - Vector2.new(Mouse.X, Mouse.Y)).Magnitude
                if d < minDist then minDist = d closest = plr end
            end
        end
    end
    return closest
end

local function getAimPart(character)
    if aimPart == "Random" then
        local parts = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso"}
        return character:FindFirstChild(parts[math.random(1, #parts)])
    end
    return character:FindFirstChild(aimPart) or character:FindFirstChild("Head")
end

RunService.RenderStepped:Connect(function()
    if fovCircle then
        fovCircle.Position = Vector2.new(Mouse.X, Mouse.Y + 36)
        fovCircle.Radius = aimbotFOV
        fovCircle.Visible = aimbotEnabled and fovCircleVisible
    end
    if aimbotEnabled then
        local t = getAimbotTarget()
        if t and t.Character then
            local ap = getAimPart(t.Character)
            if ap then
                if silentAimWallcheck then
                    local origin = Camera.CFrame.Position
                    local dir = ap.Position - origin
                    local params = RaycastParams.new()
                    params.FilterDescendantsInstances = {LocalPlayer.Character, t.Character}
                    params.FilterType = Enum.RaycastFilterType.Exclude
                    local result = workspace:Raycast(origin, dir, params)
                    if result then return end
                end
                local cur = Camera.CFrame
                local new = CFrame.new(cur.Position, ap.Position)
                if aimbotSmoothness > 1 then
                    Camera.CFrame = cur:Lerp(new, 1 / aimbotSmoothness)
                else
                    Camera.CFrame = new
                end
            end
        end
    end
end)

-- AutoShoot
RunService.RenderStepped:Connect(function()
    if not autoShootEnabled then return end
    local t = getAimbotTarget()
    if t and t.Character then
        local ap = getAimPart(t.Character)
        if ap then
            if silentAimWallcheck then
                local origin = Camera.CFrame.Position
                local dir = ap.Position - origin
                local params = RaycastParams.new()
                params.FilterDescendantsInstances = {LocalPlayer.Character, t.Character}
                params.FilterType = Enum.RaycastFilterType.Exclude
                local result = workspace:Raycast(origin, dir, params)
                if not result and mouse1click then pcall(mouse1click) end
            else
                if mouse1click then pcall(mouse1click) end
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

-- ========== ESP / SKELETON (fixed with pool) ==========
local skelPool = {}
local skelActive = 0
local espPool = {}
local espActive = 0
local textPool = {}
local textActive = 0

local function getLine(pool, index)
    if not pool[index] then
        pool[index] = Drawing.new("Line")
    end
    pool[index].Visible = true
    return pool[index]
end

local function getText(pool, index)
    if not pool[index] then
        pool[index] = Drawing.new("Text")
        pool[index].Size = 12
        pool[index].Center = true
        pool[index].Outline = true
    end
    pool[index].Visible = true
    return pool[index]
end

local function hideAll(pool, active)
    for i = 1, #pool do
        pool[i].Visible = false
    end
end

RunService.RenderStepped:Connect(function()
    if not Drawing then return end

    -- Skeleton
    if skeletonEnabled then
        local idx = 0
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                if teamCheckEnabled and plr.Team == LocalPlayer.Team then continue end
                for _, joint in pairs(plr.Character:GetDescendants()) do
                    if joint:IsA("Motor6D") and joint.Part0 and joint.Part1 then
                        local p0 = Camera:WorldToViewportPoint(joint.Part0.Position)
                        local p1 = Camera:WorldToViewportPoint(joint.Part1.Position)
                        if p0.Z > 0 and p1.Z > 0 then
                            idx = idx + 1
                            local line = getLine(skelPool, idx)
                            line.From = Vector2.new(p0.X, p0.Y)
                            line.To = Vector2.new(p1.X, p1.Y)
                            line.Color = skeletonColor
                            line.Thickness = 1
                            line.Transparency = 0.9
                        end
                    end
                end
            end
        end
        for i = idx + 1, #skelPool do skelPool[i].Visible = false end
    else
        for i = 1, #skelPool do skelPool[i].Visible = false end
    end

    -- ESP / Text
    local eIdx = 0
    local tIdx = 0
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            if teamCheckEnabled and plr.Team == LocalPlayer.Team then continue end
            local head = plr.Character:FindFirstChild("Head")
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            if head and hum then
                local pos, onScreen = Camera:WorldToViewportPoint(head.Position)
                if onScreen then
                    local dist = math.floor((head.Position - Camera.CFrame.Position).Magnitude)
                    local size = math.clamp(100 / math.max(dist, 1) * 10, 15, 45)

                    if espBoxEnabled then
                        local x, y = pos.X - size / 2, pos.Y - size / 2
                        local corners = {
                            {Vector2.new(x, y), Vector2.new(x + size, y)},
                            {Vector2.new(x + size, y), Vector2.new(x + size, y + size)},
                            {Vector2.new(x + size, y + size), Vector2.new(x, y + size)},
                            {Vector2.new(x, y + size), Vector2.new(x, y)},
                        }
                        for _, c in ipairs(corners) do
                            eIdx = eIdx + 1
                            local line = getLine(espPool, eIdx)
                            line.From = c[1]
                            line.To = c[2]
                            line.Color = espColor
                            line.Thickness = 1.5
                            line.Transparency = 1
                        end
                    end

                    if espTracerEnabled then
                        eIdx = eIdx + 1
                        local line = getLine(espPool, eIdx)
                        line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                        line.To = Vector2.new(pos.X, pos.Y)
                        line.Color = espColor
                        line.Thickness = 1
                        line.Transparency = 0.65
                    end

                    if espNamesEnabled or espDistanceEnabled then
                        tIdx = tIdx + 1
                        local text = getText(textPool, tIdx)
                        text.Position = Vector2.new(pos.X, pos.Y - size / 2 - 14)
                        text.Color = espColor
                        local content = ""
                        if espNamesEnabled then content = content .. plr.Name .. " " end
                        if espHealthEnabled then content = content .. "[" .. math.floor(hum.Health) .. "HP] " end
                        if espDistanceEnabled then content = content .. "(" .. dist .. "m)" end
                        text.Text = content
                    end
                end
            end
        end
    end
    for i = eIdx + 1, #espPool do espPool[i].Visible = false end
    for i = tIdx + 1, #textPool do textPool[i].Visible = false end

    -- Item ESP
    if itemEspEnabled then
        for _, obj in pairs(workspace:GetDescendants()) do
            if obj:IsA("Tool") or obj:IsA("Model") and obj:FindFirstChildOfClass("Tool") then
                local tool = obj:IsA("Tool") and obj or obj:FindFirstChildOfClass("Tool")
                if tool and tool.Parent then
                    local handle = tool:FindFirstChild("Handle")
                    if handle then
                        local pos, onScreen = Camera:WorldToViewportPoint(handle.Position)
                        if onScreen then
                            tIdx = tIdx + 1
                            local text = getText(textPool, tIdx)
                            text.Position = Vector2.new(pos.X, pos.Y)
                            text.Color = Color3.fromRGB(255, 215, 0)
                            text.Text = tool.Name
                        end
                    end
                end
            end
        end
        for i = tIdx + 1, #textPool do textPool[i].Visible = false end
    end
end)

-- ========== CHAMS ==========
RunService.Heartbeat:Connect(function()
    if wallhackEnabled then
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                if teamCheckEnabled and plr.Team == LocalPlayer.Team then continue end
                if not plr.Character:FindFirstChild("WIA_WH") then
                    local hl = Instance.new("Highlight")
                    hl.Name = "WIA_WH"
                    hl.FillColor = C_ACCENT
                    hl.FillTransparency = chamsOpacity
                    hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    hl.Parent = plr.Character
                else
                    plr.Character.WIA_WH.FillTransparency = chamsOpacity
                end
            end
        end
    end
end)

-- ========== FREECAM ==========
local freecamConnection = nil
local freecamSpeed = 50
local function toggleFreecam(st)
    freecamEnabled = st
    if st then
        local camera = workspace.CurrentCamera
        camera.CameraType = Enum.CameraType.Scriptable
        local cf = camera.CFrame
        local yaw, pitch = 0, 0
        freecamConnection = RunService.RenderStepped:Connect(function(dt)
            if not freecamEnabled then return end
            local move = Vector3.zero
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then move = move + camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then move = move - camera.CFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then move = move - camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then move = move + camera.CFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then move = move + Vector3.yAxis end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then move = move - Vector3.yAxis end
            if move.Magnitude > 0 then
                cf = cf + move.Unit * freecamSpeed * dt
            end
            -- Мышь
            local delta = UserInputService:GetMouseDelta()
            yaw = yaw - delta.X * 0.003
            pitch = math.clamp(pitch - delta.Y * 0.003, -math.pi/2, math.pi/2)
            camera.CFrame = CFrame.new(cf.Position) * CFrame.Angles(pitch, yaw, 0)
        end)
        notify("Freecam ON (WASD + Space/Shift)", "success")
    else
        if freecamConnection then freecamConnection:Disconnect() freecamConnection = nil end
        workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
        notify("Freecam OFF")
    end
end

-- ========== SPECTATE ==========
RunService.RenderStepped:Connect(function()
    if spectateTarget and spectateTarget.Character then
        local targetHead = spectateTarget.Character:FindFirstChild("Head")
        if targetHead then
            Camera.CameraType = Enum.CameraType.Scriptable
            Camera.CFrame = CFrame.new(targetHead.Position - targetHead.CFrame.LookVector * 10 + Vector3.new(0, 5, 0), targetHead.Position)
        end
    elseif Camera.CameraType == Enum.CameraType.Scriptable and not freecamEnabled then
        Camera.CameraType = Enum.CameraType.Custom
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
createTumbler("Wallcheck", true).onToggle(function(st) silentAimWallcheck = st end)
createTumbler("AutoShoot", false).onToggle(function(st) autoShootEnabled = st end)
createTumbler("FOV Circle", true).onToggle(function(st) fovCircleVisible = st end)
createSlider("Aimbot FOV", 10, 400, 90, function(v) aimbotFOV = v end)
createSlider("Aimbot Smooth", 1, 20, 5, function(v) aimbotSmoothness = v end)
createSection("Aim Part")
createTumbler("Head", true, { bindable = false }).onToggle(function(st)
    if st then aimPart = "Head" end
end)
createTumbler("Torso", false, { bindable = false }).onToggle(function(st)
    if st then aimPart = "HumanoidRootPart" end
end)
createTumbler("Random", false, { bindable = false }).onToggle(function(st)
    if st then aimPart = "Random" end
end)
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
createTumbler("Team Check", true).onToggle(function(st) teamCheckEnabled = st end)
createTumbler("Item ESP", false).onToggle(function(st)
    itemEspEnabled = st
    if not st then
        for _, t in pairs(textPool) do t.Visible = false end
    end
end)
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

-- Color pickers (простые кнопки циклического перебора)
local colors = {
    {name = "Purple", c = Color3.fromRGB(124, 92, 255)},
    {name = "Red", c = Color3.fromRGB(220, 80, 80)},
    {name = "Green", c = Color3.fromRGB(80, 200, 120)},
    {name = "Blue", c = Color3.fromRGB(80, 140, 220)},
    {name = "Yellow", c = Color3.fromRGB(220, 200, 80)},
    {name = "White", c = Color3.fromRGB(240, 240, 240)},
}
local espColorIdx, skelColorIdx = 1, 1
createButton("ESP Color: " .. colors[espColorIdx].name, function(btn)
    espColorIdx = espColorIdx % #colors + 1
    espColor = colors[espColorIdx].c
    btn.Text = "ESP Color: " .. colors[espColorIdx].name
end)
createButton("Skeleton Color: " .. colors[skelColorIdx].name, function(btn)
    skelColorIdx = skelColorIdx % #colors + 1
    skeletonColor = colors[skelColorIdx].c
    btn.Text = "Skeleton Color: " .. colors[skelColorIdx].name
end)

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
createTumbler("Low Gravity", false).onToggle(function(st)
    lowGravityEnabled = st
    workspace.Gravity = st and 50 or 196.2
end)

createSection("Dash")
createTumbler("Dash", false).onToggle(function(st) dashEnabled = st end)
createSlider("Dash Power", 30, 300, 90, function(v) dashPower = v end)
local dashBtn
dashBtn = createButton("Dash Key: " .. dashKey.Name, function()
    if waitingHubBind then return end
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

createSection("Wall Run / Freecam / Spectate")
createTumbler("Wall Run", false).onToggle(function(st) wallRunEnabled = st end)
createTumbler("Freecam", false).onToggle(function(st) toggleFreecam(st) end)
createButton("Спектатор: сброс", function()
    spectateTarget = nil
    Camera.CameraType = Enum.CameraType.Custom
    notify("Спектатор сброшен")
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
createTumbler("Anti-Fling", false).onToggle(function(st) antiFlingEnabled = st end)
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

-- ========== TAB: COSMETICS ==========
createTab("Cosmetics")
createSection("Аксессуары")
createTumbler("Headless", false).onToggle(function(st)
    headlessEnabled = st
    if st then applyHeadless() else removeCosmetics() end
end)
createTumbler("Korblox", false).onToggle(function(st)
    korbloxEnabled = st
    if st then applyKorblox() else removeCosmetics() end
end)

createSection("Анимации")
local animList = {
    "Default", "Zombie", "Vampire", "Werewolf", "Adidas", "Adidas Aura",
    "Ninja", "Robot", "Levitate", "Mage", "Stylish", "Ghost", "Knight", "Cartoony"
}
for _, animName in ipairs(animList) do
    createButton("Анимация: " .. animName, function()
        currentAnimPack = animName
        applyAnimPack(animName)
    end)
end

-- ========== TAB: WORLD ==========
createTab("World")
createSection("Lighting")
createTumbler("FullBright", false).onToggle(function(st)
    fullBrightEnabled = st
    if st then
        origBright, origAmbient = Lighting.Brightness, Lighting.Ambient
        Lighting.Brightness = 2
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
    else
        if origBright then Lighting.Brightness = origBright end
        if origAmbient then Lighting.Ambient = origAmbient end
    end
end)
createTumbler("No Fog", false).onToggle(function(st)
    noFogEnabled = st
    if st then
        origFog = Lighting.FogEnd
        Lighting.FogEnd = 1e6
    else
        if origFog then Lighting.FogEnd = origFog end
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
    WmGui.Enabled = st
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
        if (c:IsA("BodyVelocity") or c:IsA("BodyAngularVelocity") or c:IsA("BodyForce") or c:IsA("BodyThrust")) and c ~= bodyVelocity then
            c:Destroy()
        end
    end
end)

-- Anti-Ragdoll
local function bindAntiRagdoll(char)
    local hum = char:WaitForChild("Humanoid", 5)
    if not hum then return end
    hum.StateChanged:Connect(function(_, new)
        if antiRagdollEnabled and (new == Enum.HumanoidStateType.Ragdoll or new == Enum.HumanoidStateType.Physics) then
            hum:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
    end)
end
if LocalPlayer.Character then bindAntiRagdoll(LocalPlayer.Character) end
LocalPlayer.CharacterAdded:Connect(bindAntiRagdoll)

-- Wall Run (простая реализация: если рядом стена и идёт движение — прижимаем к стене)
RunService.Heartbeat:Connect(function()
    if not wallRunEnabled then return end
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")
    if not (root and hum) then return end
    if hum.MoveDirection.Magnitude < 0.1 then return end
    local rayOrigin = root.Position
    local rayDir = hum.MoveDirection.Unit * 3
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {char}
    params.FilterType = Enum.RaycastFilterType.Exclude
    local result = workspace:Raycast(rayOrigin, rayDir, params)
    if result then
        root.AssemblyLinearVelocity = root.AssemblyLinearVelocity + result.Normal * 10 + Vector3.yAxis * 20
    end
end)

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

setStatus("WIA HUB v11.0 загружен", C_OK)
notify("WIA HUB v11.0 готов", "success")