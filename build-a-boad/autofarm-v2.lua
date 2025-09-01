local players = game:GetService("Players")
local plr = players.LocalPlayer
local tween = game:GetService("TweenService")
local runService = game:GetService("RunService")

-- Configuration
local CONFIG = {
    TARGET_GAME_ID = 537413528,
    GRAVITY_REDUCED = 1.0,
    GRAVITY_DEFAULT = 196.2,
    TWEEN_SPEEDS = {
        START = 0, -- Instant teleport thay vì 4s
        MAIN = 20.5, -- Giữ nguyên 20.5s
        END = 0 -- Instant teleport thay vì 4s
    },
    DEATH_TIMEOUT = 20,
    RESET_COOLDOWN = 5,
    UI_CONFIG = {
        BUTTON_SIZE_SCALE = 0.035, -- Tỉ lệ % so với chiều cao màn hình
        BUTTON_POSITION_X = 0.02, -- 2% từ bên trái
        BUTTON_POSITION_Y = 0.02, -- 2% từ trên xuống
        MIN_SIZE = 30, -- Kích thước tối thiểu (pixels)
        MAX_SIZE = 60, -- Kích thước tối đa (pixels)
        MEMORY_KEY = "AntiCheatScript_State" -- Key để lưu trạng thái
    },
    NOTIFICATIONS = {
        WRONG_GAME = {
            title = "❌ Game Error",
            message = "Script không hỗ trợ game này!",
            duration = 5
        },
        SCRIPT_LOADED = {
            title = "✅ Script Loaded", 
            message = "Anti-Cheat Test Script đã sẵn sàng!",
            duration = 3
        },
        SCRIPT_ENABLED = {
            title = "🟢 Script Enabled",
            message = "Anti-Cheat Test đang chạy!",
            duration = 2
        },
        SCRIPT_DISABLED = {
            title = "🔴 Script Disabled",
            message = "Anti-Cheat Test đã dừng!",
            duration = 2
        }
    }
}

-- State Management
local ScriptState = {
    isRunning = false,
    currentTweens = {},
    connections = {},
    originalGravity = nil,
    lastDeathTime = 0,
    deathCheckRunning = false,
    lastResetTime = 0,
    checkConnection = nil,
    scriptEnabled = true,
    toggleButton = nil
}

-- Utilities
local function showNotification(title, message, duration)
    duration = duration or 5
    
    -- Method 1: Achievement-style notification
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = title,
            Text = message,
            Duration = duration,
            Icon = "rbxasset://textures/ui/GuiImagePlaceholder.png"
        })
    end)
    
    -- Method 2: Alternative notification for different games
    pcall(function()
        local StarterGui = game:GetService("StarterGui")
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)
        
        StarterGui:SetCore("ChatMakeSystemMessage", {
            Text = "[" .. title .. "] " .. message,
            Font = Enum.Font.GothamBold,
            Color = Color3.fromRGB(255, 215, 0),
            FontSize = Enum.FontSize.Size18
        })
    end)
end

-- Memory System
local function saveScriptState(enabled)
    pcall(function()
        if writefile then
            writefile(CONFIG.UI_CONFIG.MEMORY_KEY .. ".txt", tostring(enabled))
        end
    end)
end

local function loadScriptState()
    local success, result = pcall(function()
        if readfile and isfile then
            if isfile(CONFIG.UI_CONFIG.MEMORY_KEY .. ".txt") then
                local content = readfile(CONFIG.UI_CONFIG.MEMORY_KEY .. ".txt")
                return content == "true"
            end
        end
        return true -- Default enabled
    end)
    
    return success and result or true
end

-- UI Creation
local function createToggleButton()
    local CoreGui = game:GetService("CoreGui")
    local TweenService = game:GetService("TweenService")
    
    -- Calculate responsive size based on screen
    local function calculateButtonSize()
        local viewport = workspace.CurrentCamera.ViewportSize
        local screenHeight = viewport.Y
        
        -- Calculate size based on screen height percentage
        local calculatedSize = math.floor(screenHeight * CONFIG.UI_CONFIG.BUTTON_SIZE_SCALE)
        
        -- Clamp between min and max
        local finalSize = math.max(CONFIG.UI_CONFIG.MIN_SIZE, math.min(CONFIG.UI_CONFIG.MAX_SIZE, calculatedSize))
        
        return UDim2.new(0, finalSize, 0, finalSize)
    end
    
    -- Calculate responsive position
    local function calculateButtonPosition()
        return UDim2.new(CONFIG.UI_CONFIG.BUTTON_POSITION_X, 0, CONFIG.UI_CONFIG.BUTTON_POSITION_Y, 0)
    end
    
    -- Create ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AntiCheatToggle"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.IgnoreGuiInset = true -- Bỏ qua TopBar để positioning chính xác
    
    -- Create Button
    local button = Instance.new("TextButton")
    button.Name = "ToggleButton"
    button.Size = calculateButtonSize()
    button.Position = calculateButtonPosition()
    button.AnchorPoint = Vector2.new(0, 0) -- Anchor từ góc trên trái
    button.BackgroundColor3 = ScriptState.scriptEnabled and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(200, 0, 0)
    button.BorderSizePixel = 0
    button.Font = Enum.Font.GothamBold
    button.Text = ScriptState.scriptEnabled and "✓" or "✗"
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextScaled = true
    button.ZIndex = 10
    
    -- Rounded corners with responsive radius
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, math.max(8, button.AbsoluteSize.X * 0.2))
    corner.Parent = button
    
    -- Add padding for text
    local textPadding = Instance.new("UIPadding")
    textPadding.PaddingBottom = UDim.new(0, 2)
    textPadding.PaddingTop = UDim.new(0, 2)
    textPadding.PaddingLeft = UDim.new(0, 2)
    textPadding.PaddingRight = UDim.new(0, 2)
    textPadding.Parent = button
    
    -- Responsive resize handler
    local function updateButtonSize()
        local newSize = calculateButtonSize()
        local newPosition = calculateButtonPosition()
        
        -- Smooth transition to new size
        local sizeTween = TweenService:Create(button, 
            TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), 
            {Size = newSize, Position = newPosition}
        )
        sizeTween:Play()
        
        -- Update corner radius
        corner.CornerRadius = UDim.new(0, math.max(8, newSize.X.Offset * 0.2))
    end
    
    -- Listen for viewport changes
    local viewportConnection
    viewportConnection = workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
        wait(0.1) -- Small delay to avoid rapid firing
        updateButtonSize()
    end)
    
    -- Store connection for cleanup
    ScriptState.connections.viewportResize = viewportConnection
    
    -- Hover effect (responsive)
    local function getHoverSize()
        local currentSize = button.Size
        local hoverOffset = math.max(3, currentSize.X.Offset * 0.1)
        return UDim2.new(currentSize.X.Scale, currentSize.X.Offset + hoverOffset, 
                         currentSize.Y.Scale, currentSize.Y.Offset + hoverOffset)
    end
    
    button.MouseEnter:Connect(function()
        local hoverSize = getHoverSize()
        local tween = TweenService:Create(button, TweenInfo.new(0.2), {Size = hoverSize})
        tween:Play()
    end)
    
    button.MouseLeave:Connect(function()
        local normalSize = calculateButtonSize()
        local tween = TweenService:Create(button, TweenInfo.new(0.2), {Size = normalSize})
        tween:Play()
    end)
    
    -- Click functionality
    button.MouseButton1Click:Connect(function()
        ScriptState.scriptEnabled = not ScriptState.scriptEnabled
        saveScriptState(ScriptState.scriptEnabled)
        
        -- Update button appearance
        button.BackgroundColor3 = ScriptState.scriptEnabled and Color3.fromRGB(0, 200, 0) or Color3.fromRGB(200, 0, 0)
        button.Text = ScriptState.scriptEnabled and "✓" or "✗"
        
        -- Show notification
        if ScriptState.scriptEnabled then
            showNotification("🟢 Script Enabled", "Anti-Cheat Test đang chạy!", 2)
            -- Start script if character exists
            if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                spawn(safeExecuteMovement)
            end
        else
            showNotification("🔴 Script Disabled", "Anti-Cheat Test đã dừng!", 2)
            -- Stop current operations
            cleanup()
            stopDeathChecker()
        end
        
        -- Click animation (responsive)
        local normalSize = calculateButtonSize()
        local clickSize = UDim2.new(normalSize.X.Scale, normalSize.X.Offset - math.max(2, normalSize.X.Offset * 0.05), 
                                   normalSize.Y.Scale, normalSize.Y.Offset - math.max(2, normalSize.Y.Offset * 0.05))
        
        local clickTween = TweenService:Create(button, TweenInfo.new(0.1), {Size = clickSize})
        clickTween:Play()
        clickTween.Completed:Connect(function()
            local backTween = TweenService:Create(button, TweenInfo.new(0.1), {Size = normalSize})
            backTween:Play()
        end)
    end)
    
    button.Parent = screenGui
    screenGui.Parent = CoreGui
    
    return button
end

local function checkGameID()
    local placeId = game.PlaceId
    
    -- Sử dụng PlaceId vì ID từ URL là PlaceId
    local isCorrectGame = placeId == CONFIG.TARGET_GAME_ID
    
    if not isCorrectGame then
        showNotification("❌ Game Error", "Script không hỗ trợ game này!", 5)
        return false
    end
    
    showNotification("✅ Script Loaded", "Anti-Cheat Test Script đã sẵn sàng!", 3)
    return true
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

-- Movement helper functions
local function instantTeleport(humroot, targetCFrame)
    if not humroot or not humroot.Parent then
        return false
    end
    
    humroot.CFrame = targetCFrame
    return true
end

local function createMovementTween(humroot, duration, targetCFrame)
    if duration <= 0 then
        -- Instant teleport
        return instantTeleport(humroot, targetCFrame)
    else
        -- Normal tween
        return createTween(
            humroot,
            TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, false, 0),
            {CFrame = targetCFrame}
        )
    end
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
-- Main Movement Function
local function executeMovement()
    if ScriptState.isRunning or not ScriptState.scriptEnabled then
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
    
    -- Phase 1: Instant teleport to start position
    local startCFrame = CFrame.new(-51.3946571, 67.3164978, 814.888123, -0.999501824, -0.00451373775, 0.0312365349, -8.62000427e-09, 0.989720345, 0.14301616, -0.0315609723, 0.142944917, -0.989227295)
    
    local startResult = createMovementTween(humroot, CONFIG.TWEEN_SPEEDS.START, startCFrame)
    
    if CONFIG.TWEEN_SPEEDS.START > 0 then
        -- If it's a tween, wait for completion
        if not startResult then
            cleanup()
            return
        end
        
        startResult:Play()
        if not waitForTween(startResult) then
            cleanup()
            return
        end
    else
        -- If it's instant teleport, check if it succeeded
        if not startResult then
            cleanup()
            return
        end
        wait(0.1) -- Small delay for stability
    end
    
    -- Validate character still exists
    isValid, humroot = validateCharacter()
    if not isValid then
        cleanup()
        return
    end
    
    -- Phase 2: Main movement (keeps original 20.5s tween)
    local mainCFrame = CFrame.new(-77.0485153, 82.6013031, 8625.86719, -0.995574772, 0.022579968, -0.0912195817, -4.97565011e-09, 0.970703065, 0.240282282, 0.0939726979, 0.23921898, -0.966407478)
    
    local mainResult = createMovementTween(humroot, CONFIG.TWEEN_SPEEDS.MAIN, mainCFrame)
    
    if not mainResult then
        cleanup()
        return
    end
    
    mainResult:Play()
    if not waitForTween(mainResult) then
        cleanup()
        return
    end
    
    -- Validate character again
    isValid, humroot = validateCharacter()
    if not isValid then
        cleanup()
        return
    end
    
    -- Phase 3: Instant teleport to final position
    local endResult = createMovementTween(humroot, CONFIG.TWEEN_SPEEDS.END, endCFrame)
    
    if CONFIG.TWEEN_SPEEDS.END > 0 then
        -- If it's a tween, wait for completion
        if not endResult then
            cleanup()
            return
        end
        
        endResult:Play()
        if not waitForTween(endResult) then
            cleanup()
            return
        end
    else
        -- If it's instant teleport, check if it succeeded
        if not endResult then
            cleanup()
            return
        end
        wait(0.1) -- Small delay for stability
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

-- Character event handlers
local function onCharacterAdded(character)
    stopDeathChecker()
    
    if not character or not ScriptState.scriptEnabled then
        return
    end
    
    spawn(function()
        character:WaitForChild("HumanoidRootPart", 10)
        wait(1)
        if ScriptState.scriptEnabled then
            safeExecuteMovement()
        end
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

-- Main initialization
local function initialize()
    if not checkGameID() then
        return
    end
    
    -- Load previous state
    ScriptState.scriptEnabled = loadScriptState()
    
    -- Create toggle button
    ScriptState.toggleButton = createToggleButton()
    
    ScriptState.originalGravity = workspace.Gravity
    
    if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") and ScriptState.scriptEnabled then
        spawn(safeExecuteMovement)
    end
    
    ScriptState.connections.characterAdded = plr.CharacterAdded:Connect(onCharacterAdded)
    
    if plr.Character then
        spawn(function()
            onCharacterAdded(plr.Character)
        end)
    end
end

-- Auto-start
initialize()

-- Global cleanup function for manual cleanup if needed
getgenv().StopAntiCheatTest = function()
    ScriptState.scriptEnabled = false
    saveScriptState(false)
    cleanup()
    disconnectAll()
    if ScriptState.toggleButton then
        ScriptState.toggleButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
        ScriptState.toggleButton.Text = "✗"
    end
    showNotification("🔴 Script Disabled", "Anti-Cheat Test đã dừng!", 2)
end