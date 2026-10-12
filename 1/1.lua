local ZM  = game.PlaceId == 14419907512
local NT  = game.PlaceId == 4655652068
local ADT = game.PlaceId == 16389395869
local DiscordLink = "https://discord.gg/dZjcYQN9xe"

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

-- Create Main ScreenGui
local sg = Instance.new("ScreenGui")
sg.Name = "MISGHubLoadingGui"
sg.Parent = CoreGui
sg.IgnoreGuiInset = true
sg.ResetOnSpawn = false

-- Title Pill (MISG HUB) - for easy to find im lazy
local titleFrame = Instance.new("Frame")
titleFrame.Size = UDim2.new(0, 380, 0, 90)
titleFrame.Position = UDim2.new(0.5, 0, 0.39, 0)
titleFrame.AnchorPoint = Vector2.new(0.5, 0.5)
titleFrame.Rotation = 5
titleFrame.BackgroundColor3 = Color3.fromRGB(220, 220, 225)
titleFrame.BackgroundTransparency = 0.5
titleFrame.BorderSizePixel = 0
titleFrame.Parent = sg

local titleCorner = Instance.new("UICorner")
titleCorner.CornerRadius = UDim.new(1, 0)
titleCorner.Parent = titleFrame

local titleStroke = Instance.new("UIStroke")
titleStroke.Color = Color3.fromRGB(100, 100, 100)
titleStroke.Thickness = 2
titleStroke.Parent = titleFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, 0, 1, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "MISG HUB"
titleLabel.TextColor3 = Color3.fromRGB(60, 60, 65)
titleLabel.TextSize = 36
titleLabel.Font = Enum.Font.GothamBold
titleLabel.Parent = titleFrame

-- Loading Slider Bar Frame - 
local barFrame = Instance.new("Frame")
barFrame.Size = UDim2.new(0, 360, 0, 50)
barFrame.Position = UDim2.new(0.5, 0, 0.54, 0)
barFrame.AnchorPoint = Vector2.new(0.5, 0.5)
barFrame.Rotation = -5
barFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
barFrame.BackgroundTransparency = 0.5
barFrame.BorderSizePixel = 0
barFrame.ClipsDescendants = true
barFrame.Parent = sg

local barCorner = Instance.new("UICorner")
barCorner.CornerRadius = UDim.new(1, 0)
barCorner.Parent = barFrame

local barStroke = Instance.new("UIStroke")
barStroke.Color = Color3.fromRGB(80, 80, 80)
barStroke.Thickness = 1.5
barStroke.Parent = barFrame

-- White Loading Progress Bar (โหลดเต็มภายใน 4 วินาที)
local progress = Instance.new("Frame")
progress.Size = UDim2.new(0, 10, 1, -12)
progress.Position = UDim2.new(0, 6, 0.5, 0)
progress.AnchorPoint = Vector2.new(0, 0.5)
progress.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
progress.BorderSizePixel = 0
progress.Parent = barFrame

local progressCorner = Instance.new("UICorner")
progressCorner.CornerRadius = UDim.new(1, 0)
progressCorner.Parent = progress

-- Tween โหลด 4 วินาที
local tweenInfo = TweenInfo.new(4, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
local loadTween = TweenService:Create(progress, tweenInfo, {
    Size = UDim2.new(1, -12, 1, -12)
})
loadTween:Play()

-- ฟังก์ชันค่อยๆ จางหาย (Fade Out)
local function fadeOutUI()
    local fadeInfo = TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    
    TweenService:Create(titleFrame, fadeInfo, {BackgroundTransparency = 1}):Play()
    TweenService:Create(barFrame, fadeInfo, {BackgroundTransparency = 1}):Play()
    TweenService:Create(progress, fadeInfo, {BackgroundTransparency = 1}):Play()
    TweenService:Create(titleLabel, fadeInfo, {TextTransparency = 1}):Play()
    TweenService:Create(titleStroke, fadeInfo, {Transparency = 1}):Play()
    TweenService:Create(barStroke, fadeInfo, {Transparency = 1}):Play()
    
    task.wait(0.8)
    sg:Destroy()
end

-- เมื่อโหลดครบ 4 วินาทีค่อยจางหายและรันสคริปต์
task.spawn(function()
    task.wait(4)
    
    fadeOutUI()
    
    if ZM then
        loadstring(game:HttpGet("https://raw.githubusercontent.com/jn5ncjzj7j-byte/Scripts/refs/heads/main/main/ZM.lua", true))()
    elseif NT then
        loadstring(game:HttpGet("https://raw.githubusercontent.com/jn5ncjzj7j-byte/Scripts/refs/heads/main/main/NT.lua", true))()
    elseif ADT then
        loadstring(game:HttpGet("https://raw.githubusercontent.com/xxqLgnd/Utilities/main/DustyTrip", true))()
    else
        -- Unsupported Game UI
        local sgNotSupported = Instance.new("ScreenGui")
        sgNotSupported.Name = "NotSupportedGui"
        sgNotSupported.Parent = CoreGui
        sgNotSupported.IgnoreGuiInset = true

        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 300, 0, 200)
        frame.Position = UDim2.new(0.5, -150, 0.5, -100)
        frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        frame.BorderSizePixel = 0
        frame.Parent = sgNotSupported

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 10)
        corner.Parent = frame

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 0.6, 0)
        label.BackgroundTransparency = 1
        label.Text = "Game Not Supported\nID: " .. game.PlaceId .. "\n\nJoin Discord for more"
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextSize = 18
        label.Font = Enum.Font.GothamBold
        label.Parent = frame

        -- Copy Discord Button
        local copyBtn = Instance.new("TextButton")
        copyBtn.Size = UDim2.new(0, 200, 0, 40)
        copyBtn.Position = UDim2.new(0.5, -100, 0.7, 0)
        copyBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
        copyBtn.Text = "Copy Discord Link"
        copyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        copyBtn.Font = Enum.Font.GothamBold
        copyBtn.TextSize = 14
        copyBtn.Parent = frame

        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 8)
        btnCorner.Parent = copyBtn

        copyBtn.MouseButton1Click:Connect(function()
            if setclipboard then
                setclipboard(DiscordLink)
                copyBtn.Text = "Copied!"
                task.wait(2)
                copyBtn.Text = "Copy Discord Link"
            else
                copyBtn.Text = "Executor not supported"
            end
        end)

        -- Close Button
        local close = Instance.new("TextButton")
        close.Size = UDim2.new(0, 30, 0, 30)
        close.Position = UDim2.new(1, -35, 0, 5)
        close.Text = "X"
        close.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
        close.TextColor3 = Color3.fromRGB(255, 255, 255)
        close.Font = Enum.Font.GothamBold
        close.Parent = frame

        local closeCorner = Instance.new("UICorner")
        closeCorner.CornerRadius = UDim.new(0, 5)
        closeCorner.Parent = close

        close.MouseButton1Click:Connect(function()
            sgNotSupported:Destroy()
        end)

        warn("Game Not Supported. ID: " .. game.PlaceId)
    end
end)
