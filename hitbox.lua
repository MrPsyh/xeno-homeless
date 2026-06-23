--[[
    ПРОСТОЙ ВИЗУАЛЬНЫЙ РАСШИРИТЕЛЬ ХИТБОКСОВ
    by Wayne
    - Увеличивает только врагов (не тебя)
    - Ползунок размера (1–5)
    - Вкл/Выкл
    - Открыть/закрыть: T
    - Почти без лагов (проверка раз в 2 секунды)
]]

local player = game.Players.LocalPlayer
local mouse = player:GetMouse()
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- ===== НАСТРОЙКИ =====
local ENEMY_SCALE = 2.0      -- начальный размер врагов
local UPDATE_DELAY = 2       -- проверка каждые 2 сек (чтобы не лагать)
local enabled = true         -- включен ли эффект
-- =====================

local gui = Instance.new("ScreenGui")
gui.Name = "HitboxGUI"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 300, 0, 140)
frame.Position = UDim2.new(0.5, -150, 0.5, -70)
frame.BackgroundColor3 = Color3.new(0.1, 0.05, 0.2)
frame.BackgroundTransparency = 0.1
frame.BorderSizePixel = 1
frame.BorderColor3 = Color3.new(0.7, 0.1, 1)
frame.Active = true
frame.Draggable = true
frame.Parent = gui
local corner = Instance.new("UICorner", frame)
corner.CornerRadius = UDim.new(0, 8)

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 30)
title.BackgroundColor3 = Color3.new(0.7, 0.1, 1)
title.BackgroundTransparency = 0.3
title.Text = "⚡ HITBOX ⚡ by Wayne"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextScaled = true
title.Font = Enum.Font.GothamBold

local close = Instance.new("TextButton", frame)
close.Size = UDim2.new(0, 25, 0, 25)
close.Position = UDim2.new(1, -30, 0, 3)
close.BackgroundColor3 = Color3.new(0.5, 0, 0)
close.Text = "✕"
close.TextColor3 = Color3.new(1, 1, 1)
close.TextScaled = true
close.Font = Enum.Font.GothamBold
local closeCorner = Instance.new("UICorner", close)
closeCorner.CornerRadius = UDim.new(1, 0)
close.MouseButton1Click:Connect(function()
    gui.Enabled = false
end)

-- Ползунок размера
local sizeLabel = Instance.new("TextLabel", frame)
sizeLabel.Size = UDim2.new(0.8, 0, 0, 25)
sizeLabel.Position = UDim2.new(0.05, 0, 0.25, 0)
sizeLabel.BackgroundTransparency = 1
sizeLabel.Text = "Размер врагов: " .. tostring(ENEMY_SCALE)
sizeLabel.TextColor3 = Color3.new(1, 1, 1)
sizeLabel.TextScaled = true
sizeLabel.Font = Enum.Font.Gotham

local sliderBg = Instance.new("Frame", frame)
sliderBg.Size = UDim2.new(0.6, 0, 0.15, 0)
sliderBg.Position = UDim2.new(0.3, 0, 0.28, 0)
sliderBg.BackgroundColor3 = Color3.new(0.2, 0.2, 0.3)
sliderBg.BorderSizePixel = 0
local sCorner = Instance.new("UICorner", sliderBg)
sCorner.CornerRadius = UDim.new(0, 4)

local fill = Instance.new("Frame", sliderBg)
fill.Size = UDim2.new((ENEMY_SCALE - 1) / 4, 0, 1, 0) -- от 1 до 5
fill.BackgroundColor3 = Color3.new(0.7, 0.1, 1)
fill.BorderSizePixel = 0
local fCorner = Instance.new("UICorner", fill)
fCorner.CornerRadius = UDim.new(0, 4)

local knob = Instance.new("TextButton", sliderBg)
knob.Size = UDim2.new(0, 16, 0, 16)
knob.Position = UDim2.new((ENEMY_SCALE - 1) / 4, -8, 0.5, -8)
knob.BackgroundColor3 = Color3.new(1, 1, 1)
knob.Text = ""
knob.BorderSizePixel = 0
local kCorner = Instance.new("UICorner", knob)
kCorner.CornerRadius = UDim.new(1, 0)

local dragging = false
local function updateScale(input)
    local rel = (input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X
    rel = math.clamp(rel, 0, 1)
    local val = 1 + rel * 4   -- от 1 до 5
    val = math.round(val * 10) / 10
    fill.Size = UDim2.new(rel, 0, 1, 0)
    knob.Position = UDim2.new(rel, -8, 0.5, -8)
    sizeLabel.Text = "Размер врагов: " .. tostring(val)
    ENEMY_SCALE = val
    if enabled then applyToAll() end
end

knob.MouseButton1Down:Connect(function() dragging = true end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)
mouse.Move:Connect(function()
    if dragging then
        local rel = (mouse.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X
        rel = math.clamp(rel, 0, 1)
        local val = 1 + rel * 4
        val = math.round(val * 10) / 10
        fill.Size = UDim2.new(rel, 0, 1, 0)
        knob.Position = UDim2.new(rel, -8, 0.5, -8)
        sizeLabel.Text = "Размер врагов: " .. tostring(val)
        ENEMY_SCALE = val
        if enabled then applyToAll() end
    end
end)
sliderBg.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then updateScale(i) end
end)

-- Кнопка вкл/выкл
local toggleBtn = Instance.new("TextButton", frame)
toggleBtn.Size = UDim2.new(0.3, 0, 0.2, 0)
toggleBtn.Position = UDim2.new(0.35, 0, 0.72, 0)
toggleBtn.BackgroundColor3 = Color3.new(0.7, 0.1, 1)
toggleBtn.Text = "ВЫКЛ"
toggleBtn.TextColor3 = Color3.new(1, 1, 1)
toggleBtn.TextScaled = true
toggleBtn.Font = Enum.Font.GothamBold
local tCorner = Instance.new("UICorner", toggleBtn)
tCorner.CornerRadius = UDim.new(0, 6)

toggleBtn.MouseButton1Click:Connect(function()
    enabled = not enabled
    toggleBtn.Text = enabled and "ВЫКЛ" or "ВКЛ"
    toggleBtn.BackgroundColor3 = enabled and Color3.new(0.7, 0.1, 1) or Color3.new(0.3, 0, 0)
    if enabled then applyToAll() else resetAll() end
end)

-- ===== ОСНОВНАЯ ЛОГИКА (изменение масштаба) =====
local function setScale(char, scale)
    if not char then return end
    local humanoid = char:FindFirstChild("Humanoid")
    if humanoid then
        humanoid.BodyHeightScale.Value = scale
        humanoid.BodyWidthScale.Value = scale
        humanoid.BodyDepthScale.Value = scale
    end
    -- дополнительно растягиваем части (страховка)
    for _, part in ipairs(char:GetChildren()) do
        if part:IsA("BasePart") then
            part.Size = part.Size * scale
        end
    end
end

-- Применить ко всем врагам
function applyToAll()
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player then
            local char = plr.Character
            if char then
                setScale(char, ENEMY_SCALE)
            end
        end
    end
    -- себе ставим 1 (не меняем)
    local myChar = player.Character
    if myChar then
        setScale(myChar, 1)
    end
end

-- Сброс для всех (кроме себя)
function resetAll()
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player then
            local char = plr.Character
            if char then
                setScale(char, 1)
            end
        end
    end
end

-- Обработчики появления
local function onCharacterAdded(char, plr)
    task.wait(0.1)
    if plr == player then
        setScale(char, 1)
    else
        if enabled then
            setScale(char, ENEMY_SCALE)
        end
    end
end

for _, plr in pairs(Players:GetPlayers()) do
    if plr.Character then
        onCharacterAdded(plr.Character, plr)
    end
    plr.CharacterAdded:Connect(function(char)
        onCharacterAdded(char, plr)
    end)
end

Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function(char)
        onCharacterAdded(char, plr)
    end)
end)

-- Периодическая проверка (анти-сброс)
task.spawn(function()
    while true do
        task.wait(UPDATE_DELAY)
        if enabled then
            for _, plr in pairs(Players:GetPlayers()) do
                if plr ~= player then
                    local char = plr.Character
                    if char then
                        local humanoid = char:FindFirstChild("Humanoid")
                        if humanoid and humanoid.BodyHeightScale.Value ~= ENEMY_SCALE then
                            humanoid.BodyHeightScale.Value = ENEMY_SCALE
                            humanoid.BodyWidthScale.Value = ENEMY_SCALE
                            humanoid.BodyDepthScale.Value = ENEMY_SCALE
                        end
                    end
                end
            end
        end
    end
end)

-- Скрыть GUI по умолчанию
gui.Enabled = false

-- Открытие по T
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.T then
        gui.Enabled = not gui.Enabled
        if gui.Enabled then applyToAll() end
    end
end)

-- Выключение скрипта
_G.StopHitbox = false
RunService.RenderStepped:Connect(function()
    if _G.StopHitbox then
        resetAll()
        gui:Destroy()
        _G.StopHitbox = false
        print("Хитбоксы выключены")
    end
end)

print("⚡ Простые хитбоксы загружены! Нажми T для меню.")
print("Для выключения введи: _G.StopHitbox = true")
