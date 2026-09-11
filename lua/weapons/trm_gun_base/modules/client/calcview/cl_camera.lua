if ! CLIENT then return end
require("trm_utils")
require("trm_math")
local cvar_camera    = CreateClientConVar("trmbase_camera_animation_scale", 1.0)

local ZERO_ANGLE     = Angle(0, 0, 0)
local camera_delta   = 0

local localAng       = Angle()

local ShouldntFollow = { "Idle", "Fire", "Sprint" }

function SWEP:ShouldCameraFollow()
    local seqId = self:GetStatus()

    for _, seqName in ipairs(ShouldntFollow) do
        if string.find(seqName, seqId) then
            return false
        end
    end


    return true
end

function SWEP:CalcView(ply, pos, angles, _)
    local fov = self:CoolFov()

    self:CameraShakeAng(angles)

    if self.m_StoredAngle and self:GetUnderbarrel() then
        localAng = self.m_StoredAngle
        angles:RotateAroundAxis(angles:Forward(), localAng.r)
        angles:RotateAroundAxis(angles:Up(), -localAng.y)
        angles:RotateAroundAxis(angles:Right(), localAng.p)
        return pos, angles, fov
    end

    if ! self.m_CameraAttachment or ! self:ShouldCameraFollow() then
        return pos, angles, fov
    end
    camera_delta = Lerp(RealFrameTime() * 10, camera_delta, self:ShouldCameraFollow() and 1 or 0)

    localAng = self.m_CameraAttachment * camera_delta
    if ! localAng then return pos, angles, fov end

    angles:RotateAroundAxis(angles:Forward(), localAng.r)
    angles:RotateAroundAxis(angles:Up(), -localAng.y)
    angles:RotateAroundAxis(angles:Right(), localAng.p)

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
    local global = GetConVar("fov_desired"):GetInt() / 80
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
    angles.r = angles.r + math.sin(SysTime() * 75) * self.m_ScreenShake * 2 * shakeScale * self.m_ShakeDirection
    --  angles.p = angles.p + self.m_ScreenShake * -2 * shakeScale
end

function SWEP:CameraShakeFOV(fov)
    self.m_ScreenShake = math.max(0, self.m_ScreenShake - RealFrameTime() * 5)

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

local worldMatrix = Matrix()
local Ang = Angle()
---@param vm Entity
function SWEP:GetCameraAttachmentRaw(vm)
    local attId = trm_utils.LookupAttachmentCached(vm, self.CameraAttachment)
    local AttData = vm:GetAttachment(attId)
    Ang:Set(vm:WorldToLocalAngles(AttData.Ang))

    if self.CameraOffset then
        trm_math.RotateAxis(Ang, self.CameraOffset)
    end
    return Ang
end

function SWEP:GetCameraAttachmentAngle(vm)
    if ! self.CameraAttachment then
        return nil
    end

    if self.RawCameraAttachment then
        return self:GetCameraAttachmentRaw(vm)
    end



    if ! self.vm_CameraAttachment_Bone then
        local attId = trm_utils.LookupAttachmentCached(vm, self.CameraAttachment)
        if ! attId or attId == -1 then
            return
        end
        local Att = vm:GetAttachment(attId)
        if ! Att then
            return
        end
        self.vm_CameraAttachment_Bone = vm:GetBoneName(Att.Bone)
    end

    local matrix = vm:GetBoneMatrix(trm_utils.LookupBoneCached(vm, self.vm_CameraAttachment_Bone))

    if (matrix != nil) then
        worldMatrix:SetTranslation(vm:GetPos())
        worldMatrix:SetAngles(vm:GetAngles())

        local CamMatrix = matrix:GetInverse() * worldMatrix


        local ang = CamMatrix:GetAngles()
        if self.CameraOffset then
            trm_math.RotateAxis(ang, self.CameraOffset)
        end

        return ang
    end
    return false
end
