local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
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

local galaxyColors = {
	Color3.fromRGB(255,80,80),
	Color3.fromRGB(255,200,80),
	Color3.fromRGB(80,255,80),
	Color3.fromRGB(80,200,255),
	Color3.fromRGB(180,80,255),
	Color3.fromRGB(255,80,80),
}
local contrastColors = {
	Color3.fromRGB(255,80,200),
	Color3.fromRGB(60,140,255),
	Color3.fromRGB(255,80,200),
}

local function getLerpedColor(colors, percent)
	local total = #colors - 1
	local scaled = percent * total
	local i = math.floor(scaled) + 1
	local f = scaled - math.floor(scaled)
	if i >= #colors then return colors[#colors] end
	return colors[i]:Lerp(colors[i+1], f)
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
mainStroke.Color = galaxyColors[1]
mainStroke.Thickness = 1.75

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
