-- ================================================================= --
-- ПРАВКА 1: замени весь блок от "-- PLAYER LIST GUI"
-- до строки "TargetStatus.Parent = PlayerListMain" (включительно) на этот код
-- ================================================================= --

local playerListTumbler -- присваивается позже (правка 3)

local PlayerListGui = Instance.new("ScreenGui")
PlayerListGui.Name = "WiaPlayerList_v8"
PlayerListGui.ResetOnSpawn = false
PlayerListGui.Parent = CoreGui
PlayerListGui.Enabled = false

-- размер панели подстраивается под экран
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

-- заголовок (за него панель таскается пальцем)
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

-- кнопка закрытия
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
        playerListTumbler.setState(false) -- синхронизирует переключатель в меню
    else
        PlayerListGui.Enabled = false
    end
end)

-- прокручиваемый список
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

-- строки создаются прямо в ScrollingFrame
local PlayerListContainer = playerListScrollingFrame

-- нижняя панель: текущая цель + сброс
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


-- ================================================================= --
-- ПРАВКА 2: замени всю функцию updatePlayerList
-- (от "-- ========== PLAYER LIST FUNCTIONS ==========" до её конца "end")
-- на этот код
-- ================================================================= --

-- ========== PLAYER LIST FUNCTIONS ==========
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

            -- тап по AIM: выбрать / снять цель (правый клик больше не нужен)
            aimBtn.MouseButton1Click:Connect(function()
                setAimTarget(aimbotSelectedTarget == plr and nil or plr)
                updatePlayerList()
            end)
        end
    end
end

-- список обновляется сам при входе/выходе игроков
Players.PlayerAdded:Connect(function()
    if playerListEnabled then updatePlayerList() end
end)
Players.PlayerRemoving:Connect(function(plr)
    if aimbotSelectedTarget == plr then setAimTarget(nil) end
    task.defer(function()
        if playerListEnabled then updatePlayerList() end
    end)
end)


-- ================================================================= --
-- ПРАВКА 3: в разделе "TAB: PLAYER" замени
--     createTumbler("Player List GUI", false).onToggle(function(st)
-- на
--     playerListTumbler = createTumbler("Player List GUI", false)
--     playerListTumbler.onToggle(function(st)
-- (тело функции и "end)" остаются как были)
-- ================================================================= --