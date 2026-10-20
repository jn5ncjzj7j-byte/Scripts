-- Services
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local protectedParent = (gethui and gethui()) or (get_hidden_gui and get_hidden_gui()) or CoreGui

-- SINGLETON CHECK: ถ้ามี GUI นี้อยู่แล้ว จะหยุดการทำงานทันที (ไม่รันซ้ำ)
if protectedParent:FindFirstChild("misg-unti-muti-gui") then
    return
end

-- ==========================================
-- ตั้งค่าลิงก์สคริปต์ตัวล่างจาก GitHub ตรงนี้
-- ==========================================
local MapLoaderScriptUrl = "https://github.com/jn5ncjzj7j-byte/Scripts/raw/refs/heads/main/test.lua"
local DiscordLink = "https://discord.gg/dZjcYQN9xe"

if not game:IsLoaded() then
    game.Loaded:Wait()
end

-- ==========================================
-- MISG HUB LOADING SCREEN ANIMATION
-- ==========================================
local sg = Instance.new("ScreenGui")
sg.Name = "misg-unti-muti-gui"
sg.Parent = protectedParent
sg.IgnoreGuiInset = true
sg.ResetOnSpawn = false
sg.DisplayOrder = 999999

local titleFrame = Instance.new("Frame")
titleFrame.Size = UDim2.new(0, 380, 0, 90)
titleFrame.Position = UDim2.new(0.5, 0, 0.39, 0)
titleFrame.AnchorPoint = Vector2.new(0.5, 0.5)
titleFrame.Rotation = 5
titleFrame.BackgroundColor3 = Color3.fromRGB(220, 220, 225)
titleFrame.BackgroundTransparency = 0.5
titleFrame.BorderSizePixel = 0
titleFrame.ZIndex = 50
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
titleLabel.ZIndex = 51
titleLabel.Parent = titleFrame

local barFrame = Instance.new("Frame")
barFrame.Size = UDim2.new(0, 360, 0, 50)
barFrame.Position = UDim2.new(0.5, 0, 0.54, 0)
barFrame.AnchorPoint = Vector2.new(0.5, 0.5)
barFrame.Rotation = -5
barFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
barFrame.BackgroundTransparency = 0.5
barFrame.BorderSizePixel = 0
barFrame.ClipsDescendants = true
barFrame.ZIndex = 50
barFrame.Parent = sg

local barCorner = Instance.new("UICorner")
barCorner.CornerRadius = UDim.new(1, 0)
barCorner.Parent = barFrame

local barStroke = Instance.new("UIStroke")
barStroke.Color = Color3.fromRGB(80, 80, 80)
barStroke.Thickness = 1.5
barStroke.Parent = barFrame

local progress = Instance.new("Frame")
progress.Size = UDim2.new(0, 10, 1, -12)
progress.Position = UDim2.new(0, 6, 0.5, 0)
progress.AnchorPoint = Vector2.new(0, 0.5)
progress.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
progress.BorderSizePixel = 0
progress.ZIndex = 51
progress.Parent = barFrame

local progressCorner = Instance.new("UICorner")
progressCorner.CornerRadius = UDim.new(1, 0)
progressCorner.Parent = progress

local tweenInfo = TweenInfo.new(4, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
local loadTween = TweenService:Create(progress, tweenInfo, {
    Size = UDim2.new(1, -12, 1, -12)
})
loadTween:Play()

-- ==========================================
-- LOAD HANDLER (รอโหลดเสร็จแล้วค่อยทำต่อ)
-- ==========================================
task.spawn(function()
    task.wait(4) -- รออนิเมชั่นโหลด 4 วินาที
    
    local fadeInfo = TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    TweenService:Create(titleFrame, fadeInfo, {BackgroundTransparency = 1}):Play()
    TweenService:Create(barFrame, fadeInfo, {BackgroundTransparency = 1}):Play()
    TweenService:Create(progress, fadeInfo, {BackgroundTransparency = 1}):Play()
    TweenService:Create(titleLabel, fadeInfo, {TextTransparency = 1}):Play()
    TweenService:Create(titleStroke, fadeInfo, {Transparency = 1}):Play()
    TweenService:Create(barStroke, fadeInfo, {Transparency = 1}):Play()
    
    task.wait(0.8)
    
    -- เช็คก่อนว่ามีสคริปต์ตัวล่างอยู่จริงไหม (หรือจะเขียนเช็ค PlaceId ในนี้คร่าวๆ ก่อนก็ได้)
    -- โดยในที่นี้เราจะซ่อนหน้าโหลดแล้วสั่งรันสคริปต์ตัวล่างจาก GitHub
    sg.Enabled = false -- ซ่อนหน้าโหลดไว้ (ไม่ทำลาย เพื่อกันเปิดซ้ำตามเงื่อนไข)

    local success, err = pcall(function()
        loadstring(game:HttpGet(MapLoaderScriptUrl, true))()
    end)

    if not success then
        -- ถ้าดึงสคริปต์ตัวล่างไม่สำเร็จ หรือเกมไม่รองรับ (สามารถจัดการแจ้งเตือนตรงนี้ต่อได้)
        sg.Enabled = true
        titleFrame:Destroy()
        barFrame:Destroy()

        local unsupportedFrame = Instance.new("Frame")
        unsupportedFrame.Size = UDim2.new(0, 320, 0, 220)
        unsupportedFrame.Position = UDim2.new(0.5, -160, 0.5, -110)
        unsupportedFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        unsupportedFrame.BorderSizePixel = 0
        unsupportedFrame.ZIndex = 100
        unsupportedFrame.Parent = sg

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 10)
        corner.Parent = unsupportedFrame

        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 0.45, 0)
        label.BackgroundTransparency = 1
        label.Text = "Game Not Supported / Error\nID: " .. game.PlaceId .. "\nJoin Discord for more"
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextSize = 16
        label.Font = Enum.Font.GothamBold
        label.ZIndex = 101
        label.Parent = unsupportedFrame

        local countdownLabel = Instance.new("TextLabel")
        countdownLabel.Size = UDim2.new(1, 0, 0, 35)
        countdownLabel.Position = UDim2.new(0, 0, 0.48, 0)
        countdownLabel.BackgroundTransparency = 1
        countdownLabel.Text = "5 seconds remaining until destroy GUI"
        countdownLabel.TextColor3 = Color3.fromRGB(200, 50, 50)
        countdownLabel.TextSize = 14
        countdownLabel.Font = Enum.Font.GothamBold
        countdownLabel.ZIndex = 101
        countdownLabel.Parent = unsupportedFrame

        local copyBtn = Instance.new("TextButton")
        copyBtn.Size = UDim2.new(0, 220, 0, 38)
        copyBtn.Position = UDim2.new(0.5, -110, 0.72, 0)
        copyBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
        copyBtn.Text = "Copy Discord Link"
        copyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
        copyBtn.Font = Enum.Font.GothamBold
        copyBtn.TextSize = 14
        copyBtn.ZIndex = 101
        copyBtn.Parent = unsupportedFrame

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

        task.spawn(function()
            for i = 5, 1, -1 do
                if not unsupportedFrame.Parent then break end
                countdownLabel.Text = i .. " seconds remaining until destroy GUI"
                task.wait(1)
            end
            if sg and sg.Parent then
                sg:Destroy()
            end
        end)

        warn("Map Loader Error: " .. tostring(err))
    end
end)
