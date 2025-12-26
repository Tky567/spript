-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Stats = game:GetService("Stats")

-- Helper hash (simple, không phải crypto thật)
local function simpleHash(str)
    local hash = 0
    for i = 1, #str do
        hash = (hash * 31 + string.byte(str, i)) % 2^32
    end
    return string.format("%08X", hash)
end

-- Collect info
local info = {}

info.os = UserInputService:GetPlatform().Name
info.locale = Players.LocalPlayer.LocaleId
info.resolution = tostring(workspace.CurrentCamera.ViewportSize)
info.graphics = tostring(settings().Rendering.QualityLevel)
info.robloxVersion = tostring(version())
info.fpsCap = tostring(setfpscap and getfpscap() or "unknown")
info.executor = identifyexecutor and identifyexecutor() or "unknown"

-- Build raw fingerprint
local raw = table.concat({
    info.os,
    info.locale,
    info.resolution,
    info.graphics,
    info.robloxVersion,
    info.fpsCap,
    info.executor
}, "|")

-- Generate pseudo HWID
local pseudoHWID = simpleHash(raw)

-- Output
print("=== DEVICE INFO ===")
for k, v in pairs(info) do
    print(k .. ":", v)
end

print("===================")
print("Pseudo HWID:", pseudoHWID)