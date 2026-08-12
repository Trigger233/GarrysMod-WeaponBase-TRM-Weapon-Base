if SERVER then return end
SWEP.ClientState = {}
require("trm_utils")

local offsetX = CreateClientConVar("trmbase_vm_offsetX", 0, true, true, "ViewModel X Offset", -10, 10)
local offsetY = CreateClientConVar("trmbase_vm_offsetY", 0, true, true, "ViewModel Y Offset", -10, 10)
local offsetZ = CreateClientConVar("trmbase_vm_offsetZ", 0, true, true, "ViewModel Z Offset", -10, 10)
local rft = RealFrameTime()

local bobt = 0
local airDelta = 0
local airTargetDelta = 0
local hasJumped = false
local math = math
local trm_utils = trm_utils

local function getJumpPoseDelta(c)
    local t = (c > 0.5 and 1 - c or c) * 2
    return t
end

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
        bobt = (bobt or 0) + RealFrameTime() * math.min(speed, 150) * 0.05
        -- 不限制范围，让 sin 自然循环
    elseif speed < 10 then
        bobt = (bobt or 0) * 0.95 -- 停止时归零
    end
    local mult = math.min(speed / 300, 1)
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
    local ground = owner:IsOnGround()
    if ground then
        hasJumped = false
    elseif not hasJumped then
        airTargetDelta = 1
        hasJumped = true
    end
    airTargetDelta = Lerp(RealFrameTime() * 2, airTargetDelta, 0)
    airDelta = Lerp(RealFrameTime() * 10, airDelta, airTargetDelta)
    ang.p = ang.p - 15 * airDelta
    pos.z = pos.z - 2 * airDelta
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
    local targetRoll = math.Clamp(sideSpeed * 0.09, -15, 15)
    swayAng.roll = Lerp(ft * 10, swayAng.roll, targetRoll)
    -- ========================

    -- 位置派生
    local posSway = Vector(0, 0, 0)
    posSway.x = swayAng.yaw * -1
    posSway.y = math.abs(swayAng.yaw) * -0.5
    posSway.z = -swayAng.pitch * 0.5

    return swayAng, posSway
end

function SWEP:GetClientAimDelta()
    if not CLIENT then
        return self:GetAimDelta()
    end

    self.ClientState["aim"] = self.ClientState["aim"] or 0
    local target            = self:GetAimDelta() or 0
    local smoothSpeed       = 20 -- 平滑速度，越大越快

    self.ClientState["aim"] = Lerp(RealFrameTime() * smoothSpeed, self.ClientState["aim"], target) or 0
    return self.ClientState["aim"] or 0
end

local r = Angle(0, 0, 0)
function SWEP:GetClientVisualRecoil()
    if SERVER then return end
    local source = self:GetVisualRecoil()
    r = LerpAngle(RealFrameTime() * 50, r, source)

    return r
end

local DuckDelta = 0
function SWEP:GetDucking()
    local owner = self:GetOwner()
    if IsValid(owner) then
        local target = (trm_weapon_base_util.IsDucking(owner) and owner:OnGround()) and 1 or 0
        DuckDelta = Lerp(RealFrameTime() * 5, DuckDelta, target)
    else
        DuckDelta = 0
    end
    return DuckDelta
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
local visAng = Angle()

local vmanipDef = {
    pos = Vector(1.5, 0, -1.5),
    ang = Angle(0, 2, -10)
}
local vmanipPos = Vector(0, 0, 0)
local vmanipAng = Angle(0, 0, 0)
local vmanipMul = 0

local cacheAngle = {}

local SafetyMul = 0

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
local currentIdlePos = Vector()
local currentIdleAng = Angle()

local VMRecoilPos = Vector()
local VMRecoilAng = Angle()

function SWEP:CalcViewModelView(vm, pos, angles, poss, angless)
    -- 冻结 VM
    if GetConVar("trmbase_freeze_vm"):GetInt() ~= 0 then
        if not self.m_VMFreezeAng then self.m_VMFreezeAng = angles end
        if not self.m_VMFreezePos then self.m_VMFreezePos = pos end
        return self.m_VMFreezePos, self.m_VMFreezeAng
    else
        self.m_VMFreezeAng = nil
        self.m_VMFreezePos = nil
    end

    local dt       = RealFrameTime()
    local aimdelta = self:GetClientAimDelta()

    -- ========== 缓存方向向量（避免重复生成） ==========
    local right    = angles:Right()
    local forward  = angles:Forward()
    local up       = angles:Up()
    -- ==================================================

    -- ========== Idle Offset ==========
    idledelta      = (1 - aimdelta)
    currentIdlePos = self.VMOffset.Idle.Pos
    currentIdleAng = self.VMOffset.Idle.Ang

    if self:IsInspecting() and self.VMOffset.Inspect then
        currentIdlePos = self.VMOffset.Inspect.Pos or currentIdlePos
        currentIdleAng = self.VMOffset.Inspect.Ang or currentIdleAng
    end

    CachePos = ((currentIdlePos.x + offsetX:GetFloat()) * right +
        (currentIdlePos.y + offsetY:GetFloat()) * forward -
        (currentIdlePos.z + offsetZ:GetFloat()) * up) * idledelta
    CacheAngle = currentIdleAng * idledelta

    pos:Add(CachePos)
    angles:Add(CacheAngle)

    -- ========== Sway ==========
    local swayAng, swayPos = self:Sway()
    local swayMul = Lerp(aimdelta, 1, 0.1)
    local applySwayPos = -(right * swayPos.x + forward * swayPos.y + up * swayPos.z) * swayMul
    pos:Add(applySwayPos)
    angles:Add(swayAng * swayMul)

    -- ========== Bob ==========
    local bobPos, bobAng = self:CustomBob()
    local bobMul = (1 - aimdelta)
    local applyBobPos = (right * bobPos.x + forward * bobPos.y + up * bobPos.z) * bobMul
    bobAng:Mul(bobMul * 0.9)
    pos:Add(applyBobPos)
    angles:Add(bobAng)

    -- ========== Duck ==========
    local duckMul = (1 - aimdelta) * self:GetDucking()
    local duckPosOffset = self.VMOffset.Crouch.Pos
    local applyDuckPos = (right * duckPosOffset.x +
        forward * duckPosOffset.y +
        up * duckPosOffset.z) * duckMul
    pos:Add(applyDuckPos)
    angles:Add(self.VMOffset.Crouch.Ang * duckMul)

    -- ========== Sprint ==========
    local sprintDelta = self:GetSprintDelta() * (self:CanSprint() and 1 or 0)
    local sprintPosOffset = self.VMOffset.Sprint.Pos
    local applySprintPos = (right * sprintPosOffset.x +
        forward * sprintPosOffset.y +
        up * sprintPosOffset.z) * sprintDelta
    pos:Add(applySprintPos)
    angles:Add(self.VMOffset.Sprint.Ang * sprintDelta)

    -- ========== Aim Offset ==========
    AimOffset = Vector(self.Sight.Pos)
    AimOffsetAngle = Angle(self.Sight.Ang)
    if self:HasFlag("Tacsight") then
        AimOffset:Add(self.TacSight.Pos)
        AimOffsetAngle:Add(self.TacSight.Ang)
    end

    aimOffset = LerpVector(dt * 10, aimOffset, AimOffset)
    aimAngle = LerpAngle(dt * 10, aimAngle, AimOffsetAngle)

    local applyAimPos = (right * aimOffset.x + forward * aimOffset.y + up * aimOffset.z) * aimdelta
    pos:Add(applyAimPos)
    angles:Add(aimAngle * aimdelta)

    -- ========== 配件瞄具偏移 ==========
    if self:GetSight() and not self:HasFlag("Tacsight") then
        local sight = self:GetSight()
        local sightPos = sight.AimPos
        if self:HasFlag("HybridOn") and sight.HybridSight and sight.HybridSight.AimPos then
            sightPos = sight.HybridSight.AimPos
        end

        local applySightPos = (right * sightPos.x + forward * sightPos.y + up * sightPos.z) * aimdelta
        pos:Add(applySightPos)
        angles:Add(sight.AimAng * aimdelta)
    end

    -- ========== 后坐力后退 ==========
    back = Lerp(dt * 20, back, self:GetVisualRecoilBackward())
    pos:Add(-back * forward)

    -- ========== 视觉后坐力 ==========
    visAng = self:GetClientVisualRecoil()
    local tacRoll = self:HasFlag("Tacsight") and (self.TacSight.Ang and self.TacSight.Ang.r or 0) or 0
    visAng = dealTacsight(visAng, tacRoll)

    angles:RotateAroundAxis(right, -visAng.p * const_vrec)
    angles:RotateAroundAxis(up, visAng.y * const_vrec)

    -- ========== VManip ==========
    if VManip then
        if self.VMOffset.VManip then
            vmanipAng:Set(self.VMOffset.VManip.Ang)
            vmanipPos:Set(self.VMOffset.VManip.Pos)
        else
            vmanipAng:Set(vmanipDef.ang)
            vmanipPos:Set(vmanipDef.pos)
        end

        vmanipMul = Lerp(dt * 10, vmanipMul, VManip:IsActive() and aimdelta < 0.2 and 1 or 0)
        vmanipAng:Mul(vmanipMul)
        vmanipPos:Mul(vmanipMul)

        pos:Add(vmanipPos.x * right + vmanipPos.y * forward + vmanipPos.z * up)

        angles:RotateAroundAxis(forward, vmanipAng.r)
        angles:RotateAroundAxis(up, vmanipAng.y)
        angles:RotateAroundAxis(right, vmanipAng.p)
    end

    --
    VMRecoilPos = LerpVector(dt * 10, VMRecoilPos, self.ViewModelRecoilPos)
    VMRecoilAng = LerpAngle(dt * 10, VMRecoilAng, self.ViewModelRecoilAng)
    pos:Add(VMRecoilPos.x * right + VMRecoilPos.y * forward + VMRecoilPos.z * up)
    angles:Add(VMRecoilAng)
    self:RecoverViewModelRecoil()

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
    if scope and self:ShouldZoom() then
        localFOV = Lerp(aim, defaultFOV, self:GetScopeZoomFov())
    else
        localFOV = Lerp(aim, defaultFOV, defaultFOV / self.Aim.Scale)
    end
    --chat.AddText(scope)
    return MDVSensitivity(localFOV, defaultFOV, cvar_mdv:GetFloat())
end

SWEP.ViewModelRecoilPos = Vector()
SWEP.ViewModelRecoilAng = Angle()

function SWEP:DoViewModelRecoil()
    local tbl = self.ViewmodelRecoil
    --Add
    local currentPos = self.ViewModelRecoilPos
    local currentAng = self.ViewModelRecoilAng
    math.randomseed(14546)
    currentPos = tbl.Pos
    currentAng = tbl.Ang
    local yawDelta = math.Rand(-1, 1) * tbl.YawMultiplier * 0.05
    currentPos.x = currentPos.x + yawDelta
    currentAng.y = currentAng.y + yawDelta
    local PitchDelta = math.Rand(-1, 0) * tbl.PitchMultiplier * 0.005
    currentPos.z = currentPos.z + PitchDelta
    currentAng.p = currentAng.p + PitchDelta 
    --
    self.ViewModelRecoilPos = currentPos
    self.ViewModelRecoilAng = currentAng
end


local ZERO_VECTOR = Vector(0, 0, 0)
local ZERO_ANGLE = Angle(0, 0, 0)
function SWEP:RecoverViewModelRecoil()
    local dt = RealFrameTime()
    self.ViewModelRecoilAng = LerpAngle(dt * 20, self.ViewModelRecoilAng, ZERO_ANGLE)
    self.ViewModelRecoilPos = LerpVector(dt * 20, self.ViewModelRecoilPos, ZERO_VECTOR)
end
