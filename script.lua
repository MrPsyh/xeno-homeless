--[[
    XENO HOMELESS LIFE SCRIPT v9.0
    by Wayne
    - Выбор целей, режим для целей с огромными хитбоксами
    - ESP, телепорт, слайдеры, переключатели
    - Открыть/закрыть: T
]]

local player = game.Players.LocalPlayer
local mouse = player:GetMouse()
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- ===== НАСТРОЙКИ =====
local CONFIG = {
    HitboxMultiplier = 1.5,
    HitboxTransparency = 0.99,
    ESPTransparency = 0.2,
    ESPEnabled = true,
    HitboxEnabled = true,
    TargetModeEnabled = false,
    TargetMultiplier = 10,
    TargetTransparency = 0.9,
    AccentColor = Color3.new(0.7, 0.1, 1),
}
-- =====================

local menuOpen = false
local selectedPlayer = nil
local selectedTargets = {}
local espObjects = {}
local hitboxParts = {}
local guiCreated = false

-- ---- ВСПОМОГАТЕЛЬНЫЕ ФУНКЦИИ ----
local function CreateSlider(parent, yPos, labelText, minVal, maxVal, defaultVal, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -20, 0, 35)
    frame.Position = UDim2.new(0, 10, 0, yPos)
    frame.BackgroundTransparency = 1
    frame.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.4, 0, 1, 0)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText .. ": " .. tostring(defaultVal)
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextScaled = true
    label.Font = Enum.Font.Gotham
    label.Parent = frame

    local sliderBg = Instance.new("Frame")
    sliderBg.Size = UDim2.new(0.5, 0, 0.5, 0)
    sliderBg.Position = UDim2.new(0.45, 0, 0.25, 0)
    sliderBg.BackgroundColor3 = Color3.new(0.2, 0.2, 0.3)
    sliderBg.BorderSizePixel = 0
    sliderBg.Parent = frame
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = sliderBg

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((defaultVal - minVal) / (maxVal - minVal), 0, 1, 0)
    fill.BackgroundColor3 = CONFIG.AccentColor
    fill.BorderSizePixel = 0
    fill.Parent = sliderBg
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 4)
    fillCorner.Parent = fill

    local knob = Instance.new("TextButton")
    knob.Size = UDim2.new(0, 18, 0, 18)
    knob.Position = UDim2.new((defaultVal - minVal) / (maxVal - minVal), -9, 0.5, -9)
    knob.BackgroundColor3 = CONFIG.AccentColor
    knob.Text = ""
    knob.BorderSizePixel = 0
    knob.Parent = sliderBg
    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob

    local dragging = false
    local function updateSlider(input)
        local relX = (input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X
        relX = math.clamp(relX, 0, 1)
        local val = minVal + (maxVal - minVal) * relX
        val = math.round(val * 100) / 100
        fill.Size = UDim2.new(relX, 0, 1, 0)
        knob.Position = UDim2.new(relX, -9, 0.5, -9)
        label.Text = labelText .. ": " .. tostring(val)
        callback(val)
    end

    knob.MouseButton1Down:Connect(function() dragging = true end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    mouse.Move:Connect(function()
        if dragging then
            local pos = mouse.X
            local relX = (pos - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X
            relX = math.clamp(relX, 0, 1)
            local val = minVal + (maxVal - minVal) * relX
            val = math.round(val * 100) / 100
            fill.Size = UDim2.new(relX, 0, 1, 0)
            knob.Position = UDim2.new(relX, -9, 0.5, -9)
            label.Text = labelText .. ": " .. tostring(val)
            callback(val)
        end
    end)
    sliderBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then updateSlider(input) end
    end)

    return frame
end

local function CreateToggle(parent, yPos, labelText, defaultState, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -20, 0, 30)
    frame.Position = UDim2.new(0, 10, 0, yPos)
    frame.BackgroundTransparency = 1
    frame.Parent = parent

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.6, 0, 1, 0)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = Color3.new(1, 1, 1)
    label.TextScaled = true
    label.Font = Enum.Font.Gotham
    label.Parent = frame

    local toggleBg = Instance.new("Frame")
    toggleBg.Size = UDim2.new(0, 50, 0, 24)
    toggleBg.Position = UDim2.new(0.75, 0, 0.1, 0)
    toggleBg.BackgroundColor3 = defaultState and CONFIG.AccentColor or Color3.new(0.3, 0.3, 0.3)
    toggleBg.BorderSizePixel = 0
    toggleBg.Parent = frame
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = toggleBg

    local knob = Instance.new("TextButton")
    knob.Size = UDim2.new(0, 20, 0, 20)
    knob.Position = defaultState and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
    knob.BackgroundColor3 = Color3.new(1, 1, 1)
    knob.Text = ""
    knob.BorderSizePixel = 0
    knob.Parent = toggleBg
    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = knob

    local state = defaultState
    toggleBg.MouseButton1Click:Connect(function()
        state = not state
        toggleBg.BackgroundColor3 = state and CONFIG.AccentColor or Color3.new(0.3, 0.3, 0.3)
        knob.Position = state and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
        callback(state)
    end)

    return frame
end

-- ---- ГЛАВНОЕ МЕНЮ ----
local function CreateMenu()
    if guiCreated then return end
    guiCreated = true

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "XenoMenu"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = player:WaitForChild("PlayerGui")

    local mainFrame = Instance.new("Frame")
    mainFrame.Size = UDim2.new(0, 600, 0, 620)
    mainFrame.Position = UDim2.new(0.5, -300, 0.5, -310)
    mainFrame.BackgroundColor3 = Color3.new(0.1, 0.05, 0.2)
    mainFrame.BackgroundTransparency = 0.1
    mainFrame.BorderSizePixel = 1
    mainFrame.BorderColor3 = CONFIG.AccentColor
    mainFrame.Active = true
    mainFrame.Draggable = true
    mainFrame.Parent = screenGui
    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = UDim.new(0, 12)
    mainCorner.Parent = mainFrame

    -- Заголовок
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.Position = UDim2.new(0, 0, 0, 0)
    title.BackgroundColor3 = CONFIG.AccentColor
    title.BackgroundTransparency = 0.3
    title.Text = "⚡ XENO HOMELESS v9 ⚡ by Wayne"
    title.TextColor3 = Color3.new(1, 1, 1)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.Parent = mainFrame
    local titleCorner = Instance.new("UICorner")
    titleCorner.CornerRadius = UDim.new(0, 12)
    titleCorner.Parent = title

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 30, 0, 30)
    closeBtn.Position = UDim2.new(1, -35, 0, 5)
    closeBtn.BackgroundColor3 = Color3.new(0.3, 0, 0)
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.new(1, 1, 1)
    closeBtn.TextScaled = true
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = mainFrame
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(1, 0)
    closeCorner.Parent = closeBtn
    closeBtn.MouseButton1Click:Connect(function()
        menuOpen = false
        screenGui.Enabled = false
    end)

    -- Вкладки
    local tabFrame = Instance.new("Frame")
    tabFrame.Size = UDim2.new(1, 0, 0, 35)
    tabFrame.Position = UDim2.new(0, 0, 0, 40)
    tabFrame.BackgroundTransparency = 1
    tabFrame.Parent = mainFrame

    local tabs = {}
    local currentTab = nil
    local contentFrame = Instance.new("Frame")
    contentFrame.Size = UDim2.new(1, -10, 1, -95)
    contentFrame.Position = UDim2.new(0, 5, 0, 75)
    contentFrame.BackgroundColor3 = Color3.new(0.05, 0.05, 0.1)
    contentFrame.BackgroundTransparency = 0.3
    contentFrame.BorderSizePixel = 0
    contentFrame.Parent = mainFrame
    local contentCorner = Instance.new("UICorner")
    contentCorner.CornerRadius = UDim.new(0, 8)
    contentCorner.Parent = contentFrame

    local function createTab(name, buildFunc)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0.2, 0, 1, 0)
        btn.BackgroundTransparency = 0.2
        btn.BackgroundColor3 = Color3.new(0.1, 0.05, 0.2)
        btn.Text = name
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.TextScaled = true
        btn.Font = Enum.Font.GothamBold
        btn.Parent = tabFrame
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 8)
        btnCorner.Parent = btn

        local container = Instance.new("Frame")
        container.Size = UDim2.new(1, 0, 1, 0)
        container.BackgroundTransparency = 1
        container.Visible = false
        container.Parent = contentFrame

        btn.MouseButton1Click:Connect(function()
            if currentTab then
                tabs[currentTab].container.Visible = false
                tabs[currentTab].btn.BackgroundColor3 = Color3.new(0.1, 0.05, 0.2)
            end
            container.Visible = true
            btn.BackgroundColor3 = CONFIG.AccentColor
            currentTab = name
            if buildFunc then buildFunc(container) end
        end)

        tabs[name] = {btn = btn, container = container}
        return container
    end

    -- ---- ВКЛАДКИ ----
    local espBuilt = false
    createTab("ESP", function(container)
        if espBuilt then return end
        espBuilt = true
        CreateSlider(container, 5, "Прозрачность ESP", 0, 1, CONFIG.ESPTransparency, function(val)
            CONFIG.ESPTransparency = val
            if CONFIG.ESPEnabled then UpdateESP() end
        end)
        CreateToggle(container, 50, "ESP Вкл/Выкл", CONFIG.ESPEnabled, function(state)
            CONFIG.ESPEnabled = state
            if state then UpdateESP() else ClearESP() end
        end)
    end)

    local hitboxBuilt = false
    createTab("Hitbox", function(container)
        if hitboxBuilt then return end
        hitboxBuilt = true
        CreateToggle(container, 5, "Хитбоксы Вкл/Выкл", CONFIG.HitboxEnabled, function(state)
            CONFIG.HitboxEnabled = state
            UpdateHitboxes()
        end)
        CreateSlider(container, 45, "Множитель хитбоксов", 1, 5, CONFIG.HitboxMultiplier, function(val)
            CONFIG.HitboxMultiplier = val
            if CONFIG.HitboxEnabled then UpdateHitboxes() end
        end)
        CreateSlider(container, 90, "Прозрачность хитбоксов", 0.8, 1, CONFIG.HitboxTransparency, function(val)
            CONFIG.HitboxTransparency = val
            if CONFIG.HitboxEnabled then UpdateHitboxes() end
        end)
        local sep = Instance.new("Frame", container)
        sep.Size = UDim2.new(0.9, 0, 0, 2)
        sep.Position = UDim2.new(0.05, 0, 0, 135)
        sep.BackgroundColor3 = CONFIG.AccentColor
        sep.BackgroundTransparency = 0.5

        CreateToggle(container, 145, "Режим для целей", CONFIG.TargetModeEnabled, function(state)
            CONFIG.TargetModeEnabled = state
            UpdateHitboxes()
        end)
        CreateSlider(container, 185, "Множитель для целей", 1, 20, CONFIG.TargetMultiplier, function(val)
            CONFIG.TargetMultiplier = val
            if CONFIG.TargetModeEnabled then UpdateHitboxes() end
        end)
        CreateSlider(container, 230, "Прозрачность для целей", 0.8, 1, CONFIG.TargetTransparency, function(val)
            CONFIG.TargetTransparency = val
            if CONFIG.TargetModeEnabled then UpdateHitboxes() end
        end)
    end)

    local targetsBuilt = false
    createTab("Цели", function(container)
        if targetsBuilt then return end
        targetsBuilt = true

        local btnFrame = Instance.new("Frame", container)
        btnFrame.Size = UDim2.new(1, -20, 0, 30)
        btnFrame.Position = UDim2.new(0, 10, 0, 5)
        btnFrame.BackgroundTransparency = 1

        local selectAll = Instance.new("TextButton", btnFrame)
        selectAll.Size = UDim2.new(0.4, 0, 1, 0)
        selectAll.Position = UDim2.new(0, 0, 0, 0)
        selectAll.BackgroundColor3 = CONFIG.AccentColor
        selectAll.Text = "Выбрать всех"
        selectAll.TextColor3 = Color3.new(1,1,1)
        selectAll.TextScaled = true
        selectAll.Font = Enum.Font.GothamBold
        local corner1 = Instance.new("UICorner", selectAll)
        corner1.CornerRadius = UDim.new(0, 6)

        local deselectAll = Instance.new("TextButton", btnFrame)
        deselectAll.Size = UDim2.new(0.4, 0, 1, 0)
        deselectAll.Position = UDim2.new(0.55, 0, 0, 0)
        deselectAll.BackgroundColor3 = Color3.new(0.3, 0, 0)
        deselectAll.Text = "Снять всех"
        deselectAll.TextColor3 = Color3.new(1,1,1)
        deselectAll.TextScaled = true
        deselectAll.Font = Enum.Font.GothamBold
        local corner2 = Instance.new("UICorner", deselectAll)
        corner2.CornerRadius = UDim.new(0, 6)

        local listFrame = Instance.new("ScrollingFrame", container)
        listFrame.Size = UDim2.new(1, -20, 0, 420)
        listFrame.Position = UDim2.new(0, 10, 0, 45)
        listFrame.BackgroundColor3 = Color3.new(0.05,0.05,0.1)
        listFrame.BackgroundTransparency = 0.5
        listFrame.BorderSizePixel = 0
        local listCorner = Instance.new("UICorner", listFrame)
        listCorner.CornerRadius = UDim.new(0, 6)
        local layout = Instance.new("UIListLayout", listFrame)
        layout.Padding = UDim.new(0, 2)
        layout.SortOrder = Enum.SortOrder.Name

        local function refreshTargetList()
            for _, child in pairs(listFrame:GetChildren()) do
                if child:IsA("Frame") and child.Name == "TargetItem" then child:Destroy() end
            end
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= player then
                    local item = Instance.new("Frame", listFrame)
                    item.Name = "TargetItem"
                    item.Size = UDim2.new(1, 0, 0, 28)
                    item.BackgroundTransparency = 1

                    local label = Instance.new("TextLabel", item)
                    label.Size = UDim2.new(0.7, 0, 1, 0)
                    label.Position = UDim2.new(0, 0, 0, 0)
                    label.BackgroundTransparency = 1
                    label.Text = plr.Name
                    label.TextColor3 = Color3.new(1,1,1)
                    label.TextScaled = true
                    label.Font = Enum.Font.Gotham
                    label.TextXAlignment = Enum.TextXAlignment.Left

                    local toggleBg = Instance.new("Frame", item)
                    toggleBg.Size = UDim2.new(0, 40, 0, 20)
                    toggleBg.Position = UDim2.new(0.8, 0, 0.15, 0)
                    toggleBg.BackgroundColor3 = Color3.new(0.3,0.3,0.3)
                    toggleBg.BorderSizePixel = 0
                    local corner = Instance.new("UICorner", toggleBg)
                    corner.CornerRadius = UDim.new(0, 10)

                    local knob = Instance.new("TextButton", toggleBg)
                    knob.Size = UDim2.new(0, 16, 0, 16)
                    knob.Position = UDim2.new(0, 2, 0.5, -8)
                    knob.BackgroundColor3 = Color3.new(1,1,1)
                    knob.Text = ""
                    knob.BorderSizePixel = 0
                    local knobCorner = Instance.new("UICorner", knob)
                    knobCorner.CornerRadius = UDim.new(1, 0)

                    local state = false
                    for _, v in pairs(selectedTargets) do
                        if v == plr then state = true break end
                    end
                    if state then
                        toggleBg.BackgroundColor3 = CONFIG.AccentColor
                        knob.Position = UDim2.new(1, -18, 0.5, -8)
                    end

                    local function toggle()
                        state = not state
                        toggleBg.BackgroundColor3 = state and CONFIG.AccentColor or Color3.new(0.3,0.3,0.3)
                        knob.Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8)
                        if state then
                            table.insert(selectedTargets, plr)
                        else
                            for i, v in pairs(selectedTargets) do
                                if v == plr then table.remove(selectedTargets, i) break end
                            end
                        end
                        UpdateHitboxes()
                    end

                    toggleBg.MouseButton1Click:Connect(toggle)
                    knob.MouseButton1Click:Connect(toggle)
                end
            end
        end

        selectAll.MouseButton1Click:Connect(function()
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= player then
                    local found = false
                    for _, v in pairs(selectedTargets) do
                        if v == plr then found = true break end
                    end
                    if not found then
                        table.insert(selectedTargets, plr)
                    end
                end
            end
            refreshTargetList()
            UpdateHitboxes()
        end)

        deselectAll.MouseButton1Click:Connect(function()
            selectedTargets = {}
            refreshTargetList()
            UpdateHitboxes()
        end)

        refreshTargetList()
        Players.PlayerAdded:Connect(refreshTargetList)
        Players.PlayerRemoving:Connect(refreshTargetList)
    end)

    createTab("Teleport", function(container)
        local lbl = Instance.new("TextLabel", container)
        lbl.Size = UDim2.new(1, -20, 0, 30)
        lbl.Position = UDim2.new(0, 10, 0, 5)
        lbl.BackgroundTransparency = 1
        lbl.Text = "Выбери игрока:"
        lbl.TextColor3 = Color3.new(1,1,1)
        lbl.TextScaled = true
        lbl.Font = Enum.Font.Gotham

        local list = Instance.new("ScrollingFrame", container)
        list.Size = UDim2.new(1, -20, 0, 150)
        list.Position = UDim2.new(0, 10, 0, 40)
        list.BackgroundColor3 = Color3.new(0.05,0.05,0.1)
        list.BackgroundTransparency = 0.5
        list.BorderSizePixel = 0
        local listCorner = Instance.new("UICorner", list)
        listCorner.CornerRadius = UDim.new(0, 6)
        local layout = Instance.new("UIListLayout", list)
        layout.Padding = UDim.new(0, 2)
        layout.SortOrder = Enum.SortOrder.Name

        local function refreshList()
            for _, child in pairs(list:GetChildren()) do
                if child:IsA("TextButton") then child:Destroy() end
            end
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= player then
                    local btn = Instance.new("TextButton", list)
                    btn.Size = UDim2.new(1, 0, 0, 25)
                    btn.BackgroundColor3 = Color3.new(0.1,0.1,0.15)
                    btn.Text = plr.Name
                    btn.TextColor3 = Color3.new(1,1,1)
                    btn.TextScaled = true
                    btn.Font = Enum.Font.Gotham
                    local btnCorner = Instance.new("UICorner", btn)
                    btnCorner.CornerRadius = UDim.new(0, 4)
                    btn.MouseButton1Click:Connect(function()
                        selectedPlayer = plr
                        for _, b in pairs(list:GetChildren()) do
                            if b:IsA("TextButton") then
                                b.BackgroundColor3 = Color3.new(0.1,0.1,0.15)
                            end
                        end
                        btn.BackgroundColor3 = CONFIG.AccentColor
                    end)
                end
            end
        end
        refreshList()
        Players.PlayerAdded:Connect(refreshList)
        Players.PlayerRemoving:Connect(refreshList)

        local tpBtn = Instance.new("TextButton", container)
        tpBtn.Size = UDim2.new(0.8, 0, 0, 35)
        tpBtn.Position = UDim2.new(0.1, 0, 0, 200)
        tpBtn.BackgroundColor3 = CONFIG.AccentColor
        tpBtn.Text = "ТЕЛЕПОРТ К ВЫБРАННОМУ"
        tpBtn.TextColor3 = Color3.new(1,1,1)
        tpBtn.TextScaled = true
        tpBtn.Font = Enum.Font.GothamBold
        local tpCorner = Instance.new("UICorner", tpBtn)
        tpCorner.CornerRadius = UDim.new(0, 8)
        tpBtn.MouseButton1Click:Connect(function()
            if selectedPlayer and selectedPlayer.Character and selectedPlayer.Character:FindFirstChild("HumanoidRootPart") then
                local char = player.Character
                if char and char:FindFirstChild("HumanoidRootPart") then
                    char.HumanoidRootPart.CFrame = selectedPlayer.Character.HumanoidRootPart.CFrame
                end
            end
        end)
    end)

    createTab("Настройки", function(container)
        local stopBtn = Instance.new("TextButton", container)
        stopBtn.Size = UDim2.new(0.8, 0, 0, 40)
        stopBtn.Position = UDim2.new(0.1, 0, 0, 20)
        stopBtn.BackgroundColor3 = Color3.new(0.5, 0, 0)
        stopBtn.Text = "ВЫКЛЮЧИТЬ СКРИПТ"
        stopBtn.TextColor3 = Color3.new(1,1,1)
        stopBtn.TextScaled = true
        stopBtn.Font = Enum.Font.GothamBold
        local stopCorner = Instance.new("UICorner", stopBtn)
        stopCorner.CornerRadius = UDim.new(0, 8)
        stopBtn.MouseButton1Click:Connect(function()
            _G.StopXeno = true
        end)
    end)

    tabs["ESP"].btn.MouseButton1Click:Fire()
    screenGui.Enabled = false

    local function ToggleMenu()
        menuOpen = not menuOpen
        screenGui.Enabled = menuOpen
        if menuOpen and currentTab == "Teleport" then
            tabs["Teleport"].btn.MouseButton1Click:Fire()
        end
    end

    return ToggleMenu
end

-- ---- ОСНОВНЫЕ ФУНКЦИИ ----
function UpdateESP()
    ClearESP()
    if not CONFIG.ESPEnabled then return end
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player then
            local char = plr.Character
            if char then
                local hl = Instance.new("Highlight")
                hl.Parent = char
                hl.FillColor = CONFIG.AccentColor
                hl.FillTransparency = CONFIG.ESPTransparency
                hl.OutlineColor = CONFIG.AccentColor
                hl.OutlineTransparency = 0.1
                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                hl.Adornee = char
                table.insert(espObjects, hl)
            end
        end
    end
end

function ClearESP()
    for _, obj in pairs(espObjects) do
        if obj and obj.Parent then obj:Destroy() end
    end
    espObjects = {}
end

function UpdateHitboxes()
    ClearHitboxes()
    -- Если хитбоксы выключены и режим целей выключен — ничего не делаем
    if not CONFIG.HitboxEnabled and not CONFIG.TargetModeEnabled then return end

    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player then
            local char = plr.Character
            if char then
                local multiplier = CONFIG.HitboxMultiplier
                local transparency = CONFIG.HitboxTransparency
                local shouldCreate = false

                local isTarget = false
                for _, v in pairs(selectedTargets) do
                    if v == plr then isTarget = true break end
                end

                if CONFIG.TargetModeEnabled and isTarget then
                    multiplier = CONFIG.TargetMultiplier
                    transparency = CONFIG.TargetTransparency
                    shouldCreate = true
                elseif CONFIG.HitboxEnabled and not CONFIG.TargetModeEnabled then
                    shouldCreate = true
                elseif CONFIG.HitboxEnabled and CONFIG.TargetModeEnabled and not isTarget then
                    -- Если включён режим целей, но игрок не цель, хитбоксы не создаём
                    shouldCreate = false
                end

                if shouldCreate then
                    for _, part in pairs(char:GetDescendants()) do
                        if part:IsA("BasePart") then
                            local clone = Instance.new("Part")
                            clone.Size = part.Size * multiplier
                            clone.Transparency = transparency
                            clone.CanCollide = true
                            clone.Anchored = false
                            clone.Material = Enum.Material.Plastic
                            clone.Color = CONFIG.AccentColor
                            clone.Parent = char
                            local weld = Instance.new("Weld")
                            weld.Part0 = part
                            weld.Part1 = clone
                            weld.C0 = CFrame.new(0,0,0)
                            weld.Parent = clone
                            table.insert(hitboxParts, clone)
                        end
                    end
                end
            end
        end
    end
end

function ClearHitboxes()
    for _, obj in pairs(hitboxParts) do
        if obj and obj.Parent then obj:Destroy() end
    end
    hitboxParts = {}
end

-- ---- СОБЫТИЯ ----
local function onCharacterAdded(char)
    task.wait(0.2)
    if CONFIG.ESPEnabled then UpdateESP() end
    UpdateHitboxes()
end

for _, plr in pairs(Players:GetPlayers()) do
    if plr ~= player then
        if plr.Character then onCharacterAdded(plr.Character) end
        plr.CharacterAdded:Connect(onCharacterAdded)
    end
end

Players.PlayerAdded:Connect(function(plr)
    if plr ~= player then
        plr.CharacterAdded:Connect(onCharacterAdded)
    end
end)

-- ---- ЗАПУСК ----
local toggleMenu = CreateMenu()

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.T then
        toggleMenu()
    end
end)

RunService.RenderStepped:Connect(function()
    if CONFIG.ESPEnabled then UpdateESP() end
    UpdateHitboxes()
end)

_G.StopXeno = false
RunService.RenderStepped:Connect(function()
    if _G.StopXeno then
        ClearESP()
        ClearHitboxes()
        if player.PlayerGui:FindFirstChild("XenoMenu") then
            player.PlayerGui.XenoMenu:Destroy()
        end
        _G.StopXeno = false
        print("XENO HOMELESS ВЫКЛЮЧЕН")
    end
end)

print("⚡ XENO HOMELESS v9 ЗАГРУЖЕН! Нажми T для меню. by Wayne")
print("Для выключения введи: _G.StopXeno = true")