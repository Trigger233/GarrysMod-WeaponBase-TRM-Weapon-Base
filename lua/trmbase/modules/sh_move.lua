TRMBase = TRMBase or {}

local function approxEqualsZero(a)
    return math.abs(a) < 0.0001
end

TRMBase.ClientRecoil = Vector()
TRMBase.RecoilRise = Vector(0, 0, 0)
TRMBase.RecoilReset = Vector()
TRMBase.LastEyeAnglePitch = 0
TRMBase.ClientRecoilTime = 0
TRMBase.ClientRecoilTimeStep = 0.01
TRMBase.RecoilProgress = 0
hook.Add("StartCommand", "TRMBase", function(ply, cmd)
    TRMBase:StartCommand(ply, cmd)
end)

local cvar_reload_slowmove = CreateConVar("trmbase_sv_reload_slowdown", 0, { FCVAR_ARCHIVE }, "helptext", 0, 1)

function TRMBase:StartCommand(ply, cmd)
    if ! IsValid(ply) or cmd:CommandNumber() == 0 then return end

    local wpn = ply:GetActiveWeapon()
    if ! IsValid(wpn) or ! wpn.IsTRMWeapon then
        if ! self.RecoilRise:IsZero() then
            self.RecoilRise:Zero()
        end
        return
    end
    self:CameraRecoil(ply, cmd, wpn)

    if wpn:IsReloading() and cvar_reload_slowmove:GetBool() then cmd:RemoveKey(IN_SPEED) end
end

local diff = 0
local Max = math.max
local Min = math.min
local Clamp = math.Clamp
local Mass = 200
function TRMBase:CameraRecoil(ply, cmd, wpn)
    if SERVER then return end
    local EyeAngle = cmd:GetViewAngles()
    local rft = RealFrameTime()
    diff = EyeAngle.p - self.LastEyeAnglePitch

    local recrise = self.RecoilRise

    if ! approxEqualsZero(recrise[1]) then
        if recrise[1] > 0 and diff < 0 then
            recrise[1] = Max(0, recrise[1] + diff)
        elseif recrise[1] < 0 and diff > 0 then
            recrise[1] = Min(0, recrise[1] + diff)
        end
    end
    self.RecoilRise = recrise

    local dt = self.ClientRecoilTimeStep

    local wpnUp = wpn:GetRecoilUp() 
    local wpnSide = wpn:GetRecoilSide()

    self.RecoilProgress = Max(0, self.RecoilProgress - dt * 5)
    if CurTime() > self.ClientRecoilTime then
        local velo = self.ClientRecoil
        self.ClientRecoil:SetUnpacked( - wpnUp, wpnSide, 0)
        self.ClientRecoilTime = CurTime() + dt

        local recoilScale = math.abs(wpnUp) + math.abs(wpnSide)
        if recoilScale > 0.001 and self.RecoilProgress < 1 then
            self.RecoilProgress = Clamp(self.RecoilProgress + dt * 25, 0, 1)
        end
    end

    self.RecoilRise = self.RecoilRise + self.ClientRecoil
    local recoverScale = wpn.Recoil.Recover * (1 - self.RecoilProgress) * 0.1 
    if (self.RecoilProgress < 1) then
        self.RecoilReset[1] =   self.RecoilRise[1] *Clamp( recoverScale , 0 , 1)
        self.ClientRecoil:Sub(self.RecoilReset)
        self.RecoilRise = self.RecoilRise - self.RecoilReset
    end


    EyeAngle:SetUnpacked(EyeAngle.p + self.ClientRecoil[1], EyeAngle.y + self.ClientRecoil[2], EyeAngle.r)
    EyeAngle:Normalize()

    cmd:SetViewAngles(EyeAngle)
    self.LastEyeAnglePitch = EyeAngle.p
end

hook.Add("HUDPaint", "TRMBASE_RECOILDebug", function()
    if ! GetConVar('developer'):GetBool() then return end
    draw.SimpleText(TRMBase.ClientRecoil, "Default", 0, ScrH() * 0.5, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText(TRMBase.RecoilRise, "Default", 0, ScrH() * 0.6, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
end)
