local ZM  = game.PlaceId == 14419907512
local NT  = game.PlaceId == 4655652068
local DiscordLink = "https://discord.gg/MQaKgPjFD"

if not game:IsLoaded() then
    game.Loaded:Wait()
end

if ZM then
    loadstring(game:HttpGet("https://raw.githubusercontent.com/jn5ncjzj7j-byte/Scripts/refs/heads/main/ZM.lua"))()
elseif NT then
    loadstring(game:HttpGet("https://raw.githubusercontent.com/jn5ncjzj7j-byte/Scripts/refs/heads/main/NT.lua"))()
else
    local CoreGui = game:GetService("CoreGui")
    
    local sg = Instance.new("ScreenGui")
    sg.Name = "NotSupportedGui"
    sg.Parent = CoreGui
    sg.IgnoreGuiInset = true

    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 200) -- Increased height for the button
    frame.Position = UDim2.new(0.5, -150, 0.5, -100)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.BorderSizePixel = 0
    frame.Parent = sg

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

    local copyBtn = Instance.new("TextButton")
    copyBtn.Size = UDim2.new(0, 200, 0, 40)
    copyBtn.Position = UDim2.new(0.5, -100, 0.7, 0)
    copyBtn.BackgroundColor3 = Color3.fromRGB(88, 101, 242) -- Discord Blue
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

    local close = Instance.new("TextButton")
    close.Size = UDim2.new(0, 30, 0, 30)
    close.Position = UDim2.new(1, -35, 0, 5)
    close.Text = "X"
    close.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    close.TextColor3 = Color3.fromRGB(255, 255, 255)
    close.Parent = frame
    
    local closeCorner = Instance.new("UICorner")
    closeCorner.CornerRadius = UDim.new(0, 5)
    closeCorner.Parent = close

    close.MouseButton1Click:Connect(function()
        sg:Destroy()
    end)

    warn("Game Not Supported. ID: " .. game.PlaceId)
end
