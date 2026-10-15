local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 5) or LocalPlayer.PlayerGui

local protectedParent = (gethui and gethui()) or (get_hidden_gui and get_hidden_gui()) or CoreGui

LocalPlayer.CameraMaxZoomDistance = math.huge
LocalPlayer.CameraMinZoomDistance = 0.5

if PlayerGui:FindFirstChild("SizeEditorGUI") then 
    PlayerGui.SizeEditorGUI:Destroy() 
end

local function styleElement(obj, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 10)
    corner.Parent = obj
end

local tweenInfoFast = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local tweenInfoClose = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

local function smoothOpen(uiObject)
    local uiScale = uiObject:FindFirstChildOfClass("UIScale")
    if not uiScale then
        uiScale = Instance.new("UIScale", uiObject)
    end
    uiScale.Scale = 0
    uiObject.Visible = true
    local tween = TweenService:Create(uiScale, tweenInfoFast, {Scale = 1})
    tween:Play()
end

local function smoothClose(uiObject, callback)
    local uiScale = uiObject:FindFirstChildOfClass("UIScale")
    if not uiScale then
        uiScale = Instance.new("UIScale", uiObject)
        uiScale.Scale = 1
    end
    local tween = TweenService:Create(uiScale, tweenInfoClose, {Scale = 0})
    tween:Play()
    tween.Completed:Connect(function()
        uiObject.Visible = false
        uiScale.Scale = 1
        if callback then callback() end
    end)
end

local selectedPlayers = {} 
local espActive = false      
local loopSelected = false   
local loopEveryone = false   
local lastLoopUpdate = 0
local LOOP_DELAY = 0.05      
_G.DetectedSizeID = _G.DetectedSizeID or nil
local idFoundState = false
local isExecutingSequence = false 
local updateList
local updatePlayerESPVisual

local gui = Instance.new("ScreenGui")
gui.Name = "SizeEditorGUI"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = PlayerGui

-- STATUS DISPLAY (LONGER UI)
local seqStatusLabel = Instance.new("TextLabel", gui)
seqStatusLabel.Size = UDim2.new(0, 330, 0, 42)
seqStatusLabel.Position = UDim2.new(1, -435, 1, -55)
seqStatusLabel.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
seqStatusLabel.Text = "ready"
seqStatusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
seqStatusLabel.Font = Enum.Font.GothamBold
seqStatusLabel.TextScaled = true
styleElement(seqStatusLabel, 21)

local floatingBtn = Instance.new("TextButton", gui)
floatingBtn.Size = UDim2.new(0, 80, 0, 42)
floatingBtn.Position = UDim2.new(1, -95, 1, -55)
floatingBtn.BackgroundColor3 = Color3.fromRGB(30, 120, 225)
floatingBtn.Text = "MISG"
floatingBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
floatingBtn.Font = Enum.Font.GothamBold
floatingBtn.TextSize = 16
floatingBtn.Active = true
styleElement(floatingBtn, 21)

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 310, 0, 520)
frame.Position = UDim2.new(0.5, -160, 0.5, -260)
frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
frame.Active = true
styleElement(frame, 16)

local titleBar = Instance.new("Frame", frame)
titleBar.Size = UDim2.new(1, 0, 0, 48)
titleBar.BackgroundTransparency = 1
titleBar.Active = true

local titleLabel = Instance.new("TextLabel", titleBar)
titleLabel.Size = UDim2.new(1, -60, 1, 0)
titleLabel.Position = UDim2.new(0, 18, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "MISG HUB"
titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 22
titleLabel.TextXAlignment = Enum.TextXAlignment.Left

local minBtn = Instance.new("TextButton", titleBar)
minBtn.Size = UDim2.new(0, 34, 0, 34)
minBtn.Position = UDim2.new(1, -44, 0.5, -17)
minBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
minBtn.Text = "-"
minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
minBtn.Font = Enum.Font.GothamBold
minBtn.TextSize = 18
styleElement(minBtn, 17)

local playerPopup = Instance.new("Frame", gui)
playerPopup.Size = UDim2.new(0, 280, 0, 260)
playerPopup.Position = UDim2.new(frame.Position.X.Scale, frame.Position.X.Offset + frame.Size.X.Offset + 12, frame.Position.Y.Scale, frame.Position.Y.Offset)
playerPopup.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
playerPopup.Visible = false
playerPopup.Active = true
styleElement(playerPopup, 16)

local popupHeader = Instance.new("Frame", playerPopup)
popupHeader.Size = UDim2.new(1, -20, 0, 42)
popupHeader.Position = UDim2.new(0, 10, 0, 8)
popupHeader.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
popupHeader.Active = true
styleElement(popupHeader, 14)

local popupClose = Instance.new("TextButton", popupHeader)
popupClose.Size = UDim2.new(0, 28, 0, 28)
popupClose.Position = UDim2.new(1, -34, 0.5, -14)
popupClose.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
popupClose.Text = "-"
popupClose.TextColor3 = Color3.fromRGB(255, 255, 255)
popupClose.Font = Enum.Font.GothamBold
popupClose.TextSize = 16
styleElement(popupClose, 14)

local searchBox = Instance.new("TextBox", popupHeader)
searchBox.Size = UDim2.new(1, -45, 1, 0)
searchBox.Position = UDim2.new(0, 12, 0, 0)
searchBox.BackgroundTransparency = 1
searchBox.PlaceholderText = "search for player..."
searchBox.Text = ""
searchBox.TextColor3 = Color3.fromRGB(255, 255, 255)
searchBox.PlaceholderColor3 = Color3.fromRGB(150, 150, 150)
searchBox.TextXAlignment = Enum.TextXAlignment.Left
searchBox.Font = Enum.Font.Gotham
searchBox.TextSize = 14

local playerList = Instance.new("ScrollingFrame", playerPopup)
playerList.Position = UDim2.new(0, 10, 0, 58)
playerList.Size = UDim2.new(1, -20, 1, -68)
playerList.BackgroundTransparency = 1
playerList.BorderSizePixel = 0
playerList.ScrollBarThickness = 3
playerList.AutomaticCanvasSize = Enum.AutomaticSize.Y
local listLayout = Instance.new("UIListLayout", playerList)
listLayout.Padding = UDim.new(0, 6)

smoothOpen(frame)
smoothOpen(floatingBtn)
smoothOpen(seqStatusLabel)

local function alignPopupToRight()
    playerPopup.Position = UDim2.new(
        frame.Position.X.Scale, 
        frame.Position.X.Offset + frame.Size.X.Offset + 12, 
        frame.Position.Y.Scale, 
        frame.Position.Y.Offset
    )
end

local isClosing = false
local function closeAllSequentially()
    if isClosing then return end
    isClosing = true
    
    if playerPopup.Visible then
        smoothClose(playerPopup, function()
            smoothClose(frame, function()
                isClosing = false
            end)
        end)
    else
        smoothClose(frame, function()
            isClosing = false
        end)
    end
end

local function applyMobileDrag(targetFrame, dragHandle)
    dragHandle = dragHandle or targetFrame
    local dragging = false
    local dragStart, startPos

    dragHandle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = targetFrame.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            targetFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    local function onInputEnded(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end

    dragHandle.InputEnded:Connect(onInputEnded)
    UserInputService.InputEnded:Connect(onInputEnded)
end

applyMobileDrag(frame, titleBar)
applyMobileDrag(playerPopup, popupHeader)
applyMobileDrag(playerPopup, searchBox)
applyMobileDrag(floatingBtn)
applyMobileDrag(seqStatusLabel)

local selectPlayerBtn = Instance.new("TextButton", frame)
selectPlayerBtn.Size = UDim2.new(1, -20, 0, 42)
selectPlayerBtn.Position = UDim2.new(0, 10, 0, 54)
selectPlayerBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
selectPlayerBtn.Text = "Select Player  >"
selectPlayerBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
selectPlayerBtn.Font = Enum.Font.Gotham
selectPlayerBtn.TextSize = 15
styleElement(selectPlayerBtn, 12)

selectPlayerBtn.MouseButton1Click:Connect(function()
    if playerPopup.Visible then
        smoothClose(playerPopup)
    else
        alignPopupToRight()
        smoothOpen(playerPopup)
    end
end)

popupClose.MouseButton1Click:Connect(function()
    smoothClose(playerPopup)
end)

local cancelBtn = Instance.new("TextButton", frame)
cancelBtn.Size = UDim2.new(1, -20, 0, 42)
cancelBtn.Position = UDim2.new(0, 10, 0, 104)
cancelBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
cancelBtn.Text = "DeSelect All Player"
cancelBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
cancelBtn.Font = Enum.Font.Gotham
cancelBtn.TextSize = 15
styleElement(cancelBtn, 12)

cancelBtn.MouseButton1Click:Connect(function()
    selectedPlayers = {}
    for _, p in ipairs(Players:GetPlayers()) do 
        updatePlayerESPVisual(p) 
    end
    updateList()
end)

local bodyParts = {"Height", "Width", "Depth", "Head"}
local selectedParts = {Height = true, Width = true, Depth = true, Head = true}
local partsFrame = Instance.new("Frame", frame)
partsFrame.Size = UDim2.new(1, -20, 0, 92)
partsFrame.Position = UDim2.new(0, 10, 0, 154)
partsFrame.BackgroundTransparency = 1

local grid = Instance.new("UIGridLayout", partsFrame)
grid.CellSize = UDim2.new(0.48, 0, 0, 42)
grid.CellPadding = UDim2.new(0.04, 0, 0, 8)

for _, partText in ipairs(bodyParts) do
    local cb = Instance.new("TextButton", partsFrame)
    cb.BackgroundColor3 = Color3.fromRGB(30, 120, 225)
    cb.Text = partText
    cb.TextColor3 = Color3.fromRGB(255, 255, 255)
    cb.Font = Enum.Font.Gotham
    cb.TextSize = 16
    styleElement(cb, 16)
    
    cb.MouseButton1Click:Connect(function()
        selectedParts[partText] = not selectedParts[partText]
        cb.BackgroundColor3 = selectedParts[partText] and Color3.fromRGB(30, 120, 225) or Color3.fromRGB(0, 0, 0)
    end)
end

local scaleBox = Instance.new("TextBox", frame)
scaleBox.Size = UDim2.new(1, -20, 0, 42)
scaleBox.Position = UDim2.new(0, 10, 0, 254)
scaleBox.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
scaleBox.Text = "1"
scaleBox.ClearTextOnFocus = false
scaleBox.TextColor3 = Color3.fromRGB(255, 255, 255)
scaleBox.Font = Enum.Font.Gotham
scaleBox.TextSize = 16
styleElement(scaleBox, 12)

local applySelectContainer = Instance.new("Frame", frame)
applySelectContainer.Size = UDim2.new(1, -20, 0, 44)
applySelectContainer.Position = UDim2.new(0, 10, 0, 304)
applySelectContainer.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
styleElement(applySelectContainer, 12)

local applyBtn = Instance.new("TextButton", applySelectContainer)
applyBtn.Size = UDim2.new(1, -85, 1, 0)
applyBtn.BackgroundTransparency = 1
applyBtn.Text = "Apply To Select"
applyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
applyBtn.Font = Enum.Font.Gotham
applyBtn.TextSize = 14

local div1 = Instance.new("Frame", applySelectContainer)
div1.Size = UDim2.new(0, 2, 0.7, 0)
div1.Position = UDim2.new(1, -85, 0.15, 0)
div1.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
div1.BorderSizePixel = 0

local loopSelectedBtn = Instance.new("TextButton", applySelectContainer)
loopSelectedBtn.Size = UDim2.new(0, 85, 1, 0)
loopSelectedBtn.Position = UDim2.new(1, -83, 0, 0)
loopSelectedBtn.BackgroundTransparency = 1
loopSelectedBtn.Text = "LOOP 🔴"
loopSelectedBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
loopSelectedBtn.Font = Enum.Font.GothamBold
loopSelectedBtn.TextSize = 12

local applyAllContainer = Instance.new("Frame", frame)
applyAllContainer.Size = UDim2.new(1, -20, 0, 44)
applyAllContainer.Position = UDim2.new(0, 10, 0, 356)
applyAllContainer.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
styleElement(applyAllContainer, 12)

local allBtn = Instance.new("TextButton", applyAllContainer)
allBtn.Size = UDim2.new(1, -85, 1, 0)
allBtn.BackgroundTransparency = 1
allBtn.Text = "Apply To All"
allBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
allBtn.Font = Enum.Font.Gotham
allBtn.TextSize = 14

local div2 = Instance.new("Frame", applyAllContainer)
div2.Size = UDim2.new(0, 2, 0.7, 0)
div2.Position = UDim2.new(1, -85, 0.15, 0)
div2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
div2.BorderSizePixel = 0

local loopEveryoneBtn = Instance.new("TextButton", applyAllContainer)
loopEveryoneBtn.Size = UDim2.new(0, 85, 1, 0)
loopEveryoneBtn.Position = UDim2.new(1, -83, 0, 0)
loopEveryoneBtn.BackgroundTransparency = 1
loopEveryoneBtn.Text = "LOOP 🔴"
loopEveryoneBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
loopEveryoneBtn.Font = Enum.Font.GothamBold
loopEveryoneBtn.TextSize = 12

local footerFrame = Instance.new("Frame", frame)
footerFrame.Size = UDim2.new(1, -20, 0, 42)
footerFrame.Position = UDim2.new(0, 10, 0, 460)
footerFrame.BackgroundTransparency = 1

local sizeIdLabel = Instance.new("TextLabel", footerFrame)
sizeIdLabel.Size = UDim2.new(0.65, 0, 1, 0)
sizeIdLabel.Position = UDim2.new(0, 5, 0, 0)
sizeIdLabel.BackgroundTransparency = 1
sizeIdLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
sizeIdLabel.Text = "Find ID..."
sizeIdLabel.Font = Enum.Font.GothamBold
sizeIdLabel.TextSize = 13
sizeIdLabel.TextXAlignment = Enum.TextXAlignment.Left

local espToggle = Instance.new("TextButton", footerFrame)
espToggle.Size = UDim2.new(0, 80, 0, 36)
espToggle.Position = UDim2.new(1, -80, 0.5, -18)
espToggle.BackgroundColor3 = Color3.fromRGB(0, 0, 0) 
espToggle.Text = "ESP"
espToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
espToggle.Font = Enum.Font.Gotham
espToggle.TextSize = 15
styleElement(espToggle, 16)

task.spawn(function()
    local dots = {".", "..", "..."}
    local idx = 1
    while not idFoundState and not _G.DetectedSizeID do
        sizeIdLabel.Text = "Find ID" .. dots[idx]
        idx = (idx % 3) + 1
        task.wait(0.4)
    end
    if _G.DetectedSizeID then
        sizeIdLabel.Text = "ID FOUND"
    end
end)

local POST = nil
task.spawn(function()
    pcall(function()
        POST = ReplicatedStorage:FindFirstChild("POST") or ReplicatedStorage:WaitForChild("POST", 2)
        if POST then
            local mt = getrawmetatable(game)
            if mt then
                local oldNamecall = mt.__namecall
                setreadonly(mt, false)
                mt.__namecall = newcclosure(function(self, ...)
                    local args = {...}
                    if self == POST and args[2] == "UpdateScale" then
                        _G.DetectedSizeID = tostring(args[1])
                        idFoundState = true
                        if sizeIdLabel then sizeIdLabel.Text = "ID FOUND" end
                    end
                    return oldNamecall(self, ...)
                end)
                setreadonly(mt, true)
            end
        end
    end)
end)

task.spawn(function()
    task.wait(4)
    pcall(function()
        local button = game:GetService("Players").LocalPlayer.PlayerGui.UI.NoobSize.Frame.Reset.Button
        if button then
            if firebutton1click then
                firebutton1click(button)
            elseif getconnections then
                for _, conn in ipairs(getconnections(button.MouseButton1Click)) do
                    conn:Fire()
                end
                for _, conn in ipairs(getconnections(button.Activated)) do
                    conn:Fire()
                end
            end
        end
    end)
    
    task.wait(3)
    if not _G.DetectedSizeID then
        idFoundState = true
        if sizeIdLabel then sizeIdLabel.Text = "ID Not Found!" end
    end
end)

local function getESPColor(player)
    return selectedPlayers[player.Name] and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(0, 255, 255)
end

local function getNameColor(player)
    return selectedPlayers[player.Name] and Color3.fromRGB(255, 50, 50) or Color3.fromRGB(255, 255, 255)
end

updatePlayerESPVisual = function(player)
    if player and player.Character then
        local highlight = player.Character:FindFirstChild("ESPHighlight")
        if highlight then
            highlight.FillColor = getESPColor(player)
            highlight.Enabled = espActive
        end
        local tag = player.Character:FindFirstChild("ESPNameTag")
        if tag then
            tag.Enabled = espActive
            local label = tag:FindFirstChildOfClass("TextLabel")
            if label then
                label.TextColor3 = getNameColor(player)
            end
        end
    end
end

-- ESP & CHARACTER CLICK SELECTION SETUP (INFINITE DISTANCE)
local function applyESP(player)
    if player == LocalPlayer then return end
    local function setupCharacter(char)
        local highlight = char:FindFirstChild("ESPHighlight") or Instance.new("Highlight")
        highlight.Name = "ESPHighlight"
        highlight.FillColor = getESPColor(player)
        highlight.FillTransparency = 0.5
        highlight.OutlineColor = Color3.new(1, 1, 1)
        highlight.Enabled = espActive 
        highlight.Parent = char

        local billboard = char:FindFirstChild("ESPNameTag") or Instance.new("BillboardGui")
        billboard.Name = "ESPNameTag"
        billboard.Size = UDim2.new(0, 200, 0, 45)
        billboard.StudsOffset = Vector3.new(0, 3.5, 0)
        billboard.AlwaysOnTop = true
        billboard.Enabled = espActive 
        billboard.Parent = char

        local label = billboard:FindFirstChildOfClass("TextLabel") or Instance.new("TextLabel", billboard)
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = player.DisplayName .. "\n(@" .. player.Name .. ")"
        label.TextColor3 = getNameColor(player)
        label.Font = Enum.Font.GothamBold
        label.TextScaled = true 

        if not label:FindFirstChildOfClass("UIStroke") then
            local stroke = Instance.new("UIStroke", label)
            stroke.Color = Color3.new(0, 0, 0)
            stroke.Thickness = 2
        end

        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then
                local clickDetector = part:FindFirstChild("PlayerSelectClickDetector") or Instance.new("ClickDetector")
                clickDetector.Name = "PlayerSelectClickDetector"
                clickDetector.MaxActivationDistance = math.huge
                clickDetector.Parent = part

                if clickDetector:GetAttribute("Connected") ~= true then
                    clickDetector:SetAttribute("Connected", true)
                    clickDetector.MouseClick:Connect(function(clicker)
                        if clicker == LocalPlayer then
                            if selectedPlayers[player.Name] then
                                selectedPlayers[player.Name] = nil
                            else
                                selectedPlayers[player.Name] = true
                            end
                            updateList()
                            updatePlayerESPVisual(player)
                        end
                    end)
                end
            end
        end
    end

    if player.Character then setupCharacter(player.Character) end
    player.CharacterAdded:Connect(function(char)
        task.wait(0.3)
        setupCharacter(char)
        updatePlayerESPVisual(player)
    end)
end

updateList = function()
    local filter = searchBox.Text:lower()
    
    for _, child in pairs(playerList:GetChildren()) do 
        if child:IsA("TextButton") then child:Destroy() end 
    end
    
    local players = Players:GetPlayers()
    table.sort(players, function(a, b)
        if a == LocalPlayer then return true end
        if b == LocalPlayer then return false end
        return a.DisplayName:lower() < b.DisplayName:lower()
    end)

    for _, player in ipairs(players) do
        local isMe = (player == LocalPlayer)
        local displayName = isMe and "You" or (player.DisplayName .. " (@" .. player.Name .. ")")
        
        if displayName:lower():find(filter) or player.Name:lower():find(filter) then
            local btn = Instance.new("TextButton", playerList)
            btn.Size = UDim2.new(1, -6, 0, 36)
            btn.Text = displayName
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.Font = Enum.Font.Gotham
            btn.TextSize = 13
            
            local isSelected = selectedPlayers[player.Name]
            if isSelected then
                btn.BackgroundColor3 = Color3.fromRGB(30, 120, 225)
            elseif isMe then
                btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
            else
                btn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
            end
            
            styleElement(btn, 12)
            
            btn.MouseButton1Click:Connect(function()
                selectedPlayers[player.Name] = not selectedPlayers[player.Name] and true or nil
                updateList()
                updatePlayerESPVisual(player) 
            end)
        end
    end
end

-- HELPER TO FETCH INITIAL PART SIZE INDIVIDUALLY FOR EACH PLAYER
local function getPlayerInitialPartSize(p, partName)
    local fallback = 1
    local success, result = pcall(function()
        if p and p.Character then
            local humanoid = p.Character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                local scaleObj = humanoid:FindFirstChild("Body" .. partName .. "Scale") or humanoid:FindFirstChild(partName .. "Scale")
                if scaleObj then
                    return scaleObj.Value
                end
            end
        end
    end)
    if success and result then
        return result
    end
    return fallback
end

-- SEQUENCE PARSER WITH INSTANT SINGLE-NUMBER SET & SPAM GUARD
local function runScaleSequence(inputText, targetsTable, modeType)
    local singleVal = tonumber(inputText)
    if singleVal then
        if modeType == "Select" then
            seqStatusLabel.Text = string.format("size: %.1f applied to select", singleVal)
        else
            seqStatusLabel.Text = string.format("size: %.1f applied to all", singleVal)
        end
        local useId = _G.DetectedSizeID
        local remote = ReplicatedStorage:FindFirstChild("POST")
        if useId and remote then
            for _, p in ipairs(targetsTable) do
                if p then
                    for partName, enabled in pairs(selectedParts) do
                        if enabled then
                            pcall(function()
                                remote:FireServer(useId, "UpdateScale", p, partName, singleVal * 100)
                            end)
                        end
                    end
                end
            end
        end
        task.delay(1.5, function()
            seqStatusLabel.Text = "ready"
        end)
        return
    end

    if isExecutingSequence then return end
    isExecutingSequence = true

    task.spawn(function()
        if modeType == "Select" then
            seqStatusLabel.Text = "Applied Size To Select"
        else
            seqStatusLabel.Text = "Applied Size To All"
        end

        local playerInitialSizes = {}
        for _, p in ipairs(targetsTable) do
            playerInitialSizes[p] = {}
            for partName, _ in pairs(selectedParts) do
                playerInitialSizes[p][partName] = getPlayerInitialPartSize(p, partName)
            end
        end

        local tokens = {}
        for token in inputText:gmatch("[^,]+") do
            local trimmed = token:match("^%s*(.-)%s*$")
            if trimmed ~= "" then
                table.insert(tokens, trimmed)
            end
        end

        local function applyToAllTargets(val)
            local useId = _G.DetectedSizeID
            local remote = ReplicatedStorage:FindFirstChild("POST")
            if useId and remote then
                for _, p in ipairs(targetsTable) do
                    if p then
                        for partName, enabled in pairs(selectedParts) do
                            if enabled then
                                pcall(function()
                                    remote:FireServer(useId, "UpdateScale", p, partName, val * 100)
                                end)
                            end
                        end
                    end
                end
            end
        end

        local function applyPlayerOriginalSizes(progressRatio)
            local useId = _G.DetectedSizeID
            local remote = ReplicatedStorage:FindFirstChild("POST")
            if useId and remote then
                for _, p in ipairs(targetsTable) do
                    if p and playerInitialSizes[p] then
                        for partName, enabled in pairs(selectedParts) do
                            if enabled then
                                local origSize = playerInitialSizes[p][partName] or 1
                                local startSize = currentSize or 1
                                local interpolatedSize = startSize + ((origSize - startSize) * math.clamp(progressRatio, 0, 1))
                                pcall(function()
                                    remote:FireServer(useId, "UpdateScale", p, partName, interpolatedSize * 100)
                                end)
                            end
                        end
                    end
                end
            end
        end

        local currentSize = nil
        local pendingDelay = 0.5
        local i = 1

        while i <= #tokens do
            local t = tokens[i]

            if t:sub(1, 2) == ".." and not t:find("!!") and not t:find("!") then
                pendingDelay = tonumber(t:sub(3)) or 0.5
                i = i + 1

            elseif t:sub(1, 2) == ".!" then
                local stepAdd = tonumber(t:sub(3)) or 0.5
                local targetLimitToken = nil
                
                if tokens[i+1] and tokens[i+1]:sub(1, 2) == "!!" then
                    targetLimitToken = tokens[i+1]:sub(3)
                    i = i + 2
                else
                    i = i + 1
                end

                if currentSize then
                    if targetLimitToken == "?" then
                        local tempSize = currentSize
                        local isShrinking = currentSize > 1
                        
                        while true do
                            local diff = math.abs(1 - tempSize)
                            if diff < 0.01 then break end
                            
                            tempSize = isShrinking and (tempSize - stepAdd) or (tempSize + stepAdd)
                            if isShrinking and tempSize < 1 then tempSize = 1 end
                            if not isShrinking and tempSize > 1 then tempSize = 1 end

                            local ratio = math.abs(tempSize - currentSize) / math.abs(1 - currentSize)
                            if not ratio or ratio ~= ratio then ratio = 1 end

                            seqStatusLabel.Text = string.format("add: %.1f, time: %.1f, restoring", stepAdd, pendingDelay)
                            applyPlayerOriginalSizes(ratio)
                            task.wait(pendingDelay)
                            if tempSize == 1 then break end
                        end
                        currentSize = 1
                    else
                        local targetLimit = tonumber(targetLimitToken) or 5
                        local tempSize = currentSize
                        local isShrinking = currentSize > targetLimit
                        while (isShrinking and tempSize > targetLimit) or (not isShrinking and tempSize < targetLimit) do
                            local left = math.abs(targetLimit - tempSize)
                            if left < stepAdd then
                                tempSize = targetLimit
                            else
                                tempSize = isShrinking and (tempSize - stepAdd) or (tempSize + stepAdd)
                            end
                            
                            if isShrinking and tempSize < targetLimit then tempSize = targetLimit end
                            if not isShrinking and tempSize > targetLimit then tempSize = targetLimit end
                            
                            seqStatusLabel.Text = string.format("add: %.1f, time: %.1f, left", stepAdd, pendingDelay)
                            applyToAllTargets(tempSize)
                            task.wait(pendingDelay)
                        end
                        currentSize = targetLimit
                    end
                end

            elseif t:sub(1, 2) == "!!" then
                local targetLimitToken = t:sub(3)
                if targetLimitToken == "?" then
                    if currentSize then
                        local tempSize = currentSize
                        local defaultStep = 0.5
                        local isShrinking = currentSize > 1
                        while true do
                            local diff = math.abs(1 - tempSize)
                            if diff < 0.05 then break end

                            tempSize = isShrinking and (tempSize - defaultStep) or (tempSize + defaultStep)
                            if isShrinking and tempSize < 1 then tempSize = 1 end
                            if not isShrinking and tempSize > 1 then tempSize = 1 end

                            local ratio = math.abs(tempSize - currentSize) / math.abs(1 - currentSize)
                            if not ratio or ratio ~= ratio then ratio = 1 end

                            seqStatusLabel.Text = string.format("add: 0.5, time: %.1f, left", pendingDelay)
                            applyPlayerOriginalSizes(ratio)
                            task.wait(pendingDelay)
                            if tempSize == 1 then break end
                        end
                    end
                    currentSize = 1
                else
                    local targetLimit = tonumber(targetLimitToken) or 5
                    if currentSize and targetLimit then
                        local tempSize = currentSize
                        local defaultStep = 0.5
                        local isShrinking = currentSize > targetLimit
                        while (isShrinking and tempSize > targetLimit) or (not isShrinking and tempSize < targetLimit) do
                            local left = math.abs(targetLimit - tempSize)
                            if left < defaultStep then
                                tempSize = targetLimit
                            else
                                tempSize = isShrinking and (tempSize - defaultStep) or (tempSize + defaultStep)
                            end

                            if isShrinking and tempSize < targetLimit then tempSize = targetLimit end
                            if not isShrinking and tempSize > targetLimit then tempSize = targetLimit end

                            seqStatusLabel.Text = string.format("add: 0.5, time: %.1f, left", pendingDelay)
                            applyToAllTargets(tempSize)
                            task.wait(pendingDelay)
                        end
                    end
                    currentSize = targetLimit
                end
                i = i + 1

            else
                local num = tonumber(t)
                if num then
                    if currentSize then
                        seqStatusLabel.Text = string.format("add: -, time: %.1f, waiting", pendingDelay)
                        task.wait(pendingDelay)
                    end
                    currentSize = num
                    applyToAllTargets(currentSize)
                    seqStatusLabel.Text = string.format("size: %.1f applied", currentSize)
                    pendingDelay = 0.5
                end
                i = i + 1
            end
        end

        task.wait(1)
        seqStatusLabel.Text = "ready"
        isExecutingSequence = false 
    end)
end

applyBtn.MouseButton1Click:Connect(function()
    if isExecutingSequence then return end
    local targets = {}
    for name, _ in pairs(selectedPlayers) do
        local p = Players:FindFirstChild(name)
        if p then table.insert(targets, p) end
    end
    if #targets > 0 then
        runScaleSequence(scaleBox.Text, targets, "Select")
    end
end)

allBtn.MouseButton1Click:Connect(function()
    if isExecutingSequence then return end
    runScaleSequence(scaleBox.Text, Players:GetPlayers(), "All")
end)

loopSelectedBtn.MouseButton1Click:Connect(function()
    loopSelected = not loopSelected
    loopSelectedBtn.Text = loopSelected and "LOOP 🟢" or "LOOP 🔴"
    if loopSelected then 
        loopEveryone = false
        loopEveryoneBtn.Text = "LOOP 🔴" 
    end
end)

loopEveryoneBtn.MouseButton1Click:Connect(function()
    loopEveryone = not loopEveryone
    loopEveryoneBtn.Text = loopEveryone and "LOOP 🟢" or "LOOP 🔴"
    if loopEveryone then 
        loopSelected = false
        loopSelectedBtn.Text = "LOOP 🔴" 
    end
end)

-- INDEPENDENT LOOP HEARTBEAT
RunService.Heartbeat:Connect(function()
    if not loopSelected and not loopEveryone then return end
    if os.clock() - lastLoopUpdate < LOOP_DELAY then return end
    lastLoopUpdate = os.clock()

    local val = tonumber(scaleBox.Text)
    if not val then return end

    local useId = _G.DetectedSizeID
    local remote = ReplicatedStorage:FindFirstChild("POST")

    if not useId or not remote then return end

    if loopSelected then
        for name, _ in pairs(selectedPlayers) do
            local p = Players:FindFirstChild(name)
            if p then
                for partName, enabled in pairs(selectedParts) do
                    if enabled then
                        pcall(function()
                            remote:FireServer(useId, "UpdateScale", p, partName, val * 100)
                        end)
                    end
                end
            end
        end
    elseif loopEveryone then
        for _, p in ipairs(Players:GetPlayers()) do
            for partName, enabled in pairs(selectedParts) do
                if enabled then
                    pcall(function()
                        remote:FireServer(useId, "UpdateScale", p, partName, val * 100)
                    end)
                end
            end
        end
    end
end)

espToggle.MouseButton1Click:Connect(function()
    espActive = not espActive
    espToggle.BackgroundColor3 = espActive and Color3.fromRGB(30, 120, 225) or Color3.fromRGB(0, 0, 0)
    for _, p in ipairs(Players:GetPlayers()) do updatePlayerESPVisual(p) end
end)

floatingBtn.MouseButton1Click:Connect(function()
    if frame.Visible then
        closeAllSequentially()
    else
        smoothOpen(frame)
    end
end)

minBtn.MouseButton1Click:Connect(function() 
    closeAllSequentially()
end)

searchBox:GetPropertyChangedSignal("Text"):Connect(updateList)

for _, p in ipairs(Players:GetPlayers()) do applyESP(p) end

Players.PlayerAdded:Connect(function(p) 
    applyESP(p)
    updateList() 
end)

Players.PlayerRemoving:Connect(function(p) 
    selectedPlayers[p.Name] = nil
    updateList() 
end)

updateList()
