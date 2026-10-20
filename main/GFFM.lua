-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")

local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Hidden Parent Protection
local protectedParent = (gethui and gethui()) or (get_hidden_gui and get_hidden_gui()) or CoreGui

-- Network Events
local WeaponHitEvent = ReplicatedStorage:WaitForChild("WeaponsSystem"):WaitForChild("Network"):WaitForChild("WeaponHit")
local IceWallEvent = ReplicatedStorage:WaitForChild("Communication"):WaitForChild("Gelo")

-- Default Settings Configuration
local Settings = {
    ShowFOV = false,
    ESPEnabled = false,
    ESPLineEnabled = false,
    ShootThroughWalls = false,
    AutoShoot = false,
    AutoHitAll = false,
    AutoIceAll = false,
    IceWallFlood = false,
    IceFloodSpeed = 0.1, -- Configurable Ice Flood Speed (Interval in seconds)
    FOVRadius = 70,
    ShootCooldown = 0.2,
    MoveButtons = false,
    ButtonScale = 1.0,
    -- FIRE Button Position Data
    ShootBtnScaleX = 0.8, ShootBtnOffsetX = 0,
    ShootBtnScaleY = 0.6, ShootBtnOffsetY = 0,
    -- ICE Button Position Data
    IceBtnScaleX = 0.8, IceBtnOffsetX = 0,
    IceBtnScaleY = 0.72, IceBtnOffsetY = 0
}

-- Config Persistence (Auto Save / Load)
local CONFIG_FILE = "RUOK_Config.json"

local function SaveConfig()
    if writefile then
        pcall(function()
            writefile(CONFIG_FILE, HttpService:JSONEncode(Settings))
        end)
    end
end

local function LoadConfig()
    if readfile and isfile and isfile(CONFIG_FILE) then
        pcall(function()
            local decoded = HttpService:JSONDecode(readfile(CONFIG_FILE))
            for key, value in pairs(decoded) do
                Settings[key] = value
            end
        end)
    end
end

LoadConfig()

local lastShotTime = 0
local lastHitAllIndex = 1
local lastHitAllTime = 0
local HIT_ALL_INTERVAL = 0.2

local lastIceAllTime = 0
local ICE_ALL_INTERVAL = 0.1

local lastFloodTime = 0

local lastHealths = {}
local activeTarget = nil
local actionButtons = {}

---------------------------------------------------------
-- SPAWN PLANE SAFE ZONE CHECK HELPER
---------------------------------------------------------
local function isPlayerInSpawnPlane(player)
    if not player or not player.Character then return false end
    local head = player.Character:FindFirstChild("Head")
    if not head then return false end

    local planeFolder = Workspace:FindFirstChild("Plane")
    local innerPlane = planeFolder and planeFolder:FindFirstChild("Plane")
    local spawnPlane = innerPlane and innerPlane:FindFirstChild("SpawnPlane")

    if spawnPlane and spawnPlane:IsA("BasePart") then
        local planeCF = spawnPlane.CFrame
        local planeSize = spawnPlane.Size
        local localPos = planeCF:PointToObjectSpace(head.Position)

        local halfX = planeSize.X / 2
        local halfZ = planeSize.Z / 2
        
        if math.abs(localPos.X) <= halfX and math.abs(localPos.Z) <= halfZ and localPos.Y >= -(planeSize.Y / 2) then
            return true
        end
    end

    return false
end

---------------------------------------------------------
-- FLOATING DAMAGE POPUP SYSTEM
---------------------------------------------------------
local function showDamagePopup(character, damageAmount)
    local head = character and character:FindFirstChild("Head")
    if not head or damageAmount <= 0 then return end

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "DamagePopup"
    billboard.Adornee = head
    billboard.Size = UDim2.new(0, 120, 0, 50)
    billboard.StudsOffset = Vector3.new(math.random(-1, 1), 3.5, math.random(-1, 1))
    billboard.AlwaysOnTop = true

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
    textLabel.TextStrokeTransparency = 0
    textLabel.TextSize = 26
    textLabel.Font = Enum.Font.SourceSansBold
    textLabel.Text = "-" .. math.floor(damageAmount)
    textLabel.Parent = billboard

    billboard.Parent = character

    task.spawn(function()
        local startTime = tick()
        local duration = 0.8
        while tick() - startTime < duration do
            local alpha = (tick() - startTime) / duration
            if billboard and billboard.Parent then
                billboard.StudsOffset = billboard.StudsOffset + Vector3.new(0, 0.06, 0)
                textLabel.TextTransparency = alpha
                textLabel.TextStrokeTransparency = alpha
            else
                break
            end
            RunService.RenderStepped:Wait()
        end
        if billboard then billboard:Destroy() end
    end)
end

---------------------------------------------------------
-- FOV CIRCLE GUI
---------------------------------------------------------
local fovGui = Instance.new("ScreenGui")
fovGui.Name = "FOVCircleGui"
fovGui.IgnoreGuiInset = true
fovGui.Parent = protectedParent

local fovFrame = Instance.new("Frame")
fovFrame.Size = UDim2.new(0, Settings.FOVRadius * 2, 0, Settings.FOVRadius * 2)
fovFrame.AnchorPoint = Vector2.new(0.5, 0.5)
fovFrame.BackgroundTransparency = 1
fovFrame.Parent = fovGui

local fovCorner = Instance.new("UICorner")
fovCorner.CornerRadius = UDim.new(1, 0)
fovCorner.Parent = fovFrame

local fovStroke = Instance.new("UIStroke")
fovStroke.Color = Color3.fromRGB(255, 255, 255)
fovStroke.Thickness = 1.5
fovStroke.Parent = fovFrame

---------------------------------------------------------
-- TRACER LINES CONTAINER GUI
---------------------------------------------------------
local linesGui = Instance.new("ScreenGui")
linesGui.Name = "RUOK_TracerLines"
linesGui.IgnoreGuiInset = true
linesGui.Parent = protectedParent

local function drawGuiLine(frame, pointA, pointB, color)
    local distance = (pointA - pointB).Magnitude
    local angle = math.atan2(pointB.Y - pointA.Y, pointB.X - pointA.X)

    frame.Size = UDim2.new(0, distance, 0, 2)
    frame.Position = UDim2.new(0, (pointA.X + pointB.X) / 2, 0, (pointA.Y + pointB.Y) / 2)
    frame.Rotation = math.deg(angle)
    frame.BackgroundColor3 = color
    frame.Visible = true
end

---------------------------------------------------------
-- CIRCLE BUTTONS CREATION HELPER
---------------------------------------------------------
local shootGui = Instance.new("ScreenGui")
shootGui.Name = "RUOK_ActionButtonsGui"
shootGui.Parent = protectedParent

local function createCircleButton(name, text, scaleX, offsetX, scaleY, offsetY)
    local button = Instance.new("TextButton")
    button.Name = name
    local baseSize = 70 * Settings.ButtonScale
    button.Size = UDim2.new(0, baseSize, 0, baseSize)
    button.Position = UDim2.new(scaleX, offsetX, scaleY, offsetY)
    button.AnchorPoint = Vector2.new(0.5, 0.5)
    button.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    button.BackgroundTransparency = 0.7
    button.Text = text
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.TextSize = 16 * math.clamp(Settings.ButtonScale, 0.8, 2.5)
    button.Font = Enum.Font.SourceSansBold
    button.Parent = shootGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = button

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Thickness = 2
    stroke.Transparency = 0.5
    stroke.Parent = button

    -- Dragging Logic
    local dragging, dragStart, startPos
    button.InputBegan:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and Settings.MoveButtons then
            dragging = true
            dragStart = input.Position
            startPos = button.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            button.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            dragging = false
            if name == "ShootButton" then
                Settings.ShootBtnScaleX = button.Position.X.Scale
                Settings.ShootBtnOffsetX = button.Position.X.Offset
                Settings.ShootBtnScaleY = button.Position.Y.Scale
                Settings.ShootBtnOffsetY = button.Position.Y.Offset
            elseif name == "IceWallButton" then
                Settings.IceBtnScaleX = button.Position.X.Scale
                Settings.IceBtnOffsetX = button.Position.X.Offset
                Settings.IceBtnScaleY = button.Position.Y.Scale
                Settings.IceBtnOffsetY = button.Position.Y.Offset
            end
            SaveConfig()
        end
    end)

    table.insert(actionButtons, button)
    return button, stroke
end

local function updateButtonSizes()
    local newSize = 70 * Settings.ButtonScale
    local newTextSize = 16 * math.clamp(Settings.ButtonScale, 0.8, 2.5)
    for _, btn in ipairs(actionButtons) do
        btn.Size = UDim2.new(0, newSize, 0, newSize)
        btn.TextSize = newTextSize
    end
end

---------------------------------------------------------
-- SHOOT & ICE WALL ACTIONS
---------------------------------------------------------
local function shootHead(targetPlayer)
    if not targetPlayer or not targetPlayer.Character then return end
    if isPlayerInSpawnPlane(targetPlayer) then return end

    local headPart = targetPlayer.Character:FindFirstChild("Head")
    local localChar = LocalPlayer.Character
    local equippedWeapon = localChar and localChar:FindFirstChildOfClass("Tool")

    if headPart and localChar and equippedWeapon then
        pcall(function()
            WeaponHitEvent:FireServer(
                equippedWeapon,
                {
                    p = headPart.Position,
                    pid = 1,
                    part = headPart,
                    d = (headPart.Position - Camera.CFrame.Position).Magnitude,
                    maxDist = 5000,
                    h = headPart,
                    m = Enum.Material.Plastic,
                    n = Vector3.new(0, 1, 0),
                    t = 0.05,
                    sid = 1
                }
            )
        end)
    end
end

local function placeIceWallAtCharacter(character)
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    if rootPart then
        local spawnPos = (rootPart.CFrame * CFrame.new(0, 0, -8)).Position
        pcall(function()
            IceWallEvent:FireServer(spawnPos)
        end)
    end
end

local function placeIceWall()
    placeIceWallAtCharacter(LocalPlayer.Character)
end

-- Create Action Buttons
local shootButton, shootStroke = createCircleButton("ShootButton", "FIRE", Settings.ShootBtnScaleX, Settings.ShootBtnOffsetX, Settings.ShootBtnScaleY, Settings.ShootBtnOffsetY)
local iceButton, iceStroke = createCircleButton("IceWallButton", "ICE", Settings.IceBtnScaleX, Settings.IceBtnOffsetX, Settings.IceBtnScaleY, Settings.IceBtnOffsetY)

-- FIRE Button Click
shootButton.MouseButton1Click:Connect(function()
    if not Settings.MoveButtons and activeTarget then
        shootHead(activeTarget)
    end
end)

-- ICE Wall Hold to Spam (0.1s interval)
local isSpammingIce = false
iceButton.InputBegan:Connect(function(input)
    if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and not Settings.MoveButtons then
        isSpammingIce = true
        task.spawn(function()
            while isSpammingIce do
                placeIceWall()
                task.wait(0.1)
            end
        end)
    end
end)

local function stopIceSpam(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isSpammingIce = false
    end
end

iceButton.InputEnded:Connect(stopIceSpam)

---------------------------------------------------------
-- RUOK DRAGGABLE MENU GUI & HIDE BUTTON
---------------------------------------------------------
local mainGui = Instance.new("ScreenGui")
mainGui.Name = "RUOK_Menu"
mainGui.Parent = protectedParent

local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 230, 0, 520)
mainFrame.Position = UDim2.new(0.05, 0, 0.3, 0)
mainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = mainGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 8)
mainCorner.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(1, 0, 0, 35)
titleLabel.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
titleLabel.Text = "RUOK MENU"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.TextSize = 18
titleLabel.Font = Enum.Font.SourceSansBold
titleLabel.Parent = mainFrame

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(0, 8)
titleCorner.Parent = titleLabel

-- Menu Dragging Logic
local draggingMenu, dragInputMenu, dragStartMenu, startPosMenu
titleLabel.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingMenu = true
        dragStartMenu = input.Position
        startPosMenu = mainFrame.Position
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if draggingMenu and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStartMenu
        mainFrame.Position = UDim2.new(startPosMenu.X.Scale, startPosMenu.X.Offset + delta.X, startPosMenu.Y.Scale, startPosMenu.Y.Offset + delta.Y)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if draggingMenu and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
        draggingMenu = false
    end
end)

-- Bottom-Right Screen Toggle GUI Button
local toggleGui = Instance.new("ScreenGui")
toggleGui.Name = "RUOK_ToggleGui"
toggleGui.Parent = protectedParent

local openMenuBtn = Instance.new("TextButton")
openMenuBtn.Size = UDim2.new(0, 80, 0, 35)
openMenuBtn.Position = UDim2.new(1, -90, 1, -45)
openMenuBtn.BackgroundColor3 = Color3.fromRGB(180, 0, 0)
openMenuBtn.Text = "RUOK"
openMenuBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
openMenuBtn.Font = Enum.Font.SourceSansBold
openMenuBtn.TextSize = 16
openMenuBtn.Parent = toggleGui

local openBtnCorner = Instance.new("UICorner")
openBtnCorner.CornerRadius = UDim.new(0, 6)
openBtnCorner.Parent = openMenuBtn

local function toggleMenu()
    mainFrame.Visible = not mainFrame.Visible
end

openMenuBtn.MouseButton1Click:Connect(toggleMenu)

-- PC Hotkey (CTRL)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and (input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl) then
        toggleMenu()
    end
end)

-- UI Helper Function for Toggles
local yOffset = 45
local function createToggle(name, defaultState, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0.9, 0, 0, 30)
    button.Position = UDim2.new(0.05, 0, 0, yOffset)
    button.BackgroundColor3 = defaultState and Color3.fromRGB(40, 160, 40) or Color3.fromRGB(60, 60, 60)
    button.Text = name .. ": " .. (defaultState and "ON" or "OFF")
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Font = Enum.Font.SourceSansBold
    button.TextSize = 14
    button.Parent = mainFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 5)
    corner.Parent = button

    local state = defaultState
    button.MouseButton1Click:Connect(function()
        state = not state
        button.BackgroundColor3 = state and Color3.fromRGB(40, 160, 40) or Color3.fromRGB(60, 60, 60)
        button.Text = name .. ": " .. (state and "ON" or "OFF")
        callback(state)
        SaveConfig()
    end)

    yOffset = yOffset + 35
    return button
end

-- Toggles
createToggle("Show FOV", Settings.ShowFOV, function(v) Settings.ShowFOV = v end)
createToggle("ESP", Settings.ESPEnabled, function(v) Settings.ESPEnabled = v end)
createToggle("ESP Line", Settings.ESPLineEnabled, function(v) Settings.ESPLineEnabled = v end)
createToggle("Wall Check", not Settings.ShootThroughWalls, function(v) Settings.ShootThroughWalls = not v end)
createToggle("Auto Shoot", Settings.AutoShoot, function(v) Settings.AutoShoot = v end)
createToggle("Auto Hit All", Settings.AutoHitAll, function(v) Settings.AutoHitAll = v end)
createToggle("Auto Ice All", Settings.AutoIceAll, function(v) Settings.AutoIceAll = v end)
createToggle("Ice Wall Flood", Settings.IceWallFlood, function(v) Settings.IceWallFlood = v end)

-- Move Toggle
createToggle("Move Buttons", Settings.MoveButtons, function(v) 
    Settings.MoveButtons = v 
    local activeColor = v and Color3.fromRGB(255, 200, 0) or Color3.fromRGB(255, 255, 255)
    shootStroke.Color = activeColor
    iceStroke.Color = activeColor
end)

-- FOV Size Input
local fovInputBox = Instance.new("TextBox")
fovInputBox.Size = UDim2.new(0.9, 0, 0, 30)
fovInputBox.Position = UDim2.new(0.05, 0, 0, yOffset)
fovInputBox.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
fovInputBox.Text = "FOV Radius: " .. tostring(Settings.FOVRadius)
fovInputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
fovInputBox.Font = Enum.Font.SourceSansBold
fovInputBox.TextSize = 14
fovInputBox.Parent = mainFrame

local fovCorner = Instance.new("UICorner")
fovCorner.CornerRadius = UDim.new(0, 5)
fovCorner.Parent = fovInputBox

fovInputBox.FocusLost:Connect(function()
    local num = tonumber(fovInputBox.Text:match("%d+"))
    if num then
        Settings.FOVRadius = num
        fovFrame.Size = UDim2.new(0, num * 2, 0, num * 2)
        fovInputBox.Text = "FOV Radius: " .. tostring(num)
        SaveConfig()
    else
        fovInputBox.Text = "FOV Radius: " .. tostring(Settings.FOVRadius)
    end
end)

yOffset = yOffset + 35

-- Button Size Input Box (Scale: 0.3 to 5.0)
local sizeInputBox = Instance.new("TextBox")
sizeInputBox.Size = UDim2.new(0.9, 0, 0, 30)
sizeInputBox.Position = UDim2.new(0.05, 0, 0, yOffset)
sizeInputBox.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
sizeInputBox.Text = "Btn Size: " .. tostring(Settings.ButtonScale)
sizeInputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
sizeInputBox.Font = Enum.Font.SourceSansBold
sizeInputBox.TextSize = 14
sizeInputBox.Parent = mainFrame

local sizeCorner = Instance.new("UICorner")
sizeCorner.CornerRadius = UDim.new(0, 5)
sizeCorner.Parent = sizeInputBox

sizeInputBox.FocusLost:Connect(function()
    local num = tonumber(sizeInputBox.Text:match("[%d%.]+"))
    if num then
        num = math.clamp(num, 0.3, 5.0)
        Settings.ButtonScale = num
        updateButtonSizes()
        sizeInputBox.Text = "Btn Size: " .. tostring(num)
        SaveConfig()
    else
        sizeInputBox.Text = "Btn Size: " .. tostring(Settings.ButtonScale)
    end
end)

yOffset = yOffset + 35

-- Ice Flood Speed Input Box (In seconds, e.g. 0.05 or 0.1)
local speedInputBox = Instance.new("TextBox")
speedInputBox.Size = UDim2.new(0.9, 0, 0, 30)
speedInputBox.Position = UDim2.new(0.05, 0, 0, yOffset)
speedInputBox.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
speedInputBox.Text = "Ice Speed: " .. tostring(Settings.IceFloodSpeed)
speedInputBox.TextColor3 = Color3.fromRGB(255, 255, 255)
speedInputBox.Font = Enum.Font.SourceSansBold
speedInputBox.TextSize = 14
speedInputBox.Parent = mainFrame

local speedCorner = Instance.new("UICorner")
speedCorner.CornerRadius = UDim.new(0, 5)
speedCorner.Parent = speedInputBox

speedInputBox.FocusLost:Connect(function()
    local num = tonumber(speedInputBox.Text:match("[%d%.]+"))
    if num then
        num = math.clamp(num, 0.01, 5.0) -- Clamped to a min of 0.01s
        Settings.IceFloodSpeed = num
        speedInputBox.Text = "Ice Speed: " .. tostring(num)
        SaveConfig()
    else
        speedInputBox.Text = "Ice Speed: " .. tostring(Settings.IceFloodSpeed)
    end
end)

---------------------------------------------------------
-- ESP SETUP & LINE CREATION
---------------------------------------------------------
local espLineFrames = {}

local function setupPlayerESP(player)
    if player == LocalPlayer then return end

    local lineFrame = Instance.new("Frame")
    lineFrame.Name = "TracerLine_" .. player.Name
    lineFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    lineFrame.BorderSizePixel = 0
    lineFrame.Visible = false
    lineFrame.Parent = linesGui
    espLineFrames[player] = lineFrame

    local function setupCharacter(char)
        if not char then return end
        
        local oldHighlight = char:FindFirstChild("ESPHighlight")
        if oldHighlight then oldHighlight:Destroy() end
        local oldGui = char:FindFirstChild("ESPNameGui")
        if oldGui then oldGui:Destroy() end

        local highlight = Instance.new("Highlight")
        highlight.Name = "ESPHighlight"
        highlight.Adornee = char
        highlight.FillTransparency = 0.6
        highlight.OutlineTransparency = 0
        highlight.FillColor = Color3.fromRGB(255, 255, 255)
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.Parent = char

        local head = char:WaitForChild("Head", 5)
        if head then
            local billboard = Instance.new("BillboardGui")
            billboard.Name = "ESPNameGui"
            billboard.Adornee = head
            billboard.Size = UDim2.new(0, 250, 0, 60)
            billboard.StudsOffset = Vector3.new(0, 2.8, 0)
            billboard.AlwaysOnTop = true
            
            local textLabel = Instance.new("TextLabel")
            textLabel.Name = "InfoLabel"
            textLabel.Size = UDim2.new(1, 0, 1, 0)
            textLabel.BackgroundTransparency = 1
            textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
            textLabel.TextStrokeTransparency = 0
            textLabel.TextSize = 22
            textLabel.Font = Enum.Font.SourceSansBold
            textLabel.Text = player.Name .. " | 100/100"
            textLabel.Parent = billboard
            
            billboard.Parent = char
        end
    end

    if player.Character then setupCharacter(player.Character) end
    player.CharacterAdded:Connect(setupCharacter)
end

local function removePlayerESP(player)
    if espLineFrames[player] then
        espLineFrames[player]:Destroy()
        espLineFrames[player] = nil
    end
end

for _, player in ipairs(Players:GetPlayers()) do
    setupPlayerESP(player)
end
Players.PlayerAdded:Connect(setupPlayerESP)
Players.PlayerRemoving:Connect(removePlayerESP)

---------------------------------------------------------
-- MAIN RENDER LOOP
---------------------------------------------------------
RunService.RenderStepped:Connect(function()
    local viewportSize = Camera.ViewportSize
    local screenCenter = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)

    fovFrame.Visible = Settings.ShowFOV
    fovFrame.Position = UDim2.new(0, screenCenter.X, 0, screenCenter.Y)

    activeTarget = nil
    local shortestDistance = Settings.FOVRadius

    -- Find ALL instances named "Force Field" in Workspace
    local ignoreList = {LocalPlayer.Character}
    local searchFolder = Workspace:FindFirstChild("CurrentMap") or Workspace
    for _, obj in ipairs(searchFolder:GetDescendants()) do
        if obj.Name == "Force Field" then
            table.insert(ignoreList, obj)
        end
    end

    -- Target detection inside FOV
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character and not isPlayerInSpawnPlane(player) then
            local char = player.Character
            local humanoid = char:FindFirstChild("Humanoid")
            local head = char:FindFirstChild("Head")

            if humanoid and head and humanoid.Health > 0 then
                local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)

                if onScreen then
                    local distance = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude

                    if distance < shortestDistance then
                        local isVisible = true

                        if not Settings.ShootThroughWalls then
                            local raycastParams = RaycastParams.new()
                            raycastParams.FilterType = Enum.RaycastFilterType.Exclude
                            raycastParams.FilterDescendantsInstances = ignoreList
                            raycastParams.IgnoreWater = true

                            local rayResult = Workspace:Raycast(Camera.CFrame.Position, head.Position - Camera.CFrame.Position, raycastParams)
                            if not (rayResult and rayResult.Instance:IsDescendantOf(char)) then
                                isVisible = false
                            end
                        end

                        if isVisible then
                            shortestDistance = distance
                            activeTarget = player
                        end
                    end
                end
            end
        end
    end

    -- Visual updates
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local char = player.Character
            local humanoid = char:FindFirstChild("Humanoid")
            local head = char:FindFirstChild("Head")
            local highlight = char:FindFirstChild("ESPHighlight")
            local billboard = char:FindFirstChild("ESPNameGui")
            local lineFrame = espLineFrames[player]

            if highlight then highlight.Enabled = Settings.ESPEnabled end
            if billboard then billboard.Enabled = Settings.ESPEnabled end

            if humanoid and head and humanoid.Health > 0 then
                local currentHealth = humanoid.Health
                if lastHealths[player] and lastHealths[player] > currentHealth then
                    showDamagePopup(char, lastHealths[player] - currentHealth)
                end
                lastHealths[player] = currentHealth

                if billboard then
                    local textLabel = billboard:FindFirstChild("InfoLabel")
                    if textLabel then
                        textLabel.Text = player.Name .. " | " .. math.floor(currentHealth) .. "/" .. math.floor(humanoid.MaxHealth)
                    end
                end

                local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)

                -- Render RED Line ONLY if player is the active target
                if lineFrame then
                    if Settings.ESPLineEnabled and onScreen and (player == activeTarget) then
                        drawGuiLine(lineFrame, screenCenter, Vector2.new(screenPos.X, screenPos.Y), Color3.fromRGB(255, 0, 0))
                    else
                        lineFrame.Visible = false
                    end
                end

                -- Highlight / Billboard colors
                if player == activeTarget then
                    if highlight then
                        highlight.FillColor = Color3.fromRGB(255, 0, 0)
                        highlight.OutlineColor = Color3.fromRGB(255, 0, 0)
                    end
                    if billboard then
                        local textLabel = billboard:FindFirstChild("InfoLabel")
                        if textLabel then textLabel.TextColor3 = Color3.fromRGB(255, 0, 0) end
                    end
                else
                    if highlight then
                        highlight.FillColor = Color3.fromRGB(255, 255, 255)
                        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                    end
                    if billboard then
                        local textLabel = billboard:FindFirstChild("InfoLabel")
                        if textLabel then textLabel.TextColor3 = Color3.fromRGB(255, 255, 255) end
                    end
                end
            else
                if lineFrame then lineFrame.Visible = false end
            end
        else
            if espLineFrames[player] then espLineFrames[player].Visible = false end
        end
    end

    local currentTime = tick()

    -- Controlled Auto Shoot execution for FOV target
    if Settings.AutoShoot and activeTarget and (currentTime - lastShotTime >= Settings.ShootCooldown) then
        lastShotTime = currentTime
        shootHead(activeTarget)
    end

    -- Auto Hit All Logic
    if Settings.AutoHitAll and (currentTime - lastHitAllTime >= HIT_ALL_INTERVAL) then
        local allPlayers = Players:GetPlayers()
        if #allPlayers > 1 then
            if lastHitAllIndex > #allPlayers then lastHitAllIndex = 1 end

            local targetHitPlayer = allPlayers[lastHitAllIndex]
            if targetHitPlayer and targetHitPlayer ~= LocalPlayer and targetHitPlayer.Character then
                local hum = targetHitPlayer.Character:FindFirstChild("Humanoid")
                
                if hum and hum.Health > 0 and not isPlayerInSpawnPlane(targetHitPlayer) then
                    local isHitValid = true

                    if not Settings.ShootThroughWalls then
                        local targetHead = targetHitPlayer.Character:FindFirstChild("Head")
                        if targetHead then
                            local raycastParams = RaycastParams.new()
                            raycastParams.FilterType = Enum.RaycastFilterType.Exclude
                            raycastParams.FilterDescendantsInstances = ignoreList
                            raycastParams.IgnoreWater = true

                            local rayResult = Workspace:Raycast(Camera.CFrame.Position, targetHead.Position - Camera.CFrame.Position, raycastParams)
                            if not (rayResult and rayResult.Instance:IsDescendantOf(targetHitPlayer.Character)) then
                                isHitValid = false
                            end
                        else
                            isHitValid = false
                        end
                    end

                    if isHitValid then
                        shootHead(targetHitPlayer)
                        lastHitAllTime = currentTime
                    end
                end
            end
            lastHitAllIndex = lastHitAllIndex + 1
        end
    end

    -- Instant Simultaneous Auto Ice All Logic
    if Settings.AutoIceAll and (currentTime - lastIceAllTime >= ICE_ALL_INTERVAL) then
        lastIceAllTime = currentTime
        for _, enemyPlayer in ipairs(Players:GetPlayers()) do
            if enemyPlayer ~= LocalPlayer and enemyPlayer.Character then
                local hum = enemyPlayer.Character:FindFirstChild("Humanoid")
                if hum and hum.Health > 0 then
                    placeIceWallAtCharacter(enemyPlayer.Character)
                end
            end
        end
    end

    -- Configurable Spatial Ice Wall Flood Logic
    if Settings.IceWallFlood and (currentTime - lastFloodTime >= Settings.IceFloodSpeed) then
        lastFloodTime = currentTime
        local currentMap = Workspace:FindFirstChild("CurrentMap") or Workspace
        local cframe, size
        
        if currentMap:IsA("Model") then
            cframe, size = currentMap:GetBoundingBox()
        elseif currentMap:IsA("BasePart") then
            cframe, size = currentMap.CFrame, currentMap.Size
        end

        if cframe and size then
            local halfSize = size / 2
            for i = 1, 10 do
                local randomOffsetX = math.random(-halfSize.X, halfSize.X)
                local randomOffsetY = math.random(-halfSize.Y / 2, halfSize.Y / 2)
                local randomOffsetZ = math.random(-halfSize.Z, halfSize.Z)
                local floodPoint = cframe:PointToWorldSpace(Vector3.new(randomOffsetX, randomOffsetY, randomOffsetZ))

                pcall(function()
                    IceWallEvent:FireServer(floodPoint)
                end)
            end
        end
    end
end)
