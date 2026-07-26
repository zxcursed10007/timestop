-- =====================================================
-- СКРИПТ ТЕЛЕПОРТАЦИИ НА СЕРВЕР С ИГРОКОМ
-- Для Delta Executor на Android/iOS
-- ПОИСК СЕРВЕРА ЧЕРЕЗ API + АВТО-ТП
-- =====================================================

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local UserInputService = game:GetService("UserInputService")

-- ===== НАСТРОЙКИ =====
local CONFIG = {
    ButtonSize = 70,
    ButtonPosition = {0.08, 0.85},
    ListSize = {380, 450},
}

-- ===== СОСТОЯНИЕ =====
local selectedPlayer = nil
local gui = nil
local isOpen = false

-- ===== ФУНКЦИЯ ПОЛУЧЕНИЯ ID ИГРОКА ПО ИМЕНИ =====
local function GetUserId(playerName)
    local success, result = pcall(function()
        local url = "https://api.roblox.com/users/get-by-username?username=" .. playerName
        local response = HttpService:GetAsync(url)
        local data = HttpService:JSONDecode(response)
        return data and data.Id
    end)
    return success and result or nil
end

-- ===== ФУНКЦИЯ ПОИСКА ИГРЫ И СЕРВЕРА ИГРОКА =====
local function FindPlayerServer(playerName)
    -- 1. Получаем ID игрока
    local userId = GetUserId(playerName)
    if not userId then
        print("❌ НЕ УДАЛОСЬ НАЙТИ ID: " .. playerName)
        return nil, nil
    end
    
    -- 2. Получаем текущую игру игрока
    local placeId = nil
    local success, result = pcall(function()
        local url = "https://presence.roblox.com/v1/presence/users?userIds=" .. userId
        local response = HttpService:GetAsync(url)
        local data = HttpService:JSONDecode(response)
        if data and data.userPresences and #data.userPresences > 0 then
            local presence = data.userPresences[1]
            if presence and presence.gameId then
                placeId = presence.gameId
            end
        end
    end)
    
    if not placeId then
        print("❌ ИГРОК НЕ В ИГРЕ ИЛИ API НЕ ДОСТУПЕН")
        return nil, nil
    end
    
    print("🔍 ИГРОК В ИГРЕ: " .. placeId)
    
    -- 3. Ищем сервер с этим игроком
    local serverId = nil
    local success2, result2 = pcall(function()
        local url = "https://games.roblox.com/v1/games/" .. placeId .. "/servers/Public?limit=100"
        local response = HttpService:GetAsync(url)
        local data = HttpService:JSONDecode(response)
        if data and data.data then
            for _, server in ipairs(data.data) do
                if server.playing and server.playing > 0 then
                    for _, name in ipairs(server.players) do
                        if name == playerName then
                            serverId = server.id
                            return
                        end
                    end
                end
            end
        end
    end)
    
    if serverId then
        print("✅ НАЙДЕН СЕРВЕР: " .. serverId)
    else
        print("❌ СЕРВЕР С ИГРОКОМ НЕ НАЙДЕН")
    end
    
    return placeId, serverId
end

-- ===== ФУНКЦИЯ ТЕЛЕПОРТАЦИИ =====
local function TeleportToPlayerServer(playerName)
    if not playerName then
        print("❌ ВЫБЕРИ ИГРОКА")
        return
    end
    
    local placeId, serverId = FindPlayerServer(playerName)
    if not placeId or not serverId then
        print("❌ НЕ УДАЛОСЬ НАЙТИ СЕРВЕР")
        return
    end
    
    -- Телепортируемся на сервер
    local success, err = pcall(function()
        -- Метод 1: TeleportToPrivateServer с ReserveServer
        local accessCode = TeleportService:ReserveServer(placeId, serverId)
        TeleportService:TeleportToPrivateServer(placeId, accessCode, {LocalPlayer})
    end)
    
    if not success then
        print("❌ ОШИБКА ТЕЛЕПОРТА: " .. tostring(err))
        -- Метод 2: Teleport с параметром ServerId (если поддерживается)
        pcall(function()
            TeleportService:Teleport(placeId, LocalPlayer, serverId)
        end)
    end
    
    print("🚀 ТЕЛЕПОРТ НА СЕРВЕР К " .. playerName)
end

-- ===== ОБНОВЛЕНИЕ СПИСКА ИГРОКОВ =====
local function UpdatePlayerList(scrollFrame)
    for _, child in ipairs(scrollFrame:GetChildren()) do
        if child:IsA("TextButton") or child:IsA("TextLabel") then child:Destroy() end
    end
    
    local allPlayers = Players:GetPlayers()
    local yOffset = 0
    local count = 0
    
    for _, player in ipairs(allPlayers) do
        if player ~= LocalPlayer then
            count = count + 1
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
            
            local corner = Instance.new("UICorner")
            corner.CornerRadius = UDim.new(0, 10)
            corner.Parent = btn
            
            btn.MouseButton1Click:Connect(function()
                for _, b in ipairs(scrollFrame:GetChildren()) do
                    if b:IsA("TextButton") then
                        b.BackgroundColor3 = Color3.fromRGB(35, 35, 55)
                    end
                end
                btn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
                selectedPlayer = player.Name
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
        label.Text = "👥 НЕТ ДРУГИХ ИГРОКОВ"
        label.TextColor3 = Color3.fromRGB(200, 200, 200)
        label.TextSize = 24
        label.Font = Enum.Font.SourceSans
        label.Parent = scrollFrame
        yOffset = 70
    end
    
    scrollFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset + 20)
end

-- ===== СОЗДАНИЕ GUI =====
local function CreateGUI()
    if gui and gui.Parent then
        gui:Destroy()
        isOpen = false
        return
    end
    
    gui = Instance.new("ScreenGui")
    gui.Name = "FindServerGUI"
    gui.Parent = game:GetService("CoreGui")
    gui.ResetOnSpawn = false
    
    -- Фон
    local bg = Instance.new("Frame")
    bg.Size = UDim2.new(1, 0, 1, 0)
    bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    bg.BackgroundTransparency = 0.5
    bg.BorderSizePixel = 0
    bg.Parent = gui
    
    -- Окно
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, CONFIG.ListSize[1], 0, CONFIG.ListSize[2])
    frame.Position = UDim2.new(0.5, -CONFIG.ListSize[1]/2, 0.5, -CONFIG.ListSize[2]/2)
    frame.BackgroundColor3 = Color3.fromRGB(20, 20, 35)
    frame.BackgroundTransparency = 0.1
    frame.BorderSizePixel = 2
    frame.BorderColor3 = Color3.fromRGB(80, 80, 120)
    frame.Parent = gui
    
    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = UDim.new(0, 20)
    frameCorner.Parent = frame
    
    -- Заголовок
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 50)
    title.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
    title.BackgroundTransparency = 0.1
    title.Text = "🔍 ТЕЛЕПОРТ К ИГРОКУ"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextSize = 22
    title.Font = Enum.Font.SourceSansBold
    title.Parent = frame
    
    -- Кнопка закрытия
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
    
    -- Скроллинг-список
    local scroll = Instance.new("ScrollingFrame")
    scroll.Size = UDim2.new(1, 0, 1, -110)
    scroll.Position = UDim2.new(0, 0, 0, 55)
    scroll.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
    scroll.BackgroundTransparency = 0.2
    scroll.BorderSizePixel = 0
    scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    scroll.ScrollBarThickness = 8
    scroll.Parent = frame
    
    -- Кнопка "ТЕЛЕПОРТ НА СЕРВЕР"
    local tpBtn = Instance.new("TextButton")
    tpBtn.Size = UDim2.new(0.8, 0, 0, 50)
    tpBtn.Position = UDim2.new(0.1, 0, 1, -60)
    tpBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 200)
    tpBtn.Text = "🚀 ТЕЛЕПОРТ К НЕМУ"
    tpBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    tpBtn.TextSize = 22
    tpBtn.Font = Enum.Font.SourceSansBold
    tpBtn.BorderSizePixel = 0
    tpBtn.Parent = frame
    
    local tpCorner = Instance.new("UICorner")
    tpCorner.CornerRadius = UDim.new(0, 15)
    tpCorner.Parent = tpBtn
    
    tpBtn.MouseButton1Click:Connect(function()
        if selectedPlayer then
            TeleportToPlayerServer(selectedPlayer)
        else
            print("❌ ВЫБЕРИ ИГРОКА")
            tpBtn.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
            wait(0.3)
            tpBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 200)
        end
    end)
    
    -- Заполняем список
    UpdatePlayerList(scroll)
    
    -- Обновление при входе/выходе
    Players.PlayerAdded:Connect(function()
        UpdatePlayerList(scroll)
    end)
    Players.PlayerRemoving:Connect(function()
        UpdatePlayerList(scroll)
    end)
    
    isOpen = true
    print("✅ GUI ЗАГРУЖЕН: ВЫБЕРИ ИГРОКА")
end

-- ===== КНОПКА ВЫЗОВА =====
local function CreateMainButton()
    if game:GetService("CoreGui"):FindFirstChild("FindServerButton") then
        game:GetService("CoreGui"):FindFirstChild("FindServerButton"):Destroy()
    end
    
    local btnGui = Instance.new("ScreenGui")
    btnGui.Name = "FindServerButton"
    btnGui.Parent = game:GetService("CoreGui")
    btnGui.ResetOnSpawn = false
    
    local btn = Instance.new("ImageButton")
    btn.Size = UDim2.new(0, CONFIG.ButtonSize, 0, CONFIG.ButtonSize)
    btn.Position = UDim2.new(CONFIG.ButtonPosition[1], 0, CONFIG.ButtonPosition[2], 0)
    btn.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
    btn.BackgroundTransparency = 0.2
    btn.BorderSizePixel = 0
    btn.Image = "rbxassetid://0"
    btn.Parent = btnGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = btn
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = "🔍"
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = CONFIG.ButtonSize / 1.8
    label.Font = Enum.Font.SourceSansBold
    label.Parent = btn
    
    local border = Instance.new("Frame")
    border.Size = UDim2.new(1.15, 0, 1.15, 0)
    border.Position = UDim2.new(-0.075, 0, -0.075, 0)
    border.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
    border.BackgroundTransparency = 0.6
    border.BorderSizePixel = 3
    border.BorderColor3 = Color3.fromRGB(0, 200, 255)
    border.ZIndex = 0
    border.Parent = btn
    
    local borderCorner = Instance.new("UICorner")
    borderCorner.CornerRadius = UDim.new(1, 0)
    borderCorner.Parent = border
    
    btn.MouseButton1Click:Connect(function()
        CreateGUI()
        btn.Size = UDim2.new(0, CONFIG.ButtonSize * 0.9, 0, CONFIG.ButtonSize * 0.9)
        wait(0.1)
        btn.Size = UDim2.new(0, CONFIG.ButtonSize, 0, CONFIG.ButtonSize)
    end)
    
    print("✅ КНОПКА ЗАГРУЖЕНА (🔍)")
end

-- ===== ЗАПУСК =====
CreateMainButton()

-- Авто-восстановление кнопки
spawn(function()
    while true do
        wait(5)
        if not game:GetService("CoreGui"):FindFirstChild("FindServerButton") then
            CreateMainButton()
        end
    end
end)

print("⏳ ГОТОВО! НАЖМИ НА 🔍 И ВЫБЕРИ ИГРОКА")
