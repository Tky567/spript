-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

-- Simple hash
local function simpleHash(str)
    local hash = 5381
    for i = 1, #str do
        hash = ((hash << 5) + hash) + string.byte(str, i)
        hash = hash & 0xFFFFFFFF
    end
    return string.format("%08X", hash)
end

-- Detect executor / client name
local clientName = "unknown"
if identifyexecutor then
    clientName = identifyexecutor():lower()
elseif getexecutorname then
    clientName = getexecutorname():lower()
end

-- Normalize client name (giống Delta làm)
clientName = clientName:gsub("%s+", "")
clientName = clientName:gsub("[^%w]", "")

-- Build fingerprint
local fingerprintRaw = table.concat({
    UserInputService:GetPlatform().Name,
    Players.LocalPlayer.LocaleId,
    tostring(workspace.CurrentCamera.ViewportSize),
    tostring(settings().Rendering.QualityLevel),
    tostring(version())
}, "|")

local fingerprintID = simpleHash(fingerprintRaw)

-- Build client HWID (giả lập)
local clientHWIDRaw = clientName .. "|" .. fingerprintID
local clientHWID = clientName .. "_" .. simpleHash(clientHWIDRaw)

-- Final combined ID
local finalID = simpleHash(clientHWID .. "|" .. fingerprintID)

-- Output
print("=== TEST IDENTIFICATION ===")
print("Client Name      :", clientName)
print("Fingerprint ID   :", fingerprintID)
print("Client HWID      :", clientHWID)
print("Final Device ID  :", finalID)
print("===========================")