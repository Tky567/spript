local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")

-- Safe hash
local function simpleHash(str)
    local hash = 2166136261
    for i = 1, #str do
        hash = hash ~ string.byte(str, i)
        hash = (hash * 16777619) % 2^32
    end
    return string.format("%08X", hash)
end

-- Safe call
local function safe(fn, default)
    local ok, res = pcall(fn)
    if ok and res ~= nil then
        return res
    end
    return default
end

-- Detect client / executor
local clientName = "unknown"
clientName = safe(function()
    if identifyexecutor then
        return identifyexecutor()
    end
end, "unknown")

clientName = tostring(clientName):lower()
clientName = clientName:gsub("%s+", "")
clientName = clientName:gsub("[^%w]", "")

-- Collect info (mobile-safe)
local platform = safe(function()
    return UIS:GetPlatform()
end, "UnknownPlatform")

local locale = safe(function()
    return Players.LocalPlayer.LocaleId
end, "unknown")

local resolution = safe(function()
    return workspace.CurrentCamera.ViewportSize.X .. "x" ..
           workspace.CurrentCamera.ViewportSize.Y
end, "unknown")

-- Fingerprint
local fingerprintRaw = table.concat({
    tostring(platform),
    locale,
    resolution
}, "|")

local fingerprintID = simpleHash(fingerprintRaw)

-- Client HWID (Delta-style)
local clientHWIDRaw = clientName .. "|" .. fingerprintID
local clientHWID = clientName .. "_" .. simpleHash(clientHWIDRaw)

-- Output
print("===== CLIENT HWID TEST =====")
print("Client Name   :", clientName)
print("Platform      :", platform)
print("Locale        :", locale)
print("Resolution    :", resolution)
print("FingerprintID :", fingerprintID)
print("Client HWID   :", clientHWID)
print("============================")