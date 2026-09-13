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
local Max = math.max
local Min = math.min
local Mass = 200
function TRMBase:StartCmdRecoil(ply, cmd, wpn)
    if SERVER then return end
    local EyeAngle = cmd:GetViewAngles()
    local rft = RealFrameTime()
    diff = EyeAngle.p - self.LastEyeAnglePitch

    local recrise = self.RecoilRise

    if not approxEqualsZero(recrise[1]) then
        if recrise[1] > 0 and diff > 0 then
            recrise[1] = Max(0, recrise[1] - diff)
        elseif recrise[1] < 0 and diff < 0 then
            recrise[1] = Min(0, recrise[1] - diff)
        end
    end
    self.RecoilRise = recrise

    local dt = self.ClientRecoilTimeStep

    local wpnUp = wpn:GetRecoilUp()
    local wpnSide = wpn:GetRecoilSide()
    local clientShake = wpn.m_ScreenShake

    self.RecoilProgress = Max(0, self.RecoilProgress - dt * 5)
    if CurTime() > self.ClientRecoilTime then
        self.ClientRecoil:SetUnpacked(-wpnUp * rft * Mass, wpnSide * rft * Mass, 0)
        self.ClientRecoilTime = CurTime() + dt

        if math.abs(wpnUp) > 0.001 or math.abs(wpnSide) > 0.001 and self.RecoilProgress < 1 then
            self.RecoilProgress = math.Clamp(self.RecoilProgress + dt * 25, 0, 1)
        end
    end

    self.RecoilRise = self.RecoilRise + self.ClientRecoil
    local recoverScale = wpn.Recoil.Recover * 0.4 * (1 - self.RecoilProgress)
    if (self.RecoilProgress < 1) then
        self.RecoilReset[1] = math.Approach(0, self.RecoilRise[1], recoverScale)
        self.ClientRecoil:Sub(self.RecoilReset)
        self.RecoilRise = self.RecoilRise - self.RecoilReset
    end


    EyeAngle:SetUnpacked(EyeAngle.p + self.ClientRecoil[1], EyeAngle.y, EyeAngle.r)
    EyeAngle:Normalize()

    cmd:SetViewAngles(EyeAngle)
    self.LastEyeAnglePitch = EyeAngle.p
end

hook.Add("HUDPaint", "TRMBASE_RECOILDebug", function()
    if ! GetConVar('developer'):GetBool() then return end
    draw.SimpleText(TRMBase.ClientRecoil, "Default", 0, ScrH() * 0.5, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
    draw.SimpleText(TRMBase.RecoilRise, "Default", 0, ScrH() * 0.6, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
end)
