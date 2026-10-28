local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")

local CONFIG = {
    GuiName = "misg-unti-muti-gui",
    MapLoaderUrl = "https://github.com/jn5ncjzj7j-byte/Scripts/raw/refs/heads/main/1/map.lua",
    DiscordLink = "https://discord.gg/dZjcYQN9xe",
    LoadTime = 2.5,
    FadeTime = 0.8,
}

local function create(className, props, children)
    local inst = Instance.new(className)
    for key, value in pairs(props or {}) do
        inst[key] = value
    end
    for _, child in ipairs(children or {}) do
        child.Parent = inst
    end
    return inst
end

local function getProtectedParent()
    local ok, parent = pcall(function()
        return (gethui and gethui()) or (get_hidden_gui and get_hidden_gui())
    end)
    return (ok and parent) or CoreGui
end

local function tween(instance, duration, goal, style)
    local t = TweenService:Create(
        instance,
        TweenInfo.new(duration, style or Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        goal
    )
    t:Play()
    return t
end

local function round(radius)
    return create("UICorner", { CornerRadius = radius })
end

local function addHover(button, normal, hover)
    button.MouseEnter:Connect(function()
        tween(button, 0.15, { BackgroundColor3 = hover })
    end)
    button.MouseLeave:Connect(function()
        tween(button, 0.15, { BackgroundColor3 = normal })
    end)
end

local parent = getProtectedParent()
if parent:FindFirstChild(CONFIG.GuiName) then
    return
end

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local gui = create("ScreenGui", {
    Name = CONFIG.GuiName,
    IgnoreGuiInset = true,
    ResetOnSpawn = false,
    DisplayOrder = 999999,
})

local titleStroke = create("UIStroke", {
    Color = Color3.fromRGB(100, 100, 100),
    Thickness = 2,
})

local titleLabel = create("TextLabel", {
    Size = UDim2.fromScale(1, 1),
    BackgroundTransparency = 1,
    Text = "MISG HUB",
    TextColor3 = Color3.fromRGB(60, 60, 65),
    TextSize = 36,
    Font = Enum.Font.GothamBold,
    ZIndex = 51,
})

local titleFrame = create("Frame", {
    Size = UDim2.fromOffset(380, 90),
    Position = UDim2.fromScale(0.5, 0.39),
    AnchorPoint = Vector2.new(0.5, 0.5),
    Rotation = 5,
    BackgroundColor3 = Color3.fromRGB(220, 220, 225),
    BackgroundTransparency = 0.5,
    BorderSizePixel = 0,
    ZIndex = 50,
    Parent = gui,
}, { round(UDim.new(1, 0)), titleStroke, titleLabel })

local progress = create("Frame", {
    Size = UDim2.new(0, 10, 1, -12),
    Position = UDim2.new(0, 6, 0.5, 0),
    AnchorPoint = Vector2.new(0, 0.5),
    BackgroundColor3 = Color3.new(1, 1, 1),
    BorderSizePixel = 0,
    ZIndex = 51,
}, { round(UDim.new(1, 0)) })

local barStroke = create("UIStroke", {
    Color = Color3.fromRGB(80, 80, 80),
    Thickness = 1.5,
})

local barFrame = create("Frame", {
    Size = UDim2.fromOffset(360, 50),
    Position = UDim2.fromScale(0.5, 0.54),
    AnchorPoint = Vector2.new(0.5, 0.5),
    Rotation = -5,
    BackgroundColor3 = Color3.fromRGB(40, 40, 45),
    BackgroundTransparency = 0.5,
    BorderSizePixel = 0,
    ClipsDescendants = true,
    ZIndex = 50,
    Parent = gui,
}, { round(UDim.new(1, 0)), barStroke, progress })

gui.Parent = parent

local function showError(err)
    titleFrame:Destroy()
    barFrame:Destroy()
    gui.Enabled = true

    local scale = create("UIScale", { Scale = 0.9 })

    local accent = create("Frame", {
        Size = UDim2.new(1, 0, 0, 4),
        BackgroundColor3 = Color3.fromRGB(88, 101, 242),
        BorderSizePixel = 0,
        ZIndex = 102,
    }, {
        create("UIGradient", {
            Color = ColorSequence.new(Color3.fromRGB(88, 101, 242), Color3.fromRGB(190, 80, 240)),
        }),
    })

    local title = create("TextLabel", {
        Position = UDim2.fromOffset(20, 24),
        Size = UDim2.new(1, -70, 0, 26),
        BackgroundTransparency = 1,
        Text = "Game Not Supported",
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 20,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.GothamBold,
        ZIndex = 102,
    })

    local subtitle = create("TextLabel", {
        Position = UDim2.fromOffset(20, 54),
        Size = UDim2.new(1, -40, 0, 36),
        BackgroundTransparency = 1,
        Text = "This game isn't supported yet or the map failed to load.",
        TextColor3 = Color3.fromRGB(150, 150, 160),
        TextSize = 13,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Font = Enum.Font.GothamMedium,
        ZIndex = 102,
    })

    local idPill = create("TextLabel", {
        Position = UDim2.fromOffset(20, 100),
        Size = UDim2.new(1, -40, 0, 32),
        BackgroundColor3 = Color3.fromRGB(34, 34, 40),
        BorderSizePixel = 0,
        Text = "Place ID: " .. game.PlaceId,
        TextColor3 = Color3.fromRGB(200, 200, 210),
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Font = Enum.Font.GothamMedium,
        ZIndex = 102,
    }, {
        round(UDim.new(0, 8)),
        create("UIPadding", { PaddingLeft = UDim.new(0, 12) }),
    })

    local discordColor = Color3.fromRGB(88, 101, 242)
    local copyBtn = create("TextButton", {
        Position = UDim2.new(0, 20, 1, -58),
        Size = UDim2.new(1, -40, 0, 38),
        BackgroundColor3 = discordColor,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "Copy Discord Link",
        TextColor3 = Color3.new(1, 1, 1),
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        ZIndex = 102,
    }, { round(UDim.new(0, 10)) })
    addHover(copyBtn, discordColor, Color3.fromRGB(110, 122, 250))

    local closeColor = Color3.fromRGB(45, 45, 52)
    local closeBtn = create("TextButton", {
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -12, 0, 16),
        Size = UDim2.fromOffset(28, 28),
        BackgroundColor3 = closeColor,
        BorderSizePixel = 0,
        AutoButtonColor = false,
        Text = "X",
        TextColor3 = Color3.fromRGB(210, 210, 215),
        Font = Enum.Font.GothamBold,
        TextSize = 13,
        ZIndex = 103,
    }, { round(UDim.new(0, 8)) })
    addHover(closeBtn, closeColor, Color3.fromRGB(200, 60, 60))

    local card = create("CanvasGroup", {
        GroupTransparency = 1,
        Size = UDim2.fromOffset(340, 200),
        Position = UDim2.fromScale(0.5, 0.5),
        AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.fromRGB(24, 24, 28),
        BorderSizePixel = 0,
        ZIndex = 100,
        Parent = gui,
    }, {
        round(UDim.new(0, 14)),
        create("UIStroke", { Color = Color3.fromRGB(60, 60, 70), Thickness = 1.5 }),
        scale,
        accent,
        title,
        subtitle,
        idPill,
        copyBtn,
        closeBtn,
    })

    tween(scale, 0.25, { Scale = 1 }, Enum.EasingStyle.Back)
    tween(card, 0.25, { GroupTransparency = 0 })

    local closing = false
    closeBtn.MouseButton1Click:Connect(function()
        if closing then return end
        closing = true
        tween(scale, 0.25, { Scale = 0.85 })
        local fadeOut = tween(card, 0.25, { GroupTransparency = 1 })
        fadeOut.Completed:Connect(function()
            gui:Destroy()
        end)
    end)

    local copying = false
    copyBtn.MouseButton1Click:Connect(function()
        if copying then return end
        if not setclipboard then
            copyBtn.Text = "Executor not supported"
            return
        end
        copying = true
        setclipboard(CONFIG.DiscordLink)
        copyBtn.Text = "Copied!"
        task.delay(2, function()
            copyBtn.Text = "Copy Discord Link"
            copying = false
        end)
    end)

    warn("Map Loader Error: " .. tostring(err))
end

local function loadMap()
    local source = game:HttpGet(CONFIG.MapLoaderUrl, true)
    local fn, compileErr = loadstring(source)
    if not fn then
        error(compileErr or "Failed to compile map script", 0)
    end
    fn()
end

local fill = tween(progress, CONFIG.LoadTime, {
    Size = UDim2.new(1, -12, 1, -12),
}, Enum.EasingStyle.Linear)

fill.Completed:Connect(function()
    tween(titleFrame, CONFIG.FadeTime, { BackgroundTransparency = 1 })
    tween(barFrame, CONFIG.FadeTime, { BackgroundTransparency = 1 })
    tween(progress, CONFIG.FadeTime, { BackgroundTransparency = 1 })
    tween(titleLabel, CONFIG.FadeTime, { TextTransparency = 1 })
    tween(titleStroke, CONFIG.FadeTime, { Transparency = 1 })
    local lastFade = tween(barStroke, CONFIG.FadeTime, { Transparency = 1 })

    lastFade.Completed:Connect(function()
        gui.Enabled = false
        local ok, err = pcall(loadMap)
        if not ok then
            showError(err)
        end
    end)
end)
