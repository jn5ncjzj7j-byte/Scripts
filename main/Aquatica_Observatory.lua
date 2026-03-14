local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "misg Hub",
    SubTitle = "No Key",
    TabWidth = 160,
    Size = UDim2.fromOffset(480, 360),
    Acrylic = false,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.LeftControl
})

local Tabs = {
    Main = Window:AddTab({ Title = "Farming", Icon = "coffee" }),
    Settings = Window:AddTab({ Title = "Settings", Icon = "settings" })
}

local Options = Fluent.Options
local debrisFolder = workspace:WaitForChild("OceanDebris")
local player = game.Players.LocalPlayer
local originalPos = nil
local activeSpeed = 0.5

-- // 1. STABLE AUTO-SAVE FUNCTION //
local function forceSave()
    SaveManager:Save("autoload") -- This specifically targets the 'autoload.json'
end

-- // 2. SERVER HOP //
local function serverHop()
    local TeleportService = game:GetService("TeleportService")
    local HttpService = game:GetService("HttpService")
    Fluent:Notify({Title = "misg Hub", Content = "Server Empty! Hopping...", Duration = 3})
    task.wait(1)
    local Servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. game.PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
    for _, s in pairs(Servers.data) do
        if s.playing < s.maxPlayers and s.id ~= game.JobId then
            TeleportService:TeleportToPlaceInstance(game.PlaceId, s.id)
            break
        end
    end
end

-- // 3. MOBILE TOGGLE //
local ScreenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
ScreenGui.Name = "misgToggle"
ScreenGui.ResetOnSpawn = false
local ToggleButton = Instance.new("TextButton", ScreenGui)
ToggleButton.Size = UDim2.new(0, 60, 0, 60)
ToggleButton.Position = UDim2.new(0, 20, 0, 150)
ToggleButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ToggleButton.Text = "misg"
ToggleButton.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleButton.Draggable = true
ToggleButton.Active = true
Instance.new("UICorner", ToggleButton).CornerRadius = UDim.new(0, 15)
local ToggleImg = Instance.new("ImageLabel", ToggleButton)
ToggleImg.Size = UDim2.new(0.6, 0, 0.6, 0)
ToggleImg.Position = UDim2.new(0.2, 0, 0.2, 0)
ToggleImg.BackgroundTransparency = 1
ToggleImg.Visible = false
ToggleButton.MouseButton1Click:Connect(function() Window:Minimize() end)

-- // 4. FARMING LOOP //
task.spawn(function()
    while task.wait(0.5) do
        if Options.AutoFarm and Options.AFKFarm then -- Ensure options exist
            if Options.AutoFarm.Value or Options.AFKFarm.Value then
                local items = debrisFolder:GetChildren()
                activeSpeed = tonumber(Options.FarmSpeed.Value) or 0.5
                
                if #items > 0 then
                    if not originalPos then originalPos = player.Character:GetPivot() end
                    for _, item in pairs(items) do
                        if not (Options.AutoFarm.Value or Options.AFKFarm.Value) then break end
                        local char = player.Character
                        if char and char:FindFirstChild("HumanoidRootPart") then
                            char:PivotTo(item:GetPivot() * CFrame.new(0, 3, 0))
                            task.wait(activeSpeed)
                            for _, obj in pairs(item:GetDescendants()) do
                                if obj:IsA("ProximityPrompt") then fireproximityprompt(obj) end
                            end
                            task.wait(activeSpeed)
                        end
                    end
                elseif Options.AFKFarm.Value then
                    serverHop()
                end
            else
                if originalPos then
                    player.Character:PivotTo(originalPos)
                    originalPos = nil
                end
            end
        end
    end
end)

-- // 5. FARMING TAB //
Tabs.Main:AddSection("Auto Farm Controls")
Tabs.Main:AddToggle("AutoFarm", {Title = "Manual Auto-Farm", Default = false, Callback = forceSave})
Tabs.Main:AddToggle("AFKFarm", {Title = "AFK Farm (Auto-Hop)", Default = false, Callback = forceSave})

Tabs.Main:AddSection("Farm Settings")
Tabs.Main:AddInput("FarmSpeed", {
    Title = "Farm Speed", 
    Default = "0.5", 
    Numeric = true, 
    Callback = function() 
        activeSpeed = tonumber(Options.FarmSpeed.Value) or 0.5
        forceSave() 
    end
})

Tabs.Main:AddButton({
    Title = "Force Save Settings",
    Description = "Click this if auto-save is slow",
    Callback = function()
        forceSave()
        Fluent:Notify({Title = "Success", Content = "Manual Save Complete!", Duration = 2})
    end
})

-- // 6. SETTINGS TAB //
local CustomSection = Tabs.Settings:AddSection("Toggle Button Customization")
Tabs.Settings:AddInput("ToggleInput", {
    Title = "Text or Image ID",
    Default = "misg",
    Callback = function(Value)
        if tonumber(Value) then
            ToggleButton.Text = ""
            ToggleImg.Image = "rbxassetid://" .. Value
            ToggleImg.Visible = true
        else
            ToggleImg.Visible = false
            ToggleButton.Text = Value
        end
        forceSave()
    end
})

Tabs.Settings:AddColorpicker("TextCol", {Title = "Text Color", Default = Color3.fromRGB(255, 255, 255), Callback = function(v) ToggleButton.TextColor3 = v forceSave() end})
Tabs.Settings:AddColorpicker("BgCol", {Title = "Button Color", Default = Color3.fromRGB(30, 30, 30), Callback = function(v) ToggleButton.BackgroundColor3 = v forceSave() end})

-- // 7. THE CRITICAL SAVE/LOAD INITIALIZATION //
SaveManager:SetLibrary(Fluent)
SaveManager:SetFolder("misgHub_Data")
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({}) -- DO NOT IGNORE ANYTHING

-- This creates the config section logic hidden in the background
SaveManager:BuildConfigSection(Tabs.Settings) 

Window:SelectTab(1)

-- Final step: Load the config
SaveManager:LoadAutoloadConfig()

-- Sync the internal speed variable one last time after load
task.delay(1.5, function()
    if Options.FarmSpeed then
        activeSpeed = tonumber(Options.FarmSpeed.Value) or 0.5
    end
end)
