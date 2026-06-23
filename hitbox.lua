-- Простые квадратные хитбоксы (только враги)
-- Открыть/закрыть: T

local player = game.Players.LocalPlayer
local mouse = player:GetMouse()
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local enabled = true
local boxSize = 2.5  -- от 1 до 3

-- ГУИ
local gui = Instance.new("ScreenGui")
gui.Name = "HitboxGUI"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 320, 0, 100)
frame.Position = UDim2.new(0.5, -160, 0.5, -50)
frame.BackgroundColor3 = Color3.new(0.1, 0.05, 0.2)
frame.BackgroundTransparency = 0.2
frame.BorderSizePixel = 1
frame.BorderColor3 = Color3.new(0.7, 0.1, 1)
frame.Active = true
frame.Draggable = true
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

-- Заголовок
local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 25)
title.BackgroundTransparency = 1
title.Text = "Хитбоксы"
title.TextColor3 = Color3.new(1, 1, 1)
title.TextScaled = true
title.Font = Enum.Font.GothamBold

-- Кнопка закрыть
local close = Instance.new("TextButton", frame)
close.Size = UDim2.new(0, 22, 0, 22)
close.Position = UDim2.new(1, -26, 0, 2)
close.BackgroundColor3 = Color3.new(0.5, 0, 0)
close.Text = "✕"
close.TextColor3 = Color3.new(1, 1, 1)
close.TextScaled = true
close.Font = Enum.Font.GothamBold
Instance.new("UICorner", close).CornerRadius = UDim.new(1, 0)
close.MouseButton1Click:Connect(function() gui.Enabled = false end)

-- Ползунок размера
local sizeLabel = Instance.new("TextLabel", frame)
sizeLabel.Size = UDim2.new(0.5, 0, 0, 25)
sizeLabel.Position = UDim2.new(0.05, 0, 0.3, 0)
sizeLabel.BackgroundTransparency = 1
sizeLabel.Text = "Размер: " .. tostring(boxSize)
sizeLabel.TextColor3 = Color3.new(1, 1, 1)
sizeLabel.TextScaled = true
sizeLabel.Font = Enum.Font.Gotham

local sliderBg = Instance.new("Frame", frame)
sliderBg.Size = UDim2.new(0.4, 0, 0.2, 0)
sliderBg.Position = UDim2.new(0.5, 0, 0.35, 0)
sliderBg.BackgroundColor3 = Color3.new(0.2, 0.2, 0.3)
sliderBg.BorderSizePixel = 0
Instance.new("UICorner", sliderBg).CornerRadius = UDim.new(0, 4)

local fill = Instance.new("Frame", sliderBg)
fill.Size = UDim2.new((boxSize - 1) / 2, 0, 1, 0)
fill.BackgroundColor3 = Color3.new(0.7, 0.1, 1)
fill.BorderSizePixel = 0
Instance.new("UICorner", fill).CornerRadius = UDim.new(0, 4)

local knob = Instance.new("TextButton", sliderBg)
knob.Size = UDim2.new(0, 14, 0, 14)
knob.Position = UDim2.new((boxSize - 1) / 2, -7, 0.5, -7)
knob.BackgroundColor3 = Color3.new(1, 1, 1)
knob.Text = ""
knob.BorderSizePixel = 0
Instance.new("UICorner", knob).CornerRadius = UDim.new(1, 0)

local dragging = false
local function updateSlider(input)
    local rel = (input.Position.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X
    rel = math.clamp(rel, 0, 1)
    local val = 1 + rel * 2  -- от 1 до 3
    val = math.round(val * 10) / 10
    fill.Size = UDim2.new(rel, 0, 1, 0)
    knob.Position = UDim2.new(rel, -7, 0.5, -7)
    sizeLabel.Text = "Размер: " .. tostring(val)
    boxSize = val
    if enabled then updateBoxes() end
end

knob.MouseButton1Down:Connect(function() dragging = true end)
UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
end)
mouse.Move:Connect(function()
    if dragging then
        local rel = (mouse.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X
        rel = math.clamp(rel, 0, 1)
        local val = 1 + rel * 2
        val = math.round(val * 10) / 10
        fill.Size = UDim2.new(rel, 0, 1, 0)
        knob.Position = UDim2.new(rel, -7, 0.5, -7)
        sizeLabel.Text = "Размер: " .. tostring(val)
        boxSize = val
        if enabled then updateBoxes() end
    end
end)
sliderBg.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then updateSlider(i) end
end)

-- Кнопка вкл/выкл
local toggleBtn = Instance.new("TextButton", frame)
toggleBtn.Size = UDim2.new(0.2, 0, 0.2, 0)
toggleBtn.Position = UDim2.new(0.75, 0, 0.7, 0)
toggleBtn.BackgroundColor3 = Color3.new(0.7, 0.1, 1)
toggleBtn.Text = "ВЫКЛ"
toggleBtn.TextColor3 = Color3.new(1, 1, 1)
toggleBtn.TextScaled = true
toggleBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0, 6)
toggleBtn.MouseButton1Click:Connect(function()
    enabled = not enabled
    toggleBtn.Text = enabled and "ВЫКЛ" or "ВКЛ"
    toggleBtn.BackgroundColor3 = enabled and Color3.new(0.7, 0.1, 1) or Color3.new(0.3, 0, 0)
    if enabled then updateBoxes() else clearBoxes() end
end)

-- ---- ОСНОВНАЯ ЛОГИКА ----
local boxes = {}

function updateBoxes()
    clearBoxes()
    if not enabled then return end
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= player then
            local char = plr.Character
            if char then
                local root = char:FindFirstChild("HumanoidRootPart")
                if root then
                    local adorn = Instance.new("BoxHandleAdornment")
                    adorn.Size = Vector3.new(boxSize, boxSize, boxSize)
                    adorn.Adornee = root
                    adorn.ZIndex = 0
                    adorn.Color3 = Color3.new(0.7, 0.1, 1)  -- фиолетовый
                    adorn.Transparency = 0.6   -- прозрачный
                    adorn.AlwaysOnTop = true
                    adorn.Parent = root
                    table.insert(boxes, adorn)
                end
            end
        end
    end
end

function clearBoxes()
    for _, obj in pairs(boxes) do
        if obj and obj.Parent then obj:Destroy() end
    end
    boxes = {}
end

-- Обработчики появления
local function onChar(char)
    task.wait(0.1)
    if enabled then updateBoxes() end
end

for _, plr in pairs(Players:GetPlayers()) do
    if plr ~= player then
        if plr.Character then onChar(plr.Character) end
        plr.CharacterAdded:Connect(onChar)
    end
end
Players.PlayerAdded:Connect(function(plr)
    if plr ~= player then
        plr.CharacterAdded:Connect(onChar)
    end
end)

-- Автообновление (для новых частей) - редко, чтобы не лагать
RunService.RenderStepped:Connect(function()
    if enabled then updateBoxes() end
end)

gui.Enabled = false

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.T then
        gui.Enabled = not gui.Enabled
        if gui.Enabled then updateBoxes() end
    end
end)

-- Выключение
_G.StopBox = false
RunService.RenderStepped:Connect(function()
    if _G.StopBox then
        clearBoxes()
        gui:Destroy()
        _G.StopBox = false
        print("Хитбоксы выключены")
    end
end)

print("⚡ Квадратные хитбоксы загружены! Нажми T.")
