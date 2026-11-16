local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local HttpService = game:GetService("HttpService")
local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local pName = player.Name

local ENABLED, PRIORITY, REACH, SPOOF = false, true, 6.5, 2.0
local pkrOn, pkrSpeed = false, 16

local torso, ball
local touching = false
local _insideSpoof = false
local oldTouch, oldClosest
local hookedTouch, hookedClosest
local SWCfg, srvBallPos, seed, TokenUtil
local CHAR = {char = nil, reachActive = false}
local BALL_FLOOR = 5.473
local constraints, curPokerBall, _lastScan = {}, nil, nil
local fnCache = {}

getgenv().PerformanceConfig = getgenv().PerformanceConfig or {
    maxFps = 60,
    boostFps = false,
    reduceLatency = false,
    disableShadows = false,
    disableParticles = false,
    lowerTextures = false,
    clearTerrain = false,
    reduceSound = false,
}
local perf = getgenv().PerformanceConfig
getgenv().MeasureLagEnabled = getgenv().MeasureLagEnabled or false

local F = {
    hook = hookfunction or hookfunc,
    gc = getgc,
    isL = islclosure or is_l_closure,
    meta = getrawmetatable,
    ro = setreadonly,
    nc = newcclosure,
    check = checkcaller,
    info = debug and debug.getinfo
}
if not F.ro then F.ro = function(t,b) if b then (make_readonly or function() end)(t) else (make_writeable or function() end)(t) end end end
if not F.nc then F.nc = function(f) return f end end
if not F.check then F.check = function() return false end end

local AC_PATTERN = "^_%x%x%x%x%x%x%x%x%x%x%x%x$"
local acRemotes = {}

local function runGCScan()
    local gotBall = SWCfg ~= nil
    local gotToken = TokenUtil ~= nil
    local gotT25 = false
    local funcs = {}
    for _, v in pairs(F.gc(true)) do
        local tv = type(v)
        if tv == "table" then
            if not gotBall and rawget(v, "TOUCH_RADIUS") and rawget(v, "BALL_RADIUS") then
                SWCfg = v; gotBall = true
            end
            if not gotToken and type(rawget(v, "compute")) == "function" and type(rawget(v, "digest")) == "function" then
                TokenUtil = v; gotToken = true
            end
            if not gotT25 and rawget(v, "DiveTouchGui") == true and rawget(v, "SWBurstResidency") == true and rawget(v, "SWInsetProbe") == true then
                v["Rayfield"] = true; v["RayfieldLib"] = true; v["RayfieldTransparency"] = true
                v["ScarletTSW"] = true; v["ScarletScreen"] = true
                gotT25 = true
            end
        elseif tv == "function" then
            funcs[#funcs+1] = v
        end
    end
    fnCache = funcs
    return gotBall, gotToken, gotT25
end

do
    local function hookAC(remote)
        if acRemotes[remote] then return end
        acRemotes[remote] = true
        remote.OnClientEvent:Connect(function(evt, s)
            if evt == "seed" and type(s) == "string" then seed = s end
        end)
    end
    for _, c in RS:GetChildren() do
        if c:IsA("RemoteEvent") and c.Name:match(AC_PATTERN) then hookAC(c) end
    end
    RS.ChildAdded:Connect(function(c)
        if c:IsA("RemoteEvent") and c.Name:match(AC_PATTERN) then hookAC(c) end
    end)
end

local function clearPokers()
    for _, c in ipairs(constraints) do
        if c and c.Parent then pcall(function() c:Destroy() end) end
    end
    constraints = {}
end

local function applyPokers(chr, b)
    clearPokers()
    if not chr or not b then return end
    for _, d in ipairs(chr:GetDescendants()) do
        if d:IsA("BasePart") then
            local ncc = Instance.new("NoCollisionConstraint")
            ncc.Part0 = d
            ncc.Part1 = b
            ncc.Parent = d
            table.insert(constraints, ncc)
        end
    end
end

if F.meta and F.ro then
    local mt = F.meta(game)
    local oIdx = mt.__index
    local oNC = rawget(mt, "__namecall")
    local getncm = getnamecallmethod or function() return nil end
    F.ro(mt, false)

    mt.__index = F.nc(function(obj, key)
        if key == "DescendantRemoved" then return oIdx(obj, "DescendantRemoving") end

        local isPos = key == "Position" or key == "CFrame" or key == "GetPivot"

        if ENABLED and isPos then
            local chr = CHAR.char
            if chr then
                if not F.check() and not _insideSpoof then
                    if obj == torso and ball and ball.Parent then
                        local rp = oIdx(obj, "Position")
                        local bp = oIdx(ball, "Position")
                        local diff = rp - bp
                        local dist = diff.Magnitude
                        if dist > SPOOF and dist <= REACH then
                            local flat = Vector3.new(diff.X, 0, diff.Z)
                            local flatDist = flat.Magnitude
                            if flatDist >= 0.1 then
                                local torsoY = oIdx(torso, "Position").Y
                                local receiveY = bp.Y + math.clamp((torsoY - bp.Y) * 0.45, 0.4, 2.2)
                                local sp = Vector3.new(
                                    bp.X + (flat.X / flatDist) * SPOOF,
                                    receiveY,
                                    bp.Z + (flat.Z / flatDist) * SPOOF
                                )
                                local sd = (bp - sp).Magnitude
                                if sd > 3.8 then
                                    local dir = sp - bp
                                    if dir.Magnitude > 0.01 then
                                        sp = bp + dir.Unit * 3.0
                                    end
                                end
                                if key == "Position" then return sp end
                                local cf = oIdx(obj, "CFrame")
                                if key == "CFrame" then return CFrame.new(sp)*cf.Rotation end
                                local sc = CFrame.new(sp)*cf.Rotation
                                return F.nc(function() return sc end)
                            end
                        end
                    end
                end
            end
        end
        return oIdx(obj, key)
    end)

    if oNC then
        mt.__namecall = F.nc(function(self, ...)
            local m = getncm()
            if getgenv().MeasureLagEnabled and (m == "FireServer" or m == "InvokeServer") then
                local ok, n = pcall(function() return self.Name end)
                if ok and (n == "MeasureLagEvent" or n == "MeasureLag") then return end
            end
            if m == "FireServer" and acRemotes[self] then
                local args = {...}
                local payload = args[2]
                if args[1] == "beat" and type(payload) == "table" then
                    local r = payload.readings
                    if type(r) == "table" then
                        local dirty = r.exec or r.hook or r.poshook or r.gui or r.identity
                            or r.hidden or r.hitbox or r.ball or r.mover or r.decoy
                            or r.console or r.peer
                        if dirty then
                            local clean = {
                                walkSpeed = r.walkSpeed, rig = r.rig,
                                rigAll = r.rigAll, ballSize = r.ballSize,
                                hitbox = nil, exec = nil, hook = nil, poshook = nil,
                                gui = nil, identity = nil, hidden = nil, plat = nil,
                                menu = nil, peer = nil, ball = nil, mover = nil,
                                decoy = nil, console = nil
                            }
                            if seed and TokenUtil then
                                local ok, tk = pcall(TokenUtil.compute, seed, payload.counter, TokenUtil.digest(clean))
                                if ok and tk then
                                    payload.token = tk
                                    payload.readings = clean
                                    return oNC(self, ...)
                                end
                            end
                            return
                        end
                    end
                end
            end
            return oNC(self, ...)
        end)
    end
    F.ro(mt, true)
end

local function setupChar(c) CHAR.char = c; torso = c and c:FindFirstChild("UpperTorso") end
local function getTorso(c) return c and c:FindFirstChild("UpperTorso") end
local function refreshTorso()
    if not (torso and torso.Parent) then torso = getTorso(player.Character) end
    return torso
end

player.CharacterAdded:Connect(function(c)
    task.wait(0.3)
    setupChar(c)
    torso = getTorso(c)
end)

if player.Character then setupChar(player.Character); torso = getTorso(player.Character) end

RunService.Heartbeat:Connect(function()
    if ball and ball.Parent then
        local ok, p = pcall(function() return ball.CFrame.Position end)
        if ok then srvBallPos = p end
    end
    local needFind = not ball or not ball.Parent
    if not needFind then
        local ok, attr = pcall(function() return ball:GetAttribute("ClientVisualBall") end)
        if not ok or attr ~= true then needFind = true end
    end
    if needFind then
        local field = workspace:FindFirstChild("FootballField")
        if field then
            for _, v in ipairs(field:GetChildren()) do
                if v:IsA("BasePart") and v:GetAttribute("ClientVisualBall") == true then
                    ball = v; needFind = false; break
                end
            end
        end
        if needFind then
            local now = os.clock()
            if not _lastScan or now - _lastScan > 1 then
                _lastScan = now
                for _, v in ipairs(workspace:GetDescendants()) do
                    if v:IsA("BasePart") and v:GetAttribute("ClientVisualBall") == true then ball = v; break end
                end
            end
        end
    end
    if pkrOn then
        local chr = CHAR.char
        local hum = chr and chr:FindFirstChildOfClass("Humanoid")
        if hum and hum.WalkSpeed ~= pkrSpeed then hum.WalkSpeed = pkrSpeed end
        if ball and ball ~= curPokerBall then
            curPokerBall = ball
            applyPokers(chr, ball)
        end
    elseif #constraints > 0 then
        clearPokers()
        curPokerBall = nil
    end
end)

local function fname(f)
    local ok, info = pcall(F.info, f)
    return ok and info and info.name or nil
end

local function inReach()
    local bp = srvBallPos
    if not bp and ball and ball.Parent then
        local ok, p = pcall(function() return ball.CFrame.Position end)
        if ok then bp = p end
    end
    if not bp then return false end
    local t = torso or (CHAR.char and (CHAR.char:FindFirstChild("UpperTorso") or CHAR.char:FindFirstChild("HumanoidRootPart")))
    if not t then return false end
    local ok, tp = pcall(function() return t.Position end)
    if not ok then return false end
    return (bp - tp).Magnitude <= REACH
end

local function wantPriority()
    local ir = inReach()
    return (ENABLED and PRIORITY and ball and ir)
        or (pkrOn and ball and ir)
end

local function tryHooks()
    if hookedTouch and hookedClosest then return true end
    for _, v in pairs(fnCache or {}) do
        if type(v) == "function" and F.isL(v) then
            local n = fname(v)
            local ok, cs = pcall(debug.getconstants, v)
            if ok and cs then
                if not hookedTouch and (n == "touchDetect" or table.find(cs, "hasdjiodsafhdusy8tys7a7t78yTGY79TAS67SADTGDSHIAG678tasdgasasesehiekbsahigdywy8wd6sadahjY78yhHGSA7TYAST68YGh6GGY7DGWg67dgyiawgyd")) then
                    hookedTouch = v
                end
                if not hookedClosest and (n == "getClosestPlayerName" or (table.find(cs, 10000) and table.find(cs, "Magnitude"))) then
                    hookedClosest = v
                end
            end
        end
        if hookedTouch and hookedClosest then break end
    end

    if hookedTouch and not oldTouch then
        oldTouch = F.hook(hookedTouch, F.nc(function(...)
            if not ENABLED and not pkrOn then return oldTouch(...) end
            refreshTorso()
            touching = true
            local ret = {pcall(oldTouch, ...)}
            touching = false
            if ret[1] then return unpack(ret, 2) end
        end))
    end

    if hookedClosest and not oldClosest then
        oldClosest = F.hook(hookedClosest, F.nc(function(...)
            if wantPriority() then return pName end
            return oldClosest(...)
        end))
    end

    return hookedTouch and hookedClosest
end

task.spawn(function()
    task.wait(1.5)
    local b, tk, t = runGCScan()
    tryHooks()
    for _ = 1, 3 do
        if b and tk and t and hookedTouch and hookedClosest then break end
        task.wait(2)
        local nb, ntk, nt = runGCScan()
        b = b or nb; tk = tk or ntk; t = t or nt
        tryHooks()
    end
end)

local scrLock = false
local scrButtons = {}
local scrGui = Instance.new("ScreenGui")
scrGui.Name = "ScarletScreen"
scrGui.ResetOnSpawn = false
scrGui.IgnoreGuiInset = true
scrGui.Parent = CoreGui

local BW, BH = 118, 34

local function mkScrBtn(name, yi, getSt, onTog)
    local b = Instance.new("TextButton")
    b.Name = name
    b.Size = UDim2.new(0, BW, 0, BH)
    b.Position = UDim2.new(0.82, 0, 0.10, yi*(BH+5))
    b.BackgroundColor3 = Color3.fromRGB(22, 8, 18)
    b.BackgroundTransparency = 0.1
    b.BorderSizePixel = 0
    b.TextColor3 = Color3.fromRGB(240, 240, 240)
    b.Font = Enum.Font.GothamMedium
    b.TextSize = 12
    b.AutoButtonColor = false
    b.Visible = false
    b.Parent = scrGui
    table.insert(scrButtons, b)

    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 8); c.Parent = b
    local s = Instance.new("UIStroke"); s.Thickness = 1.2; s.Parent = b

    local function refresh()
        local on = getSt()
        b.Text = name .. (on and " [ON]" or " [OFF]")
        b.BackgroundColor3 = on and Color3.fromRGB(180,20,50) or Color3.fromRGB(22,8,18)
        s.Color = on and Color3.fromRGB(255,80,110) or Color3.fromRGB(90,30,60)
    end

    local dragging, dragStart, startPos, moved = false, nil, nil, false
    b.InputBegan:Connect(function(inp)
        if inp.UserInputType ~= Enum.UserInputType.MouseButton1 and inp.UserInputType ~= Enum.UserInputType.Touch then return end
        moved = false
        if not scrLock then dragging = true; dragStart = inp.Position; startPos = b.Position end
    end)
    b.InputEnded:Connect(function(inp)
        if inp.UserInputType ~= Enum.UserInputType.MouseButton1 and inp.UserInputType ~= Enum.UserInputType.Touch then return end
        if dragging then dragging = false end
    end)
    UIS.InputChanged:Connect(function(inp)
        if not dragging or scrLock then return end
        if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
            local d = inp.Position - dragStart
            if d.Magnitude > 5 then
                moved = true
                b.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
            end
        end
    end)
    b.MouseButton1Click:Connect(function()
        if moved then return end
        onTog(); refresh()
    end)

    RunService.Heartbeat:Connect(refresh)
    return b
end

local REACH_PRESETS = {4.5, 5.5, 6.5, 8.0, 10.0, 12.0}
local _rpIdx = 3

local function mkReachBtn()
    local b = Instance.new("TextButton")
    b.Name = "Reach"
    b.Size = UDim2.new(0, BW, 0, BH)
    b.Position = UDim2.new(0.82, 0, 0.10, 5*(BH+5))
    b.BackgroundColor3 = Color3.fromRGB(12, 6, 22)
    b.BackgroundTransparency = 0.1
    b.BorderSizePixel = 0
    b.TextColor3 = Color3.fromRGB(240, 240, 240)
    b.Font = Enum.Font.GothamMedium
    b.TextSize = 12
    b.AutoButtonColor = false
    b.Visible = false
    b.Parent = scrGui
    table.insert(scrButtons, b)

    local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,8); c.Parent = b
    local s = Instance.new("UIStroke"); s.Thickness = 1.2; s.Color = Color3.fromRGB(80,40,120); s.Parent = b

    local function refreshR()
        b.Text = "Reach: " .. string.format("%.1f", REACH)
        s.Color = ENABLED and Color3.fromRGB(160,80,220) or Color3.fromRGB(80,40,120)
    end

    local dragging, dragStart, startPos, moved = false, nil, nil, false
    b.InputBegan:Connect(function(inp)
        if inp.UserInputType ~= Enum.UserInputType.MouseButton1 and inp.UserInputType ~= Enum.UserInputType.Touch then return end
        moved = false
        if not scrLock then dragging = true; dragStart = inp.Position; startPos = b.Position end
    end)
    b.InputEnded:Connect(function(inp)
        if inp.UserInputType ~= Enum.UserInputType.MouseButton1 and inp.UserInputType ~= Enum.UserInputType.Touch then return end
        if dragging then dragging = false end
    end)
    UIS.InputChanged:Connect(function(inp)
        if not dragging or scrLock then return end
        if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
            local d = inp.Position - dragStart
            if d.Magnitude > 5 then
                moved = true
                b.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
            end
        end
    end)
    b.MouseButton1Click:Connect(function()
        if moved then return end
        _rpIdx = (_rpIdx % #REACH_PRESETS) + 1
        REACH = REACH_PRESETS[_rpIdx]
        if E.Reach then E.Reach:Set(REACH) end
        refreshR()
    end)

    RunService.Heartbeat:Connect(refreshR)
    return b
end

local btnHBE, btnPkr, btnReach
local POS_FILE = "ScarletTSW_positions.json"

local function savePos()
    if not writefile then return end
    local d = {}
    for _, b in ipairs(scrButtons) do
        d[b.Name] = {XS=b.Position.X.Scale, XO=b.Position.X.Offset, YS=b.Position.Y.Scale, YO=b.Position.Y.Offset}
    end
    pcall(writefile, POS_FILE, HttpService:JSONEncode(d))
end

local function loadPos()
    if not (readfile and isfile) then return end
    pcall(function()
        if isfile(POS_FILE) then
            local d = HttpService:JSONDecode(readfile(POS_FILE))
            for _, b in ipairs(scrButtons) do
                local pd = d[b.Name]
                if pd then b.Position = UDim2.new(pd.XS, pd.XO, pd.YS, pd.YO) end
            end
        end
    end)
end

UIS.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1 then task.defer(savePos) end
end)

local HW_OPTS = {"None","ButtonA","ButtonB","ButtonX","ButtonY","DPadUp","DPadDown","DPadLeft","DPadRight","ButtonL1","ButtonR1","ButtonL2","ButtonR2","ButtonL3","ButtonR3"}
local HW = {HBE="None", Priority="None", Pokers="None"}

local Window = Rayfield:CreateWindow({
    Name = "Scarlet Hub",
    LoadingTitle = "Scarlet Hub",
    LoadingSubtitle = "Scarlet TSW",
    ConfigurationSaving = {Enabled = true, FolderName = "ScarletTSW", FileName = "Config_v2"},
    Discord = {Enabled = false, Invite = "noinvitelink", RememberJoins = true},
    KeySystem = false,
    Theme = {
        TextColor = Color3.fromRGB(240,240,240),
        Background = Color3.fromRGB(15,8,20),
        Topbar = Color3.fromRGB(25,10,30),
        Shadow = Color3.fromRGB(10,0,10),
        NotificationBackground = Color3.fromRGB(20,10,25),
        NotificationActionsBackground = Color3.fromRGB(30,12,35),
        TabBackground = Color3.fromRGB(20,8,25),
        TabStroke = Color3.fromRGB(45,15,45),
        TabBackgroundSelected = Color3.fromRGB(60,15,40),
        TabTextColor = Color3.fromRGB(200,200,200),
        SelectedTabTextColor = Color3.fromRGB(255,255,255),
        ElementBackground = Color3.fromRGB(25,10,30),
        ElementBackgroundHover = Color3.fromRGB(40,15,45),
        SecondaryElementBackground = Color3.fromRGB(35,12,40),
        ElementStroke = Color3.fromRGB(50,15,50),
        SecondaryElementStroke = Color3.fromRGB(60,20,60),
        SliderBackground = Color3.fromRGB(45,15,45),
        SliderProgress = Color3.fromRGB(170,20,50),
        SliderStroke = Color3.fromRGB(65,20,55),
        ToggleBackground = Color3.fromRGB(35,10,35),
        ToggleEnabled = Color3.fromRGB(180,25,55),
        ToggleDisabled = Color3.fromRGB(50,15,50),
        ToggleEnabledStroke = Color3.fromRGB(210,30,65),
        ToggleDisabledStroke = Color3.fromRGB(60,20,60),
        ToggleEnabledOuterStroke = Color3.fromRGB(110,15,35),
        ToggleDisabledOuterStroke = Color3.fromRGB(35,10,35),
        InputBackground = Color3.fromRGB(30,10,35),
        InputStroke = Color3.fromRGB(55,15,55),
        PlaceholderColor = Color3.fromRGB(120,120,120)
    }
})

local E = {}

local tabMain = Window:CreateTab("Main", 4483362458)
tabMain:CreateSection("Hitbox Expander")
E.HBE = tabMain:CreateToggle({Name="Enable HBE", CurrentValue=false, Flag="HBE_Toggle", Callback=function(v) ENABLED = v end})
E.Priority = tabMain:CreateToggle({Name="Priority Steal", CurrentValue=true, Flag="Priority_Toggle", Callback=function(v) PRIORITY = v end})

tabMain:CreateSection("Pokers")
E.Pokers = tabMain:CreateToggle({
    Name="Enable Pokers", CurrentValue=false, Flag="Pokers_Toggle",
    Callback=function(v)
        pkrOn = v
        if not v then
            clearPokers()
            curPokerBall = nil
            local chr = CHAR.char
            local hum = chr and chr:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = 23 end
        end
    end
})

local tabCfg = Window:CreateTab("Config", 4483362458)
tabCfg:CreateSection("HBE")
E.Reach = tabCfg:CreateSlider({Name="Reach Size", Range={4,15}, Increment=0.1, Suffix="Studs", CurrentValue=6.5, Flag="Reach_Slider", Callback=function(v) REACH = v end})
E.Spoof = tabCfg:CreateSlider({Name="Spoof Distance", Range={1,3.5}, Increment=0.1, Suffix="Studs", CurrentValue=2.0, Flag="Spoof_Slider", Callback=function(v) SPOOF = v end})

tabCfg:CreateSection("Pokers")
E.PokerSpeed = tabCfg:CreateSlider({Name="Walk Speed", Range={8,23}, Increment=1, CurrentValue=16, Flag="Pokers_Speed", Callback=function(v) pkrSpeed = v end})

local tabScr = Window:CreateTab("Screen", 4483362458)
btnHBE = mkScrBtn("HBE", 0, function() return ENABLED end, function() E.HBE:Set(not ENABLED) end)
btnPkr = mkScrBtn("Pokers", 1, function() return pkrOn end, function() E.Pokers:Set(not pkrOn) end)
btnReach = mkReachBtn()
loadPos()

tabScr:CreateSection("Toggle Buttons")
local function addShow(label, btn, flag)
    tabScr:CreateToggle({Name="Show "..label, CurrentValue=false, Flag="Show_"..flag, Callback=function(v) btn.Visible = v end})
    tabScr:CreateButton({Name="Centre "..label, Callback=function() btn.Position = UDim2.new(0.5, -BW/2, 0.5, -BH/2); savePos() end})
end
addShow("HBE", btnHBE, "HBE")
addShow("Pokers", btnPkr, "Pokers")

tabScr:CreateSection("Reach Button")
tabScr:CreateToggle({Name="Show Reach", CurrentValue=false, Flag="Show_Reach", Callback=function(v) btnReach.Visible = v end})
tabScr:CreateButton({Name="Centre Reach", Callback=function() btnReach.Position = UDim2.new(0.5, -BW/2, 0.5, -BH/2); savePos() end})

tabScr:CreateSection("Position Control")
tabScr:CreateToggle({Name="Lock Screen", CurrentValue=false, Flag="Screen_Lock", Callback=function(v) scrLock = v end})
tabScr:CreateButton({Name="Save Positions", Callback=function() savePos() end})

tabScr:CreateSection("Console")
tabScr:CreateButton({Name="Print Status", Callback=function()
    print("[Scarlet] HBE="..tostring(ENABLED).." Priority="..tostring(PRIORITY).." Reach="..REACH)
    print("[Scarlet] Pokers="..tostring(pkrOn))
    print("[Scarlet] Ball="..tostring(ball and ball.Name or "nil").." BallPos="..tostring(srvBallPos))
    print("[Scarlet] Hooks: touch="..tostring(hookedTouch ~= nil).." closest="..tostring(hookedClosest ~= nil))
    print("[Scarlet] Seed="..tostring(seed ~= nil).." TokenUtil="..tostring(TokenUtil ~= nil).." SWBallConfig="..tostring(SWCfg ~= nil))
end})
tabScr:CreateButton({Name="Clear Ball Ref", Callback=function() ball = nil; srvBallPos = nil; print("[Scarlet] Ball ref cleared") end})
tabScr:CreateButton({Name="Rescan GC", Callback=function()
    local b, tk, t = runGCScan()
    tryHooks()
    print("[Scarlet] GC rescan - ball="..tostring(b).." token="..tostring(tk).." t25="..tostring(t).." hooks="..tostring(hookedTouch ~= nil and hookedClosest ~= nil))
end})

local tabPerf = Window:CreateTab("Performance", 4483362458)
tabPerf:CreateSection("Framerate")
tabPerf:CreateToggle({Name="Unlock FPS Cap", CurrentValue=perf.boostFps, Flag="UnlockFPS", Callback=function(v) perf.boostFps=v; if setfpscap then pcall(function() setfpscap(v and perf.maxFps or 60) end) end end})
tabPerf:CreateSlider({Name="Maximum FPS", Range={60,360}, Increment=10, CurrentValue=perf.maxFps, Flag="MaxFPS", Callback=function(v) perf.maxFps=math.floor(v); if setfpscap and perf.boostFps then pcall(function() setfpscap(perf.maxFps) end) end end})

tabPerf:CreateSection("Renderer Bypass")
tabPerf:CreateToggle({Name="Disable Global Shadows", CurrentValue=perf.disableShadows, Flag="NoShadows", Callback=function(v) perf.disableShadows=v; pcall(function() Lighting.GlobalShadows=not v end) end})
tabPerf:CreateToggle({Name="Disable Particle Emitters", CurrentValue=perf.disableParticles, Flag="NoParticles", Callback=function(v) perf.disableParticles=v end})
tabPerf:CreateToggle({Name="Flatten Textures", CurrentValue=perf.lowerTextures, Flag="LowTex", Callback=function(v)
    perf.lowerTextures=v
    if v then
        pcall(function()
            for _, d in pairs(workspace:GetDescendants()) do
                if d:IsA("Decal") or d:IsA("Texture") then d.Transparency = 1
                elseif d:IsA("BasePart") and d.Material ~= Enum.Material.SmoothPlastic then d.Material = Enum.Material.SmoothPlastic end
            end
        end)
    end
end})
tabPerf:CreateToggle({Name="Mute Ambient Sounds", CurrentValue=perf.reduceSound, Flag="MuteAmbient", Callback=function(v)
    perf.reduceSound=v
    pcall(function()
        for _, s in pairs(SoundService:GetDescendants()) do
            if s:IsA("Sound") then s.Volume = v and 0 or 0.5 end
        end
    end)
end})
tabPerf:CreateToggle({Name="Network Latency Reduction", CurrentValue=perf.reduceLatency, Flag="ReduceLatency", Callback=function(v) perf.reduceLatency=v end})
tabPerf:CreateToggle({Name="Clear Terrain Effects", CurrentValue=perf.clearTerrain, Flag="ClearTerrain", Callback=function(v) perf.clearTerrain=v end})
tabPerf:CreateToggle({Name="Ping Spoof (Measure Lag)", CurrentValue=false, Flag="PingSpoof", Callback=function(v) getgenv().MeasureLagEnabled=v end})

local tabKeys = Window:CreateTab("Keybinds", 4483362458)
tabKeys:CreateSection("Keyboard / Mouse")
tabKeys:CreateKeybind({Name="HBE", Value="None", Flag="KB_HBE", Callback=function() E.HBE:Set(not ENABLED) end})
tabKeys:CreateKeybind({Name="Priority Steal", Value="None", Flag="KB_Priority", Callback=function() E.Priority:Set(not PRIORITY) end})
tabKeys:CreateKeybind({Name="Pokers", Value="None", Flag="KB_Pokers", Callback=function() E.Pokers:Set(not pkrOn) end})

tabKeys:CreateSection("Controller")
local function hwDrop(label, key, flag)
    tabKeys:CreateDropdown({Name=label.." (Controller)", Flag="HW_"..flag, Options=HW_OPTS, CurrentOption={"None"}, Callback=function(v) HW[key] = type(v) == "table" and v[1] or v end})
end
hwDrop("HBE", "HBE", "HBE")
hwDrop("Priority Steal", "Priority", "Priority")
hwDrop("Pokers", "Pokers", "Pokers")

UIS.InputBegan:Connect(function(inp, proc)
    if proc then return end
    if inp.UserInputType ~= Enum.UserInputType.Gamepad1 then return end
    local k = inp.KeyCode.Name
    if k == HW.HBE and k ~= "None" then E.HBE:Set(not ENABLED) end
    if k == HW.Priority and k ~= "None" then E.Priority:Set(not PRIORITY) end
    if k == HW.Pokers and k ~= "None" then E.Pokers:Set(not pkrOn) end
end)

task.spawn(function()
    if setfpscap and perf.boostFps then pcall(function() setfpscap(perf.maxFps) end) end
end)

task.spawn(function()
    if perf.disableShadows then pcall(function() Lighting.GlobalShadows=false end) end
    if perf.reduceSound then pcall(function() for _,s in pairs(SoundService:GetDescendants()) do if s:IsA("Sound") then s.Volume=0 end end end) end
end)

task.spawn(function()
    while task.wait(0.5) do
        if perf.disableParticles then
            pcall(function()
                for _, v in pairs(workspace:GetDescendants()) do
                    if v:IsA("ParticleEmitter") or v:IsA("Smoke") or v:IsA("Fire") then v.Enabled = false end
                end
            end)
        end
        if perf.reduceLatency then
            pcall(function()
                local char = player.Character
                if char then
                    for _, v in pairs(char:GetDescendants()) do
                        if v:IsA("BasePart") then v.CastShadow = false end
                    end
                end
            end)
        end
        if perf.clearTerrain then
            pcall(function()
                workspace.Terrain.WaterWaveSize = 0
                workspace.Terrain.WaterWaveSpeed = 0
                workspace.Terrain.WaterReflectance = 0
                workspace.Terrain.WaterTransparency = 1
            end)
        end
    end
end)

Rayfield:LoadConfiguration()