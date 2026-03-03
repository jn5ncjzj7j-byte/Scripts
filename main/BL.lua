--// FULL INTEGRATED V24 - FIX FACING DIRECTION + STATIC DATA + CAMERA NOCLIP
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local liveFolder = workspace:WaitForChild("Live")
local npcFolder = workspace:FindFirstChild("Npcs") or workspace:FindFirstChild("NPCs")
local effectsFolder = workspace:FindFirstChild("Effects")

-- State
local farming, farmAll, autoQuest = false, false, false
local selectedDisplay = nil 
local searchNPC, searchCombat = "", ""

--// NPC DATA TABLE (พิกัดที่คุณให้มา)
local NpcData = {
    ["Rahaj"] = CFrame.new(1598.43, 875.81, 201.62),
    ["Rahaj (2)"] = CFrame.new(677.66, 896.98, -690.96),
    ["Rhett"] = CFrame.new(-193.86, 892.86, 38.64),
    ["Cultist Leader"] = CFrame.new(3089.69, 952.58, 1478.20),
    ["Kakyoin"] = CFrame.new(1077.60, 902.51, 805.22),
    ["Rhett (2)"] = CFrame.new(1312.40, 892.29, 460.66),
    ["Lowly Thief"] = CFrame.new(1582.58, 893.23, -392.28),
    ["Rhett (3)"] = CFrame.new(649.36, 908.98, 1178.71),
    ["Clinician"] = CFrame.new(784.96, 886.39, -580.04),
    ["Doctor"] = CFrame.new(-183.53, 918.76, -331.10),
    ["Yukako Yamagishi"] = CFrame.new(414.53, 949.74, 1745.12),
    ["Boxing Coach"] = CFrame.new(1118.21, 912.19, 10.56),
    ["Saitama"] = CFrame.new(1175.66, 876.74, -716.99),
    ["Hayato"] = CFrame.new(2223.42, 874.72, -144.08),
    ["Gang Contractor"] = CFrame.new(1453.57, 875.60, -675.69),
    ["Gupta"] = CFrame.new(1918.85, 884.93, 327.10),
    ["Gardner Gwen"] = CFrame.new(1801.53, 875.01, -123.53),
    ["Bruford"] = CFrame.new(1358.69, 923.92, 1928.65),
    ["Jean Pierre Polnareff"] = CFrame.new(1704.57, 933.15, 1362.47),
    ["Corrupt Police Officer"] = CFrame.new(1234.34, 875.60, -790.85),
    ["Kobayashi"] = CFrame.new(719.90, 894.56, -281.11),
    ["Reimi"] = CFrame.new(778.31, 887.00, -758.37),
    ["Banker"] = CFrame.new(1737.34, 874.77, 135.21),
    ["Tonio Trussardi"] = CFrame.new(1394.02, 876.28, -620.63),
    ["Kaiser"] = CFrame.new(1773.75, 874.80, -538.27),
    ["Yuto Horigome"] = CFrame.new(1096.80, 884.35, -57.50),
    ["Shigechi"] = CFrame.new(820.30, 884.80, -169.17),
    ["Aya Tsuji"] = CFrame.new(597.04, 886.39, -495.02),
    ["Nurse"] = CFrame.new(-214.91, 912.53, -440.69),
    ["Shadowy Figure"] = CFrame.new(2120.76, 930.45, 1932.66),
    ["Mafia Boss"] = CFrame.new(-1644.50, 891.59, 862.41),
    ["Rohan Kishibe"] = CFrame.new(2550.36, 874.53, -71.76),
    ["Jotaro Kujo"] = CFrame.new(1165.21, 884.24, 25.28),
    ["Invisible Baby"] = CFrame.new(869.60, 884.72, -347.71),
    ["Josuke Higashikata"] = CFrame.new(477.96, 886.42, -183.68),
    ["Okuyasu Nijimura"] = CFrame.new(2194.65, 874.66, -444.20),
    ["Gym Owner"] = CFrame.new(1113.11, 885.09, 148.02),
    ["Joseph Joestar"] = CFrame.new(1166.26, 869.82, -234.50),
    ["Yoshikage Kira"] = CFrame.new(1018.66, 875.77, -652.42),
    ["Caesar Zeppeli"] = CFrame.new(993.26, 869.70, -241.37),
    ["Karate Sensei"] = CFrame.new(537.53, 886.29, -260.12),
    ["Muhammad Avdol"] = CFrame.new(329.59, 876.08, 1024.92),
    ["potat"] = CFrame.new(1076.00, 166329.55, -98.05)
}

if PlayerGui:FindFirstChild("MisgHubNPC") then PlayerGui.MisgHubNPC:Destroy() end

local function styleElement(obj, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 6)
    corner.Parent = obj
end

-- CAMERA NOCLIP (ALWAYS ON)
RunService:BindToRenderStep("CameraNoclip", 201, function()
    LocalPlayer.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam
    LocalPlayer.CameraMinZoomDistance = 0.5
end)

-- STAND LOGIC
local function isStandOut()
    if not effectsFolder then return false end
    for _, v in pairs(effectsFolder:GetChildren()) do
        if v.Name:find(LocalPlayer.Name) and v.Name:find("Stand") then return true end
    end
    return false
end

local function summonStand()
    local char = LocalPlayer.Character
    local remote = char and char:FindFirstChild("client_character_controller") and char.client_character_controller:FindFirstChild("SummonStand")
    if remote then remote:FireServer() end
end

-- DRAGGING
local function makeDraggable(gui)
    local dragging, dragInput, dragStart, startPos
    gui.InputBegan:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
            dragging = true; dragStart = input.Position; startPos = gui.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    gui.InputChanged:Connect(function(input) if (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then dragInput = input end end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            gui.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

--------------------------------------------------
-- GUI
--------------------------------------------------
local gui = Instance.new("ScreenGui", PlayerGui); gui.Name = "MisgHubNPC"; gui.ResetOnSpawn = false
local toggleBar = Instance.new("Frame", gui); toggleBar.Size = UDim2.new(0, 210, 0, 45); toggleBar.Position = UDim2.new(1, -230, 1, -70); toggleBar.BackgroundColor3 = Color3.fromRGB(60, 120, 215); toggleBar.Active = true; styleElement(toggleBar, 12); makeDraggable(toggleBar)
local mainToggle = Instance.new("TextButton", toggleBar); mainToggle.Size = UDim2.new(1, 0, 1, 0); mainToggle.BackgroundTransparency = 1; mainToggle.Text = "CLOSE GUI"; mainToggle.TextColor3 = Color3.new(1, 1, 1); mainToggle.Font = Enum.Font.GothamBold; mainToggle.TextSize = 14

local frame = Instance.new("Frame", gui); frame.Size = UDim2.new(0, 320, 0, 540); frame.Position = UDim2.new(0.5, -160, 0.5, -270); frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20); frame.Active = true; styleElement(frame, 12); makeDraggable(frame)
local titleBar = Instance.new("Frame", frame); titleBar.Size = UDim2.new(1,0,0,40); titleBar.BackgroundColor3 = Color3.fromRGB(30,30,30); styleElement(titleBar, 12)
local titleL = Instance.new("TextLabel", titleBar); titleL.Size = UDim2.new(1,0,1,0); titleL.BackgroundTransparency = 1; titleL.Text = "Misg Hub"; titleL.TextColor3 = Color3.new(1,1,1); titleL.Font = Enum.Font.GothamBold; titleL.TextSize = 16

local qSearch = Instance.new("TextBox", frame); qSearch.Size = UDim2.new(1, -20, 0, 30); qSearch.Position = UDim2.new(0, 10, 0, 50); qSearch.BackgroundColor3 = Color3.fromRGB(35, 35, 35); qSearch.PlaceholderText = "Search Quest NPCs..."; qSearch.Text = ""; qSearch.TextColor3 = Color3.new(1,1,1); styleElement(qSearch, 8)
local tpList = Instance.new("ScrollingFrame", frame); tpList.Position = UDim2.new(0,10,0,85); tpList.Size = UDim2.new(1,-20,0,90); tpList.BackgroundColor3 = Color3.fromRGB(25, 25, 25); styleElement(tpList, 8); Instance.new("UIListLayout", tpList).Padding = UDim.new(0,4)

local cSearch = Instance.new("TextBox", frame); cSearch.Size = UDim2.new(1, -20, 0, 30); cSearch.Position = UDim2.new(0, 10, 0, 185); cSearch.BackgroundColor3 = Color3.fromRGB(35, 35, 35); cSearch.PlaceholderText = "Search Enemies..."; cSearch.Text = ""; cSearch.TextColor3 = Color3.new(1,1,1); styleElement(cSearch, 8)
local combatList = Instance.new("ScrollingFrame", frame); combatList.Position = UDim2.new(0,10,0,220); combatList.Size = UDim2.new(1,-20,0,90); combatList.BackgroundColor3 = Color3.fromRGB(25, 25, 25); styleElement(combatList, 8); Instance.new("UIListLayout", combatList).Padding = UDim.new(0,4)

local function createBtn(text, pos, color)
    local b = Instance.new("TextButton", frame); b.Size = UDim2.new(1,-20,0,40); b.Position = pos; b.BackgroundColor3 = color; b.Text = text; b.TextColor3 = Color3.new(1,1,1); b.Font = Enum.Font.GothamBold; styleElement(b, 8)
    return b
end
local qBtn = createBtn("AUTO QUEST: OFF", UDim2.new(0,10,0,330), Color3.fromRGB(80,20,20))
local fBtn = createBtn("FARM SELECTED: OFF", UDim2.new(0,10,0,380), Color3.fromRGB(50, 50, 50))
local aBtn = createBtn("FARM ALL: OFF", UDim2.new(0,10,0,430), Color3.fromRGB(20, 60, 20))

--------------------------------------------------
-- MASTER LIST REFRESH
--------------------------------------------------
function refresh()
    for _, v in pairs(tpList:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
    for name, cf in pairs(NpcData) do
        local labelName = name .. " [Quest]"
        if labelName:lower():find(searchNPC:lower()) then
            local b = Instance.new("TextButton", tpList); b.Size = UDim2.new(1, -8, 0, 28); b.BackgroundColor3 = Color3.fromRGB(45, 45, 45); b.TextColor3 = Color3.new(1,1,1); b.Text = labelName; b.Font = Enum.Font.Gotham; styleElement(b, 4)
            b.MouseButton1Click:Connect(function() LocalPlayer.Character.HumanoidRootPart.CFrame = cf * CFrame.new(0,0,3) end)
        end
    end

    for _, v in pairs(combatList:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
    local combatNames = {}
    for _, obj in pairs(liveFolder:GetChildren()) do
        if obj:FindFirstChild("HumanoidRootPart") and not Players:GetPlayerFromCharacter(obj) then
            local h = obj:FindFirstChild("Humanoid"); local dName = (h and h.DisplayName ~= "") and h.DisplayName or obj.Name
            if dName:lower():find(searchCombat:lower()) then combatNames[dName] = true end
        end
    end
    for name, _ in pairs(combatNames) do
        local b = Instance.new("TextButton", combatList); b.Size = UDim2.new(1, -8, 0, 28); b.Text = name; b.TextColor3 = Color3.new(1,1,1); b.Font = Enum.Font.Gotham
        b.BackgroundColor3 = (selectedDisplay == name) and Color3.fromRGB(60, 120, 215) or Color3.fromRGB(45, 45, 45); styleElement(b, 4)
        b.MouseButton1Click:Connect(function() selectedDisplay = name; refresh() end)
    end
end

--------------------------------------------------
-- FARM ENGINE (FACING FIX)
--------------------------------------------------
local function reset()
    farming, farmAll, autoQuest = false, false, false
    qBtn.Text = "AUTO QUEST: OFF"; qBtn.BackgroundColor3 = Color3.fromRGB(80, 20, 20)
    fBtn.Text = "FARM SELECTED: OFF"; fBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    aBtn.Text = "FARM ALL: OFF"; aBtn.BackgroundColor3 = Color3.fromRGB(20, 60, 20)
    if isStandOut() then summonStand() end
    if LocalPlayer.Character then
        for _, v in pairs(LocalPlayer.Character:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = true end end
        LocalPlayer.Character.Humanoid.AutoRotate = true
    end
end

qBtn.MouseButton1Click:Connect(function() local s = not autoQuest; reset(); if s then autoQuest = true; qBtn.Text = "AUTO QUEST: ON"; qBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 215) end end)
fBtn.MouseButton1Click:Connect(function() local s = not farming; reset(); if s then farming = true; fBtn.Text = "FARM SELECTED: ON"; fBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 215) end end)
aBtn.MouseButton1Click:Connect(function() local s = not farmAll; reset(); if s then farmAll = true; aBtn.Text = "FARM ALL: ON"; aBtn.BackgroundColor3 = Color3.fromRGB(60, 120, 215) end end)
mainToggle.MouseButton1Click:Connect(function() frame.Visible = not frame.Visible; mainToggle.Text = frame.Visible and "CLOSE GUI" or "OPEN GUI" end)

task.spawn(function()
    while task.wait(1.5) do
        if (farming or farmAll or autoQuest) and not isStandOut() then summonStand() end
    end
end)

RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character; local hrp = char and char:FindFirstChild("HumanoidRootPart"); local hum = char and char:FindFirstChild("Humanoid")
    if not (hrp and hum and (farming or farmAll or autoQuest)) then return end

    local targetName = ""
    if autoQuest then
        pcall(function()
            local taskUI = PlayerGui.menu.task_holder.holder.newobjective.ScrollingFrame.holder:FindFirstChildOfClass("Frame")
            if taskUI then
                local raw = taskUI.TextLabel.Text:lower()
                if raw:find("talk to") then
                    local n = (raw:gsub("talk to:", ""):gsub("talk to", "")):match("^%s*(.-)%s*$")
                    for name, cf in pairs(NpcData) do
                        if name:lower():find(n) then hrp.CFrame = cf * CFrame.new(0,0,3); break end
                    end
                else targetName = (raw:gsub("defeat", "")):match("^%s*(.-)%s*$") end
            end
        end)
    end
    if farming and targetName == "" then targetName = (selectedDisplay or ""):lower() end

    if targetName ~= "" or farmAll then
        local target = nil; local dist = math.huge
        for _, v in pairs(liveFolder:GetChildren()) do
            if v:IsA("Model") and not Players:GetPlayerFromCharacter(v) then
                local h = v:FindFirstChild("Humanoid"); local r = v:FindFirstChild("HumanoidRootPart")
                if r and (not h or h.Health > 0) then
                    local dName = ((h and h.DisplayName ~= "") and h.DisplayName or v.Name):lower()
                    if farmAll or dName:find(targetName) then
                        local d = (r.Position - hrp.Position).Magnitude
                        if d < dist then target = v; dist = d end
                    end
                end
            end
        end
        if target then
            hum.AutoRotate = false; hrp.Velocity = Vector3.zero
            -- [[ FIX: ตัวละครอยู่ข้างล่าง และหันหน้าขึ้นไปหาเป้าหมาย ]]
            local targetPos = target.HumanoidRootPart.Position
            local standPos = targetPos + Vector3.new(0, -7, 0)
            hrp.CFrame = CFrame.lookAt(standPos, targetPos)
            
            local m1 = char:FindFirstChild("client_character_controller") and char.client_character_controller:FindFirstChild("M1")
            if m1 then m1:FireServer(true, true) end
        end
    end
end)

RunService.Stepped:Connect(function()
    if (farming or farmAll or autoQuest) and LocalPlayer.Character then
        for _, v in pairs(LocalPlayer.Character:GetDescendants()) do if v:IsA("BasePart") then v.CanCollide = false end end
    end
end)

qSearch:GetPropertyChangedSignal("Text"):Connect(function() searchNPC = qSearch.Text; refresh() end)
cSearch:GetPropertyChangedSignal("Text"):Connect(function() searchCombat = cSearch.Text; refresh() end)
task.spawn(function() while task.wait(5) do refresh() end end); refresh()
