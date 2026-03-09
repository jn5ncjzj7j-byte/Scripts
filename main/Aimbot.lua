-- Services
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Configuration
local Settings = {
    ESP = true,
    Aimbot = true,
    TeamCheck = false,
    WallCheck = true,
    FullBright = true,
    ShowFOV = true,
    FOV = 150, -- Set to your default
    Language = "TH",
    Whitelist = {"khomggg", "7h3_W0r1d"}
}

-- Language Dictionary
local Lang = {
    EN = {
        Menu = "CLOSE GUI",
        MenuOpen = "OPEN GUI",
        ESP = "ESP",
        Aimbot = "Aimbot Head",
        Team = "Team Check",
        Wall = "Wall Check",
        Bright = "FullBright",
        FOV = "Show FOV",
        Lang = "Language: EN",
        WLPlace = "Add Whitelist Name...",
        FOVPlace = "FOV Size..."
    },
    TH = {
        Menu = "ปิดเมนู",
        MenuOpen = "เปิดเมนู",
        ESP = "เปิด ESP",
        Aimbot = "ล็อคหัว (Aimbot)",
        Team = "เช็คทีม",
        Wall = "เช็คกำแพง",
        Bright = "เปิดสว่าง",
        FOV = "แสดงวง FOV",
        Lang = "ภาษา: TH",
        WLPlace = "ใส่ชื่อที่ยกเว้น...",
        FOVPlace = "ขนาด FOV..."
    }
}

-- UI Setup
local ScreenGui = Instance.new("ScreenGui", game.CoreGui)
ScreenGui.Name = "StyledCheatGUI"
ScreenGui.ResetOnSpawn = false

local function styleElement(obj, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 6)
    corner.Parent = obj
end

-- TOGGLE BAR
local toggleBar = Instance.new("Frame", ScreenGui)
toggleBar.Size = UDim2.new(0, 160, 0, 45)
toggleBar.Position = UDim2.new(1, -180, 1, -70)
toggleBar.BackgroundColor3 = Color3.fromRGB(60, 120, 215)
toggleBar.Active = true
styleElement(toggleBar, 12)

local mainToggle = Instance.new("TextButton", toggleBar)
mainToggle.Size = UDim2.new(1, 0, 1, 0)
mainToggle.BackgroundTransparency = 1
mainToggle.Text = Lang[Settings.Language].Menu
mainToggle.TextColor3 = Color3.new(1, 1, 1)
mainToggle.Font = Enum.Font.GothamBold
mainToggle.TextSize = 14

-- MAIN FRAME
local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 280, 0, 600)
MainFrame.Position = UDim2.new(0.5, -140, 0.5, -300)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
MainFrame.Active = true
styleElement(MainFrame, 12)

-- TITLE BAR (FIXED: Title is now Misg Aimbot)
local titleBar = Instance.new("Frame", MainFrame)
titleBar.Size = UDim2.new(1, 0, 0, 40)
titleBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
styleElement(titleBar, 12)

local titleLabel = Instance.new("TextLabel", titleBar)
titleLabel.Size = UDim2.new(1, -50, 1, 0)
titleLabel.Position = UDim2.new(0, 15, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Misg Aimbot"
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

-- DRAGGING LOGIC (RESTORED)
local function makeDraggable(obj)
    local dragging, dragInput, dragStart, startPos
    obj.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = obj.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    obj.InputChanged:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            obj.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end
makeDraggable(MainFrame)
makeDraggable(toggleBar)

-- FIXED TEXTBOXES
local WLInput = Instance.new("TextBox", MainFrame)
WLInput.Size = UDim2.new(1, -30, 0, 40)
WLInput.Position = UDim2.new(0, 15, 0, 460)
WLInput.PlaceholderText = Lang.EN.WLPlace
WLInput.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
WLInput.TextColor3 = Color3.new(1, 1, 1)
WLInput.Font = Enum.Font.Gotham
styleElement(WLInput, 8)

WLInput.FocusLost:Connect(function(enter)
    if enter and WLInput.Text ~= "" then
        table.insert(Settings.Whitelist, WLInput.Text:lower())
        WLInput.Text = ""
    end
end)

local FOVInput = Instance.new("TextBox", MainFrame)
FOVInput.Size = UDim2.new(1, -30, 0, 40)
FOVInput.Position = UDim2.new(0, 15, 0, 510)
FOVInput.PlaceholderText = Lang.EN.FOVPlace
FOVInput.Text = "150"
FOVInput.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
FOVInput.TextColor3 = Color3.new(1, 1, 1)
FOVInput.Font = Enum.Font.Gotham
styleElement(FOVInput, 8)

FOVInput.FocusLost:Connect(function() Settings.FOV = tonumber(FOVInput.Text) or 150 end)

-- Wall Check Logic
local function IsVisible(part)
    if not Settings.WallCheck then return true end
    local castParams = RaycastParams.new()
    castParams.FilterDescendantsInstances = {LocalPlayer.Character, Camera}
    castParams.FilterType = Enum.RaycastFilterType.Exclude
    local result = workspace:Raycast(Camera.CFrame.Position, (part.Position - Camera.CFrame.Position).Unit * 5000, castParams)
    if result then return result.Instance:IsDescendantOf(part.Parent) end
    return true
end

-- FIXED ESP (Forced Loop for Players and NPCs)
local function ApplyESP(char, color, dist)
    local h = char:FindFirstChild("Highlight") or Instance.new("Highlight", char)
    h.Name = "Highlight"
    h.FillColor = color
    h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    h.Enabled = Settings.ESP
    
    local tag = char:FindFirstChild("CheatTag") or Instance.new("BillboardGui", char)
    if not tag:FindFirstChild("Label") then
        tag.Name = "CheatTag"; tag.AlwaysOnTop = true; tag.Size = UDim2.new(0,150,0,40); tag.StudsOffset = Vector3.new(0,3,0)
        local l = Instance.new("TextLabel", tag); l.Name = "Label"; l.BackgroundTransparency = 1; l.Size = UDim2.new(1,0,1,0); l.TextStrokeTransparency = 0; l.TextSize = 14; l.Font = Enum.Font.GothamBold
    end
    tag.Enabled = Settings.ESP
    tag.Label.Text = string.format("%s\n[%d m]", char.Name, math.floor(dist))
    tag.Label.TextColor3 = color
end

-- FOV Circle
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1.5; FOVCircle.Color = Color3.new(1,1,1); FOVCircle.Filled = false

-- Main Loop (RESTORED AIMBOT LOGIC)
RunService.RenderStepped:Connect(function()
    local center = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    FOVCircle.Position = center; FOVCircle.Radius = Settings.FOV
    FOVCircle.Visible = Settings.ShowFOV
    
    -- FIXED FULLBRIGHT
    if Settings.FullBright then
        Lighting.Brightness = 2
        Lighting.ClockTime = 14
        Lighting.GlobalShadows = false
        Lighting.OutdoorAmbient = Color3.new(1,1,1)
    end
    
    local lockTarget = nil
    local shortestDist = Settings.FOV

    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Humanoid") and v.Health > 0 and v.Parent:FindFirstChild("Head") then
            local char = v.Parent
            if char == LocalPlayer.Character then continue end
            
            local playerObj = Players:GetPlayerFromCharacter(char)
            local isNPC = playerObj == nil
            local dist = (char.Head.Position - Camera.CFrame.Position).Magnitude
            
            local isWL = false
            for _, name in pairs(Settings.Whitelist) do if char.Name:lower() == name:lower() then isWL = true end end
            
            local isTeam = Settings.TeamCheck and playerObj and LocalPlayer.Team and playerObj.Team == LocalPlayer.Team
            local visible = IsVisible(char.Head)
            
            -- Color Logic
            local color = Color3.fromRGB(255, 0, 0)
            if isWL or isTeam then color = Color3.fromRGB(0, 160, 255)
            elseif isNPC then color = visible and Color3.fromRGB(255, 140, 0) or Color3.fromRGB(255, 255, 0)
            elseif visible then color = Color3.fromRGB(0, 255, 0) end
            
            -- ESP (Forced check)
            if Settings.ESP then 
                ApplyESP(char, color, dist)
            else
                if char:FindFirstChild("Highlight") then char.Highlight.Enabled = false end
                if char:FindFirstChild("CheatTag") then char.CheatTag.Enabled = false end
            end
            
            -- ORIGINAL AIMBOT LOGIC
            if Settings.Aimbot and not isWL and not isTeam and visible then
                local screenPos, onScreen = Camera:WorldToViewportPoint(char.Head.Position)
                if onScreen then
                    local mag = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                    if mag < shortestDist then
                        shortestDist = mag
                        lockTarget = char.Head
                    end
                end
            end
        end
    end
    
    if lockTarget and Settings.Aimbot then
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, lockTarget.Position)
    end
end)

-- Button Creation
local Buttons = {}
local function NewBtn(id, nameKey, y, set)
    local b = Instance.new("TextButton", MainFrame)
    b.Size = UDim2.new(1, -30, 0, 40); b.Position = UDim2.new(0, 15, 0, y)
    b.BackgroundColor3 = Settings[set] and Color3.fromRGB(0, 120, 215) or Color3.fromRGB(45, 45, 45)
    b.TextColor3 = Color3.new(1, 1, 1); b.Font = Enum.Font.GothamBold; b.TextSize = 13
    styleElement(b, 6)
    
    local function updateText()
        b.Text = Lang[Settings.Language][nameKey] .. ": " .. (Settings[set] and "ON" or "OFF")
        b.BackgroundColor3 = Settings[set] and Color3.fromRGB(0, 120, 215) or Color3.fromRGB(45, 45, 45)
    end
    
    b.MouseButton1Click:Connect(function()
        Settings[set] = not Settings[set]
        updateText()
    end)
    Buttons[id] = {Update = updateText}
    updateText()
end

-- UI Refresh
local function RefreshUI()
    for _, item in pairs(Buttons) do item.Update() end
    mainToggle.Text = MainFrame.Visible and Lang[Settings.Language].Menu or Lang[Settings.Language].MenuOpen
    WLInput.PlaceholderText = Lang[Settings.Language].WLPlace
    FOVInput.PlaceholderText = Lang[Settings.Language].FOVPlace
end

NewBtn("ESP", "ESP", 60, "ESP")
NewBtn("Aimbot", "Aimbot", 110, "Aimbot")
NewBtn("Team", "Team", 160, "TeamCheck")
NewBtn("Wall", "Wall", 210, "WallCheck")
NewBtn("Bright", "Bright", 260, "FullBright")
NewBtn("FOV", "FOV", 310, "ShowFOV")

local LangBtn = Instance.new("TextButton", MainFrame)
LangBtn.Size = UDim2.new(1, -30, 0, 40); LangBtn.Position = UDim2.new(0, 15, 0, 360)
LangBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60); LangBtn.TextColor3 = Color3.new(1, 1, 1)
LangBtn.Font = Enum.Font.GothamBold; LangBtn.Text = Lang[Settings.Language].Lang
styleElement(LangBtn, 6)

LangBtn.MouseButton1Click:Connect(function()
    Settings.Language = (Settings.Language == "EN") and "TH" or "EN"
    LangBtn.Text = Lang[Settings.Language].Lang
    RefreshUI()
end)

mainToggle.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
    mainToggle.Text = MainFrame.Visible and Lang[Settings.Language].Menu or Lang[Settings.Language].MenuOpen
end)
minBtn.MouseButton1Click:Connect(function() MainFrame.Visible = false; mainToggle.Text = Lang[Settings.Language].MenuOpen end)

RefreshUI()
