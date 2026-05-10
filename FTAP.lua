-- [[ NAME HUB MOBILE EDITION - FTAP (PRO FIXED) ]]
-- Viết bởi Antigravity AI (Fix lỗi tự văng bản thân)

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Biến lưu trữ trạng thái
local _G_Settings = {
    FlingEnabled = false,
    FlingStrength = 2500,
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
    Name = "Name Hub - Mobile Edition (Fixed)",
    LoadingTitle = "Fling Things and People",
    LoadingSubtitle = "by Zenon & Antigravity",
    ConfigurationSaving = { Enabled = true, FileName = "NameHubMobileV3" },
    KeySystem = false 
})

-- 2. TABS
local MainTab = Window:CreateTab("Main", 4483362458)
local AuraTab = Window:CreateTab("Aura", 4483362458)
local MiscTab = Window:CreateTab("Misc", 4483362458)

-- 3. MAIN FEATURES
MainTab:CreateSection("Fling & Physics")

MainTab:CreateToggle({
    Name = "Enable Fling (Hold to Fling)",
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
    CurrentValue = 2500,
    Callback = function(Value)
        _G_Settings.FlingStrength = Value
    end,
})

-- 4. AURA FEATURES
AuraTab:CreateSection("Combat Aura")

AuraTab:CreateToggle({
    Name = "Kill Aura (Auto Fling Others)",
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
                pcall(function()
                    RepS.GrabEvents.DestroyGrabLine:FireServer(part)
                end)
            end
        end
    end,
})

-- [[ LOGIC THỰC THI (CORE) ]]

-- Loop chính mượt mà
RS.Heartbeat:Connect(function()
    local Char = LP.Character
    if not Char then return end
    local HRP = Char:FindFirstChild("HumanoidRootPart")
    if not HRP then return end

    -- FIX: KHÔNG XOAY NGƯỜI DÙNG QUÁ MẠNH
    if _G_Settings.FlingEnabled then
        HRP.RotVelocity = Vector3.new(0, 30, 0) -- Xoay cực nhẹ để phá physics khớp nối
    end

    -- LOGIC 1: FLING VẬT ĐANG CẦM (FIX CHO BẠN)
    if _G_Settings.FlingEnabled then
        local hand = Char:FindFirstChild("Right Arm") or Char:FindFirstChild("RightHand")
        if hand then
            for _, part in pairs(workspace.GrabParts:GetChildren()) do
                if part:IsA("BasePart") then
                    local dist = (part.Position - hand.Position).Magnitude
                    if dist < 15 then -- Bạn đang cầm vật này
                        local force = _G_Settings.FlingStrength
                        -- Bắn vật đi theo hướng bạn đang nhìn
                        local vel = HRP.CFrame.LookVector * force
                        
                        -- Dùng SetNetworkOwner để ép Server chấp nhận vận tốc này
                        RepS.GrabEvents.SetNetworkOwner:FireServer(part, CFrame.new(vel))
                        
                        -- Force vật thể bay đi
                        part.Velocity = vel
                        part.RotVelocity = Vector3.new(force, force, force)
                    end
                end
            end
        end
    end

    -- LOGIC 2: ANTI-GRAB
    if _G_Settings.AntiGrab then
        if Char:FindFirstChild("Head") and Char.Head:FindFirstChild("PartOwner") then
            RepS.CharacterEvents.Struggle:FireServer()
            RepS.GameCorrectionEvents.StopAllVelocity:FireServer()
        end
    end

    -- LOGIC 3: KILL AURA (FLING NGƯỜI XUNG QUANH)
    if _G_Settings.KillAura then
        for _, player in pairs(game.Players:GetPlayers()) do
            if player ~= LP and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local targetHRP = player.Character.HumanoidRootPart
                local dist = (targetHRP.Position - HRP.Position).Magnitude
                
                if dist <= _G_Settings.AuraRange then
                    -- Văng đối thủ bằng SetNetworkOwner (Kỹ thuật cực mạnh)
                    RepS.GrabEvents.SetNetworkOwner:FireServer(targetHRP, CFrame.new(9e9, 9e9, 9e9))
                end
            end
        end
    end
end)

Rayfield:Notify({
    Title = "Fix Applied!",
    Content = "Đã fix lỗi tự văng bản thân. Giờ bạn có thể văng vật thể an toàn!",
    Duration = 5,
    Image = 4483362458,
})
