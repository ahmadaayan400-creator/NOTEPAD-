--[[
AAYAN V3 | SMART STUDIO
Premium Notepad + Drawing Lab starter
Roblox client-side Lua; session-only (no Save/Load/autosave).
Clipboard support depends on executor environment.
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
if not player then return end
local playerGui = player:WaitForChild("PlayerGui")

local old = playerGui:FindFirstChild("AAYAN_SMART_STUDIO")
if old then old:Destroy() end

local C = {
    bg = Color3.fromRGB(8, 11, 24),
    panel = Color3.fromRGB(17, 22, 42),
    panel2 = Color3.fromRGB(26, 32, 58),
    cyan = Color3.fromRGB(0, 235, 255),
    blue = Color3.fromRGB(55, 115, 255),
    purple = Color3.fromRGB(165, 75, 255),
    white = Color3.fromRGB(238, 245, 255),
    muted = Color3.fromRGB(135, 155, 185),
    red = Color3.fromRGB(255, 75, 105),
    green = Color3.fromRGB(70, 255, 170),
}
local selectedColor = C.cyan
local secondaryColor = C.purple
local brushSize, currentFontSize = 4, 18
local currentFont = Enum.Font.Gotham
local currentTool, activeTab = "Brush", "NOTEPAD"
local drawingBackground = Color3.fromRGB(12, 17, 32)
local gridEnabled = false
local drawingObjects, redoObjects, connections = {}, {}, {}
local selectedTemplate, templateScale = nil, 1
local confirmClear, minimized = false, false
local drawingInput, drawingStart, drawingLast, drawingStroke
local destroyed = false

local function connect(signal, callback)
    local c = signal:Connect(callback)
    table.insert(connections, c)
    return c
end
local function make(className, props, parent)
    local obj = Instance.new(className)
    for k, v in pairs(props or {}) do obj[k] = v end
    obj.Parent = parent
    return obj
end
local function round(obj, radius)
    make("UICorner", {CornerRadius = UDim.new(0, radius or 8)}, obj)
end
local function outline(obj, color, thickness, transparency)
    return make("UIStroke", {
        Color = color or C.cyan, Thickness = thickness or 1,
        Transparency = transparency or 0
    }, obj)
end
local function label(parent, text, size, pos, fontSize, color)
    return make("TextLabel", {
        BackgroundTransparency = 1, Position = pos or UDim2.new(),
        Size = size or UDim2.new(1, 0, 0, 25), Text = text or "",
        TextColor3 = color or C.white, Font = Enum.Font.Gotham,
        TextSize = fontSize or 12, TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center
    }, parent)
end
local function button(parent, text, callback, size, pos, color)
    local b = make("TextButton", {
        Size = size or UDim2.new(0, 90, 0, 30),
        Position = pos or UDim2.new(), BackgroundColor3 = color or C.panel2,
        Text = text, TextColor3 = C.white, TextSize = 12,
        Font = Enum.Font.GothamSemibold, AutoButtonColor = true,
        BorderSizePixel = 0
    }, parent)
    round(b, 7)
    outline(b, color or C.cyan, 1, 0.45)
    if callback then connect(b.Activated, callback) end
    return b
end
local function textbox(parent, placeholder, size, pos, initial)
    local t = make("TextBox", {
        Size = size or UDim2.new(1, -12, 0, 32),
        Position = pos or UDim2.new(), BackgroundColor3 = C.bg,
        TextColor3 = C.white, PlaceholderColor3 = C.muted,
        PlaceholderText = placeholder or "", Text = initial or "",
        Font = Enum.Font.Gotham, TextSize = 12, ClearTextOnFocus = false,
        TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0
    }, parent)
    round(t, 6)
    outline(t, C.blue, 1, 0.65)
    return t
end

local gui = make("ScreenGui", {
    Name = "AAYAN_SMART_STUDIO", ResetOnSpawn = false,
    IgnoreGuiInset = true, DisplayOrder = 999,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling
}, playerGui)

local main = make("Frame", {
    Name = "MainWindow", Size = UDim2.new(0.94, 0, 0.84, 0),
    Position = UDim2.new(0.03, 0, 0.08, 0), BackgroundColor3 = C.bg,
    BorderSizePixel = 0, ClipsDescendants = true
}, gui)
round(main, 12)
outline(main, C.cyan, 1.5, 0.15)
make("UISizeConstraint", {
    MinSize = Vector2.new(285, 300), MaxSize = Vector2.new(850, 760)
}, main)

local top = make("Frame", {
    Size = UDim2.new(1, 0, 0, 42), BackgroundColor3 = C.panel,
    BorderSizePixel = 0
}, main)
local title = label(top, "◆ AAYAN V3 | SMART STUDIO",
    UDim2.new(1, -145, 1, 0), UDim2.new(0, 12, 0, 0), 14, C.cyan)
title.Font = Enum.Font.GothamBold
local minimizeButton = button(top, "—", nil, UDim2.new(0,32,0,28), UDim2.new(1,-108,0,7), C.blue)
local closeButton = button(top, "×", nil, UDim2.new(0,32,0,28), UDim2.new(1,-38,0,7), C.red)

-- Drag main window with mouse/touch.
local draggingMain, mainDragInput, mainDragStart, mainStartPosition = false, nil, nil, nil
connect(top.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        draggingMain, mainDragInput = true, input
        mainDragStart, mainStartPosition = input.Position, main.Position
    end
end)
connect(UserInputService.InputChanged, function(input)
    if draggingMain and (input == mainDragInput or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - mainDragStart
        main.Position = UDim2.new(mainStartPosition.X.Scale, mainStartPosition.X.Offset + delta.X,
            mainStartPosition.Y.Scale, mainStartPosition.Y.Offset + delta.Y)
    end
end)
connect(UserInputService.InputEnded, function(input)
    if input == mainDragInput or input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        draggingMain, mainDragInput = false, nil
    end
end)

local toggle = button(gui, "A3", nil, UDim2.new(0,45,0,45), UDim2.new(0,8,0.42,0), C.purple)
toggle.TextSize = 15
toggle.Font = Enum.Font.GothamBlack
round(toggle, 23)
outline(toggle, C.cyan, 2, 0)

local toggleDragging, toggleInput, toggleStart, togglePosition = false, nil, nil, nil
connect(toggle.InputBegan, function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        toggleDragging, toggleInput = true, input
        toggleStart, togglePosition = input.Position, toggle.Position
    end
end)
connect(UserInputService.InputChanged, function(input)
    if toggleDragging and (input == toggleInput or input.UserInputType == Enum.UserInputType.MouseMovement) then
        local delta = input.Position - toggleStart
        toggle.Position = UDim2.new(togglePosition.X.Scale, togglePosition.X.Offset + delta.X,
            togglePosition.Y.Scale, togglePosition.Y.Offset + delta.Y)
    end
end)
connect(UserInputService.InputEnded, function(input)
    if input == toggleInput or input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        toggleDragging, toggleInput = false, nil
    end
end)
connect(toggle.Activated, function() main.Visible = not main.Visible end)
connect(closeButton.Activated, function() main.Visible = false end)

local body
connect(minimizeButton.Activated, function()
    minimized = not minimized
    body.Visible = not minimized
    main.Size = minimized and UDim2.new(0.94,0,0,42) or UDim2.new(0.94,0,0.84,0)
end)

local tabBar = make("Frame", {
    Position = UDim2.new(0,5,0,46), Size = UDim2.new(1,-10,0,36),
    BackgroundTransparency = 1
}, main)
local tabNames = {"NOTEPAD","DRAWING LAB","TEMPLATES","COLOR LAB"}
local tabButtons, pages = {}, {}
for i, name in ipairs(tabNames) do
    tabButtons[name] = button(tabBar, name, nil, UDim2.new(0.25,-4,1,0),
        UDim2.new((i-1)*0.25,2,0,0), C.panel2)
    tabButtons[name].TextSize = 10
end
body = make("Frame", {
    Position = UDim2.new(0,5,0,87), Size = UDim2.new(1,-10,1,-92),
    BackgroundTransparency = 1
}, main)

local function createPage(name)
    local p = make("ScrollingFrame", {
        Name = name, Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1,
        BorderSizePixel = 0, ScrollBarThickness = 4, ScrollBarImageColor3 = C.cyan,
        CanvasSize = UDim2.new(0,0,0,0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false
    }, body)
    make("UIPadding", {
        PaddingLeft = UDim.new(0,3), PaddingRight = UDim.new(0,3),
        PaddingTop = UDim.new(0,3), PaddingBottom = UDim.new(0,8)
    }, p)
    pages[name] = p
    return p
end
local notePage = createPage("NOTEPAD")
local drawPage = createPage("DRAWING LAB")
local templatePage = createPage("TEMPLATES")
local colorPage = createPage("COLOR LAB")
local function switchTab(name)
    activeTab = name
    for tab, p in pairs(pages) do
        p.Visible = tab == name
        tabButtons[tab].BackgroundColor3 = tab == name and C.blue or C.panel2
    end
end
for name, b in pairs(tabButtons) do connect(b.Activated, function() switchTab(name) end) end

-- NOTEPAD
label(notePage, "SESSION NOTEPAD  /  WRITE • SEARCH • STYLE",
    UDim2.new(1,-8,0,24), nil, 12, C.cyan)
local editor = make("TextBox", {
    Position = UDim2.new(0,0,0,30), Size = UDim2.new(1,-5,0,185),
    BackgroundColor3 = C.panel, TextColor3 = C.white,
    PlaceholderText = "Start writing your notes here...", PlaceholderColor3 = C.muted,
    Text = "", ClearTextOnFocus = false, MultiLine = true, TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
    TextSize = currentFontSize, Font = currentFont, BorderSizePixel = 0
}, notePage)
round(editor,8); outline(editor,C.cyan,1,0.35)
make("UIPadding", {
    PaddingTop=UDim.new(0,8), PaddingBottom=UDim.new(0,8),
    PaddingLeft=UDim.new(0,8), PaddingRight=UDim.new(0,8)
}, editor)
local counter = label(notePage,"Characters: 0  |  Words: 0",
    UDim2.new(1,-4,0,23),UDim2.new(0,0,0,218),11,C.muted)
local function updateCounter()
    local text = editor.Text
    local words = 0
    for _ in text:gmatch("%S+") do words += 1 end
    counter.Text = "Characters: "..#text.."  |  Words: "..words
end
connect(editor:GetPropertyChangedSignal("Text"),updateCounter)
local noteActions = make("Frame", {
    Position=UDim2.new(0,0,0,244),Size=UDim2.new(1,-4,0,35),BackgroundTransparency=1
},notePage)
local function copyText(text)
    if type(setclipboard) == "function" then return pcall(setclipboard,text) end
    return false
end
button(noteActions,"NEW NOTE",function() editor.Text="";editor:CaptureFocus() end,
    UDim2.new(.25,-4,1,0),UDim2.new(0,0,0,0),C.blue)
button(noteActions,"CLEAR",function() editor.Text="" end,
    UDim2.new(.25,-4,1,0),UDim2.new(.25,2,0,0),C.red)
button(noteActions,"COPY TEXT",function()
    local ok=copyText(editor.Text)
    counter.Text=ok and "Text copied." or "Clipboard unavailable in this environment."
end,UDim2.new(.25,-4,1,0),UDim2.new(.5,2,0,0),C.purple)
button(noteActions,"SELECT ALL",function()
    editor:CaptureFocus()
    pcall(function() editor.CursorPosition=#editor.Text+1;editor.SelectionStart=1 end)
end,UDim2.new(.25,-4,1,0),UDim2.new(.75,2,0,0),C.blue)

label(notePage,"SEARCH CURRENT NOTE",UDim2.new(1,-4,0,22),UDim2.new(0,0,0,286),11,C.cyan)
local searchBox=textbox(notePage,"Enter text to find...",UDim2.new(1,-4,0,32),UDim2.new(0,0,0,310))
local searchStatus=label(notePage,"",UDim2.new(1,-4,0,22),UDim2.new(0,0,0,344),11,C.muted)
button(notePage,"FIND TEXT",function()
    local q=searchBox.Text
    if q=="" then searchStatus.Text="Type a search term first.";return end
    local startPos=editor.CursorPosition
    if startPos<1 then startPos=1 end
    local text=editor.Text
    local found=string.find(string.lower(text),string.lower(q),startPos,true)
    if not found then found=string.find(string.lower(text),string.lower(q),1,true) end
    if found then
        editor:CaptureFocus()
        pcall(function() editor.CursorPosition=found+#q;editor.SelectionStart=found end)
        searchStatus.Text="Match found at character "..found
    else searchStatus.Text="No match found." end
end,UDim2.new(0,100,0,29),UDim2.new(0,0,0,369),C.blue)

label(notePage,"FONT SIZE",UDim2.new(.25,0,0,23),UDim2.new(0,0,0,408),11,C.cyan)
local sizeBox=textbox(notePage,"8–48",UDim2.new(.3,0,0,30),UDim2.new(0,0,0,432),"18")
button(notePage,"APPLY SIZE",function()
    local n=tonumber(sizeBox.Text)
    if n and n>=8 and n<=48 then currentFontSize=math.floor(n);editor.TextSize=currentFontSize
    else sizeBox.Text=tostring(currentFontSize) end
end,UDim2.new(.3,0,0,30),UDim2.new(.32,0,0,432),C.blue)
label(notePage,"TEXT ALIGNMENT",UDim2.new(1,-4,0,23),UDim2.new(0,0,0,468),11,C.cyan)
local alignRow=make("Frame",{Position=UDim2.new(0,0,0,493),Size=UDim2.new(1,-4,0,30),BackgroundTransparency=1},notePage)
for i,a in ipairs({"Left","Center","Right"}) do
    button(alignRow,a,function() editor.TextXAlignment=Enum.TextXAlignment[a] end,
        UDim2.new(1/3,-4,1,0),UDim2.new((i-1)/3,2,0,0))
end
label(notePage,"FONT PREVIEW",UDim2.new(1,-4,0,22),UDim2.new(0,0,0,530),11,C.cyan)
local fontPreview=make("TextLabel",{
    Position=UDim2.new(0,0,0,554),Size=UDim2.new(1,-4,0,42),BackgroundColor3=C.panel,
    Text="AAYAN V3 • Smart Studio 012345",TextColor3=selectedColor,
    TextSize=currentFontSize,Font=currentFont,BorderSizePixel=0
},notePage)
round(fontPreview,7)
local fontSearch=textbox(notePage,"Search built-in fonts...",UDim2.new(1,-4,0,31),UDim2.new(0,0,0,604))
local fontList=make("ScrollingFrame",{
    Position=UDim2.new(0,0,0,640),Size=UDim2.new(1,-4,0,175),BackgroundColor3=C.panel,
    BorderSizePixel=0,ScrollBarThickness=5,ScrollBarImageColor3=C.cyan,
    CanvasSize=UDim2.new(0,0,0,0),AutomaticCanvasSize=Enum.AutomaticSize.Y
},notePage)
round(fontList,7)
make("UIListLayout",{Padding=UDim.new(0,3),SortOrder=Enum.SortOrder.LayoutOrder},fontList)
local availableFonts,fontButtons={},{}
local okFonts,enumFonts=pcall(function() return Enum.Font:GetEnumItems() end)
if okFonts then for _,f in ipairs(enumFonts) do table.insert(availableFonts,f) end end
table.sort(availableFonts,function(a,b) return a.Name<b.Name end)
local function applyFont(font)
    currentFont=font;editor.Font=font;fontPreview.Font=font;fontPreview.TextSize=currentFontSize
end
local function rebuildFonts(filter)
    for _,b in ipairs(fontButtons) do b:Destroy() end
    table.clear(fontButtons)
    local count=0;filter=string.lower(filter or "")
    for _,font in ipairs(availableFonts) do
        if string.find(string.lower(font.Name),filter,1,true) then
            count+=1
            local b
            b=button(fontList,font.Name..(font==currentFont and "  ✓" or ""),function()
                applyFont(font);rebuildFonts(fontSearch.Text)
            end,UDim2.new(1,-8,0,31),nil,font==currentFont and C.blue or C.panel2)
            b.Font=font;b.LayoutOrder=count;table.insert(fontButtons,b)
        end
    end
    if count==0 then table.insert(fontButtons,label(fontList,"No matching built-in font.",UDim2.new(1,-8,0,28),nil,11,C.muted)) end
end
connect(fontSearch:GetPropertyChangedSignal("Text"),function() rebuildFonts(fontSearch.Text) end)
rebuildFonts("")
label(notePage,"Built-in fonts detected: "..#availableFonts,UDim2.new(1,-4,0,24),UDim2.new(0,0,0,820),10,C.muted)

-- DRAWING LAB
label(drawPage,"DRAWING LAB  /  TOUCH OR MOUSE",UDim2.new(1,-5,0,24),nil,12,C.cyan)
local toolRow=make("Frame",{Position=UDim2.new(0,0,0,27),Size=UDim2.new(1,-4,0,32),BackgroundTransparency=1},drawPage)
local function setTool(tool) currentTool=tool end
for i,tool in ipairs({"Brush","Eraser","Line","Rectangle","Circle","Arrow"}) do
    button(toolRow,tool,function() setTool(tool) end,UDim2.new(1/3,-4,1,0),
        UDim2.new(((i-1)%3)/3,2,0,0))
end
local brushLabel=label(drawPage,"Brush size: 4",UDim2.new(.4,0,0,24),UDim2.new(0,0,0,64),11,C.muted)
local brushSlider=make("Frame",{Position=UDim2.new(.42,0,0,67),Size=UDim2.new(.57,-4,0,18),BackgroundColor3=C.panel2,BorderSizePixel=0},drawPage)
round(brushSlider,8)
local brushFill=make("Frame",{Size=UDim2.new(3/23,0,1,0),BackgroundColor3=C.cyan,BorderSizePixel=0},brushSlider)
round(brushFill,8)
local brushHit=make("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text=""},brushSlider)
local function setBrushFromX(x)
    local fraction=math.clamp((x-brushSlider.AbsolutePosition.X)/math.max(1,brushSlider.AbsoluteSize.X),0,1)
    brushSize=math.floor(1+fraction*23)
    brushFill.Size=UDim2.new(fraction,0,1,0);brushLabel.Text="Brush size: "..brushSize
end
connect(brushHit.InputBegan,function(input)
    if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then setBrushFromX(input.Position.X) end
end)
connect(brushHit.InputChanged,function(input)
    if input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch then
        if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) or input.UserInputType==Enum.UserInputType.Touch then setBrushFromX(input.Position.X) end
    end
end)

local gridButton=button(drawPage,"GRID: OFF",function()
    gridEnabled=not gridEnabled
end,UDim2.new(.32,-3,0,30),UDim2.new(0,0,0,92))
local bgButton=button(drawPage,"CYCLE BG",function()
    local choices={Color3.fromRGB(12,17,32),Color3.fromRGB(245,245,245),Color3.fromRGB(28,35,42),Color3.fromRGB(35,20,50)}
    local found=1
    for i,col in ipairs(choices) do if drawingBackground==col then found=i;break end end
    drawingBackground=choices[(found%#choices)+1]
end,UDim2.new(.32,-3,0,30),UDim2.new(.34,1,0,92))
local undoButton=button(drawPage,"UNDO",function()
    if #drawingObjects>0 then table.insert(redoObjects,table.remove(drawingObjects)) end
end,UDim2.new(.32,-3,0,30),UDim2.new(.68,1,0,92))
local redoButton=button(drawPage,"REDO",function()
    if #redoObjects>0 then table.insert(drawingObjects,table.remove(redoObjects)) end
end,UDim2.new(.32,-3,0,30),UDim2.new(0,0,0,126))
local clearCanvasButton
clearCanvasButton=button(drawPage,"CLEAR CANVAS",function()
    if not confirmClear then confirmClear=true;clearCanvasButton.Text="CONFIRM CLEAR?"
    else table.clear(drawingObjects);table.clear(redoObjects);confirmClear=false;clearCanvasButton.Text="CLEAR CANVAS" end
end,UDim2.new(.64,-3,0,30),UDim2.new(.34,1,0,126),C.red)

local canvas=make("Frame",{
    Position=UDim2.new(0,0,0,163),Size=UDim2.new(1,-4,0,310),
    BackgroundColor3=drawingBackground,BorderSizePixel=0,ClipsDescendants=true,Active=true
},drawPage)
round(canvas,8);outline(canvas,C.cyan,1,.35)
local gridLayer=make("Frame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Active=false,ZIndex=1},canvas)
local objectLayer=make("Frame",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Active=false,ZIndex=2},canvas)
local function clearLayer(layer) for _,child in ipairs(layer:GetChildren()) do child:Destroy() end end
local function renderGrid()
    clearLayer(gridLayer)
    if not gridEnabled then return end
    for x=24,canvas.AbsoluteSize.X,24 do
        make("Frame",{Position=UDim2.new(0,x,0,0),Size=UDim2.new(0,1,1,0),BackgroundColor3=C.cyan,BackgroundTransparency=.88,BorderSizePixel=0},gridLayer)
    end
    for y=24,canvas.AbsoluteSize.Y,24 do
        make("Frame",{Position=UDim2.new(0,0,0,y),Size=UDim2.new(1,0,0,1),BackgroundColor3=C.cyan,BackgroundTransparency=.88,BorderSizePixel=0},gridLayer)
    end
end
local function linePrimitive(parent,x1,y1,x2,y2,color,thickness)
    local dx,dy=x2-x1,y2-y1
    local len=math.sqrt(dx*dx+dy*dy)
    local obj=make("Frame",{
        AnchorPoint=Vector2.new(.5,.5),Position=UDim2.new(0,(x1+x2)/2,0,(y1+y2)/2),
        Size=UDim2.new(0,math.max(1,len),0,thickness or 3),Rotation=math.deg(math.atan2(dy,dx)),
        BackgroundColor3=color,BorderSizePixel=0
    },parent)
    round(obj,math.max(1,(thickness or 3)/2))
end
local glyphs={
    ["Smiley face"]="☺",Heart="♥",Star="★",["Lightning bolt"]="ϟ",Crown="♛",Diamond="◆",
    Flower="✿",Cloud="☁",Sun="☀",Moon="☾",["Robot face"]="▣",["Cat face"]="⌃ᴥ⌃",
    ["Game controller"]="⌘",["Sword icon"]="⚔",Shield="⬟",Rocket="♢",
    ["Planet with rings"]="◎",["Mountain landscape"]="△",["Simple house"]="⌂",
    ["Abstract geometric pattern"]="◈",["Neon spiral"]="◎",["Pixel-style character"]="▦",
    ["Roblox-inspired block character silhouette"]="▣",["Futuristic AI emblem"]="✧"
}
local function renderObject(obj,parent)
    local sx,sy=canvas.AbsoluteSize.X,canvas.AbsoluteSize.Y
    if sx<=0 or sy<=0 then return end
    local color,size=obj.color or selectedColor,obj.size or brushSize
    local function px(v) return v*sx end
    local function py(v) return v*sy end
    if obj.kind=="stroke" then
        for i=2,#obj.points do
            local a,b=obj.points[i-1],obj.points[i]
            linePrimitive(parent,px(a.x),py(a.y),px(b.x),py(b.y),color,size)
        end
    elseif obj.kind=="line" or obj.kind=="arrow" then
        local a,b=obj.a,obj.b
        linePrimitive(parent,px(a.x),py(a.y),px(b.x),py(b.y),color,size)
        if obj.kind=="arrow" then
            local angle=math.atan2(py(b.y-a.y),px(b.x-a.x))
            local head=math.max(10,size*3)
            for _,off in ipairs({2.5,-2.5}) do
                linePrimitive(parent,px(b.x),py(b.y),px(b.x)-math.cos(angle+off)*head,py(b.y)-math.sin(angle+off)*head,color,size)
            end
        end
    elseif obj.kind=="rect" or obj.kind=="circle" then
        local x1,x2=math.min(obj.a.x,obj.b.x),math.max(obj.a.x,obj.b.x)
        local y1,y2=math.min(obj.a.y,obj.b.y),math.max(obj.a.y,obj.b.y)
        local shape=make("Frame",{Position=UDim2.new(0,px(x1),0,py(y1)),Size=UDim2.new(0,math.max(1,px(x2-x1)),0,math.max(1,py(y2-y1))),BackgroundTransparency=1,BorderSizePixel=0},parent)
        outline(shape,color,math.max(1,size),0)
        if obj.kind=="circle" then round(shape,1000) end
    elseif obj.kind=="template" then
        make("TextLabel",{
            AnchorPoint=Vector2.new(.5,.5),Position=UDim2.new(0,px(obj.x),0,py(obj.y)),
            Size=UDim2.new(0,math.max(24,70*obj.scale),0,math.max(24,70*obj.scale)),
            BackgroundTransparency=1,Text=glyphs[obj.name] or "◆",TextColor3=color,
            TextSize=math.max(20,48*obj.scale),Font=Enum.Font.GothamBlack,TextWrapped=true,ZIndex=4
        },parent)
    end
end
local function redrawCanvas()
    clearLayer(objectLayer)
    canvas.BackgroundColor3=drawingBackground
    for _,obj in ipairs(drawingObjects) do renderObject(obj,objectLayer) end
    renderGrid()
    gridButton.Text=gridEnabled and "GRID: ON" or "GRID: OFF"
end
local function normalizePosition(pos)
    local abs,size=canvas.AbsolutePosition,canvas.AbsoluteSize
    return {x=math.clamp((pos.X-abs.X)/math.max(1,size.X),0,1),y=math.clamp((pos.Y-abs.Y)/math.max(1,size.Y),0,1)}
end
local function beginDrawing(input)
    if input.UserInputType~=Enum.UserInputType.MouseButton1 and input.UserInputType~=Enum.UserInputType.Touch then return end
    local p=normalizePosition(input.Position)
    drawingInput,drawingStart,drawingLast=input,p,p
    if currentTool=="Brush" or currentTool=="Eraser" then
        drawingStroke={kind="stroke",color=currentTool=="Eraser" and drawingBackground or selectedColor,size=currentTool=="Eraser" and brushSize*3 or brushSize,points={p}}
        table.insert(drawingObjects,drawingStroke);table.clear(redoObjects)
    else drawingStroke=nil end
end
local function moveDrawing(input)
    if not drawingInput then return end
    if input~=drawingInput and input.UserInputType~=Enum.UserInputType.MouseMovement then return end
    if input.UserInputType==Enum.UserInputType.MouseMovement and not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then return end
    local p=normalizePosition(input.Position);drawingLast=p
    if drawingStroke then table.insert(drawingStroke.points,p) end
    redrawCanvas()
end
local function finishDrawing(input)
    if not drawingInput then return end
    if input~=drawingInput and input.UserInputType~=Enum.UserInputType.MouseButton1 and input.UserInputType~=Enum.UserInputType.Touch then return end
    local p=normalizePosition(input.Position)
    local kinds={Line="line",Arrow="arrow",Rectangle="rect",Circle="circle"}
    if kinds[currentTool] then
        table.insert(drawingObjects,{kind=kinds[currentTool],a=drawingStart,b=p,color=selectedColor,size=brushSize})
        table.clear(redoObjects)
    elseif drawingStroke then table.insert(drawingStroke.points,p) end
    drawingInput,drawingStroke,drawingStart,drawingLast=nil,nil,nil,nil
    redrawCanvas()
end
connect(canvas.InputBegan,beginDrawing)
connect(UserInputService.InputChanged,moveDrawing)
connect(UserInputService.InputEnded,finishDrawing)
connect(gridButton.Activated,function() gridEnabled=not gridEnabled;redrawCanvas() end)
connect(bgButton.Activated,function() redrawCanvas() end)
connect(undoButton.Activated,function() redrawCanvas() end)
connect(redoButton.Activated,function() redrawCanvas() end)
connect(clearCanvasButton.Activated,function() redrawCanvas() end)
connect(canvas:GetPropertyChangedSignal("AbsoluteSize"),function() task.defer(redrawCanvas) end)

-- TEMPLATES
label(templatePage,"TEMPLATE GALLERY  /  SELECT • COLOR • SCALE • PLACE",UDim2.new(1,-5,0,30),nil,11,C.cyan)
local templates={"Smiley face","Heart","Star","Lightning bolt","Crown","Diamond","Flower","Cloud","Sun","Moon","Robot face","Cat face","Game controller","Sword icon","Shield","Rocket","Planet with rings","Mountain landscape","Simple house","Abstract geometric pattern","Neon spiral","Pixel-style character","Roblox-inspired block character silhouette","Futuristic AI emblem"}
local templateSearch=textbox(templatePage,"Search templates...",UDim2.new(1,-4,0,32),UDim2.new(0,0,0,34))
local templateScaleLabel=label(templatePage,"Template scale: 1×",UDim2.new(1,-4,0,24),UDim2.new(0,0,0,70),11,C.muted)
local scaleRow=make("Frame",{Position=UDim2.new(0,0,0,95),Size=UDim2.new(1,-4,0,30),BackgroundTransparency=1},templatePage)
for i,value in ipairs({.6,1,1.5,2}) do
    button(scaleRow,tostring(value).."×",function() templateScale=value;templateScaleLabel.Text="Template scale: "..value.."×" end,
        UDim2.new(.25,-4,1,0),UDim2.new((i-1)*.25,2,0,0))
end
button(templatePage,"PLACE SELECTED TEMPLATE",function()
    if not selectedTemplate then return end
    table.insert(drawingObjects,{kind="template",name=selectedTemplate,x=.5,y=.5,scale=templateScale,color=selectedColor})
    table.clear(redoObjects);redrawCanvas();switchTab("DRAWING LAB")
end,UDim2.new(1,-4,0,35),UDim2.new(0,0,0,132),C.purple)
local templateList=make("ScrollingFrame",{
    Position=UDim2.new(0,0,0,174),Size=UDim2.new(1,-4,0,370),BackgroundColor3=C.panel,
    BorderSizePixel=0,ScrollBarThickness=5,ScrollBarImageColor3=C.cyan,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(0,0,0,0)
},templatePage)
round(templateList,8)
make("UIGridLayout",{CellSize=UDim2.new(.48,-3,0,72),CellPadding=UDim2.new(0,4,0,4),SortOrder=Enum.SortOrder.LayoutOrder},templateList)
local templateButtons={}
local function rebuildTemplates(filter)
    for _,b in ipairs(templateButtons) do b:Destroy() end
    table.clear(templateButtons);filter=string.lower(filter or "")
    for i,name in ipairs(templates) do
        if string.find(string.lower(name),filter,1,true) then
            local b
            b=button(templateList,name,function()
                selectedTemplate=name
                for _,other in ipairs(templateButtons) do other.BackgroundColor3=C.panel2 end
                b.BackgroundColor3=C.blue
            end,UDim2.new(1,0,0,70),nil,name==selectedTemplate and C.blue or C.panel2)
            b.TextWrapped=true;b.TextSize=11;b.LayoutOrder=i;table.insert(templateButtons,b)
        end
    end
end
connect(templateSearch:GetPropertyChangedSignal("Text"),function() rebuildTemplates(templateSearch.Text) end)
rebuildTemplates("")

-- COLOR LAB
label(colorPage,"COLOR LAB  /  RGB • HSV • HEX • BLEND",UDim2.new(1,-4,0,26),nil,12,C.cyan)
local colorPreview=make("Frame",{Position=UDim2.new(0,0,0,30),Size=UDim2.new(1,-4,0,55),BackgroundColor3=selectedColor,BorderSizePixel=0},colorPage)
round(colorPreview,8);outline(colorPreview,C.white,1,.3)
local colorHex=textbox(colorPage,"#00EBFF",UDim2.new(.55,-4,0,32),UDim2.new(0,0,0,92),"#00EBFF")
local function colorToHex(col) return string.format("#%02X%02X%02X",math.floor(col.R*255+.5),math.floor(col.G*255+.5),math.floor(col.B*255+.5)) end
local function hexToColor(s)
    s=s:gsub("#","")
    if #s~=6 or not s:match("^%x%x%x%x%x%x$") then return nil end
    return Color3.fromRGB(tonumber(s:sub(1,2),16),tonumber(s:sub(3,4),16),tonumber(s:sub(5,6),16))
end
local rgbLabels,rgbValues={}, {0,235,255}
local function updateColorUI()
    colorPreview.BackgroundColor3=selectedColor;colorHex.Text=colorToHex(selectedColor);fontPreview.TextColor3=selectedColor
    for i,v in ipairs({selectedColor.R,selectedColor.G,selectedColor.B}) do
        rgbValues[i]=math.floor(v*255+.5)
        if rgbLabels[i] then rgbLabels[i].Text=({"R: ","G: ","B: "})[i]..rgbValues[i] end
    end
end
local function updateHSV()
    local h,s,v=selectedColor:ToHSV()
    hsvLabel.Text=string.format("H: %d°   S: %d%%   V: %d%%",math.floor(h*360+.5),math.floor(s*100+.5),math.floor(v*100+.5))
end
local applyHexButton=button(colorPage,"APPLY HEX",function()
    local col=hexToColor(colorHex.Text)
    if col then selectedColor=col;updateColorUI();updateHSV() else colorHex.Text="Invalid hex code" end
end,UDim2.new(.43,-4,0,32),UDim2.new(.57,0,0,92),C.blue)
label(colorPage,"RGB CHANNELS",UDim2.new(1,-4,0,22),UDim2.new(0,0,0,132),11,C.cyan)
for i,ch in ipairs({"R","G","B"}) do
    local y=158+(i-1)*56
    rgbLabels[i]=label(colorPage,ch..": "..rgbValues[i],UDim2.new(.25,0,0,22),UDim2.new(0,0,0,y),11,C.white)
    local slider=make("Frame",{Position=UDim2.new(.27,0,0,y+3),Size=UDim2.new(.72,-4,0,18),BackgroundColor3=C.panel2,BorderSizePixel=0},colorPage)
    round(slider,8)
    local fill=make("Frame",{Size=UDim2.new(rgbValues[i]/255,0,1,0),BackgroundColor3=({C.red,C.green,C.blue})[i],BorderSizePixel=0},slider)
    round(fill,8)
    local hit=make("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text=""},slider)
    local function setChannel(x)
        local fraction=math.clamp((x-slider.AbsolutePosition.X)/math.max(1,slider.AbsoluteSize.X),0,1)
        rgbValues[i]=math.floor(fraction*255+.5);fill.Size=UDim2.new(fraction,0,1,0)
        rgbLabels[i].Text=ch..": "..rgbValues[i]
        selectedColor=Color3.fromRGB(rgbValues[1],rgbValues[2],rgbValues[3])
        colorPreview.BackgroundColor3=selectedColor;colorHex.Text=colorToHex(selectedColor);fontPreview.TextColor3=selectedColor;updateHSV()
    end
    connect(hit.InputBegan,function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then setChannel(input.Position.X) end
    end)
    connect(hit.InputChanged,function(input)
        if input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.Touch then
            if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) or input.UserInputType==Enum.UserInputType.Touch then setChannel(input.Position.X) end
        end
    end)
end
label(colorPage,"HSV VALUES",UDim2.new(1,-4,0,22),UDim2.new(0,0,0,330),11,C.cyan)
local hsvLabel=label(colorPage,"H: 0°   S: 100%   V: 100%",UDim2.new(1,-4,0,25),UDim2.new(0,0,0,353),11,C.white)
local function setHSV(h,s,v) selectedColor=Color3.fromHSV(math.clamp(h,0,1),math.clamp(s,0,1),math.clamp(v,0,1));updateColorUI();updateHSV() end
local hueSlider=make("Frame",{Position=UDim2.new(0,0,0,385),Size=UDim2.new(1,-4,0,20),BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0},colorPage)
round(hueSlider,8)
for i=0,60 do make("Frame",{Position=UDim2.new(i/60,0,0,0),Size=UDim2.new(1/60,1,1,0),BackgroundColor3=Color3.fromHSV(i/60,1,1),BorderSizePixel=0},hueSlider) end
local hueHit=make("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text=""},hueSlider)
connect(hueHit.InputBegan,function(input)
    if input.UserInputType~=Enum.UserInputType.MouseButton1 and input.UserInputType~=Enum.UserInputType.Touch then return end
    local h=math.clamp((input.Position.X-hueSlider.AbsolutePosition.X)/math.max(1,hueSlider.AbsoluteSize.X),0,1)
    local _,s,v=selectedColor:ToHSV();setHSV(h,s,v)
end)
label(colorPage,"PRESET PALETTE",UDim2.new(1,-4,0,22),UDim2.new(0,0,0,418),11,C.cyan)
local presetColors={
    Color3.fromRGB(0,235,255),Color3.fromRGB(165,75,255),Color3.fromRGB(50,115,255),Color3.fromRGB(255,75,105),
    Color3.fromRGB(70,255,170),Color3.fromRGB(255,215,0),Color3.fromRGB(255,120,30),Color3.fromRGB(255,255,255),
    Color3.fromRGB(0,0,0),Color3.fromRGB(120,120,120),Color3.fromRGB(255,0,255),Color3.fromRGB(0,255,0),
    Color3.fromRGB(255,0,0),Color3.fromRGB(0,0,255),Color3.fromRGB(0,255,180),Color3.fromRGB(255,160,200),
    Color3.fromRGB(150,100,50),Color3.fromRGB(90,60,150),Color3.fromRGB(30,180,210),Color3.fromRGB(255,240,200),
    Color3.fromRGB(100,255,80),Color3.fromRGB(255,100,160),Color3.fromRGB(80,140,255),Color3.fromRGB(190,190,255)
}
local palette=make("Frame",{Position=UDim2.new(0,0,0,443),Size=UDim2.new(1,-4,0,95),BackgroundTransparency=1},colorPage)
make("UIGridLayout",{CellSize=UDim2.new(0,28,0,28),CellPadding=UDim2.new(0,5,0,5)},palette)
for _,col in ipairs(presetColors) do
    local swatch=button(palette,"",function() selectedColor=col;updateColorUI();updateHSV() end,UDim2.new(0,28,0,28),nil,col)
    swatch.BackgroundColor3=col
end
button(colorPage,"SET PRIMARY",function() updateColorUI() end,UDim2.new(.48,-3,0,32),UDim2.new(0,0,0,548),C.blue)
local secondaryButton
secondaryButton=button(colorPage,"SET SECONDARY",function() secondaryColor=selectedColor;secondaryButton.BackgroundColor3=secondaryColor end,
    UDim2.new(.48,-3,0,32),UDim2.new(.52,0,0,548),C.purple)
local blendAmount=.5
local blendLabel=label(colorPage,"BLEND AMOUNT: 50%",UDim2.new(1,-4,0,22),UDim2.new(0,0,0,587),11,C.cyan)
local blendSlider=make("Frame",{Position=UDim2.new(0,0,0,611),Size=UDim2.new(1,-4,0,20),BackgroundColor3=C.panel2,BorderSizePixel=0},colorPage)
round(blendSlider,8)
local blendFill=make("Frame",{Size=UDim2.new(.5,0,1,0),BackgroundColor3=C.purple,BorderSizePixel=0},blendSlider)
round(blendFill,8)
local blendHit=make("TextButton",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text=""},blendSlider)
connect(blendHit.InputBegan,function(input)
    if input.UserInputType~=Enum.UserInputType.MouseButton1 and input.UserInputType~=Enum.UserInputType.Touch then return end
    blendAmount=math.clamp((input.Position.X-blendSlider.AbsolutePosition.X)/math.max(1,blendSlider.AbsoluteSize.X),0,1)
    blendFill.Size=UDim2.new(blendAmount,0,1,0);blendLabel.Text="BLEND AMOUNT: "..math.floor(blendAmount*100).."%"
end)
button(colorPage,"APPLY BLEND",function()
    selectedColor=Color3.new(selectedColor.R*(1-blendAmount)+secondaryColor.R*blendAmount,
        selectedColor.G*(1-blendAmount)+secondaryColor.G*blendAmount,
        selectedColor.B*(1-blendAmount)+secondaryColor.B*blendAmount)
    updateColorUI();updateHSV()
end,UDim2.new(1,-4,0,32),UDim2.new(0,0,0,637),C.purple)
button(colorPage,"USE COLOR ON CANVAS",function() switchTab("DRAWING LAB") end,
    UDim2.new(1,-4,0,32),UDim2.new(0,0,0,675),C.blue)
label(colorPage,"GUI primitives are not a full raster/image editor.",UDim2.new(1,-4,0,35),UDim2.new(0,0,0,712),10,C.muted)

connect(gui.Destroying,function()
    if destroyed then return end
    destroyed=true
    for _,c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    table.clear(connections)
end)

switchTab("NOTEPAD")
updateCounter()
updateColorUI()
updateHSV()
redrawCanvas()
main.Position=UDim2.new(.03,0,.06,15)
TweenService:Create(main,TweenInfo.new(.25,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),
    {Position=UDim2.new(.03,0,.08,0)}):Play()
print("AAYAN V3 | SMART STUDIO initialized. Fonts detected:",#availableFonts)
