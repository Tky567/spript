-- [[ NAME HUB MOBILE EDITION - FTAP (UPDATED) ]]
-- Viết bởi Antigravity AI (Dựa trên source Name Hub & captures từ Remote Spy)

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Biến lưu trữ trạng thái
local _G_Settings = {
    FlingEnabled = false,
    FlingStrength = 850,
    AntiGrab = false,
    KillAura = false,
    AuraRange = 25,
    SuperThrow = false
}

local LP = game.Players.LocalPlayer
local RS = game:GetService("RunService")
local RepS = game:GetService("ReplicatedStorage")

-- 1. WINDOW
local Window = Rayfield:CreateWindow({
    Name = "Name Hub - Mobile Edition (Pro)",
    LoadingTitle = "Fling Things and People",
    LoadingSubtitle = "by Zenon & Antigravity",
    ConfigurationSaving = { Enabled = true, FileName = "NameHubMobileV2" },
    KeySystem = false 
})

-- 2. TABS
local MainTab = Window:CreateTab("Main", 4483362458)
local AuraTab = Window:CreateTab("Aura", 4483362458)
local MiscTab = Window:CreateTab("Misc", 4483362458)

-- 3. MAIN FEATURES
MainTab:CreateSection("Fling & Physics")

MainTab:CreateToggle({
    Name = "Enable Fling (Spinbot)",
    CurrentValue = false,
    Callback = function(Value)
        _G_Settings.FlingEnabled = Value
    end,
})

MainTab:CreateSlider({
    Name = "Fling Strength",
    Range = {100, 10000},
    Increment = 100,
    Suffix = "Power",
    CurrentValue = 850,
    Callback = function(Value)
        _G_Settings.FlingStrength = Value
    end,
})

MainTab:CreateToggle({
    Name = "Super Throw (From NameHub)",
    CurrentValue = false,
    Callback = function(Value)
        _G_Settings.SuperThrow = Value
    end,
})

-- 4. AURA FEATURES
AuraTab:CreateSection("Combat Aura (RemoteSpy Enhanced)")

AuraTab:CreateToggle({
    Name = "Kill Aura (Fling Others)",
    CurrentValue = false,
    Callback = function(Value)
        _G_Settings.KillAura = Value
    end,
})

AuraTab:CreateSlider({
    Name = "Aura Range",
    Range = {10, 100},
    Increment = 1,
    Suffix = "Studs",
    CurrentValue = 25,
    Callback = function(Value)
        _G_Settings.AuraRange = Value
    end,
})

-- 5. MISC FEATURES
MiscTab:CreateSection("Protection")

MiscTab:CreateToggle({
    Name = "Anti Grab (Auto Struggle)",
    CurrentValue = false,
    Callback = function(Value)
        _G_Settings.AntiGrab = Value
    end,
})

MiscTab:CreateButton({
    Name = "Destroy All Grab Lines (Anti-Lag)",
    Callback = function()
        for _, part in pairs(workspace:GetDescendants()) do
            if part:IsA("BasePart") then
                RepS.GrabEvents.DestroyGrabLine:FireServer(part)
            end
        end
    end,
})

-- [[ LOGIC THỰC THI (CORE) ]]

-- Loop chính xử lý Fling, Anti-Grab và Aura (Dùng Heartbeat để mượt nhất)
RS.Heartbeat:Connect(function()
    local Char = LP.Character
    if not Char then return end
    local HRP = Char:FindFirstChild("HumanoidRootPart")
    if not HRP then return end

    -- 1. Logic Fling (Spin Character)
    if _G_Settings.FlingEnabled then
        HRP.RotVelocity = Vector3.new(0, _G_Settings.FlingStrength * 10, 0)
    end

    -- 2. Logic Anti-Grab (Dựa trên lệnh Struggle)
    if _G_Settings.AntiGrab then
        if Char:FindFirstChild("Head") and Char.Head:FindFirstChild("PartOwner") then
            RepS.CharacterEvents.Struggle:FireServer()
            RepS.GameCorrectionEvents.StopAllVelocity:FireServer()
        end
    end

    -- 3. Logic Kill Aura (Dựa trên cấu trúc SetNetworkOwner từ Remote Spy)
    if _G_Settings.KillAura then
        for _, player in pairs(game.Players:GetPlayers()) do
            if player ~= LP and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local targetHRP = player.Character.HumanoidRootPart
                local dist = (targetHRP.Position - HRP.Position).Magnitude
                
                if dist <= _G_Settings.AuraRange then
                    -- Kỹ thuật SetNetworkOwner + CFrame xa để văng đối thủ
                    -- Lấy đúng cấu trúc từ file 2.lua trong thư mục new
                    local flingCFrame = CFrame.new(9e9, 9e9, 9e9) 
                    RepS.GrabEvents.SetNetworkOwner:FireServer(targetHRP, flingCFrame)
                end
            end
        end
    end
end)

-- Thông báo khi script chạy xong
Rayfield:Notify({
    Title = "Name Hub Updated!",
    Content = "Đã cập nhật logic từ Remote Spy. Các tính năng Aura đã mạnh hơn!",
    Duration = 5,
    Image = 4483362458,
})
