if not CLIENT then return end

local math = math

local cv_debug = GetConVar("developer")
local cv_crosshair_enable = CreateClientConVar("trmbase_crosshair_enable", 1, true, false)
local cv_crosshair_style = CreateClientConVar("trmbase_crosshair_style", 1, true, false)
local cv_crosshair_color_r = CreateClientConVar("trmbase_crosshair_color_r", 255, true, false)
local cv_crosshair_color_g = CreateClientConVar("trmbase_crosshair_color_g", 255, true, false)
local cv_crosshair_color_b = CreateClientConVar("trmbase_crosshair_color_b", 255, true, false)
local cv_crosshair_alpha = CreateClientConVar("trmbase_crosshair_alpha", 210, true, false)
local cv_crosshair_dot = CreateClientConVar("trmbase_crosshair_dot", 1, true, false)
local cv_crosshair_width = CreateClientConVar("trmbase_crosshair_width", 20, true, false)
local cv_crosshair_height = CreateClientConVar("trmbase_crosshair_height", 1, true, false)
local cv_crosshair_outline = CreateClientConVar("trmbase_crosshair_outline", 3, true, false)
local cv_crosshair_scale = CreateClientConVar("trmbase_crosshair_scale", 1, true, false)
local cvar_hint_enabled = CreateClientConVar("trmbase_cl_hud_hint", 1, true, false)
---------------------
local MAT_TRM_MARK = Material("trmbase/ui/trm_mark.png", "smooth mips")
local MAT_AMMO = Material("trmbase/ui/symbols/ammo.png", "smooth mips")

local cvar_key_underbarrel = GetConVar("trmbase_cl_keybind_ub")
local cvar_key_bash = GetConVar("trmbase_cl_keybind_melee")
local cv_inspect = GetConVar("trmbase_cl_keybind_inspect")
local fov = GetConVar("fov_desired")
local color_shadow = Color(0, 0, 0, 100)
local rft = RealFrameTime
local Phrase = language.GetPhrase
local rndx = include("include/rndx.lua")
local w, h = ScrW(), ScrH()
local scale = ScreenScale(0.25)
hook.Add("OnScreenSizeChanged", "TRMBase_HUD", function(oldWidth, oldHeight, newWidth, newHeight)
    w, h = ScrW(), ScrH()
    scale = ScreenScale(0.25)
end)
local SwayX = 0
local SwayY = 0
local LastX = 0
local LastY = 0

local function DrawRoundBox(cornerRadius, x, y, width, height, color)
    rndx.Rect(x, y, width, height)
        :Rad(cornerRadius)
        :Color(color)
        :Draw()
end

function SWEP:GetCrosshairSway()
    local eye = EyeAngles()
    local currentX = eye.yaw
    local currentY = eye.pitch


    local deltaX = math.AngleDifference(currentX, LastX)
    local deltaY = math.AngleDifference(currentY, LastY)
    LastX = currentX
    LastY = currentY
    SwayX = SwayX * 0.9 + deltaX * 10
    SwayY = SwayY * 0.9 + deltaY * 10

    return SwayX, -SwayY
end

function SWEP:DrawHUD()
    local ply = LocalPlayer()
    if ! ply:GetAllowWeaponsInVehicle() and ply:InVehicle() then
        return
    end
    self:DrawCustomCrosshair(w * 0.5, h * 0.5, w, h, ply)
    self:DrawHUDHint(w * 0.5, h * 0.6)

    if cv_debug:GetBool() then
        self:DrawDebugHUD(w * 0.5, h * 0.6)
    end
end

local function DrawCenterRoundBox(x, y, W, H, color)
    local outline = cv_crosshair_outline:GetInt()
    if outline > 0 then
        local shadowW, shadowH = W + outline, H + outline
        DrawRoundBox(2, x - 0.5 * shadowW, y - 0.5 * shadowH, shadowW, shadowH, color_shadow)
    end
    DrawRoundBox(2, x - 0.5 * W, y - 0.5 * H, W, H, color)
end

function SWEP:GetCrossHairColor()
    return Color(cv_crosshair_color_r:GetInt(), cv_crosshair_color_g:GetInt(),
        cv_crosshair_color_b:GetInt(),
        cv_crosshair_alpha:GetInt())
end

local TraceOutPut = {}
local CrossHairTrace = {
    output = TraceOutPut
}
local NextTrace = 0
local TraceLine = util.TraceLine



function SWEP:GetCrosshairPos(x, y, ply)
    if ply:ShouldDrawLocalPlayer() then
        local scr = ply:GetEyeTraceNoCursor().HitPos:ToScreen()
        return scr.x, scr.y
    end


    return x, y
end

function SWEP:DrawCustomCrosshair(x, y, w, h, ply)
    if ! self:ShouldDrawCrossHair() then return end
    local gap = self:GetCurrentSpread() * cv_crosshair_scale:GetFloat()

    local screenPosX, screenPosY = self:GetCrosshairPos(x, y, ply)

    local X, Y = screenPosX, screenPosY
    local color = self:GetCrossHairColor()
    local width, height = cv_crosshair_width:GetInt() * scale, cv_crosshair_height:GetInt() * scale

    if self.Primary and self.Primary.NumBullets > 1 then
        width, height = height, width
    end
    if cv_crosshair_dot:GetBool() then
        local dotSize = math.min(height, width)
        DrawCenterRoundBox(X, Y, dotSize, dotSize, color)
    end

    DrawCenterRoundBox(X + (width * 0.5 + gap * h), Y, width, height, color)
    DrawCenterRoundBox(X - (width * 0.5 + gap * h), Y, width, height, color)

    if self:GetUnderbarrel() then
        DrawCenterRoundBox(X + (width * 0.5), Y + 50, width * 0.5, height, color)
        DrawCenterRoundBox(X - (width * 0.5), Y + 50, width * 0.5, height, color)

        DrawCenterRoundBox(X + (width * 0.5), Y + 100, width * 0.25, height, color)
        DrawCenterRoundBox(X - (width * 0.5), Y + 100, width * 0.25, height, color)
    else
        DrawCenterRoundBox(X, Y + (width * 0.5 + gap * h), height, width, color)
    end

    if self.Primary.Automatic then
        DrawCenterRoundBox(X, Y - (width * 0.5 + gap * h), height, width, color)
    end
    return false
end

function SWEP:ShouldDrawCrossHair()
    if LocalPlayer():ShouldDrawLocalPlayer() then
        return true
    end

    if ! cv_crosshair_enable:GetBool() then
        return false
    end

    if self:IsInspecting() then
        return false
    end

    local seqClass = self:GetStatus()



    if string.find(seqClass, "Holster") then
        return false
    end

    if self:GetAimDelta() > 0.5 and not self.DrawCrossHairIS then
        return false
    end

    if self:GetSprintDelta() > 0.2 then
        return false
    end

    if self:IsReloading() then
        return false
    end

    return true
end

local OldFiremode = ""
local FiremodeHintDelta = 1
function SWEP:DrawFiremodeHint(x, y)
    ------------Firemode
    local firemodeName = self:GetFiremodeName()
    if firemodeName != OldFiremode then
        OldFiremode = firemodeName
        FiremodeHintDelta = 1
    end
    if FiremodeHintDelta > 0 then
        surface.SetAlphaMultiplier(FiremodeHintDelta * 3)
        FiremodeHintDelta = Lerp(RealFrameTime() * 2, FiremodeHintDelta, 0)
        draw.SimpleText(firemodeName, "TRM_HUD_Firemode", x, y, color_white, TEXT_ALIGN_CENTER, 1)
    end
    ------------------------------------------------------
end

function SWEP:DrawHUDHint(x, y)
    if ! cvar_hint_enabled:GetBool() then
        return
    end
    self:DrawFiremodeHint(x, y)
    self:DrawZoomHint(x, y + 50)
    self:HUDControlHint(x - w * 0.25, y + h * 0.32)
end

do
    local Zoom = 1
    local ZoomDelta = 1
    function SWEP:DrawZoomHint(x, y)
        local CurrentZoom = self:GetScopeZoom()
        if Zoom != CurrentZoom then
            Zoom = CurrentZoom
            ZoomDelta = 1
        end

        if ZoomDelta > 0 then
            local text = math.Round(CurrentZoom, 2) .. " X"
            surface.SetAlphaMultiplier(ZoomDelta * 5)
            draw.SimpleText(text, "TRM_HUD_Firemode", x, y, color_white, TEXT_ALIGN_CENTER, 1)
            ZoomDelta = Lerp(RealFrameTime() * 2, ZoomDelta, 0)
        end
        surface.SetAlphaMultiplier(1)
    end
end
local function DrawButton(inputtext, x, y, size, small)
    local text = string.upper(tostring(inputtext))
    DrawRoundBox(5, x, y, size, size, color_white)
    draw.SimpleText(text, small and "TRM_HUD_Small" or "TRM_HUD_Button", x + size * 0.5, y + size * 0.5, color_black,
        TEXT_ALIGN_CENTER,
        TEXT_ALIGN_CENTER)
end

local function DrawSingleHint(inputtext, Text, x, y, size, isDoubleTap, smaller)
    DrawButton(inputtext, x, y, size, smaller)
    draw.SimpleTextOutlined(Text, "TRM_HUD_Hint", x + size + 10, y + size * 0.5, color_white, TEXT_ALIGN_LEFT,
        TEXT_ALIGN_CENTER, 1, color_shadow)
    if isDoubleTap then
        local padding = 2
        surface.SetDrawColor(0, 0, 0, 255)
        surface.DrawOutlinedRect(x + padding, y + padding, size - padding * 2, size - padding * 2, 2)
    end
end
function SWEP:HUDControlHint(x, y)
    local hintY = y
    local size, Ygap = 30, 10

    if self:HasFlag("Aiming") then
        DrawSingleHint(input.LookupBinding("use"), Phrase("TRMBase_Hint_Tacsight"), x, hintY, size, true)
        hintY = hintY - size - Ygap
        local tac = self:HasFlag("Tacsight")
        if self:GetSight() and self:GetSight().HybridSight and not tac then
            DrawSingleHint("Scroll", Phrase("TRMBase_Hint_Hybrid"), x, hintY, size, false, true)
            hintY = hintY - size - Ygap
        end
        if self:GetSight() and not tac and self:GetSight().MaxZoom and self:GetSight().MinZoom and self:GetSight().MaxZoom != self:GetSight().MinZoom then
            DrawSingleHint("Scroll", Phrase("TRMBase_Hint_ScrollScope"), x, hintY, size, false, true)
            hintY = hintY - size - Ygap
        end
    end

    local underbarrel = GetConVar("trmbase_cl_keybind_ub"):GetInt()
    if underbarrel > 0 and self.underbarrel then
        DrawSingleHint(input.GetKeyName(underbarrel), Phrase("TRMBase_Hint_UBarrel"), x, hintY, size, false)
        hintY = hintY - size - Ygap
    end

    local melee = cvar_key_bash:GetInt()
    if melee > 0 and self.Melee.Enabled and self.Animations.Melee then
        DrawSingleHint(input.GetKeyName(melee), Phrase("TRMBase_Hint_Melee"), x, hintY, size, false)
        hintY = hintY - size - Ygap
    end

    local inspect = cv_inspect:GetInt()
    if inspect > 0 and self.Animations.Inspect then
        DrawSingleHint(input.GetKeyName(inspect), Phrase("TRMBase_Hint_Inspect"), x, hintY, size, false)
        hintY = hintY - size - Ygap
    end

    local firemode = self.Firemode
    if firemode then
        DrawSingleHint(input.LookupBinding("zoom"), Phrase("TRMBase_Hint_Firemode"), x, hintY, size, false)
        hintY = hintY - size - Ygap
    end

    local bipod = self:HasFlag("BipodDeployed")
    if bipod then
        DrawSingleHint("", "BipodEnabled", x, hintY, size, false)
    end
end

function SWEP:DrawDebugHUD(x, y)
    local oy = y
    draw.SimpleText("Debug", "TRM_HUD_Hint", x, oy, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    local vm = self:GetViewModel()
    if IsValid(vm) then
        oy = oy + 40
        local sequence = vm:GetSequence()
        local name = vm:GetSequenceName(sequence)
        draw.SimpleText(name, "TRM_HUD_Hint", x, oy, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    oy   = oy + 40
    name = self:GetStatus()
    draw.SimpleText(name, "TRM_HUD_Hint", x, oy, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    oy   = oy + 40
    name = "TaskName:" .. self:GetCurrentTaskName()
    draw.SimpleText(name, "TRM_HUD_Hint", x, oy, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    oy   = oy + 40
    name = "Cycle:" .. vm:GetCycle()
    draw.SimpleText(name, "TRM_HUD_Hint", x, oy, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end
