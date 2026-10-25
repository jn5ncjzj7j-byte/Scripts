local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LogService = game:GetService("LogService")
local StarterGui = game:GetService("StarterGui")

local parent = (gethui and gethui()) or game:FindFirstChildOfClass("CoreGui") or Players.LocalPlayer:WaitForChild("PlayerGui")
local old = parent:FindFirstChild("CodeEditorGui")
if old then old:Destroy() end

local FOLDER = "Misg_CodeEditor"
local HAS_FS = writefile and readfile and isfile and makefolder and isfolder and true or false
if HAS_FS and not isfolder(FOLDER) then pcall(makefolder, FOLDER) end

local function tween(obj, t, props, style, dir)
	local tw = TweenService:Create(obj, TweenInfo.new(t, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

local C = {
	bg = Color3.fromRGB(30,30,30), bar = Color3.fromRGB(37,37,38),
	tab = Color3.fromRGB(45,45,48), tabOn = Color3.fromRGB(30,30,30),
	btn = Color3.fromRGB(0,122,204), text = Color3.fromRGB(212,212,212),
}
local HL = {
	keyword="#569CD6", string="#CE9178", number="#B5CEA8", comment="#6A9955",
	builtin="#DCDCAA", const="#4FC1FF", plain="#D4D4D4",
}
local KEYWORDS = {}
for w in ([[and break do else elseif end for function if in local not or repeat return then until while continue]]):gmatch("%a+") do KEYWORDS[w]=true end
local CONSTS = {["true"]=true,["false"]=true,["nil"]=true,["self"]=true}
local BUILTINS = {}
for w in ([[print warn error pcall xpcall require game workspace script wait task spawn delay tick time pairs ipairs next type typeof tostring tonumber setmetatable getmetatable table string math Instance Vector3 Vector2 CFrame Color3 UDim2 Enum select unpack rawget rawset assert os]]):gmatch("%a+") do BUILTINS[w]=true end

local function esc(s) return (s:gsub("&","&amp;"):gsub("<","&lt;"):gsub(">","&gt;")) end
local function highlight(src)
	local out, i, n = {}, 1, #src
	local function push(color, s) out[#out+1] = '<font color="'..color..'">'..esc(s)..'</font>' end
	while i <= n do
		local c = src:sub(i,i)
		if src:sub(i,i+1) == "--" then
			local lvl = src:match("^%-%-%[(=*)%[", i)
			local e
			if lvl then
				local _, ee = src:find("]"..lvl.."]", i, true)
				e = ee or n
			else
				e = (src:find("\n", i, true) or n+1) - 1
			end
			push(HL.comment, src:sub(i,e)); i = e+1
		elseif c == '"' or c == "'" then
			local j = i+1
			while j <= n do
				local d = src:sub(j,j)
				if d == "\\" then j += 2
				elseif d == c or d == "\n" then break
				else j += 1 end
			end
			push(HL.string, src:sub(i,j)); i = j+1
		elseif c == "[" and src:match("^%[=*%[", i) then
			local lvl = src:match("^%[(=*)%[", i)
			local _, e = src:find("]"..lvl.."]", i, true)
			e = e or n
			push(HL.string, src:sub(i,e)); i = e+1
		elseif c:match("%d") then
			local num = src:match("^0[xX]%x+", i) or src:match("^%d+%.?%d*", i)
			push(HL.number, num); i += #num
		elseif c:match("[%a_]") then
			local w = src:match("^[%a_][%w_]*", i)
			local col = HL.plain
			if KEYWORDS[w] then col = HL.keyword
			elseif CONSTS[w] then col = HL.const
			elseif BUILTINS[w] then col = HL.builtin end
			push(col, w); i += #w
		else
			local chunk = src:match('^[^%w_"\'%-%[]+', i) or c
			push(HL.plain, chunk); i += #chunk
		end
	end
	return table.concat(out)
end

local tabs, current, nextId = {}, 1, 1
local colorMode = true
local focused = false

local gui = Instance.new("ScreenGui")
gui.Name = "CodeEditorGui"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true
gui.DisplayOrder = 999; gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = parent

local shownPos = UDim2.new(0.04,0,0.05,0)
local function hiddenPos() return UDim2.new(shownPos.X.Scale, shownPos.X.Offset, -1, 0) end

local main = Instance.new("Frame", gui)
main.Size = UDim2.new(0.92,0,0.7,0); main.Position = hiddenPos()
main.BackgroundColor3 = C.bg; main.BorderSizePixel = 0
main.ClipsDescendants = true
Instance.new("UICorner", main).CornerRadius = UDim.new(0,8)

local top = Instance.new("Frame", main)
top.Size = UDim2.new(1,0,0,36); top.BackgroundColor3 = C.bar; top.BorderSizePixel = 0

local function mkBtn(text, w, color, parent)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0,w,0,26)
	b.BackgroundColor3 = color; b.Text = text; b.TextColor3 = Color3.new(1,1,1)
	b.Font = Enum.Font.GothamBold; b.TextSize = 13
	Instance.new("UICorner", b).CornerRadius = UDim.new(0,5)
	b.Parent = parent
	return b
end

local title = Instance.new("TextLabel", top)
title.Size = UDim2.new(0,60,1,0); title.Position = UDim2.new(0,8,0,0)
title.BackgroundTransparency = 1; title.Text = "Misg Code Editor"
title.TextColor3 = C.text; title.Font = Enum.Font.GothamBold; title.TextSize = 13
title.TextXAlignment = Enum.TextXAlignment.Left

local btnRow = Instance.new("Frame", top)
btnRow.BackgroundTransparency = 1
btnRow.AnchorPoint = Vector2.new(1,0)
btnRow.Position = UDim2.new(1,-6,0,0)
btnRow.Size = UDim2.new(1,-70,1,0)
local bl = Instance.new("UIListLayout", btnRow)
bl.FillDirection = Enum.FillDirection.Horizontal
bl.HorizontalAlignment = Enum.HorizontalAlignment.Right
bl.VerticalAlignment = Enum.VerticalAlignment.Center
bl.Padding = UDim.new(0,5)
bl.SortOrder = Enum.SortOrder.LayoutOrder

local clearBtn = mkBtn("Clear", 48, Color3.fromRGB(150,60,60), btnRow); clearBtn.LayoutOrder = 1
local copyBtn  = mkBtn("Copy All", 66, C.btn, btnRow); copyBtn.LayoutOrder = 2
local hideBtn  = mkBtn("_", 28, Color3.fromRGB(90,90,90), btnRow); hideBtn.LayoutOrder = 3
local closeBtn = mkBtn("X", 28, Color3.fromRGB(200,50,50), btnRow); closeBtn.LayoutOrder = 4

local tabBar = Instance.new("ScrollingFrame", main)
tabBar.Position = UDim2.new(0,0,0,36); tabBar.Size = UDim2.new(1,0,0,30)
tabBar.BackgroundColor3 = C.bar; tabBar.BorderSizePixel = 0
tabBar.ScrollBarThickness = 0; tabBar.ScrollingDirection = Enum.ScrollingDirection.X
tabBar.AutomaticCanvasSize = Enum.AutomaticSize.X; tabBar.CanvasSize = UDim2.new()
local tl = Instance.new("UIListLayout", tabBar)
tl.FillDirection = Enum.FillDirection.Horizontal; tl.Padding = UDim.new(0,2)
tl.SortOrder = Enum.SortOrder.LayoutOrder

local EDITOR_POS = UDim2.new(0,0,0,68)
local scroll = Instance.new("ScrollingFrame", main)
scroll.Position = EDITOR_POS; scroll.Size = UDim2.new(1,0,1,-104)
scroll.BackgroundColor3 = C.bg; scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 6
scroll.ScrollingDirection = Enum.ScrollingDirection.XY
scroll.AutomaticCanvasSize = Enum.AutomaticSize.XY; scroll.CanvasSize = UDim2.new()

local function setupText(obj)
	obj.Position = UDim2.new(0,0,0,0)
	obj.Size = UDim2.new(1,-6,1,0)
	obj.AutomaticSize = Enum.AutomaticSize.XY
	obj.BackgroundTransparency = 1
	obj.Font = Enum.Font.Code; obj.TextSize = 16
	obj.TextXAlignment = Enum.TextXAlignment.Left
	obj.TextYAlignment = Enum.TextYAlignment.Top
	obj.TextWrapped = false
	local p = Instance.new("UIPadding", obj)
	p.PaddingLeft = UDim.new(0,6); p.PaddingTop = UDim.new(0,4)
	p.PaddingBottom = UDim.new(0,40); p.PaddingRight = UDim.new(0,40)
end

local view = Instance.new("TextLabel", scroll)
setupText(view)
view.RichText = true; view.Text = ""; view.TextColor3 = C.text; view.ZIndex = 1

local box = Instance.new("TextBox", scroll)
setupText(box)
box.MultiLine = true; box.ClearTextOnFocus = false; box.TextEditable = true
box.TextColor3 = C.text; box.Text = ""
box.TextTransparency = 0; box.ZIndex = 2
box.PlaceholderText = "-- type code here"; box.PlaceholderColor3 = Color3.fromRGB(110,110,110)

local function applyMode()
	if colorMode and not focused then
		view.Visible = true
		box.TextTransparency = 1
	else
		view.Visible = false
		box.TextTransparency = 0
	end
end

local bottom = Instance.new("Frame", main)
bottom.Position = UDim2.new(0,0,1,-36); bottom.Size = UDim2.new(1,0,0,36)
bottom.BackgroundColor3 = C.bar; bottom.BorderSizePixel = 0

local status = Instance.new("TextLabel", bottom)
status.Position = UDim2.new(0,8,0,0); status.Size = UDim2.new(1,-250,1,0)
status.BackgroundTransparency = 1; status.TextColor3 = Color3.fromRGB(150,150,150)
status.Font = Enum.Font.Gotham; status.TextSize = 11; status.Text = ""
status.TextXAlignment = Enum.TextXAlignment.Left
status.TextTruncate = Enum.TextTruncate.AtEnd
local function setStatus(t) status.Text = t end

local botRow = Instance.new("Frame", bottom)
botRow.BackgroundTransparency = 1
botRow.AnchorPoint = Vector2.new(1,0)
botRow.Position = UDim2.new(1,-6,0,0)
botRow.Size = UDim2.new(0,240,1,0)
local bl2 = Instance.new("UIListLayout", botRow)
bl2.FillDirection = Enum.FillDirection.Horizontal
bl2.HorizontalAlignment = Enum.HorizontalAlignment.Right
bl2.VerticalAlignment = Enum.VerticalAlignment.Center
bl2.Padding = UDim.new(0,4)
bl2.SortOrder = Enum.SortOrder.LayoutOrder

local consoleBtn = mkBtn("Console", 62, Color3.fromRGB(120,80,170), botRow); consoleBtn.LayoutOrder = 1
local colorBtn = mkBtn("Color: ON", 74, Color3.fromRGB(190,120,30), botRow); colorBtn.LayoutOrder = 2
local lineBtn = mkBtn("+ Line", 70, Color3.fromRGB(40,150,90), botRow); lineBtn.LayoutOrder = 3
lineBtn.Size = UDim2.new(0,70,0,28)

colorBtn.MouseButton1Click:Connect(function()
	colorMode = not colorMode
	colorBtn.Text = colorMode and "Color: ON" or "Color: OFF"
	applyMode()
	setStatus(colorMode and "Colors show when not typing" or "Colors off")
end)

local consolePanel = Instance.new("Frame", main)
consolePanel.BackgroundColor3 = Color3.fromRGB(20,20,22); consolePanel.BorderSizePixel = 0
consolePanel.Size = UDim2.new(1,0,1,-104)
consolePanel.Position = UDim2.new(0,0,1,0)
consolePanel.Visible = false
consolePanel.ZIndex = 10
consolePanel.ClipsDescendants = true

local cHead = Instance.new("Frame", consolePanel)
cHead.Size = UDim2.new(1,0,0,30); cHead.BackgroundColor3 = C.bar; cHead.BorderSizePixel = 0; cHead.ZIndex = 11
local cTitle = Instance.new("TextLabel", cHead)
cTitle.Size = UDim2.new(0,70,1,0); cTitle.Position = UDim2.new(0,8,0,0)
cTitle.BackgroundTransparency = 1; cTitle.Text = "Console"; cTitle.ZIndex = 11
cTitle.TextColor3 = C.text; cTitle.Font = Enum.Font.GothamBold; cTitle.TextSize = 13
cTitle.TextXAlignment = Enum.TextXAlignment.Left

local cRow = Instance.new("Frame", cHead)
cRow.BackgroundTransparency = 1; cRow.ZIndex = 11
cRow.AnchorPoint = Vector2.new(1,0); cRow.Position = UDim2.new(1,-6,0,0); cRow.Size = UDim2.new(1,-80,1,0)
local cl = Instance.new("UIListLayout", cRow)
cl.FillDirection = Enum.FillDirection.Horizontal
cl.HorizontalAlignment = Enum.HorizontalAlignment.Right
cl.VerticalAlignment = Enum.VerticalAlignment.Center
cl.Padding = UDim.new(0,5); cl.SortOrder = Enum.SortOrder.LayoutOrder

local cClear = mkBtn("Clear", 48, Color3.fromRGB(150,60,60), cRow); cClear.LayoutOrder = 1; cClear.ZIndex = 12
local cDev = mkBtn("Dev Console", 88, C.btn, cRow); cDev.LayoutOrder = 2; cDev.ZIndex = 12
local cClose = mkBtn("Close", 48, Color3.fromRGB(90,90,90), cRow); cClose.LayoutOrder = 3; cClose.ZIndex = 12

local cScroll = Instance.new("ScrollingFrame", consolePanel)
cScroll.Position = UDim2.new(0,0,0,30); cScroll.Size = UDim2.new(1,0,1,-30)
cScroll.BackgroundTransparency = 1; cScroll.BorderSizePixel = 0; cScroll.ZIndex = 11
cScroll.ScrollBarThickness = 6
cScroll.ScrollingDirection = Enum.ScrollingDirection.Y
cScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y; cScroll.CanvasSize = UDim2.new()

local cText = Instance.new("TextLabel", cScroll)
cText.Size = UDim2.new(1,-8,0,0); cText.AutomaticSize = Enum.AutomaticSize.Y
cText.Position = UDim2.new(0,4,0,0)
cText.BackgroundTransparency = 1; cText.RichText = true; cText.TextWrapped = true
cText.Font = Enum.Font.Code; cText.TextSize = 14; cText.ZIndex = 11
cText.TextXAlignment = Enum.TextXAlignment.Left; cText.TextYAlignment = Enum.TextYAlignment.Top
cText.TextColor3 = C.text; cText.Text = ""

local logs = {}
local MAX_LOGS = 200
local LOG_COLORS = {
	[Enum.MessageType.MessageOutput] = "#D4D4D4",
	[Enum.MessageType.MessageInfo] = "#4FC1FF",
	[Enum.MessageType.MessageWarning] = "#E5A83B",
	[Enum.MessageType.MessageError] = "#F44747",
}
local function renderLogs()
	cText.Text = table.concat(logs, "\n")
	task.defer(function() cScroll.CanvasPosition = Vector2.new(0, 1e6) end)
end
local function addLog(msg, mtype)
	local col = LOG_COLORS[mtype] or "#D4D4D4"
	logs[#logs+1] = '<font color="'..col..'">'..esc(tostring(msg))..'</font>'
	if #logs > MAX_LOGS then table.remove(logs, 1) end
end
pcall(function()
	for _, entry in ipairs(LogService:GetLogHistory()) do
		addLog(entry.message, entry.messageType)
	end
end)
renderLogs()
local logConn = LogService.MessageOut:Connect(function(msg, mtype)
	addLog(msg, mtype)
	if consolePanel.Visible then renderLogs() end
end)

local consoleOpen = false
local function setConsole(open)
	if open == consoleOpen then return end
	consoleOpen = open
	if open then
		renderLogs()
		consolePanel.Position = UDim2.new(0,0,1,0)
		consolePanel.Visible = true
		tween(consolePanel, 0.35, {Position = EDITOR_POS}, Enum.EasingStyle.Back)
		consoleBtn.Text = "Editor"
	else
		consoleBtn.Text = "Console"
		tween(consolePanel, 0.3, {Position = UDim2.new(0,0,1,0)}, Enum.EasingStyle.Quint, Enum.EasingDirection.In).Completed:Connect(function()
			if not consoleOpen then consolePanel.Visible = false end
		end)
	end
end
consoleBtn.MouseButton1Click:Connect(function() setConsole(not consoleOpen) end)
cClose.MouseButton1Click:Connect(function() setConsole(false) end)
cClear.MouseButton1Click:Connect(function() logs = {}; renderLogs() end)
cDev.MouseButton1Click:Connect(function()
	local ok = pcall(function() StarterGui:SetCore("DevConsoleVisible", true) end)
	if not ok then setStatus("Could not open Dev Console") end
end)

local function tabPath(id) return FOLDER.."/tab_"..id..".lua" end
local function saveIndex()
	if not HAS_FS then return end
	local names = {}
	for _, t in ipairs(tabs) do names[#names+1] = t.id..":"..t.name end
	pcall(writefile, FOLDER.."/_index.txt", table.concat(names, "\n"))
end
local function saveTab(t)
	if not HAS_FS then return end
	if pcall(writefile, tabPath(t.id), t.code) then
		setStatus("Saved "..t.name.." ("..os.date("%X")..")")
	end
end

local lastCursor = nil
box:GetPropertyChangedSignal("CursorPosition"):Connect(function()
	if box.CursorPosition ~= -1 then lastCursor = box.CursorPosition end
end)

local renderTabs
local function switchTo(i, animate)
	current = math.clamp(i, 1, #tabs)
	lastCursor = nil
	box.Text = tabs[current].code
	renderTabs(animate and current or nil)
	if animate then
		scroll.Position = UDim2.new(0,0,0,EDITOR_POS.Y.Offset + 24)
		tween(scroll, 0.3, {Position = EDITOR_POS})
	end
end

function renderTabs(animIndex)
	for _, c in ipairs(tabBar:GetChildren()) do
		if c:IsA("GuiObject") then c:Destroy() end
	end
	for i, t in ipairs(tabs) do
		local f = Instance.new("Frame")
		f.Size = UDim2.new(0,100,1,0); f.BorderSizePixel = 0
		f.BackgroundColor3 = (i == current) and C.tabOn or C.tab
		f.LayoutOrder = i; f.ClipsDescendants = true; f.Parent = tabBar
		local b = Instance.new("TextButton", f)
		b.Size = UDim2.new(0,76,1,0); b.BackgroundTransparency = 1
		b.Text = t.name; b.TextColor3 = C.text; b.Font = Enum.Font.Gotham
		b.TextSize = 13; b.TextTruncate = Enum.TextTruncate.AtEnd
		b.MouseButton1Click:Connect(function()
			if i ~= current then switchTo(i, true) end
		end)
		local x = Instance.new("TextButton", f)
		x.Size = UDim2.new(0,24,1,0); x.Position = UDim2.new(0,76,0,0)
		x.BackgroundTransparency = 1; x.Text = "x"; x.TextColor3 = Color3.fromRGB(180,180,180)
		x.Font = Enum.Font.GothamBold; x.TextSize = 12
		x.MouseButton1Click:Connect(function()
			if #tabs <= 1 then
				tabs[1].code = ""; box.Text = ""; saveTab(tabs[1]); return
			end
			if HAS_FS and delfile then pcall(delfile, tabPath(t.id)) end
			table.remove(tabs, i)
			saveIndex()
			switchTo(math.min(current > i and current - 1 or current, #tabs), true)
		end)
		if animIndex == i then
			f.Size = UDim2.new(0,0,1,0)
			tween(f, 0.3, {Size = UDim2.new(0,100,1,0)}, Enum.EasingStyle.Back)
		end
	end
	local add = Instance.new("TextButton")
	add.Size = UDim2.new(0,30,1,0); add.LayoutOrder = 9999
	add.BackgroundColor3 = C.btn; add.Text = "+"; add.TextColor3 = Color3.new(1,1,1)
	add.Font = Enum.Font.GothamBold; add.TextSize = 18; add.BorderSizePixel = 0
	add.Parent = tabBar
	add.MouseButton1Click:Connect(function()
		nextId += 1
		tabs[#tabs+1] = {id = nextId, name = "Script "..nextId, code = ""}
		saveIndex(); saveTab(tabs[#tabs])
		switchTo(#tabs, true)
		task.delay(0.35, function()
			tabBar.CanvasPosition = Vector2.new(math.huge, 0)
		end)
	end)
end

if HAS_FS and isfile(FOLDER.."/_index.txt") then
	local ok, data = pcall(readfile, FOLDER.."/_index.txt")
	if ok and data then
		for line in data:gmatch("[^\n]+") do
			local id, name = line:match("^(%d+):(.+)$")
			if id and isfile(tabPath(id)) then
				local ok2, code = pcall(readfile, tabPath(id))
				tabs[#tabs+1] = {id = tonumber(id), name = name, code = ok2 and code or ""}
				nextId = math.max(nextId, tonumber(id))
			end
		end
	end
end
if #tabs == 0 then tabs[1] = {id = 1, name = "Script 1", code = ""} end

local saveToken = 0
box:GetPropertyChangedSignal("Text"):Connect(function()
	local ok, res = pcall(highlight, box.Text)
	if ok then view.Text = res end
	applyMode()
	local t = tabs[current]
	if t then
		t.code = box.Text
		saveToken += 1
		local my = saveToken
		task.delay(1, function()
			if my == saveToken then saveTab(t) end
		end)
	end
end)

box.Focused:Connect(function()
	focused = true
	applyMode()
end)
box.FocusLost:Connect(function()
	focused = false
	local ok, res = pcall(highlight, box.Text)
	if ok then view.Text = res end
	applyMode()
end)

lineBtn.MouseButton1Click:Connect(function()
	local txt = box.Text
	local pos = math.clamp(lastCursor or (#txt + 1), 1, #txt + 1)
	box.Text = txt:sub(1, pos - 1) .. "\n" .. txt:sub(pos)
	box:CaptureFocus()
	task.delay(0.05, function()
		box.CursorPosition = pos + 1
		lastCursor = pos + 1
	end)
	lineBtn.Size = UDim2.new(0,62,0,24)
	tween(lineBtn, 0.2, {Size = UDim2.new(0,70,0,28)}, Enum.EasingStyle.Back)
end)

copyBtn.MouseButton1Click:Connect(function()
	local fn = setclipboard or toclipboard or (Clipboard and Clipboard.set)
	if fn then pcall(fn, box.Text); copyBtn.Text = "Copied!" else copyBtn.Text = "No clip" end
	task.delay(1.2, function() copyBtn.Text = "Copy All" end)
end)
clearBtn.MouseButton1Click:Connect(function() box.Text = "" end)

local busy = false

local mini = mkBtn("Editor", 64, C.btn, gui)
mini.Size = UDim2.new(0,64,0,30); mini.Position = UDim2.new(0,-80,0,60); mini.Visible = false

local function hideGui()
	if busy then return end
	busy = true
	shownPos = main.Position
	tween(main, 0.35, {Position = hiddenPos()}, Enum.EasingStyle.Quint, Enum.EasingDirection.In).Completed:Connect(function()
		main.Visible = false
		mini.Position = UDim2.new(0,-80,0,60); mini.Visible = true
		tween(mini, 0.3, {Position = UDim2.new(0,10,0,60)}, Enum.EasingStyle.Back)
		busy = false
	end)
end

local function showGui()
	if busy then return end
	busy = true
	tween(mini, 0.2, {Position = UDim2.new(0,-80,0,60)}).Completed:Connect(function()
		mini.Visible = false
		main.Position = hiddenPos(); main.Visible = true
		tween(main, 0.45, {Position = shownPos}, Enum.EasingStyle.Back).Completed:Connect(function()
			busy = false
		end)
	end)
end

hideBtn.MouseButton1Click:Connect(hideGui)
mini.MouseButton1Click:Connect(showGui)
closeBtn.MouseButton1Click:Connect(function()
	if busy then return end
	busy = true
	local t = tabs[current]; if t then saveTab(t) end
	logConn:Disconnect()
	shownPos = main.Position
	tween(main, 0.35, {Position = hiddenPos()}, Enum.EasingStyle.Quint, Enum.EasingDirection.In).Completed:Connect(function()
		gui:Destroy()
	end)
end)

do
	local dragging, startPos, startInput
	top.InputBegan:Connect(function(i)
		if busy then return end
		if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = true; startInput = i.Position; startPos = main.Position
		end
	end)
	UIS.InputChanged:Connect(function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseMovement) then
			local d = i.Position - startInput
			main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
			shownPos = main.Position
		end
	end)
	UIS.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
	end)
end

saveIndex()
switchTo(1)
applyMode()
setStatus(HAS_FS and "Auto-save on ("..FOLDER..")" or "Auto-save unavailable")

busy = true
tween(main, 0.5, {Position = shownPos}, Enum.EasingStyle.Back).Completed:Connect(function() busy = false end)
