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
        aimFOV = self:GetScopeZoomFov()
    end
    local reload = self:IsReloading()
    reloadFovDelta = Lerp(RealFrameTime() * 5, reloadFovDelta or 0, reload and 1 or 0)
    aimFOV = math.min(aimFOV * (1 + reloadFovDelta * 0.2), normalFOV)
    local easedDelta = aimDelta
    local FOV = Lerp(easedDelta, normalFOV, aimFOV) +   self:CameraShakeFOV(finalFOV)

    finalFOV = Lerp(RealFrameTime() * 15, finalFOV, FOV)

    return finalFOV
end

function SWEP:TranslateFOV(fov)
    return self:CoolFov()
end

net.Receive("TRMBase_ScreenShake", function(len)
    local wpn = net.ReadEntity()
    if ! wpn.IsTRMWeapon then return end
    wpn.m_ScreenShake = 1
    wpn.m_ShakeDirection = -wpn.m_ShakeDirection 
    wpn:DoViewModelRecoil()
end)


SWEP.m_ScreenShake = 0
SWEP.m_ShakeDirection = 1
local delta = 0
function SWEP:CameraShakeAng(angles)
    delta = math.sin(SysTime() * 100) * self.m_ScreenShake
    local shakeScale = self.Recoil.Shake * self.m_ShakeDirection
    angles.r = angles.r + delta * 2 * shakeScale
    angles.p = angles.p + delta * 1 * shakeScale
    angles.y = angles.y + delta * 1 * shakeScale
end

function SWEP:CameraShakeFOV(fov)
    self.m_ScreenShake = Lerp(RealFrameTime() * 2, self.m_ScreenShake, 0)
    return -self.m_ScreenShake * 5 * self.Recoil.Shake
end