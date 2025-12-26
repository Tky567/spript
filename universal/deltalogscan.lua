local MAX_DEPTH = 3
local seen = {}

local function containsDelta(v)
    if type(v) == "string" then
        return v:lower():find("delta", 1, true) ~= nil
    end
    return false
end

local function scan(value, path, depth)
    if depth > MAX_DEPTH then return end
    if seen[value] then return end
    seen[value] = true

    local t = type(value)

    if t == "string" then
        if containsDelta(value) then
            print("[STRING]", path, "=", value)
        end

    elseif t == "function" then
        local ok, info = pcall(tostring, value)
        if ok and containsDelta(info) then
            print("[FUNCTION]", path, info)
        end

    elseif t == "table" then
        for k, v in pairs(value) do
            local keyPath = path .. "." .. tostring(k)

            if containsDelta(tostring(k)) then
                print("[KEY]", keyPath)
            end

            scan(v, keyPath, depth + 1)
        end
    end
end

print("===== SCAN DELTA START =====")

-- Global env
scan(_G, "_G", 1)

-- Executor env (nếu có)
pcall(function()
    if getgenv then
        scan(getgenv(), "getgenv()", 1)
    end
end)

-- Roblox env
pcall(function()
    if getrenv then
        scan(getrenv(), "getrenv()", 1)
    end
end)

print("===== SCAN DELTA END =====")