local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")

-- hash cực đơn giản (Lua thuần, không bitwise)
local function simpleHash(str)
    local hash = 0
    for i = 1, #str do
        hash = (hash + string.byte(str, i) * i) % 100000000
    end
    return tostring(hash)
end

-- safe call helper
local function safe(fn, default)
    local ok, res = pcall(fn)
    if ok and res ~= nil then
        return res
    end
    return default
end

-- client / executor name
local clientName = safe(function()
    if identifyexecutor then
        return identifyexecutor()
    end
end, "unknown")

clientName = tostring(clientName):lower()
clientName = clientName:gsub("%s+", "")
clientName = clientName:gsub("[^%w]", "")

-- device info (mobile-safe)
local platform = safe(function()
    return tostring(UIS:GetPlatform())
end, "unknown")

local locale = safe(function()
    return Players.LocalPlayer.LocaleId
end, "unknown")

local resolution = safe(function()
    local v = workspace.CurrentCamera.ViewportSize
    return v.X .. "x" .. v.Y
end, "unknown")

-- fingerprint
local rawFingerprint = platform .. "|" .. locale .. "|" .. resolution
local fingerprintID = simpleHash(rawFingerprint)

-- client hwid (delta-style)
local clientHWID = clientName .. "_" .. simpleHash(clientName .. "|" .. fingerprintID)

-- output
print("===== HWID TEST =====")
print("Client Name  :", clientName)
print("Platform     :", platform)
print("Locale       :", locale)
print("Resolution   :", resolution)
print("Fingerprint  :", fingerprintID)
print("Client HWID  :", clientHWID)
print("=====================")