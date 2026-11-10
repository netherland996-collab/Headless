--[[
    Client-Side Visual Override (Headless Only)
    Not: Yalnızca yerel oyuncuda görünür, sunucuya yansımaz.
]]

local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local LocalPlayer  = Players.LocalPlayer

-- 0. Güvenli GUI parent seçimi
local function getGuiParent()
    if gethui then
        local ok, hui = pcall(gethui)
        if ok and hui then return hui end
    end
    local ok, cg = pcall(function() return game:GetService("CoreGui") end)
    if ok and cg then
        local test = Instance.new("Folder")
        local assigned = pcall(function() test.Parent = cg end)
        test:Destroy()
        if assigned then return cg end
    end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local parentContainer = getGuiParent()
local existingGui = parentContainer:FindFirstChild("VisualOverrideLoading")
if existingGui then existingGui:Destroy() end

-- 1. Yükleme UI Oluşturma
local screenGui = Instance.new("ScreenGui")
screenGui.Name           = "VisualOverrideLoading"
screenGui.ResetOnSpawn   = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder   = 999
screenGui.Parent         = parentContainer

local frame = Instance.new("Frame")
frame.Size                   = UDim2.fromScale(1, 1)
frame.BackgroundColor3       = Color3.fromRGB(15, 15, 15)
frame.BackgroundTransparency = 0.1
frame.Parent                 = screenGui

local textLabel = Instance.new("TextLabel")
textLabel.Size                   = UDim2.new(0, 350, 0, 60)
textLabel.Position               = UDim2.new(0.5, -175, 0.5, -30)
textLabel.BackgroundTransparency = 1
textLabel.Font                   = Enum.Font.GothamBold
textLabel.Text                   = "Sistem Yükleniyor..."
textLabel.TextColor3             = Color3.fromRGB(255, 255, 255)
textLabel.TextSize               = 22
textLabel.Parent                 = frame

local subLabel = Instance.new("TextLabel")
subLabel.Size                   = UDim2.new(0, 350, 0, 40)
subLabel.Position               = UDim2.new(0.5, -175, 0.5, 20)
subLabel.BackgroundTransparency = 1
subLabel.Font                   = Enum.Font.Gotham
subLabel.Text                   = "Modüller senkronize ediliyor..."
subLabel.TextColor3             = Color3.fromRGB(170, 170, 170)
subLabel.TextSize               = 14
subLabel.Parent                 = frame

-- 2. Headless Uygulama Fonksiyonu
local function applyHeadless(character)
    if not character then return end
    local humanoid = character:WaitForChild("Humanoid", 5)
    if not humanoid then return end

    -- Kafayı ve üzerindeki yüz/dokuları tamamen gizle
    local head = character:FindFirstChild("Head")
    if head then
        pcall(function()
            head.Transparency = 1
            head.CanCollide = false
        end)
        for _, c in ipairs(head:GetChildren()) do
            pcall(function()
                if c:IsA("Decal") or c:IsA("SpecialMesh") or c:IsA("Texture") then
                    c.Transparency = 1
                end
            end)
        end
    end

    -- Kafaya bağlı şapka ve aksesuarları gizle
    for _, acc in ipairs(character:GetChildren()) do
        if acc:IsA("Accessory") then
            local handle = acc:FindFirstChild("Handle")
            if handle and handle:IsA("BasePart") then
                local isHat = handle:FindFirstChild("HatAttachment") ~= nil
                if not isHat and head then
                    isHat = (handle.Position - head.Position).Magnitude < 2.5
                end
                if isHat then
                    pcall(function() 
                        handle.Transparency = 1 
                        for _, sub in ipairs(handle:GetDescendants()) do
                            if sub:IsA("BasePart") or sub:IsA("SpecialMesh") or sub:IsA("Decal") then
                                sub.Transparency = 1
                            end
                        end
                    end)
                end
            end
        end
    end
end

-- 3. Akış ve Animasyon Yönetimi
task.spawn(function()
    local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    task.wait(0.6)

    textLabel.Text = "Görseller Entegre Ediliyor..."
    task.wait(0.4)

    local ok, err = pcall(function()
        applyHeadless(character)
    end)
    if not ok then warn("[VisualOverride] hata:", err) end

    textLabel.Text = "Tamamlandı!"
    subLabel.Text  = "Sistem hazır."
    task.wait(0.3)

    local info  = TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tween = TweenService:Create(frame, info, { BackgroundTransparency = 1 })
    TweenService:Create(textLabel, info, { TextTransparency = 1 }):Play()
    TweenService:Create(subLabel,  info, { TextTransparency = 1 }):Play()
    tween:Play()
    tween.Completed:Wait()

    screenGui:Destroy()
end)

-- 4. Respawn (yeniden doğma) güvencesi
LocalPlayer.CharacterAdded:Connect(function(newChar)
    task.spawn(function()
        task.wait(1)
        pcall(function()
            applyHeadless(newChar)
        end)
    end)
end)
