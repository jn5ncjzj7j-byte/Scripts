local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local POST = ReplicatedStorage:WaitForChild("POST")

-- Cleanup existing
if PlayerGui:FindFirstChild("SizeEditorGUI") then PlayerGui.SizeEditorGUI:Destroy() end

local function styleElement(obj, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 6)
    corner.Parent = obj
end

-- VARIABLES
local selectedPlayers = {} 
local espActive = false 
local loopSelected = false
local loopEveryone = false
local lastLoopUpdate = 0
local LOOP_DELAY = 0.2 

-- ESP LOGIC
local function getESPColor(player)
    return selectedPlayers[player.Name] and Color3.fromRGB(255, 0, 0) or Color3.fromRGB(0, 255, 255)
end

local function updatePlayerESPVisual(player)
    if player and player.Character then
        local highlight = player.Character:FindFirstChild("ESPHighlight")
        if highlight then
            highlight.FillColor = getESPColor(player)
            highlight.Enabled = espActive
        end
        local tag = player.Character:FindFirstChild("ESPNameTag")
        if tag then tag.Enabled = espActive end
    end
end

local function applyESP(player)
    if player == LocalPlayer then return end
    local function setupCharacter(char)
        local highlight = Instance.new("Highlight")
        highlight.Name = "ESPHighlight"
        highlight.FillColor = getESPColor(player)
        highlight.FillTransparency = 0.5
        highlight.OutlineColor = Color3.new(1, 1, 1)
        highlight.Enabled = espActive 
        highlight.Parent = char

        local billboard = Instance.new("BillboardGui")
        billboard.Name = "ESPNameTag"
        billboard.Size = UDim2.new(0, 180, 0, 40)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.AlwaysOnTop = true
        billboard.Enabled = espActive 
        billboard.Parent = char

        local label = Instance.new("TextLabel", billboard)
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.Text = player.DisplayName .. "\n(@" .. player.Name .. ")"
        label.TextColor3 = Color3.new(1, 1, 1)
        label.Font = Enum.Font.GothamBold
        label.TextScaled = true 
    end
    if player.Character then setupCharacter(player.Character) end
    player.CharacterAdded:Connect(setupCharacter)
end

-- MAIN GUI
local gui = Instance.new("ScreenGui", PlayerGui)
gui.Name = "SizeEditorGUI"
gui.ResetOnSpawn = false

-- TOGGLE BAR
local toggleBar = Instance.new("Frame", gui)
toggleBar.Size = UDim2.new(0, 210, 0, 45)
toggleBar.Position = UDim2.new(1, -230, 1, -70)
toggleBar.BackgroundColor3 = Color3.fromRGB(60, 120, 215)
toggleBar.Active = true
styleElement(toggleBar, 12)

local mainToggle = Instance.new("TextButton", toggleBar)
mainToggle.Size = UDim2.new(0.6, 0, 1, 0)
mainToggle.BackgroundTransparency = 1
mainToggle.Text = "CLOSE GUI"
mainToggle.TextColor3 = Color3.new(1, 1, 1)
mainToggle.Font = Enum.Font.GothamBold
mainToggle.TextSize = 14

local dividerBar = Instance.new("Frame", toggleBar)
dividerBar.Size = UDim2.new(0, 3, 0.7, 0)
dividerBar.Position = UDim2.new(0.6, -1, 0.15, 0)
dividerBar.BackgroundColor3 = Color3.new(1, 1, 1)
styleElement(dividerBar, 2)

local espToggle = Instance.new("TextButton", toggleBar)
espToggle.Size = UDim2.new(0.4, 0, 1, 0)
espToggle.Position = UDim2.new(0.6, 0, 0, 0)
espToggle.BackgroundTransparency = 1
espToggle.Text = "ESP [ ]" 
espToggle.TextColor3 = Color3.new(1, 1, 1)
espToggle.Font = Enum.Font.GothamBold
espToggle.TextSize = 14

-- MAIN FRAME
local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 320, 0, 560)
frame.Position = UDim2.new(0.5, -160, 0.5, -280)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
frame.Active = true
styleElement(frame, 12)

local titleBar = Instance.new("Frame", frame)
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
styleElement(titleBar, 12)

local titleLabel = Instance.new("TextLabel", titleBar)
titleLabel.Size = UDim2.new(1, -50, 1, 0)
titleLabel.Position = UDim2.new(0, 15, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Misg Hub"
titleLabel.TextColor3 = Color3.new(1, 1, 1)
titleLabel.Font = Enum.Font.GothamBold
titleLabel.TextSize = 18
titleLabel.TextXAlignment = Enum.TextXAlignment.Left

local minBtn = Instance.new("TextButton", titleBar)
minBtn.Size = UDim2.new(0, 28, 0, 28)
minBtn.Position = UDim2.new(1, -34, 0.5, -14)
minBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
minBtn.Text = "X"
minBtn.TextColor3 = Color3.new(1, 1, 1)
minBtn.Font = Enum.Font.GothamBold
styleElement(minBtn, 6)

-- DRAGGING
local function makeDraggable(obj)
    local dragging, dragInput, dragStart, startPos
    obj.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = obj.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    obj.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            obj.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end
makeDraggable(frame)
makeDraggable(toggleBar)

-- ID DISPLAY
local sizeIdLabel = Instance.new("TextLabel", frame)
sizeIdLabel.Size = UDim2.new(1, -20, 0, 40)
sizeIdLabel.Position = UDim2.new(0, 10, 0, 55)
sizeIdLabel.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
sizeIdLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
sizeIdLabel.Text = "WAITING FOR ID..."
sizeIdLabel.Font = Enum.Font.Code
sizeIdLabel.TextScaled = true 
styleElement(sizeIdLabel, 8)

-- SNIFFER
_G.DetectedSizeID = _G.DetectedSizeID or nil
local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
setreadonly(mt, false)

mt.__namecall = newcclosure(function(self, ...)
    local args = {...}
    if self == POST and args[2] == "UpdateScale" then
        _G.DetectedSizeID = tostring(args[1])
        if sizeIdLabel then sizeIdLabel.Text = "ID: FOUND (" .. _G.DetectedSizeID .. ")" end
    end
    return oldNamecall(self, ...)
end)
setreadonly(mt, true)

-- SEARCH BAR
local searchFrame = Instance.new("Frame", frame)
searchFrame.Size = UDim2.new(1, -20, 0, 45)
searchFrame.Position = UDim2.new(0, 10, 0, 105)
searchFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
styleElement(searchFrame, 8)

local searchBox = Instance.new("TextBox", searchFrame)
searchBox.Size = UDim2.new(1, -15, 1, 0)
searchBox.Position = UDim2.new(0, 10, 0, 0)
searchBox.BackgroundTransparency = 1
searchBox.PlaceholderText = "Search players..."
searchBox.Text = ""
searchBox.TextColor3 = Color3.new(1,1,1)
searchBox.TextXAlignment = Enum.TextXAlignment.Left
searchBox.Font = Enum.Font.Gotham
searchBox.TextSize = 14

-- PLAYER LIST (FIXED)
local playerList = Instance.new("ScrollingFrame", frame)
playerList.Position = UDim2.new(0, 10, 0, 160)
playerList.Size = UDim2.new(1, -20, 0, 80)
playerList.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
playerList.BorderSizePixel = 0
playerList.ScrollBarThickness = 2
playerList.AutomaticCanvasSize = Enum.AutomaticSize.Y
local listLayout = Instance.new("UIListLayout", playerList)
listLayout.Padding = UDim.new(0, 4)

local function updateList()
    local filter = searchBox.Text:lower()
    
    -- Clear current list items
    for _, child in pairs(playerList:GetChildren()) do 
        if child:IsA("TextButton") then child:Destroy() end 
    end
    
    local players = Players:GetPlayers()
    
    -- Sorting logic: YOU first, then alphabetical
    table.sort(players, function(a, b)
        if a == LocalPlayer then return true end
        if b == LocalPlayer then return false end
        return a.DisplayName:lower() < b.DisplayName:lower()
    end)

    for _, player in ipairs(players) do
        local isMe = (player == LocalPlayer)
        local displayName = isMe and "YOU" or (player.DisplayName .. " (@" .. player.Name .. ")")
        
        -- Filter logic
        if displayName:lower():find(filter) or player.Name:lower():find(filter) then
            local btn = Instance.new("TextButton", playerList)
            btn.Size = UDim2.new(1, -8, 0, 30)
            btn.Text = displayName
            btn.TextColor3 = Color3.new(1, 1, 1)
            btn.Font = isMe and Enum.Font.GothamBold or Enum.Font.Gotham
            btn.TextSize = 13
            
            -- Visual feedback for selection
            local isSelected = selectedPlayers[player.Name]
            if isSelected then
                btn.BackgroundColor3 = Color3.fromRGB(200, 50, 50) -- Red for selected
            elseif isMe then
                btn.BackgroundColor3 = Color3.fromRGB(40, 70, 110) -- Blue for self
            else
                btn.BackgroundColor3 = Color3.fromRGB(45, 45, 45) -- Gray for others
            end
            
            styleElement(btn, 4)
            
            btn.MouseButton1Click:Connect(function()
                if selectedPlayers[player.Name] then
                    selectedPlayers[player.Name] = nil
                else
                    selectedPlayers[player.Name] = true
                end
                updateList()
                updatePlayerESPVisual(player) 
            end)
        end
    end
end

-- CONTROLS
local cancelBtn = Instance.new("TextButton", frame)
cancelBtn.Size = UDim2.new(1, -20, 0, 25)
cancelBtn.Position = UDim2.new(0, 10, 0, 250)
cancelBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
cancelBtn.Text = "DESELECT ALL"
cancelBtn.TextColor3 = Color3.new(1, 1, 1)
cancelBtn.Font = Enum.Font.GothamBold
styleElement(cancelBtn, 4)

local bodyParts = {"Height", "Width", "Depth", "Head"}
local selectedParts = {Height = true, Width = true, Depth = true, Head = true}
local partsFrame = Instance.new("Frame", frame)
partsFrame.Size = UDim2.new(1, -20, 0, 80)
partsFrame.Position = UDim2.new(0, 10, 0, 285)
partsFrame.BackgroundTransparency = 1
local grid = Instance.new("UIGridLayout", partsFrame)
grid.CellSize = UDim2.new(0.48, 0, 0, 35)

for _, part in ipairs(bodyParts) do
    local cb = Instance.new("TextButton", partsFrame)
    cb.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
    cb.Text = part
    cb.TextColor3 = Color3.new(1, 1, 1)
    styleElement(cb, 4)
    cb.MouseButton1Click:Connect(function()
        selectedParts[part] = not selectedParts[part]
        cb.BackgroundColor3 = selectedParts[part] and Color3.fromRGB(0, 120, 215) or Color3.fromRGB(60, 60, 60)
    end)
end

local scaleBox = Instance.new("TextBox", frame)
scaleBox.Size = UDim2.new(1, -20, 0, 40)
scaleBox.Position = UDim2.new(0, 10, 0, 380)
scaleBox.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
scaleBox.Text = "1"
scaleBox.TextColor3 = Color3.new(1,1,1)
styleElement(scaleBox)

-- APPLY & LOOP BUTTONS
local function createLoopButton(parent, pos)
    local container = Instance.new("Frame", parent)
    container.Size = UDim2.new(0, 70, 0, 40)
    container.Position = pos
    container.BackgroundTransparency = 1

    local div = Instance.new("Frame", container)
    div.Size = UDim2.new(0, 2, 0.6, 0)
    div.Position = UDim2.new(0, 5, 0.2, 0)
    div.BackgroundColor3 = Color3.new(1, 1, 1)
    div.BorderSizePixel = 0

    local btn = Instance.new("TextButton", container)
    btn.Size = UDim2.new(1, -10, 1, 0)
    btn.Position = UDim2.new(0, 10, 0, 0)
    btn.BackgroundTransparency = 1
    btn.Text = "🔄 ⬜"
    btn.TextColor3 = Color3.new(1, 1, 1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 16
    return btn
end

local applyBtn = Instance.new("TextButton", frame)
applyBtn.Size = UDim2.new(1, -100, 0, 40)
applyBtn.Position = UDim2.new(0, 10, 0, 430)
applyBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
applyBtn.Text = "APPLY TO SELECTED"
applyBtn.TextColor3 = Color3.new(1,1,1)
styleElement(applyBtn)

local loopSelectedBtn = createLoopButton(frame, UDim2.new(1, -80, 0, 430))

local allBtn = Instance.new("TextButton", frame)
allBtn.Size = UDim2.new(1, -100, 0, 40)
allBtn.Position = UDim2.new(0, 10, 0, 480)
allBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
allBtn.Text = "APPLY TO EVERYONE"
allBtn.TextColor3 = Color3.new(1,1,1)
styleElement(allBtn)

local loopEveryoneBtn = createLoopButton(frame, UDim2.new(1, -80, 0, 480))

-- SCALE LOGIC
local function applySize(target, inputNum)
    local useId = _G.DetectedSizeID
    if not target or not useId then return end
    for part, enabled in pairs(selectedParts) do
        if enabled then 
            POST:FireServer(useId, "UpdateScale", target, part, inputNum * 100) 
        end
    end
end

-- BUTTON EVENTS
applyBtn.MouseButton1Click:Connect(function()
    local val = tonumber(scaleBox.Text) or 1
    for name, _ in pairs(selectedPlayers) do
        local p = Players:FindFirstChild(name)
        if p then applySize(p, val) end
    end
end)

allBtn.MouseButton1Click:Connect(function()
    local val = tonumber(scaleBox.Text) or 1
    for _, p in ipairs(Players:GetPlayers()) do applySize(p, val) end
end)

loopSelectedBtn.MouseButton1Click:Connect(function()
    loopSelected = not loopSelected
    loopSelectedBtn.Text = loopSelected and "🔄 ✅" or "🔄 ⬜"
    if loopSelected then loopEveryone = false; loopEveryoneBtn.Text = "🔄 ⬜" end
end)

loopEveryoneBtn.MouseButton1Click:Connect(function()
    loopEveryone = not loopEveryone
    loopEveryoneBtn.Text = loopEveryone and "🔄 ✅" or "🔄 ⬜"
    if loopEveryone then loopSelected = false; loopSelectedBtn.Text = "🔄 ⬜" end
end)

-- DELAYED HEARTBEAT LOOP
RunService.Heartbeat:Connect(function()
    if tick() - lastLoopUpdate < LOOP_DELAY then return end
    lastLoopUpdate = tick()

    local val = tonumber(scaleBox.Text) or 1
    if loopSelected then
        for name, _ in pairs(selectedPlayers) do
            local p = Players:FindFirstChild(name)
            if p then applySize(p, val) end
        end
    elseif loopEveryone then
        for _, p in ipairs(Players:GetPlayers()) do
            applySize(p, val)
        end
    end
end)

-- WRAP UP
cancelBtn.MouseButton1Click:Connect(function()
    selectedPlayers = {}
    for _, p in ipairs(Players:GetPlayers()) do updatePlayerESPVisual(p) end
    updateList()
end)

espToggle.MouseButton1Click:Connect(function()
    espActive = not espActive
    espToggle.Text = espActive and "ESP [X]" or "ESP [ ]"
    for _, p in ipairs(Players:GetPlayers()) do updatePlayerESPVisual(p) end
end)

mainToggle.MouseButton1Click:Connect(function()
    frame.Visible = not frame.Visible
    mainToggle.Text = frame.Visible and "CLOSE GUI" or "OPEN GUI"
end)

searchBox:GetPropertyChangedSignal("Text"):Connect(updateList)
minBtn.MouseButton1Click:Connect(function() frame.Visible = false; mainToggle.Text = "OPEN GUI" end)

for _, p in ipairs(Players:GetPlayers()) do applyESP(p) end
Players.PlayerAdded:Connect(function(p) applyESP(p); updateList() end)
Players.PlayerRemoving:Connect(function(p) selectedPlayers[p.Name] = nil; updateList() end)
updateList()
