if SERVER then return end


local offsetX = CreateClientConVar("trmbase_vm_offsetX", 0, true, true, "ViewModel X Offset", -10, 10)
local offsetY = CreateClientConVar("trmbase_vm_offsetY", 0, true, true, "ViewModel Y Offset", -10, 10)
local offsetZ = CreateClientConVar("trmbase_vm_offsetZ", 0, true, true, "ViewModel Z Offset", -10, 10)
local rft = RealFrameTime()
function SWEP:CustomBob()
    if not CLIENT then
        return
    end

    local owner = self:GetOwner()
    if not IsValid(owner) then
        return Vector(0, 0, 0), Angle(0, 0, 0)
    end

    local speed = owner:GetVelocity():Length2D()
    if not self.Bob_t then self.Bob_t = 0 end

    -- 移动时累积，停止时衰减
    if speed > 10 and owner:OnGround() then
        self.Bob_t = (self.Bob_t or 0) + RealFrameTime() * math.min(speed, 200) * 0.05
        -- 不限制范围，让 sin 自然循环
    elseif speed < 10 then
        self.Bob_t = (self.Bob_t or 0) * 0.95 -- 停止时归零
    end
    local t = math.sin(self.Bob_t or 0) * (speed / 200)
    local mult = math.min(speed / 200, 1)
    -- 位置偏移
    local pos = Vector(
        math.sin(self.Bob_t) * -0.9 * mult,          -- 左右
        math.cos(self.Bob_t * 1.5) * 0.5 * mult,     -- 前后
        math.abs(math.sin(self.Bob_t)) * 0.25 * mult -- 上下
    )

    -- 角度偏移
    local ang = Angle(
        math.sin(self.Bob_t * 2) * 1.5 * mult, -- Pitch
        math.sin(self.Bob_t) * 1 * mult,       -- Yaw
        math.sin(self.Bob_t * 1.5) * 2 * mult  -- Roll
    )

    return pos, ang
end

function SWEP:Sway()
    if not (CLIENT and self:GetOwner() and self:GetOwner():IsPlayer()) then
        return Angle(0, 0, 0), Vector(0, 0, 0)
    end

    if not IsFirstTimePredicted() and SERVER then
        if not self.m_SwayAngle then
            self.m_SwayAngle = Angle(0, 0, 0)
            self.m_SwayPos = Vector(0, 0, 0)
        end
        return self.m_SwayAngle, self.m_SwayPos
    end

    local owner = self:GetOwner()
    local angles = owner:EyeAngles()
    local velo = owner:GetVelocity()

    if not self.m_LastViewModelAngle then
        self.m_LastViewModelAngle = angles
        self.m_SwayAngle = Angle(0, 0, 0)
        self.m_SwayPos = Vector(0, 0, 0)
        return Angle(0, 0, 0), Vector(0, 0, 0)
    end

    local ft = math.min(RealFrameTime(), 0.033)

    -- 视角移动摇摆
    local dx = -math.AngleDifference(angles.yaw, self.m_LastViewModelAngle.yaw)
    local dy = -math.AngleDifference(angles.pitch, self.m_LastViewModelAngle.pitch)
    self.m_LastViewModelAngle = angles

    local maxSway = 2
    local force = 0.1
    local smooth = 12

    self.m_SwayAngle.yaw = math.Clamp(self.m_SwayAngle.yaw - dx * force, -maxSway, maxSway)
    self.m_SwayAngle.pitch = math.Clamp(self.m_SwayAngle.pitch - dy * force, -maxSway, maxSway)

    self.m_SwayAngle.yaw = Lerp(ft * smooth, self.m_SwayAngle.yaw, 0)
    self.m_SwayAngle.pitch = Lerp(ft * smooth, self.m_SwayAngle.pitch, 0)

    -- ===== 侧向移动滚动 =====
    local sideSpeed = velo:Dot(owner:GetRight())
    local targetRoll = math.Clamp(sideSpeed * 0.05, -15, 15)
    self.m_SwayAngle.roll = Lerp(ft * 10, self.m_SwayAngle.roll, targetRoll)
    -- ========================

    -- 位置派生
    local posSway = Vector(0, 0, 0)
    posSway.x = self.m_SwayAngle.yaw * -1
    posSway.y = math.abs(self.m_SwayAngle.yaw) * -0.5
    posSway.z = -self.m_SwayAngle.pitch * 0.5

    self.m_SwayPos = posSway

    return self.m_SwayAngle, posSway
end

function SWEP:GetClientAimDelta()
    if not CLIENT then
        return self:GetAimDelta()
    end

    local target = self:GetAimDelta() or 0
    local smoothSpeed = 50 -- 平滑速度，越大越快

    self.m_SmoothAimDelta = self.m_SmoothAimDelta or 0
    self.m_SmoothAimDelta = Lerp(RealFrameTime() * smoothSpeed, self.m_SmoothAimDelta, target)

    -- 接近时直接归位避免残留
    -- if math.abs(self.m_SmoothAimDelta - target) < 0.01 then
    --     self.m_SmoothAimDelta = target
    -- end

    return self.m_SmoothAimDelta
end

function SWEP:GetClientVisualRecoil()
    if SERVER then return end
    local source = self:GetVisualRecoil()
    if not self.m_Client_VisualRecoil then
        self.m_Client_VisualRecoil = source
    end
    self.m_Client_VisualRecoil = LerpAngle(RealFrameTime() * 50, self.m_Client_VisualRecoil, source)

    return self.m_Client_VisualRecoil
end

function SWEP:GetDucking()
    local owner = self:GetOwner()
    self.m_DuckDelta = self.m_DuckDelta or 0
    if IsValid(owner) then
        local target = (trm_weapon_base_util.IsDucking(owner) and owner:OnGround()) and 1 or 0
        self.m_DuckDelta = Lerp(RealFrameTime() * 2, self.m_DuckDelta, target)
    else
        self.m_DuckDelta = 0
    end
    return self.m_DuckDelta
end

function SWEP:TranslateFOV(fov)
    local aimDelta = self:GetAimDelta() or 0
    local normalFOV = GetConVar("fov_desired"):GetInt()
    local aimFOV = normalFOV / self.Aim.Scale -- 建议 55-65 之间
    -- if self:IsReloading() then aimFOV = normalFOV  end
    -- 使用平滑曲线，让过渡更自然
    local easedDelta = math.pow(aimDelta, 1)
    local FOV = Lerp(easedDelta, normalFOV, aimFOV)
    return FOV
end

local cvar_camera = CreateClientConVar("trmbase_camera_animation_scale", 1.0)

function SWEP:CalcView(ply, pos, angles, fov)
    local vm = self:GetViewModel(0)
    if not IsValid(vm) then return pos, angles, fov end

    -- 不需要相机跟随的动画
    local ignoreAnims = { "Fire", "Idle", "Sprint" }
    local currentSeq = self.m_CurrentSequence or self:GetPlayingSequence() or ""

    for _, anim in ipairs(ignoreAnims) do
        if string.find(currentSeq, anim) then
            return pos, angles, fov
        end
    end

    local attachmentID = vm:LookupAttachment(self.CameraAttachment)
    if not attachmentID or attachmentID <= 0 then
        return pos, angles, fov
    end

    local attachment = vm:GetAttachment(attachmentID)
    if not attachment then return pos, angles, fov end
    if self.CameraOffset then
        angles:Add(self.CameraOffset)
    end

    local recoil = self:GetRecoil()
    if recoil then
        angles:Add(recoil)
    end

    local localAng = vm:WorldToLocalAngles(attachment.Ang)
    local mul = cvar_camera:GetFloat()
    if self.CameraReserve == true then
        localAng:Mul(-1)
    end
    localAng:Mul(mul)
    angles:Add(localAng)

    return pos, angles, fov
end

local CachePos = Vector(0, 0, 0)
local CacheAngle = Angle(0, 0, 0)

local AimOffset, AimOffsetAngle
local back = 0

local idledelta = 0

function SWEP:CalcViewModelView(vm, pos, angles, poss, angless)
    if not CLIENT then return end

    -- 冻结 VM 调试（直接读 ConVar，不依赖 m_VMFrozen 同步）
    if GetConVar("trmbase_freeze_vm"):GetInt() ~= 0 then
        if not self.m_VMFreezeAng then self.m_VMFreezeAng = angles end
        if not self.m_VMFreezePos then self.m_VMFreezePos = pos end
        return self.m_VMFreezePos, self.m_VMFreezeAng
    else
        self.m_VMFreezeAng = nil
        self.m_VMFreezePos = nil
    end


    local aimdelta = self:GetClientAimDelta()
    --Idle Offset
    -- if not self.m_IdleDelta then self.m_IdleDelta = 1 end
    idledelta = Lerp(RealFrameTime() * 10, idledelta or 0, self:IsInspecting() and 0 or 1) * (1 - aimdelta)
    CachePos = ((self.VMOffset.Idle.Pos.x + GetConVar("trmbase_vm_offsetX"):GetFloat()) * angles:Right() + (self.VMOffset.Idle.Pos.y + GetConVar("trmbase_vm_offsetY"):GetFloat()) * angles:Forward() - (self.VMOffset.Idle.Pos.z + GetConVar("trmbase_vm_offsetZ"):GetFloat()) * angles:Up()) *
        idledelta
    CacheAngle = self.VMOffset.Idle.Ang * idledelta
    pos:Add(CachePos)
    angles:Add(CacheAngle)
    --Sway
    CacheAngle, CachePos = self:Sway()
    local Pos            = -Vector(angles:Right() * CachePos.x + angles:Forward() * CachePos.y + angles:Up() * CachePos
            .z) *
        Lerp(aimdelta, 1, 0.2)
    pos:Add(Pos)
    angles:Add(CacheAngle * Lerp(aimdelta, 1, 0.5))
    --Bob
    local BobPos, BobAngle = self:CustomBob()
    local ApplyBobPos = Vector(angles:Right() * BobPos.x + angles:Forward() * BobPos.y + angles:Up() * BobPos.z) *
        (1 - aimdelta)
    BobAngle:Mul(1 - aimdelta * 0.8)
    pos:Add(ApplyBobPos)
    angles:Add(BobAngle)
    --Duck Pose
    local DuckDelta = (1 - aimdelta) * self:GetDucking()
    local DuckPos = (angles:Right() * self.VMOffset.Crouch.Pos.x +
        angles:Forward() * self.VMOffset.Crouch.Pos.y +
        angles:Up() * self.VMOffset.Crouch.Pos.z) * DuckDelta
    local DuckAngle = self.VMOffset.Crouch.Ang * DuckDelta
    pos:Add(DuckPos)
    angles:Add(DuckAngle)
    --Sprint Pose

    local sprintDelta = self:GetSprintDelta() * (self:CanSprint() and 1 or 0)
    local sprintPos = (angles:Right() * self.VMOffset.Sprint.Pos.x +
        angles:Forward() * self.VMOffset.Sprint.Pos.y +
        angles:Up() * self.VMOffset.Sprint.Pos.z) * sprintDelta
    local sprintAngle = self.VMOffset.Sprint.Ang * sprintDelta

    pos:Add(sprintPos)
    angles:Add(sprintAngle)
    -- Aim Pose（基础偏移用 VM 朝向）
    AimOffset =  Vector(self.Sight.Pos) 
    AimOffsetAngle =  Angle(self.Sight.Ang) 

 
    



    local applyAimPos = (angles:Right() * AimOffset.x + angles:Forward() * AimOffset.y + angles:Up() * AimOffset.z) *
        aimdelta
    pos:Add(applyAimPos)
    angles:Add(AimOffsetAngle * aimdelta)

    -- 配件瞄具偏移（用骨骼自身 axis 变换，与 GenerateAimOffset 的 WorldToLocal 坐标空间一致）
    if self:GetSight() and not self:GetTacSight() then
        local sight = self:GetSight()
        local boneAng = sight.AimBoneAng or angles
        local sightPos = (angles:Right() * sight.AimPos.x + angles:Forward() * sight.AimPos.y + angles:Up() * sight.AimPos.z) *
            aimdelta
        pos:Add(sightPos)
        local applyAng = sight.AimAng * aimdelta
        angles:Add(applyAng)
    end



    --Visual Recoil（只有玩家持有时才应用）
    if IsValid(self:GetOwner()) and self:GetOwner():IsPlayer() and not ( self:GetSight() and self:GetSight().zoom and aimdelta > 0.2 ) then
        -- 后坐力后退（position）
        back = Lerp(RealFrameTime() * 20, back or 0,
            self:GetVisualRecoilBackward() or back)
        pos:Add(Vector(-back * angles:Forward()))
        -- 后坐力角度偏移（pitch/yaw 让 viewmodel 上跳）
        local visAng = self:GetClientVisualRecoil()


        angles:RotateAroundAxis(angles:Right(), -visAng.p * 0.66)
        angles:RotateAroundAxis(angles:Up(), visAng.y * 0.66)

        ------ViewModel Recoil
        local fireInterval = (60 / self.Primary.RPM)* 1
        local timeToNextFire = self:GetNextRecoil() - CurTime()
        local t = math.Clamp(timeToNextFire / fireInterval, 0, 1)
        local Recoildelta = (t > 0.5 and 1 - t or t) * 2 -- 开火时 = 1，然后衰减到 0

        local recoiloffsetpos = self.ViewmodelRecoil.Pos
        local recoiloffsetang = self.ViewmodelRecoil.Ang
       pos:Add(Vector(recoiloffsetpos[1] * angles:Right() + recoiloffsetpos[2] * angles:Forward() +
            recoiloffsetpos[3] * angles:Up()) * Recoildelta)

       angles:Add(recoiloffsetang * Recoildelta)
    end


    return pos, angles
end
