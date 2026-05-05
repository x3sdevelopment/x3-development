-- DH Customs Aim Module — Starlight UI + BulletRedirect + Animated FOV Circle

if not LPH_OBFUSCATED then
    function LPH_NO_VIRTUALIZE(f) return f end
    function LPH_JIT(f) return f end
    function LPH_JIT_MAX(f) return f end
    function LPH_NO_UPVALUES(f) return f end
    function LPH_ENCSTR(s) return s end
    function LPH_ENCNUM(n) return n end
end

local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local RS         = game:GetService("ReplicatedStorage")
local UIS        = game:GetService("UserInputService")
local Camera     = workspace.CurrentCamera
local LP         = Players.LocalPlayer

-- ══════════════════════════════════════════════════════════════════════════════
-- LOAD UI LIB (same loader as lol3.lua)
-- ══════════════════════════════════════════════════════════════════════════════
do
    local ls = rawget(_G, "loadstring") or rawget(_G, "load")
    if type(ls) == "function" then
        _G.loadstring = _G.loadstring or ls
        _G.load = _G.load or ls
    end
end

local __genv = (type(getgenv) == "function" and getgenv()) or _G
__genv.SecureMode = true
__genv.__GLASSUI_NO_DEMO = true

local Starlight = loadstring(game:HttpGet(
    LPH_ENCSTR("https://raw.githubusercontent.com/x3sdevelopment/x3-development/refs/heads/main/ui_library-obfuscated.lua")
))()
local NebulaIcons = loadstring(game:HttpGet(
    LPH_ENCSTR("https://raw.nebulasoftworks.xyz/nebula-icon-library-loader")
))()

local function runMain()
local _genv = (type(getgenv) == "function" and getgenv()) or _G
if _genv.__DH_CUSTOMS_LOADED == true then return end

-- ══════════════════════════════════════════════════════════════════════════════
-- SILENT AIM CONFIG
-- ══════════════════════════════════════════════════════════════════════════════
local AimConfig = {
    Enabled       = false,
    HitChance     = 70,
    FOVRadius     = 100,
}

-- ══════════════════════════════════════════════════════════════════════════════
-- AIMBOT CONFIG
-- ══════════════════════════════════════════════════════════════════════════════
local AimbotConfig = {
    Enabled       = false,
    ActivateKey   = "MouseButton2",
    SecondaryKey  = "None",
    HoldMode      = true,
    Smoothness    = 15,
    NonSticky     = true,
    FOVRadius     = 120,
    MaxDist       = 500,
    PrioritizeClosest = false,

    PredEnabled   = true,
    PredStrength  = 0.35,
    PredSmoothing = 0.45,

    ResolverEnabled  = false,
    ResolverMode     = "Auto",       -- Auto / Backtrack / Centroid
    BacktrackDepth   = 6,            -- frames of history to aim back
    DesyncThreshold  = 8,            -- studs/frame teleport = desync
    HistorySize      = 20,           -- ring buffer size
    UseMoveDir       = true,         -- cross-check Humanoid.MoveDirection
    ResolverSmooth   = 0.5,          -- blend factor toward resolved pos

    PartMode      = "UpperTorso",
    BlacklistParts = {},
    DuelsMode     = false,

    ShowFOV         = true,
    FOVThickness    = 2,
    FOVOpacity      = 1,
    FOVColor1       = Color3.fromRGB(0, 200, 255),
    FOVColor2       = Color3.fromRGB(255, 0, 128),
    FOVColor3       = Color3.fromRGB(128, 0, 255),

    OutlineEnabled  = true,
    OutlineThickness = 1,
    OutlineOpacity  = 0.4,
    OutlineColor    = Color3.fromRGB(255, 255, 255),
    OutlineOffset   = 3,

    AnimStyle       = "Rotating Gradient",
    AnimSpeed       = 1.5,
}

local VisualsConfig = {
    Enabled         = false,
    AimLine         = true,
    AimLineColor    = Color3.fromRGB(0, 200, 255),
    AimLineWidth    = 0.06,
    AimLineOpacity  = 0.5,

    PredLine        = true,
    PredLineColor   = Color3.fromRGB(255, 100, 50),
    PredLineWidth   = 0.05,
    PredLineOpacity = 0.4,

    VelocityLine    = true,
    VelocityColor   = Color3.fromRGB(100, 255, 100),
    VelocityWidth   = 0.04,
    VelocityOpacity = 0.35,
    VelocityScale   = 0.12,

    ESPEnabled          = false,
    ESPBox              = true,
    ESPName             = true,
    ESPHealth           = true,
    ESPDistance          = true,
    ESPWeapon           = true,
    ESPBoxColor         = Color3.fromRGB(255, 255, 255),
    ESPNameColor        = Color3.fromRGB(255, 255, 255),
    ESPDistColor        = Color3.fromRGB(200, 200, 200),
    ESPWeaponColor      = Color3.fromRGB(180, 180, 255),
    ESPHealthTop        = Color3.fromRGB(0, 255, 0),
    ESPHealthBot        = Color3.fromRGB(255, 0, 0),
    ESPMaxDist          = 1000,
    ESPFontSize         = 13,

    ChamsEnabled        = false,
    ChamsMethod         = "LayeredGlow",
    ChamsTrans          = 0,
    VisibleColor        = Color3.fromRGB(255, 50, 50),
    OccludedColor       = Color3.fromRGB(150, 0, 200),
    GlowColor           = Color3.fromRGB(0, 200, 255),
    GlowMultiplier      = 5,
}

local aimbotActive    = false
local aimbotToggled   = false
local aimbotKeyDown   = false
local currentTarget   = nil
local playerVelocity  = {}
local blacklist       = {}

local KEY_MAP = {
    MouseButton1 = Enum.UserInputType.MouseButton1,
    MouseButton2 = Enum.UserInputType.MouseButton2,
    MouseButton3 = Enum.UserInputType.MouseButton3,
    Shift        = Enum.KeyCode.LeftShift,
    Ctrl         = Enum.KeyCode.LeftControl,
    Alt          = Enum.KeyCode.LeftAlt,
    CapsLock     = Enum.KeyCode.CapsLock,
    Tab          = Enum.KeyCode.Tab,
    Q            = Enum.KeyCode.Q,
    E            = Enum.KeyCode.E,
    F            = Enum.KeyCode.F,
    X            = Enum.KeyCode.X,
    C            = Enum.KeyCode.C,
    V            = Enum.KeyCode.V,
}

local GunConfig = {
    ClipDump      = false,
    DumpDelay     = 0.06,
    RapidFire     = false,
    RapidDelay    = 0.03,
    AutoShoot     = false,
    NoRecoil      = false,
}

local KillConfig = {
    AutoKill      = false,
    SwingDelay    = 0.35,
    SingleTarget  = false,
    Depth         = 6,
}

local autoKillRunning = false
local selectedTarget  = nil
local preKillCFrame   = nil

local ActiveConnections = {}

-- ══════════════════════════════════════════════════════════════════════════════
-- RAKNET DESYNC (parity with lol3.lua — RakNet send hook, 0x1B packet filter)
-- ══════════════════════════════════════════════════════════════════════════════
local RN_AVAILABLE = pcall(function()
    return raknet.add_send_hook
end)

local RN_ENABLED     = false
local RN_MODE        = "smooth"

local RN_SM_BASE = 85;  local RN_SM_STD  = 22; local RN_SM_MIN = 12
local RN_SM_MAX  = 260; local RN_SM_LOSS = 0.04

local RN_JT_MIN  = 8;   local RN_JT_MAX    = 140; local RN_JT_LOSS  = 0.07
local RN_JT_BRST = 0.55; local RN_JT_BLEN  = 3

local RN_SP_NORM = 28;  local RN_SP_SIZE   = 420; local RN_SP_VAR   = 80
local RN_SP_PROB = 0.018; local RN_SP_DUR  = 10;  local RN_SP_LOSS  = 0.12

local RN_DR_START = 15; local RN_DR_RATE   = 4;   local RN_DR_MAX   = 200
local RN_DR_SNAP  = 0.20

local RN_CO_RATE  = 0.55; local RN_CO_ALSO = false; local RN_CO_MS   = 30

local RN_HY_BASE  = 60; local RN_HY_STD    = 18;  local RN_HY_MIN   = 10
local RN_HY_MAX   = 180; local RN_HY_CRPT   = 0.45

local RN_BU_BLOCK = 190; local RN_BU_OPEN  = 650

local RN_buBlocking  = false; local RN_buTimer  = 0
local RN_drCurrent   = 15
local RN_spInSpike   = false; local RN_spLeft   = 0
local RN_jtBurstLeft = 0
local RN_hookRef     = nil
local RN_hooked      = false
local RN_lastSentCFrame = nil -- actual CFrame at the moment the last valid packet went through

if RN_AVAILABLE then
    ActiveConnections.RN_BurstHeartbeat = RunService.Heartbeat:Connect(LPH_JIT_MAX(function(dt)
        if not RN_ENABLED or RN_MODE ~= "burst" then return end
        RN_buTimer = RN_buTimer + dt * 1000
        if RN_buBlocking then
            if RN_buTimer >= RN_BU_BLOCK then RN_buBlocking = false; RN_buTimer = 0 end
        else
            if RN_buTimer >= RN_BU_OPEN  then RN_buBlocking = true;  RN_buTimer = 0 end
        end
    end))

    local RN_gauss = LPH_JIT_MAX(function(mean, std)
        local u1 = math.max(math.random(), 1e-10)
        local u2 = math.random()
        return mean + std * (math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2))
    end)

    local function RN_snapPose()
        local c = LP and LP.Character
        if c then
            local h = c:FindFirstChild("HumanoidRootPart")
            if h then RN_lastSentCFrame = h.CFrame end
        end
    end

    RN_hookRef = LPH_JIT_MAX(function(packet)
        if not RN_ENABLED then return end
        local bytes = packet.AsArray
        if #bytes == 0 or bytes[1] ~= 0x1B then return end

        local pri = packet.Priority
        local rel = packet.Reliability
        local ch  = packet.OrderingChannel
        local function send(ms)
            packet:Block()
            task.delay(ms / 1000, function() raknet.send(bytes, pri, rel, ch) end)
        end
        local function corrupt()
            local buf = packet.AsBuffer
            buffer.writeu32(buf, 1, 0xFFFFFFFF)
            packet:SetData(buf)
        end

        local m = RN_MODE
        if m == "smooth" then
            if math.random() < RN_SM_LOSS then packet:Block(); return end
            RN_snapPose()
            send(math.max(RN_SM_MIN, math.min(RN_SM_MAX, RN_gauss(RN_SM_BASE, RN_SM_STD)))); return
        elseif m == "jitter" then
            local lr = (RN_jtBurstLeft > 0) and RN_JT_BRST or RN_JT_LOSS
            if math.random() < lr then
                RN_jtBurstLeft = math.max(0, RN_jtBurstLeft - 1) + RN_JT_BLEN
                packet:Block(); return
            end
            RN_jtBurstLeft = math.max(0, RN_jtBurstLeft - 1)
            RN_snapPose()
            send(RN_JT_MIN + math.random() * (RN_JT_MAX - RN_JT_MIN)); return
        elseif m == "spike" then
            if RN_spInSpike then
                RN_spLeft = RN_spLeft - 1
                if RN_spLeft <= 0 then RN_spInSpike = false end
                if math.random() < RN_SP_LOSS then packet:Block(); return end
                RN_snapPose()
                send(math.max(1, RN_SP_SIZE + (math.random()*2-1)*RN_SP_VAR)); return
            else
                if math.random() < RN_SP_PROB then RN_spInSpike=true; RN_spLeft=RN_SP_DUR end
                RN_snapPose()
                send(RN_SP_NORM); return
            end
        elseif m == "drift" then
            local ms = RN_drCurrent
            RN_drCurrent = RN_drCurrent + RN_DR_RATE
            if RN_drCurrent >= RN_DR_MAX then
                RN_drCurrent = RN_DR_START
                if math.random() < RN_DR_SNAP then packet:Block(); return end
            end
            RN_snapPose()
            send(ms); return
        elseif m == "corrupt" then
            if math.random() < RN_CO_RATE then
                corrupt()
                if RN_CO_ALSO then send(RN_CO_MS); return end
                return
            end
            RN_snapPose()
        elseif m == "hybrid" then
            local didCorrupt = math.random() < RN_HY_CRPT
            if didCorrupt then corrupt() else RN_snapPose() end
            send(math.max(RN_HY_MIN, math.min(RN_HY_MAX, RN_gauss(RN_HY_BASE, RN_HY_STD)))); return
        elseif m == "burst" then
            if RN_buBlocking then packet:Block(); return end
            RN_snapPose()
        end
    end)
end

-- ══════════════════════════════════════════════════════════════════════════════
-- BULLET REDIRECT CORE (from BulletRedirect.luau, integrated)
-- ══════════════════════════════════════════════════════════════════════════════
local MainEvent = RS:WaitForChild("MainEvent")

local AC_KEYWORDS = {
    "ban", "kick", "exploit", "cheat", "flag", "detect", "anticheat",
    "spoof", "invalid", "suspend", "warning", "heat", "lockdown",
    "AnticheatEffects", "ShowBanHeatWarning", "KickPlayer", "ServerBan",
    "SHOW_EXPLOITER_TAG", "EXP_HIGHLIGHT", "EXP_TAG", "LOCK_DOWN",
    "HasReadWarning", "INTERACTION_SUSPENDED",
}

local disabledACConnections = {}

local function hasACKeyword(constants)
    for _, c in constants do
        if type(c) == "string" then
            local lower = string.lower(c)
            for _, kw in AC_KEYWORDS do
                if string.find(lower, string.lower(kw)) then
                    return true, c
                end
            end
        end
    end
    return false
end

local function disableAC()
    local conns = getconnections(MainEvent.OnClientEvent)
    local count = 0
    for i, conn in conns do
        if conn.LuaConnection and conn.Function and conn.Enabled then
            local ok, constants = pcall(debug.getconstants, conn.Function)
            if ok and type(constants) == "table" then
                local suspect, match = hasACKeyword(constants)
                if suspect then
                    conn:Disable()
                    count += 1
                    disabledACConnections[#disabledACConnections + 1] = {
                        conn = conn, index = i, keyword = match
                    }
                end
            end
        end
    end
    return count
end

-- ══════════════════════════════════════════════════════════════════════════════
-- TEAMMATE DETECTION
-- ══════════════════════════════════════════════════════════════════════════════

local function getCrewID(char)
    local be = char and char:FindFirstChild("BodyEffects")
    if not be then return nil end
    local cid = be:FindFirstChild("CrewID")
    if not cid then return nil end
    local v = cid.Value
    if type(v) == "number" and v > 0 then return v end
    if type(v) == "string" and v ~= "" and v ~= "0" then return v end
    return nil
end

local function isTeammateByName(charName)
    local myChar = LP and LP.Character
    local myCrew = getCrewID(myChar)
    if not myCrew then return false end

    for _, p in Players:GetPlayers() do
        if p ~= LP and p.Character and p.Character.Name == charName then
            local theirCrew = getCrewID(p.Character)
            return theirCrew ~= nil and theirCrew == myCrew
        end
    end
    return false
end

-- ══════════════════════════════════════════════════════════════════════════════
-- DUELS DETECTION
-- ══════════════════════════════════════════════════════════════════════════════

local function getInBoxFolder()
    local wp = workspace:FindFirstChild("Players")
    return wp and wp:FindFirstChild("InBox")
end

local function isLocalPlayerInBox()
    local char = LP and LP.Character
    if not char then return false end
    local inbox = getInBoxFolder()
    return inbox and char:IsDescendantOf(inbox)
end

local DUEL_BOX_RANGE = 80

local function getDuelOpponents()
    local opponents = {}
    if not isLocalPlayerInBox() then return opponents end
    local inbox = getInBoxFolder()
    if not inbox then return opponents end

    local myChar = LP and LP.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return opponents end
    local myPos = myHRP.Position

    for _, p in Players:GetPlayers() do
        if p ~= LP and p.Character and p.Character:IsDescendantOf(inbox) then
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hrp and (hrp.Position - myPos).Magnitude <= DUEL_BOX_RANGE then
                opponents[p.Character.Name] = true
            end
        end
    end
    return opponents
end

-- Enemy target cache
local enemyPartSet   = {}
local cachedTargets  = {}
local heartbeatCount = 0
local BR_HITBOX_PARTS = {
    "Head", "UpperTorso", "LowerTorso",
    "LeftUpperArm", "LeftLowerArm", "LeftHand",
    "RightUpperArm", "RightLowerArm", "RightHand",
    "LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
    "RightUpperLeg", "RightLowerLeg", "RightFoot",
    "HumanoidRootPart",
}
local BR_DEBUG = false

local function dot(a, b) return a.X*b.X + a.Y*b.Y + a.Z*b.Z end
local function mag(v)    return math.sqrt(v.X*v.X + v.Y*v.Y + v.Z*v.Z) end

ActiveConnections.TargetCache = RunService.Heartbeat:Connect(LPH_JIT_MAX(function()
    heartbeatCount += 1
    local parts, pset = {}, {}
    for _, p in Players:GetPlayers() do
        if p ~= LP and p.Character then
            local hum = p.Character:FindFirstChild("Humanoid")
            if hum and hum.Health > 0 then
                local cn = p.Character.Name
                local sp = p.Character:FindFirstChild("SpecialParts")
                if sp then
                    for _, part in sp:GetChildren() do
                        if part:IsA("BasePart") then
                            parts[#parts+1] = {
                                part = part, pos = part.Position,
                                charName = cn, partName = part.Name,
                            }
                            pset[part] = true
                        end
                    end
                else
                    for _, name in BR_HITBOX_PARTS do
                        local part = p.Character:FindFirstChild(name)
                        if part and part:IsA("BasePart") then
                            parts[#parts+1] = {
                                part = part, pos = part.Position,
                                charName = cn, partName = name,
                            }
                            pset[part] = true
                        end
                    end
                end
            end
        end
    end
    if BR_DEBUG and heartbeatCount % 120 == 0 then
        print(string.format("[BR] cache: %d parts, %d players", #parts, #Players:GetPlayers() - 1))
    end
    cachedTargets, enemyPartSet = parts, pset
end))

local findClosestInFOV = LPH_JIT_MAX(function(origin)
    local best, bestDist = nil, math.huge
    local mousePos = UIS:GetMouseLocation()
    local duelFilter = AimbotConfig.DuelsMode and getDuelOpponents() or nil

    for _, e in cachedTargets do
        if blacklist[e.charName] then continue end
        if isTeammateByName(e.charName) then continue end
        if duelFilter and not duelFilter[e.charName] then continue end
        local screenPos, onScreen = Camera:WorldToViewportPoint(e.pos)
        if onScreen then
            local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
            if screenDist <= AimConfig.FOVRadius then
                local worldDist = mag(e.pos - origin)
                if worldDist > 1 and worldDist < bestDist then
                    best, bestDist = e, worldDist
                end
            end
        end
    end
    return best
end)

local buildIgnoreList = LPH_JIT_MAX(function()
    local ig = {}
    local gameList = rawget(_G, "GUN_IGNORE_LIST")
    if type(gameList) == "table" then
        for _, v in gameList do ig[#ig+1] = v end
    end
    if LP.Character then ig[#ig+1] = LP.Character end
    for _, name in {"Ignored", "BULLET_RAYS", "WORLD_EVENT_PARTICLES"} do
        local obj = workspace:FindFirstChild(name)
        if obj then ig[#ig+1] = obj end
    end
    for _, p in Players:GetPlayers() do
        if p ~= LP and p.Character then
            for _, child in p.Character:GetChildren() do
                if not enemyPartSet[child] and child.Name ~= "SpecialParts" then
                    ig[#ig+1] = child
                end
            end
        end
    end
    return ig
end)

local function rollHitChance()
    return math.random(1, 100) <= AimConfig.HitChance
end

-- ══════════════════════════════════════════════════════════════════════════════
-- AIMBOT CORE
-- ══════════════════════════════════════════════════════════════════════════════

local function matchesKey(input, keyName)
    if not keyName or keyName == "None" then return false end
    local mapped = KEY_MAP[keyName]
    if not mapped then return false end
    if typeof(mapped) == "EnumItem" then
        if mapped.EnumType == Enum.KeyCode then
            return input.KeyCode == mapped
        else
            return input.UserInputType == mapped
        end
    end
    return false
end

local function isKeyMatch(input)
    return matchesKey(input, AimbotConfig.ActivateKey)
        or matchesKey(input, AimbotConfig.SecondaryKey)
end

ActiveConnections.AimbotKeyDown = UIS.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if not AimbotConfig.Enabled then return end
    if not isKeyMatch(input) then return end

    if AimbotConfig.HoldMode then
        aimbotKeyDown = true
        aimbotActive = true
    else
        aimbotToggled = not aimbotToggled
        aimbotActive = aimbotToggled
        if not aimbotActive then
            currentTarget = nil
        end
    end
end)

ActiveConnections.AimbotKeyUp = UIS.InputEnded:Connect(function(input)
    if not isKeyMatch(input) then return end
    if AimbotConfig.HoldMode then
        aimbotKeyDown = false
        aimbotActive = false
        currentTarget = nil
    end
end)

local function groupTargetsByPlayer()
    local grouped = {}
    for _, e in cachedTargets do
        local cn = e.charName
        if not grouped[cn] then grouped[cn] = {} end
        grouped[cn][#grouped[cn] + 1] = e
    end
    return grouped
end

local function isPartBlacklisted(partName)
    local bl = AimbotConfig.BlacklistParts
    if not bl or #bl == 0 then return false end
    for _, name in bl do
        if name == partName then return true end
    end
    return false
end

local function filterParts(parts)
    local filtered = {}
    for _, e in parts do
        if not isPartBlacklisted(e.partName) then
            filtered[#filtered + 1] = e
        end
    end
    return #filtered > 0 and filtered or parts
end

local function pickPartForPlayer(parts, mousePos)
    for _, e in parts do
        pcall(function() e.pos = e.part.Position end)
    end

    parts = filterParts(parts)

    local mode = AimbotConfig.PartMode
    if mode == "Head" then
        for _, e in parts do
            if e.partName == "Head" then return e end
        end
        return parts[1]
    elseif mode == "UpperTorso" then
        for _, e in parts do
            if e.partName == "UpperTorso" then return e end
        end
        return parts[1]
    elseif mode == "Random" then
        return parts[math.random(1, #parts)]
    elseif mode == "Smart" then
        local myHRP = LP and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
        local myPos = myHRP and myHRP.Position
        local best, bestScore = nil, -math.huge
        for _, e in parts do
            local sp, onScreen = Camera:WorldToViewportPoint(e.pos)
            if not onScreen then continue end
            local screenDist = (Vector2.new(sp.X, sp.Y) - mousePos).Magnitude
            local vis = isVisible(e.pos, e.charName) and 1 or 0
            local partBonus = 0
            if e.partName == "UpperTorso" or e.partName == "LowerTorso" then partBonus = 2
            elseif e.partName == "Head" then partBonus = 3 end
            local worldDist = myPos and (e.pos - myPos).Magnitude or 100
            local score = vis * 50 + partBonus * 10 - screenDist * 0.3 - worldDist * 0.05
            if score > bestScore then best, bestScore = e, score end
        end
        return best or parts[1]
    else
        local best, bestDist = nil, math.huge
        for _, e in parts do
            local sp, onScreen = Camera:WorldToViewportPoint(e.pos)
            if onScreen then
                local d = (Vector2.new(sp.X, sp.Y) - mousePos).Magnitude
                if d < bestDist then best, bestDist = e, d end
            end
        end
        return best or parts[1]
    end
end

local function isVisible(targetPos, targetCharName)
    local camPos = Camera.CFrame.Position
    local dir = targetPos - camPos
    local dist = mag(dir)
    if dist < 1 then return true end

    local ig = {Camera}
    if LP.Character then ig[#ig + 1] = LP.Character end
    local ignored = workspace:FindFirstChild("Ignored")
    if ignored then ig[#ig + 1] = ignored end
    local bullets = workspace:FindFirstChild("BULLET_RAYS")
    if bullets then ig[#ig + 1] = bullets end
    local particles = workspace:FindFirstChild("WORLD_EVENT_PARTICLES")
    if particles then ig[#ig + 1] = particles end

    -- Ignore all player characters so only world geometry blocks LOS
    for _, p in Players:GetPlayers() do
        if p ~= LP and p.Character then
            ig[#ig + 1] = p.Character
        end
    end

    local ray = Ray.new(camPos, dir)
    local hitPart = workspace:FindPartOnRayWithIgnoreList(ray, ig)
    return hitPart == nil
end

local function acquireTarget()
    local mousePos = UIS:GetMouseLocation()
    local fov = AimbotConfig.FOVRadius
    local grouped = groupTargetsByPlayer()

    local myHRP = LP and LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    local myPos = myHRP and myHRP.Position

    local duelFilter = AimbotConfig.DuelsMode and getDuelOpponents() or nil

    local bestTarget = nil
    local bestScreenDist = math.huge
    local bestWorldDist  = math.huge

    for charName, parts in grouped do
        if blacklist[charName] then continue end
        if isTeammateByName(charName) then continue end
        if duelFilter and not duelFilter[charName] then continue end

        local pick = pickPartForPlayer(parts, mousePos)
        if pick then
            local sp, onScreen = Camera:WorldToViewportPoint(pick.pos)
            if onScreen then
                local screenDist = (Vector2.new(sp.X, sp.Y) - mousePos).Magnitude
                local worldDist = myPos and (pick.pos - myPos).Magnitude or 0
                if screenDist <= fov and worldDist <= AimbotConfig.MaxDist and isVisible(pick.pos) then
                    if AimbotConfig.PrioritizeClosest and myPos then
                        if worldDist < bestWorldDist then
                            bestTarget = pick
                            bestWorldDist = worldDist
                            bestScreenDist = screenDist
                        end
                    else
                        if screenDist < bestScreenDist then
                            bestTarget = pick
                            bestScreenDist = screenDist
                        end
                    end
                end
            end
        end
    end
    return bestTarget
end

local smoothedScreenPos = nil
local lastPredicted = nil

local predictionState = {}

local function getOrCreatePredState(charName)
    if not predictionState[charName] then
        predictionState[charName] = {
            lastPos = nil,
            smoothVelX = 0, smoothVelZ = 0,
            lastVelX = 0, lastVelZ = 0,
            jitter = 0,
        }
    end
    return predictionState[charName]
end

local function getCharHRP(charName)
    for _, p in Players:GetPlayers() do
        if p ~= LP and p.Character and p.Character.Name == charName then
            return p.Character:FindFirstChild("HumanoidRootPart")
        end
    end
    return nil
end

local function getCharHumanoid(charName)
    for _, p in Players:GetPlayers() do
        if p ~= LP and p.Character and p.Character.Name == charName then
            return p.Character:FindFirstChild("Humanoid")
        end
    end
    return nil
end

-- ══════════════════════════════════════════════════════════════════════════════
-- RESOLVER — position history, desync detection, backtrack, centroid, MoveDir
-- ══════════════════════════════════════════════════════════════════════════════
local resolverState = {} -- [charName] = { history, desyncScore, ... }

local function getOrCreateResolverState(charName)
    if not resolverState[charName] then
        resolverState[charName] = {
            history      = {},   -- ring buffer of {pos, tick}
            histIdx      = 0,
            desyncScore  = 0,    -- 0..1, how desynced they appear
            lastCleanPos = nil,  -- last position that wasn't a teleport
            cleanVelX    = 0,
            cleanVelZ    = 0,
            resolvedPos  = nil,
        }
    end
    return resolverState[charName]
end

local resolverPushHistory = LPH_JIT_MAX(function(rs, pos)
    local maxSize = AimbotConfig.HistorySize
    rs.histIdx = rs.histIdx + 1
    if rs.histIdx > maxSize then rs.histIdx = 1 end
    rs.history[rs.histIdx] = { pos = pos, t = tick() }
    if #rs.history > maxSize then
        for i = maxSize + 1, #rs.history do
            rs.history[i] = nil
        end
    end
end)

local resolverGetBacktrackPos = LPH_JIT_MAX(function(rs, depth)
    local count = math.min(#rs.history, depth)
    if count == 0 then return nil end
    local idx = rs.histIdx - count + 1
    if idx < 1 then idx = idx + #rs.history end
    local entry = rs.history[idx]
    return entry and entry.pos or nil
end)

local resolverGetCentroid = LPH_JIT_MAX(function(rs, depth)
    local count = math.min(#rs.history, depth)
    if count == 0 then return nil end
    local sx, sy, sz = 0, 0, 0
    local n = 0
    local idx = rs.histIdx
    for _ = 1, count do
        local entry = rs.history[idx]
        if entry then
            sx = sx + entry.pos.X
            sy = sy + entry.pos.Y
            sz = sz + entry.pos.Z
            n = n + 1
        end
        idx = idx - 1
        if idx < 1 then idx = #rs.history end
    end
    if n == 0 then return nil end
    return Vector3.new(sx / n, sy / n, sz / n)
end)

local resolvePosition = LPH_JIT_MAX(function(charName, rawPos, dt)
    if not AimbotConfig.ResolverEnabled then return rawPos end

    local rs = getOrCreateResolverState(charName)
    local threshold = AimbotConfig.DesyncThreshold

    if rs.lastCleanPos then
        local delta = rawPos - rs.lastCleanPos
        local frameDist = math.sqrt(delta.X * delta.X + delta.Z * delta.Z)
        local maxNormal = threshold * math.max(dt, 0.016)

        if frameDist > maxNormal then
            rs.desyncScore = math.min(rs.desyncScore + 0.3, 1)
        else
            rs.desyncScore = math.max(rs.desyncScore - dt * 1.5, 0)
            rs.lastCleanPos = rawPos

            local elapsed = math.max(dt, 0.001)
            rs.cleanVelX = rs.cleanVelX + ((delta.X / elapsed) - rs.cleanVelX) * 0.3
            rs.cleanVelZ = rs.cleanVelZ + ((delta.Z / elapsed) - rs.cleanVelZ) * 0.3
        end
    else
        rs.lastCleanPos = rawPos
    end

    resolverPushHistory(rs, rawPos)

    if AimbotConfig.UseMoveDir then
        local hum = getCharHumanoid(charName)
        if hum then
            local md = hum.MoveDirection
            local mdLen = math.sqrt(md.X * md.X + md.Z * md.Z)
            if mdLen > 0.1 then
                local cvLen = math.sqrt(rs.cleanVelX * rs.cleanVelX + rs.cleanVelZ * rs.cleanVelZ)
                if cvLen > 1 then
                    local dotVal = (md.X * rs.cleanVelX + md.Z * rs.cleanVelZ) / (mdLen * cvLen)
                    if dotVal < -0.3 then
                        rs.desyncScore = math.min(rs.desyncScore + 0.2, 1)
                    end
                end
            end
        end
    end

    if rs.desyncScore < 0.15 then
        rs.resolvedPos = rawPos
        return rawPos
    end

    local mode = AimbotConfig.ResolverMode
    local resolved = rawPos

    if mode == "Backtrack" then
        local bt = resolverGetBacktrackPos(rs, AimbotConfig.BacktrackDepth)
        if bt then resolved = bt end
    elseif mode == "Centroid" then
        local ct = resolverGetCentroid(rs, AimbotConfig.BacktrackDepth)
        if ct then resolved = ct end
    else -- "Auto"
        if rs.desyncScore > 0.6 then
            local ct = resolverGetCentroid(rs, AimbotConfig.BacktrackDepth)
            if ct then resolved = ct end
        else
            local bt = resolverGetBacktrackPos(rs, math.ceil(AimbotConfig.BacktrackDepth * 0.5))
            if bt then resolved = bt end
        end
    end

    local blend = AimbotConfig.ResolverSmooth * rs.desyncScore
    resolved = Vector3.new(
        rawPos.X + (resolved.X - rawPos.X) * blend,
        rawPos.Y,
        rawPos.Z + (resolved.Z - rawPos.Z) * blend
    )

    rs.resolvedPos = resolved
    return resolved
end)

local getPredictedPos = LPH_JIT_MAX(function(target, dt)
    if not AimbotConfig.PredEnabled then
        return resolvePosition(target.charName, target.pos, dt)
    end

    local hrp = getCharHRP(target.charName)
    if not hrp then return target.pos end

    local pos = resolvePosition(target.charName, target.pos, dt)
    local ps = getOrCreatePredState(target.charName)

    if ps.lastPos then
        local elapsed = dt
        if elapsed < 0.001 then elapsed = 0.016 end

        local rawVX = (pos.X - ps.lastPos.X) / elapsed
        local rawVZ = (pos.Z - ps.lastPos.Z) / elapsed

        local dotX = rawVX * ps.lastVelX
        local dotZ = rawVZ * ps.lastVelZ
        local directionChanged = (dotX < 0) or (dotZ < 0)

        if directionChanged then
            ps.jitter = math.min(ps.jitter + 0.15, 1)
        else
            ps.jitter = math.max(ps.jitter - dt * 2, 0)
        end

        local smoothAlpha = math.clamp(1 - AimbotConfig.PredSmoothing - ps.jitter * 0.4, 0.05, 0.9)

        ps.smoothVelX = ps.smoothVelX + (rawVX - ps.smoothVelX) * smoothAlpha
        ps.smoothVelZ = ps.smoothVelZ + (rawVZ - ps.smoothVelZ) * smoothAlpha

        ps.lastVelX = rawVX
        ps.lastVelZ = rawVZ
    end
    ps.lastPos = pos

    local hSpeed = math.sqrt(ps.smoothVelX * ps.smoothVelX + ps.smoothVelZ * ps.smoothVelZ)
    if hSpeed < 2 then return pos end

    local jitterScale = math.clamp(1 - ps.jitter * 0.8, 0.1, 1)
    local lookAhead = dt * AimbotConfig.PredStrength * 10 * jitterScale

    return Vector3.new(
        pos.X + ps.smoothVelX * lookAhead,
        pos.Y,
        pos.Z + ps.smoothVelZ * lookAhead
    )
end)

ActiveConnections.AimbotLoop = RunService.RenderStepped:Connect(LPH_JIT_MAX(function(dt)
    if not AimbotConfig.Enabled or not aimbotActive then
        currentTarget = nil
        smoothedScreenPos = nil
        return
    end

    if currentTarget then
        local alive = false
        pcall(function()
            alive = currentTarget.part and currentTarget.part.Parent ~= nil
        end)
        if not alive then
            currentTarget = nil
            smoothedScreenPos = nil
        end
    end

    -- Re-read live position every frame
    if currentTarget then
        pcall(function()
            currentTarget.pos = currentTarget.part.Position
        end)
    end

    if currentTarget then
        local dropTarget = false
        if not isVisible(currentTarget.pos) then
            dropTarget = true
        else
            local sp, onScreen = Camera:WorldToViewportPoint(currentTarget.pos)
            if not onScreen then
                dropTarget = true
            else
                local mousePos = UIS:GetMouseLocation()
                local screenDist = (Vector2.new(sp.X, sp.Y) - mousePos).Magnitude
                if AimbotConfig.NonSticky and screenDist > AimbotConfig.FOVRadius then
                    dropTarget = true
                elseif screenDist > AimbotConfig.FOVRadius * 2 then
                    dropTarget = true
                end
            end
        end
        if dropTarget then
            currentTarget = nil
            smoothedScreenPos = nil
        end
    end

    if not currentTarget then
        currentTarget = acquireTarget()
        smoothedScreenPos = nil
        predictionState = {}
        resolverState = {}
    end

    if not currentTarget then return end

    local predicted = getPredictedPos(currentTarget, dt)
    lastPredicted = predicted
    local sp, onScreen = Camera:WorldToViewportPoint(predicted)
    if not onScreen then
        currentTarget = nil
        smoothedScreenPos = nil
        return
    end

    local targetScreen = Vector2.new(sp.X, sp.Y)
    local mousePos = UIS:GetMouseLocation()
    local dx = targetScreen.X - mousePos.X
    local dy = targetScreen.Y - mousePos.Y
    local dist = math.sqrt(dx * dx + dy * dy)

    if dist < 1 then return end

    -- Frame-rate independent smoothing using exponential decay
    -- At smoothness 1: ~95% per frame (near instant)
    -- At smoothness 10: ~40% per frame
    -- At smoothness 25: ~18% per frame
    -- At smoothness 50: ~9% per frame
    local rate = 60 / math.max(AimbotConfig.Smoothness, 1)
    local factor = 1 - math.exp(-rate * dt)

    local moveX = dx * factor
    local moveY = dy * factor

    if math.abs(moveX) < 0.5 and math.abs(moveY) < 0.5 then return end

    mousemoverel(moveX, moveY)
end))

-- ══════════════════════════════════════════════════════════════════════════════
-- RAPID FIRE — clear Attacking_CLIENT to bypass fire rate cooldown
-- ══════════════════════════════════════════════════════════════════════════════

ActiveConnections.RapidFire = RunService.Heartbeat:Connect(LPH_JIT_MAX(function()
    if not GunConfig.RapidFire then return end
    local char = LP and LP.Character
    if not char then return end
    local be = char:FindFirstChild("BodyEffects")
    if not be then return end
    local flag = be:FindFirstChild("Attacking_CLIENT")
    if flag and flag.Value == true then
        task.delay(GunConfig.RapidDelay, function()
            if flag and flag.Value == true then
                flag.Value = false
            end
        end)
    end
end))

-- ══════════════════════════════════════════════════════════════════════════════
-- AUTO SHOOT — fires mouse1 when aimbot has a locked target
-- ══════════════════════════════════════════════════════════════════════════════

local autoShootActive = false
ActiveConnections.AutoShoot = RunService.Heartbeat:Connect(LPH_JIT_MAX(function()
    if not GunConfig.AutoShoot then
        autoShootActive = false
        return
    end
    if not AimbotConfig.Enabled or not aimbotActive or not currentTarget then
        if autoShootActive then
            mouse1release()
            autoShootActive = false
        end
        return
    end

    local char = LP and LP.Character
    if not char then return end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then
        if autoShootActive then
            mouse1release()
            autoShootActive = false
        end
        return
    end

    if not autoShootActive then
        mouse1press()
        autoShootActive = true
    end
end))



-- ══════════════════════════════════════════════════════════════════════════════
-- PREDICTION VISUALS (Drawing API — screen-space lines)
-- ══════════════════════════════════════════════════════════════════════════════

local aimLine = Drawing.new("Line")
aimLine.Visible = false
aimLine.Thickness = 2
aimLine.Color = VisualsConfig.AimLineColor
aimLine.Transparency = VisualsConfig.AimLineOpacity

local predLine = Drawing.new("Line")
predLine.Visible = false
predLine.Thickness = 2
predLine.Color = VisualsConfig.PredLineColor
predLine.Transparency = VisualsConfig.PredLineOpacity

local velLine = Drawing.new("Line")
velLine.Visible = false
velLine.Thickness = 2
velLine.Color = VisualsConfig.VelocityColor
velLine.Transparency = VisualsConfig.VelocityOpacity

local function hideAllLines()
    aimLine.Visible = false
    predLine.Visible = false
    velLine.Visible = false
end

local function worldToScreen(pos)
    local sp, onScreen = Camera:WorldToViewportPoint(pos)
    return Vector2.new(sp.X, sp.Y), onScreen
end

-- ══════════════════════════════════════════════════════════════════════════════
-- DESYNC POSITION OVERLAY (client HRP vs ping-rewind server ~estimate)
-- ══════════════════════════════════════════════════════════════════════════════
local DesyncPosConfig = {
    Enabled    = false,
    AllPlayers = false,
}

local desyncPosPool = {} -- [userId] = { text = Drawing }

local function getHalfTripSeconds()
    local h = 0.04
    pcall(function()
        local p = LP:GetNetworkPing()
        if type(p) == "number" and p > 0 then
            h = p * 0.5
        end
    end)
    return h
end

local function removeDesyncPosPlayer(uid)
    local d = desyncPosPool[uid]
    if d then
        pcall(function() d.text:Remove() end)
        desyncPosPool[uid] = nil
    end
end

local function clearAllDesyncPosDrawings()
    for uid in desyncPosPool do
        removeDesyncPosPlayer(uid)
    end
end

local function getOrCreateDesyncPosDraw(uid)
    local d = desyncPosPool[uid]
    if d then return d end
    local t = Drawing.new("Text")
    t.Visible = false
    t.Size = 13
    t.Center = true
    t.Outline = true
    t.OutlineColor = Color3.new(0, 0, 0)
    desyncPosPool[uid] = { text = t }
    return desyncPosPool[uid]
end

local function hideDesyncPosDraw(d)
    d.text.Visible = false
end

ActiveConnections.DesyncPosOverlay = RunService.RenderStepped:Connect(LPH_JIT_MAX(function()
    if not DesyncPosConfig.Enabled then
        for _, d in desyncPosPool do
            hideDesyncPosDraw(d)
        end
        return
    end

    local seen = {}

    local function wantPlayer(player)
        if DesyncPosConfig.AllPlayers then return true end
        return player == LP
    end

    local function updatePlayer(player)
        if not wantPlayer(player) then return end
        local char = player.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChild("Humanoid")
        if not hrp or not hum or hum.Health <= 0 then
            removeDesyncPosPlayer(player.UserId)
            return
        end

        seen[player.UserId] = true
        local cli = hrp.Position

        local cfSrv
        if player == LP and RN_lastSentCFrame then
            cfSrv = RN_lastSentCFrame
        else
            local halfTrip = getHalfTripSeconds()
            local vel = hrp.AssemblyLinearVelocity
            cfSrv = CFrame.new(cli - vel * halfTrip) * hrp.CFrame.Rotation
        end
        local srvEst = cfSrv.Position

        local headPos = cli + Vector3.new(0, 3.2, 0)
        local sp, onScr = Camera:WorldToViewportPoint(headPos)
        if sp.Z < 0 or not onScr then
            local d0 = desyncPosPool[player.UserId]
            if d0 then hideDesyncPosDraw(d0) end
            return
        end

        local d = getOrCreateDesyncPosDraw(player.UserId)
        local label = (player == LP) and "you" or player.Name
        d.text.Text = string.format(
            "%s  Cli %.1f,%.1f,%.1f  |  Srv %.1f,%.1f,%.1f",
            label, cli.X, cli.Y, cli.Z, srvEst.X, srvEst.Y, srvEst.Z
        )
        d.text.Position = Vector2.new(sp.X, sp.Y)
        d.text.Color = Color3.fromRGB(180, 255, 200)
        d.text.Visible = true
    end

    if DesyncPosConfig.AllPlayers then
        for _, p in Players:GetPlayers() do
            updatePlayer(p)
        end
    else
        updatePlayer(LP)
    end

    for uid in desyncPosPool do
        if not seen[uid] then
            removeDesyncPosPlayer(uid)
        end
    end
end))

ActiveConnections.DesyncPosPlayerRemoving = Players.PlayerRemoving:Connect(function(p)
    removeDesyncPosPlayer(p.UserId)
end)

ActiveConnections.VisualsLoop = RunService.RenderStepped:Connect(LPH_JIT_MAX(function()
    if not VisualsConfig.Enabled or not AimbotConfig.Enabled or not aimbotActive or not currentTarget then
        hideAllLines()
        lastPredicted = nil
        return
    end

    local targetPos = currentTarget.pos
    local mousePos = UIS:GetMouseLocation()
    local from = Vector2.new(mousePos.X, mousePos.Y)

    if VisualsConfig.AimLine then
        local to, onScreen = worldToScreen(targetPos)
        if onScreen then
            aimLine.From = from
            aimLine.To = to
            aimLine.Color = VisualsConfig.AimLineColor
            aimLine.Thickness = math.max(1, math.floor(VisualsConfig.AimLineWidth * 40))
            aimLine.Transparency = VisualsConfig.AimLineOpacity
            aimLine.Visible = true
        else
            aimLine.Visible = false
        end
    else
        aimLine.Visible = false
    end

    local ps = predictionState[currentTarget.charName]
    local predPos = lastPredicted or targetPos
    if VisualsConfig.PredLine and ps and (predPos - targetPos).Magnitude > 0.3 then
        local fromS, fromOn = worldToScreen(targetPos)
        local toS, toOn = worldToScreen(predPos)
        if fromOn and toOn then
            predLine.From = fromS
            predLine.To = toS
            predLine.Color = VisualsConfig.PredLineColor
            predLine.Thickness = math.max(1, math.floor(VisualsConfig.PredLineWidth * 40))
            predLine.Transparency = VisualsConfig.PredLineOpacity
            predLine.Visible = true
        else
            predLine.Visible = false
        end
    else
        predLine.Visible = false
    end

    if VisualsConfig.VelocityLine and ps then
        local vx = ps.smoothVelX or 0
        local vz = ps.smoothVelZ or 0
        local speed = math.sqrt(vx * vx + vz * vz)
        if speed > 2 then
            local velEnd = targetPos + Vector3.new(vx, 0, vz) * VisualsConfig.VelocityScale
            local fromS, fromOn = worldToScreen(targetPos)
            local toS, toOn = worldToScreen(velEnd)
            if fromOn and toOn then
                velLine.From = fromS
                velLine.To = toS
                velLine.Color = VisualsConfig.VelocityColor
                velLine.Thickness = math.max(1, math.floor(VisualsConfig.VelocityWidth * 40))
                velLine.Transparency = VisualsConfig.VelocityOpacity
                velLine.Visible = true
            else
                velLine.Visible = false
            end
        else
            velLine.Visible = false
        end
    else
        velLine.Visible = false
    end
end))

local clearAllESP
local clearAllChams

local function buildESPAndChams()
-- ══════════════════════════════════════════════════════════════════════════════
-- ESP SYSTEM (Drawing API — 2D bounding box, name, health, distance, weapon)
-- ══════════════════════════════════════════════════════════════════════════════

local espCache = {}

local function createESPDrawings()
    local boxTL = Drawing.new("Line"); boxTL.Visible = false; boxTL.Thickness = 1
    local boxTR = Drawing.new("Line"); boxTR.Visible = false; boxTR.Thickness = 1
    local boxBL = Drawing.new("Line"); boxBL.Visible = false; boxBL.Thickness = 1
    local boxBR = Drawing.new("Line"); boxBR.Visible = false; boxBR.Thickness = 1

    local boxOutTL = Drawing.new("Line"); boxOutTL.Visible = false; boxOutTL.Thickness = 3; boxOutTL.Color = Color3.new(0,0,0)
    local boxOutTR = Drawing.new("Line"); boxOutTR.Visible = false; boxOutTR.Thickness = 3; boxOutTR.Color = Color3.new(0,0,0)
    local boxOutBL = Drawing.new("Line"); boxOutBL.Visible = false; boxOutBL.Thickness = 3; boxOutBL.Color = Color3.new(0,0,0)
    local boxOutBR = Drawing.new("Line"); boxOutBR.Visible = false; boxOutBR.Thickness = 3; boxOutBR.Color = Color3.new(0,0,0)

    local hpBg = Drawing.new("Line"); hpBg.Visible = false; hpBg.Thickness = 4; hpBg.Color = Color3.new(0,0,0)
    local hpBar = Drawing.new("Line"); hpBar.Visible = false; hpBar.Thickness = 2

    local nameText = Drawing.new("Text"); nameText.Visible = false; nameText.Center = true; nameText.Outline = true; nameText.OutlineColor = Color3.new(0,0,0)
    local distText = Drawing.new("Text"); distText.Visible = false; distText.Center = true; distText.Outline = true; distText.OutlineColor = Color3.new(0,0,0)
    local weapText = Drawing.new("Text"); weapText.Visible = false; weapText.Center = true; weapText.Outline = true; weapText.OutlineColor = Color3.new(0,0,0)

    return {
        boxTL = boxTL, boxTR = boxTR, boxBL = boxBL, boxBR = boxBR,
        boxOutTL = boxOutTL, boxOutTR = boxOutTR, boxOutBL = boxOutBL, boxOutBR = boxOutBR,
        hpBg = hpBg, hpBar = hpBar,
        nameText = nameText, distText = distText, weapText = weapText,
    }
end

local function hideESP(d)
    d.boxTL.Visible = false; d.boxTR.Visible = false; d.boxBL.Visible = false; d.boxBR.Visible = false
    d.boxOutTL.Visible = false; d.boxOutTR.Visible = false; d.boxOutBL.Visible = false; d.boxOutBR.Visible = false
    d.hpBg.Visible = false; d.hpBar.Visible = false
    d.nameText.Visible = false; d.distText.Visible = false; d.weapText.Visible = false
end

local function removeESP(d)
    for _, v in d do
        pcall(function() v:Remove() end)
    end
end

local function getHeldWeapon(char)
    if not char then return nil end
    local tool = char:FindFirstChildOfClass("Tool")
    if tool then return tool.Name end
    return nil
end

local function lerpColor(c1, c2, t)
    return Color3.new(
        c1.R + (c2.R - c1.R) * t,
        c1.G + (c2.G - c1.G) * t,
        c1.B + (c2.B - c1.B) * t
    )
end

ActiveConnections.ESPLoop = RunService.RenderStepped:Connect(LPH_JIT_MAX(function()
    if not VisualsConfig.ESPEnabled then
        for charName, d in espCache do
            hideESP(d)
        end
        return
    end

    local camPos = Camera.CFrame.Position
    local activePlayers = {}

    for _, p in Players:GetPlayers() do
        if p ~= LP and p.Character then
            if not isTeammateByName(p.Character.Name) then
                activePlayers[p.Character.Name] = p
            end
        end
    end

    for charName, d in espCache do
        if not activePlayers[charName] then
            hideESP(d)
        end
    end

    for charName, p in activePlayers do
        local char = p.Character
        if not char then continue end
        local hum = char:FindFirstChild("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hum or not hrp or hum.Health <= 0 then
            if espCache[charName] then hideESP(espCache[charName]) end
            continue
        end

        local dist = mag(hrp.Position - camPos)
        if dist > VisualsConfig.ESPMaxDist then
            if espCache[charName] then hideESP(espCache[charName]) end
            continue
        end

        local head = char:FindFirstChild("Head")
        if not head then
            if espCache[charName] then hideESP(espCache[charName]) end
            continue
        end

        local topPos = head.Position + Vector3.new(0, head.Size.Y * 0.5 + 0.5, 0)
        local botPos = hrp.Position - Vector3.new(0, 3, 0)

        local topSP, topOn = Camera:WorldToViewportPoint(topPos)
        local botSP, botOn = Camera:WorldToViewportPoint(botPos)

        if not topOn or not botOn then
            if espCache[charName] then hideESP(espCache[charName]) end
            continue
        end

        if not espCache[charName] then
            espCache[charName] = createESPDrawings()
        end
        local d = espCache[charName]

        local topY = topSP.Y
        local botY = botSP.Y
        local height = math.abs(botY - topY)
        local width = height * 0.55
        local midX = (topSP.X + botSP.X) * 0.5

        local x1 = midX - width * 0.5
        local x2 = midX + width * 0.5

        local fontSize = VisualsConfig.ESPFontSize
        local boxColor = VisualsConfig.ESPBoxColor

        -- Box (4 lines with outline)
        if VisualsConfig.ESPBox then
            d.boxOutTL.From = Vector2.new(x1, topY); d.boxOutTL.To = Vector2.new(x2, topY); d.boxOutTL.Visible = true
            d.boxOutBL.From = Vector2.new(x1, botY); d.boxOutBL.To = Vector2.new(x2, botY); d.boxOutBL.Visible = true
            d.boxOutTR.From = Vector2.new(x1, topY); d.boxOutTR.To = Vector2.new(x1, botY); d.boxOutTR.Visible = true
            d.boxOutBR.From = Vector2.new(x2, topY); d.boxOutBR.To = Vector2.new(x2, botY); d.boxOutBR.Visible = true

            d.boxTL.From = Vector2.new(x1, topY); d.boxTL.To = Vector2.new(x2, topY); d.boxTL.Color = boxColor; d.boxTL.Visible = true
            d.boxBL.From = Vector2.new(x1, botY); d.boxBL.To = Vector2.new(x2, botY); d.boxBL.Color = boxColor; d.boxBL.Visible = true
            d.boxTR.From = Vector2.new(x1, topY); d.boxTR.To = Vector2.new(x1, botY); d.boxTR.Color = boxColor; d.boxTR.Visible = true
            d.boxBR.From = Vector2.new(x2, topY); d.boxBR.To = Vector2.new(x2, botY); d.boxBR.Color = boxColor; d.boxBR.Visible = true
        else
            d.boxTL.Visible = false; d.boxTR.Visible = false; d.boxBL.Visible = false; d.boxBR.Visible = false
            d.boxOutTL.Visible = false; d.boxOutTR.Visible = false; d.boxOutBL.Visible = false; d.boxOutBR.Visible = false
        end

        -- Health bar (left side)
        if VisualsConfig.ESPHealth then
            local hp = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
            local barX = x1 - 5
            local barTop = topY
            local barBot = botY
            local barFillBot = barBot - (barBot - barTop) * hp
            local hpColor = lerpColor(VisualsConfig.ESPHealthBot, VisualsConfig.ESPHealthTop, hp)

            d.hpBg.From = Vector2.new(barX, barTop); d.hpBg.To = Vector2.new(barX, barBot); d.hpBg.Visible = true
            d.hpBar.From = Vector2.new(barX, barFillBot); d.hpBar.To = Vector2.new(barX, barBot); d.hpBar.Color = hpColor; d.hpBar.Visible = true
        else
            d.hpBg.Visible = false; d.hpBar.Visible = false
        end

        -- Name text (above box)
        if VisualsConfig.ESPName then
            local displayName = p.DisplayName or p.Name
            local userName = p.Name
            local label = displayName
            if displayName ~= userName then
                label = displayName .. " (@" .. userName .. ")"
            end
            d.nameText.Text = label
            d.nameText.Position = Vector2.new(midX, topY - fontSize - 4)
            d.nameText.Size = fontSize
            d.nameText.Color = VisualsConfig.ESPNameColor
            d.nameText.Visible = true
        else
            d.nameText.Visible = false
        end

        -- Distance text (below box)
        local bottomTextY = botY + 2
        if VisualsConfig.ESPDistance then
            d.distText.Text = math.floor(dist) .. " studs"
            d.distText.Position = Vector2.new(midX, bottomTextY)
            d.distText.Size = fontSize
            d.distText.Color = VisualsConfig.ESPDistColor
            d.distText.Visible = true
            bottomTextY = bottomTextY + fontSize + 2
        else
            d.distText.Visible = false
        end

        -- Weapon text (below distance)
        if VisualsConfig.ESPWeapon then
            local weapon = getHeldWeapon(char)
            if weapon then
                d.weapText.Text = weapon
                d.weapText.Position = Vector2.new(midX, bottomTextY)
                d.weapText.Size = fontSize
                d.weapText.Color = VisualsConfig.ESPWeaponColor
                d.weapText.Visible = true
            else
                d.weapText.Visible = false
            end
        else
            d.weapText.Visible = false
        end
    end
end))

clearAllESP = function()
    for charName, d in espCache do
        removeESP(d)
    end
    espCache = {}
end

ActiveConnections.ESPPlayerRemoving = Players.PlayerRemoving:Connect(function(p)
    local cn = p.Name
    if espCache[cn] then
        removeESP(espCache[cn])
        espCache[cn] = nil
    end
end)

-- ══════════════════════════════════════════════════════════════════════════════
-- PLAYER CHAMS SYSTEM (HandleAdornments + HDR bloom glow)
-- ══════════════════════════════════════════════════════════════════════════════

pcall(function() setfflag("AdornShadingAPI", "true") end)

local chamsData = {}
local chamsCleanupCounter = 0
local CHAMS_PARTS = {
    "Head", "UpperTorso", "LowerTorso",
    "LeftUpperArm", "LeftLowerArm", "LeftHand",
    "RightUpperArm", "RightLowerArm", "RightHand",
    "LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
    "RightUpperLeg", "RightLowerLeg", "RightFoot",
}

local HEAD_PARTS = {Head = true, FakeHead = true}

local function isChamsVisible(targetPos)
    local camPos = Camera.CFrame.Position
    local dir = targetPos - camPos
    if mag(dir) < 1 then return true end

    local ig = {Camera}
    if LP.Character then ig[#ig + 1] = LP.Character end
    for _, name in {"Ignored", "BULLET_RAYS", "WORLD_EVENT_PARTICLES"} do
        local obj = workspace:FindFirstChild(name)
        if obj then ig[#ig + 1] = obj end
    end
    local wpPlayers = workspace:FindFirstChild("Players")
    if wpPlayers then ig[#ig + 1] = wpPlayers end
    for _, p in Players:GetPlayers() do
        if p ~= LP and p.Character then ig[#ig + 1] = p.Character end
    end

    local ray = Ray.new(camPos, dir)
    local hitPart = workspace:FindPartOnRayWithIgnoreList(ray, ig)
    return hitPart == nil
end

local function removeAdorns(part)
    if not part then return end
    for _, obj in part:GetChildren() do
        if obj.Name == "DH_Cham" or obj.Name == "DH_Glow" then
            obj:Destroy()
        end
    end
end

local function createAdornment(part, isHead, color, trans, zIndex, sizeOffset, extra)
    extra = extra or {}
    local ad
    if isHead then
        ad = Instance.new("CylinderHandleAdornment")
        ad.Height = part.Size.Y + (extra.HeightOffset or 0.3)
        ad.Radius = (part.Size.X * 0.5) + (extra.RadiusOffset or 0.2)
        ad.CFrame = CFrame.new(Vector3.zero, Vector3.new(0, 1, 0))
    else
        ad = Instance.new("BoxHandleAdornment")
        ad.Size = part.Size + (sizeOffset or Vector3.new(0.02, 0.02, 0.02))
    end

    ad.Name = "DH_Cham"
    ad.AlwaysOnTop = true
    ad.ZIndex = zIndex or 4
    ad.Adornee = part
    ad.Color3 = color
    ad.Transparency = trans or 0

    if extra.Shading then
        pcall(function() ad.Shading = extra.Shading end)
    end

    ad.Parent = part
    return ad
end

local function buildPartAdorns(part, partName, mainColor, glowColor, trans, method, glowMul)
    local isHead = HEAD_PARTS[partName] ~= nil

    if method == "Glow" then
        local hdr = Color3.new(mainColor.R * glowMul, mainColor.G * glowMul, mainColor.B * glowMul)
        createAdornment(part, isHead, hdr, -1, isHead and 10 or 9,
            Vector3.new(0.03, 0.03, 0.03),
            { Shading = Enum.AdornShading.XRayShaded })
    else
        local hdr = Color3.new(glowColor.R * 15, glowColor.G * 15, glowColor.B * 15)
        local glow = createAdornment(part, isHead, hdr, -1, isHead and 9 or 8,
            Vector3.new(0.03, 0.03, 0.03),
            { Shading = Enum.AdornShading.XRayShaded })
        glow.Name = "DH_Glow"

        createAdornment(part, isHead, mainColor, trans, 10,
            Vector3.new(0.02, 0.02, 0.02))
    end
end

local function createChamsForPlayer(player)
    local char = player.Character
    if not char then return nil end

    local entry = {
        player = player,
        charName = char.Name,
        char = char,
        parts = {},
    }

    local mainColor = VisualsConfig.VisibleColor
    local glowColor = VisualsConfig.GlowColor
    local trans = VisualsConfig.ChamsTrans
    local method = VisualsConfig.ChamsMethod
    local glowMul = VisualsConfig.GlowMultiplier

    for _, partName in CHAMS_PARTS do
        local part = char:FindFirstChild(partName)
        if part and part:IsA("BasePart") and part.Transparency < 1 then
            buildPartAdorns(part, partName, mainColor, glowColor, trans, method, glowMul)
            entry.parts[partName] = part
        end
    end

    return entry
end

local function updateChamsEntry(entry)
    local char = entry.player and entry.player.Character
    if not char then return false end
    if char ~= entry.char then return false end
    local hum = char:FindFirstChild("Humanoid")
    if not hum or hum.Health <= 0 then return false end

    local hrp = char:FindFirstChild("HumanoidRootPart")
    local visible = hrp and isChamsVisible(hrp.Position) or false

    local mainColor = visible and VisualsConfig.VisibleColor or VisualsConfig.OccludedColor
    local glowColor = VisualsConfig.GlowColor
    local trans = VisualsConfig.ChamsTrans
    local method = VisualsConfig.ChamsMethod
    local glowMul = VisualsConfig.GlowMultiplier

    local liveCount = 0
    for partName, part in entry.parts do
        if not part or not part.Parent then continue end
        liveCount += 1

        for _, obj in part:GetChildren() do
            if obj.Name == "DH_Cham" then
                if method == "Glow" then
                    obj.Color3 = Color3.new(mainColor.R * glowMul, mainColor.G * glowMul, mainColor.B * glowMul)
                else
                    obj.Color3 = mainColor
                    obj.Transparency = trans
                end
            elseif obj.Name == "DH_Glow" then
                obj.Color3 = Color3.new(glowColor.R * 15, glowColor.G * 15, glowColor.B * 15)
            end
        end
    end

    if liveCount == 0 then return false end
    return true
end

local function destroyChamsEntry(entry)
    for _, part in entry.parts do
        if part and part.Parent then
            removeAdorns(part)
        end
    end
end

clearAllChams = function()
    for _, entry in chamsData do
        destroyChamsEntry(entry)
    end
    chamsData = {}
end

ActiveConnections.ChamsPlayerRemoving = Players.PlayerRemoving:Connect(function(p)
    local cn = p.Name
    if chamsData[cn] then
        destroyChamsEntry(chamsData[cn])
        chamsData[cn] = nil
    end
end)

ActiveConnections.ChamsLoop = RunService.Heartbeat:Connect(LPH_JIT_MAX(function()
    if not VisualsConfig.ChamsEnabled then
        if next(chamsData) then clearAllChams() end
        return
    end

    local activePlayers = {}
    for _, p in Players:GetPlayers() do
        if p ~= LP and p.Character then
            if not isTeammateByName(p.Character.Name) then
                activePlayers[p.Character.Name] = p
            end
        end
    end

    for charName, entry in chamsData do
        if not activePlayers[charName] then
            destroyChamsEntry(entry)
            chamsData[charName] = nil
        end
    end

    for charName, p in activePlayers do
        local existing = chamsData[charName]
        if existing and existing.char ~= p.Character then
            destroyChamsEntry(existing)
            chamsData[charName] = nil
            existing = nil
        end
        if not existing then
            local entry = createChamsForPlayer(p)
            if entry then chamsData[charName] = entry end
        end
    end

    for charName, entry in chamsData do
        if not updateChamsEntry(entry) then
            destroyChamsEntry(entry)
            chamsData[charName] = nil
        end
    end
end))

end
buildESPAndChams()

-- ── Gun Mods helpers ────────────────────────────────────────────────────────

local function getEquippedTool()
    local char = LP and LP.Character
    if not char then return nil end
    return char:FindFirstChildOfClass("Tool")
end

local function getAmmoValues(tool)
    tool = tool or getEquippedTool()
    if not tool then return nil, nil end
    local scr = tool:FindFirstChild("Script")
    if not scr then return nil, nil end
    local af = scr:FindFirstChild("Ammo")
    if not af then return nil, nil end
    return af:FindFirstChild("CLIENT"), scr:FindFirstChild("MaxAmmo")
end


-- Clip dump
local dumpActive = false

local findClosestEnemy = LPH_JIT_MAX(function(origin)
    local best, bestDist = nil, math.huge
    for _, e in cachedTargets do
        local d = mag(e.pos - origin)
        if d > 1 and d < bestDist then
            best, bestDist = e, d
        end
    end
    return best
end)

local function getShootOrigin()
    local char = LP and LP.Character
    if not char then return nil end
    local head = char:FindFirstChild("Head")
    if head then return head.Position end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then return hrp.Position end
    return nil
end

local function buildShotData()
    local origin = getShootOrigin()
    if not origin then return nil end

    local target = findClosestEnemy(origin)
    if not target then return nil end
    local dist = mag(target.pos - origin)
    if dist >= 500 then return nil end

    local ig = buildIgnoreList()
    local dir = target.pos - origin
    local dirMag = mag(dir)
    local ray = Ray.new(origin, dir * ((dirMag + 30) / dirMag))
    local hitPart, hitPos, hitNormal =
        workspace:FindPartOnRayWithIgnoreList(ray, ig)

    if not hitPart or not enemyPartSet[hitPart] then return nil end

    local localOff = hitPart.CFrame:PointToObjectSpace(hitPos)
    local hits = { { Instance = hitPart, Position = hitPos, Normal = hitNormal } }
    local offsets = { { thePart = hitPart, theOffset = localOff } }
    return { hits, offsets, origin, hitPos }, hitPart
end

local isDumpShot = false

local function doClipDump(ammoRef)
    if dumpActive then return end
    dumpActive = true
    task.spawn(function()
        local maxShots = ammoRef and math.clamp(ammoRef.Value, 0, 20) or 5
        for i = 1, maxShots do
            task.wait(GunConfig.DumpDelay)
            if not GunConfig.ClipDump then break end
            if ammoRef and ammoRef.Value <= 0 then break end

            local data, _ = buildShotData()
            if not data then break end

            if ammoRef then ammoRef.Value = ammoRef.Value - 1 end
            isDumpShot = true
            MainEvent:FireServer("Shoot", data)
            isDumpShot = false
        end
        dumpActive = false
    end)
end


-- ── Auto Kill helpers ─────────────────────────────────────────────────────
local function findKnifeTool()
    local char = LP and LP.Character
    if not char then return nil end
    for _, child in char:GetChildren() do
        if child:IsA("Tool") and string.find(child.Name, "Knife") then
            return child
        end
    end
    local bp = LP:FindFirstChild("Backpack")
    if bp then
        for _, child in bp:GetChildren() do
            if child:IsA("Tool") and string.find(child.Name, "Knife") then
                return child
            end
        end
    end
    return nil
end

local function findAliveEnemy()
    local enemies = {}
    for _, p in Players:GetPlayers() do
        if p ~= LP and p.Character then
            local hum = p.Character:FindFirstChild("Humanoid")
            local hrp = p.Character:FindFirstChild("HumanoidRootPart")
            if hum and hrp and hum.Health > 0 then
                local ko = p.Character:FindFirstChild("BodyEffects")
                    and p.Character.BodyEffects:FindFirstChild("K.O")
                if not ko or ko.Value == false then
                    enemies[#enemies + 1] = p
                end
            end
        end
    end
    if #enemies == 0 then return nil end
    return enemies[math.random(1, #enemies)]
end

local function isTargetKO(target)
    if not target or not target.Character then return true end
    local hum = target.Character:FindFirstChild("Humanoid")
    if not hum or hum.Health <= 0 then return true end
    local be = target.Character:FindFirstChild("BodyEffects")
    if be then
        local ko = be:FindFirstChild("K.O")
        if ko and ko.Value == true then return true end
    end
    return false
end

local function isTargetDead(target)
    if not target or not target.Character then return true end
    local hum = target.Character:FindFirstChild("Humanoid")
    return not hum or hum.Health <= 0
end

local noclipConn = nil
local lockCFrame = nil

local function setNoclip(enabled)
    if enabled then
        if noclipConn then return end
        noclipConn = RunService.Stepped:Connect(LPH_JIT(function()
            local char = LP and LP.Character
            if not char then return end
            for _, part in char:GetDescendants() do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp and lockCFrame then
                hrp.CFrame = lockCFrame
                hrp.Velocity = Vector3.new(0, 0, 0)
                hrp.RotVelocity = Vector3.new(0, 0, 0)
            end
        end))
    else
        if noclipConn then
            noclipConn:Disconnect()
            noclipConn = nil
        end
        lockCFrame = nil
    end
end

local function teleportTo(pos, mode)
    local cf
    if mode == "faceup" then
        cf = CFrame.new(pos) * CFrame.Angles(math.rad(90), 0, 0)
    elseif mode == "flipped" then
        cf = CFrame.new(pos) * CFrame.Angles(math.rad(180), 0, 0)
    else
        cf = CFrame.new(pos)
    end
    lockCFrame = cf
    local char = LP and LP.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    hrp.CFrame = cf
    hrp.Velocity = Vector3.new(0, 0, 0)
    hrp.RotVelocity = Vector3.new(0, 0, 0)
end

local function stopAutoKill()
    KillConfig.AutoKill = false
    autoKillRunning = false
    lockCFrame = nil
    setNoclip(false)
    local char = LP and LP.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if hrp then
        if preKillCFrame then
            hrp.CFrame = preKillCFrame
        end
        hrp.Velocity = Vector3.new(0, 0, 0)
        hrp.RotVelocity = Vector3.new(0, 0, 0)
    end
    preKillCFrame = nil
    selectedTarget = nil
end

local function doAutoKillLoop()
    if autoKillRunning then return end
    autoKillRunning = true

    task.spawn(function()
        print("[AK] Auto Kill started")

        local char = LP and LP.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        if hrp then preKillCFrame = hrp.CFrame end

        setNoclip(true)

        local lastChar = char

        while KillConfig.AutoKill and autoKillRunning do
            char = LP and LP.Character
            local hum = char and char:FindFirstChild("Humanoid")

            -- Detect respawn: character changed or we were dead
            if not char or not hum or hum.Health <= 0 then
                lockCFrame = nil
                task.wait(1)
                continue
            end

            if char ~= lastChar then
                lockCFrame = nil
                lastChar = char
                print("[AK] Respawned — re-equipping knife...")
                task.wait(1)
                local newHRP = char:FindFirstChild("HumanoidRootPart")
                if newHRP then preKillCFrame = newHRP.CFrame end
            end

            local knife = findKnifeTool()
            if not knife then
                print("[AK] No knife found — waiting...")
                task.wait(1)
                continue
            end

            if knife.Parent ~= char then
                hum:EquipTool(knife)
                task.wait(0.5)
            end

            local target
            if KillConfig.SingleTarget and selectedTarget then
                if not isTargetDead(selectedTarget) and not isTargetKO(selectedTarget) then
                    target = selectedTarget
                else
                    target = nil
                end
            else
                target = findAliveEnemy()
            end

            if not target then
                print("[AK] No alive enemies — waiting...")
                task.wait(1)
                continue
            end

            local tChar = target.Character
            local tHRP = tChar and tChar:FindFirstChild("HumanoidRootPart")
            if not tHRP then
                task.wait(0.5)
                continue
            end

            print("[AK] Targeting: " .. target.Name)

            -- Capture ground-level Y from target's standing position
            local groundY = tHRP.Position.Y - KillConfig.Depth

            -- Phase 1: Teleport below target on our back, swing knife upward
            while KillConfig.AutoKill and autoKillRunning
                  and not isTargetKO(target) and not isTargetDead(target) do

                local tHRP2 = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
                if not tHRP2 then break end

                local tPos = tHRP2.Position
                local yPos = math.min(tPos.Y - KillConfig.Depth, groundY)
                local belowPos = Vector3.new(tPos.X, yPos, tPos.Z)
                teleportTo(belowPos, "faceup")

                knife = findKnifeTool()
                if knife then
                    knife:Activate()
                end

                task.wait(KillConfig.SwingDelay)
            end

            if KillConfig.SingleTarget and selectedTarget and isTargetKO(target) then
                print("[AK] K.O.'d single target — waiting for respawn...")
                while KillConfig.AutoKill and autoKillRunning and selectedTarget do
                    local sc = selectedTarget.Character
                    local sh = sc and sc:FindFirstChild("Humanoid")
                    local shrp = sc and sc:FindFirstChild("HumanoidRootPart")
                    if sh and shrp and sh.Health > 0 then
                        local ko = sc:FindFirstChild("BodyEffects")
                            and sc.BodyEffects:FindFirstChild("K.O")
                        if not ko or ko.Value == false then
                            print("[AK] " .. selectedTarget.Name .. " respawned — going again")
                            break
                        end
                    end
                    task.wait(0.5)
                end
            end

            task.wait(0.3)
        end

        stopAutoKill()
        print("[AK] Auto Kill stopped")
    end)
end

local function buildHooksAndRecoil()
-- __namecall hook
local inHook = false
local oldNc
oldNc = hookmetamethod(game, "__namecall", newcclosure(LPH_NO_UPVALUES(function(self, ...)
    if inHook then return oldNc(self, ...) end

    local m = getnamecallmethod()
    if m == "FireServer"
        and not isDumpShot
        and typeof(self) == "Instance"
        and self.Name == "MainEvent"
        and select(1, ...) == "Shoot" then

        local args = { ... }
        local data = args[2]
        if type(data) ~= "table" then
            if BR_DEBUG then print("[BR] data is not a table, passthrough") end
            return oldNc(self, ...)
        end

        local origin   = data[3]
        local endpoint = data[4]
        local hits     = data[1]
        local offsets  = data[2]
        if typeof(origin) ~= "Vector3" or typeof(endpoint) ~= "Vector3"
            or type(hits) ~= "table" or type(offsets) ~= "table" then
            if BR_DEBUG then
                print(string.format("[BR] format mismatch: origin=%s endpoint=%s hits=%s offsets=%s",
                    typeof(origin), typeof(endpoint), type(hits), type(offsets)))
            end
            return oldNc(self, ...)
        end

        local isSinglePellet = (#hits == 1)

        inHook = true

        if AimConfig.Enabled and isSinglePellet then
            local ok, err = pcall(function()
                local h = hits[1]
                if type(h) ~= "table" or not h.Instance then
                    if BR_DEBUG then print("[BR] skip: hit entry invalid") end
                    return
                end
                if enemyPartSet[h.Instance] then
                    if BR_DEBUG then print("[BR] already on enemy — no redirect needed") end
                    return
                end
                if not rollHitChance() then
                    if BR_DEBUG then print("[BR] skip: hit chance roll failed") end
                    return
                end

                local nTargets = #cachedTargets
                local target = findClosestInFOV(origin)
                if not target then
                    if BR_DEBUG then print(string.format("[BR] skip: no target in FOV (%d cached)", nTargets)) end
                    return
                end
                local dist = mag(target.pos - origin)
                if dist >= 500 then
                    if BR_DEBUG then print(string.format("[BR] skip: target %s too far (%.0f)", target.charName, dist)) end
                    return
                end

                local dir = target.pos - origin
                local dirMag = mag(dir)
                local ray = Ray.new(origin, dir * ((dirMag + 30) / dirMag))
                local hitPart, hitPos, hitNormal =
                    workspace:FindPartOnRayWithIgnoreList(ray, buildIgnoreList())
                if not hitPart then
                    if BR_DEBUG then print(string.format("[BR] skip: raycast hit nothing (target=%s)", target.charName)) end
                    return
                end
                if not enemyPartSet[hitPart] then
                    if BR_DEBUG then print(string.format("[BR] skip: ray hit %s (not in enemyPartSet)", hitPart:GetFullName())) end
                    return
                end

                h.Instance = hitPart
                h.Position = hitPos
                h.Normal   = hitNormal
                local oe = offsets[1]
                if type(oe) == "table" then
                    oe.thePart   = hitPart
                    oe.theOffset = hitPart.CFrame:PointToObjectSpace(hitPos)
                end
                data[4] = hitPos
                if BR_DEBUG then
                    print(string.format("[BR] REDIRECT -> %s.%s (%.1f studs)", target.charName, hitPart.Name, dirMag))
                end
            end)
            if not ok and BR_DEBUG then
                print("[BR] hook error: " .. tostring(err))
            end
        elseif BR_DEBUG then
            if not AimConfig.Enabled then
                print("[BR] skip: AimConfig.Enabled is false")
            elseif not isSinglePellet then
                print(string.format("[BR] multi-pellet (%d hits) — passthrough", #hits))
            end
        end

        inHook = false

        setnamecallmethod("FireServer")
        local r = oldNc(self, unpack(args))

        if GunConfig.ClipDump and not dumpActive then
            local ammoRef = nil
            pcall(function() ammoRef = select(1, getAmmoValues()) end)
            doClipDump(ammoRef)
        end

        return r
    end

    return oldNc(self, ...)
end)))

-- ══════════════════════════════════════════════════════════════════════════════
-- NO RECOIL — intercept BodyEffects.GunChanges.Changed
-- The game applies recoil via:
--   GunChanges.Changed → Camera.CFrame * CFrame.Angles(kick, ...)
-- We disconnect all existing .Changed connections and replace with our own
-- that skips the CFrame.Angles when NoRecoil is enabled.
-- ══════════════════════════════════════════════════════════════════════════════

do
    local function hookGunChanges(char)
        if not char then return end
        local be = char:FindFirstChild("BodyEffects")
        if not be then return end
        local gc = be:FindFirstChild("GunChanges")
        if not gc then return end

        local conns = getconnections(gc.Changed)
        for _, c in conns do
            c:Disable()
        end

        ActiveConnections.NoRecoilGC = gc.Changed:Connect(function()
            if GunConfig.NoRecoil then return end
            for _, c in conns do
                c:Enable()
                c:Fire()
                c:Disable()
            end
        end)
    end

    pcall(function()
        hookGunChanges(LP.Character)
    end)

    LP.CharacterAdded:Connect(function(char)
        task.wait(1)
        pcall(hookGunChanges, char)
    end)
end

end
buildHooksAndRecoil()

local SEGMENTS = 90
local fovMainSegments = {}
local fovOutlineSegments = {}

local function buildFOVCircle()
-- ══════════════════════════════════════════════════════════════════════════════
-- ANIMATED FOV CIRCLE (segment-based Drawing API for per-segment color)
-- ══════════════════════════════════════════════════════════════════════════════

for i = 1, SEGMENTS do
    local main = Drawing.new("Line")
    main.Visible = false
    main.Thickness = 2
    fovMainSegments[i] = main

    local outline = Drawing.new("Line")
    outline.Visible = false
    outline.Thickness = 1
    fovOutlineSegments[i] = outline
end

local function lerpColor(c1, c2, t)
    return Color3.new(
        c1.R + (c2.R - c1.R) * t,
        c1.G + (c2.G - c1.G) * t,
        c1.B + (c2.B - c1.B) * t
    )
end

local function hsvToColor(h, s, v)
    return Color3.fromHSV(h % 1, s, v)
end

local function triColorLerp(c1, c2, c3, t)
    if t < 0.5 then
        return lerpColor(c1, c2, t * 2)
    else
        return lerpColor(c2, c3, (t - 0.5) * 2)
    end
end

local AnimFunctions = {}

AnimFunctions["None"] = function(angle, t)
    return AimbotConfig.FOVColor1
end

AnimFunctions["Rotating Gradient"] = function(angle, t)
    local offset = (angle + t * AimbotConfig.AnimSpeed) % 1
    return triColorLerp(AimbotConfig.FOVColor1, AimbotConfig.FOVColor2, AimbotConfig.FOVColor3, offset)
end

AnimFunctions["Rainbow Sweep"] = function(angle, t)
    local hue = (angle + t * AimbotConfig.AnimSpeed * 0.3) % 1
    return hsvToColor(hue, 1, 1)
end

AnimFunctions["Plasma"] = function(angle, t)
    local spd = AimbotConfig.AnimSpeed
    local v1 = math.sin(angle * math.pi * 4 + t * spd * 2) * 0.5 + 0.5
    local v2 = math.cos(angle * math.pi * 6 - t * spd * 1.7) * 0.5 + 0.5
    local v3 = math.sin((angle + t * spd * 0.5) * math.pi * 2) * 0.5 + 0.5
    local blend = (v1 + v2 + v3) / 3
    return triColorLerp(AimbotConfig.FOVColor1, AimbotConfig.FOVColor2, AimbotConfig.FOVColor3, blend)
end

AnimFunctions["Neon Pulse"] = function(angle, t)
    local spd = AimbotConfig.AnimSpeed
    local pulse = math.sin(t * spd * 3) * 0.3 + 0.7
    local sweep = (angle + t * spd * 0.5) % 1
    local base = triColorLerp(AimbotConfig.FOVColor1, AimbotConfig.FOVColor2, AimbotConfig.FOVColor3, sweep)
    return Color3.new(
        math.clamp(base.R * pulse, 0, 1),
        math.clamp(base.G * pulse, 0, 1),
        math.clamp(base.B * pulse, 0, 1)
    )
end

local updateFOVCircle = LPH_JIT_MAX(function()
    local show = AimbotConfig.Enabled and AimbotConfig.ShowFOV
    if not show then
        for i = 1, SEGMENTS do
            fovMainSegments[i].Visible = false
            fovOutlineSegments[i].Visible = false
        end
        return
    end

    local mousePos = UIS:GetMouseLocation()
    local cx = mousePos.X
    local cy = mousePos.Y
    local radius = AimbotConfig.FOVRadius
    local t = os.clock()
    local getColor = AnimFunctions[AimbotConfig.AnimStyle] or AnimFunctions["None"]
    local step = (2 * math.pi) / SEGMENTS

    local showOutline = AimbotConfig.OutlineEnabled
    local outlineRadius = radius + AimbotConfig.OutlineOffset

    for i = 1, SEGMENTS do
        local a1 = step * (i - 1)
        local a2 = step * i
        local cos1 = math.cos(a1)
        local sin1 = math.sin(a1)
        local cos2 = math.cos(a2)
        local sin2 = math.sin(a2)

        local seg = fovMainSegments[i]
        seg.From = Vector2.new(cx + cos1 * radius, cy + sin1 * radius)
        seg.To   = Vector2.new(cx + cos2 * radius, cy + sin2 * radius)
        seg.Color = getColor(i / SEGMENTS, t)
        seg.Thickness = AimbotConfig.FOVThickness
        seg.Transparency = 1 - AimbotConfig.FOVOpacity
        seg.Visible = true

        local out = fovOutlineSegments[i]
        if showOutline then
            out.From = Vector2.new(cx + cos1 * outlineRadius, cy + sin1 * outlineRadius)
            out.To   = Vector2.new(cx + cos2 * outlineRadius, cy + sin2 * outlineRadius)
            out.Color = AimbotConfig.OutlineColor
            out.Thickness = AimbotConfig.OutlineThickness
            out.Transparency = 1 - AimbotConfig.OutlineOpacity
            out.Visible = true
        else
            out.Visible = false
        end
    end
end)

ActiveConnections.FOVRender = RunService.RenderStepped:Connect(updateFOVCircle)

end
buildFOVCircle()

-- ══════════════════════════════════════════════════════════════════════════════
-- STARLIGHT UI
-- ══════════════════════════════════════════════════════════════════════════════

local Window = Starlight:CreateWindow({
    Name = "X3 Customs", Subtitle = "Aim Assist", Icon = NebulaIcons:GetIcon('crosshair', 'Lucide'),
    LoadingSettings = { Title = "DH Customs", Subtitle = "Loading..." },
    FileSettings = { ConfigFolder = "DH_Customs_Aim" },
})

local MainSection = Window:CreateTabSection("Main", false)

local function buildAimbotTabUI()
-- ═══════════════════════════════════════════
-- AIMBOT TAB
-- ═══════════════════════════════════════════
local AimbotTab = MainSection:CreateTab({
    Name = "Aimbot", Icon = NebulaIcons:GetIcon('crosshair', 'Lucide'), Columns = 2
}, "AimbotTab")

-- Column 1: Controls
local ABControls = AimbotTab:CreateGroupbox({
    Name = "Controls", Icon = NebulaIcons:GetIcon('target', 'Lucide'), Column = 1
}, "ABControls")

ABControls:CreateToggle({
    Name = "Enable Aimbot", Icon = NebulaIcons:GetIcon('power', 'Lucide'),
    CurrentValue = false, Style = 2,
    Callback = function(V)
        AimbotConfig.Enabled = V
        if not V then
            aimbotActive = false
            aimbotToggled = false
            currentTarget = nil
        end
        Starlight:Notification({
            Title = "Aimbot",
            Content = V and "Enabled" or "Disabled",
            Icon = NebulaIcons:GetIcon(V and 'check-circle' or 'x-circle', 'Lucide')
        }, "AimbotToggleNotif")
    end,
}, "AimbotEnableToggle")

ABControls:CreateDivider()

local keyNames = {}
for k in KEY_MAP do keyNames[#keyNames + 1] = k end
table.sort(keyNames)

ABControls:CreateLabel({
    Name = "Primary Key", Icon = NebulaIcons:GetIcon('keyboard', 'Lucide')
}, "ActivateKeyLabel"):AddDropdown({
    Options = keyNames,
    CurrentOptions = {"MouseButton2"},
    Placeholder = "Select Key",
    Callback = function(O)
        if O and O[1] then AimbotConfig.ActivateKey = O[1] end
    end,
}, "ActivateKeyDropdown")

local secondaryKeyNames = {"None"}
for _, k in keyNames do secondaryKeyNames[#secondaryKeyNames + 1] = k end

ABControls:CreateLabel({
    Name = "Secondary Key", Icon = NebulaIcons:GetIcon('keyboard', 'Lucide')
}, "SecondaryKeyLabel"):AddDropdown({
    Options = secondaryKeyNames,
    CurrentOptions = {"None"},
    Placeholder = "Select Key",
    Callback = function(O)
        if O and O[1] then AimbotConfig.SecondaryKey = O[1] end
    end,
}, "SecondaryKeyDropdown")

ABControls:CreateDivider()

ABControls:CreateToggle({
    Name = "Hold Mode (off = toggle)", Icon = NebulaIcons:GetIcon('grip-horizontal', 'Lucide'),
    CurrentValue = true, Style = 2,
    Callback = function(V)
        AimbotConfig.HoldMode = V
        aimbotActive = false
        aimbotToggled = false
        currentTarget = nil
    end,
}, "HoldModeToggle")

ABControls:CreateDivider()

ABControls:CreateToggle({
    Name = "Non-Sticky (release off-FOV)", Icon = NebulaIcons:GetIcon('unlink', 'Lucide'),
    CurrentValue = true, Style = 2,
    Callback = function(V) AimbotConfig.NonSticky = V end,
}, "NonStickyToggle")

ABControls:CreateDivider()

ABControls:CreateSlider({
    Name = "FOV Radius", Icon = NebulaIcons:GetIcon('circle', 'Lucide'),
    Range = {30, 600}, Increment = 5, CurrentValue = 120, Suffix = " px",
    Callback = function(V) AimbotConfig.FOVRadius = V end,
}, "ABFOVSlider")

ABControls:CreateSlider({
    Name = "Max Target Distance", Icon = NebulaIcons:GetIcon('ruler', 'Lucide'),
    Range = {10, 1000}, Increment = 10, CurrentValue = 500, Suffix = " studs",
    Callback = function(V) AimbotConfig.MaxDist = V end,
}, "ABMaxDistSlider")

ABControls:CreateDivider()

ABControls:CreateToggle({
    Name = "Duels Mode", Icon = NebulaIcons:GetIcon('swords', 'Lucide'),
    CurrentValue = false, Style = 2,
    Callback = function(V)
        AimbotConfig.DuelsMode = V
        currentTarget = nil
    end,
}, "DuelsModeToggle")

-- Column 1: Targeting
local ABTargeting = AimbotTab:CreateGroupbox({
    Name = "Targeting", Icon = NebulaIcons:GetIcon('crosshair', 'Lucide'), Column = 1
}, "ABTargeting")

local BL_PART_OPTIONS = {
    "Head", "UpperTorso", "LowerTorso",
    "LeftUpperArm", "RightUpperArm", "LeftLowerArm", "RightLowerArm",
    "LeftHand", "RightHand",
    "LeftUpperLeg", "RightUpperLeg", "LeftLowerLeg", "RightLowerLeg",
    "LeftFoot", "RightFoot",
}

-- Multiselect (same x3 / Glass Starlight fork as lol3.lua): MultipleOptions + CurrentOptions,
-- Callback receives a sequential table of selected strings: for i = 1, #O do … end
local function setBlacklistPartsFromDropdown(O)
    local out = {}
    if type(O) ~= "table" then
        AimbotConfig.BlacklistParts = out
        return
    end
    for i = 1, #O do
        local name = O[i]
        if type(name) == "string" and name ~= "" then
            out[#out + 1] = name
        end
    end
    AimbotConfig.BlacklistParts = out
end

ABTargeting:CreateLabel({
    Name = "Part Mode", Icon = NebulaIcons:GetIcon('bone', 'Lucide')
}, "PartModeLabel"):AddDropdown({
    Options = {"Closest", "Head", "UpperTorso", "Random", "Smart"},
    CurrentOptions = {"UpperTorso"},
    Placeholder = "Select Part",
    Callback = function(O)
        if O and O[1] then AimbotConfig.PartMode = O[1] end
    end,
}, "PartModeDropdown")

ABTargeting:CreateLabel({
    Name = "Blacklist Parts", Icon = NebulaIcons:GetIcon('x-circle', 'Lucide')
}, "BLPartsLabel"):AddDropdown({
    Options = BL_PART_OPTIONS,
    CurrentOptions = {},
    MultipleOptions = true,
    Placeholder = "Select parts to exclude…",
    Callback = function(O)
        setBlacklistPartsFromDropdown(O)
    end,
}, "BLPartsDropdown")

ABTargeting:CreateDivider()

ABTargeting:CreateToggle({
    Name = "Prioritize Closest Player", Icon = NebulaIcons:GetIcon('users', 'Lucide'),
    CurrentValue = false, Style = 2,
    Callback = function(V) AimbotConfig.PrioritizeClosest = V end,
}, "PrioritizeClosestToggle")

-- Column 1: Blacklist
local ABBlacklist = AimbotTab:CreateGroupbox({
    Name = "Player Blacklist", Icon = NebulaIcons:GetIcon('shield-off', 'Lucide'), Column = 1
}, "ABBlacklist")

local blacklistDisplayMap = {}

local function getBlacklistPlayerNames()
    local names = {}
    blacklistDisplayMap = {}
    for _, p in Players:GetPlayers() do
        if p ~= LP then
            local display = p.DisplayName .. " (@" .. p.Name .. ")"
            names[#names + 1] = display
            blacklistDisplayMap[display] = p.Name
        end
    end
    table.sort(names)
    return names
end

local function getCurrentBlacklistSelections()
    local sel = {}
    for display, userName in blacklistDisplayMap do
        if blacklist[userName] then
            sel[#sel + 1] = display
        end
    end
    return sel
end

local blacklistDropdownRef = nil

local blLabel = ABBlacklist:CreateLabel({
    Name = "Blacklisted Players", Icon = NebulaIcons:GetIcon('user', 'Lucide')
}, "BLPlayerLabel")

blacklistDropdownRef = blLabel:AddDropdown({
    Options = getBlacklistPlayerNames(),
    CurrentOptions = getCurrentBlacklistSelections(),
    MultipleOptions = true,
    Placeholder = "Select players...",
    Callback = function(O)
        blacklist = {}
        for i = 1, #O do
            local userName = blacklistDisplayMap[O[i]]
            if userName then
                blacklist[userName] = true
            end
        end
        currentTarget = nil
    end,
}, "BLPlayerDropdown")

ABBlacklist:CreateDivider()

ABBlacklist:CreateButton({
    Name = "Refresh Player List", Icon = NebulaIcons:GetIcon('refresh-cw', 'Lucide'),
    Callback = function()
        if blacklistDropdownRef and blacklistDropdownRef.SetOptions then
            blacklistDropdownRef:SetOptions(getBlacklistPlayerNames())
        end
    end,
}, "BLRefreshButton")

ABBlacklist:CreateButton({
    Name = "Clear Blacklist", Icon = NebulaIcons:GetIcon('trash-2', 'Lucide'),
    Callback = function()
        blacklist = {}
        if blacklistDropdownRef and blacklistDropdownRef.SetOptions then
            blacklistDropdownRef:SetOptions(getBlacklistPlayerNames())
        end
        Starlight:Notification({
            Title = "Blacklist",
            Content = "Cleared all",
            Icon = NebulaIcons:GetIcon('trash-2', 'Lucide')
        }, "BLClearNotif")
    end,
}, "BLClearButton")

-- Column 2: Smoothing & Prediction
local ABSmoothing = AimbotTab:CreateGroupbox({
    Name = "Smoothing & Prediction", Icon = NebulaIcons:GetIcon('sliders', 'Lucide'), Column = 2
}, "ABSmoothing")

ABSmoothing:CreateSlider({
    Name = "Smoothness", Icon = NebulaIcons:GetIcon('move', 'Lucide'),
    Range = {1, 50}, Increment = 1, CurrentValue = 15, Suffix = "",
    Callback = function(V) AimbotConfig.Smoothness = V end,
}, "SmoothnessSlider")

ABSmoothing:CreateDivider()

ABSmoothing:CreateToggle({
    Name = "Enable Prediction", Icon = NebulaIcons:GetIcon('trending-up', 'Lucide'),
    CurrentValue = true, Style = 2,
    Callback = function(V) AimbotConfig.PredEnabled = V end,
}, "PredToggle")

ABSmoothing:CreateDivider()

ABSmoothing:CreateSlider({
    Name = "Prediction Strength", Icon = NebulaIcons:GetIcon('zap', 'Lucide'),
    Range = {0, 1}, Increment = 0.05, CurrentValue = 0.35, Suffix = "",
    Callback = function(V) AimbotConfig.PredStrength = V end,
}, "PredStrengthSlider")

ABSmoothing:CreateSlider({
    Name = "Prediction Smoothing", Icon = NebulaIcons:GetIcon('waves', 'Lucide'),
    Range = {0.05, 0.9}, Increment = 0.05, CurrentValue = 0.45, Suffix = "",
    Callback = function(V) AimbotConfig.PredSmoothing = V end,
}, "PredSmoothingSlider")

local ABResolver = AimbotTab:CreateGroupbox({
    Name = "Resolver", Icon = NebulaIcons:GetIcon('shield', 'Lucide'), Column = 2
}, "ABResolver")

ABResolver:CreateToggle({
    Name = "Enable Resolver", Icon = NebulaIcons:GetIcon('power', 'Lucide'),
    CurrentValue = false, Style = 2,
    Callback = function(V) AimbotConfig.ResolverEnabled = V end,
}, "ResolverToggle")

ABResolver:CreateDivider()

ABResolver:CreateLabel({
    Name = "Resolver Mode", Icon = NebulaIcons:GetIcon('layers', 'Lucide'),
}, "ResolverModeLabel"):AddDropdown({
    Options = { "Auto", "Backtrack", "Centroid" },
    CurrentOptions = { "Auto" }, Placeholder = "Select Mode",
    Callback = function(O) AimbotConfig.ResolverMode = O[1] end,
}, "ResolverModeDropdown")

ABResolver:CreateDivider()

ABResolver:CreateSlider({
    Name = "Backtrack Depth", Icon = NebulaIcons:GetIcon('clock', 'Lucide'),
    Range = { 2, 20 }, Increment = 1, CurrentValue = 6, Suffix = " frames",
    Callback = function(V) AimbotConfig.BacktrackDepth = V end,
}, "BacktrackDepthSlider")

ABResolver:CreateSlider({
    Name = "Desync Threshold", Icon = NebulaIcons:GetIcon('alert-triangle', 'Lucide'),
    Range = { 2, 25 }, Increment = 1, CurrentValue = 8, Suffix = " studs/f",
    Callback = function(V) AimbotConfig.DesyncThreshold = V end,
}, "DesyncThresholdSlider")

ABResolver:CreateSlider({
    Name = "Resolve Blend", Icon = NebulaIcons:GetIcon('sliders', 'Lucide'),
    Range = { 0.1, 1 }, Increment = 0.05, CurrentValue = 0.5, Suffix = "",
    Callback = function(V) AimbotConfig.ResolverSmooth = V end,
}, "ResolverBlendSlider")

ABResolver:CreateDivider()

ABResolver:CreateToggle({
    Name = "MoveDirection Cross-Check", Icon = NebulaIcons:GetIcon('compass', 'Lucide'),
    CurrentValue = true, Style = 2,
    Callback = function(V) AimbotConfig.UseMoveDir = V end,
}, "MoveDirToggle")

-- Column 2: FOV Circle Visuals
local ABFOVVisuals = AimbotTab:CreateGroupbox({
    Name = "FOV Circle", Icon = NebulaIcons:GetIcon('eye', 'Lucide'), Column = 2
}, "ABFOVVisuals")

ABFOVVisuals:CreateToggle({
    Name = "Show FOV Circle", Icon = NebulaIcons:GetIcon('circle', 'Lucide'),
    CurrentValue = true, Style = 2,
    Callback = function(V) AimbotConfig.ShowFOV = V end,
}, "ABShowFOVToggle")

ABFOVVisuals:CreateDivider()

ABFOVVisuals:CreateSlider({
    Name = "Ring Thickness", Icon = NebulaIcons:GetIcon('maximize-2', 'Lucide'),
    Range = {1, 6}, Increment = 0.5, CurrentValue = 2, Suffix = " px",
    Callback = function(V) AimbotConfig.FOVThickness = V end,
}, "ABFOVThicknessSlider")

ABFOVVisuals:CreateSlider({
    Name = "Ring Opacity", Icon = NebulaIcons:GetIcon('eye', 'Lucide'),
    Range = {0, 1}, Increment = 0.05, CurrentValue = 1, Suffix = "",
    Callback = function(V) AimbotConfig.FOVOpacity = V end,
}, "ABFOVOpacitySlider")

ABFOVVisuals:CreateDivider()

ABFOVVisuals:CreateToggle({
    Name = "Outer Outline", Icon = NebulaIcons:GetIcon('circle', 'Lucide'),
    CurrentValue = true, Style = 2,
    Callback = function(V) AimbotConfig.OutlineEnabled = V end,
}, "ABOutlineToggle")

ABFOVVisuals:CreateSlider({
    Name = "Outline Gap", Icon = NebulaIcons:GetIcon('move', 'Lucide'),
    Range = {1, 10}, Increment = 1, CurrentValue = 3, Suffix = " px",
    Callback = function(V) AimbotConfig.OutlineOffset = V end,
}, "ABOutlineOffsetSlider")

ABFOVVisuals:CreateSlider({
    Name = "Outline Thickness", Icon = NebulaIcons:GetIcon('minus', 'Lucide'),
    Range = {0.5, 4}, Increment = 0.5, CurrentValue = 1, Suffix = " px",
    Callback = function(V) AimbotConfig.OutlineThickness = V end,
}, "ABOutlineThicknessSlider")

ABFOVVisuals:CreateSlider({
    Name = "Outline Opacity", Icon = NebulaIcons:GetIcon('eye', 'Lucide'),
    Range = {0, 1}, Increment = 0.05, CurrentValue = 0.4, Suffix = "",
    Callback = function(V) AimbotConfig.OutlineOpacity = V end,
}, "ABOutlineOpacitySlider")

ABFOVVisuals:CreateLabel({
    Name = "Outline Color", Icon = NebulaIcons:GetIcon('palette', 'Lucide')
}, "ABOutlineColorLabel"):AddColorPicker({
    CurrentValue = Color3.fromRGB(255, 255, 255),
    Callback = function(C) AimbotConfig.OutlineColor = C end,
}, "ABOutlineColorPicker")

-- Column 2: Animation
local ABAnimGroup = AimbotTab:CreateGroupbox({
    Name = "Circle Animation", Icon = NebulaIcons:GetIcon('sparkles', 'Lucide'), Column = 2
}, "ABAnimGroup")

ABAnimGroup:CreateLabel({
    Name = "Animation Style", Icon = NebulaIcons:GetIcon('wand-2', 'Lucide')
}, "ABAnimStyleLabel"):AddDropdown({
    Options = {"None", "Rotating Gradient", "Rainbow Sweep", "Plasma", "Neon Pulse"},
    CurrentOptions = {"Rotating Gradient"},
    Placeholder = "Select Style",
    Callback = function(O) if O and O[1] then AimbotConfig.AnimStyle = O[1] end end,
}, "ABAnimStyleDropdown")

ABAnimGroup:CreateDivider()

ABAnimGroup:CreateSlider({
    Name = "Animation Speed", Icon = NebulaIcons:GetIcon('gauge', 'Lucide'),
    Range = {0.1, 5}, Increment = 0.1, CurrentValue = 1.5, Suffix = "x",
    Callback = function(V) AimbotConfig.AnimSpeed = V end,
}, "ABAnimSpeedSlider")

ABAnimGroup:CreateDivider()

ABAnimGroup:CreateLabel({
    Name = "Color 1 (Primary)", Icon = NebulaIcons:GetIcon('palette', 'Lucide')
}, "ABColor1Label"):AddColorPicker({
    CurrentValue = Color3.fromRGB(0, 200, 255),
    Callback = function(C) AimbotConfig.FOVColor1 = C end,
}, "ABColor1Picker")

ABAnimGroup:CreateLabel({
    Name = "Color 2 (Secondary)", Icon = NebulaIcons:GetIcon('palette', 'Lucide')
}, "ABColor2Label"):AddColorPicker({
    CurrentValue = Color3.fromRGB(255, 0, 128),
    Callback = function(C) AimbotConfig.FOVColor2 = C end,
}, "ABColor2Picker")

ABAnimGroup:CreateLabel({
    Name = "Color 3 (Accent)", Icon = NebulaIcons:GetIcon('palette', 'Lucide')
}, "ABColor3Label"):AddColorPicker({
    CurrentValue = Color3.fromRGB(128, 0, 255),
    Callback = function(C) AimbotConfig.FOVColor3 = C end,
}, "ABColor3Picker")

end
buildAimbotTabUI()

local function buildGunModsTabUI()
-- ═══════════════════════════════════════════
-- GUN MODS TAB (Silent Aim + Clip Dump)
-- ═══════════════════════════════════════════
local GunTab = MainSection:CreateTab({
    Name = "Gun Mods", Icon = NebulaIcons:GetIcon('zap', 'Lucide'), Columns = 2
}, "GunTab")

-- Column 1: Silent Aim
local SilentAimGroup = GunTab:CreateGroupbox({
    Name = "Silent Aim", Icon = NebulaIcons:GetIcon('eye-off', 'Lucide'), Column = 1
}, "SilentAimGroup")

SilentAimGroup:CreateToggle({
    Name = "Enable Bullet Redirect", Icon = NebulaIcons:GetIcon('power', 'Lucide'),
    CurrentValue = false, Style = 2,
    Callback = function(V)
        AimConfig.Enabled = V
        Starlight:Notification({
            Title = "Silent Aim",
            Content = V and "Enabled" or "Disabled",
            Icon = NebulaIcons:GetIcon(V and 'check-circle' or 'x-circle', 'Lucide')
        }, "AimToggleNotif")
    end,
}, "AimEnableToggle")

SilentAimGroup:CreateDivider()

SilentAimGroup:CreateSlider({
    Name = "Hit Chance", Icon = NebulaIcons:GetIcon('percent', 'Lucide'),
    Range = {0, 100}, Increment = 1, CurrentValue = 70, Suffix = "%",
    Callback = function(V) AimConfig.HitChance = V end,
}, "HitChanceSlider")

SilentAimGroup:CreateDivider()

SilentAimGroup:CreateSlider({
    Name = "FOV Radius", Icon = NebulaIcons:GetIcon('circle', 'Lucide'),
    Range = {30, 600}, Increment = 5, CurrentValue = 100, Suffix = " px",
    Callback = function(V) AimConfig.FOVRadius = V end,
}, "SilentFOVSlider")

SilentAimGroup:CreateDivider()



-- Column 2: Gun Mods
local GunModsGroup = GunTab:CreateGroupbox({
    Name = "Gun Mods", Icon = NebulaIcons:GetIcon('zap', 'Lucide'), Column = 2
}, "GunModsGroup")

GunModsGroup:CreateToggle({
    Name = "No Recoil", Icon = NebulaIcons:GetIcon('lock', 'Lucide'),
    CurrentValue = false, Style = 2,
    Callback = function(V) GunConfig.NoRecoil = V end,
}, "NoRecoilToggle")

GunModsGroup:CreateToggle({
    Name = "Rapid Fire", Icon = NebulaIcons:GetIcon('zap', 'Lucide'),
    CurrentValue = false, Style = 2,
    Callback = function(V) GunConfig.RapidFire = V end,
}, "RapidFireToggle")

GunModsGroup:CreateSlider({
    Name = "Rapid Fire Delay", Icon = NebulaIcons:GetIcon('clock', 'Lucide'),
    Range = {0.01, 0.15}, Increment = 0.01, CurrentValue = 0.03, Suffix = "s",
    Callback = function(V) GunConfig.RapidDelay = V end,
}, "RapidDelaySlider")

GunModsGroup:CreateDivider()

GunModsGroup:CreateToggle({
    Name = "Auto Shoot", Icon = NebulaIcons:GetIcon('crosshair', 'Lucide'),
    CurrentValue = false, Style = 2,
    Callback = function(V) GunConfig.AutoShoot = V end,
}, "AutoShootToggle")

GunModsGroup:CreateDivider()

GunModsGroup:CreateToggle({
    Name = "Clip Dump", Icon = NebulaIcons:GetIcon('layers', 'Lucide'),
    CurrentValue = false, Style = 2,
    Callback = function(V) GunConfig.ClipDump = V end,
}, "ClipDumpToggle")

GunModsGroup:CreateSlider({
    Name = "Dump Delay", Icon = NebulaIcons:GetIcon('clock', 'Lucide'),
    Range = {0.02, 0.5}, Increment = 0.01, CurrentValue = 0.06, Suffix = "s",
    Callback = function(V) GunConfig.DumpDelay = V end,
}, "DumpDelaySlider")

end
buildGunModsTabUI()

local function buildVisualsTabUI()
-- ═══════════════════════════════════════════
-- VISUALS TAB
-- ═══════════════════════════════════════════
local VisualsTab = MainSection:CreateTab({
    Name = "Visuals", Icon = NebulaIcons:GetIcon('eye', 'Lucide'), Columns = 2
}, "VisualsTab")

-- Column 1: Aim Card
local AimCard = VisualsTab:CreateGroupbox({
    Name = "Aim", Icon = NebulaIcons:GetIcon('crosshair', 'Lucide'), Column = 1
}, "AimCard")

AimCard:CreateToggle({
    Name = "Enable Aim Visuals", Icon = NebulaIcons:GetIcon('power', 'Lucide'),
    CurrentValue = false, Style = 2,
    Callback = function(V)
        VisualsConfig.Enabled = V
        if not V then hideAllLines() end
    end,
}, "VisualsEnableToggle")

AimCard:CreateDivider()

AimCard:CreateToggle({
    Name = "Aim Line", Icon = NebulaIcons:GetIcon('minus', 'Lucide'),
    CurrentValue = true, Style = 2,
    Callback = function(V) VisualsConfig.AimLine = V end,
}, "AimLineToggle")

AimCard:CreateLabel({
    Name = "Aim Line Color", Icon = NebulaIcons:GetIcon('palette', 'Lucide')
}, "AimLineColorLabel"):AddColorPicker({
    CurrentValue = Color3.fromRGB(0, 200, 255),
    Callback = function(C) VisualsConfig.AimLineColor = C end,
}, "AimLineColorPicker")

AimCard:CreateSlider({
    Name = "Aim Line Width", Icon = NebulaIcons:GetIcon('maximize-2', 'Lucide'),
    Range = {0.01, 0.2}, Increment = 0.01, CurrentValue = 0.06, Suffix = "",
    Callback = function(V) VisualsConfig.AimLineWidth = V end,
}, "AimLineWidthSlider")

AimCard:CreateSlider({
    Name = "Aim Line Opacity", Icon = NebulaIcons:GetIcon('droplet', 'Lucide'),
    Range = {0, 1}, Increment = 0.05, CurrentValue = 0.5, Suffix = "",
    Callback = function(V) VisualsConfig.AimLineOpacity = V end,
}, "AimLineOpacitySlider")

AimCard:CreateDivider()

AimCard:CreateToggle({
    Name = "Prediction Line", Icon = NebulaIcons:GetIcon('trending-up', 'Lucide'),
    CurrentValue = true, Style = 2,
    Callback = function(V) VisualsConfig.PredLine = V end,
}, "PredLineToggle")

AimCard:CreateLabel({
    Name = "Prediction Line Color", Icon = NebulaIcons:GetIcon('palette', 'Lucide')
}, "PredLineColorLabel"):AddColorPicker({
    CurrentValue = Color3.fromRGB(255, 100, 50),
    Callback = function(C) VisualsConfig.PredLineColor = C end,
}, "PredLineColorPicker")

AimCard:CreateSlider({
    Name = "Pred Line Width", Icon = NebulaIcons:GetIcon('maximize-2', 'Lucide'),
    Range = {0.01, 0.2}, Increment = 0.01, CurrentValue = 0.05, Suffix = "",
    Callback = function(V) VisualsConfig.PredLineWidth = V end,
}, "PredLineWidthSlider")

AimCard:CreateSlider({
    Name = "Pred Line Opacity", Icon = NebulaIcons:GetIcon('droplet', 'Lucide'),
    Range = {0, 1}, Increment = 0.05, CurrentValue = 0.4, Suffix = "",
    Callback = function(V) VisualsConfig.PredLineOpacity = V end,
}, "PredLineOpacitySlider")

-- Column 2: Velocity
local VelocityCard = VisualsTab:CreateGroupbox({
    Name = "Velocity", Icon = NebulaIcons:GetIcon('activity', 'Lucide'), Column = 2
}, "VelocityCard")

VelocityCard:CreateToggle({
    Name = "Velocity Arrow", Icon = NebulaIcons:GetIcon('arrow-right', 'Lucide'),
    CurrentValue = true, Style = 2,
    Callback = function(V) VisualsConfig.VelocityLine = V end,
}, "VelocityLineToggle")

VelocityCard:CreateLabel({
    Name = "Velocity Color", Icon = NebulaIcons:GetIcon('palette', 'Lucide')
}, "VelocityColorLabel"):AddColorPicker({
    CurrentValue = Color3.fromRGB(100, 255, 100),
    Callback = function(C) VisualsConfig.VelocityColor = C end,
}, "VelocityColorPicker")

VelocityCard:CreateSlider({
    Name = "Arrow Width", Icon = NebulaIcons:GetIcon('maximize-2', 'Lucide'),
    Range = {0.01, 0.2}, Increment = 0.01, CurrentValue = 0.04, Suffix = "",
    Callback = function(V) VisualsConfig.VelocityWidth = V end,
}, "VelocityWidthSlider")

VelocityCard:CreateSlider({
    Name = "Arrow Opacity", Icon = NebulaIcons:GetIcon('droplet', 'Lucide'),
    Range = {0, 1}, Increment = 0.05, CurrentValue = 0.35, Suffix = "",
    Callback = function(V) VisualsConfig.VelocityOpacity = V end,
}, "VelocityOpacitySlider")

VelocityCard:CreateSlider({
    Name = "Arrow Length Scale", Icon = NebulaIcons:GetIcon('ruler', 'Lucide'),
    Range = {0.05, 0.5}, Increment = 0.01, CurrentValue = 0.12, Suffix = "",
    Callback = function(V) VisualsConfig.VelocityScale = V end,
}, "VelocityScaleSlider")

-- Column 1: ESP
local ESPCard = VisualsTab:CreateGroupbox({
    Name = "ESP", Icon = NebulaIcons:GetIcon('scan', 'Lucide'), Column = 1
}, "ESPCard")

ESPCard:CreateToggle({
    Name = "Enable ESP", Icon = NebulaIcons:GetIcon('power', 'Lucide'),
    CurrentValue = false, Style = 2,
    Callback = function(V)
        VisualsConfig.ESPEnabled = V
        if not V then clearAllESP() end
    end,
}, "ESPEnableToggle")

ESPCard:CreateDivider()

ESPCard:CreateToggle({
    Name = "Bounding Box", Icon = NebulaIcons:GetIcon('square', 'Lucide'),
    CurrentValue = true, Style = 2,
    Callback = function(V) VisualsConfig.ESPBox = V end,
}, "ESPBoxToggle")

ESPCard:CreateToggle({
    Name = "Name", Icon = NebulaIcons:GetIcon('user', 'Lucide'),
    CurrentValue = true, Style = 2,
    Callback = function(V) VisualsConfig.ESPName = V end,
}, "ESPNameToggle")

ESPCard:CreateToggle({
    Name = "Health Bar", Icon = NebulaIcons:GetIcon('heart', 'Lucide'),
    CurrentValue = true, Style = 2,
    Callback = function(V) VisualsConfig.ESPHealth = V end,
}, "ESPHealthToggle")

ESPCard:CreateToggle({
    Name = "Distance", Icon = NebulaIcons:GetIcon('ruler', 'Lucide'),
    CurrentValue = true, Style = 2,
    Callback = function(V) VisualsConfig.ESPDistance = V end,
}, "ESPDistToggle")

ESPCard:CreateToggle({
    Name = "Weapon", Icon = NebulaIcons:GetIcon('sword', 'Lucide'),
    CurrentValue = true, Style = 2,
    Callback = function(V) VisualsConfig.ESPWeapon = V end,
}, "ESPWeaponToggle")

ESPCard:CreateDivider()

ESPCard:CreateSlider({
    Name = "Max Distance", Icon = NebulaIcons:GetIcon('maximize', 'Lucide'),
    Range = {50, 2000}, Increment = 50, CurrentValue = 1000, Suffix = "",
    Callback = function(V) VisualsConfig.ESPMaxDist = V end,
}, "ESPMaxDistSlider")

ESPCard:CreateSlider({
    Name = "Font Size", Icon = NebulaIcons:GetIcon('type', 'Lucide'),
    Range = {8, 20}, Increment = 1, CurrentValue = 13, Suffix = "px",
    Callback = function(V) VisualsConfig.ESPFontSize = V end,
}, "ESPFontSizeSlider")

-- Column 2: ESP Colors
local ESPColors = VisualsTab:CreateGroupbox({
    Name = "ESP Colors", Icon = NebulaIcons:GetIcon('palette', 'Lucide'), Column = 2
}, "ESPColors")

ESPColors:CreateLabel({
    Name = "Box Color", Icon = NebulaIcons:GetIcon('square', 'Lucide')
}, "ESPBoxColorLabel"):AddColorPicker({
    CurrentValue = Color3.fromRGB(255, 255, 255),
    Callback = function(C) VisualsConfig.ESPBoxColor = C end,
}, "ESPBoxColorPicker")

ESPColors:CreateLabel({
    Name = "Name Color", Icon = NebulaIcons:GetIcon('user', 'Lucide')
}, "ESPNameColorLabel"):AddColorPicker({
    CurrentValue = Color3.fromRGB(255, 255, 255),
    Callback = function(C) VisualsConfig.ESPNameColor = C end,
}, "ESPNameColorPicker")

ESPColors:CreateLabel({
    Name = "Distance Color", Icon = NebulaIcons:GetIcon('ruler', 'Lucide')
}, "ESPDistColorLabel"):AddColorPicker({
    CurrentValue = Color3.fromRGB(200, 200, 200),
    Callback = function(C) VisualsConfig.ESPDistColor = C end,
}, "ESPDistColorPicker")

ESPColors:CreateLabel({
    Name = "Weapon Color", Icon = NebulaIcons:GetIcon('sword', 'Lucide')
}, "ESPWeaponColorLabel"):AddColorPicker({
    CurrentValue = Color3.fromRGB(180, 180, 255),
    Callback = function(C) VisualsConfig.ESPWeaponColor = C end,
}, "ESPWeaponColorPicker")

ESPColors:CreateDivider()

ESPColors:CreateLabel({
    Name = "Health Full", Icon = NebulaIcons:GetIcon('heart', 'Lucide')
}, "ESPHPTopLabel"):AddColorPicker({
    CurrentValue = Color3.fromRGB(0, 255, 0),
    Callback = function(C) VisualsConfig.ESPHealthTop = C end,
}, "ESPHPTopPicker")

ESPColors:CreateLabel({
    Name = "Health Empty", Icon = NebulaIcons:GetIcon('heart', 'Lucide')
}, "ESPHPBotLabel"):AddColorPicker({
    CurrentValue = Color3.fromRGB(255, 0, 0),
    Callback = function(C) VisualsConfig.ESPHealthBot = C end,
}, "ESPHPBotPicker")

-- Column 1: Chams
local ChamsCard = VisualsTab:CreateGroupbox({
    Name = "Chams", Icon = NebulaIcons:GetIcon('user', 'Lucide'), Column = 1
}, "ChamsCard")

ChamsCard:CreateToggle({
    Name = "Enable Chams", Icon = NebulaIcons:GetIcon('power', 'Lucide'),
    CurrentValue = false, Style = 2,
    Callback = function(V)
        VisualsConfig.ChamsEnabled = V
        if not V then clearAllChams() end
    end,
}, "ChamsEnableToggle")

ChamsCard:CreateDivider()

ChamsCard:CreateLabel({
    Name = "Method", Icon = NebulaIcons:GetIcon('layers', 'Lucide')
}, "ChamsMethodLabel"):AddDropdown({
    Options = {"Glow", "LayeredGlow"},
    CurrentOptions = {"LayeredGlow"},
    Placeholder = "Select Method",
    Callback = function(O)
        if O and O[1] then
            VisualsConfig.ChamsMethod = O[1]
            clearAllChams()
        end
    end,
}, "ChamsMethodDropdown")

ChamsCard:CreateSlider({
    Name = "Transparency", Icon = NebulaIcons:GetIcon('droplet', 'Lucide'),
    Range = {0, 1}, Increment = 0.05, CurrentValue = 0, Suffix = "",
    Callback = function(V) VisualsConfig.ChamsTrans = V end,
}, "ChamsTransSlider")

ChamsCard:CreateSlider({
    Name = "Glow Multiplier", Icon = NebulaIcons:GetIcon('zap', 'Lucide'),
    Range = {1, 15}, Increment = 0.5, CurrentValue = 5, Suffix = "x",
    Callback = function(V) VisualsConfig.GlowMultiplier = V end,
}, "GlowMultiplierSlider")

-- Column 2: Chams Colors
local ChamsColors = VisualsTab:CreateGroupbox({
    Name = "Chams Colors", Icon = NebulaIcons:GetIcon('palette', 'Lucide'), Column = 2
}, "ChamsColors")

ChamsColors:CreateLabel({
    Name = "Visible Color", Icon = NebulaIcons:GetIcon('eye', 'Lucide')
}, "VisColorLabel"):AddColorPicker({
    CurrentValue = Color3.fromRGB(255, 50, 50),
    Callback = function(C) VisualsConfig.VisibleColor = C end,
}, "VisColorPicker")

ChamsColors:CreateDivider()

ChamsColors:CreateLabel({
    Name = "Occluded Color", Icon = NebulaIcons:GetIcon('eye-off', 'Lucide')
}, "OccColorLabel"):AddColorPicker({
    CurrentValue = Color3.fromRGB(150, 0, 200),
    Callback = function(C) VisualsConfig.OccludedColor = C end,
}, "OccColorPicker")

ChamsColors:CreateDivider()

ChamsColors:CreateLabel({
    Name = "Glow Color", Icon = NebulaIcons:GetIcon('sparkles', 'Lucide')
}, "GlowColorLabel"):AddColorPicker({
    CurrentValue = Color3.fromRGB(0, 200, 255),
    Callback = function(C) VisualsConfig.GlowColor = C end,
}, "GlowColorPicker")

end
buildVisualsTabUI()

-- ═══════════════════════════════════════════
-- DESYNC TAB (RakNet + position overlay)
-- Built in its own function — Luau limits ~200 locals per chunk.
-- ═══════════════════════════════════════════
local function buildDesyncTabUI()
local RN_MODE_DESCS = {
    smooth  = "Realistic stable elevated ping. Your server-side position lags naturally behind your actual position.",
    jitter  = "Mimics bad WiFi. Slight random per-packet delay with bursty drops — smooth and subtle.",
    spike   = "Normal latency most of the time, then sudden heavy ping spikes every few seconds.",
    drift   = "Smooth and slight. Delay slowly climbs then snaps back — looks like a buffer filling up.",
    corrupt = "Overwrites the physics timestamp field. At high rates acts as a near-timestop on the server.",
    hybrid  = "Corruption + Gaussian delay combined. Produces freeze-frame like lag. Best for hold-key use.",
    burst   = "Hard block/open cycle. More rhythmic freeze-frame feel. Smoother to observe than corrupt.",
}

local RN_KEY_MAP = {
    ["Z"] = Enum.KeyCode.Z, ["X"] = Enum.KeyCode.X, ["C"] = Enum.KeyCode.C,
    ["V"] = Enum.KeyCode.V, ["F"] = Enum.KeyCode.F, ["G"] = Enum.KeyCode.G,
    ["H"] = Enum.KeyCode.H, ["T"] = Enum.KeyCode.T, ["Y"] = Enum.KeyCode.Y,
    ["N"] = Enum.KeyCode.N, ["M"] = Enum.KeyCode.M, ["Q"] = Enum.KeyCode.Q,
    ["E"] = Enum.KeyCode.E, ["R"] = Enum.KeyCode.R, ["LeftAlt"] = Enum.KeyCode.LeftAlt,
    ["RightAlt"] = Enum.KeyCode.RightAlt,
}
local RN_HOLD_KEY       = Enum.KeyCode.V
local RN_HOLD_MODE      = "corrupt"
local RN_HOLD_ACTIVE    = false
local RN_HOLD_ENABLED   = false
local RN_HOLD_PREV_MODE = "smooth"
local RN_HOLD_PREV_EN   = false

ActiveConnections.DS_InputBegan = UIS.InputBegan:Connect(function(inp, gpe)
    if not RN_HOLD_ENABLED then return end
    if gpe or inp.KeyCode ~= RN_HOLD_KEY then return end
    if RN_HOLD_ACTIVE then return end
    RN_HOLD_ACTIVE    = true
    RN_HOLD_PREV_MODE = RN_MODE
    RN_HOLD_PREV_EN   = RN_ENABLED
    RN_MODE = RN_HOLD_MODE
    RN_buBlocking = false; RN_buTimer = 0; RN_drCurrent = RN_DR_START
    RN_spInSpike = false; RN_spLeft = 0; RN_jtBurstLeft = 0
    if not RN_ENABLED and RN_AVAILABLE and RN_hookRef and not RN_hooked then
        RN_ENABLED = true
        local ok = pcall(raknet.add_send_hook, RN_hookRef)
        if ok then RN_hooked = true end
    end
end)
ActiveConnections.DS_InputEnded = UIS.InputEnded:Connect(function(inp)
    if not RN_HOLD_ENABLED then return end
    if inp.KeyCode ~= RN_HOLD_KEY or not RN_HOLD_ACTIVE then return end
    RN_HOLD_ACTIVE = false
    RN_MODE = RN_HOLD_PREV_MODE
    RN_buBlocking = false; RN_buTimer = 0; RN_drCurrent = RN_DR_START
    RN_spInSpike = false; RN_spLeft = 0; RN_jtBurstLeft = 0
    if not RN_HOLD_PREV_EN then
        RN_ENABLED = false
        if RN_AVAILABLE and RN_hookRef and RN_hooked then
            pcall(raknet.remove_send_hook, RN_hookRef)
            RN_hooked = false
        end
    end
end)

local DesyncTab = MainSection:CreateTab({
    Name = "Desync", Icon = NebulaIcons:GetIcon('wifi-off', 'Lucide'), Columns = 2
}, "DesyncTab")

local DesyncWarningBox = DesyncTab:CreateGroupbox({
    Name = "Warning", Icon = NebulaIcons:GetIcon('alert-triangle', 'Lucide'), Column = 1
}, "DesyncWarningBox")
DesyncWarningBox:CreateParagraph({ Name = "", Content = "Use at your own risk." }, "DesyncRiskParagraph")
DesyncWarningBox:CreateDivider()
DesyncWarningBox:CreateLabel({
    Name = RN_AVAILABLE and "✓ raknet detected" or "✗ raknet not available",
    Icon = NebulaIcons:GetIcon('cpu', 'Lucide'),
}, "RakNetStatusLabel")

local DesyncControlsBox = DesyncTab:CreateGroupbox({
    Name = "Controls", Icon = NebulaIcons:GetIcon('sliders', 'Lucide'), Column = 1
}, "DesyncControlsBox")
DesyncControlsBox:CreateToggle({
    Name = "Enable Desync", Icon = NebulaIcons:GetIcon('power', 'Lucide'),
    CurrentValue = false, Style = 2,
    Callback = function(V)
        RN_ENABLED = V
        if not (RN_AVAILABLE and RN_hookRef) then return end
        if V then
            if not RN_hooked then
                local ok = pcall(raknet.add_send_hook, RN_hookRef)
                if ok then RN_hooked = true end
            end
        else
            if RN_hooked then
                pcall(raknet.remove_send_hook, RN_hookRef)
                RN_hooked = false
            end
            RN_buBlocking = false; RN_buTimer = 0; RN_drCurrent = RN_DR_START
            RN_spInSpike = false; RN_spLeft = 0; RN_jtBurstLeft = 0
        end
    end,
}, "DesyncMasterToggle")
DesyncControlsBox:CreateDivider()
local DesyncModeDescLabel = DesyncControlsBox:CreateParagraph({
    Name = "Mode Info", Content = RN_MODE_DESCS["smooth"],
}, "DesyncModeDesc")
DesyncControlsBox:CreateLabel({
    Name = "Desync Mode", Icon = NebulaIcons:GetIcon('layers', 'Lucide'),
}, "DesyncModeLabel"):AddDropdown({
    Options = { "smooth", "jitter", "spike", "drift", "corrupt", "hybrid", "burst" },
    CurrentOptions = { "smooth" }, Placeholder = "Select Mode",
    Callback = function(O)
        RN_MODE = O[1]
        RN_buBlocking = false; RN_buTimer = 0; RN_drCurrent = RN_DR_START
        RN_spInSpike = false; RN_spLeft = 0; RN_jtBurstLeft = 0
        DesyncModeDescLabel:Set({ Content = RN_MODE_DESCS[O[1]] or "" })
    end,
}, "DesyncModeDropdown")
DesyncControlsBox:CreateDivider()

local DesyncHoldBox = DesyncTab:CreateGroupbox({
    Name = "Hold-Key Desync", Icon = NebulaIcons:GetIcon('key', 'Lucide'), Column = 1
}, "DesyncHoldBox")
DesyncHoldBox:CreateToggle({
    Name = "Enable Hold-Key", Icon = NebulaIcons:GetIcon('power', 'Lucide'),
    CurrentValue = false, Style = 2,
    Callback = function(V)
        RN_HOLD_ENABLED = V
        if not V and RN_HOLD_ACTIVE then
            RN_HOLD_ACTIVE = false
            RN_MODE = RN_HOLD_PREV_MODE
            RN_buBlocking = false; RN_buTimer = 0; RN_drCurrent = RN_DR_START
            RN_spInSpike = false; RN_spLeft = 0; RN_jtBurstLeft = 0
            if not RN_HOLD_PREV_EN then
                RN_ENABLED = false
                if RN_AVAILABLE and RN_hookRef and RN_hooked then
                    pcall(raknet.remove_send_hook, RN_hookRef)
                    RN_hooked = false
                end
            end
        end
    end,
}, "DesyncHoldToggle")
DesyncHoldBox:CreateDivider()
DesyncHoldBox:CreateParagraph({
    Name = "",
    Content = "Works on top of desync or standalone. Hold the key to activate, release to stop. Corrupt works best for a freeze-frame like effect.",
}, "DesyncHoldNote")
DesyncHoldBox:CreateDivider()
DesyncHoldBox:CreateLabel({
    Name = "Hold Key", Icon = NebulaIcons:GetIcon('keyboard', 'Lucide'),
}, "DesyncHoldKeyLabel"):AddDropdown({
    Options = { "Z", "X", "C", "V", "F", "G", "H", "T", "Y", "N", "M", "Q", "E", "R", "LeftAlt", "RightAlt" },
    CurrentOptions = { "V" }, Placeholder = "Select Key",
    Callback = function(O) RN_HOLD_KEY = RN_KEY_MAP[O[1]] or Enum.KeyCode.V end,
}, "DesyncHoldKeyDrop")
DesyncHoldBox:CreateLabel({
    Name = "Hold Mode", Icon = NebulaIcons:GetIcon('zap', 'Lucide'),
}, "DesyncHoldModeLabel"):AddDropdown({
    Options = { "smooth", "jitter", "spike", "drift", "corrupt", "hybrid", "burst" },
    CurrentOptions = { "corrupt" }, Placeholder = "Select Mode",
    Callback = function(O) RN_HOLD_MODE = O[1] end,
}, "DesyncHoldModeDrop")

local DesyncPosBox = DesyncTab:CreateGroupbox({
    Name = "Position Overlay", Icon = NebulaIcons:GetIcon('map-pin', 'Lucide'), Column = 1
}, "DesyncPosBox")
DesyncPosBox:CreateParagraph({
    Name = "",
    Content = "Cli = your client HRP. Srv = last position from the RakNet hook (actual sent pose when desync is on; ping rewind estimate for other players).",
}, "DesyncPosExplain")
DesyncPosBox:CreateDivider()
DesyncPosBox:CreateToggle({
    Name = "Show Cli / Srv Text", Icon = NebulaIcons:GetIcon('eye', 'Lucide'),
    CurrentValue = false, Style = 2,
    Callback = function(V) DesyncPosConfig.Enabled = V end,
}, "DesyncPosToggle")
DesyncPosBox:CreateToggle({
    Name = "All Players (not just you)", Icon = NebulaIcons:GetIcon('users', 'Lucide'),
    CurrentValue = false, Style = 2,
    Callback = function(V) DesyncPosConfig.AllPlayers = V end,
}, "DesyncPosAllToggle")

local DesyncSmoothBox = DesyncTab:CreateGroupbox({
    Name = "Smooth / Hybrid", Icon = NebulaIcons:GetIcon('activity', 'Lucide'), Column = 2
}, "DesyncSmoothBox")
DesyncSmoothBox:CreateParagraph({ Name = "", Content = "Used by: smooth, hybrid" }, "SmoothNote")
DesyncSmoothBox:CreateSlider({
    Name = "Base Delay", Icon = NebulaIcons:GetIcon('clock', 'Lucide'),
    Range = { 10, 300 }, Increment = 5, CurrentValue = 85, Suffix = "ms",
    Callback = function(V) RN_SM_BASE = V; RN_HY_BASE = V end,
}, "DesyncSmBase")
DesyncSmoothBox:CreateSlider({
    Name = "Std Deviation", Icon = NebulaIcons:GetIcon('bar-chart-2', 'Lucide'),
    Range = { 1, 80 }, Increment = 1, CurrentValue = 22, Suffix = "ms",
    Callback = function(V) RN_SM_STD = V; RN_HY_STD = V end,
}, "DesyncSmStd")
DesyncSmoothBox:CreateSlider({
    Name = "Min Delay", Icon = NebulaIcons:GetIcon('arrow-down', 'Lucide'),
    Range = { 0, 100 }, Increment = 1, CurrentValue = 12, Suffix = "ms",
    Callback = function(V) RN_SM_MIN = V; RN_HY_MIN = V end,
}, "DesyncSmMin")
DesyncSmoothBox:CreateSlider({
    Name = "Max Delay", Icon = NebulaIcons:GetIcon('arrow-up', 'Lucide'),
    Range = { 50, 500 }, Increment = 10, CurrentValue = 260, Suffix = "ms",
    Callback = function(V) RN_SM_MAX = V; RN_HY_MAX = V end,
}, "DesyncSmMax")
DesyncSmoothBox:CreateSlider({
    Name = "Packet Loss", Icon = NebulaIcons:GetIcon('wifi-off', 'Lucide'),
    Range = { 0, 30 }, Increment = 1, CurrentValue = 4, Suffix = "%",
    Callback = function(V) RN_SM_LOSS = V / 100 end,
}, "DesyncSmLoss")
DesyncSmoothBox:CreateSlider({
    Name = "Hybrid Corrupt Rate", Icon = NebulaIcons:GetIcon('zap', 'Lucide'),
    Range = { 0, 100 }, Increment = 5, CurrentValue = 45, Suffix = "%",
    Callback = function(V) RN_HY_CRPT = V / 100 end,
}, "DesyncHyCrpt")

local DesyncJitterBox = DesyncTab:CreateGroupbox({
    Name = "Jitter", Icon = NebulaIcons:GetIcon('radio', 'Lucide'), Column = 2
}, "DesyncJitterBox")
DesyncJitterBox:CreateParagraph({ Name = "", Content = "Used by: jitter" }, "JitterNote")
DesyncJitterBox:CreateSlider({
    Name = "Min Delay", Icon = NebulaIcons:GetIcon('arrow-down', 'Lucide'),
    Range = { 0, 100 }, Increment = 1, CurrentValue = 8, Suffix = "ms",
    Callback = function(V) RN_JT_MIN = V end,
}, "DesyncJtMin")
DesyncJitterBox:CreateSlider({
    Name = "Max Delay", Icon = NebulaIcons:GetIcon('arrow-up', 'Lucide'),
    Range = { 20, 300 }, Increment = 5, CurrentValue = 140, Suffix = "ms",
    Callback = function(V) RN_JT_MAX = V end,
}, "DesyncJtMax")
DesyncJitterBox:CreateSlider({
    Name = "Base Loss Rate", Icon = NebulaIcons:GetIcon('wifi-off', 'Lucide'),
    Range = { 0, 30 }, Increment = 1, CurrentValue = 7, Suffix = "%",
    Callback = function(V) RN_JT_LOSS = V / 100 end,
}, "DesyncJtLoss")
DesyncJitterBox:CreateSlider({
    Name = "Burst Loss Rate", Icon = NebulaIcons:GetIcon('zap', 'Lucide'),
    Range = { 10, 90 }, Increment = 5, CurrentValue = 55, Suffix = "%",
    Callback = function(V) RN_JT_BRST = V / 100 end,
}, "DesyncJtBrst")

local DesyncSpikeBox = DesyncTab:CreateGroupbox({
    Name = "Spike", Icon = NebulaIcons:GetIcon('trending-up', 'Lucide'), Column = 2
}, "DesyncSpikeBox")
DesyncSpikeBox:CreateParagraph({ Name = "", Content = "Used by: spike" }, "SpikeNote")
DesyncSpikeBox:CreateSlider({
    Name = "Normal Delay", Icon = NebulaIcons:GetIcon('minus', 'Lucide'),
    Range = { 5, 100 }, Increment = 1, CurrentValue = 28, Suffix = "ms",
    Callback = function(V) RN_SP_NORM = V end,
}, "DesyncSpNorm")
DesyncSpikeBox:CreateSlider({
    Name = "Spike Size", Icon = NebulaIcons:GetIcon('arrow-up', 'Lucide'),
    Range = { 100, 800 }, Increment = 10, CurrentValue = 420, Suffix = "ms",
    Callback = function(V) RN_SP_SIZE = V end,
}, "DesyncSpSize")
DesyncSpikeBox:CreateSlider({
    Name = "Spike Variance", Icon = NebulaIcons:GetIcon('shuffle', 'Lucide'),
    Range = { 0, 200 }, Increment = 10, CurrentValue = 80, Suffix = "ms",
    Callback = function(V) RN_SP_VAR = V end,
}, "DesyncSpVar")
DesyncSpikeBox:CreateSlider({
    Name = "Spike Probability", Icon = NebulaIcons:GetIcon('percent', 'Lucide'),
    Range = { 0, 10 }, Increment = 1, CurrentValue = 2, Suffix = "%",
    Callback = function(V) RN_SP_PROB = V / 100 end,
}, "DesyncSpProb")
DesyncSpikeBox:CreateSlider({
    Name = "Spike Duration", Icon = NebulaIcons:GetIcon('clock', 'Lucide'),
    Range = { 1, 30 }, Increment = 1, CurrentValue = 10, Suffix = " pkts",
    Callback = function(V) RN_SP_DUR = V end,
}, "DesyncSpDur")

local DesyncMiscModesBox = DesyncTab:CreateGroupbox({
    Name = "Drift / Corrupt / Burst", Icon = NebulaIcons:GetIcon('settings-2', 'Lucide'), Column = 2
}, "DesyncMiscModesBox")
DesyncMiscModesBox:CreateParagraph({
    Name = "Drift", Content = "Delay climbs from start to max then snaps back.",
}, "DriftNote")
DesyncMiscModesBox:CreateSlider({
    Name = "Start Delay", Icon = NebulaIcons:GetIcon('arrow-down', 'Lucide'),
    Range = { 0, 100 }, Increment = 1, CurrentValue = 15, Suffix = "ms",
    Callback = function(V) RN_DR_START = V; RN_drCurrent = V end,
}, "DesyncDrStart")
DesyncMiscModesBox:CreateSlider({
    Name = "Rate per Packet", Icon = NebulaIcons:GetIcon('trending-up', 'Lucide'),
    Range = { 1, 20 }, Increment = 1, CurrentValue = 4, Suffix = "ms",
    Callback = function(V) RN_DR_RATE = V end,
}, "DesyncDrRate")
DesyncMiscModesBox:CreateSlider({
    Name = "Max Delay", Icon = NebulaIcons:GetIcon('arrow-up', 'Lucide'),
    Range = { 50, 500 }, Increment = 10, CurrentValue = 200, Suffix = "ms",
    Callback = function(V) RN_DR_MAX = V end,
}, "DesyncDrMax")
DesyncMiscModesBox:CreateDivider()
DesyncMiscModesBox:CreateParagraph({
    Name = "Corrupt",
    Content = "Overwrites the physics timestamp field. Packets still arrive but server cannot reconcile position.",
}, "CorruptNote")
DesyncMiscModesBox:CreateSlider({
    Name = "Corrupt Rate", Icon = NebulaIcons:GetIcon('zap', 'Lucide'),
    Range = { 0, 100 }, Increment = 5, CurrentValue = 55, Suffix = "%",
    Callback = function(V) RN_CO_RATE = V / 100 end,
}, "DesyncCoRate")
DesyncMiscModesBox:CreateToggle({
    Name = "Also Delay Corrupted", Icon = NebulaIcons:GetIcon('clock', 'Lucide'),
    CurrentValue = false, Style = 2,
    Callback = function(V) RN_CO_ALSO = V end,
}, "DesyncCoAlso")
DesyncMiscModesBox:CreateSlider({
    Name = "Corrupt Delay", Icon = NebulaIcons:GetIcon('timer', 'Lucide'),
    Range = { 0, 150 }, Increment = 5, CurrentValue = 30, Suffix = "ms",
    Callback = function(V) RN_CO_MS = V end,
}, "DesyncCoMs")
DesyncMiscModesBox:CreateDivider()
DesyncMiscModesBox:CreateParagraph({
    Name = "Burst",
    Content = "Hard block for BLOCK_MS, open for OPEN_MS. Least realistic — prefer smooth or spike.",
}, "BurstNote")
DesyncMiscModesBox:CreateSlider({
    Name = "Block Duration", Icon = NebulaIcons:GetIcon('pause', 'Lucide'),
    Range = { 50, 500 }, Increment = 10, CurrentValue = 190, Suffix = "ms",
    Callback = function(V) RN_BU_BLOCK = V end,
}, "DesyncBuBlock")
DesyncMiscModesBox:CreateSlider({
    Name = "Open Duration", Icon = NebulaIcons:GetIcon('play', 'Lucide'),
    Range = { 100, 2000 }, Increment = 50, CurrentValue = 650, Suffix = "ms",
    Callback = function(V) RN_BU_OPEN = V end,
}, "DesyncBuOpen")

end
buildDesyncTabUI()

local function buildKillTabUI()
-- ═══════════════════════════════════════════
-- AUTO KILL TAB
-- ═══════════════════════════════════════════
local KillTab = MainSection:CreateTab({
    Name = "Auto Kill", Icon = NebulaIcons:GetIcon('skull', 'Lucide'), Columns = 2
}, "KillTab")

-- Column 1: Controls
local KillControls = KillTab:CreateGroupbox({
    Name = "Controls", Icon = NebulaIcons:GetIcon('sword', 'Lucide'), Column = 1
}, "KillControls")

KillControls:CreateToggle({
    Name = "Enable Auto Kill", Icon = NebulaIcons:GetIcon('power', 'Lucide'),
    CurrentValue = false, Style = 2,
    Callback = function(V)
        KillConfig.AutoKill = V
        if V then
            doAutoKillLoop()
        else
            stopAutoKill()
        end
        Starlight:Notification({
            Title = "Auto Kill",
            Content = V and "Enabled — equips knife & kills nearby players" or "Disabled",
            Icon = NebulaIcons:GetIcon(V and 'check-circle' or 'x-circle', 'Lucide')
        }, "AutoKillNotif")
    end,
}, "AutoKillToggle")

KillControls:CreateDivider()

KillControls:CreateButton({
    Name = "Stop & Return", Icon = NebulaIcons:GetIcon('square', 'Lucide'),
    Callback = function()
        stopAutoKill()
        Starlight:Notification({
            Title = "Auto Kill",
            Content = "Stopped — returned to original position",
            Icon = NebulaIcons:GetIcon('square', 'Lucide')
        }, "AutoKillStopNotif")
    end,
}, "AutoKillStopButton")

KillControls:CreateDivider()

KillControls:CreateToggle({
    Name = "Single Target Mode", Icon = NebulaIcons:GetIcon('target', 'Lucide'),
    CurrentValue = false, Style = 2,
    Callback = function(V) KillConfig.SingleTarget = V end,
}, "SingleTargetToggle")

-- Column 1: Target Selection
local KillTarget = KillTab:CreateGroupbox({
    Name = "Target Selection", Icon = NebulaIcons:GetIcon('crosshair', 'Lucide'), Column = 1
}, "KillTarget")

local playerDisplayMap = {}

local function getPlayerNames()
    local names = {}
    playerDisplayMap = {}
    for _, p in Players:GetPlayers() do
        if p ~= LP then
            local display = p.DisplayName .. " (@" .. p.Name .. ")"
            names[#names + 1] = display
            playerDisplayMap[display] = p
        end
    end
    return names
end

local targetDropdownRef = nil

local targetLabel = KillTarget:CreateLabel({
    Name = "Select Target", Icon = NebulaIcons:GetIcon('user', 'Lucide')
}, "TargetLabel")

targetDropdownRef = targetLabel:AddDropdown({
    Options = getPlayerNames(),
    CurrentOptions = {},
    Placeholder = "Pick a player...",
    Callback = function(O)
        if not O or not O[1] then return end
        local display = O[1]
        local p = playerDisplayMap[display]
        if p then
            selectedTarget = p
            Starlight:Notification({
                Title = "Auto Kill",
                Content = "Target set: " .. p.DisplayName,
                Icon = NebulaIcons:GetIcon('crosshair', 'Lucide')
            }, "TargetSetNotif")
        end
    end,
}, "TargetDropdown")

KillTarget:CreateButton({
    Name = "Refresh Player List", Icon = NebulaIcons:GetIcon('refresh-cw', 'Lucide'),
    Callback = function()
        if targetDropdownRef and targetDropdownRef.SetOptions then
            targetDropdownRef:SetOptions(getPlayerNames())
        end
    end,
}, "RefreshPlayersButton")

-- Column 2: Timing
local KillTiming = KillTab:CreateGroupbox({
    Name = "Timing", Icon = NebulaIcons:GetIcon('clock', 'Lucide'), Column = 2
}, "KillTiming")

KillTiming:CreateSlider({
    Name = "Depth (Studs Under)", Icon = NebulaIcons:GetIcon('arrow-down', 'Lucide'),
    Range = {3, 7}, Increment = 0.1, CurrentValue = 6, Suffix = " studs",
    Callback = function(V) KillConfig.Depth = V end,
}, "DepthSlider")

KillTiming:CreateDivider()

KillTiming:CreateSlider({
    Name = "Swing Delay", Icon = NebulaIcons:GetIcon('swords', 'Lucide'),
    Range = {0.1, 1.0}, Increment = 0.05, CurrentValue = 0.35, Suffix = "s",
    Callback = function(V) KillConfig.SwingDelay = V end,
}, "SwingDelaySlider")

end
buildKillTabUI()

-- ═══════════════════════════════════════════
-- SETTINGS TAB
-- ═══════════════════════════════════════════
local SettingsTab = MainSection:CreateTab({
    Name = "Settings", Icon = NebulaIcons:GetIcon('settings', 'Lucide'), Columns = 2
}, "SettingsTab")
SettingsTab:BuildThemeGroupbox(1)
SettingsTab:BuildConfigGroupbox(2)

Starlight:LoadAutoloadTheme()

-- ══════════════════════════════════════════════════════════════════════════════
-- CLEANUP
-- ══════════════════════════════════════════════════════════════════════════════

Starlight:OnDestroy(function()
    stopAutoKill()
    AimbotConfig.Enabled = false
    aimbotActive = false
    currentTarget = nil
    if autoShootActive then
        pcall(mouse1release)
        autoShootActive = false
    end
    if RN_AVAILABLE and RN_hookRef and RN_hooked then
        pcall(raknet.remove_send_hook, RN_hookRef)
        RN_hooked = false
    end
    clearAllDesyncPosDrawings()
    for k, conn in ActiveConnections do
        pcall(function() conn:Disconnect() end)
    end
    ActiveConnections = {}
    for i = 1, SEGMENTS do
        pcall(function() fovMainSegments[i]:Remove() end)
        pcall(function() fovOutlineSegments[i]:Remove() end)
    end
    pcall(function() aimLine:Remove() end)
    pcall(function() predLine:Remove() end)
    pcall(function() velLine:Remove() end)
    clearAllESP()
    clearAllChams()
end)

Starlight:LoadAutoloadConfig()

disableAC()

Starlight:Notification({
    Title = "X3 Customs", Content = "Loaded",
    Icon = NebulaIcons:GetIcon('check', 'Lucide')
}, "InitNotif")

_genv.__DH_CUSTOMS_LOADED = true
end -- runMain

-- ══════════════════════════════════════════════════════════════════════════════
-- LICENSE / KEY SYSTEM (same pattern as lol3.lua)
-- ══════════════════════════════════════════════════════════════════════════════
local LICENSE_WORKER_BASE = LPH_ENCSTR("https://license-auth.ravindra8991gjbdh.workers.dev")
local LICENSE_JSON_FILE   = LPH_ENCSTR("DH_Customs/license.json")
local LICENSE_LEGACY_KEY  = LPH_ENCSTR("dh_customs_license.key")

local HttpServiceLicense = game:GetService("HttpService")

local function trimLicense(s)
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function licenseJsonPath()
    if type(getgenv().DH_LICENSE_JSON_FILE) == "string" and trimLicense(getgenv().DH_LICENSE_JSON_FILE) ~= "" then
        return trimLicense(getgenv().DH_LICENSE_JSON_FILE)
    end
    return LICENSE_JSON_FILE
end

local function ensureLicenseDir(filePath)
    if typeof(isfolder) ~= "function" or typeof(makefolder) ~= "function" then return end
    local parent = filePath:match("^(.+)/[^/]+$")
    if not parent or parent == "" then return end
    pcall(function()
        if not isfolder(parent) then makefolder(parent) end
    end)
end

local function readSavedLicenseKey()
    if typeof(isfile) ~= "function" or typeof(readfile) ~= "function" then return nil end
    local jsonPath = licenseJsonPath()
    local okJ, exJ = pcall(isfile, jsonPath)
    if okJ and exJ then
        local okR, raw = pcall(readfile, jsonPath)
        if okR and type(raw) == "string" and raw ~= "" then
            local okD, data = pcall(HttpServiceLicense.JSONDecode, HttpServiceLicense, raw)
            if okD and type(data) == "table" then
                local k = data.licenseKey or data.key
                if type(k) == "string" then
                    k = trimLicense(k)
                    if k ~= "" then return k end
                end
            end
        end
    end
    local okL, exL = pcall(isfile, LICENSE_LEGACY_KEY)
    if okL and exL then
        local okR2, raw2 = pcall(readfile, LICENSE_LEGACY_KEY)
        if okR2 and type(raw2) == "string" then
            local k2 = trimLicense(raw2)
            if k2 ~= "" then return k2 end
        end
    end
    return nil
end

local function saveLicenseKey(key)
    if typeof(writefile) ~= "function" then return end
    local k = trimLicense(key)
    local path = licenseJsonPath()
    ensureLicenseDir(path)
    pcall(function()
        writefile(path, HttpServiceLicense:JSONEncode({ licenseKey = k }))
    end)
    pcall(function()
        if typeof(isfile) == "function" and typeof(delfile) == "function" then
            local ok, ex = pcall(isfile, LICENSE_LEGACY_KEY)
            if ok and ex then delfile(LICENSE_LEGACY_KEY) end
        end
    end)
end

local function clearLicenseFiles()
    pcall(function()
        if typeof(isfile) ~= "function" or typeof(delfile) ~= "function" then return end
        for _, f in { licenseJsonPath(), LICENSE_LEGACY_KEY } do
            local ok, ex = pcall(isfile, f)
            if ok and ex then pcall(delfile, f) end
        end
    end)
end

local function getLicenseHwid()
    if typeof(gethwid) == "function" then
        local ok, h = pcall(gethwid)
        if ok and type(h) == "string" and trimLicense(h) ~= "" then
            return trimLicense(h)
        end
    end
    return nil
end

local function authLicenseKey(key, hwid)
    local base = LICENSE_WORKER_BASE:gsub("/+$", "")
    local url = base .. "/v1/auth"
    local body = HttpServiceLicense:JSONEncode({ key = key, hwid = hwid })
    local execRequest = request or http_request or (typeof(http) == "table" and http.request) or (fluxus and fluxus.request)
    if typeof(execRequest) ~= "function" then
        return false, "no_request", nil
    end
    local okR, resp = pcall(execRequest, {
        Url = url,
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = body,
    })
    if not okR or type(resp) ~= "table" or type(resp.Body) ~= "string" then
        return false, "http_error", nil
    end
    local ok2, data = pcall(function()
        return HttpServiceLicense:JSONDecode(resp.Body)
    end)
    if not ok2 or type(data) ~= "table" then
        return false, "bad_response", nil
    end
    if data.ok == true then
        return true, nil, data
    end
    return false, tostring(data.error or "denied"), data
end

if type(Starlight.CreateLicenseGate) ~= "function" then
    error(LPH_ENCSTR("[DH Customs] Your Starlight build needs CreateLicenseGate (update ui_library)."))
end

local hwidLicense = getLicenseHwid()
if not hwidLicense then
    error(LPH_ENCSTR("[DH Customs] License check requires executor gethwid()."))
end
local execRequestCheck = request or http_request or (typeof(http) == "table" and http.request) or (fluxus and fluxus.request)
if typeof(execRequestCheck) ~= "function" then
    error(LPH_ENCSTR("[DH Customs] License requires executor HTTP (request or http_request)."))
end

local savedKey = readSavedLicenseKey()
if savedKey then
    local ok, err, data = authLicenseKey(savedKey, hwidLicense)
    if ok then
        saveLicenseKey(savedKey)
        runMain()
        return
    end
    if err == "invalid_key" or err == "revoked" then
        clearLicenseFiles()
    end
end

Starlight:CreateLicenseGate({
    WorkerBase = LICENSE_WORKER_BASE,
    Title = "DH Customs",
    Subtitle = "Enter your license key to continue.",
    MaxAuthFailures = LPH_ENCNUM(3),
    OnLockout = function()
        error(LPH_ENCSTR("[DH Customs] Too many invalid license attempts. Script stopped."))
    end,
    OnSuccess = function(licenseKey, _authJson)
        saveLicenseKey(licenseKey)
        runMain()
    end,
})
