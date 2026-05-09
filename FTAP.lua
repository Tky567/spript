local HttpGetContent_6 = game:HttpGet('https://sirius.menu/rayfield')
local Rayfield_7 = loadstring(HttpGetContent_6)()

local v8 = Rayfield_7:CreateWindow({
    Name = 'FTAP Superfling',
    LoadingTitle = 'Fling Things and People',
    LoadingSubtitle = 'by Zenon',
    ConfigurationSaving = {
        Enabled = true,
        FileName = 'FTAP_Superfling'
    },
    Discord = {
        Enabled = false,
        RememberJoins = true,
        Invite = 'noinvitelink'
    },
    KeySystem = false, -- Đã tắt hệ thống Key
    KeySettings = {
        -- Đã vô hiệu hóa các cài đặt này
    }
})

local v9 = Rayfield_7:Notify({
    Image = 4483362458,
    Duration = 5,
    Title = '✓ Script Loaded!',
    Content = 'Key system has been removed. Enjoy!'
})

local v10 = v8:CreateTab('Main', 4483362458)
local v11 = v10:CreateSection('Fling Features')

-- Biến lưu trạng thái
local Strength = 500
local AutoFling = false
local FlingEnabled = false

local v15 = v10:CreateSlider({
    Name = 'Fling Strength',
    Range = {0, 2000},
    Increment = 10,
    Suffix = 'Force',
    CurrentValue = 500,
    Flag = 'FlingStrengthSlider',
    Callback = function(Value)
        Strength = Value
    end
})

local v14 = v10:CreateToggle({
    Name = 'Enable Super Fling',
    CurrentValue = false,
    Flag = 'FlingToggle',
    Callback = function(Value)
        FlingEnabled = Value
    end
})

local v13 = v10:CreateToggle({
    Name = 'Auto Fling (On Grab)',
    CurrentValue = false,
    Flag = 'AutoFlingToggle',
    Callback = function(Value)
        AutoFling = Value
    end
})

local v12 = v10:CreateSection('Presets')
v10:CreateButton({
    Name = 'Low (500)',
    Callback = function()
        v15:Set(500)
    end
})

v10:CreateButton({
    Name = 'High (1200)',
    Callback = function()
        v15:Set(1200)
    end
})

v10:CreateButton({
    Name = 'Extreme (2000)',
    Callback = function()
        v15:Set(2000)
    end
})

local v22 = v8:CreateTab('Info', 4483362458)
v22:CreateParagraph({
    Title = 'How to Use',
    Content = '1. Enable fling with the toggle\n2. Adjust strength with the slider\n3. Grab objects in-game\n4. Release to fling them\n\nKey System removed by AI.'
})
