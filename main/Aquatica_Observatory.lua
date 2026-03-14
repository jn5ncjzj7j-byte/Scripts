local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "misg Hub",
    SubTitle = "Ocean Money Farm",
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

-- 1. MOBILE TOGGLE
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
ToggleButton.MouseButton1Click:Connect(function() Window:Minimize() end)

-- 2. SERVER HOP LOGIC
local function serverHop()
    local TeleportService = game:GetService("TeleportService")
    local HttpService = game:GetService("HttpService")
    local PlaceId = game.PlaceId
    
    Fluent:Notify({Title = "misg Hub", Content = "Ocean empty! Hopping server...", Duration = 3})
    task.wait(1)
    
    local Servers = HttpService:JSONDecode(game:HttpGet("https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Asc&limit=100"))
    for _, s in pairs(Servers.data) do
        if s.playing < s.maxPlayers and s.id ~= game.JobId then
            TeleportService:TeleportToPlaceInstance(PlaceId, s.id)
            break
        end
    end
end

-- 3. ANTI-AFK
local VirtualUser = game:GetService("VirtualUser")
player.Idled:Connect(function()
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

-- 4. FARMING LOGIC
task.spawn(function()
    while task.wait(0.1) do
        local isFarming = Options.AutoFarm.Value or Options.AFKFarm.Value
        
        if isFarming then
            local items = debrisFolder:GetChildren()
            
            if #items > 0 then
                if not originalPos then originalPos = player.Character:GetPivot() end

                for _, item in pairs(items) do
                    if not (Options.AutoFarm.Value or Options.AFKFarm.Value) then break end
                    local char = player.Character
                    if char and char:FindFirstChild("HumanoidRootPart") then
                        -- Get the speed from the slider
                        local speedDelay = Options.FarmSpeed.Value
                        
                        char:PivotTo(item:GetPivot() * CFrame.new(0, 3, 0))
                        task.wait(speedDelay * 0.6) -- Wait to land based on speed
                        
                        for _, obj in pairs(item:GetDescendants()) do
                            if obj:IsA("ProximityPrompt") then fireproximityprompt(obj) end
                        end
                        
                        task.wait(speedDelay * 0.4) -- Wait before moving to next item
                    end
                end
            elseif Options.AFKFarm.Value then
                serverHop()
                task.wait(10)
            end
        else
            if originalPos then
                player.Character:PivotTo(originalPos)
                originalPos = nil
                Fluent:Notify({Title = "misg Hub", Content = "Returned to start position.", Duration = 2})
            end
        end
    end
end)

-- 5. BUTTONS & SETTINGS UI
Tabs.Main:AddSection("Farming Toggles")

Tabs.Main:AddToggle("AutoFarm", {
    Title = "Manual Auto-Farm", 
    Description = "Farms items and returns to your position.", 
    Default = false,
    Callback = function() SaveManager:Save("autoload") end
})

Tabs.Main:AddToggle("AFKFarm", {
    Title = "AFK Farm (Auto-Hop)", 
    Description = "Farms items and automatically hops servers.", 
    Default = false,
    Callback = function() SaveManager:Save("autoload") end
})

Tabs.Main:AddSection("Farm Settings")

Tabs.Main:AddSlider("FarmSpeed", {
    Title = "Farm Speed (Delay)",
    Description = "Lower = Faster. Increase if game is lagging or missing items.",
    Default = 0.5,
    Min = 0.1,
    Max = 2.0,
    Rounding = 1,
    Callback = function()
        SaveManager:Save("autoload") -- Auto-saves your speed preference
    end
})

-- 6. CONFIG MANAGER (AUTO-SAVE)
SaveManager:SetLibrary(Fluent)
InterfaceManager:SetLibrary(Fluent)

SaveManager:SetFolder("misgHub")

InterfaceManager:BuildInterfaceSection(Tabs.Settings)
SaveManager:BuildConfigSection(Tabs.Settings)

Window:SelectTab(1)
SaveManager:LoadAutoloadConfig()
