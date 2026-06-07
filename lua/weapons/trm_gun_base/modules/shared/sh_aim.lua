function SWEP:CanAim()
    local seq = self.m_CurrentSequence or self:GetPlayingSequence()
    if self:GetSprintDelta() > 0.8 or (self.IronsightReload == false and self:IsReloading()) or string.find(seq, "Melee") or string.find(seq, "Holster") or string.find(seq, "Draw") then return false end
    return true
end

function SWEP:AimIn()
    self.m_AimDelta = math.Approach(self.m_AimDelta, 1, FrameTime() / self.m_AimTime)
    if not self.m_Aiming then
        if self:IsAnimFinished() then
            self:TrySetTask("AdsIn")
        end
        self.m_Aiming = true
    end
end

function SWEP:AimOut()
    self.m_AimDelta = math.Approach(self.m_AimDelta, 0, FrameTime() / self.Aim.Time)
    if self.m_Aiming then
        if self:IsAnimFinished() then
            self:TrySetTask("AdsOut")
        end
        self.m_Aiming = false
    end
end

local cvar_toggle = CreateClientConVar("trmbase_toggle_aim", 0, true, true, "", 0, 1)
function SWEP:AimLogic()
    if not cvar_toggle:GetBool() then
        -- 这里是按住开镜
        if self:GetOwner():KeyDown(IN_ATTACK2) and self:CanAim() then
            self:AimIn()
        else
            self:AimOut()
        end
    else
        if (self:GetOwner():KeyPressed(IN_ATTACK2) and self:CanAim()) then
            self.m_AimToggle = not self.m_AimToggle or false
        end

        if (self.m_AimToggle && self:CanAim()) then
            self:AimIn()
        else
            self:AimOut()
            self.m_AimToggle = false
        end
    end

    if SERVER then
        self:SetAimDelta(self.m_AimDelta)
    end

    return true
end

function SWEP:AimThink()
    if SERVER and IsFirstTimePredicted() then
        self:AimLogic()
    end
end

