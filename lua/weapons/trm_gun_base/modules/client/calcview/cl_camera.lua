if ! CLIENT then return end
local cvar_camera = CreateClientConVar("trmbase_camera_animation_scale", 1.0)

local CamAngDelta = Angle()
local ZERO_ANGLE  = Angle(0, 0, 0)


local localAng = Angle()



function SWEP:CalcView(ply, pos, angles, fov)
    local vm = self:GetViewModel(0)
    if not IsValid(vm) then return pos, angles, fov end
    localAng:Zero()
    -- 不需要相机跟随的动画
    local ignoreAnims = { "Fire", "Idle", "Sprint" }
    local currentSeq = self:GetPlayingSequence()
    local shouldFollow = true

    for _, anim in ipairs(ignoreAnims) do
        if string.find(currentSeq, anim) then
            shouldFollow = false
            break
        end
    end


    local attachmentID = trm_utils.LookupAttachmentCached(vm, self.CameraAttachment)
    if not attachmentID or attachmentID <= 0 then
        return pos, angles, fov
    end


    if self.m_StoredAngle != nil and self:GetUnderbarrel() then
        shouldFollow = true
        localAng = self.m_StoredAngle
    else
        local attachment = vm:GetAttachment(attachmentID)

        if not attachment then return pos, angles, fov end

        localAng = vm:WorldToLocalAngles(attachment.Ang)
    end


    localAng = localAng * cvar_camera:GetFloat()
    if self.CameraReserve then
        localAng:Mul(-1)
    end

    if self.CameraOffset then
        localAng:Add(self.CameraOffset)
    end

    local targetAng = shouldFollow and localAng or ZERO_ANGLE
    if self.CameraLerp then
        CamAngDelta = LerpAngle(RealFrameTime() * 10, CamAngDelta, targetAng)
    else
        CamAngDelta = targetAng
    end
    angles:Add(CamAngDelta)

    self:CameraShakeAng(angles)

    return pos, angles, fov
end

local viewmodelFovMul = CreateClientConVar("trmbase_cl_viewmodelfov_aim", 1, true, true, "", 0, 3)


local finalFOV = 75

function SWEP:ShouldZoom()
    return not (self:HasFlag("Tacsight") or self:HasFlag("HybridOn"))
end

local viewmodelFov = 0
function SWEP:GetViewmodelFov()
    local delta = self:GetClientAimDelta()
    local global = GetConVar("fov_desired"):GetInt() / 75
    viewmodelFov = math.Clamp(
        self.ViewModelFOV * global * Lerp(delta, 1, viewmodelFovMul:GetFloat() / self.Aim.Scale), 1, 170)
    return viewmodelFov
end

local reloadFovDelta = 0

function SWEP:CoolFov()
    local aimDelta = self:GetClientAimDelta() or 0
    local normalFOV = GetConVar("fov_desired"):GetInt()
    local aimFOV = normalFOV / self.Aim.Scale -- 建议 55-65 之间
    -- 使用平滑曲线，让过渡更自然
    if self.sight and self.sight.zoom and (GetConVar("trmbase_cl_cheapscope"):GetBool() or not self:IsFirstPerson()) and self:ShouldZoom() then
        aimFOV = math.min(aimFOV, self:GetScopeZoomFov())
    end
    local reload = self:IsReloading()
    reloadFovDelta = Lerp(RealFrameTime() * 5, reloadFovDelta or 0, reload and 1 or 0)
    aimFOV = math.min(aimFOV * (1 + reloadFovDelta * 0.2), normalFOV)
    local easedDelta = aimDelta
    local FOV = Lerp(easedDelta, normalFOV, aimFOV) + self:CameraShakeFOV(finalFOV)

    finalFOV = Lerp(RealFrameTime() * 15, finalFOV, FOV)

    return finalFOV
end

function SWEP:TranslateFOV(fov)
    return self:CoolFov()
end

function SWEP:DoViewModelShake()
    self.m_ScreenShake = 1
    self.m_ShakeDirection = -self.m_ShakeDirection
    self:DoViewModelRecoil()
    hook.Run("TRM_Weapon_PostFireEffect", self, self:GetOwner())
end

local pi = 3.1415
SWEP.m_ScreenShake = 0
SWEP.m_ShakeDirection = 1
local delta = 0
function SWEP:CameraShakeAng(angles)
    local shakeScale = self.Recoil.Shake * Lerp(self:GetAimDelta(), 1, self.Recoil.AdsMultiplier or 0.25)
    angles.r = angles.r + math.sin(SysTime() * 75) * self.m_ScreenShake * 10 * shakeScale * self.m_ShakeDirection
  --  angles.p = angles.p + self.m_ScreenShake * -2 * shakeScale
end

function SWEP:CameraShakeFOV(fov)
    self.m_ScreenShake = math.max(0, self.m_ScreenShake - RealFrameTime())

    return -self.m_ScreenShake * 5 * self.Recoil.Shake
end

function SWEP:CameraShakeMotionBlur(h, v, f, r)
    local _delta = self.m_ScreenShake * self.Recoil.Shake
    f = f + 0.02 * _delta
    r = r + 0.02 * _delta
    return h, v, f, r
end

local cvar_shootingblur = CreateClientConVar("trmbase_cl_shootfx", 1, true, true, "helptext", 0, 1)

hook.Add("GetMotionBlurValues", "TRMBase_Weapon", function(h, v, f, r)
    if ! cvar_shootingblur:GetBool() then return end
    local ply = LocalPlayer()
    if ! IsValid(ply) then return end
    local wpn = ply:GetActiveWeapon()
    if ! IsValid(wpn) or ! wpn.IsTRMWeapon then return end

    return wpn:CameraShakeMotionBlur(h, v, f, r)
end)
