-- =====================================================
-- СКРИПТ ОСТАНОВКИ ВРЕМЕНИ V2.0 (ТОЛЬКО ТЕЛЕФОН)
-- Для Delta Executor на Android/iOS
-- ВСЁ УПРАВЛЕНИЕ – СЕНСОРНОЕ (пальцем)
-- =====================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")

-- ===== НАСТРОЙКИ (изменяй под себя) =====
local CONFIG = {
    ButtonSize = 100,             -- Размер кнопки (палец не промахнётся)
    ButtonPosition = {0.92, 0.88},-- Позиция (X, Y) от 0 до 1
    SwipeToToggle = true,         -- Свайп влево/вправо для переключения
    DoubleTapReset = true,        -- Двойной тап по кнопке = сброс
    FreezePlayers = true,
    FreezeObjects = true,
    FreezeAnimations = true,
    FreezeSounds = true,
    VisualEffect = true,
    SoundEffect = true,
    VibrateOnToggle = true,       -- Вибрация при переключении (если есть)
    AutoRefresh = true,
    RefreshInterval = 0.5,
    TimeScale = 0,
}

-- ===== СОСТОЯНИЕ =====
local timeFrozen = false
local frozenObjects = {}
local freezeStartTime = 0
local button = nil
local label = nil
local border = nil
local lastTapTime = 0
local gui = nil

-- ===== ВИБРАЦИЯ (если поддерживается) =====
local function Vibrate()
    if not CONFIG.VibrateOnToggle then return end
    if UserInputService then
        UserInputService:Vibrate(0.1)
    end
end

-- ===== ЗВУК (встроенный, без ID) =====
local function PlaySound(pitch)
    if not CONFIG.SoundEffect then return end
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxassetid://9120373631"
    sound.Pitch = pitch or 1
    sound.Volume = 0.3
    sound.Parent = Workspace
    sound:Play()
    game:GetService("Debris"):AddItem(sound, 0.8)
end

-- ===== ВИЗУАЛЬНЫЙ ЭФФЕКТ =====
local function SetVisualEffect(enabled)
    if not CONFIG.VisualEffect then return end
    if enabled then
        local colorEffect = Instance.new("ColorCorrectionEffect")
        colorEffect.Name = "TimeStopEffect"
        colorEffect.Saturation = -0.5
        colorEffect.Brightness = -0.3
        colorEffect.Contrast = 0.2
        colorEffect.Parent = Lighting
        
        local bloom = Instance.new("BloomEffect")
        bloom.Name = "TimeStopBloom"
        bloom.Intensity = 0.2
        bloom.Size = 12
        bloom.Parent = Lighting
    else
        for _, effect in ipairs(Lighting:GetChildren()) do
            if effect:IsA("PostEffect") and effect.Name:match("TimeStop") then
                effect:Destroy()
            end
        end
    end
end

-- ===== ЗАМОРОЗКА =====
local function FreezeAll(freeze)
    if freeze then freezeStartTime = tick() end
    
    if CONFIG.FreezePlayers then
        for _, player in ipairs(Players:GetPlayers()) do
            local char = player.Character
            if char then
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") then
                        if freeze then
                            part.Anchored = true
                            part.Velocity = Vector3.new(0,0,0)
                            part.RotVelocity = Vector3.new(0,0,0)
                        else
                            part.Anchored = false
                        end
                    end
                end
            end
        end
    end
    
    if CONFIG.FreezeObjects then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") and obj.Name ~= "Baseplate" and obj.Name ~= "Terrain" then
                if freeze then
                    if not obj.Anchored then
                        table.insert(frozenObjects, obj)
                        obj.Anchored = true
                        obj.Velocity = Vector3.new(0,0,0)
                        obj.RotVelocity = Vector3.new(0,0,0)
                    end
                else
                    obj.Anchored = false
                end
            end
        end
    end
    
    if CONFIG.FreezeAnimations then
        for _, player in ipairs(Players:GetPlayers()) do
            local char = player.Character
            if char then
                local animator = char:FindFirstChildOfClass("Animator")
                if animator then
                    if freeze then
                        for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                            track:Stop()
                        end
                    end
                end
            end
        end
    end
    
    if CONFIG.FreezeSounds then
        for _, sound in ipairs(Workspace:GetDescendants()) do
            if sound:IsA("Sound") then
                if freeze then
                    sound.Playing = false
                end
            end
        end
    end
end

-- ===== ПЕРЕКЛЮЧЕНИЕ =====
local function ToggleTime()
    timeFrozen = not timeFrozen
    
    if timeFrozen then
        FreezeAll(true)
        RunService:SetTimeScale(CONFIG.TimeScale)
        SetVisualEffect(true)
        PlaySound(0.8)
        Vibrate()
        
        if label then label.Text = "▶" end
        if border then
            border.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
            border.BorderColor3 = Color3.fromRGB(255, 0, 0)
        end
        if button then
            button.BackgroundColor3 = Color3.fromRGB(50, 20, 20)
        end
        print("⏸ ВРЕМЯ ОСТАНОВЛЕНО")
    else
        FreezeAll(false)
        RunService:SetTimeScale(1)
        SetVisualEffect(false)
        PlaySound(1.2)
        Vibrate()
        
        if label then label.Text = "⏸" end
        if border then
            border.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
            border.BorderColor3 = Color3.fromRGB(0, 255, 0)
        end
        if button then
            button.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
        end
        print("▶ ВРЕМЯ ВОЗОБНОВЛЕНО")
    end
end

-- ===== СБРОС (возобновить принудительно) =====
local function ResetTime()
    if timeFrozen then
        ToggleTime() -- выключаем паузу
    end
    RunService:SetTimeScale(1)
    SetVisualEffect(false)
    FreezeAll(false)
    timeFrozen = false
    if label then label.Text = "⏸" end
    if border then
        border.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        border.BorderColor3 = Color3.fromRGB(0, 255, 0)
    end
    if button then
        button.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
    end
    print("🔄 ВРЕМЯ СБРОШЕНО")
end

-- ===== СОЗДАНИЕ GUI =====
local function CreateGUI()
    if game:GetService("CoreGui"):FindFirstChild("TimeStopGUI") then
        game:GetService("CoreGui"):FindFirstChild("TimeStopGUI"):Destroy()
    end
    
    gui = Instance.new("ScreenGui")
    gui.Name = "TimeStopGUI"
    gui.Parent = game:GetService("CoreGui")
    gui.ResetOnSpawn = false
    
    button = Instance.new("ImageButton")
    button.Size = UDim2.new(0, CONFIG.ButtonSize, 0, CONFIG.ButtonSize)
    button.Position = UDim2.new(CONFIG.ButtonPosition[1], -CONFIG.ButtonSize/2, CONFIG.ButtonPosition[2], 0)
    button.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
    button.BackgroundTransparency = 0.15
    button.BorderSizePixel = 0
    button.Image = "rbxassetid://0"
    button.Parent = gui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = button
    
    label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = "⏸"
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = CONFIG.ButtonSize / 2
    label.Font = Enum.Font.SourceSansBold
    label.Parent = button
    
    border = Instance.new("Frame")
    border.Size = UDim2.new(1.2, 0, 1.2, 0)
    border.Position = UDim2.new(-0.1, 0, -0.1, 0)
    border.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
    border.BackgroundTransparency = 0.6
    border.BorderSizePixel = 4
    border.BorderColor3 = Color3.fromRGB(0, 255, 0)
    border.ZIndex = 0
    border.Parent = button
    
    local borderCorner = Instance.new("UICorner")
    borderCorner.CornerRadius = UDim.new(1, 0)
    borderCorner.Parent = border
    
    -- ===== ОБРАБОТКА НАЖАТИЙ (СЕНСОР) =====
    button.MouseButton1Click:Connect(function()
        local now = tick()
        -- ДВОЙНОЙ ТАП = СБРОС
        if CONFIG.DoubleTapReset and (now - lastTapTime) < 0.4 then
            ResetTime()
            lastTapTime = 0
            return
        end
        lastTapTime = now
        ToggleTime()
    end)
    
    -- ===== СВАЙП ВЛЕВО/ВПРАВО ДЛЯ ПЕРЕКЛЮЧЕНИЯ =====
    if CONFIG.SwipeToToggle then
        local startPos = nil
        button.TouchBegan:Connect(function(touch)
            startPos = touch.Position.X
        end)
        button.TouchEnded:Connect(function(touch)
            if startPos then
                local delta = touch.Position.X - startPos
                if math.abs(delta) > 30 then -- свайп на 30 пикселей
                    if delta < 0 then
                        ToggleTime() -- свайп влево = пауза
                    else
                        ResetTime() -- свайп вправо = сброс
                    end
                end
                startPos = nil
            end
        end)
    end
    
    -- ===== ЗАКРЫТИЕ ПО СЕНСОРНОЙ КОМАНДЕ =====
    -- Тройной тап по кнопке = закрыть (безопасный выход)
    local tapCount = 0
    local tapTimer = 0
    button.MouseButton1Click:Connect(function()
        local now = tick()
        if (now - tapTimer) < 0.5 then
            tapCount = tapCount + 1
        else
            tapCount = 1
        end
        tapTimer = now
        if tapCount >= 3 then
            gui:Destroy()
            print("✅ GUI ЗАКРЫТ (тройной тап)")
            tapCount = 0
        end
    end)
    
    print("✅ ВРЕМЯ-СТОП V2.0 (ТЕЛЕФОН) ЗАГРУЖЕН!")
    print("👆 Кнопка в правом нижнем углу")
    print("🔄 Двойной тап = сброс")
    print("👈 Свайп влево = пауза, вправо = сброс")
    print("👆👆👆 Тройной тап = закрыть панель")
end

-- ===== АВТО-ОБНОВЛЕНИЕ =====
if CONFIG.AutoRefresh then
    spawn(function()
        while true do
            wait(CONFIG.RefreshInterval)
            if timeFrozen then
                for _, obj in ipairs(Workspace:GetDescendants()) do
                    if obj:IsA("BasePart") and obj.Name ~= "Baseplate" and not obj.Anchored then
                        obj.Anchored = true
                        obj.Velocity = Vector3.new(0,0,0)
                        obj.RotVelocity = Vector3.new(0,0,0)
                    end
                end
            end
        end
    end)
end

-- ===== ЗАПУСК =====
CreateGUI()

-- ===== НОВЫЕ ИГРОКИ АВТО-ЗАМОРОЗКА =====
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function(char)
        if timeFrozen then
            wait(0.2)
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.Anchored = true
                    part.Velocity = Vector3.new(0,0,0)
                    part.RotVelocity = Vector3.new(0,0,0)
                end
            end
        end
    end)
end)

print("⏳ ГОТОВО! ТЫКАЙ ПО КНОПКЕ")
