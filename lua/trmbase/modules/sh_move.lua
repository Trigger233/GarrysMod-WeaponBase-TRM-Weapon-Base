TRMBase = TRMBase or {}

local function approxEqualsZero(a)
    return math.abs(a) < 0.0001
end

TRMBase.ClientRecoil = Angle()
TRMBase.RecoilRise = Angle()
TRMBase.RecoilReset = Angle()
TRMBase.LastEyeAnglePitch = 0
TRMBase.ClientRecoilTime = 0
TRMBase.ClientRecoilTimeStep = 0.01
TRMBase.RecoilProgress = 0
hook.Add("StartCommand", "TRMBase", function(ply, cmd)
    TRMBase:StartCommand(ply, cmd)
end)


function TRMBase:StartCommand(ply, cmd)
    if ! IsValid(ply) or cmd:CommandNumber() == 0 then return end

    local wpn = ply:GetActiveWeapon()
    if ! IsValid(wpn) or ! wpn.IsTRMWeapon then
        if ! self.RecoilRise:IsZero() then
            self.RecoilRise:Zero()
        end
        return
    end
    self:StartCmdRecoil(ply, cmd, wpn)
end

local diff = 0


function TRMBase:StartCmdRecoil(ply, cmd, wpn)
    if SERVER then return end
    local EyeAngle = cmd:GetViewAngles()
    local rft = RealFrameTime()
    diff = EyeAngle.p - self.LastEyeAnglePitch
    self.RecoilRise:Normalize()

    local recrise = self.RecoilRise

    if not approxEqualsZero(recrise.p) then
        if recrise.p > 0 and diff > 0 then
            recrise.p = math.max(0, recrise.p - diff)
        elseif recrise.p < 0 and diff < 0 then
            recrise.p = math.min(0, recrise.p - diff)
        end
    end
    self.RecoilRise = recrise

    local dt = self.ClientRecoilTimeStep

    local wpnUp = wpn:GetRecoilUp()
    local wpnSide = wpn:GetRecoilSide()
    local clientShake = wpn.m_ScreenShake

    self.RecoilProgress = math.max(0 ,self.RecoilProgress - dt * 5)

    if CurTime() > self.ClientRecoilTime then
        self.ClientRecoil.p = wpnUp
        self.ClientRecoil.y = wpnSide
        self.ClientRecoilTime = CurTime() + dt

        if math.abs(wpnUp) > 0.001 or math.abs(wpnSide) > 0.001 and self.RecoilProgress < 1 then
            self.RecoilProgress = math.Clamp(self.RecoilProgress + dt * 25, 0, 1)
        end
    end

    self.RecoilRise = self.RecoilRise + self.ClientRecoil
    local recoverScale = wpn.Recoil.Recover * 0.4 * (1 - self.RecoilProgress)
    if (self.RecoilProgress < 1) then
        self.RecoilReset.p = math.Approach(0, self.RecoilRise.p, recoverScale)
        self.ClientRecoil:Sub(self.RecoilReset)
        self.RecoilRise = self.RecoilRise - self.RecoilReset
    end

    self.ClientRecoil:Normalize()

    EyeAngle:Add(-self.ClientRecoil)
    EyeAngle:Normalize()

    cmd:SetViewAngles(EyeAngle)
    self.LastEyeAnglePitch = EyeAngle.p
end
