local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")

-- safe helper
local function safe(fn, def)
    local ok, r = pcall(fn)
    if ok and r ~= nil then return r end
    return def
end

-- simple stable hash (Lua thuần)
local function stableHash(str)
    local h = 0
    for i = 1, #str do
        h = (h * 131 + string.byte(str, i)) % 1000000000
    end
    return string.format("%08x", h)
end

-- executor / client name
local client = safe(function()
    if identifyexecutor then return identifyexecutor() end
end, "unknown")

client = tostring(client):lower()
client = client:gsub("%s+", "")
client = client:gsub("[^%w]", "")

-- stable device-like sources
local platform = tostring(safe(function()
    return UIS:GetPlatform()
end, "unknown"))

local locale = safe(function()
    return Players.LocalPlayer.LocaleId
end, "unknown")

local resolution = safe(function()
    local v = workspace.CurrentCamera.ViewportSize
    return math.floor(v.X) .. "x" .. math.floor(v.Y)
end, "unknown")

-- build device-style raw string
local rawDevice = table.concat({
    "device",
    platform,
    locale,
    resolution
}, "|")

-- device-style hwid (SIMULATED)
local deviceHWID = stableHash(rawDevice)

-- client-style hwid (giống ArceusX / Delta hành vi)
local clientHWID = client .. "_" .. stableHash(client .. "|" .. deviceHWID)

print("===== DEVICE HWID TEST =====")
print("Client          :", client)
print("Platform        :", platform)
print("Locale          :", locale)
print("Resolution      :", resolution)
print("----------------------------")
print("Sim Device HWID :", deviceHWID)
print("Client HWID     :", clientHWID)
print("============================")