local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")
local LogService = game:GetService("LogService")
local StarterGui = game:GetService("StarterGui")
local HttpService = game:GetService("HttpService")

local parent = (gethui and gethui()) or game:FindFirstChildOfClass("CoreGui") or Players.LocalPlayer:WaitForChild("PlayerGui")
for _, v in ipairs(parent:GetChildren()) do
	if v:GetAttribute("MisgEditor") then v:Destroy() end
end

local FOLDER = "Misg_CodeEditor"
local HAS_FS = writefile and readfile and isfile and makefolder and isfolder and true or false
if HAS_FS and not isfolder(FOLDER) then pcall(makefolder, FOLDER) end

local conns = {}
local function bind(sig, fn)
	local c = sig:Connect(fn)
	conns[#conns+1] = c
	return c
end

local function tween(obj, t, props, style, dir)
	local tw = TweenService:Create(obj, TweenInfo.new(t, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

local C = {
	bg = Color3.fromRGB(30,30,30), bar = Color3.fromRGB(37,37,38),
	tab = Color3.fromRGB(45,45,48), tabOn = Color3.fromRGB(30,30,30),
	btn = Color3.fromRGB(0,122,204), text = Color3.fromRGB(212,212,212),
	fav = Color3.fromRGB(230,180,50)
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
local searchText = ""

local gui = Instance.new("ScreenGui")
do
	local ok, n = pcall(function() return HttpService:GenerateGUID(false) end)
	gui.Name = ok and n or ("MisgEditor_"..tostring(os.time()).."_"..tostring(math.random(1,99999)))
end
gui:SetAttribute("MisgEditor", true)
gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true
gui.DisplayOrder = 999; gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = parent

local function rainbow(off)
	local kps = {}
	for i = 0, 8 do
		kps[#kps+1] = ColorSequenceKeypoint.new(i/8, Color3.fromHSV((i/8 + off) % 1, 0.65, 1))
	end
	return ColorSequence.new(kps)
end

local shownPos = UDim2.new(0.04,0,0.15,0)
local function hiddenPos() return UDim2.new(shownPos.X.Scale, shownPos.X.Offset, -1, 0) end

local main = Instance.new("Frame", gui)
main.Size = UDim2.new(0.92,0,0.7,0); main.Position = hiddenPos()
main.BackgroundColor3 = C.bg; main.BorderSizePixel = 0
main.ClipsDescendants = true
main.Visible = false
Instance.new("UICorner", main).CornerRadius = UDim.new(0,8)

local mainStroke = Instance.new("UIStroke", main)
mainStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
mainStroke.LineJoinMode = Enum.LineJoinMode.Round
mainStroke.Color = Color3.new(1,1,1)
mainStroke.Thickness = 2
local mainGrad = Instance.new("UIGradient", mainStroke)
mainGrad.Color = rainbow(0)

local top = Instance.new("Frame", main)
top.Size = UDim2.new(1,0,0,36); top.BackgroundColor3 = C.bar; top.BorderSizePixel = 0
top.ZIndex = 1
local topCorner = Instance.new("UICorner", top)
topCorner.CornerRadius = UDim.new(0,8)
local topCornerFix = Instance.new("Frame", top)
topCornerFix.Size = UDim2.new(1,0,0,10)
topCornerFix.Position = UDim2.new(0,0,1,-10)
topCornerFix.BackgroundColor3 = C.bar; topCornerFix.BorderSizePixel = 0; topCornerFix.ZIndex = 1

local function mkBtn(text, w, color, parent)
	local b = Instance.new("TextButton")
	b.Size = UDim2.new(0,w,0,26)
	b.BackgroundColor3 = color; b.Text = text; b.TextColor3 = Color3.new(1,1,1)
	b.Font = Enum.Font.GothamBold; b.TextSize = 13
	Instance.new("UICorner", b).CornerRadius = UDim.new(0,5)
	b.Parent = parent
	return b
end

local function isPress(inp)
	return inp.UserInputType == Enum.UserInputType.Touch or inp.UserInputType == Enum.UserInputType.MouseButton1
end

local title = Instance.new("TextLabel", top)
title.Size = UDim2.new(0,60,1,0); title.Position = UDim2.new(0,8,0,0)
title.BackgroundTransparency = 1; title.Text = "Misg Code Editor"
title.TextColor3 = C.text; title.Font = Enum.Font.GothamBold; title.TextSize = 13
title.TextXAlignment = Enum.TextXAlignment.Left; title.Active = false; title.ZIndex = 2

local topCatcher = Instance.new("TextButton", top)
topCatcher.Size = UDim2.new(1,-70,1,0); topCatcher.Position = UDim2.new(0,0,0,0)
topCatcher.BackgroundTransparency = 1; topCatcher.Text = ""; topCatcher.AutoButtonColor = false
topCatcher.ZIndex = 0; topCatcher.Active = true
topCatcher.MouseButton1Click:Connect(function() end)

local btnRow = Instance.new("Frame", top)
btnRow.BackgroundTransparency = 1; btnRow.AnchorPoint = Vector2.new(1,0)
btnRow.Position = UDim2.new(1,-6,0,0); btnRow.Size = UDim2.new(1,-70,1,0); btnRow.ZIndex = 2
local bl = Instance.new("UIListLayout", btnRow)
bl.FillDirection = Enum.FillDirection.Horizontal; bl.HorizontalAlignment = Enum.HorizontalAlignment.Right
bl.VerticalAlignment = Enum.VerticalAlignment.Center; bl.Padding = UDim.new(0,5); bl.SortOrder = Enum.SortOrder.LayoutOrder

local runBtn   = mkBtn("▶ Run", 60, Color3.fromRGB(40,150,90), btnRow); runBtn.LayoutOrder = 0
local clearBtn = mkBtn("Clear", 48, Color3.fromRGB(150,60,60), btnRow); clearBtn.LayoutOrder = 1
local copyBtn  = mkBtn("Copy All", 66, C.btn, btnRow); copyBtn.LayoutOrder = 2
local hideBtn  = mkBtn("_", 28, Color3.fromRGB(90,90,90), btnRow); hideBtn.LayoutOrder = 3
local closeBtn = mkBtn("X", 28, Color3.fromRGB(200,50,50), btnRow); closeBtn.LayoutOrder = 4

local toolBar = Instance.new("Frame", main)
toolBar.Position = UDim2.new(0,0,0,36); toolBar.Size = UDim2.new(1,0,0,26)
toolBar.BackgroundColor3 = C.bar; toolBar.BorderSizePixel = 0

local searchBox = Instance.new("TextBox", toolBar)
searchBox.Size = UDim2.new(0,120,1,-6); searchBox.Position = UDim2.new(0,6,0,3)
searchBox.BackgroundColor3 = C.bg; searchBox.BorderSizePixel = 0
searchBox.TextColor3 = C.text; searchBox.Font = Enum.Font.Gotham; searchBox.TextSize = 12
searchBox.PlaceholderText = "Search tabs..."; searchBox.PlaceholderColor3 = Color3.fromRGB(110,110,110)
searchBox.TextXAlignment = Enum.TextXAlignment.Left; searchBox.ClearTextOnFocus = false
searchBox.Text = ""
Instance.new("UICorner", searchBox).CornerRadius = UDim.new(0,4)
local sPad = Instance.new("UIPadding", searchBox)
sPad.PaddingLeft = UDim.new(0,6)

local delAllBtn = mkBtn("Delete All", 65, Color3.fromRGB(180,50,50), toolBar)
delAllBtn.AnchorPoint = Vector2.new(1,0); delAllBtn.Position = UDim2.new(1,-6,0,0)
delAllBtn.Size = UDim2.new(0,65,0,20); delAllBtn.TextSize = 11

local tabBar = Instance.new("ScrollingFrame", main)
tabBar.Position = UDim2.new(0,0,0,62); tabBar.Size = UDim2.new(1,0,0,30)
tabBar.BackgroundColor3 = C.bar; tabBar.BorderSizePixel = 0
tabBar.ScrollBarThickness = 0; tabBar.ScrollingDirection = Enum.ScrollingDirection.X
tabBar.AutomaticCanvasSize = Enum.AutomaticSize.X; tabBar.CanvasSize = UDim2.new()
local tl = Instance.new("UIListLayout", tabBar)
tl.FillDirection = Enum.FillDirection.Horizontal; tl.Padding = UDim.new(0,2); tl.SortOrder = Enum.SortOrder.LayoutOrder

local EDITOR_POS = UDim2.new(0,0,0,92)
local scroll = Instance.new("ScrollingFrame", main)
scroll.Position = EDITOR_POS; scroll.Size = UDim2.new(1,0,1,-128)
scroll.BackgroundColor3 = C.bg; scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 6; scroll.ScrollingDirection = Enum.ScrollingDirection.XY
scroll.AutomaticCanvasSize = Enum.AutomaticSize.XY; scroll.CanvasSize = UDim2.new()

local function setupText(obj)
	obj.Position = UDim2.new(0,0,0,0); obj.Size = UDim2.new(1,-6,1,0); obj.AutomaticSize = Enum.AutomaticSize.XY
	obj.BackgroundTransparency = 1; obj.Font = Enum.Font.Code; obj.TextSize = 16
	obj.TextXAlignment = Enum.TextXAlignment.Left; obj.TextYAlignment = Enum.TextYAlignment.Top; obj.TextWrapped = false
	local p = Instance.new("UIPadding", obj)
	p.PaddingLeft = UDim.new(0,6); p.PaddingTop = UDim.new(0,4); p.PaddingBottom = UDim.new(0,40); p.PaddingRight = UDim.new(0,40)
end

local view = Instance.new("TextLabel", scroll)
setupText(view); view.RichText = true; view.Text = ""; view.TextColor3 = C.text; view.ZIndex = 1

local box = Instance.new("TextBox", scroll)
setupText(box)
box.MultiLine = true; box.ClearTextOnFocus = false; box.TextEditable = true
box.TextColor3 = C.text; box.Text = ""; box.TextTransparency = 0; box.ZIndex = 2
box.PlaceholderText = "-- type code here (Ctrl+Enter to run)"; box.PlaceholderColor3 = Color3.fromRGB(110,110,110)

local function fitText()
	local s = scroll.AbsoluteSize
	local sz = UDim2.fromOffset(math.max(s.X - 6, 10), math.max(s.Y, 10))
	view.Size = sz
	box.Size = sz
end
scroll:GetPropertyChangedSignal("AbsoluteSize"):Connect(fitText)
fitText()

local charW, charH = 9, 16
pcall(function()
	local s = TextService:GetTextSize("A", 16, Enum.Font.Code, Vector2.new(10000, 10000))
	if s.X > 0 and s.Y > 0 then charW, charH = s.X, s.Y end
end)

local function posFromPoint(pt)
	local txt = box.Text
	local x = pt.X - box.AbsolutePosition.X - 6
	local y = pt.Y - box.AbsolutePosition.Y - 4
	local lineIdx = math.max(0, math.floor(y / charH))
	local idx = 1
	local n = 0
	while n < lineIdx do
		local nl = txt:find("\n", idx, true)
		if not nl then return #txt + 1 end
		idx = nl + 1
		n += 1
	end
	local nl = txt:find("\n", idx, true) or (#txt + 1)
	local len = nl - idx
	local col = math.clamp(math.floor(x / charW + 0.5), 0, len)
	return idx + col
end

local function indentBefore(txt, upto)
	local prefix = txt:sub(1, upto - 1)
	local line = prefix:match("[^\n]*$") or ""
	local ws = line:match("^[ \t]*") or ""
	local trimmed = line:match("^%s*(.-)%s*$") or ""
	local extra = ""
	if trimmed:match("%f[%w_]then$") or trimmed:match("%f[%w_]do$") or trimmed:match("%f[%w_]else$")
		or trimmed:match("%f[%w_]repeat$") or trimmed:match("function%s*[%w_%.:]*%s*%b()$") or trimmed:match("{$") then
		extra = "    "
	end
	return ws .. extra
end

local function applyMode()
	if colorMode and not focused then view.Visible = true; box.TextTransparency = 1
	else view.Visible = false; box.TextTransparency = 0 end
end

local bottom = Instance.new("Frame", main)
bottom.Position = UDim2.new(0,0,1,-36); bottom.Size = UDim2.new(1,0,0,36)
bottom.BackgroundColor3 = C.bar; bottom.BorderSizePixel = 0; bottom.ZIndex = 1
local botCorner = Instance.new("UICorner", bottom)
botCorner.CornerRadius = UDim.new(0,8)
local botCornerFix = Instance.new("Frame", bottom)
botCornerFix.Size = UDim2.new(1,0,0,10)
botCornerFix.Position = UDim2.new(0,0,0,0)
botCornerFix.BackgroundColor3 = C.bar; botCornerFix.BorderSizePixel = 0; botCornerFix.ZIndex = 1

local status = Instance.new("TextLabel", bottom)
status.Position = UDim2.new(0,8,0,0); status.Size = UDim2.new(1,-330,1,0)
status.BackgroundTransparency = 1; status.TextColor3 = Color3.fromRGB(150,150,150)
status.Font = Enum.Font.Gotham; status.TextSize = 11; status.Text = ""; status.TextXAlignment = Enum.TextXAlignment.Left
status.TextTruncate = Enum.TextTruncate.AtEnd; status.ZIndex = 2
local function setStatus(t) status.Text = t end

local botRow = Instance.new("Frame", bottom)
botRow.BackgroundTransparency = 1; botRow.AnchorPoint = Vector2.new(1,0)
botRow.Position = UDim2.new(1,-32,0,0); botRow.Size = UDim2.new(0,270,1,0); botRow.ZIndex = 2
local bl2 = Instance.new("UIListLayout", botRow)
bl2.FillDirection = Enum.FillDirection.Horizontal; bl2.HorizontalAlignment = Enum.HorizontalAlignment.Right
bl2.VerticalAlignment = Enum.VerticalAlignment.Center; bl2.Padding = UDim.new(0,4); bl2.SortOrder = Enum.SortOrder.LayoutOrder

local consoleBtn = mkBtn("Console", 62, C.btn, botRow); consoleBtn.LayoutOrder = 1
local colorBtn = mkBtn("Color: ON", 74, Color3.fromRGB(190,120,30), botRow); colorBtn.LayoutOrder = 2
local lineBtn = mkBtn("+ Line", 70, Color3.fromRGB(40,150,90), botRow); lineBtn.LayoutOrder = 3
lineBtn.Size = UDim2.new(0,70,0,28)

colorBtn.MouseButton1Click:Connect(function()
	colorMode = not colorMode
	colorBtn.Text = colorMode and "Color: ON" or "Color: OFF"
	applyMode()
	setStatus(colorMode and "Colors show when not typing" or "Colors off")
end)

local consoleShown = UDim2.new(0.04,0,0.3,0)
local function consoleHidden() return UDim2.new(consoleShown.X.Scale, consoleShown.X.Offset, 1.2, 0) end

local consoleWin = Instance.new("Frame", gui)
consoleWin.Size = UDim2.new(0.92,0,0.7,0); consoleWin.Position = consoleHidden()
consoleWin.BackgroundColor3 = C.bg; consoleWin.BorderSizePixel = 0
consoleWin.ClipsDescendants = true; consoleWin.Visible = false; consoleWin.ZIndex = 5
Instance.new("UICorner", consoleWin).CornerRadius = UDim.new(0,8)

local consoleStroke = Instance.new("UIStroke", consoleWin)
consoleStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
consoleStroke.LineJoinMode = Enum.LineJoinMode.Round
consoleStroke.Color = Color3.new(1,1,1)
consoleStroke.Thickness = 2
local consoleGrad = Instance.new("UIGradient", consoleStroke)
consoleGrad.Color = rainbow(0.5)

local cHead = Instance.new("Frame", consoleWin)
cHead.Size = UDim2.new(1,0,0,36); cHead.BackgroundColor3 = C.bar; cHead.BorderSizePixel = 0; cHead.ZIndex = 6; cHead.Active = true
local cHeadCorner = Instance.new("UICorner", cHead)
cHeadCorner.CornerRadius = UDim.new(0,8)
local cHeadFix = Instance.new("Frame", cHead)
cHeadFix.Size = UDim2.new(1,0,0,10); cHeadFix.Position = UDim2.new(0,0,1,-10)
cHeadFix.BackgroundColor3 = C.bar; cHeadFix.BorderSizePixel = 0; cHeadFix.ZIndex = 6

local headCatcher = Instance.new("TextButton", cHead)
headCatcher.Size = UDim2.new(1,0,1,0); headCatcher.BackgroundTransparency = 1
headCatcher.Text = ""; headCatcher.AutoButtonColor = false; headCatcher.ZIndex = 6; headCatcher.Active = true
headCatcher.MouseButton1Click:Connect(function() end)

local cTitle = Instance.new("TextLabel", cHead)
cTitle.Size = UDim2.new(0,70,1,0); cTitle.Position = UDim2.new(0,8,0,0)
cTitle.BackgroundTransparency = 1; cTitle.Text = "Console"; cTitle.ZIndex = 7
cTitle.TextColor3 = C.text; cTitle.Font = Enum.Font.GothamBold; cTitle.TextSize = 13
cTitle.TextXAlignment = Enum.TextXAlignment.Left; cTitle.Active = false

local cRow = Instance.new("Frame", cHead)
cRow.BackgroundTransparency = 1; cRow.ZIndex = 7; cRow.AnchorPoint = Vector2.new(1,0)
cRow.Position = UDim2.new(1,-6,0,0); cRow.Size = UDim2.new(1,-80,1,0)
local cl = Instance.new("UIListLayout", cRow)
cl.FillDirection = Enum.FillDirection.Horizontal; cl.HorizontalAlignment = Enum.HorizontalAlignment.Right
cl.VerticalAlignment = Enum.VerticalAlignment.Center; cl.Padding = UDim.new(0,5); cl.SortOrder = Enum.SortOrder.LayoutOrder

local cClear = mkBtn("Clear", 48, Color3.fromRGB(150,60,60), cRow); cClear.LayoutOrder = 1; cClear.ZIndex = 8
local cDev = mkBtn("Dev Console", 88, C.btn, cRow); cDev.LayoutOrder = 2; cDev.ZIndex = 8
local cClose = mkBtn("Close", 48, Color3.fromRGB(90,90,90), cRow); cClose.LayoutOrder = 3; cClose.ZIndex = 8

local cScroll = Instance.new("ScrollingFrame", consoleWin)
cScroll.Position = UDim2.new(0,0,0,36); cScroll.Size = UDim2.new(1,0,1,-36)
cScroll.BackgroundTransparency = 1; cScroll.BorderSizePixel = 0; cScroll.ZIndex = 6
cScroll.ScrollBarThickness = 6; cScroll.ScrollingDirection = Enum.ScrollingDirection.Y
cScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y; cScroll.CanvasSize = UDim2.new()

local cText = Instance.new("TextLabel", cScroll)
cText.Size = UDim2.new(1,-8,0,0); cText.AutomaticSize = Enum.AutomaticSize.Y; cText.Position = UDim2.new(0,4,0,4)
cText.BackgroundTransparency = 1; cText.RichText = true; cText.TextWrapped = true
cText.Font = Enum.Font.Code; cText.TextSize = 14; cText.ZIndex = 6
cText.TextXAlignment = Enum.TextXAlignment.Left; cText.TextYAlignment = Enum.TextYAlignment.Top
cText.TextColor3 = C.text; cText.Text = ""

local logs = {}
local MAX_LOGS = 200
local LOG_COLORS = {
	[Enum.MessageType.MessageOutput] = "#D4D4D4", [Enum.MessageType.MessageInfo] = "#4FC1FF",
	[Enum.MessageType.MessageWarning] = "#E5A83B", [Enum.MessageType.MessageError] = "#F44747",
}
local function renderLogs()
	cText.Text = table.concat(logs, "\n")
	task.defer(function() pcall(function() cScroll.CanvasPosition = Vector2.new(0, 1e6) end) end)
end
local function addLog(msg, mtype)
	local col = LOG_COLORS[mtype] or "#D4D4D4"
	logs[#logs+1] = '<font color="'..col..'">'..esc(tostring(msg))..'</font>'
	if #logs > MAX_LOGS then table.remove(logs, 1) end
end
pcall(function()
	local hist = LogService:GetLogHistory()
	if hist then for _, entry in ipairs(hist) do addLog(entry.message, entry.messageType) end end
end)
renderLogs()
local logConn
do
	local ok, conn = pcall(function()
		return LogService.MessageOut:Connect(function(msg, mtype)
			addLog(msg, mtype)
			if consoleWin.Visible then renderLogs() end
		end)
	end)
	if ok then logConn = conn end
end

local consoleOpen = false
local function setConsole(open)
	if open == consoleOpen then return end
	consoleOpen = open
	if open then
		renderLogs(); consoleWin.Position = consoleHidden(); consoleWin.Visible = true
		tween(consoleWin, 0.4, {Position = consoleShown}, Enum.EasingStyle.Back)
	else
		tween(consoleWin, 0.3, {Position = consoleHidden()}, Enum.EasingStyle.Quint, Enum.EasingDirection.In).Completed:Connect(function()
			if not consoleOpen then consoleWin.Visible = false end
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

bind(RunService.RenderStepped, function()
	local rot = (tick() * 60) % 360
	mainGrad.Rotation = rot
	consoleGrad.Rotation = (360 - rot) % 360
end)

local function runCurrent()
	local t = tabs[current]
	local src = t and t.code or box.Text
	if not src or src:gsub("%s","") == "" then return end
	local loader = loadstring or load
	if not loader then return end
	local fn = loader(src, "=MisgTab")
	if not fn then return end
	pcall(fn)
end
runBtn.MouseButton1Click:Connect(runCurrent)

bind(UIS.InputBegan, function(inp, processed)
	if processed then return end
	if inp.KeyCode == Enum.KeyCode.Return and (UIS:IsKeyDown(Enum.KeyCode.LeftControl) or UIS:IsKeyDown(Enum.KeyCode.RightControl)) then
		runCurrent()
	end
end)

local function tabPath(id) return FOLDER.."/tab_"..id..".lua" end
local function saveIndex()
	if not HAS_FS then return end
	local names = {}
	for _, t in ipairs(tabs) do names[#names+1] = t.id..":"..t.name..":"..(t.fav and "1" or "0") end
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

local pendingTap = nil
box.InputBegan:Connect(function(inp)
	if not focused and isPress(inp) then
		pendingTap = { p = Vector2.new(inp.Position.X, inp.Position.Y), t = tick() }
	end
end)

local renderTabs
local switchTo

local modalBlocker = Instance.new("TextButton")
modalBlocker.Size = UDim2.new(1,0,1,0); modalBlocker.Position = UDim2.new(0,0,0,0)
modalBlocker.BackgroundTransparency = 1; modalBlocker.Text = ""; modalBlocker.AutoButtonColor = false
modalBlocker.ZIndex = 19; modalBlocker.Visible = false; modalBlocker.Parent = gui
modalBlocker.MouseButton1Click:Connect(function() end)

local renameFrame = Instance.new("Frame", gui)
renameFrame.AnchorPoint = Vector2.new(0.5,0.5); renameFrame.Position = UDim2.new(0.5,0,0.5,0)
renameFrame.Size = UDim2.new(0.8,0,0,110); renameFrame.BackgroundColor3 = C.bar; renameFrame.BorderSizePixel = 0
renameFrame.ZIndex = 20; renameFrame.Visible = false
Instance.new("UICorner", renameFrame).CornerRadius = UDim.new(0,8)
local rStroke = Instance.new("UIStroke", renameFrame)
rStroke.Color = C.btn; rStroke.Thickness = 1

local rTitle = Instance.new("TextLabel", renameFrame)
rTitle.Size = UDim2.new(1,-16,0,24); rTitle.Position = UDim2.new(0,8,0,6)
rTitle.BackgroundTransparency = 1; rTitle.Text = "Rename tab"; rTitle.ZIndex = 21
rTitle.TextColor3 = C.text; rTitle.Font = Enum.Font.GothamBold; rTitle.TextSize = 14; rTitle.TextXAlignment = Enum.TextXAlignment.Left

local renameBox = Instance.new("TextBox", renameFrame)
renameBox.Size = UDim2.new(1,-16,0,28); renameBox.Position = UDim2.new(0,8,0,34)
renameBox.BackgroundColor3 = C.bg; renameBox.BorderSizePixel = 0; renameBox.ZIndex = 21
renameBox.TextColor3 = C.text; renameBox.Font = Enum.Font.Gotham; renameBox.TextSize = 14
renameBox.ClearTextOnFocus = false; renameBox.Text = ""; renameBox.TextXAlignment = Enum.TextXAlignment.Left
Instance.new("UICorner", renameBox).CornerRadius = UDim.new(0,5)
local rPad = Instance.new("UIPadding", renameBox)
rPad.PaddingLeft = UDim.new(0,6)

local rOk = mkBtn("OK", 80, Color3.fromRGB(40,150,90), renameFrame)
rOk.AnchorPoint = Vector2.new(1,1); rOk.Position = UDim2.new(1,-8,1,-8); rOk.ZIndex = 22
local rCancel = mkBtn("Cancel", 80, Color3.fromRGB(150,60,60), renameFrame)
rCancel.AnchorPoint = Vector2.new(1,1); rCancel.Position = UDim2.new(1,-94,1,-8); rCancel.ZIndex = 22

local renameTarget = nil
local function openRename(t)
	renameTarget = t; renameBox.Text = t.name; modalBlocker.ZIndex = 19
	modalBlocker.Visible = true; renameFrame.Visible = true; renameBox:CaptureFocus()
end
local function closeRename(apply)
	if apply and renameTarget then
		local n = renameBox.Text:gsub("[\r\n]", ""):match("^%s*(.-)%s*$")
		if n and n ~= "" then renameTarget.name = n:sub(1, 24); saveIndex(); renderTabs() end
	end
	renameTarget = nil; renameFrame.Visible = false; modalBlocker.Visible = false
end
rOk.MouseButton1Click:Connect(function() closeRename(true) end)
rCancel.MouseButton1Click:Connect(function() closeRename(false) end)

local confirmFrame = Instance.new("Frame", gui)
confirmFrame.AnchorPoint = Vector2.new(0.5,0.5); confirmFrame.Position = UDim2.new(0.5,0,0.5,0)
confirmFrame.Size = UDim2.new(0.8,0,0,120); confirmFrame.BackgroundColor3 = C.bar; confirmFrame.BorderSizePixel = 0
confirmFrame.ZIndex = 30; confirmFrame.Visible = false
Instance.new("UICorner", confirmFrame).CornerRadius = UDim.new(0,8)
local cfStroke = Instance.new("UIStroke", confirmFrame)
cfStroke.Color = Color3.fromRGB(200,50,50); cfStroke.Thickness = 1

local cfText = Instance.new("TextLabel", confirmFrame)
cfText.Size = UDim2.new(1,-20,0,60); cfText.Position = UDim2.new(0,10,0,8)
cfText.BackgroundTransparency = 1; cfText.ZIndex = 31; cfText.TextColor3 = C.text
cfText.Font = Enum.Font.GothamBold; cfText.TextSize = 14; cfText.TextWrapped = true; cfText.Text = ""
cfText.TextXAlignment = Enum.TextXAlignment.Center; cfText.TextYAlignment = Enum.TextYAlignment.Center

local cfYes = mkBtn("Yes", 90, Color3.fromRGB(200,50,50), confirmFrame)
cfYes.AnchorPoint = Vector2.new(1,1); cfYes.Position = UDim2.new(0.5,-6,1,-10); cfYes.ZIndex = 32; cfYes.Size = UDim2.new(0,90,0,30)
local cfNo = mkBtn("No", 90, Color3.fromRGB(90,90,90), confirmFrame)
cfNo.AnchorPoint = Vector2.new(0,1); cfNo.Position = UDim2.new(0.5,6,1,-10); cfNo.ZIndex = 32; cfNo.Size = UDim2.new(0,90,0,30)

local confirmAction = nil

local function openConfirm(text, action)
	cfText.Text = text
	confirmAction = action
	modalBlocker.ZIndex = 29; modalBlocker.Visible = true; confirmFrame.Visible = true
	confirmFrame.Size = UDim2.new(0.7,0,0,100)
	tween(confirmFrame, 0.25, {Size = UDim2.new(0.8,0,0,120)}, Enum.EasingStyle.Back)
end

local function closeConfirm()
	confirmFrame.Visible = false; modalBlocker.Visible = false
	confirmAction = nil
end

cfYes.MouseButton1Click:Connect(function()
	local act = confirmAction
	closeConfirm()
	if act then act() end
end)
cfNo.MouseButton1Click:Connect(closeConfirm)

clearBtn.MouseButton1Click:Connect(function()
	local t = tabs[current]; local name = t and t.name or "this tab"
	openConfirm('Are You Sure To Clear "'..name..'" ?', function()
		box.Text = ""
	end)
end)

delAllBtn.MouseButton1Click:Connect(function()
	openConfirm('Are You Sure To Delete All Tabs?\n(Favorites will be kept)', function()
		local toKeep = {}
		for _, t in ipairs(tabs) do
			if t.fav then table.insert(toKeep, t)
			elseif HAS_FS and delfile then pcall(delfile, tabPath(t.id)) end
		end
		if #toKeep == 0 then
			nextId += 1
			table.insert(toKeep, {id = nextId, name = "Script 1", code = "", fav = false})
		end
		tabs = toKeep
		saveIndex()
		saveTab(tabs[1])
		switchTo(1, false)
		setStatus("Deleted non-favorite tabs")
	end)
end)

function switchTo(i, animate)
	current = math.clamp(i, 1, #tabs); lastCursor = nil; box.Text = tabs[current].code
	renderTabs(animate and current or nil)
	if animate then
		scroll.Position = UDim2.new(0,0,0,EDITOR_POS.Y.Offset + 24)
		tween(scroll, 0.3, {Position = EDITOR_POS})
	end
end

function renderTabs(animIndex)
	for _, c in ipairs(tabBar:GetChildren()) do if c:IsA("GuiObject") then c:Destroy() end end
	local lowSearch = searchText:lower()
	for i, t in ipairs(tabs) do
		if lowSearch ~= "" and not t.name:lower():find(lowSearch, 1, true) then continue end
		local showX = (not t.fav) and #tabs > 1
		local w = showX and 116 or 96
		local f = Instance.new("Frame")
		f.Size = UDim2.new(0,w,1,0); f.BorderSizePixel = 0
		f.BackgroundColor3 = (i == current) and C.tabOn or C.tab
		f.LayoutOrder = i; f.ClipsDescendants = true; f.Parent = tabBar

		local b = Instance.new("TextButton", f)
		b.Size = UDim2.new(0,76,1,0); b.BackgroundTransparency = 1
		b.Text = t.name; b.TextColor3 = t.fav and C.fav or C.text; b.Font = Enum.Font.Gotham
		b.TextSize = 13; b.TextTruncate = Enum.TextTruncate.AtEnd

		local favBtn = Instance.new("TextButton", f)
		favBtn.Size = UDim2.new(0,20,1,0); favBtn.Position = UDim2.new(0,76,0,0)
		favBtn.BackgroundTransparency = 1; favBtn.Text = "★"; favBtn.TextColor3 = t.fav and C.fav or Color3.fromRGB(90,90,90)
		favBtn.Font = Enum.Font.GothamBold; favBtn.TextSize = 14
		favBtn.MouseButton1Click:Connect(function()
			t.fav = not t.fav
			saveIndex()
			renderTabs()
		end)

		if showX then
			local x = Instance.new("TextButton", f)
			x.Size = UDim2.new(0,20,1,0); x.Position = UDim2.new(0,96,0,0)
			x.BackgroundTransparency = 1; x.Text = "x"; x.TextColor3 = Color3.fromRGB(180,180,180)
			x.Font = Enum.Font.GothamBold; x.TextSize = 12
			x.MouseButton1Click:Connect(function()
				openConfirm('Are You Sure To Delete "'..t.name..'" ?', function()
					local realIndex = table.find(tabs, t)
					if not realIndex or #tabs <= 1 then return end
					if HAS_FS and delfile then pcall(delfile, tabPath(t.id)) end
					table.remove(tabs, realIndex)
					saveIndex()
					if current > realIndex then current -= 1
					elseif current == realIndex then current = math.clamp(current, 1, #tabs) end
					switchTo(current, true)
				end)
			end)
		end

		local holdId, long = 0, false
		b.InputBegan:Connect(function(inp)
			if isPress(inp) then
				holdId += 1; local my = holdId; long = false
				task.delay(0.5, function() if holdId == my then long = true; openRename(t) end end)
			end
		end)
		b.InputEnded:Connect(function(inp) if isPress(inp) then holdId += 1 end end)
		b.MouseButton1Click:Connect(function()
			if long then long = false return end
			local realIndex = table.find(tabs, t)
			if realIndex and realIndex ~= current then switchTo(realIndex, true) end
		end)

		if animIndex == i then
			f.Size = UDim2.new(0,0,1,0)
			tween(f, 0.3, {Size = UDim2.new(0,w,1,0)}, Enum.EasingStyle.Back)
		end
	end
	local add = Instance.new("TextButton")
	add.Size = UDim2.new(0,30,1,0); add.LayoutOrder = 9999
	add.BackgroundColor3 = C.btn; add.Text = "+"; add.TextColor3 = Color3.new(1,1,1)
	add.Font = Enum.Font.GothamBold; add.TextSize = 18; add.BorderSizePixel = 0; add.Parent = tabBar
	add.MouseButton1Click:Connect(function()
		nextId += 1
		local used = {}
		for _, tb in ipairs(tabs) do
			local n = tb.name:match("^Script (%d+)$")
			if n then used[tonumber(n)] = true end
		end
		local maxN = 0
		for n in pairs(used) do maxN = math.max(maxN, n) end
		local num = maxN > 0 and maxN + 1 or 1
		tabs[#tabs+1] = {id = nextId, name = "Script "..num, code = "", fav = false}
		saveIndex(); saveTab(tabs[#tabs]); switchTo(#tabs, true)
		task.delay(0.35, function() tabBar.CanvasPosition = Vector2.new(math.huge, 0) end)
	end)
end

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
	searchText = searchBox.Text
	renderTabs()
end)

if HAS_FS and isfile(FOLDER.."/_index.txt") then
	local ok, data = pcall(readfile, FOLDER.."/_index.txt")
	if ok and data then
		for line in data:gmatch("[^\n]+") do
			local id, name, fav = line:match("^(%d+):(.+):(%d)$")
			if not id then
				id, name = line:match("^(%d+):(.+)$")
				fav = "0"
			end
			if id and isfile(tabPath(id)) then
				local ok2, code = pcall(readfile, tabPath(id))
				tabs[#tabs+1] = {id = tonumber(id), name = name, code = ok2 and code or "", fav = fav == "1"}
				nextId = math.max(nextId, tonumber(id))
			end
		end
	end
end
if #tabs == 0 then tabs[1] = {id = 1, name = "Script 1", code = "", fav = false} end

local saveToken = 0
local lastText = ""
local applying = false
box:GetPropertyChangedSignal("Text"):Connect(function()
	local new = box.Text
	if not applying and focused and #new == #lastText + 1 then
		local i = 1
		local m = math.min(#new, #lastText)
		while i <= m and new:byte(i) == lastText:byte(i) do i += 1 end
		if new:sub(i, i) == "\n" and new:sub(1, i - 1) .. new:sub(i + 1) == lastText then
			local ind = indentBefore(new, i)
			if ind ~= "" then
				applying = true
				box.Text = new:sub(1, i) .. ind .. new:sub(i + 1)
				box.CursorPosition = i + 1 + #ind
				applying = false
				return
			end
		end
	end
	lastText = new
	local ok, res = pcall(highlight, new)
	if ok then view.Text = res end
	applyMode()
	local t = tabs[current]
	if t then
		t.code = new; saveToken += 1
		local my = saveToken
		task.delay(1, function() if my == saveToken then saveTab(t) end end)
	end
end)

box.Focused:Connect(function()
	focused = true
	applyMode()
	local tap = pendingTap
	pendingTap = nil
	if tap and tick() - tap.t < 1 then
		local p = posFromPoint(tap.p)
		task.delay(0.05, function()
			if focused then
				box.CursorPosition = p
				lastCursor = p
			end
		end)
	end
end)
box.FocusLost:Connect(function()
	focused = false
	local ok, res = pcall(highlight, box.Text)
	if ok then view.Text = res end
	applyMode()
end)

lineBtn.MouseButton1Click:Connect(function()
	pendingTap = nil
	local txt = box.Text
	local pos = math.clamp(lastCursor or (#txt + 1), 1, #txt + 1)
	local ind = indentBefore(txt, pos)
	box.Text = txt:sub(1, pos - 1) .. "\n" .. ind .. txt:sub(pos)
	box:CaptureFocus()
	local newPos = pos + 1 + #ind
	task.delay(0.05, function() box.CursorPosition = newPos; lastCursor = newPos end)
	lineBtn.Size = UDim2.new(0,62,0,24)
	tween(lineBtn, 0.2, {Size = UDim2.new(0,70,0,28)}, Enum.EasingStyle.Back)
end)

copyBtn.MouseButton1Click:Connect(function()
	local fn = setclipboard or toclipboard or (Clipboard and Clipboard.set)
	if fn then pcall(fn, box.Text); copyBtn.Text = "Copied!" else copyBtn.Text = "No clip" end
	task.delay(1.2, function() copyBtn.Text = "Copy All" end)
end)

local busy = false
local mini = mkBtn("Editor", 64, C.btn, gui)
mini.Size = UDim2.new(0,64,0,30); mini.Position = UDim2.new(0,-80,0,60); mini.Visible = true

local LAYOUT_FILE = FOLDER.."/_layout.json"
local function round(n) return math.floor(n * 100 + 0.5) / 100 end
local function udToTable(ud) return { xs = round(ud.X.Scale), xo = round(ud.X.Offset), ys = round(ud.Y.Scale), yo = round(ud.Y.Offset) } end
local function tableToUd(t) return UDim2.new(t.xs or 0, t.xo or 0, t.ys or 0, t.yo or 0) end

local function saveLayout()
	if not HAS_FS then return end
	local data = {
		main = { size = udToTable(main.Size), pos = udToTable(shownPos) },
		console = { size = udToTable(consoleWin.Size), pos = udToTable(consoleShown) },
	}
	local ok, enc = pcall(function() return HttpService:JSONEncode(data) end)
	if ok and enc then pcall(writefile, LAYOUT_FILE, enc) end
end

local function loadLayout()
	if not HAS_FS or not isfile(LAYOUT_FILE) then return end
	local ok, raw = pcall(readfile, LAYOUT_FILE)
	if not ok or not raw then return end
	local ok2, data = pcall(function() return HttpService:JSONDecode(raw) end)
	if not ok2 or type(data) ~= "table" then return end
	if data.main then
		if data.main.size then main.Size = tableToUd(data.main.size) end
		if data.main.pos then shownPos = tableToUd(data.main.pos); main.Position = shownPos end
	end
	if data.console then
		if data.console.size then consoleWin.Size = tableToUd(data.console.size) end
		if data.console.pos then consoleShown = tableToUd(data.console.pos); consoleWin.Position = consoleShown end
	end
end

loadLayout()

local function hideGui()
	if busy then return end
	busy = true
	if consoleOpen then
		consoleOpen = false
		tween(consoleWin, 0.25, {Position = consoleHidden()}, Enum.EasingStyle.Quint, Enum.EasingDirection.In).Completed:Connect(function() consoleWin.Visible = false end)
		task.wait(0.12)
	end
	shownPos = main.Position
	tween(main, 0.3, {Position = hiddenPos()}, Enum.EasingStyle.Quint, Enum.EasingDirection.In).Completed:Connect(function()
		main.Visible = false; mini.Position = UDim2.new(0,-80,0,60); mini.Visible = true
		tween(mini, 0.3, {Position = UDim2.new(0,10,0,60)}, Enum.EasingStyle.Back); busy = false
	end)
end

local function showGui()
	if busy then return end
	busy = true
	tween(mini, 0.2, {Position = UDim2.new(0,-80,0,60)}).Completed:Connect(function()
		mini.Visible = false; main.Position = hiddenPos(); main.Visible = true
		tween(main, 0.45, {Position = shownPos}, Enum.EasingStyle.Back).Completed:Connect(function() busy = false end)
	end)
end

hideBtn.MouseButton1Click:Connect(hideGui)
mini.MouseButton1Click:Connect(showGui)
closeBtn.MouseButton1Click:Connect(function()
	if busy then return end
	busy = true; shownPos = main.Position
	local t = tabs[current]; if t then saveTab(t) end
	saveLayout()
	if logConn then pcall(function() logConn:Disconnect() end) end
	if consoleOpen then
		consoleOpen = false
		tween(consoleWin, 0.25, {Position = consoleHidden()}, Enum.EasingStyle.Quint, Enum.EasingDirection.In).Completed:Connect(function() consoleWin.Visible = false end)
		task.wait(0.15)
	end
	tween(main, 0.3, {Position = hiddenPos()}, Enum.EasingStyle.Quint, Enum.EasingDirection.In).Completed:Connect(function()
		for _, c in ipairs(conns) do pcall(function() c:Disconnect() end) end
		gui:Destroy()
	end)
end)

local function makeDraggable(handle, target, onMove)
	local dragging = false
	local startMouse, startPos
	handle.InputBegan:Connect(function(i)
		if isPress(i) then dragging = true; startMouse = UIS:GetMouseLocation(); startPos = target.Position end
	end)
	handle.InputEnded:Connect(function(i) if isPress(i) then dragging = false end end)
	bind(UIS.InputEnded, function(i) if isPress(i) then dragging = false end end)
	bind(UIS.TouchEnded, function() dragging = false end)
	bind(RunService.RenderStepped, function()
		if not dragging then return end
		local m = UIS:GetMouseLocation(); local d = m - startMouse
		if d.Magnitude < 0.5 then return end
		target.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		if onMove then onMove(target.Position) end
	end)
end

local function makeResizable(handle, target, minW, minH)
	local resizing = false
	local startMouse, startW, startH
	handle.InputBegan:Connect(function(i)
		if isPress(i) then resizing = true; startMouse = UIS:GetMouseLocation(); local abs = target.AbsoluteSize; startW, startH = abs.X, abs.Y end
	end)
	handle.InputEnded:Connect(function(i) if isPress(i) then resizing = false end end)
	bind(UIS.InputEnded, function(i) if isPress(i) then resizing = false end end)
	bind(UIS.TouchEnded, function() resizing = false end)
	bind(RunService.RenderStepped, function()
		if not resizing then return end
		local m = UIS:GetMouseLocation(); local d = m - startMouse
		local newW = math.max(minW, math.floor(startW + d.X + 0.5))
		local newH = math.max(minH, math.floor(startH + d.Y + 0.5))
		target.Size = UDim2.fromOffset(newW, newH)
	end)
end

local function makeResizeGrip(target, color, minW, minH)
	local grip = Instance.new("TextButton")
	grip.Size = UDim2.new(0, 26, 0, 26); grip.AnchorPoint = Vector2.new(1,1); grip.Position = UDim2.new(1, -2, 1, -2)
	grip.BackgroundColor3 = color; grip.BackgroundTransparency = 0.25
	grip.Text = "◢"; grip.TextColor3 = Color3.new(1,1,1); grip.TextSize = 13; grip.Font = Enum.Font.GothamBold
	grip.AutoButtonColor = false; grip.ZIndex = 12; grip.Parent = target
	Instance.new("UICorner", grip).CornerRadius = UDim.new(0,5)
	makeResizable(grip, target, minW or 260, minH or 180)
	return grip
end

makeDraggable(topCatcher, main, function(pos) shownPos = pos end)
makeDraggable(headCatcher, consoleWin, function(pos) consoleShown = pos end)

makeResizeGrip(main, Color3.fromRGB(220,60,60), 300, 200)
makeResizeGrip(consoleWin, Color3.fromRGB(60,200,110), 260, 180)

saveIndex()
switchTo(1)
applyMode()
setStatus(HAS_FS and "Auto-save on ("..FOLDER..")" or "Auto-save unavailable")

tween(mini, 0.4, {Position = UDim2.new(0,10,0,60)}, Enum.EasingStyle.Back)
