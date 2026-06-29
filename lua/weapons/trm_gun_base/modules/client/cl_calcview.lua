if SERVER then return end


local offsetX = CreateClientConVar("trmbase_vm_offsetX", 0, true, true, "ViewModel X Offset", -10, 10)
local offsetY = CreateClientConVar("trmbase_vm_offsetY", 0, true, true, "ViewModel Y Offset", -10, 10)
local offsetZ = CreateClientConVar("trmbase_vm_offsetZ", 0, true, true, "ViewModel Z Offset", -10, 10)
local rft = RealFrameTime()

local bobt = 0

function SWEP:CustomBob()
    if not CLIENT then
        return
    end

    local owner = self:GetOwner()
    if not IsValid(owner) then
        return Vector(0, 0, 0), Angle(0, 0, 0)
    end

    local speed = owner:GetVelocity():Length2D()

    -- 移动时累积，停止时衰减
    if speed > 10 and owner:OnGround() then
        bobt = (bobt or 0) + RealFrameTime() * math.min(speed, 200) * 0.05
        -- 不限制范围，让 sin 自然循环
    elseif speed < 10 then
        bobt = (bobt or 0) * 0.95 -- 停止时归零
    end
    local t = math.sin(bobt or 0) * (speed / 200)
    local mult = math.min(speed / 200, 1)
    -- 位置偏移
    local pos = Vector(
        math.sin(bobt) * -0.9 * mult,          -- 左右
        math.cos(bobt * 1.5) * 0.5 * mult,     -- 前后
        math.abs(math.sin(bobt)) * 0.25 * mult -- 上下
    )

    -- 角度偏移
    local ang = Angle(
        math.sin(bobt * 2) * 1.5 * mult, -- Pitch
        math.sin(bobt) * 1 * mult,       -- Yaw
        math.sin(bobt * 1.5) * 2 * mult  -- Roll
    )

    return pos, ang
end

local lastangle = Angle(0, 0, 0)
local swayAng = Angle(0, 0, 0)

function SWEP:Sway()
    if not (CLIENT and self:GetOwner() and self:GetOwner():IsPlayer()) then
        return Angle(0, 0, 0), Vector(0, 0, 0)
    end


    local owner = self:GetOwner()
    local angles = owner:EyeAngles()
    local velo = owner:GetVelocity()


    local ft = math.min(RealFrameTime(), 0.033)

    -- 视角移动摇摆
    local dx = -math.AngleDifference(angles.yaw, lastangle.yaw)
    local dy = -math.AngleDifference(angles.pitch, lastangle.pitch)

    lastangle = angles
    local maxSway = 2
    local force = 0.1
    local smooth = 12

    swayAng.yaw = math.Clamp(swayAng.yaw - dx * force, -maxSway, maxSway)
    swayAng.pitch = math.Clamp(swayAng.pitch - dy * force, -maxSway, maxSway)
    swayAng.yaw = Lerp(ft * smooth, swayAng.yaw, 0)
    swayAng.pitch = Lerp(ft * smooth, swayAng.pitch, 0)
    -- ===== 侧向移动滚动 =====
    local sideSpeed = velo:Dot(owner:GetRight())
    local targetRoll = math.Clamp(sideSpeed * 0.05, -15, 15)
    swayAng.roll = Lerp(ft * 10, swayAng.roll, targetRoll)
    -- ========================

    -- 位置派生
    local posSway = Vector(0, 0, 0)
    posSway.x = swayAng.yaw * -1
    posSway.y = math.abs(swayAng.yaw) * -0.5
    posSway.z = -swayAng.pitch * 0.5

    return swayAng, posSway
end

local aimdelta = 0
function SWEP:GetClientAimDelta()
    if not CLIENT then
        return self:GetAimDelta()
    end

    local target = self:GetAimDelta() or 0
    local smoothSpeed = 20 -- 平滑速度，越大越快

    aimdelta = Lerp(RealFrameTime() * smoothSpeed, aimdelta, target)

    return aimdelta
end

local r = Angle(0, 0, 0)
function SWEP:GetClientVisualRecoil()
    if SERVER then return end
    local source = self:GetVisualRecoil()
    r = LerpAngle(RealFrameTime() * 25, r, source)

    return r
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

local cvar_camera = CreateClientConVar("trmbase_camera_animation_scale", 1.0)

function SWEP:CalcView(ply, pos, angles, fov)
    self:ScaleViewmodelFov()

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
local aimOffset = Vector()
local aimAngle = Angle()

local back = 0

local idledelta = 0
local const_vrec = 0.5
local Vrecoil_Mul = 0
local visAng = Angle( )

local vmanipDef = {
    pos = Vector(1.5, 0, -1.5),
    ang = Angle(0, 2, -10)
}
local vmanipPos = Vector(0, 0, 0)
local vmanipAng = Angle(0, 0, 0)
local vmanipMul = 0

local cacheAngle = {}

local function dealTacsight(angles, roll)
    -- 缓存 key
    local key = angles.pitch .. "_" .. angles.yaw .. "_" .. angles.roll .. "_" .. roll

    if cacheAngle[roll] then
        return cacheAngle[roll]
    end

    local rad = math.rad(roll)
    local cos = math.cos(rad)
    local sin = math.sin(rad)

    local newPitch = angles.pitch * cos + angles.yaw * sin
    local newYaw = -angles.pitch * sin + angles.yaw * cos

    local result = Angle(newPitch, newYaw, 0)
    cacheAngle[key] = result

    return result
end

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
    idledelta = Lerp(RealFrameTime() * 10, idledelta or 0, self:IsInspecting() and self.VMOffset.Inspect and 0 or 1) *
        (1 - aimdelta)
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
    AimOffset = Vector(self.Sight.Pos)
    AimOffsetAngle = Angle(self.Sight.Ang)
    local tac = self:GetTacSight()

    if tac then
        AimOffset:Add(self.TacSight.Pos)
        AimOffsetAngle:Add(self.TacSight.Ang)
    end

    aimOffset = LerpVector(RealFrameTime() * 10, aimOffset  , AimOffset)
    aimAngle = LerpAngle(RealFrameTime() * 10, aimAngle, AimOffsetAngle)


    local applyAimPos = (angles:Right() * aimOffset.x + angles:Forward() * aimOffset.y + angles:Up() * aimOffset.z) *
        aimdelta
    pos:Add(applyAimPos)
    angles:Add(aimAngle * aimdelta)
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
    if IsValid(self:GetOwner()) and self:GetOwner():IsPlayer()  then
        -- 后坐力后退（position）
        back = Lerp(RealFrameTime() * 20, back or 0,
            self:GetVisualRecoilBackward() or back)
        pos:Add(Vector(-back * angles:Forward()))
        -- 后坐力角度偏移（pitch/yaw 让 viewmodel 上跳）
        visAng =self:GetClientVisualRecoil()

        local rad = math.rad(self:GetTacSight() and self.TacSight.Ang.r or 0)

        visAng = dealTacsight( visAng ,rad)

        Vrecoil_Mul = const_vrec


        angles:RotateAroundAxis(angles:Right(), -visAng.p * Vrecoil_Mul)
        angles:RotateAroundAxis(angles:Up(), visAng.y * Vrecoil_Mul)
        
        if not (self:GetSight() and self:GetSight().zoom and aimdelta > 0.2) then
            ------ViewModel Recoil
            local fireInterval = (60 / self.Primary.RPM) * 0.5
            local timeToNextFire = self:GetNextRecoil() - CurTime()
            local t = math.Clamp(timeToNextFire / fireInterval, 0, 1)
            local Recoildelta = math.min((t > 0.5 and 1 - t or t) * 2, 1) -- 开火时 = 1，然后衰减到 0

            local recoiloffsetpos = self.ViewmodelRecoil.Pos
            local recoiloffsetang = self.ViewmodelRecoil.Ang
            pos:Add(Vector(recoiloffsetpos[1] * angles:Right() + recoiloffsetpos[2] * angles:Forward() +
                recoiloffsetpos[3] * angles:Up()) * Recoildelta)

            angles:Add(recoiloffsetang * Recoildelta)
        end
    end

    if VManip then
        if self.VMOffset.VManip then
            vmanipAng:Set(self.VMOffset.VManip.Ang)
            vmanipPos:Set(self.VMOffset.VManip.Pos)
        else
            vmanipAng:Set(vmanipDef.ang)
            vmanipPos:Set(vmanipDef.pos)
        end

        vmanipMul = Lerp(RealFrameTime() * 10, vmanipMul, VManip:IsActive() and aimdelta < 0.2 and 1 or 0)

        vmanipAng:Mul(vmanipMul)
        vmanipPos:Mul(vmanipMul)

        pos:Add(vmanipPos.x * angles:Right() + vmanipPos.y * angles:Forward() + vmanipPos.z * angles:Up())


        angles:RotateAroundAxis(angles:Forward(), vmanipAng.r)
        angles:RotateAroundAxis(angles:Up(), vmanipAng.y)
        angles:RotateAroundAxis(angles:Right(), vmanipAng.p)
    end

    return pos, angles
end

local cvar_mdv = CreateClientConVar("trmbase_sight_mdv", 1.33, true, false, "None Description", 0, 3)
local function MDVSensitivity(curFOV, defFOV, mdv)
    -- 限制 mdv 最小值，避免 tan 爆炸
    mdv = math.max(mdv or 1.33, 0.5) -- 最小 0.5

    if mdv == 0 then
        return curFOV / defFOV
    end

    -- 保护：避免角度接近 90°
    local angleA = math.rad(defFOV / 2) / mdv
    local angleB = math.rad(curFOV / 2) / mdv

    -- 角度超过 85° 时钳制，避免 tan 爆炸
    local maxAngle = math.rad(85)
    if angleA > maxAngle then angleA = maxAngle end
    if angleB > maxAngle then angleB = maxAngle end

    local a = math.tan(angleA)
    local b = math.tan(angleB)

    return math.Clamp(b / a, 0.01, 1)
end


function SWEP:AdjustMouseSensitivity(defaultSensitivity, localFOV, _)
    local defaultFOV = GetConVar("fov_desired"):GetInt()

    local scope = self.sight and self.sight.zoom or false
    local aim = self:GetAimDelta()
    if scope and not self:GetTacSight() then
        localFOV = Lerp(aim, defaultFOV, self:GetScopeZoomFov())
    else
        localFOV = Lerp(aim, defaultFOV, defaultFOV / self.Aim.Scale)
    end
    --chat.AddText(scope)
    return MDVSensitivity(localFOV, defaultFOV, cvar_mdv:GetFloat())
end

local viewmodelFovMul = CreateClientConVar("trmbase_cl_viewmodelfov_aim", 1, true, true, "", 0, 3)
local Mytan = math.tan


local finalFOV = 75
local vmFov = 75
function SWEP:ScaleViewmodelFov()
    local aim = self:GetClientAimDelta()
    local originFov = self.m_ViewModelFOV or 70
    local isCheap = GetConVar("trmbase_cl_cheapscope"):GetBool()

    local aimFOV = originFov
    if self.sight and self.sight.zoom and not self:GetTacSight() then
        if isCheap then
            -- Cheap Scope：VM 缩放只随开镜进度变化，不随倍率变化
            -- 让 VM 缩到 80% ~ 90% 左右，不怼脸就行
            local newFov = originFov * (0.25 + self.sight.zoom ^ 0.2)
            aimFOV = Lerp(aim, originFov, newFov)
        end
    else
        -- 没有瞄具：正常开镜缩放
        aimFOV = originFov
    end

    aimFOV = aimFOV * viewmodelFovMul:GetFloat()
    vmFov = Lerp(RealFrameTime() * 10, vmFov or 75, math.Clamp(Lerp(aim, originFov, aimFOV), 0, 180))
    self.ViewModelFOV = vmFov
end

function SWEP:TranslateFOV(fov)
    local aimDelta = self:GetClientAimDelta() or 0
    local normalFOV = GetConVar("fov_desired"):GetInt()
    local aimFOV = normalFOV / self.Aim.Scale -- 建议 55-65 之间
    -- 使用平滑曲线，让过渡更自然
    if self.sight and self.sight.zoom and (GetConVar("trmbase_cl_cheapscope"):GetBool() or not self:IsFirstPerson()) and not self:GetTacSight() then
        aimFOV = self:GetScopeZoomFov()
    end

    if self:IsReloading() then
        aimFOV = aimFOV + 5
    end

    local easedDelta = aimdelta
    local FOV = Lerp(easedDelta, normalFOV, aimFOV)
    finalFOV = Lerp(RealFrameTime() * 15, finalFOV, FOV)
    return finalFOV
end
