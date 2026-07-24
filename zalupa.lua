-- =====================================================
-- СКРИПТ ТЕЛЕПОРТАЦИИ К ИГРОКАМ (ТОЛЬКО ТЕЛЕФОН)
-- Для Delta Executor на Android/iOS
-- СЕНСОРНОЕ УПРАВЛЕНИЕ
-- =====================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- ===== НАСТРОЙКИ =====
local CONFIG = {
    ButtonSize = 70,              -- Размер кнопки открытия
    ButtonPosition = {0.08, 0.85},-- Левая нижняя часть
    ListSize = {350, 400},        -- Ширина, высота списка
}

-- ===== СОСТОЯНИЕ =====
local selectedPlayer = nil
local gui = nil
local mainButton = nil
local isOpen = false

-- ===== ФУНКЦИЯ ТЕЛЕПОРТАЦИИ =====
local function TeleportToPlayer(targetPlayer)
    if not targetPlayer then
        print("❌ ВЫБЕРИ ИГРОКА")
        return
    end
    
    local targetChar = targetPlayer.Character
    local localChar = LocalPlayer.Character
    
    if not targetChar or not localChar then
        print("❌ ПЕРСОНАЖ НЕ ЗАГРУЖЕН")
        return
    end
    
    local targetRoot = targetChar:FindFirstChild("HumanoidRootPart") or targetChar:FindFirstChild("Head")
    local localRoot = localChar:FindFirstChild("HumanoidRootPart") or localChar:FindFirstChild("Head")
    
    if not targetRoot or not localRoot then
        print("❌ ROOT ЧАСТЬ НЕ НАЙДЕНА")
        return
    end
    
    -- Телепорт с плавностью (опционально)
    localRoot.CFrame = targetRoot.CFrame + Vector3.new(0, 2, 0)
    localRoot.Velocity = Vector3.new(0,0,0)
    localRoot.RotVelocity = Vector3.new(0,0,0)
    
    print("✅ ТЕЛЕПОРТ К " .. targetPlayer.Name)
    
    -- Закрываем список после телепорта
    if gui then gui:Destroy() end
    isOpen = false
end

-- ===== ОБНОВЛЕНИЕ СПИСКА =====
local function UpdatePlayerList(scrollFrame)
    -- Очистка
    for _, child in ipairs(scrollFrame:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    
    local yOffset = 0
    local allPlayers = Players:GetPlayers()
    local count = 0
    
    for _, player in ipairs(allPlayers) do
        if player ~= LocalPlayer then
            count = count + 1
            
            -- КНОПКА ИГРОКА
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, -20, 0, 55)
            btn.Position = UDim2.new(0, 10, 0, yOffset)
            btn.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
            btn.BorderSizePixel = 0
            btn.Text = player.Name
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.TextSize = 22
            btn.Font = Enum.Font.SourceSansBold
            btn.Parent = scrollFrame
            
            -- Скругление
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 10)
            corner.Parent = btn
            
            -- Подсветка при нажатии
            btn.MouseButton1Click:Connect(function()
                -- Сброс подсветки
                for _, b in ipairs(scrollFrame:GetChildren()) do
                    if b:IsA("TextButton") then
                        b.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
                    end
                end
                btn.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
                selectedPlayer = player
                
                -- Вибрация
                if UserInputService then
                    UserInputService:Vibrate(0.05)
                end
                
                print("🎯 ВЫБРАН: " .. player.Name)
            end)
            
            yOffset = yOffset + 60
        end
    end
    
    if count == 0 then
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 0, 50)
        label.Position = UDim2.new(0, 0, 0, 10)
        label.BackgroundTransparency = 1
        label.Text = "👥 НЕТ ИГРОКОВ"
        label.TextColor3 = Color3.fromRGB(200, 200, 200)
        label.TextSize = 24
        label.Font = Enum.Font.SourceSans
        label.Parent = scrollFrame
        yOffset = 70
    end
    
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset + 20)
end

-- ===== СОЗДАНИЕ GUI СПИСКА =====
local function CreatePlayerList()
    -- Если уже открыт - закрываем
    if gui and gui.Parent then
        gui:Destroy()
        isOpen = false
        return
    end
    
    gui = Instance.new("ScreenGui")
    gui.Name = "TeleportGUI"
    gui.Parent = game:GetService("CoreGui")
    gui.ResetOnSpawn = false
    
    -- ФОН (затемнение)
    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    bg.BackgroundTransparency = 0.5
    bg.BorderSizePixel = 0
    bg.Parent = gui
    
    -- ОСНОВНОЕ ОКНО СПИСКА
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, CONFIG.ListSize[1], 0, CONFIG.ListSize[2])
    frame.Position = UDim2.new(0.5, -CONFIG.ListSize[1]/2, 0.5, -CONFIG.ListSize[2]/2)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
    frame.BackgroundTransparency = 0.1
    frame.BorderSizePixel = 2
    frame.BorderColor3 = Color3.fromRGB(80, 80, 120)
    frame.Parent = gui
    
    -- Скругление
    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0, 20)
    frameCorner.Parent = frame
    
    -- ЗАГОЛОВОК
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 50)
    title.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
    title.BackgroundTransparency = 0.1
    title.Text = "👥 ВЫБЕРИ ИГРОКА"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 24
    title.Font = Enum.Font.SourceSansBold
    title.Parent = frame
    
    -- КНОПКА ЗАКРЫТИЯ (крестик)
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 50, 0, 50)
    closeBtn.Position = UDim2.new(1, -55, 0, 0)
    closeBtn.BackgroundColor3 = Color3.fromRGB(150, 0, 0)
    closeBtn.Text = "✕"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextSize = 30
    closeBtn.Font = Enum.Font.SourceSansBold
    closeBtn.BorderSizePixel = 0
    closeBtn.Parent = frame
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 10)
    closeCorner.Parent = closeBtn
    
    closeBtn.MouseButton1Click:Connect(function()
        gui:Destroy()
        isOpen = false
    end)
    
    -- СКРОЛЛИНГ-СПИСОК
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, 0, 1, -110)
    scroll.Position = UDim2.new(0, 0, 0, 55)
    scroll.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
    scroll.BackgroundTransparency = 0.2
    scroll.BorderSizePixel = 0
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.ScrollBarThickness = 8
    scroll.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 150)
    scroll.Parent = frame
    
    -- КНОПКА "ТЕЛЕПОРТ" (внизу)
    local teleportBtn = Instance.new("TextButton")
    teleportBtn.Size = UDim2.new(0.8, 0, 0, 50)
    teleportBtn.Position = UDim2.new(0.1, 0, 1, -60)
    teleportBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
    teleportBtn.Text = "🚀 ТЕЛЕПОРТ"
    teleportBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    teleportBtn.TextSize = 24
    teleportBtn.Font = Enum.Font.SourceSansBold
    teleportBtn.BorderSizePixel = 0
    teleportBtn.Parent = frame
    
    local tpCorner = Instance.new("UICorner")
    tpCorner.CornerRadius = UDim.new(0, 15)
    tpCorner.Parent = teleportBtn
    
    teleportBtn.MouseButton1Click:Connect(function()
        if selectedPlayer then
            TeleportToPlayer(selectedPlayer)
        else
            print("❌ СНАЧАЛА ВЫБЕРИ ИГРОКА")
            -- Визуальный сигнал
            teleportBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
            wait(0.3)
            teleportBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 0)
        end
    end)
    
    -- Заполняем список
    UpdatePlayerList(scroll)
    
    -- Обновление при входе/выходе игроков
    Players.PlayerAdded:Connect(function()
        UpdatePlayerList(scroll)
    end)
    Players.PlayerRemoving:Connect(function()
        UpdatePlayerList(scroll)
    end)
    
    isOpen = true
    print("✅ СПИСОК ИГРОКОВ ОТКРЫТ")
end

-- ===== КНОПКА ВЫЗОВА (на экране) =====
local function CreateMainButton()
    -- Очистка старой
    if game:GetService("CoreGui"):FindFirstChild("TeleportMainButton") then
        game:GetService("CoreGui"):FindFirstChild("TeleportMainButton"):Destroy()
    end
    
    local btnGui = Instance.new("ScreenGui")
    btnGui.Name = "TeleportMainButton"
    btnGui.Parent = game:GetService("CoreGui")
    btnGui.ResetOnSpawn = false
    
    mainButton = Instance.new("ImageButton")
    mainButton.Size = UDim2.new(0, CONFIG.ButtonSize, 0, CONFIG.ButtonSize)
    mainButton.Position = UDim2.new(CONFIG.ButtonPosition[1], 0, CONFIG.ButtonPosition[2], 0)
    mainButton.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
    mainButton.BackgroundTransparency = 0.2
    mainButton.BorderSizePixel = 0
    mainButton.Image = "rbxassetid://0"
    mainButton.Parent = btnGui
    
    -- Круглая форма
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = mainButton
    
    -- Текст
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = "🚀"
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = CONFIG.ButtonSize / 1.8
    label.Font = Enum.Font.SourceSansBold
    label.Parent = mainButton
    
    -- Ободок
    local border = Instance.new("Frame")
    border.Size = UDim2.new(1.15, 0, 1.15, 0)
    border.Position = UDim2.new(-0.075, 0, -0.075, 0)
    border.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
    border.BackgroundTransparency = 0.6
    border.BorderSizePixel = 3
    border.BorderColor3 = Color3.fromRGB(0, 200, 255)
    border.ZIndex = 0
    border.Parent = mainButton
    
    local borderCorner = Instance.new("UICorner")
    borderCorner.CornerRadius = UDim.new(1, 0)
    borderCorner.Parent = border
    
    -- Обработка нажатия
    mainButton.MouseButton1Click:Connect(function()
        CreatePlayerList()
        -- Анимация нажатия
        mainButton.Size = UDim2.new(0, CONFIG.ButtonSize * 0.9, 0, CONFIG.ButtonSize * 0.9)
        wait(0.1)
        mainButton.Size = UDim2.new(0, CONFIG.ButtonSize, 0, CONFIG.ButtonSize)
    end)
    
    print("✅ КНОПКА ТЕЛЕПОРТА ЗАГРУЖЕНА")
    print("🚀 Нажми на кнопку с ракетой в левом нижнем углу")
end

-- ===== ЗАПУСК =====
CreateMainButton()

-- ===== АВТООБНОВЛЕНИЕ КНОПКИ (если пропала) =====
spawn(function()
    while true do
        wait(5)
        if not game:GetService("CoreGui"):FindFirstChild("TeleportMainButton") then
            CreateMainButton()
        end
    end
end)

print("⏳ ГОТОВО! ТЫКАЙ НА РАКЕТУ 🚀")
