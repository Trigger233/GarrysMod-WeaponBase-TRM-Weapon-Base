if SERVER then return end
SWEP.ClientState = {}
require("trm_utils")
require("trm_math")
local offsetX = CreateClientConVar("trmbase_vm_offsetX", 0, true, true, "ViewModel X Offset", -10, 10)
local offsetY = CreateClientConVar("trmbase_vm_offsetY", 0, true, true, "ViewModel Y Offset", -10, 10)
local offsetZ = CreateClientConVar("trmbase_vm_offsetZ", 0, true, true, "ViewModel Z Offset", -10, 10)

local bobt = 0
local JumpDelta = 1
local math = math
local clamp = math.Clamp

SWEP.PlayerJumpDelta = 0

local currentJumpedDelta = 0

function SWEP:CustomBob(AimDelta)

    local rft = RealFrameTime()

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
    local mult = math.min(speed / 300, 1) * Lerp(AimDelta, 1, 0.2)
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

    -- self.PlayerJumpDelta = math.max(0, self.PlayerJumpDelta - rft * 2)
    -- currentJumpedDelta = trm_math.SafeLerp(rft * 10, currentJumpedDelta, self.PlayerJumpDelta)
 
    -- ang.p = ang.p + 5 * currentJumpedDelta
    -- pos.z = pos.z + 1 * currentJumpedDelta
    return pos, ang
end

local sway = {
    pos = Vector(),
    ang = Angle(),
    lastEyeAng = Angle(),
}
local cvar_swaymultiplier = CreateClientConVar("trmbase_cl_sway", 1, true, true, "", 0, 10)
local cvar_swaymultiplier_Recover = CreateClientConVar("trmbase_cl_sway_recover", 1, true, true, "", 0, 10)

function SWEP:Sway(aimDelta)
    if game.SinglePlayer() and gui.IsGameUIVisible() then
        return sway.ang, sway.pos
    end
    local multiplier = cvar_swaymultiplier:GetFloat()
    local rft = RealFrameTime()
    local p = LocalPlayer()
    if ! IsValid(p) then
        return sway.ang, sway.pos
    end
    local mul = Lerp(aimDelta, 1, 0.25) * multiplier
    local Currentvelocity = p:GetVelocity()
    local CurrentEyeAngle = p:EyeAngles()

    local diffAng = CurrentEyeAngle - sway.lastEyeAng
    sway.lastEyeAng = CurrentEyeAngle
    diffAng:Normalize()

    local veloRight = Currentvelocity:Dot(CurrentEyeAngle:Right())
    local veloForward = Currentvelocity:Dot(CurrentEyeAngle:Forward()) * (1 - self:GetSprintDelta())
    sway.ang:Add(diffAng * 0.1 * mul)
    ---
    sway.pos.x = math.Clamp(sway.pos.x - diffAng.y * 0.1 * mul, -45, 45)
    sway.pos.z = sway.pos.z - diffAng.p * 0.05
    ----------------
    sway.ang.r = sway.ang.r + veloRight * 0.001
    sway.ang.y = sway.ang.y + veloRight * 0.0002
    -----------------
    sway.pos.y = sway.pos.y + math.max(0, veloForward) * 0.0001


    --------------------
    sway.ang.r = math.Clamp(sway.ang.r, -15, 15)
    sway.ang.y = math.Clamp(sway.ang.y, -45, 45)
    ---------
    local recoverSpeed = cvar_swaymultiplier_Recover:GetFloat() *  rft * 10 / mul
    sway.ang:Set(trm_math.SafeLerpAngle(recoverSpeed, sway.ang, angle_zero))
    sway.pos:Set(trm_math.SafeLerpVector(recoverSpeed, sway.pos, vector_origin))
    return sway.ang, sway.pos
end

function SWEP:GetClientAimDelta()
    if not CLIENT then
        return self:GetAimDelta()
    end

    self.ClientState["aim"] = self.ClientState["aim"] or 0
    local target            = self:GetAimDelta() or 0
    local smoothSpeed       = self.Aim.Type == "Linear" and 20 or 5 -- 平滑速度，越大越快

    self.ClientState["aim"] = trm_math.SafeLerp(RealFrameTime() * smoothSpeed, self.ClientState["aim"], target) or 0
    return self.ClientState["aim"] or 0
end

local r = Angle(0, 0, 0)
function SWEP:GetClientVisualRecoil()
    if SERVER then return end
    local source = self:GetVisualRecoil()
    r = trm_math.SafeLerpAngle(RealFrameTime() * 10 , r, source)
    return r
end

local DuckDelta = 0
function SWEP:GetDucking()
    local owner = self:GetOwner()
    if IsValid(owner) then
        local target = (trm_weapon_base_util.IsDucking(owner) and owner:OnGround()) and 1 or 0
        DuckDelta = trm_math.SafeLerp(RealFrameTime() * 5, DuckDelta, target)
    else
        DuckDelta = 0
    end
    return DuckDelta
end

local CachePos = Vector(0, 0, 0)
local CacheAngle = Angle(0, 0, 0)

local AimOffset, AimOffsetAngle = Vector() , Angle()
local aimOffset = Vector()
local aimAngle = Angle()

local back = 0
local sprintDelta = 0
local sprintPosOffset = Vector()
local sprintAngOffset = Angle()
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

local cvar_AdditivePos = Vector()




function SWEP:CalcViewModelView(vm, pos, angles, poss, angless)
    --冻结 VM
    if GetConVar("trmbase_freeze_vm"):GetInt() ~= 0 then
        if not self.m_VMFreezeAng then self.m_VMFreezeAng = angles end
        if not self.m_VMFreezePos then self.m_VMFreezePos = pos end
        return self.m_VMFreezePos, self.m_VMFreezeAng
    else
        self.m_VMFreezeAng = nil
        self.m_VMFreezePos = nil
    end

    if LocalPlayer():ShouldDrawLocalPlayer() then
        return pos, angles
    end

    local dt       = RealFrameTime()
    local aimdelta = self:GetClientAimDelta()

    -- ========== 缓存方向向量（避免重复生成） ==========
    local right    = angles:Right()
    local forward  = angles:Forward()
    local up       = angles:Up()

    --     -- ==================================================

    -- ========== Idle Offset ==========
    idledelta      = (1 - aimdelta)
    currentIdlePos = self.VMOffset.Idle.Pos
    currentIdleAng = self.VMOffset.Idle.Ang
    cvar_AdditivePos:SetUnpacked(offsetX:GetFloat(), offsetY:GetFloat(),
        offsetZ:GetFloat())

    if self:IsInspecting() and self.VMOffset.Inspect then
        currentIdlePos = self.VMOffset.Inspect.Pos or currentIdlePos
        currentIdleAng = self.VMOffset.Inspect.Ang or currentIdleAng
    end

    CachePos:Set(currentIdlePos * idledelta)
    CacheAngle:Set(currentIdleAng * idledelta)

    CachePos:Add(cvar_AdditivePos* idledelta)

    --     -- ========== Sway ==========
    local swayAng, swayPos = self:Sway(aimdelta)
    local applySwayPos = -swayPos
    CachePos:Add(applySwayPos)
    CacheAngle:Add(swayAng)
    --     -- ========== Bob ==========
    local bobPos, bobAng = self:CustomBob(aimdelta)
    CachePos:Add(bobPos)
    CacheAngle:Add(bobAng)
    --     -- ========== Duck ==========
    local DuckingDelta = self:GetDucking()
    local duckMul = (1 - aimdelta) * DuckingDelta
    local duckPosOffset = self.VMOffset.Crouch.Pos
    local applyDuckPos = duckPosOffset * duckMul
    CachePos:Add(applyDuckPos)
    CacheAngle:Add(self.VMOffset.Crouch.Ang * duckMul)
    --     -- ========== Sprint ==========
    if self.VMOffset.Sprint then
        sprintDelta = trm_math.SafeLerp(dt * 8, sprintDelta, self:GetSprintDelta() > 0 and 1 or 0)
        sprintPosOffset:Set(self.VMOffset.Sprint.Pos)
        sprintAngOffset:Set(self.VMOffset.Sprint.Ang)
        sprintPosOffset:Mul(sprintDelta)
        sprintAngOffset:Mul(sprintDelta)

        CachePos:Add(sprintPosOffset)
        CacheAngle:Add(sprintAngOffset)
    end
    --     -- ========== Aim Offset ==========
    AimOffset = Vector(self.Sight.Pos)
    AimOffsetAngle = Angle(self.Sight.Ang)
    if self:HasFlag("Tacsight") then
        AimOffset:Add(self.TacSight.Pos)
        AimOffsetAngle:Add(self.TacSight.Ang)
    end

    aimOffset = trm_math.SafeLerpVector(dt * 10, aimOffset, AimOffset)
    aimAngle = trm_math.SafeLerpAngle(dt * 10, aimAngle, AimOffsetAngle)

    local applyAimPos = aimOffset * aimdelta
    CachePos:Add(applyAimPos)
    CacheAngle:Add(aimAngle * aimdelta)
    --     -- ========== 配件瞄具偏移 ==========
    if self:GetSight() and not self:HasFlag("Tacsight") then
        local sight = self:GetSight()
        local sightPos = sight.AimPos
        if self:HasFlag("HybridOn") and sight.HybridSight and sight.HybridSight.AimPos then
            sightPos = sight.HybridSight.AimPos
        end

        local applySightPos = sightPos * aimdelta
        CachePos:Add(applySightPos)
        CacheAngle:Add(sight.AimAng * aimdelta)
    end


    --     -- ========== 视觉后坐力 ==========
    visAng = self:GetClientVisualRecoil()
    local tacRoll = self:HasFlag("Tacsight") and (self.TacSight.Ang and self.TacSight.Ang.r or 0) or 0
    visAng = dealTacsight(visAng, tacRoll)

    CachePos.z = CachePos.z + visAng.pitch * 0.005
    CachePos.x = CachePos.x + visAng.yaw * 0.005

    angles:RotateAroundAxis(right, -visAng.p * const_vrec)
    angles:RotateAroundAxis(up, visAng.y * const_vrec)
    --     -- ========== VManip ==========
    if VManip then
        if self.VMOffset.VManip then
            vmanipAng:Set(self.VMOffset.VManip.Ang)
            vmanipPos:Set(self.VMOffset.VManip.Pos)
        else
            vmanipAng:Set(vmanipDef.ang)
            vmanipPos:Set(vmanipDef.pos)
        end

        vmanipMul = trm_math.SafeLerp(dt * 10, vmanipMul, VManip:IsActive() and aimdelta < 0.2 and 1 or 0)
        vmanipAng:Mul(vmanipMul)
        vmanipPos:Mul(vmanipMul)

        CachePos:Add(vmanipPos)

        angles:RotateAroundAxis(forward, vmanipAng.r)
        angles:RotateAroundAxis(up, vmanipAng.y)
        angles:RotateAroundAxis(right, vmanipAng.p)
    end


    VMRecoilPos = self.ViewModelRecoilPos
    VMRecoilAng = self.ViewModelRecoilAng
    CachePos:Add(VMRecoilPos)
    CacheAngle:Add(VMRecoilAng)
    self:RecoverViewModelRecoil()
    -- print(CacheAngle , CachePos)
    pos:Add(CachePos.x * right + CachePos.y * forward + CachePos.z * up)
    angles:Add(CacheAngle)

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
--Shake ViewModel
function SWEP:DoViewModelRecoil()
    local tbl = self.ViewmodelRecoil
    --Add
    local currentPos = self.ViewModelRecoilPos
    local currentAng = self.ViewModelRecoilAng
    currentPos:Set(tbl.Pos)
    currentAng:Set(tbl.Ang)


    local yawDelta = math.Rand(-1, 1) * tbl.YawMultiplier * 0.25
    currentPos.x = currentPos.x + yawDelta
    currentAng.y = currentAng.y + yawDelta
    local PitchDelta = math.Rand(-1, 0) * tbl.PitchMultiplier
    currentPos.z = currentPos.z + PitchDelta
    currentAng.p = currentAng.p + PitchDelta
    local VeloUp = self:GetRecoilUp()
    local VeloSide = self:GetRecoilSide()

    currentAng.p = currentAng.p - VeloUp * 1 * tbl.PitchMultiplier
    currentAng.y = currentAng.y - VeloSide * 0.2 * tbl.YawMultiplier

    currentPos.z = currentPos.z - VeloUp * 1 * tbl.PitchMultiplier
    currentPos.x = currentPos.x - VeloSide * 0.2 * tbl.YawMultiplier

    local aim = self:GetAimDelta()
    local mul = trm_math.SafeLerp(aim, 1, tbl.AdsMultiplier or 0.25)
    currentPos:Mul(mul)
    currentAng:Mul(mul)
    --

    currentPos.y = currentPos.y -
        math.Rand(self.VisualRecoil.Backward[1], self.VisualRecoil.Backward[2]) *
        trm_math.SafeLerp(aim, 1, self.VisualRecoil.AdsMultiplier or 1)
    ---


    self.ViewModelRecoilPos = currentPos
    self.ViewModelRecoilAng = currentAng
end

local ZERO_VECTOR = Vector(0, 0, 0)
local ZERO_ANGLE = Angle(0, 0, 0)
function SWEP:RecoverViewModelRecoil()
    local dt = RealFrameTime()
    local recoverMul = clamp(dt * 20 * (self.ViewmodelRecoil.RecoverMultiplier or 1), 0, 1)
    self.ViewModelRecoilAng:Set(trm_math.SafeLerpAngle(recoverMul, self.ViewModelRecoilAng, ZERO_ANGLE))
    self.ViewModelRecoilPos:Set(trm_math.SafeLerpVector(recoverMul, self.ViewModelRecoilPos, ZERO_VECTOR))
    --print(self.ViewModelRecoilAng, self.ViewModelRecoilPos)
end
