if not CLIENT then return end

local cv_debug = CreateClientConVar("trmbase_debug_hud", 0, false, false)
local cv_hud_enable = CreateClientConVar("trmbase_hud_enable", 1, true, false)
local cv_hud_hide_default = CreateClientConVar("trmbase_hud_hide_default", 1, true, false)
local cv_hud_scale = CreateClientConVar("trmbase_hud_scale", 1, true, false, "Scales the TRM tactical HUD.", 0.75, 1.35)

local cv_crosshair_enable = CreateClientConVar("trmbase_crosshair_enable", 1, true, false)
local cv_crosshair_style = CreateClientConVar("trmbase_crosshair_style", 1, true, false)
local cv_crosshair_color_r = CreateClientConVar("trmbase_crosshair_color_r", 255, true, false)
local cv_crosshair_color_g = CreateClientConVar("trmbase_crosshair_color_g", 255, true, false)
local cv_crosshair_color_b = CreateClientConVar("trmbase_crosshair_color_b", 255, true, false)
local cv_crosshair_alpha = CreateClientConVar("trmbase_crosshair_alpha", 210, true, false)
local cv_crosshair_dot = CreateClientConVar("trmbase_crosshair_dot", 1, true, false)

local MAT_TRM_MARK = Material("trmbase/ui/trm_mark.png", "smooth mips")
local MAT_AMMO = Material("trmbase/ui/symbols/ammo.png", "smooth mips")
local HUD = HUD or {}
local HIDE_SEQUENCES = {
    reload = true,
    inspect = true,
    melee = true,
    holster = true,
    draw = true
}

local HIDE_DEFAULT_HUD = {
    CHudAmmo = true,
    CHudSecondaryAmmo = true,
    CHudBattery = true,
    CHudHealth = true,
    CHudCrosshair = true
}

local COL = {
    panel = Color(6, 13, 16, 188),
    panelDeep = Color(4, 8, 10, 220),
    line = Color(126, 236, 228, 150),
    lineDim = Color(92, 128, 130, 95),
    teal = Color(137, 245, 232, 235),
    green = Color(82, 230, 134, 235),
    amber = Color(245, 171, 58, 235),
    red = Color(235, 78, 72, 235),
    white = Color(235, 245, 244, 245),
    muted = Color(164, 191, 190, 185),
    black = Color(0, 0, 0, 210)
}

surface.CreateFont("TRM_HUD_Tiny", {
    font = "Tahoma",
    size = 11,
    weight = 800,
    antialias = true,
    extended = true
})

surface.CreateFont("TRM_HUD_Small", {
    font = "Tahoma",
    size = 14,
    weight = 800,
    antialias = true,
    extended = true
})

surface.CreateFont("TRM_HUD_Label", {
    font = "Tahoma",
    size = 18,
    weight = 900,
    antialias = true,
    extended = true
})

surface.CreateFont("TRM_HUD_Value", {
    font = "Trebuchet24",
    size = 34,
    weight = 900,
    antialias = true,
    extended = true
})

surface.CreateFont("TRM_HUD_Ammo", {
    font = "Trebuchet24",
    size = 54,
    weight = 900,
    antialias = true,
    extended = true
})

surface.CreateFont("TRM_HUD_AmmoReserve", {
    font = "Tahoma",
    size = 25,
    weight = 900,
    antialias = true,
    extended = true
})

local hudState = {
    health = 100,
    armor = 0,
    clip = 0,
    reserve = 0,
    spread = 0,
    lowAmmoPulse = 0,
    statusAlpha = 0
}

local lastTraceFrame = 0
local lastScreenPos = { x = ScrW() * 0.5, y = ScrH() * 0.5 }

local function IsTRMWeapon(wep)
    return IsValid(wep) and (wep.Base == "trm_gun_base" or wep:GetClass() == "trm_gun_base")
end

local function GetActiveTRMWeapon()
    local ply = LocalPlayer()
    if not IsValid(ply) then return nil, nil end

    local wep = ply:GetActiveWeapon()
    if not IsTRMWeapon(wep) then return ply, nil end

    return ply, wep
end

local function IsSequenceHidden(sequence)
    if not sequence or sequence == "" then return false end

    sequence = string.lower(tostring(sequence))
    for word in pairs(HIDE_SEQUENCES) do
        if string.find(sequence, word, 1, true) then
            return true
        end
    end

    return false
end

local function Approach(current, target, speed)
    return math.Approach(current or target, target, FrameTime() * speed)
end

local function LerpColor(frac, a, b)
    frac = math.Clamp(frac, 0, 1)
    return Color(
        Lerp(frac, a.r, b.r),
        Lerp(frac, a.g, b.g),
        Lerp(frac, a.b, b.b),
        Lerp(frac, a.a or 255, b.a or 255)
    )
end

local function DrawOutlinedBox(x, y, w, h, line, fill)
    draw.RoundedBox(0, x, y, w, h, fill or COL.panel)
    surface.SetDrawColor(line or COL.lineDim)
    surface.DrawOutlinedRect(x, y, w, h, 1)

    local corner = math.min(18, math.floor(math.min(w, h) * 0.18))
    surface.SetDrawColor(line or COL.line)
    surface.DrawRect(x, y, corner, 2)
    surface.DrawRect(x, y, 2, corner)
    surface.DrawRect(x + w - corner, y + h - 2, corner, 2)
    surface.DrawRect(x + w - 2, y + h - corner, 2, corner)
end

local function DrawMaterialIcon(mat, x, y, size, color)
    if not mat or mat:IsError() then return end

    surface.SetMaterial(mat)
    surface.SetDrawColor(color or COL.white)
    surface.DrawTexturedRect(x, y, size, size)
end

local function DrawHashLine(x, y, w, color)
    color = color or COL.lineDim
    surface.SetDrawColor(color)
    for i = 0, w, 12 do
        surface.DrawLine(x + i, y + 4, x + i + 8, y)
    end
end

local function DrawClippedPlate(x, y, w, h, line, fill, cut)
    cut = cut or math.floor(h * 0.22)
    surface.SetDrawColor(fill or COL.panelDeep)
    surface.DrawPoly({
        { x = x,           y = y },
        { x = x + w - cut, y = y },
        { x = x + w,       y = y + cut },
        { x = x + w,       y = y + h },
        { x = x + cut,     y = y + h },
        { x = x,           y = y + h - cut }
    })

    surface.SetDrawColor(line or COL.line)
    surface.DrawLine(x, y, x + w - cut, y)
    surface.DrawLine(x + w - cut, y, x + w, y + cut)
    surface.DrawLine(x + w, y + cut, x + w, y + h)
    surface.DrawLine(x + w, y + h, x + cut, y + h)
    surface.DrawLine(x + cut, y + h, x, y + h - cut)
    surface.DrawLine(x, y + h - cut, x, y)

    surface.SetDrawColor(Color((line or COL.line).r, (line or COL.line).g, (line or COL.line).b, 95))
    surface.DrawLine(x + 10, y + h - 13, x + w - cut - 12, y + h - 13)
end

local function DrawBar(x, y, w, h, frac, color, deltaFrac)
    frac = math.Clamp(frac or 0, 0, 1)
    deltaFrac = deltaFrac or 0

    draw.RoundedBox(0, x, y, w, h, Color(2, 8, 9, 190))
    surface.SetDrawColor(Color(28, 54, 54, 210))
    surface.DrawRect(x, y, w, h)

    surface.SetDrawColor(color or COL.teal)
    surface.DrawRect(x, y, math.floor(w * frac), h)

    if math.abs(deltaFrac) > 0.01 then
        local dx = math.floor(w * frac)
        local dw = math.floor(w * math.abs(deltaFrac))
        local dc = deltaFrac > 0 and COL.green or COL.red
        surface.SetDrawColor(dc)
        if deltaFrac > 0 then
            surface.DrawRect(math.min(x + dx, x + w - dw), y, dw, h)
        else
            surface.DrawRect(math.max(x, x + dx - dw), y, dw, h)
        end
    end

    surface.SetDrawColor(COL.lineDim)
    surface.DrawOutlinedRect(x, y, w, h, 1)
end

local function HealthColor(frac)
    if frac <= 0.25 then return COL.red end
    if frac <= 0.55 then return COL.amber end
    return COL.green
end

local function AmmoColor(frac)
    if frac <= 0.18 then return COL.red end
    if frac <= 0.35 then return COL.amber end
    return COL.teal
end

local function GetClipData(ply, wep)
    local clip = wep:Clip1()
    local maxClip = wep.GetMaxClip1 and wep:GetMaxClip1() or -1

    if maxClip <= 0 and wep.Primary and tonumber(wep.Primary.ClipSize) then
        maxClip = tonumber(wep.Primary.ClipSize)
    end

    local ammoType = wep:GetPrimaryAmmoType()
    local reserve = ammoType and ammoType >= 0 and ply:GetAmmoCount(ammoType) or -1

    return math.max(clip or 0, 0), math.max(maxClip or 0, 0), reserve or -1
end

local function GetFireModeText(wep)
    if wep.GetFiremodeName then
        local ok, text = pcall(wep.GetFiremodeName, wep)
        if ok and text and text ~= "" then return string.upper(tostring(text)) end
    end

    if wep.GetFireModeName then
        local ok, text = pcall(wep.GetFireModeName, wep)
        if ok and text and text ~= "" then return string.upper(tostring(text)) end
    end

    if wep.GetFireMode then
        local ok, mode = pcall(wep.GetFireMode, wep)
        if ok and mode then return string.upper(tostring(mode)) end
    end

    if wep.Primary and wep.Primary.Automatic then return "AUTO" end
    return "SEMI"
end

local function GetWeaponName(wep)
    local name = wep.PrintName or wep:GetClass() or "TRM WEAPON"
    return string.upper(tostring(name))
end

local function DrawWeaponHUD(ply, wep, scale)
    local sw, sh = ScrW(), ScrH()
    local pad = math.floor(28 * scale)
    local panelW = math.floor(430 * scale)
    local panelH = math.floor(126 * scale)
    local x = sw - panelW - pad
    local y = sh - panelH - math.floor(34 * scale)

    local clip, maxClip, reserve = GetClipData(ply, wep)
    local clipFrac = maxClip > 0 and clip / maxClip or 1
    local col = AmmoColor(clipFrac)

    hudState.clip = Approach(hudState.clip, clip, 90)
    hudState.reserve = Approach(hudState.reserve, math.max(reserve, 0), 120)
    hudState.lowAmmoPulse = Lerp(FrameTime() * 7, hudState.lowAmmoPulse, clipFrac <= 0.18 and 1 or 0)

    local pulse = math.abs(math.sin(CurTime() * 7)) * hudState.lowAmmoPulse
    local border = LerpColor(pulse, COL.line, COL.red)

    DrawClippedPlate(x, y, panelW, panelH, border, Color(5, 10, 11, 205), math.floor(18 * scale))
    DrawHashLine(x + 14, y + 10, panelW - 34, Color(col.r, col.g, col.b, 62))

    local iconSize = math.floor(54 * scale)
    DrawMaterialIcon(MAT_AMMO, x + panelW - iconSize - math.floor(26 * scale), y + math.floor(25 * scale), iconSize,
        Color(230, 236, 232, 85))

    draw.SimpleText("+1", "TRM_HUD_Label", x + math.floor(25 * scale), y + math.floor(11 * scale), col,
        TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

    local ammoText = tostring(math.floor(hudState.clip + 0.5))
    draw.SimpleText(ammoText, "TRM_HUD_Ammo", x + math.floor(74 * scale), y + math.floor(20 * scale), col,
        TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText("/", "TRM_HUD_AmmoReserve", x + math.floor(168 * scale), y + math.floor(45 * scale), COL.muted,
        TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText(reserve >= 0 and tostring(math.floor(hudState.reserve + 0.5)) or "--", "TRM_HUD_AmmoReserve",
        x + math.floor(198 * scale), y + math.floor(45 * scale), COL.white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)

    DrawBar(x + math.floor(28 * scale), y + math.floor(75 * scale), math.floor(150 * scale), math.floor(6 * scale),
        clipFrac, col)

    local mode = GetFireModeText(wep)
    local status = clip <= 0 and "DRY" or ((wep.GetReloading and wep:GetReloading()) and "RELOADING" or "READY")
    draw.SimpleText(GetWeaponName(wep), "TRM_HUD_Label", x + math.floor(26 * scale), y + math.floor(84 * scale),
        COL.white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText(mode, "TRM_HUD_Small", x + math.floor(27 * scale), y + panelH - math.floor(24 * scale), COL.amber,
        TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText(status, "TRM_HUD_Tiny", x + panelW - math.floor(24 * scale), y + panelH - math.floor(21 * scale),
        status == "DRY" and COL.red or COL.muted, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
end

local function DrawPlayerHUD(ply, wep, scale)
    local sw, sh = ScrW(), ScrH()
    local pad = math.floor(28 * scale)
    local panelW = math.floor(400 * scale)
    local panelH = math.floor(88 * scale)
    local x = pad
    local y = sh - panelH - math.floor(34 * scale)

    local health = math.Clamp(ply:Health(), 0, 100)
    local armor = math.Clamp(ply:Armor(), 0, 100)
    hudState.health = Approach(hudState.health, health, 85)
    hudState.armor = Approach(hudState.armor, armor, 80)

    local hFrac = math.Clamp(hudState.health / 100, 0, 1)
    local aFrac = math.Clamp(hudState.armor / 100, 0, 1)
    local hCol = HealthColor(hFrac)

    DrawClippedPlate(x, y, panelW, panelH, hCol, Color(5, 10, 11, 205), math.floor(18 * scale))
    DrawHashLine(x + 14, y + 10, panelW - 34, Color(hCol.r, hCol.g, hCol.b, 68))

    local icon = math.floor(48 * scale)
    surface.SetDrawColor(Color(hCol.r, hCol.g, hCol.b, 35))
    surface.DrawRect(x + math.floor(14 * scale), y + math.floor(16 * scale), icon, icon)
    surface.SetDrawColor(hCol)
    surface.DrawOutlinedRect(x + math.floor(14 * scale), y + math.floor(16 * scale), icon, icon, 1)
    surface.DrawRect(x + math.floor(29 * scale), y + math.floor(38 * scale), math.floor(18 * scale),
        math.floor(5 * scale))
    surface.DrawRect(x + math.floor(35 * scale), y + math.floor(31 * scale), math.floor(5 * scale),
        math.floor(19 * scale))

    draw.SimpleText(tostring(math.floor(hudState.health + 0.5)), "TRM_HUD_Ammo", x + math.floor(76 * scale),
        y + math.floor(8 * scale), hCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText("/ 100", "TRM_HUD_Label", x + math.floor(168 * scale), y + math.floor(35 * scale), COL.muted,
        TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText("HEALTH", "TRM_HUD_Small", x + panelW - math.floor(27 * scale), y + math.floor(31 * scale),
        hCol, TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)

    DrawBar(x + math.floor(76 * scale), y + panelH - math.floor(22 * scale), panelW - math.floor(105 * scale),
        math.floor(8 * scale), hFrac, hCol)

    local sprint = wep.GetSprintDelta and wep:GetSprintDelta() or 0
    local aim = wep.GetAimDelta and wep:GetAimDelta() or 0
    local state = "STABLE"
    local stateCol = COL.green
    if sprint > 0.55 then
        state = "SPRINT"
        stateCol = COL.amber
    elseif aim > 0.55 then
        state = "ADS"
        stateCol = COL.teal
    end

    draw.SimpleText(state, "TRM_HUD_Tiny", x + panelW - math.floor(27 * scale), y + math.floor(14 * scale), stateCol,
        TEXT_ALIGN_RIGHT, TEXT_ALIGN_TOP)
    if armor > 0 then
        DrawBar(x + math.floor(76 * scale), y + panelH - math.floor(9 * scale), panelW - math.floor(105 * scale),
            math.floor(4 * scale), aFrac, COL.teal)
    end
end

local function DrawCenterStatus(ply, wep, scale)
    local sw, sh = ScrW(), ScrH()
    local w = math.floor(245 * scale)
    local h = math.floor(28 * scale)
    local x = math.floor((sw - w) * 0.5)
    local y = sh - math.floor(50 * scale)

    local spread = wep.GetCurrentSpread and (wep:GetCurrentSpread() or 0) or 0
    hudState.spread = Lerp(FrameTime() * 10, hudState.spread, math.Clamp(spread * 60, 0, 1))

    draw.RoundedBox(0, x, y, w, h, Color(0, 0, 0, 108))
    surface.SetDrawColor(COL.lineDim)
    surface.DrawOutlinedRect(x, y, w, h, 1)
    draw.SimpleText("STABILITY", "TRM_HUD_Tiny", x + 12, y + 8, COL.muted, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    DrawBar(x + 86, y + 11, w - 106, 5, 1 - hudState.spread, COL.teal)
end

local function DrawTacticalHUD(ply, wep)
    DrawScopeStats(ply, wep)
    DrawFiremodeHint(ply, wep)
    if cv_hud_enable:GetBool() == false then return end

    local scale = math.Clamp(cv_hud_scale:GetFloat(), 0.75, 1.35)
    DrawPlayerHUD(ply, wep, scale)
    DrawWeaponHUD(ply, wep, scale)
end

local function GetCrosshairScreenPos(ply, wep)
    local aimPos = ply:GetShootPos()
    local aimAng = ply:GetAimVector():Angle()
    local visualRecoil = (wep.GetClientVisualRecoil and wep:GetClientVisualRecoil()) or wep.m_VRecoil or Angle(0, 0, 0)
    local recoil = ply:GetViewPunchAngles()

    aimAng.pitch = aimAng.pitch + visualRecoil.pitch + recoil.pitch
    aimAng.yaw = aimAng.yaw + visualRecoil.yaw + recoil.yaw

    local frame = FrameNumber()
    if frame ~= lastTraceFrame and frame % 3 == 0 then
        lastTraceFrame = frame
        local tr = util.TraceLine({
            start = aimPos,
            endpos = aimPos + aimAng:Forward() * 12000,
            filter = ply,
            mask = MASK_SHOT
        })
        lastScreenPos = tr.HitPos:ToScreen()
    end

    return lastScreenPos or { x = ScrW() * 0.5, y = ScrH() * 0.5 }
end
local meterToHu = 52.5

function DebugHUD(ply, wep)
    if cv_debug:GetInt() == 0 then return end

    local vm = ply:GetViewModel(0)
    local cycle = IsValid(vm) and math.Round(vm:GetCycle(), 2) or 0
    local sequence = wep.m_CurrentSequence or (wep.GetPlayingSequence and wep:GetPlayingSequence()) or "None"
    local aimDelta = wep.GetAimDelta and math.Round(wep:GetAimDelta(), 2) or 0
    local canFire = wep.CanPrimaryAttack and wep:CanPrimaryAttack() and "true" or "false"

    local tr = ply:GetEyeTraceNoCursor().HitPos
    local distance = ply:GetPos():Distance(tr)  / meterToHu
    draw.SimpleText("Task: " .. tostring(wep.GetCurrentTask and wep:GetCurrentTask() or "None"), "Default", ScrW() / 2,
        ScrH() * 0.68, COL.white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.SimpleText("Dis: " .. distance , "Default",
        ScrW() * 0.75, ScrH() * 0.71, COL.white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    draw.SimpleText("Cycle: " .. tostring(cycle), "Default", ScrW() / 2, ScrH() * 0.74, COL.white, TEXT_ALIGN_CENTER,
        TEXT_ALIGN_CENTER)
end

-- 在文件开头添加变量
local firemodeDisplayAlpha = 0
local lastFiremode = ""

-- 修改 DrawFiremodeHint 函数
function DrawFiremodeHint(ply, wep)
    local current = wep:GetFiremodeName()

    -- 检测开火模式变化
    if current ~= lastFiremode then
        lastFiremode = current
        firemodeDisplayAlpha = 255 -- 触发显示
    end

      -- 淡出效果
    if firemodeDisplayAlpha > 0 then
        firemodeDisplayAlpha = firemodeDisplayAlpha - (RealFrameTime() * 200) -- 1秒淡出
        if firemodeDisplayAlpha < 0 then firemodeDisplayAlpha = 0 end
        local x, y = ScrW() * 0.5, ScrH() * 0.6
        local color = Color(COL.white.r, COL.white.g, COL.white.b, firemodeDisplayAlpha)
        draw.SimpleText(lastFiremode, "TRM_HUD_AmmoReserve", x, y, color, TEXT_ALIGN_CENTER,
            TEXT_ALIGN_TOP)
    end
end

local scopealpha = 0
local scopezoom = 0
local scopeZero = 100
local needzero = GetConVar("trmbase_sv_physical_bullet"):GetBool()

function DrawScopeStats(ply, wep)
    local Current = math.Round(wep:GetScopeZoom(),1)
    local zero = wep.ZeroDistance
    if Current ~= scopezoom or scopeZero != zero then
        scopezoom = Current
        scopealpha = 255 
        scopeZero = zero
    end

    local text = "Zoom : "..scopezoom.." x " .. scopeZero .. "M"

     -- 淡出效果
    if scopealpha > 0 then
        scopealpha = scopealpha - (RealFrameTime() * 200) -- 1秒淡出
        if scopealpha < 0 then scopealpha = 0 end
        local x, y = ScrW() * 0.5, ScrH() * 0.65
        local color = Color(COL.white.r, COL.white.g, COL.white.b, scopealpha)
        draw.SimpleTextOutlined(text, "TRM_HUD_AmmoReserve", x, y, color, TEXT_ALIGN_CENTER,
            TEXT_ALIGN_CENTER, 2, Color(0, 0, 0, scopealpha))
    end
end 

function DrawCustomCrosshair(ply, wep)
    if cv_crosshair_enable:GetInt() == 0 then return end

    local alpha = cv_crosshair_alpha:GetInt()
    local sequence = wep.m_CurrentSequence or (wep.GetPlayingSequence and wep:GetPlayingSequence()) or ""

    if not ply:ShouldDrawLocalPlayer() and wep.DrawCrossHairIS ~= true and wep.GetAimDelta and wep:GetAimDelta() > 0.5 and not wep:GetTacSight() then
        alpha = 0
    end

    if (wep.GetSprintDelta and wep:GetSprintDelta() > 0.5 and wep.CanSprint and wep:CanSprint()) or IsSequenceHidden(sequence) then
        alpha = 0
    end

    if alpha <= 0 then return end

    local pos = GetCrosshairScreenPos(ply, wep)
    local x = math.Clamp(pos.x, 0, ScrW())
    local y = math.Clamp(pos.y, 0, ScrH())

    local spread = (wep.GetCurrentSpread and (wep:GetCurrentSpread() or 0) or 0) * 900
    local spreadH = wep.GetSpreadHorizonal and (wep:GetSpreadHorizonal() or 0.5) or 0.5
    local spreadV = wep.GetSpreadVertical and (wep:GetSpreadVertical() or 0.5) or 0.5
    local gapX = math.max(math.tan(spreadH) * spread, 5)
    local gapY = math.max(math.tan(spreadV) * spread, 5)

    local r = math.Clamp(cv_crosshair_color_r:GetInt(), 0, 255)
    local g = math.Clamp(cv_crosshair_color_g:GetInt(), 0, 255)
    local b = math.Clamp(cv_crosshair_color_b:GetInt(), 0, 255)
    local style = cv_crosshair_style:GetInt()
    local base = Color(r, g, b, alpha)
    local shadow = Color(0, 0, 0, math.min(alpha, 180))
    local len = 15
    local thick = 2

    surface.SetDrawColor(shadow)
    surface.DrawRect(x - gapX - len - 1, y - thick, len + 2, thick + 2)
    surface.DrawRect(x + gapX - 1, y - thick, len + 2, thick + 2)
    surface.DrawRect(x - thick, y - gapY - len - 1, thick + 2, len + 2)
    surface.DrawRect(x - thick, y + gapY - 1, thick + 2, len + 2)

    surface.SetDrawColor(base)

    if style == 1 then
        surface.DrawRect(x - gapX - len, y - thick * 0.5, len, thick)
        surface.DrawRect(x + gapX, y - thick * 0.5, len, thick)
        surface.DrawRect(x - thick * 0.5, y - gapY - len, thick, len)
        surface.DrawRect(x - thick * 0.5, y + gapY, thick, len)
    elseif style == 2 then
        surface.DrawCircle(x, y, math.Clamp((gapX + gapY) * 0.5 + 8, 8, 80), r, g, b, alpha * 0.65)
        surface.DrawRect(x - 3, y - 3, 6, 6)
    else
        local size = 11
        local gap = 4
        surface.DrawRect(x - 1, y - gap - size, 2, size)
        surface.DrawRect(x - 1, y + gap, 2, size)
        surface.DrawRect(x - gap - size, y - 1, size, 2)
        surface.DrawRect(x + gap, y - 1, size, 2)
        surface.DrawOutlinedRect(x - 4, y - 4, 8, 8, 1)
    end

    if cv_crosshair_dot:GetInt() == 1 then
        surface.SetDrawColor(0, 0, 0, math.min(alpha, 210))
        surface.DrawRect(x - 2, y - 2, 4, 4)
        surface.SetDrawColor(base)
        surface.DrawRect(x - 1, y - 1, 2, 2)
    end
end

function DrawDebugHUD(ply, wep)
end

hook.Add("HUDShouldDraw", "TRMBase_HideDefaultHUD", function(name)
    if cv_hud_enable:GetBool() == false or cv_hud_hide_default:GetBool() == false then return end
    if not HIDE_DEFAULT_HUD[name] then return end

    local _, wep = GetActiveTRMWeapon()
    if not IsTRMWeapon(wep) then return end

    return false
end)

hook.Add("HUDPaint", "TRMBase_HUD", function()
    local ply, wep = GetActiveTRMWeapon()
    if not IsTRMWeapon(wep) then return end

    DrawTacticalHUD(ply, wep)
    DrawCustomCrosshair(ply, wep)
    DebugHUD(ply, wep)
    DrawDebugHUD(ply, wep)
end)

concommand.Add("trmbase_wep_updateIcon", function(ply)
    local wep = ply:GetActiveWeapon()
    if IsTRMWeapon(wep) and wep.UpdateSelectIcon then
        wep:UpdateSelectIcon()
    end
end)
