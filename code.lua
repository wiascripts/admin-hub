-- ================================================================= --
-- WIA HUB v12.1 :: whitewia / tordark
-- FIX: лимит 200 local-переменных (do ... end блоки)
-- FIX: fovCircle создаётся
-- FIX: безопасный parent для GUI (gethui / CoreGui / PlayerGui)
-- FIX: ошибки запуска показываются в warn + уведомление
-- ================================================================= --

local function main()

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

-- безопасная установка родителя для GUI
local function parentGui(gui)
    local ok = pcall(function()
        gui.Parent = (gethui and gethui()) or CoreGui
    end)
    if not ok or not gui.Parent then
        gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
    end
end

-- ========== COLORS ==========
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
local notify
do
    local NotifGui = Instance.new("ScreenGui")
    NotifGui.Name = "WiaNotifs"
    NotifGui.ResetOnSpawn = false
    NotifGui.DisplayOrder = 200
    parentGui(NotifGui)

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
    notify = function(text, kind)
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
local aimPart = "Head"

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

local dashEnabled, dashPower = false, 90
local dashKey = Enum.KeyCode.Q
local dashCooldown, dashLastUsed = 0.4, 0

local hubToggleKey = Enum.KeyCode.RightShift
local guiVisible = true
local waitingHubBind = false

local headlessEnabled, korbloxEnabled = false, false

-- ========== ANIMATION PACKS ==========
local PACKS, applyPack
do
    PACKS = {
        ["Adidas Sports"] = {
            WalkAnim = 18537392113, RunAnim = 18537384940, JumpAnim = 18537380791,
            FallAnim = 18537367238, SwimIdle = 18537387180, Swim = 18537389531,
            Animation1 = 18537376492, Animation2 = 18537371272, ClimbAnim = 18537363391,
        },
        ["Adidas Community"] = {
            WalkAnim = 122150855457006, RunAnim = 82598234841035, JumpAnim = 75290611992385,
            FallAnim = 98600215928904, SwimIdle = 109346520324160, Swim = 133308483266208,
            Animation1 = 122257458498464, Animation2 = 102357151005774, ClimbAnim = 88763136693023,
        },
        ["Adidas Aura"] = {
            WalkAnim = 83842218823011, RunAnim = 118320322718866, JumpAnim = 109996626521204,
            FallAnim = 95603166884636, SwimIdle = 94922130551805, Swim = 134530128383903,
            Animation1 = 110211186840347, Animation2 = 114191137265065, ClimbAnim = 97824616490448,
        },
        ["Wicked Popular"] = {
            WalkAnim = 92072849924640, RunAnim = 72301599441680, JumpAnim = 104325245285198,
            FallAnim = 121152442762481, Animation1 = 118832222982049, ClimbAnim = 131326830509784,
            SwimIdle = 113199415118199, Swim = 99384245425157, Animation2 = 76049494037641,
        },
        Elder = {
            WalkAnim = 10921111375, RunAnim = 10921104374, JumpAnim = 10921107367,
            FallAnim = 10921105765, SwimIdle = 10921110146, Swim = 10921108971,
            ClimbAnim = 10921100400, Animation1 = 10921101664, Animation2 = 10921102574,
        },
        Zombie = {
            WalkAnim = 10921355261, RunAnim = 616163682, JumpAnim = 10921351278,
            FallAnim = 10921350320, SwimIdle = 10921353442, Swim = 10921352344,
            Animation1 = 10921344533, Animation2 = 10921345304, ClimbAnim = 10921343576,
        },
        Mage = {
            WalkAnim = 10921152678, RunAnim = 10921148209, JumpAnim = 10921149743,
            FallAnim = 10921148939, SwimIdle = 10921151661, Swim = 10921150788,
            ClimbAnim = 10921143404, Animation1 = 10921144709, Animation2 = 10921145797,
        },
        ["Catwalk Glam"] = {
            WalkAnim = 109168724482748, RunAnim = 81024476153754, JumpAnim = 116936326516985,
            FallAnim = 92294537340807, SwimIdle = 98854111361360, Swim = 134591743181628,
            ClimbAnim = 119377220967554, Animation1 = 133806214992291, Animation2 = 94970088341563,
        },
        Astronaut = {
            WalkAnim = 10921046031, RunAnim = 10921039308, JumpAnim = 10921042494,
            FallAnim = 10921040576, SwimIdle = 10921045006, Swim = 10921044000,
            ClimbAnim = 10921032124, Animation1 = 10921034824, Animation2 = 10921036806,
        },
        ['Wicked "Dancing Through Life"'] = {
            WalkAnim = 73718308412641, RunAnim = 135515454877967, JumpAnim = 78508480717326,
            FallAnim = 78147885297412, SwimIdle = 129183123083281, Swim = 110657013921774,
            ClimbAnim = 129447497744818, Animation1 = 92849173543269, Animation2 = 132238900951109,
        },
        Werewolf = {
            WalkAnim = 10921342074, RunAnim = 10921336997, JumpAnim = nil,
            FallAnim = 10921337907, SwimIdle = 10921341319, Swim = 10921340419,
            ClimbAnim = 10921329322, Animation1 = 10921330408, Animation2 = 10921333667,
        },
        Superhero = {
            WalkAnim = 10921298616, RunAnim = 10921291831, JumpAnim = 10921294559,
            FallAnim = 10921293373, SwimIdle = 10921297391, Swim = 10921295495,
            ClimbAnim = 10921286911, Animation1 = 10921288909, Animation2 = 10921290167,
        },
        Toy = {
            WalkAnim = 10921312010, RunAnim = 10921306285, JumpAnim = 10921308158,
            FallAnim = 10921307241, SwimIdle = 10921310341, Swim = 10921309319,
            ClimbAnim = 10921300839, Animation1 = 10921301576, Animation2 = nil,
        },
        ["No Boundaries"] = {
            WalkAnim = 18747074203, RunAnim = 18747070484, JumpAnim = 18747069148,
            FallAnim = 18747062535, SwimIdle = 18747071682, Swim = 18747073181,
            ClimbAnim = 18747060903, Animation1 = 18747067405, Animation2 = 18747063918,
        },
        NFL = {
            WalkAnim = 110358958299415, RunAnim = 117333533048078, JumpAnim = 119846112151352,
            FallAnim = 129773241321032, SwimIdle = 79090109939093, Swim = 132697394189921,
            ClimbAnim = 134630013742019, Animation1 = 92080889861410, Animation2 = 74451233229259,
        },
        ["Amazon Unboxed"] = {
            WalkAnim = 90478085024465, RunAnim = 134824450619865, JumpAnim = 121454505477205,
            FallAnim = 94788218468396, SwimIdle = 129126268464847, Swim = 105962919001086,
            ClimbAnim = 121145883950231, Animation1 = 98281136301627, Animation2 = nil,
        },
        Vampire = {
            WalkAnim = 10921326949, RunAnim = 10921320299, JumpAnim = 10921322186,
            FallAnim = 10921321317, SwimIdle = 10921325443, Swim = 10921324408,
            ClimbAnim = 10921314188, Animation1 = 10921315373, Animation2 = nil,
        },
        Ninja = {
            Run=656118852, Walk=656121766, Jump=656117878, Fall=656115606,
            Swim=656119721, SwimIdle=656121397, Climb=656114359,
            Idle={656117400,656118341,886742569}
        },
        Robot = {
            Run=616091570, Walk=616095330, Jump=616090535, Fall=616087089,
            Swim=616092998, SwimIdle=616094091, Climb=616086039,
            Idle={616088211,616089559,885531463}
        },
        Levitation = {
            Run=616010382, Walk=616013216, Jump=616008936, Fall=616005863,
            Swim=616011509, SwimIdle=616012453, Climb=616003713,
            Idle={616006778,616008087,886862142}
        },
        Stylish = {
            Run=616140816, Walk=616146177, Jump=616139451, Fall=616134815,
            Swim=616143378, SwimIdle=616144772, Climb=616133594,
            Idle={616136790,616138447,886888594}
        },
        Bubbly = {
            Run=910025107, Walk=910034870, Jump=910016857, Fall=910001910,
            Swim=910028158, SwimIdle=910030921, Climb=909997997,
            Idle={910004836,910009958,1018536639}
        },
        Cartoon = {
            Run=742638842, Walk=742640026, Jump=742637942, Fall=742637151,
            Swim=742639220, SwimIdle=742639812, Climb=742636889,
            Idle={742637544,742638445,885477856}
        },
    }

    local ATTR_LAST = "AnimPack_Last"
    local applyingAnim = false

    local function waitForAnimate(char)
        for _ = 1, 40 do
            local a = char:FindFirstChild("Animate")
            if a and a:FindFirstChild("idle") and a:FindFirstChild("run") and a:FindFirstChild("walk") then
                return a
            end
            task.wait(0.1)
        end
        return nil
    end

    local function setAnim(animObj, id)
        if animObj and id then
            animObj.AnimationId = "rbxassetid://" .. tostring(id)
        end
    end

    local function stopAllTracks(hum)
        if not hum then return end
        for _, t in ipairs(hum:GetPlayingAnimationTracks()) do
            pcall(function() t:Stop(0) end)
        end
    end

    local function ensureAnim(folder, name)
        if not folder then return nil end
        local a = folder:FindFirstChild(name)
        if not a then
            a = Instance.new("Animation")
            a.Name = name
            a.Parent = folder
        end
        return a
    end

    local function ensureIdleSlots(idleFolder, n)
        if not idleFolder then return end
        n = n or 2
        for i = 1, n do
            ensureAnim(idleFolder, "Animation" .. i)
        end
    end

    local function pick(pack, ...)
        for i = 1, select("#", ...) do
            local k = select(i, ...)
            local v = pack[k]
            if v ~= nil then return v end
        end
        return nil
    end

    applyPack = function(packName)
        if applyingAnim then return false end
        applyingAnim = true

        local pack = PACKS[packName]
        if not pack then
            applyingAnim = false
            return false
        end

        local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
        local animate = waitForAnimate(char)
        if not animate then
            applyingAnim = false
            notify("Animate не найден", "error")
            return false
        end

        local hum = char:FindFirstChildOfClass("Humanoid")
        stopAllTracks(hum)

        local runObj = ensureAnim(animate:FindFirstChild("run"), "RunAnim")
        local walkObj = ensureAnim(animate:FindFirstChild("walk"), "WalkAnim")
        local jumpObj = ensureAnim(animate:FindFirstChild("jump"), "JumpAnim")
        local fallObj = ensureAnim(animate:FindFirstChild("fall"), "FallAnim")
        local climbObj = ensureAnim(animate:FindFirstChild("climb"), "ClimbAnim")
        local swimObj = ensureAnim(animate:FindFirstChild("swim"), "Swim")
        local swimIdleObj = ensureAnim(animate:FindFirstChild("swimidle"), "SwimIdle")
        local idleFolder = animate:FindFirstChild("idle")

        setAnim(walkObj, pick(pack, "WalkAnim", "Walk"))
        setAnim(runObj, pick(pack, "RunAnim", "Run"))
        setAnim(jumpObj, pick(pack, "JumpAnim", "Jump"))
        setAnim(fallObj, pick(pack, "FallAnim", "Fall"))
        setAnim(climbObj, pick(pack, "ClimbAnim", "Climb"))
        setAnim(swimObj, pick(pack, "Swim"))
        setAnim(swimIdleObj, pick(pack, "SwimIdle") or pick(pack, "Swim"))

        if idleFolder then
            local a1 = pick(pack, "Animation1")
            local a2 = pick(pack, "Animation2")
            if a1 or a2 then
                ensureIdleSlots(idleFolder, 2)
                local id1 = a1 or a2
                local id2 = a2 or a1 or id1
                setAnim(idleFolder:FindFirstChild("Animation1"), id1)
                setAnim(idleFolder:FindFirstChild("Animation2"), id2)
            elseif pack.Idle and #pack.Idle > 0 then
                ensureIdleSlots(idleFolder, math.max(2, #pack.Idle))
                setAnim(idleFolder:FindFirstChild("Animation1"), pack.Idle[1])
                setAnim(idleFolder:FindFirstChild("Animation2"), pack.Idle[2] or pack.Idle[1])
                for i = 3, #pack.Idle do
                    local a = idleFolder:FindFirstChild("Animation" .. i)
                    if a then setAnim(a, pack.Idle[i]) end
                end
            end
        end

        animate.Disabled = true
        task.wait(0.06)
        animate.Disabled = false

        if hum then
            pcall(function()
                hum:ChangeState(Enum.HumanoidStateType.Landed)
                task.wait(0.03)
                hum:ChangeState(Enum.HumanoidStateType.Running)
            end)
        end

        pcall(function() LocalPlayer:SetAttribute(ATTR_LAST, packName) end)
        applyingAnim = false
        notify("Анимация: " .. packName, "success")
        return true
    end

    LocalPlayer.CharacterAdded:Connect(function()
        task.wait(0.6)
        local saved = LocalPlayer:GetAttribute(ATTR_LAST)
        if type(saved) == "string" and saved ~= "" and PACKS[saved] then
            applyPack(saved)
        end
    end)
end

-- ========== COSMETICS ==========
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
    local mesh = head:FindFirstChildOfClass("SpecialMesh")
    if not mesh then
        mesh = Instance.new("SpecialMesh", head)
    end
    mesh.MeshType = Enum.MeshType.FileMesh
    mesh.MeshId = "rbxassetid://1095708"
    mesh.Scale = Vector3.new(0.001, 0.001, 0.001)
end

local function applyKorblox()
    local char = LocalPlayer.Character
    if not char then return end
    local KORBLOX_MESH = "rbxassetid://139607718"
    local KORBLOX_TEXTURE = "rbxassetid://139607389"
    local DARK = Color3.fromRGB(64, 64, 64)

    local upper = char:FindFirstChild("RightUpperLeg")
    local lower = char:FindFirstChild("RightLowerLeg")
    local foot = char:FindFirstChild("RightFoot")

    if upper and lower and foot then
        for _, p in ipairs({upper, lower, foot}) do
            for _, c in ipairs(p:GetChildren()) do
                if c:IsA("SpecialMesh") or c:IsA("CharacterMesh") then c:Destroy() end
            end
        end
        local mesh = Instance.new("SpecialMesh")
        mesh.MeshType = Enum.MeshType.FileMesh
        mesh.MeshId = KORBLOX_MESH
        mesh.TextureId = KORBLOX_TEXTURE
        mesh.Scale = Vector3.new(1, 1, 1)
        mesh.Parent = upper
        upper.Color = DARK
        lower.Transparency = 1
        foot.Transparency = 1
        return
    end

    local leg = char:FindFirstChild("Right Leg")
    if leg then
        for _, c in ipairs(leg:GetChildren()) do
            if c:IsA("SpecialMesh") or c:IsA("CharacterMesh") then c:Destroy() end
        end
        local mesh = Instance.new("SpecialMesh")
        mesh.MeshType = Enum.MeshType.FileMesh
        mesh.MeshId = KORBLOX_MESH
        mesh.TextureId = KORBLOX_TEXTURE
        mesh.Scale = Vector3.new(1, 1, 1)
        mesh.Parent = leg
        leg.Color = DARK
    end
end

local function removeCosmetics()
    local char = LocalPlayer.Character
    if not char then return end
    local head = char:FindFirstChild("Head")
    if head then
        head.Transparency = 0
        local m = head:FindFirstChildOfClass("SpecialMesh")
        if m and m.MeshId == "rbxassetid://1095708" then m:Destroy() end
    end
    for _, name in ipairs({"RightUpperLeg", "RightLowerLeg", "RightFoot", "Right Leg"}) do
        local p = char:FindFirstChild(name)
        if p then
            for _, c in ipairs(p:GetChildren()) do
                if c:IsA("SpecialMesh") and c.MeshId == "rbxassetid://139607718" then c:Destroy() end
            end
            if name == "RightLowerLeg" or name == "RightFoot" then
                p.Transparency = 0
            end
        end
    end
end

-- ========== WATERMARK ==========
local WmGui
do
    WmGui = Instance.new("ScreenGui")
    WmGui.Name = "WiaWm"
    WmGui.ResetOnSpawn = false
    WmGui.DisplayOrder = 50
    parentGui(WmGui)

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
    WmTitle.Text = "WIA HUB v12.1"
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
end

-- ========== PLAYER LIST ==========
local playerListTumbler
local PlayerListGui = Instance.new("ScreenGui")
PlayerListGui.Name = "WiaPlayerList"
PlayerListGui.ResetOnSpawn = false
PlayerListGui.Enabled = false
parentGui(PlayerListGui)

local PlayerListMain, PlayerListTitle, PlayerListContainer, TargetStatus, ResetTargetBtn
do
    local plV = workspace.CurrentCamera.ViewportSize
    local plW = math.clamp(plV.X * 0.5, 260, 340)
    local plH = math.clamp(plV.Y - 80, 200, 400)

    PlayerListMain = Instance.new("Frame")
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

    PlayerListTitle = Instance.new("TextLabel")
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

    PlayerListContainer = plScroll

    TargetStatus = Instance.new("TextLabel")
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

    ResetTargetBtn = Instance.new("TextButton")
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
end

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
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
end

-- ========== MAIN GUI ==========
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "WiaHubGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Enabled = true
parentGui(ScreenGui)

local MainFrame, Title, Underline, MinBtn, TabBar, PageHolder, StatusBar
do
    local vp0 = Camera.ViewportSize
    local menuW = math.clamp(vp0.X - 20, 250, 330)
    local menuH = math.clamp(vp0.Y - 40, 240, 470)

    MainFrame = Instance.new("Frame")
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

    Title = Instance.new("TextLabel")
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
    TitleVer.Text = "v12"
    TitleVer.TextColor3 = C_DIM
    TitleVer.TextSize = 11
    TitleVer.TextXAlignment = Enum.TextXAlignment.Left
    TitleVer.BackgroundTransparency = 1
    TitleVer.Font = Enum.Font.Gotham
    TitleVer.Parent = MainFrame

    Underline = Instance.new("Frame")
    Underline.Size = UDim2.new(1, -24, 0, 1)
    Underline.Position = UDim2.new(0, 12, 0, 34)
    Underline.BackgroundColor3 = C_STROKE
    Underline.BorderSizePixel = 0
    Underline.Parent = MainFrame

    MinBtn = Instance.new("TextButton")
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

    TabBar = Instance.new("ScrollingFrame")
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

    PageHolder = Instance.new("Frame")
    PageHolder.Size = UDim2.new(1, 0, 1, -98)
    PageHolder.Position = UDim2.new(0, 0, 0, 74)
    PageHolder.BackgroundTransparency = 1
    PageHolder.ClipsDescendants = true
    PageHolder.Parent = MainFrame

    StatusBar = Instance.new("TextLabel")
    StatusBar.Size = UDim2.new(1, -20, 0, 20)
    StatusBar.Position = UDim2.new(0, 12, 1, -22)
    StatusBar.Text = "Ready"
    StatusBar.TextColor3 = C_DIM
    StatusBar.TextSize = 11
    StatusBar.TextXAlignment = Enum.TextXAlignment.Left
    StatusBar.BackgroundTransparency = 1
    StatusBar.Font = Enum.Font.Gotham
    StatusBar.Parent = MainFrame
end

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
        t.page.Visible = on
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

do
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
end

makeDraggable(MainFrame, Title)
makeDraggable(PlayerListMain, PlayerListTitle)

-- ========== TOGGLE BUTTON ==========
do
    local ToggleGui = Instance.new("ScreenGui")
    ToggleGui.Name = "WiaToggle"
    ToggleGui.ResetOnSpawn = false
    parentGui(ToggleGui)

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
end

-- ========== FLY BUTTONS ==========
local FlyGui = Instance.new("ScreenGui")
FlyGui.Name = "WiaFly"
FlyGui.ResetOnSpawn = false
FlyGui.Enabled = false
parentGui(FlyGui)

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

local function registerElement(el) table.insert(allElements, el) end

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
    registerElement({ obj = lbl, name = text })
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
    registerElement({ obj = row, name = labelText })
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

    registerElement({ obj = row, name = labelText })
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
    btn.MouseButton1Click:Connect(function()
        callback(btn)
    end)
    registerElement({ obj = btn, name = labelText })
    return btn
end

-- ========== SEARCH BAR ==========
do
    local searchFrame = Instance.new("Frame")
    searchFrame.Size = UDim2.new(1, -24, 0, 32)
    searchFrame.Position = UDim2.new(0, 12, 0, 74)
    searchFrame.BackgroundColor3 = C_ROW
    searchFrame.BorderSizePixel = 0
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
            if el.obj and el.obj.Parent then el.obj.Visible = true end
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
end

PageHolder.Position = UDim2.new(0, 0, 0, 112)
PageHolder.Size = UDim2.new(1, 0, 1, -136)

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

-- ========== SILENT AIM ==========
if hookmetamethod and getnamecallmethod then
    pcall(function()
        local old
        old = hookmetamethod(game, "__namecall", function(self, ...)
            local method = getnamecallmethod()
            if method == "FireServer" and silentAimEnabled then
                local target = aimbotSelectedTarget
                if not target then
                    local minDist = aimbotFOV
                    for _, p in pairs(Players:GetPlayers()) do
                        if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild("Head") then
                            if teamCheckEnabled and p.Team == LocalPlayer.Team then continue end
                            local s, onScreen = Camera:WorldToViewportPoint(p.Character.Head.Position)
                            if onScreen then
                                local d = (Vector2.new(s.X, s.Y) - Vector2.new(Mouse.X, Mouse.Y)).Magnitude
                                if d < minDist then minDist = d target = p end
                            end
                        end
                    end
                end
                if target and target.Character then
                    local ap = target.Character:FindFirstChild(aimPart) or target.Character:FindFirstChild("Head")
                    if ap then
                        if silentAimWallcheck then
                            local origin = Camera.CFrame.Position
                            local dir = ap.Position - origin
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
                                args[i] = CFrame.new(args[i].Position, ap.Position)
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
    if updatePlayerList then updatePlayerList() end
end)

local function makeRowButton(parent, text, xOff, color)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 44, 0, 30)
    b.Position = UDim2.new(1, xOff, 0.5, -15)
    b.Text = text
    b.TextColor3 = C_TEXT
    b.TextSize = 11
    b.Font = Enum.Font.GothamBold
    b.BackgroundColor3 = color
    b.BorderSizePixel = 0
    b.Parent = parent
    addCorner(b, 6)
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
            row.Size = UDim2.new(1, 0, 0, 42)
            row.BackgroundColor3 = sel and Color3.fromRGB(30, 55, 45) or C_ROW
            row.BorderSizePixel = 0
            row.LayoutOrder = order
            row.Parent = PlayerListContainer
            addCorner(row, 8)

            local nm = Instance.new("TextLabel")
            nm.Size = UDim2.new(1, -160, 1, 0)
            nm.Position = UDim2.new(0, 10, 0, 0)
            nm.BackgroundTransparency = 1
            nm.Text = plr.Name
            nm.TextColor3 = C_TEXT
            nm.TextSize = 12
            nm.Font = Enum.Font.Gotham
            nm.TextXAlignment = Enum.TextXAlignment.Left
            nm.TextTruncate = Enum.TextTruncate.AtEnd
            nm.Parent = row

            local spBtn = makeRowButton(row, "SP", -142, C_ROW_D)
            local tpBtn = makeRowButton(row, "TP", -96, C_ROW_D)
            local aimBtn = makeRowButton(row, sel and "✓" or "AIM", -50,
                sel and Color3.fromRGB(30, 100, 65) or C_ROW_D)

            spBtn.MouseButton1Click:Connect(function()
                spectateTarget = plr
                if freecamEnabled then
                    toggleFreecam(false)
                end
                notify("Спектатор: " .. plr.Name, "success")
            end)

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
    if spectateTarget == plr then
        spectateTarget = nil
        Camera.CameraType = Enum.CameraType.Custom
    end
    task.defer(function()
        if playerListEnabled then updatePlayerList() end
    end)
end)

-- ========== AIMBOT ==========
local fovCircle = Drawing and Drawing.new("Circle") or nil
if fovCircle then
    fovCircle.Thickness = 1
    fovCircle.NumSides = 64
    fovCircle.Filled = false
    fovCircle.Color = C_ACCENT
    fovCircle.Visible = false
end

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

-- ========== DRAWING POOLS ==========
local skelPool = {}
local espPool = {}
local textPool = {}

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

local skeletonSelfTest = false

RunService.RenderStepped:Connect(function()
    if not Drawing then return end

    -- ===== SKELETON =====
    if skeletonEnabled then
        local idx = 0
        for _, plr in pairs(Players:GetPlayers()) do
            local valid = plr ~= LocalPlayer or skeletonSelfTest
            if valid and plr.Character then
                local isTeammate = teamCheckEnabled and plr.Team == LocalPlayer.Team and plr ~= LocalPlayer
                if not isTeammate then
                    for _, joint in ipairs(plr.Character:GetDescendants()) do
                        if joint:IsA("Motor6D") and joint.Part0 and joint.Part1 then
                            local p0 = Camera:WorldToViewportPoint(joint.Part0.Position)
                            local p1 = Camera:WorldToViewportPoint(joint.Part1.Position)
                            if p0.Z > 0 and p1.Z > 0 then
                                idx = idx + 1
                                local line = getLine(skelPool, idx)
                                line.From = Vector2.new(p0.X, p0.Y)
                                line.To = Vector2.new(p1.X, p1.Y)
                                line.Color = skeletonColor
                                line.Thickness = 1.5
                                line.Transparency = 0.15
                            end
                        end
                    end
                end
            end
        end
        for i = idx + 1, #skelPool do skelPool[i].Visible = false end
    else
        for i = 1, #skelPool do skelPool[i].Visible = false end
    end

    -- ===== ESP =====
    local eIdx, tIdx = 0, 0
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local isTeammate = teamCheckEnabled and plr.Team == LocalPlayer.Team
            if not isTeammate then
                local head = plr.Character:FindFirstChild("Head")
                local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                if head and hum then
                    local pos, onScreen = Camera:WorldToViewportPoint(head.Position)
                    if onScreen then
                        local dist = math.floor((head.Position - Camera.CFrame.Position).Magnitude)
                        local size = math.clamp(100 / math.max(dist, 1) * 10, 15, 45)

                        if espBoxEnabled then
                            local x, y = pos.X - size / 2, pos.Y - size / 2
                            local edges = {
                                {Vector2.new(x, y), Vector2.new(x + size, y)},
                                {Vector2.new(x + size, y), Vector2.new(x + size, y + size)},
                                {Vector2.new(x + size, y + size), Vector2.new(x, y + size)},
                                {Vector2.new(x, y + size), Vector2.new(x, y)},
                            }
                            for _, e in ipairs(edges) do
                                eIdx = eIdx + 1
                                local line = getLine(espPool, eIdx)
                                line.From = e[1]
                                line.To = e[2]
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
    end

    -- ===== ITEM ESP =====
    if itemEspEnabled then
        for _, obj in pairs(workspace:GetDescendants()) do
            local tool = obj:IsA("Tool") and obj or (obj:IsA("Model") and obj:FindFirstChildOfClass("Tool"))
            if tool then
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

    for i = eIdx + 1, #espPool do espPool[i].Visible = false end
    for i = tIdx + 1, #textPool do textPool[i].Visible = false end
end)

-- ========== CHAMS ==========
RunService.Heartbeat:Connect(function()
    if wallhackEnabled then
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                local isTeammate = teamCheckEnabled and plr.Team == LocalPlayer.Team
                if not isTeammate then
                    local existing = plr.Character:FindFirstChild("WIA_WH")
                    if not existing then
                        local hl = Instance.new("Highlight")
                        hl.Name = "WIA_WH"
                        hl.FillColor = C_ACCENT
                        hl.FillTransparency = chamsOpacity
                        hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                        hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        hl.Parent = plr.Character
                    else
                        existing.FillTransparency = chamsOpacity
                    end
                end
            end
        end
    end
end)

-- ========== FREECAM ==========
local freecamConnection = nil
local freecamSpeed = 50
function toggleFreecam(st)
    freecamEnabled = st
    if st then
        spectateTarget = nil
        local camera = workspace.CurrentCamera
        camera.CameraType = Enum.CameraType.Scriptable
        camera.CameraSubject = nil
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
            local delta = UserInputService:GetMouseDelta()
            yaw = yaw - delta.X * 0.003
            pitch = math.clamp(pitch - delta.Y * 0.003, -math.pi / 2, math.pi / 2)
            camera.CFrame = CFrame.new(cf.Position) * CFrame.Angles(pitch, yaw, 0)
        end)
        notify("Freecam ON", "success")
    else
        if freecamConnection then freecamConnection:Disconnect() freecamConnection = nil end
        workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            workspace.CurrentCamera.CameraSubject = hum
        end
        notify("Freecam OFF")
    end
end

-- ========== SPECTATE ==========
RunService.RenderStepped:Connect(function()
    if spectateTarget then
        local char = spectateTarget.Character
        local head = char and char:FindFirstChild("Head")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if head and root then
            Camera.CameraType = Enum.CameraType.Scriptable
            Camera.CameraSubject = nil
            local offset = root.CFrame.LookVector * -14 + Vector3.new(0, 6, 0)
            Camera.CFrame = CFrame.new(head.Position + offset, head.Position)
        end
    elseif Camera.CameraType == Enum.CameraType.Scriptable and not freecamEnabled then
        Camera.CameraType = Enum.CameraType.Custom
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum then
            Camera.CameraSubject = hum
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
createTumbler("Skeleton Self Test", false).onToggle(function(st) skeletonSelfTest = st end)
createTumbler("Team Check", true).onToggle(function(st) teamCheckEnabled = st end)
createTumbler("Item ESP", false).onToggle(function(st) itemEspEnabled = st end)
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

do
    local colors = {
        {name = "Purple", c = Color3.fromRGB(124, 92, 255)},
        {name = "Red", c = Color3.fromRGB(220, 80, 80)},
        {name = "Green", c = Color3.fromRGB(80, 200, 120)},
        {name = "Blue", c = Color3.fromRGB(80, 140, 220)},
        {name = "Yellow", c = Color3.fromRGB(220, 200, 80)},
        {name = "White", c = Color3.fromRGB(240, 240, 240)},
    }
    local espColorIdx, skelColorIdx = 1, 1
    createButton("ESP Color: " .. colors[espColorIdx].name, function(b)
        espColorIdx = espColorIdx % #colors + 1
        espColor = colors[espColorIdx].c
        if b then b.Text = "ESP Color: " .. colors[espColorIdx].name end
    end)
    createButton("Skeleton Color: " .. colors[skelColorIdx].name, function(b)
        skelColorIdx = skelColorIdx % #colors + 1
        skeletonColor = colors[skelColorIdx].c
        if b then b.Text = "Skeleton Color: " .. colors[skelColorIdx].name end
    end)
end

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
createButton("Dash Key: " .. dashKey.Name, function(b)
    if waitingHubBind then return end
    if b then b.Text = "Нажми клавишу..." end
    local c
    c = UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            dashKey = input.KeyCode
            if b then b.Text = "Dash Key: " .. dashKey.Name end
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
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if hum then Camera.CameraSubject = hum end
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
do
    local sortedPacks = {}
    for name in pairs(PACKS) do table.insert(sortedPacks, name) end
    table.sort(sortedPacks, function(a, b) return a:lower() < b:lower() end)
    for _, animName in ipairs(sortedPacks) do
        createButton("Анимация: " .. animName, function()
            applyPack(animName)
        end)
    end
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
hubKeyBtn = createButton("Hub Key: " .. hubToggleKey.Name, function(b)
    if waitingHubBind then return end
    waitingHubBind = true
    if b then b.Text = "Нажми клавишу..." end
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

do
    local function bindAntiRagdoll(char)
        local hum = char:WaitForChild("Humanoid", 5)
        if not hum then return end
        hum.StateChanged:Connect(function(_, new)
            if antiRagdollEnabled and (new == Enum.HumanoidStateType.Ragdoll or new == Enum.HumanoidStateType.Physics) then
                hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
        end)
    end
    if LocalPlayer.Character then task.spawn(bindAntiRagdoll, LocalPlayer.Character) end
    LocalPlayer.CharacterAdded:Connect(bindAntiRagdoll)
end

RunService.Heartbeat:Connect(function()
    if not wallRunEnabled then return end
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")
    if not (root and hum) then return end
    if hum.MoveDirection.Magnitude < 0.1 then return end
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {char}
    params.FilterType = Enum.RaycastFilterType.Exclude
    local result = workspace:Raycast(root.Position, hum.MoveDirection.Unit * 3, params)
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

do
    local vu = game:GetService("VirtualUser")
    LocalPlayer.Idled:Connect(function()
        if antiAFKEnabled then
            vu:Button2Down(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
            task.wait(1)
            vu:Button2Up(Vector2.new(0, 0), workspace.CurrentCamera.CFrame)
        end
    end)
end

UserInputService.JumpRequest:Connect(function()
    if infiniteJumpEnabled and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

setStatus("WIA HUB v12.1 загружен", C_OK)
notify("WIA HUB v12.1 готов", "success")

end -- main

-- ========== ЗАПУСК С ПОКАЗОМ ОШИБОК ==========
local ok, err = xpcall(main, function(e)
    return tostring(e) .. "\n" .. debug.traceback()
end)
if not ok then
    warn("[WIA HUB] Ошибка запуска:\n" .. tostring(err))
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = "WIA HUB: ошибка",
            Text = tostring(err):sub(1, 140),
            Duration = 15,
        })
    end)
end