local players = game:GetService("Players")
local plr = players.LocalPlayer
local tween = game:GetService("TweenService")
local runService = game:GetService("RunService")

local CONFIG = {
    TARGET_GAME_ID = 123456789, -- Thay đổi thành game ID bạn muốn
    GRAVITY_REDUCED = 1.0,      -- Gravity khi đang di chuyển
    GRAVITY_DEFAULT = 196.2,    -- Gravity mặc định của Roblox
    TWEEN_SPEEDS = {
        START = 4,
        MAIN = 20.5,
        END = 4
    },
    MAX_RETRIES = 3,
    RETRY_DELAY = 2,
    DEATH_CHECK_INTERVAL = 1,   -- Kiểm tra mỗi giây
    DEATH_TIMEOUT = 20,         -- Reset sau 20s không phát hiện chết
    RESET_COOLDOWN = 5          -- Cooldown giữa các lần reset
}

local ScriptState = {
    isRunning = false,
    currentTweens = {},
    connections = {},
    retryCount = 0,
    originalGravity = nil,
    lastDeathTime = 0,
    deathCheckRunning = false,
    lastResetTime = 0
}

local function checkGameID()
    return game.GameId == CONFIG.TARGET_GAME_ID
end

local function setGravity(value)
    pcall(function()
        game.Workspace.Gravity = value
    end)
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
    
    pcall(function()
        if plr.Character and plr.Character:FindFirstChild("Humanoid") then
            plr.Character.Humanoid.Health = 0
        else
            plr:LoadCharacter()
        end
    end)
end

local function startDeathChecker()
    if ScriptState.deathCheckRunning then
        return
    end
    
    ScriptState.deathCheckRunning = true
    ScriptState.lastDeathTime = tick()
    
    spawn(function()
        while ScriptState.deathCheckRunning do
            wait(CONFIG.DEATH_CHECK_INTERVAL)
            
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
        end
    end)
end

local function stopDeathChecker()
    ScriptState.deathCheckRunning = false
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
            connection:Disconnect()
        end
    end
    ScriptState.connections = {}
    
    stopDeathChecker()
    restoreOriginalGravity()
end

local function safeWait(tween, timeout)
    timeout = timeout or 30
    local startTime = tick()
    
    while tween.PlaybackState == Enum.PlaybackState.Playing do
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
    if not plr.Character then
        return false, nil
    end
    
    local humroot = plr.Character:FindFirstChild("HumanoidRootPart")
    if not humroot then
        return false, nil
    end
    
    return true, humroot
end

local function validateEndTarget()
    local workspace = game:GetService("Workspace")
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
    ScriptState.retryCount = ScriptState.retryCount + 1
    
    if not ScriptState.originalGravity then
        ScriptState.originalGravity = game.Workspace.Gravity
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
        ScriptState.isRunning = false
        restoreOriginalGravity()
        return
    end
    
    startTween:Play()
    if not safeWait(startTween) then
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
    if not safeWait(mainTween) then
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
    if not safeWait(endTween) then
        cleanup()
        return
    end
    
    restoreOriginalGravity()
    
    ScriptState.lastDeathTime = tick()
    if not ScriptState.deathCheckRunning then
        startDeathChecker()
    end
    
    ScriptState.isRunning = false
    ScriptState.retryCount = 0
end

local function safeExecuteMovement()
    local success, error = pcall(executeMovement)
    if not success then
        cleanup()
        
        if ScriptState.retryCount < CONFIG.MAX_RETRIES then
            wait(CONFIG.RETRY_DELAY)
            safeExecuteMovement()
        else
            ScriptState.retryCount = 0
        end
    end
end

local function initialize()
    if not checkGameID() then
        return
    end
    
    disconnectAll()
    
    ScriptState.originalGravity = game.Workspace.Gravity
    
    if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
        spawn(safeExecuteMovement)
    end
    
    ScriptState.connections.characterAdded = plr.CharacterAdded:Connect(function(char)
        stopDeathChecker()
        
        local humanoidRootPart = char:WaitForChild("HumanoidRootPart", 10)
        if humanoidRootPart then
            wait(1)
            spawn(safeExecuteMovement)
        end
    end)
    
    local function setupDeathDetection(character)
        local humanoid = character:WaitForChild("Humanoid", 5)
        if humanoid then
            ScriptState.connections.humanoidDied = humanoid.Died:Connect(function()
                stopDeathChecker()
            end)
        end
    end
    
    if plr.Character then
        setupDeathDetection(plr.Character)
    end
    
    ScriptState.connections.characterAddedDeath = plr.CharacterAdded:Connect(setupDeathDetection)
    
    ScriptState.connections.playerRemoving = players.PlayerRemoving:Connect(function(player)
        if player == plr then
            cleanup()
            disconnectAll()
        end
    end)
end

initialize()