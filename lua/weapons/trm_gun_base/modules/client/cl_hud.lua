if not CLIENT then return end
timer.Simple(1, function()
    hook.Add("HUDPaint", "TRMBase_HUD", function()
        local ply = LocalPlayer()
        if IsValid(ply) and ply:Alive() then
            local weapon = ply:GetActiveWeapon()
            if ! util.IsTRMBase(weapon) then return end
            if weapon.TRMHUD then
                weapon:TRMHUD(ply)
            end
        end
    end)
end)


local cv_debug = CreateClientConVar("trmbase_debug_hud", 1, true, false)
local cv_crosshair_enable = CreateClientConVar("trmbase_crosshair_enable", 1, true, false)
local cv_crosshair_style = CreateClientConVar("trmbase_crosshair_style", 1, true, false)
local cv_crosshair_color_r = CreateClientConVar("trmbase_crosshair_color_r", 255, true, false)
local cv_crosshair_color_g = CreateClientConVar("trmbase_crosshair_color_g", 255, true, false)
local cv_crosshair_color_b = CreateClientConVar("trmbase_crosshair_color_b", 255, true, false)
local cv_crosshair_alpha = CreateClientConVar("trmbase_crosshair_alpha", 210, true, false)
local cv_crosshair_dot = CreateClientConVar("trmbase_crosshair_dot", 1, true, false)

local MAT_TRM_MARK = Material("trmbase/ui/trm_mark.png", "smooth mips")
local MAT_AMMO = Material("trmbase/ui/symbols/ammo.png", "smooth mips")

local cvar_key_underbarrel = GetConVar("trmbase_cl_keybind_ub")
local cvar_key_bash = GetConVar("trmbase_cl_keybind_melee")
local cv_inspect = GetConVar("trmbase_cl_keybind_inspect")
local fov = GetConVar("fov_desired")
local color_shadow = Color(0, 0, 0, 100)

local Phrase = language.GetPhrase
local w, h = ScrW(), ScrH()
hook.Add("OnScreenSizeChanged", "TRMBase_HUD", function(oldWidth, oldHeight, newWidth, newHeight)
    w, h = ScrW(), ScrH()
end)
function SWEP:TRMHUD(ply)
    self:DrawCustomCrosshair(w * 0.5, h * 0.5, w, h)
    self:DrawHUDHint(w * 0.5, h * 0.6)

    if cv_debug:GetBool() then
        self:DrawDebugHUD(w * 0.5, h * 0.6)
    end
end

local function DrawCenterRoundBox(x, y, w, h)
    surface.DrawRect(x - 0.5 * w, y - 0.5 * h, w, h)
end

function SWEP:GetCrossHairColor()
    return Color(cv_crosshair_color_r:GetInt(), cv_crosshair_color_g:GetInt(),
        cv_crosshair_color_b:GetInt(),
        cv_crosshair_alpha:GetInt())
end

function SWEP:DrawCustomCrosshair(x, y, w, h)
    if ! self:ShouldDrawCrossHair() then return end
    local gap = self:GetCurrentSpread()
    local recoil = self:GetClientVisualRecoil()


    local X, Y = x, y
    surface.SetDrawColor(self:GetCrossHairColor())
    draw.NoTexture()

    local width, height = 20, 3

    DrawCenterRoundBox(X + (width * 0.5 + gap * h), Y, width, height)
    DrawCenterRoundBox(X - (width * 0.5 + gap * h), Y, width, height)

    if self:GetUnderbarrel() then
        DrawCenterRoundBox(X + (width * 0.5), Y + 50, width * 0.5, height)
        DrawCenterRoundBox(X - (width * 0.5), Y + 50, width * 0.5, height)

        DrawCenterRoundBox(X + (width * 0.5), Y + 100, width * 0.25, height)
        DrawCenterRoundBox(X - (width * 0.5), Y + 100, width * 0.25, height)
    else
        DrawCenterRoundBox(X, Y + (width * 0.5 + gap * h), height, width)
    end

    if self.Primary.Automatic then
        DrawCenterRoundBox(X, Y - (width * 0.5 + gap * h), height, width)
    end
    if cv_crosshair_dot:GetBool() then
        DrawCenterRoundBox(X, Y, height, height)
    end
    return false
end

function SWEP:ShouldDrawCrossHair()
    if ! cv_crosshair_enable:GetBool() then
        return false
    end

    if self:IsInspecting() then
        return false
    end

    local seqClass = self:GetPlayingSequence()



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
    self:DrawFiremodeHint(x, y)
    self:DrawZoomHint(x, y + 50)
    self:HUDControlHint(x - w * 0.3, y + h * 0.32)
end

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

local function DrawButton(inputtext, x, y, size, small)
    local text = string.NiceName(tostring(inputtext))
    draw.RoundedBox(5, x, y, size, size, color_white)
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

        if self:GetSight() and self:GetSight().HybridSight and not self:HasFlag("Tacsight") then
            DrawSingleHint("Scroll", Phrase("TRMBase_Hint_Hybrid"), x, hintY, size, false, true)
            hintY = hintY - size - Ygap
        end
        if self:GetSight() and not self:HasFlag("Tacsight") and self:GetSight().MaxZoom and self:GetSight().MinZoom and self:GetSight().MaxZoom != self:GetSight().MinZoom then
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

    oy         = oy + 40
    local name = math.Round(self:GetVisualRecoilBackward(), 2)
    draw.SimpleText(name, "TRM_HUD_Hint", x, oy, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end
