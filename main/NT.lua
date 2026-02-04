local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local POST = ReplicatedStorage:WaitForChild("POST")
local Camera = workspace.CurrentCamera

-- Cleanup existing
if PlayerGui:FindFirstChild("SizeEditorGUI") then PlayerGui.SizeEditorGUI:Destroy() end

local function styleElement(obj, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 6)
    corner.Parent = obj
end

-- ESP LOGIC (Updated to show real name)
local selectedPlayers = {} 
local espActive = true

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
        billboard.Size = UDim2.new(0, 180, 0, 40) -- Slightly larger for dual names
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.AlwaysOnTop = true
        billboard.Enabled = espActive
        billboard.Parent = char

        local label = Instance.new("TextLabel", billboard)
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        -- UPDATED: Shows Display Name and @Username
        label.Text = player.DisplayName .. "\n(@" .. player.Name .. ")"
        label.TextColor3 = Color3.new(1, 1, 1)
        label.Font = Enum.Font.GothamBold
        label.TextScaled = true 
        
        local tagPadding = Instance.new("UIPadding", label)
        tagPadding.PaddingTop = UDim.new(0, 2)
        tagPadding.PaddingBottom = UDim.new(0, 2)
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

local divider = Instance.new("Frame", toggleBar)
divider.Size = UDim2.new(0, 3, 0.7, 0)
divider.Position = UDim2.new(0.6, -1, 0.15, 0)
divider.BackgroundColor3 = Color3.new(1, 1, 1)
styleElement(divider, 2)

local espToggle = Instance.new("TextButton", toggleBar)
espToggle.Size = UDim2.new(0.4, 0, 1, 0)
espToggle.Position = UDim2.new(0.6, 0, 0, 0)
espToggle.BackgroundTransparency = 1
espToggle.Text = "ESP [X]"
espToggle.TextColor3 = Color3.new(1, 1, 1)
espToggle.Font = Enum.Font.GothamBold
espToggle.TextSize = 14

-- MAIN FRAME
local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 320, 0, 540)
frame.Position = UDim2.new(0.5, -160, 0.5, -270)
frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
frame.Active = true
styleElement(frame, 12)

local minBtn = Instance.new("TextButton", frame)
minBtn.Size = UDim2.new(0, 28, 0, 28)
minBtn.Position = UDim2.new(1, -38, 0, 10)
minBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 255)
minBtn.Text = "—"
minBtn.TextColor3 = Color3.new(1, 1, 1)
minBtn.Font = Enum.Font.GothamBold
styleElement(minBtn, 14)

-- DRAGGING LOGIC
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
sizeIdLabel.Position = UDim2.new(0, 10, 0, 50)
sizeIdLabel.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
sizeIdLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
sizeIdLabel.Text = "WAITING FOR ID..."
sizeIdLabel.Font = Enum.Font.Code
sizeIdLabel.TextScaled = true 
styleElement(sizeIdLabel, 8)
local idPadding = Instance.new("UIPadding", sizeIdLabel)
idPadding.PaddingLeft = UDim.new(0, 10)
idPadding.PaddingRight = UDim.new(0, 10)

-- ID SNIFFER
_G.DetectedSizeID = _G.DetectedSizeID or nil
local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
setreadonly(mt, false)

mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    if self == POST and args[2] == "UpdateScale" then
        local foundId = tostring(args[1])
        _G.DetectedSizeID = foundId
        if sizeIdLabel then
            sizeIdLabel.Text = "ID: FOUND (" .. foundId .. ")"
        end
    end
    return oldNamecall(self, ...)
end)
setreadonly(mt, true)

if _G.DetectedSizeID then 
    sizeIdLabel.Text = "ID: FOUND (" .. _G.DetectedSizeID .. ")" 
end

-- SEARCH BAR
local searchFrame = Instance.new("Frame", frame)
searchFrame.Size = UDim2.new(1, -20, 0, 45)
searchFrame.Position = UDim2.new(0, 10, 0, 100)
searchFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
styleElement(searchFrame, 8)

local searchBox = Instance.new("TextBox", searchFrame)
searchBox.Size = UDim2.new(1, -50, 1, 0)
searchBox.Position = UDim2.new(0, 15, 0, 0)
searchBox.BackgroundTransparency = 1
searchBox.PlaceholderText = "Search..."
searchBox.Text = ""
searchBox.TextColor3 = Color3.new(1,1,1)
searchBox.TextXAlignment = Enum.TextXAlignment.Left
searchBox.Font = Enum.Font.Gotham
searchBox.TextSize = 14

local clearX = Instance.new("TextButton", searchFrame)
clearX.Size = UDim2.new(0, 24, 0, 24)
clearX.Position = UDim2.new(1, -34, 0.5, -12)
clearX.BackgroundColor3 = Color3.new(1, 1, 1)
clearX.Text = "x"
clearX.TextColor3 = Color3.new(0, 0, 0)
clearX.Font = Enum.Font.GothamBold
clearX.TextSize = 14
clearX.Visible = false
styleElement(clearX, 12)

-- PLAYER LIST
local playerList = Instance.new("ScrollingFrame", frame)
playerList.Position = UDim2.new(0, 10, 0, 155)
playerList.Size = UDim2.new(1, -20, 0, 80)
playerList.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
playerList.BorderSizePixel = 0
playerList.ScrollBarThickness = 2
playerList.AutomaticCanvasSize = Enum.AutomaticSize.Y
local listLayout = Instance.new("UIListLayout", playerList)
listLayout.Padding = UDim.new(0, 4)

local function updateList()
    local filter = searchBox.Text:lower()
    clearX.Visible = (searchBox.Text ~= "")
    for _, child in pairs(playerList:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
    
    local pArray = Players:GetPlayers()
    table.sort(pArray, function(a, b)
        if a == LocalPlayer then return true end
        if b == LocalPlayer then return false end
        return a.Name:lower() < b.Name:lower()
    end)

    for _, player in ipairs(pArray) do
        local isMe = (player == LocalPlayer)
        if player.Name:lower():find(filter) or player.DisplayName:lower():find(filter) or (isMe and ("me"):find(filter)) then
            local btn = Instance.new("TextButton", playerList)
            btn.Size = UDim2.new(1, -10, 0, 30)
            btn.TextColor3 = Color3.new(1, 1, 1)
            btn.TextXAlignment = Enum.TextXAlignment.Left
            btn.TextScaled = true 
            
            local btnPadding = Instance.new("UIPadding", btn)
            btnPadding.PaddingLeft = UDim.new(0, 8)
            btnPadding.PaddingRight = UDim.new(0, 8)

            styleElement(btn, 4)
            
            if isMe then
                btn.Text = "ME"
                btn.Font = Enum.Font.GothamBold
                btn.BackgroundColor3 = selectedPlayers[player.Name] and Color3.fromRGB(200, 0, 0) or Color3.fromRGB(30, 60, 100)
                btn.LayoutOrder = -1
            else
                btn.Text = player.DisplayName .. " (@" .. player.Name .. ")"
                btn.Font = Enum.Font.Gotham
                btn.BackgroundColor3 = selectedPlayers[player.Name] and Color3.fromRGB(200, 0, 0) or Color3.fromRGB(45, 45, 45)
                btn.LayoutOrder = 0
            end
            
            btn.MouseButton1Click:Connect(function()
                selectedPlayers[player.Name] = not selectedPlayers[player.Name] or nil
                updateList()
                updatePlayerESPVisual(player) 
            end)
        end
    end
end

-- CONTROLS
local cancelBtn = Instance.new("TextButton", frame)
cancelBtn.Size = UDim2.new(1, -20, 0, 25)
cancelBtn.Position = UDim2.new(0, 10, 0, 245)
cancelBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
cancelBtn.Text = "DESELECT ALL"
cancelBtn.TextColor3 = Color3.new(1, 1, 1)
cancelBtn.Font = Enum.Font.GothamBold
cancelBtn.TextSize = 11
styleElement(cancelBtn, 4)

local bodyParts = {"Height", "Width", "Depth", "Head"}
local selectedParts = {Height = true, Width = true, Depth = true, Head = true}
local partsFrame = Instance.new("Frame", frame)
partsFrame.Size = UDim2.new(1, -20, 0, 80)
partsFrame.Position = UDim2.new(0, 10, 0, 280)
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
scaleBox.Position = UDim2.new(0, 10, 0, 370)
scaleBox.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
scaleBox.Text = "1"
scaleBox.TextColor3 = Color3.new(1,1,1)
styleElement(scaleBox)

local applyBtn = Instance.new("TextButton", frame)
applyBtn.Size = UDim2.new(1, -20, 0, 40)
applyBtn.Position = UDim2.new(0, 10, 0, 420)
applyBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 215)
applyBtn.Text = "APPLY TO SELECTED"
applyBtn.TextColor3 = Color3.new(1,1,1)
styleElement(applyBtn)

local allBtn = Instance.new("TextButton", frame)
allBtn.Size = UDim2.new(1, -20, 0, 40)
allBtn.Position = UDim2.new(0, 10, 0, 470)
allBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
allBtn.Text = "APPLY TO EVERYONE"
allBtn.TextColor3 = Color3.new(1,1,1)
styleElement(allBtn)

-- SCALE LOGIC
local function applySize(target, inputNum)
    local useId = _G.DetectedSizeID
    if not target or not useId then return end
    for part, enabled in pairs(selectedParts) do
        if enabled then 
            POST:FireServer(useId, "UpdateScale", target, part, inputNum * 100) 
        end
    end
    
    if target == LocalPlayer then
        local baseZoom = 128
        local multiplier = math.max(inputNum, 0.5)
        LocalPlayer.CameraMaxZoomDistance = baseZoom * multiplier
    end
end

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

cancelBtn.MouseButton1Click:Connect(function()
    selectedPlayers = {}
    for _, p in ipairs(Players:GetPlayers()) do updatePlayerESPVisual(p) end
    updateList()
end)

searchBox:GetPropertyChangedSignal("Text"):Connect(updateList)
clearX.MouseButton1Click:Connect(function() searchBox.Text = ""; updateList() end)

espToggle.MouseButton1Click:Connect(function()
    espActive = not espActive
    espToggle.Text = espActive and "ESP [X]" or "ESP [ ]"
    for _, p in ipairs(Players:GetPlayers()) do updatePlayerESPVisual(p) end
end)

mainToggle.MouseButton1Click:Connect(function()
    frame.Visible = not frame.Visible
    mainToggle.Text = frame.Visible and "CLOSE GUI" or "OPEN GUI"
end)

minBtn.MouseButton1Click:Connect(function()
    frame.Visible = false
    mainToggle.Text = "OPEN GUI"
end)

-- INITIALIZE
for _, p in ipairs(Players:GetPlayers()) do applyESP(p) end
Players.PlayerAdded:Connect(function(p) applyESP(p); updateList() end)
Players.PlayerRemoving:Connect(function(p) selectedPlayers[p.Name] = nil; updateList() end)
updateList()
