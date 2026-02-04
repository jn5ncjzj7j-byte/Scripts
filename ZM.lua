--// ================= SERVICES =================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

--// ================= PATHS =================
local WeaponFolder = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Weapons")

--// ================= REMOTES =================
-- SNIPER
local SniperRemote =
	ReplicatedStorage:WaitForChild("NetworkEvents")
	:WaitForChild("RemoteEvent")

-- OTHER GUNS
local GunsFolder =
	ReplicatedStorage:WaitForChild("Remotes")
	:WaitForChild("Guns")

-- MELEE
local MeleeRemote =
	ReplicatedStorage:WaitForChild("Remotes")
	:WaitForChild("Melee")
	:WaitForChild("Damage")

-- GIVE WEAPON
local EquipRemote =
	ReplicatedStorage:WaitForChild("Remotes")
	:WaitForChild("Shop")
	:WaitForChild("EquipWeapon")

--// ================= SETTINGS =================
local TARGET_FOLDER = "LivingThings"
local SNIPER_EVENT = "GUN_DAMAGE"

--// ================= STATES =================
local shootNPC = false
local shootPlayer = false
local selectedWeapon = "None"
local guiOpen = false

-- auto give weapon
local lastWeaponName = nil
local giveCooldown = false

--// ================= GUI ROOT =================
local gui = Instance.new("ScreenGui")
gui.Name = " "
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

--// ================= MAIN FRAME =================
local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 340, 0, 380)
frame.Position = UDim2.new(0, 30, 0, 200)
frame.BackgroundColor3 = Color3.fromRGB(20,20,20)
frame.BorderSizePixel = 0
frame.Visible = false
Instance.new("UICorner", frame).CornerRadius = UDim.new(0,14)

--// ================= DRAG (PC + MOBILE) =================
do
	local dragging = false
	local dragStart
	local startPos

	frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position

			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)

	UserInputService.InputChanged:Connect(function(input)
		if dragging and (
			input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch
		) then
			local delta = input.Position - dragStart
			frame.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end
	end)
end

--// ================= TITLE =================
local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1,0,0,40)
title.BackgroundTransparency = 1
title.Text = "Misg Hub"
title.Font = Enum.Font.GothamBlack
title.TextSize = 20
title.TextColor3 = Color3.fromRGB(255,80,80)

--// ================= GIVE WEAPON =================
local giveBtn = Instance.new("TextButton", frame)
giveBtn.Size = UDim2.new(0,280,0,40)
giveBtn.Position = UDim2.new(0.5,-140,0,50)
giveBtn.BackgroundColor3 = Color3.fromRGB(70,120,220)
giveBtn.Text = "GIVE WEAPON"
giveBtn.Font = Enum.Font.GothamBold
giveBtn.TextSize = 15
giveBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", giveBtn).CornerRadius = UDim.new(0,10)

local selectLabel = Instance.new("TextLabel", frame)
selectLabel.Size = UDim2.new(0,280,0,30)
selectLabel.Position = UDim2.new(0.5,-140,0,95)
selectLabel.BackgroundTransparency = 1
selectLabel.Text = "Selected: None"
selectLabel.Font = Enum.Font.Gotham
selectLabel.TextSize = 14
selectLabel.TextColor3 = Color3.fromRGB(200,200,200)

--// ================= WEAPON LIST =================
local scroll = Instance.new("ScrollingFrame", frame)
scroll.Size = UDim2.new(0,300,0,150)
scroll.Position = UDim2.new(0.5,-150,0,130)
scroll.BackgroundTransparency = 1
scroll.ScrollBarImageTransparency = 0.2

local layout = Instance.new("UIListLayout", scroll)
layout.Padding = UDim.new(0,6)

for _, w in ipairs(WeaponFolder:GetChildren()) do
	local btn = Instance.new("TextButton", scroll)
	btn.Size = UDim2.new(1,0,0,32)
	btn.BackgroundColor3 = Color3.fromRGB(45,45,45)
	btn.Text = w.Name
	btn.Font = Enum.Font.GothamBold
	btn.TextSize = 14
	btn.TextColor3 = Color3.new(1,1,1)
	Instance.new("UICorner", btn).CornerRadius = UDim.new(0,8)

	btn.MouseButton1Click:Connect(function()
		selectedWeapon = w.Name
		selectLabel.Text = "Selected: "..w.Name
	end)
end

task.wait()
scroll.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y + 10)

--// ================= TOGGLES =================
local npcBtn = Instance.new("TextButton", frame)
npcBtn.Size = UDim2.new(0,280,0,40)
npcBtn.Position = UDim2.new(0.5,-140,0,290)
npcBtn.BackgroundColor3 = Color3.fromRGB(180,60,60)
npcBtn.Text = "NPC : OFF"
npcBtn.Font = Enum.Font.GothamBold
npcBtn.TextSize = 16
npcBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", npcBtn).CornerRadius = UDim.new(0,10)

local plrBtn = Instance.new("TextButton", frame)
plrBtn.Size = UDim2.new(0,280,0,40)
plrBtn.Position = UDim2.new(0.5,-140,0,335)
plrBtn.BackgroundColor3 = Color3.fromRGB(180,60,60)
plrBtn.Text = "PLAYER : OFF"
plrBtn.Font = Enum.Font.GothamBold
plrBtn.TextSize = 16
plrBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", plrBtn).CornerRadius = UDim.new(0,10)

--// ================= TOGGLE BUTTON =================
local toggleBtn = Instance.new("TextButton", gui)
toggleBtn.Size = UDim2.new(0,140,0,36)
toggleBtn.Position = UDim2.new(0,10,1,-46)
toggleBtn.BackgroundColor3 = Color3.fromRGB(50,50,50)
toggleBtn.Text = "^"
toggleBtn.Font = Enum.Font.GothamBlack
toggleBtn.TextSize = 22
toggleBtn.TextColor3 = Color3.new(1,1,1)
Instance.new("UICorner", toggleBtn).CornerRadius = UDim.new(0,10)

toggleBtn.MouseButton1Click:Connect(function()
	guiOpen = not guiOpen
	frame.Visible = guiOpen
	toggleBtn.Text = guiOpen and "v" or "^"
end)

--// ================= BUTTON LOGIC =================
giveBtn.MouseButton1Click:Connect(function()
	if selectedWeapon ~= "None" then
		lastWeaponName = selectedWeapon
		pcall(function()
			EquipRemote:InvokeServer(selectedWeapon)
		end)
	end
end)

npcBtn.MouseButton1Click:Connect(function()
	shootNPC = not shootNPC
	npcBtn.Text = shootNPC and "NPC kill Aura : ON" or "NPC kill Aura : OFF"
	npcBtn.BackgroundColor3 = shootNPC and Color3.fromRGB(60,180,90) or Color3.fromRGB(180,60,60)
end)

plrBtn.MouseButton1Click:Connect(function()
	shootPlayer = not shootPlayer
	plrBtn.Text = shootPlayer and "PLAYER kill Aura : ON" or "PLAYER kill Aura : OFF"
	plrBtn.BackgroundColor3 = shootPlayer and Color3.fromRGB(60,180,90) or Color3.fromRGB(180,60,60)
end)

--// ================= GET EQUIPPED TOOL =================
local function getEquippedTool()
	local char = player.Character
	if not char then return end

	for _, v in ipairs(char:GetChildren()) do
		if v:IsA("Tool") then
			lastWeaponName = v.Name
			return v
		end
	end
end

--// ================= AUTO GIVE BACK WEAPON =================
RunService.Heartbeat:Connect(function()
	if giveCooldown then return end
	if not lastWeaponName then return end

	local char = player.Character
	if not char then return end

	for _, v in ipairs(char:GetChildren()) do
		if v:IsA("Tool") and v.Name == lastWeaponName then
			return
		end
	end

	giveCooldown = true
	pcall(function()
		EquipRemote:InvokeServer(lastWeaponName)
	end)

	task.delay(1.2, function()
		giveCooldown = false
	end)
end)

player.CharacterAdded:Connect(function()
	task.wait(1)
	giveCooldown = false
end)

--// ================= FIRE GUN =================
local function fireGun(target)
	local tool = getEquippedTool()
	if not tool then return end

	local hitPart =
		target:FindFirstChild("Torso")
		or target:FindFirstChild("UpperTorso")
		or target:FindFirstChild("HumanoidRootPart")
		or target:FindFirstChild("Head")

	if not hitPart then return end

	if tool.Name:lower():find("sniper") then
		pcall(function()
			SniperRemote:FireServer(SNIPER_EVENT, target)
		end)
		return
	end

	local gunRemote = GunsFolder:FindFirstChild(tool.Name .. "Damage")
	if gunRemote then
		pcall(function()
			gunRemote:FireServer({[2] = hitPart})
		end)
	end
end

--// ================= MELEE =================
local function meleeHit(model)
	local part =
		model:FindFirstChild("Head")
		or model:FindFirstChild("HumanoidRootPart")

	if part then
		pcall(function()
			MeleeRemote:InvokeServer(part)
		end)
	end
end

--// ================= KILL AURA =================
local lastHit = {}
local HIT_CD = 0.15

RunService.Heartbeat:Connect(function()
	local folder = workspace:FindFirstChild(TARGET_FOLDER)
	if not folder then return end

	local now = os.clock()

	for _, target in ipairs(folder:GetChildren()) do
		if not target:IsA("Model") then continue end
		local hum = target:FindFirstChildOfClass("Humanoid")
		if not hum or hum.Health <= 0 then continue end
		if lastHit[target] and now - lastHit[target] < HIT_CD then continue end

		local targetPlayer = Players:GetPlayerFromCharacter(target)

		if targetPlayer then
			if shootPlayer and targetPlayer ~= player then
				lastHit[target] = now
				fireGun(target)
				task.spawn(meleeHit, target)
			end
		else
			if shootNPC then
				lastHit[target] = now
				fireGun(target)
				task.spawn(meleeHit, target)
			end
		end
	end
end)
