-- [[ NAME HUB MOBILE EDITION - FTAP (SUPER THROW FIXED) ]]
-- Viết bởi Antigravity AI (Logic Siêu ném: Chỉ văng khi buông tay)

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

-- Biến lưu trữ trạng thái
local _G_Settings = {
    FlingEnabled = false,
    FlingStrength = 5000,
    AntiGrab = false,
    KillAura = false,
    AuraRange = 25
}

local LP = game.Players.LocalPlayer
local RS = game:GetService("RunService")
local RepS = game:GetService("ReplicatedStorage")

-- 1. WINDOW
local Window = Rayfield:CreateWindow({
    Name = "Name Hub - Mobile (Super Throw)",
    LoadingTitle = "Fling Things and People",
    LoadingSubtitle = "by Zenon & Antigravity",
    ConfigurationSaving = { Enabled = true, FileName = "NameHubMobileV4" },
    KeySystem = false 
})

-- 2. TABS
local MainTab = Window:CreateTab("Main", 4483362458)
local AuraTab = Window:CreateTab("Aura", 4483362458)
local MiscTab = Window:CreateTab("Misc", 4483362458)

-- 3. MAIN FEATURES
MainTab:CreateSection("Super Throw Settings")

MainTab:CreateToggle({
    Name = "Enable Super Throw (Release to Fling)",
    CurrentValue = false,
    Callback = function(Value)
        _G_Settings.FlingEnabled = Value
    end,
})

MainTab:CreateSlider({
    Name = "Throw Power",
    Range = {100, 20000},
    Increment = 500,
    Suffix = "Power",
    CurrentValue = 5000,
    Callback = function(Value)
        _G_Settings.FlingStrength = Value
    end,
})

-- 4. AURA FEATURES
AuraTab:CreateSection("Combat Aura")

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

-- [[ LOGIC THỰC THI (CORE) ]]

-- 1. HOOKING LOGIC (ĐÁNH CHẶN LỆNH THẢ TAY)
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local args = {...}
    local method = getnamecallmethod()
    
    -- Kiểm tra nếu script game đang gọi lệnh thả vật (DestroyGrabLine)
    if not checkcaller() and method == "FireServer" and self.Name == "DestroyGrabLine" then
        local targetPart = args[1]
        
        -- Nếu đang bật Super Throw và có vật thể hợp lệ
        if _G_Settings.FlingEnabled and targetPart and targetPart:IsA("BasePart") then
            local force = _G_Settings.FlingStrength
            local lookDir = LP.Character.HumanoidRootPart.CFrame.LookVector
            local flingVelocity = lookDir * force
            
            -- "Bơm" lực văng vào vật thể ngay khoảnh khắc thả tay
            RepS.GrabEvents.SetNetworkOwner:FireServer(targetPart, CFrame.new(flingVelocity))
            
            -- Thêm hiệu ứng vật lý để chắc chắn nó bay đi
            targetPart.Velocity = flingVelocity
        end
    end
    
    return oldNamecall(self, ...)
end)

-- 2. LOOP LOGIC (CHO CÁC TÍNH NĂNG KHÁC)
RS.Heartbeat:Connect(function()
    local Char = LP.Character
    if not Char then return end
    local HRP = Char:FindFirstChild("HumanoidRootPart")
    if not HRP then return end

    -- Anti-Grab
    if _G_Settings.AntiGrab then
        if Char:FindFirstChild("Head") and Char.Head:FindFirstChild("PartOwner") then
            RepS.CharacterEvents.Struggle:FireServer()
            RepS.GameCorrectionEvents.StopAllVelocity:FireServer()
        end
    end

    -- Kill Aura (Văng người chơi lọt vào tầm đánh)
    if _G_Settings.KillAura then
        for _, player in pairs(game.Players:GetPlayers()) do
            if player ~= LP and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                local targetHRP = player.Character.HumanoidRootPart
                local dist = (targetHRP.Position - HRP.Position).Magnitude
                if dist <= _G_Settings.AuraRange then
                    RepS.GrabEvents.SetNetworkOwner:FireServer(targetHRP, CFrame.new(9e9, 9e9, 9e9))
                end
            end
        end
    end
end)

Rayfield:Notify({
    Title = "Super Throw Enabled!",
    Content = "Hãy cầm vật thể và thả tay để thấy sức mạnh siêu ném!",
    Duration = 5,
    Image = 4483362458,
})
