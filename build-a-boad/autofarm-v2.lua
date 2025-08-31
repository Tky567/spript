local players = game:GetService("Players")
local plr = players.LocalPlayer
local tween = game:GetService("TweenService")
local runService = game:GetService("RunService")

local CONFIG = {
    TARGET_GAME_ID = 537413528,
    GRAVITY_REDUCED = 1.0,
    GRAVITY_DEFAULT = 196.2,
    TWEEN_SPEEDS = {
        START = 4,
        MAIN = 20.5,
        END = 4
    },
    DEATH_TIMEOUT = 20,
    RESET_COOLDOWN = 5
}

local ScriptState = {
    isRunning = false,
    currentTweens = {},
    connections = {},
    originalGravity = nil,
    lastDeathTime = 0,
    deathCheckRunning = false,
    lastResetTime = 0,
    checkConnection = nil
}

local function checkGameID()
    return game.GameId == CONFIG.TARGET_GAME_ID or true -- Bypass for testing
end

local function setGravity(value)
    workspace.Gravity = value
end

local function restoreOriginalGravity()
    if ScriptState.originalGravity then
        setGravity(ScriptState.originalGravity)
    else
        setGravity(CONFIG.GRAVITY_DEFAULT)
    end
end

local function forceResetCharacter()
    local currentTime = tick()
    if currentTime - ScriptState.lastResetTime < CONFIG.RESET_COOLDOWN then
        return
    end
    
    ScriptState.lastResetTime = currentTime
    
    if plr.Character and plr.Character:FindFirstChild("Humanoid") then
        plr.Character.Humanoid.Health = 0
    end
end

local function startDeathChecker()
    if ScriptState.deathCheckRunning then
        return
    end
    
    ScriptState.deathCheckRunning = true
    ScriptState.lastDeathTime = tick()
    
    if ScriptState.checkConnection then
        ScriptState.checkConnection:Disconnect()
    end
    
    ScriptState.checkConnection = runService.Heartbeat:Connect(function()
        if not ScriptState.deathCheckRunning then
            return
        end
        
        local currentTime = tick()
        local character = plr.Character
        local humanoid = character and character:FindFirstChild("Humanoid")
        
        if humanoid and humanoid.Health <= 0 then
            ScriptState.lastDeathTime = currentTime
        elseif humanoid and humanoid.Health > 0 then
            local timeSinceLastDeath = currentTime - ScriptState.lastDeathTime
            
            if timeSinceLastDeath >= CONFIG.DEATH_TIMEOUT then
                forceResetCharacter()
                ScriptState.lastDeathTime = currentTime
            end
        end
    end)
end

local function stopDeathChecker()
    ScriptState.deathCheckRunning = false
    if ScriptState.checkConnection then
        ScriptState.checkConnection:Disconnect()
        ScriptState.checkConnection = nil
    end
end

local function cleanup()
    for _, tween in pairs(ScriptState.currentTweens) do
        if tween and tween.PlaybackState ~= Enum.PlaybackState.Completed then
            tween:Cancel()
        end
    end
    ScriptState.currentTweens = {}
    
    restoreOriginalGravity()
    ScriptState.isRunning = false
end

local function disconnectAll()
    for _, connection in pairs(ScriptState.connections) do
        if connection then
            pcall(function() connection:Disconnect() end)
        end
    end
    ScriptState.connections = {}
    
    stopDeathChecker()
    restoreOriginalGravity()
end

local function waitForTween(tweenObj, timeout)
    timeout = timeout or 30
    local startTime = tick()
    
    while tweenObj.PlaybackState == Enum.PlaybackState.Playing do
        if tick() - startTime > timeout then
            return false
        end
        runService.Heartbeat:Wait()
    end
    
    return true
end

local function createTween(object, tweenInfo, properties)
    if not object or not object.Parent then
        return nil
    end
    
    local newTween = tween:Create(object, tweenInfo, properties)
    table.insert(ScriptState.currentTweens, newTween)
    return newTween
end

local function validateCharacter()
    local character = plr.Character
    if not character then
        return false, nil
    end
    
    local humroot = character:FindFirstChild("HumanoidRootPart")
    if not humroot then
        return false, nil
    end
    
    return true, humroot
end

local function validateEndTarget()
    local target = workspace:FindFirstChild("BoatStages")
    
    if target then
        target = target:FindFirstChild("NormalStages")
    end
    if target then
        target = target:FindFirstChild("TheEnd")
    end
    if target then
        target = target:FindFirstChild("GoldenChest")
    end
    if target then
        target = target:FindFirstChild("Trigger")
    end
    
    if not target then
        return false, nil
    end
    
    return true, target.CFrame
end

local function executeMovement()
    if ScriptState.isRunning then
        return
    end
    
    ScriptState.isRunning = true
    
    if not ScriptState.originalGravity then
        ScriptState.originalGravity = workspace.Gravity
    end
    
    local isValid, humroot = validateCharacter()
    if not isValid then
        ScriptState.isRunning = false
        return
    end
    
    local targetValid, endCFrame = validateEndTarget()
    if not targetValid then
        ScriptState.isRunning = false
        return
    end
    
    setGravity(CONFIG.GRAVITY_REDUCED)
    
    local startTween = createTween(
        humroot,
        TweenInfo.new(CONFIG.TWEEN_SPEEDS.START, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, false, 0),
        {CFrame = CFrame.new(-51.3946571, 67.3164978, 814.888123, -0.999501824, -0.00451373775, 0.0312365349, -8.62000427e-09, 0.989720345, 0.14301616, -0.0315609723, 0.142944917, -0.989227295)}
    )
    
    if not startTween then
        cleanup()
        return
    end
    
    startTween:Play()
    if not waitForTween(startTween) then
        cleanup()
        return
    end
    
    isValid, humroot = validateCharacter()
    if not isValid then
        cleanup()
        return
    end
    
    local mainTween = createTween(
        humroot,
        TweenInfo.new(CONFIG.TWEEN_SPEEDS.MAIN, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, false, 0),
        {CFrame = CFrame.new(-77.0485153, 82.6013031, 8625.86719, -0.995574772, 0.022579968, -0.0912195817, -4.97565011e-09, 0.970703065, 0.240282282, 0.0939726979, 0.23921898, -0.966407478)}
    )
    
    if not mainTween then
        cleanup()
        return
    end
    
    mainTween:Play()
    if not waitForTween(mainTween) then
        cleanup()
        return
    end
    
    isValid, humroot = validateCharacter()
    if not isValid then
        cleanup()
        return
    end
    
    local endTween = createTween(
        humroot,
        TweenInfo.new(CONFIG.TWEEN_SPEEDS.END, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, false, 0),
        {CFrame = endCFrame}
    )
    
    if not endTween then
        cleanup()
        return
    end
    
    endTween:Play()
    if not waitForTween(endTween) then
        cleanup()
        return
    end
    
    restoreOriginalGravity()
    
    ScriptState.lastDeathTime = tick()
    if not ScriptState.deathCheckRunning then
        startDeathChecker()
    end
    
    ScriptState.isRunning = false
end

local function safeExecuteMovement()
    pcall(executeMovement)
end

local function onCharacterAdded(character)
    stopDeathChecker()
    
    if not character then
        return
    end
    
    spawn(function()
        character:WaitForChild("HumanoidRootPart", 10)
        wait(1)
        safeExecuteMovement()
    end)
    
    spawn(function()
        local humanoid = character:WaitForChild("Humanoid", 5)
        if humanoid then
            ScriptState.connections.humanoidDied = humanoid.Died:Connect(function()
                stopDeathChecker()
            end)
        end
    end)
end

local function initialize()
    if not checkGameID() then
        return
    end
    
    disconnectAll()
    
    ScriptState.originalGravity = workspace.Gravity
    
    if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
        spawn(safeExecuteMovement)
    end
    
    ScriptState.connections.characterAdded = plr.CharacterAdded:Connect(onCharacterAdded)
    
    if plr.Character then
        spawn(function()
            onCharacterAdded(plr.Character)
        end)
    end
end

initialize()

getgenv().StopAntiCheatTest = function()
    disconnectAll()
end