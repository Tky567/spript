-- [[ NAME HUB MOBILE EDITION - FTAP ]]
-- Viết bởi Antigravity AI (Dựa trên source Name Hub & Rayfield)

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Biến lưu trữ trạng thái
local _G_Settings = {
    FlingEnabled = false,
    FlingStrength = 850,
    AntiGrab = false,
    KillAura = false,
    AuraRange = 20
}

local LP = game.Players.LocalPlayer
local RS = game:GetService("RunService")
local RepS = game:GetService("ReplicatedStorage")

-- 1. WINDOW
local Window = Rayfield:CreateWindow({
    Name = "Name Hub - Mobile Edition",
    LoadingTitle = "Fling Things and People",
    LoadingSubtitle = "by Zenon & Antigravity",
    ConfigurationSaving = { Enabled = true, FileName = "NameHubMobile" },
    KeySystem = false -- TẮT KEY SYSTEM CHO BẠN
})

-- 2. TABS
local MainTab = Window:CreateTab("Main", 4483362458)
local AuraTab = Window:CreateTab("Aura", 4483362458)

-- 3. MAIN FEATURES
MainTab:CreateSection("Fling Settings")

MainTab:CreateToggle({
    Name = "Enable Fling",
    CurrentValue = false,
    Callback = function(Value)
        _G_Settings.FlingEnabled = Value
    end,
})

MainTab:CreateSlider({
    Name = "Fling Strength",
    Range = {100, 5000},
    Increment = 100,
    Suffix = "Power",
    CurrentValue = 850,
    Callback = function(Value)
        _G_Settings.FlingStrength = Value
    end,
})

MainTab:CreateSection("Anti Features")

MainTab:CreateToggle({
    Name = "Anti Grab (Auto Struggle)",
    CurrentValue = false,
    Callback = function(Value)
        _G_Settings.AntiGrab = Value
    end,
})

-- 4. AURA FEATURES
AuraTab:CreateSection("Combat Aura")

AuraTab:CreateToggle({
    Name = "Kill Aura",
    CurrentValue = false,
    Callback = function(Value)
        _G_Settings.KillAura = Value
    end,
})

AuraTab:CreateSlider({
    Name = "Aura Range",
    Range = {5, 50},
    Increment = 1,
    Suffix = "Studs",
    CurrentValue = 20,
    Callback = function(Value)
        _G_Settings.AuraRange = Value
    end,
})

-- [[ LOGIC THỰC THI (CORE) ]]

-- Loop xử lý Fling & Anti-Grab
RS.Heartbeat:Connect(function()
    local Char = LP.Character
    if not Char then return end
    local HRP = Char:FindFirstChild("HumanoidRootPart")
    if not HRP then return end

    -- Thực thi Fling
    if _G_Settings.FlingEnabled then
        HRP.RotVelocity = Vector3.new(0, _G_Settings.FlingStrength * 10, 0)
    end

    -- Thực thi Anti-Grab (Dựa trên lệnh Struggle tìm thấy trong source)
    if _G_Settings.AntiGrab then
        -- Kiểm tra nếu đang bị cầm (Dựa trên cấu trúc game)
        if Char:FindFirstChild("Head") and Char.Head:FindFirstChild("PartOwner") then
            RepS.CharacterEvents.Struggle:FireServer()
            RepS.GameCorrectionEvents.StopAllVelocity:FireServer()
        end
    end
end)

-- Loop xử lý Kill Aura
task.spawn(function()
    while task.wait(0.1) do
        if _G_Settings.KillAura and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart") then
            for _, player in pairs(game.Players:GetPlayers()) do
                if player ~= LP and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    local dist = (player.Character.HumanoidRootPart.Position - LP.Character.HumanoidRootPart.Position).Magnitude
                    if dist <= _G_Settings.AuraRange then
                        -- Gửi lệnh chiếm quyền điều khiển vật thể của đối thủ
                        -- Đây là kỹ thuật Fling Aura cực mạnh trong FTAP
                        RepS.GrabEvents.SetNetworkOwner:FireServer(player.Character.HumanoidRootPart)
                    end
                end
            end
        end
    end
end)

Rayfield:Notify({
    Title = "Name Hub Ready!",
    Content = "Script đã sẵn sàng cho Mobile. Chúc bạn chơi vui vẻ!",
    Duration = 5,
    Image = 4483362458,
})
