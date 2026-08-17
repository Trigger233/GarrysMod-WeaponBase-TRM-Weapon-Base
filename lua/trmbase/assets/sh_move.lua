TRMBase = TRMBase or {}

local function approxEqualsZero(a)
    return math.abs(a) < 0.0001
end

TRMBase.ClientRecoil = Angle()
TRMBase.RecoilRise = Angle()
TRMBase.RecoilReset = Angle()
TRMBase.LastEyeAnglePitch = 0

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

    local wpnUp = wpn:GetRecoilUp() 
    local wpnSide = wpn:GetRecoilSide()
    local clientShake = wpn.m_ScreenShake
    self.ClientRecoil.p = wpnUp * ( 1 + clientShake) * 0.5
    self.ClientRecoil.y = wpnSide
    self.RecoilRise = self.RecoilRise + self.ClientRecoil

    if (math.abs(wpnUp) < 0.01  ) then
        local recoverScale = wpn.Recoil.Recover * 0.2
        self.RecoilReset.p = math.Approach(0, self.RecoilRise.p, recoverScale)
        self.RecoilReset.y = math.Approach(0, self.RecoilRise.y, recoverScale * 0.5)
        self.ClientRecoil:Sub(self.RecoilReset)
        self.RecoilRise = self.RecoilRise - self.RecoilReset
    end

    self.ClientRecoil:Normalize()

    EyeAngle:Add(-self.ClientRecoil)
    EyeAngle:Normalize()

    cmd:SetViewAngles(EyeAngle)
    self.LastEyeAnglePitch = EyeAngle.p
end

