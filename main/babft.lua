local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local Stats = game:GetService("Stats")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local protectedParent = (gethui and gethui()) or (get_hidden_gui and get_hidden_gui()) or CoreGui

local workspace = game:GetService("Workspace")
local boatStages = workspace:WaitForChild("BoatStages", 5)
if not boatStages then
	warn("[Terminal] Workspace.BoatStages not found!")
	return
end
local normalStages = boatStages:WaitForChild("NormalStages", 5)
if not normalStages then
	warn("[Terminal] Workspace.BoatStages.NormalStages not found!")
	return
end

local existingGui = protectedParent:FindFirstChild("StageTerminalGui") or playerGui:FindFirstChild("StageTerminalGui")
if existingGui then
	existingGui:Destroy()
end

local moveSpeed = 500
local stageWaitTime = 0.55
local isRunning = false

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "StageTerminalGui"
screenGui.ResetOnSpawn = false
screenGui.DisplayOrder = math.huge
screenGui.Parent = protectedParent

local terminalFrame = Instance.new("Frame")
terminalFrame.Name = "TerminalFrame"
terminalFrame.Size = UDim2.new(0, 520, 0, 320)
terminalFrame.Position = UDim2.new(0.5, -260, 0.5, -160)
terminalFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
terminalFrame.BorderSizePixel = 0
terminalFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = terminalFrame

local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 30)
topBar.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
topBar.BorderSizePixel = 0
topBar.Parent = terminalFrame

local topCorner = Instance.new("UICorner")
topCorner.CornerRadius = UDim.new(0, 8)
topCorner.Parent = topBar

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(0.5, 0, 1, 0)
titleLabel.Position = UDim2.new(0, 12, 0, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Misg-Hub @" .. player.Name .. "~"
titleLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
titleLabel.TextSize = 13
titleLabel.Font = Enum.Font.Code
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = topBar

local statsLabel = Instance.new("TextLabel")
statsLabel.Size = UDim2.new(0.5, -12, 1, 0)
statsLabel.Position = UDim2.new(0.5, 0, 0, 0)
statsLabel.BackgroundTransparency = 1
statsLabel.Text = "FPS: 0 | Ping: 0ms"
statsLabel.TextColor3 = Color3.fromRGB(0, 255, 150)
statsLabel.TextSize = 12
statsLabel.Font = Enum.Font.Code
statsLabel.TextXAlignment = Enum.TextXAlignment.Right
statsLabel.Parent = topBar

local frameCount, lastUpdate = 0, tick()
RunService.RenderStepped:Connect(function()
	frameCount += 1
	local now = tick()
	if now - lastUpdate >= 0.1 then
		local fps = math.round(frameCount / (now - lastUpdate))
		local ping = 0
		pcall(function()
			ping = math.round(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
		end)
		statsLabel.Text = string.format("FPS: %d | Ping: %dms", fps, ping)
		frameCount, lastUpdate = 0, now
	end
end)

local dragging, dragStart, startPos

topBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = terminalFrame.Position
		
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
		local delta = input.Position - dragStart
		terminalFrame.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end
end)

local outputScroll = Instance.new("ScrollingFrame")
outputScroll.Size = UDim2.new(1, -20, 1, -85)
outputScroll.Position = UDim2.new(0, 10, 0, 40)
outputScroll.BackgroundTransparency = 1
outputScroll.BorderSizePixel = 0
outputScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
outputScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
outputScroll.Parent = terminalFrame

local uiList = Instance.new("UIListLayout")
uiList.SortOrder = Enum.SortOrder.LayoutOrder
uiList.Padding = UDim.new(0, 4)
uiList.Parent = outputScroll

local inputBar = Instance.new("Frame")
inputBar.Size = UDim2.new(1, -20, 0, 35)
inputBar.Position = UDim2.new(0, 10, 1, -42)
inputBar.BackgroundColor3 = Color3.fromRGB(12, 12, 12)
inputBar.BorderSizePixel = 0
inputBar.Parent = terminalFrame

local inputCorner = Instance.new("UICorner")
inputCorner.CornerRadius = UDim.new(0, 6)
inputCorner.Parent = inputBar

local promptLabel = Instance.new("TextLabel")
promptLabel.Size = UDim2.new(0, 20, 1, 0)
promptLabel.Position = UDim2.new(0, 8, 0, 0)
promptLabel.BackgroundTransparency = 1
promptLabel.Text = ">"
promptLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
promptLabel.TextSize = 14
promptLabel.Font = Enum.Font.Code
promptLabel.Parent = inputBar

local commandInput = Instance.new("TextBox")
commandInput.Size = UDim2.new(1, -35, 1, 0)
commandInput.Position = UDim2.new(0, 28, 0, 0)
commandInput.BackgroundTransparency = 1
commandInput.Text = ""
commandInput.PlaceholderText = "type 'start', 'stop', or 'help'..."
commandInput.PlaceholderColor3 = Color3.fromRGB(80, 80, 80)
commandInput.TextColor3 = Color3.fromRGB(255, 255, 255)
commandInput.TextSize = 14
commandInput.Font = Enum.Font.Code
commandInput.TextXAlignment = Enum.TextXAlignment.Left
commandInput.ClearTextOnFocus = false
commandInput.Parent = inputBar

local isVisible = true
local function toggleTerminal()
	isVisible = not isVisible
	terminalFrame.Visible = isVisible
end

local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

if isMobile then
	local toggleBtn = Instance.new("TextButton")
	toggleBtn.Name = "ToggleTerminalButton"
	toggleBtn.Size = UDim2.new(0, 110, 0, 45)
	toggleBtn.Position = UDim2.new(0, 20, 0, 20)
	toggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	toggleBtn.Text = "Misg Hub"
	toggleBtn.TextColor3 = Color3.fromRGB(0, 255, 100)
	toggleBtn.TextSize = 14
	toggleBtn.Font = Enum.Font.Code
	toggleBtn.Parent = screenGui
	
	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 8)
	btnCorner.Parent = toggleBtn
	
	toggleBtn.MouseButton1Click:Connect(toggleTerminal)
else
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if input.KeyCode == Enum.KeyCode.RightControl then
			toggleTerminal()
		end
	end)
end

local function printToTerminal(text, color)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 0, 18)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = color or Color3.fromRGB(200, 200, 200)
	label.TextSize = 13
	label.Font = Enum.Font.Code
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextWrapped = true
	label.Parent = outputScroll
	
	task.defer(function()
		outputScroll.CanvasPosition = Vector2.new(0, outputScroll.AbsoluteCanvasSize.Y)
	end)
end

if isMobile then
	printToTerminal("Terminal | Press 'Toggle UI' button to hide/show.", Color3.fromRGB(0, 255, 100))
else
	printToTerminal("Terminal | Press [Right Ctrl] to hide/show.", Color3.fromRGB(0, 255, 100))
end
printToTerminal("Type 'start' to begin Auto Farm, 'stop' to cancel.", Color3.fromRGB(150, 150, 150))
printToTerminal("------------------------------------------------", Color3.fromRGB(60, 60, 60))

local function getOrderedStages()
	local orderedStages = {}
	
	local forest = normalStages:FindFirstChild("ForestStage")
	if forest then table.insert(orderedStages, forest) end
	
	local caves = {}
	for _, child in ipairs(normalStages:GetChildren()) do
		if child.Name:match("^CaveStage%d+$") then
			table.insert(caves, child)
		end
	end
	
	table.sort(caves, function(a, b)
		local numA = tonumber(a.Name:match("%d+")) or 0
		local numB = tonumber(b.Name:match("%d+")) or 0
		return numA < numB
	end)
	
	for _, cave in ipairs(caves) do
		table.insert(orderedStages, cave)
	end
	
	local theEnd = normalStages:FindFirstChild("TheEnd")
	if theEnd then
		local waterfallEnd = theEnd:FindFirstChild("WaterfallEnd")
		if waterfallEnd then
			local wall = waterfallEnd:FindFirstChild("Wall")
			if wall then
				table.insert(orderedStages, wall)
			end
		end
		
		local goldenChest = theEnd:FindFirstChild("GoldenChest")
		if goldenChest then
			local trigger = goldenChest:FindFirstChild("Trigger")
			if trigger then
				table.insert(orderedStages, trigger)
			else
				table.insert(orderedStages, goldenChest)
			end
		else
			table.insert(orderedStages, theEnd)
		end
	end
	
	return orderedStages
end

local function getTargetPosition(targetInstance)
	if targetInstance:IsA("Model") then
		local cf, size = targetInstance:GetBoundingBox()
		return cf.Position + Vector3.new(0, 3, 0)
	elseif targetInstance:IsA("BasePart") then
		return targetInstance.Position + Vector3.new(0, 2, 0)
	end
	return targetInstance:GetPivot().Position
end

local function getMovablePart()
	local character = player.Character
	if not character then return nil end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.SeatPart then
		local seat = humanoid.SeatPart
		seat.Anchored = false
		local vehicleModel = seat:FindFirstAncestorOfClass("Model")
		if vehicleModel and vehicleModel.PrimaryPart then
			vehicleModel.PrimaryPart.Anchored = false
			return vehicleModel.PrimaryPart
		end
		return seat
	end
	
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if hrp then hrp.Anchored = false end
	return hrp
end

local function startSequence()
	if isRunning then
		printToTerminal("Auto Farm is already running!", Color3.fromRGB(255, 200, 0))
		return
	end
	
	local stages = getOrderedStages()
	if #stages == 0 then
		printToTerminal("Error: No stages found!", Color3.fromRGB(255, 80, 80))
		return
	end
	
	isRunning = true
	printToTerminal(string.format("Auto Farm started. Speed: %d studs/s", moveSpeed), Color3.fromRGB(0, 255, 100))
	
	task.spawn(function()
		while isRunning do
			local character = player.Character or player.CharacterAdded:Wait()
			local humanoid = character:WaitForChild("Humanoid", 10)
			
			local isDead = false
			local reachedEnd = false
			local diedConn
			
			if humanoid then
				diedConn = humanoid.Died:Connect(function()
					isDead = true
					if reachedEnd then
						printToTerminal("Reached Gold Chest!", Color3.fromRGB(0, 255, 150))
					else
						printToTerminal("Player died during Auto Farm! Waiting for respawn...", Color3.fromRGB(255, 150, 0))
					end
				end)
			end
			
			for index, target in ipairs(stages) do
				if not isRunning or isDead then break end
				
				if index == #stages then
					reachedEnd = true
				end
				
				local part = getMovablePart()
				if not part then break end
				
				local targetPos = getTargetPosition(target)
				local targetName = target.Name
				if target.Parent and target.Parent.Name == "WaterfallEnd" then
					targetName = "TheEnd.WaterfallEnd.Wall"
				elseif target.Parent and target.Parent.Name == "GoldenChest" then
					targetName = "TheEnd.GoldenChest.Trigger"
				end
				
				while isRunning and not isDead do
					local currentPos = part.Position
					local distance = (currentPos - targetPos).Magnitude
					
					if distance < 2 then break end
					
					local step = math.min(moveSpeed * RunService.Heartbeat:Wait(), distance)
					local newPos = currentPos:Lerp(targetPos, step / distance)
					
					part.CFrame = CFrame.new(newPos)
					if part:IsA("BasePart") then
						part.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
						part.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
					end
				end
				
				if not isRunning or isDead then break end
				task.wait(stageWaitTime)
			end
			
			if diedConn then diedConn:Disconnect() end
			
			if isRunning then
				player.CharacterAdded:Wait()
				task.wait(1.5)
			end
		end
		
		printToTerminal("Autofarm stopped.", Color3.fromRGB(255, 80, 80))
	end)
end

local function stopSequence()
	if not isRunning then
		printToTerminal("Auto Farm is not currently running.", Color3.fromRGB(150, 150, 150))
		return
	end
	
	isRunning = false
	printToTerminal("Auto Farm stopped.", Color3.fromRGB(255, 80, 80))
end

commandInput.FocusLost:Connect(function(enterPressed)
	if not enterPressed then return end
	
	local text = commandInput.Text:lower():gsub("^%s+", ""):gsub("%s+$", "")
	commandInput.Text = ""
	
	if text == "" then return end
	
	printToTerminal("> " .. text, Color3.fromRGB(255, 255, 255))
	
	if text == "start" or text == "on" then
		startSequence()
	elseif text == "stop" or text == "off" then
		stopSequence()
	elseif text == "clear" then
		for _, child in ipairs(outputScroll:GetChildren()) do
			if child:IsA("TextLabel") then child:Destroy() end
		end
	elseif text:match("^speed%s+(%d+)$") then
		local newSpeed = tonumber(text:match("^speed%s+(%d+)$"))
		if newSpeed and newSpeed > 0 then
			moveSpeed = newSpeed
			printToTerminal("Tween Speed Update To: " .. moveSpeed .. " Studs/s", Color3.fromRGB(0, 255, 100))
		else
			printToTerminal("Invalid value.", Color3.fromRGB(255, 80, 80))
		end
	elseif text == "help" then
		printToTerminal("Commands:", Color3.fromRGB(255, 255, 100))
		printToTerminal(" - start / on : Start Auto Far,", Color3.fromRGB(200, 200, 200))
		printToTerminal(" - stop / off : Cancel Auto Farm", Color3.fromRGB(200, 200, 200))
		printToTerminal(" - speed [n]  : Changes Tween speed", Color3.fromRGB(200, 200, 200))
		printToTerminal(" - clear      : Clears terminal history", Color3.fromRGB(200, 200, 200))
	else
		printToTerminal("Unknown command. Type 'help' for options.", Color3.fromRGB(255, 80, 80))
	end
end)
