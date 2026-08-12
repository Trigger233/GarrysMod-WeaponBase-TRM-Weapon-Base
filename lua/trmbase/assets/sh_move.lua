TRMBase = TRMBase or {}

local function approxEqualsZero(a)
    return math.abs(a) < 0.0001
end

TRMBase.RecoilTimeStep = 0.03
TRMBase.RecoilTime = 0
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

    if( math.abs(wpnUp) < 0.0001 and clientShake < 0.1  )or wpn.Recoil.AutoControl  then
        self.RecoilReset =  self.RecoilRise * 0.05 * wpn.Recoil.Recover
        self.ClientRecoil:Sub(self.RecoilReset)
        self.RecoilRise = self.RecoilRise - self.RecoilReset
    end

    self.ClientRecoil:Normalize()

    EyeAngle:Add(-self.ClientRecoil)
    EyeAngle:Normalize()

    cmd:SetViewAngles(EyeAngle)
    self.LastEyeAnglePitch = EyeAngle.p
end

hook.Add("HUDPaint", "TRM_Recoil_Debug", function()
    if ! GetConVar("developer"):GetBool() then return end
    local w, h = ScrH(), ScrH()
    draw.SimpleText(diff, "Default", w * 0.5, h * 0.5, color_white, TEXT_ALIGN_CENTER, 1)
    draw.SimpleText(TRMBase.ClientRecoil, "Default", w * 0.5, h * 0.55, color_white, TEXT_ALIGN_CENTER, 1)
    draw.SimpleText(TRMBase.RecoilRise, "Default", w * 0.5, h * 0.6, color_white, 1, 1)
end)
